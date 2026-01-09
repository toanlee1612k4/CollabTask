using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Auth;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace CollabTask.Api.Services.AuthService
{
    public class AuthService : IAuthService
    {
        private readonly CollabTaskDbContext _context;
        private readonly IConfiguration _configuration;
        private const string DefaultUserRole = "User";

        public AuthService(CollabTaskDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public async Task<User> Register(UserRegisterDto request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new Exception("Địa chỉ email này đã được sử dụng.");
            }

            var userRole = await _context.SystemRoles.SingleOrDefaultAsync(r => r.RoleName == DefaultUserRole);
            if (userRole == null)
            {
                throw new InvalidOperationException($"Vai trò mặc định '{DefaultUserRole}' không tồn tại trong CSDL.");
            }

            // === SỬ DỤNG EXECUTION STRATEGY VỚI TRANSACTION ĐỂ ĐẢM BẢO DATA INTEGRITY ===
            var strategy = _context.Database.CreateExecutionStrategy();
            
            return await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

                    var newUser = new User
                    {
                        UserID = Guid.NewGuid(),
                        FullName = request.FullName,
                        Email = request.Email,
                        PasswordHash = passwordHash,
                        SystemRoleID = userRole.RoleID,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.Users.Add(newUser);
                    await _context.SaveChangesAsync();

                    // === KHỞI TẠO USER TRAITS MẶC ĐỊNH ===
                    // Tạo UserTaskWeight với giá trị mặc định cho user mới
                    var userWeight = new UserTaskWeight
                    {
                        UserID = newUser.UserID,
                        DeadlineWeight = 0.5m,      // 50% ưu tiên deadline
                        ImportanceWeight = 0.3m,    // 30% ưu tiên độ quan trọng
                        EffortWeight = 0.2m,        // 20% ưu tiên độ nhanh (effort thấp)
                        DominantTrait = UserTrait.Unknown, // Chưa đủ dữ liệu để phân loại
                        LastUpdatedAt = DateTime.UtcNow
                    };

                    _context.UserTaskWeights.Add(userWeight);
                    await _context.SaveChangesAsync();

                    // Commit transaction nếu tất cả thành công
                    await transaction.CommitAsync();

                    return newUser;
                }
                catch (Exception)
                {
                    // Rollback nếu có lỗi (xóa luôn User đã tạo)
                    await transaction.RollbackAsync();
                    throw; // Re-throw exception để controller xử lý
                }
            });
        }

        public async Task<string> Login(UserLoginDto request)
        {
            var user = await _context.Users
                .Include(u => u.SystemRole) // Lấy kèm thông tin SystemRole
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                throw new Exception("Email hoặc mật khẩu không chính xác.");
            }

            return CreateToken(user);
        }

        // Public method to generate token for external login
        public string GenerateToken(User user)
        {
            return CreateToken(user);
        }

        private string CreateToken(User user)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                new Claim(ClaimTypes.Name, user.FullName ?? string.Empty),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.SystemRole?.RoleName ?? string.Empty) // Thêm vai trò vào token
            };

            var secretKey = _configuration.GetSection("AppSettings:Token").Value;
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512Signature);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.Now.AddDays(1),
                SigningCredentials = creds
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }
    }
}