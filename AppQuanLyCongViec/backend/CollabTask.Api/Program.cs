using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using CollabTask.Api.Data;
using CollabTask.Api.Services.AuthService;
using CollabTask.Api.Services.PriorityScoringService;
using CollabTask.Api.Services.UserWeightService;
using CollabTask.Api.Services.DatabaseSeeder;
using CollabTask.Api.Services.BackgroundServices;
using CollabTask.Api.Hubs;
using CollabTask.Api.Helpers;
using CollabTask.Api.Middleware;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.Filters;
using System.Text.Json.Serialization;
using Serilog;

// ===== CẤU HÌNH SERILOG =====
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File(
        path: "logs/log-.txt",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 7,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
    )
    .Enrich.FromLogContext()
    .MinimumLevel.Information()
    .CreateLogger();

try
{
    Log.Information("🚀 Starting CollabTask API...");

    var builder = WebApplication.CreateBuilder(args);

    // Sử dụng Serilog làm logging provider
    builder.Host.UseSerilog();

    // Add services to the container.
    builder.Services.AddControllers().AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.WriteIndented = true; 
    });

    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen(options => {
        options.AddSecurityDefinition("oauth2", new OpenApiSecurityScheme
        {
            Description = "Standard Authorization header using the Bearer scheme (\"bearer {token}\")",
            In = ParameterLocation.Header,
            Name = "Authorization",
            Type = SecuritySchemeType.ApiKey
        });
        options.OperationFilter<SecurityRequirementsOperationFilter>();
        
        options.MapType<IFormFile>(() => new OpenApiSchema
        {
            Type = "string",
            Format = "binary"
        });
        
        options.OperationFilter<FileUploadOperationFilter>();
    });

    builder.Services.AddDbContext<CollabTaskDbContext>(options =>
    {
        options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"), 
            sqlOptions =>
            {
                sqlOptions.CommandTimeout(30);
                sqlOptions.EnableRetryOnFailure(maxRetryCount: 3, maxRetryDelay: TimeSpan.FromSeconds(5), errorNumbersToAdd: null);
            });
        
        options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
        
        if (builder.Environment.IsDevelopment())
        {
            options.EnableSensitiveDataLogging();
        }
    });

    // Add Authentication
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                    builder.Configuration.GetSection("AppSettings:Token").Value!)),
                ValidateIssuer = false,
                ValidateAudience = false,
                NameClaimType = "unique_name",
                RoleClaimType = "role"
            };
        });

    // Add Authorization
    builder.Services.AddAuthorization();

    // Add CORS - Updated for SignalR
    builder.Services.AddCors(options =>
    {
        options.AddPolicy("AllowAll", policy =>
        {
            policy.SetIsOriginAllowed(_ => true) // Allow any origin for SignalR
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials(); // Required for SignalR
        });
    });

    // ===== SIGNALR CONFIGURATION =====
    builder.Services.AddSignalR(options =>
    {
        options.EnableDetailedErrors = builder.Environment.IsDevelopment();
        options.KeepAliveInterval = TimeSpan.FromSeconds(15);
        options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
    });
    
    // Register NotificationService for DI
    builder.Services.AddScoped<INotificationService, NotificationService>();

    builder.Services.AddMemoryCache(options =>
    {
        options.SizeLimit = 1024;
    });

    // Add Response Compression for better performance
    builder.Services.AddResponseCompression(options =>
    {
        options.EnableForHttps = true;
    });

    // Register services
    builder.Services.AddScoped<IAuthService, AuthService>();
    builder.Services.AddScoped<IPriorityScoringService, PriorityScoringService>(); // <-- Dòng này đã có
    builder.Services.AddScoped<IUserWeightService, UserWeightService>(); // <-- THÊM DÒNG NÀY
    builder.Services.AddScoped<IDatabaseSeeder, DatabaseSeeder>(); // <-- Database Seeder

    // Background Services
    builder.Services.AddHostedService<OverdueTaskService>();

    var app = builder.Build();

    // === Global Exception Middleware ===
    app.UseMiddleware<ExceptionMiddleware>();

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }
    else
    {
        app.UseHttpsRedirection();
    }

    app.UseResponseCompression();
    app.UseCors("AllowAll");

    app.UseAuthentication();
    app.UseAuthorization();

    app.MapControllers();
    
    // ===== MAP SIGNALR HUB =====
    app.MapHub<NotificationHub>("/notificationHub");

    // Apply any pending migrations and verify database connection
    try
    {
        using (var scope = app.Services.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<CollabTaskDbContext>();
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            
            // Check if database can connect
            if (await context.Database.CanConnectAsync())
            {
                logger.LogInformation("✅ Database connection successful");
                
                // Apply pending migrations if any
                var pendingMigrations = await context.Database.GetPendingMigrationsAsync();
                if (pendingMigrations.Any())
                {
                    logger.LogInformation("Applying {Count} pending migrations...", pendingMigrations.Count());
                    await context.Database.MigrateAsync();
                    logger.LogInformation("✅ Migrations applied successfully");
                }
            }
            else
            {
                logger.LogWarning("⚠️ Database connection failed - server will start but database operations may fail");
            }
        }
    }
    catch (Exception ex)
    {
        var logger = app.Services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "❌ Error during database initialization");
    }

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "❌ Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
