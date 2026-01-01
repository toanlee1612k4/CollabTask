using System.Net;
using System.Text.Json;

namespace CollabTask.Api.Middleware
{
    /// <summary>
    /// Global Exception Handler Middleware
    /// Bắt toàn bộ exception và trả về format JSON chuẩn
    /// </summary>
    public class ExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionMiddleware> _logger;
        private readonly IHostEnvironment _env;

        public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger, IHostEnvironment env)
        {
            _next = next;
            _logger = logger;
            _env = env;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Unhandled exception occurred: {Message}", ex.Message);
                await HandleExceptionAsync(context, ex);
            }
        }

        private Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            context.Response.ContentType = "application/json";
            
            var statusCode = exception switch
            {
                UnauthorizedAccessException => (int)HttpStatusCode.Unauthorized,
                KeyNotFoundException => (int)HttpStatusCode.NotFound,
                ArgumentException => (int)HttpStatusCode.BadRequest,
                InvalidOperationException => (int)HttpStatusCode.BadRequest,
                _ => (int)HttpStatusCode.InternalServerError
            };

            context.Response.StatusCode = statusCode;

            var response = new ErrorResponse
            {
                StatusCode = statusCode,
                Message = GetUserFriendlyMessage(exception),
                Detail = _env.IsDevelopment() ? exception.StackTrace : null
            };

            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = true
            };

            return context.Response.WriteAsync(JsonSerializer.Serialize(response, options));
        }

        private string GetUserFriendlyMessage(Exception exception)
        {
            return exception switch
            {
                UnauthorizedAccessException => "Bạn không có quyền truy cập tài nguyên này.",
                KeyNotFoundException => "Không tìm thấy tài nguyên yêu cầu.",
                ArgumentException => exception.Message,
                InvalidOperationException => exception.Message,
                _ => _env.IsDevelopment() 
                    ? exception.Message 
                    : "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau."
            };
        }
    }

    /// <summary>
    /// Format JSON response cho error
    /// </summary>
    public class ErrorResponse
    {
        public int StatusCode { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? Detail { get; set; }
    }
}
