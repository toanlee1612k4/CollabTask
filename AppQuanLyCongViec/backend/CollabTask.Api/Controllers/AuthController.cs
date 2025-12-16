using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CollabTask.Api.Services.AuthService;
using CollabTask.Api.Dtos.Auth;
using CollabTask.Api.Models;
using CollabTask.Api.Dtos.Users; // Thêm using cho UserDto
using CollabTask.Api.Data;       // Thêm using cho DbContext
using Microsoft.EntityFrameworkCore; // Thêm using cho FindAsync

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly CollabTaskDbContext _context; // Inject DbContext

        // Sửa constructor để inject thêm DbContext
        public AuthController(IAuthService authService, CollabTaskDbContext context)
        {
            _authService = authService;
            _context = context; // Lưu lại DbContext
        }

        [HttpPost("register")]
        // Sửa kiểu trả về thành ActionResult<UserDto>
        public async Task<ActionResult<UserDto>> Register(UserRegisterDto request)
        {
            try
            {
                var user = await _authService.Register(request);

                // Lấy tên Role từ DbContext
                var role = await _context.SystemRoles.FindAsync(user.SystemRoleID);
                var roleName = role?.RoleName ?? "User"; // Lấy RoleName, mặc định là "User" nếu không tìm thấy

                // Tạo đối tượng DTO để trả về
                var userDto = new UserDto
                {
                    UserID = user.UserID,
                    FullName = user.FullName,
                    Email = user.Email,
                    RoleName = roleName, // Sử dụng RoleName đã lấy
                    CreatedAt = user.CreatedAt,
                    AvatarURL = user.AvatarURL
                };

                return Ok(userDto); // Trả về DTO thay vì User
            }
            catch (DbUpdateException ex)
            {
                return StatusCode(500, new { message = "Database error during registration", error = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred during registration", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        [HttpPost("login")]
        public async Task<ActionResult<string>> Login(UserLoginDto request)
        {
            try
            {
                var token = await _authService.Login(request);
                return Ok(new { token }); // Trả về token trong một object JSON
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred during login", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/auth/external-login
        // OAuth login với Google hoặc Facebook
        [HttpPost("external-login")]
        public async Task<ActionResult<object>> ExternalLogin([FromBody] ExternalLoginDto loginDto)
        {
            try
            {
                // TODO: Verify ID token với Google/Facebook API
                // For Google: Use Google.Apis.Auth.GoogleJsonWebSignature.ValidateAsync(idToken)
                // For Facebook: Call Facebook Graph API to verify token
                // For now, this is a placeholder structure that trusts the client

                if (string.IsNullOrEmpty(loginDto.Email))
                {
                    return BadRequest(new { message = "Email is required from OAuth provider" });
                }

                // Check if user already exists
                var existingUser = await _context.Users
                    .Include(u => u.SystemRole)
                    .FirstOrDefaultAsync(u => u.Email == loginDto.Email);

                User user;
                bool isNewUser = false;

                if (existingUser == null)
                {
                    // Create new user from OAuth data
                    var userRole = await _context.SystemRoles.FirstOrDefaultAsync(r => r.RoleName == "User");
                    if (userRole == null)
                    {
                        return StatusCode(500, new { message = "System role not found" });
                    }

                    user = new User
                    {
                        UserID = Guid.NewGuid(),
                        FullName = loginDto.FullName ?? loginDto.Email.Split('@')[0],
                        Email = loginDto.Email,
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()), // Random password
                        SystemRoleID = userRole.RoleID,
                        AvatarURL = loginDto.AvatarURL,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();
                    isNewUser = true;
                }
                else
                {
                    user = existingUser;

                    // Update avatar if provided and different
                    if (!string.IsNullOrEmpty(loginDto.AvatarURL) && user.AvatarURL != loginDto.AvatarURL)
                    {
                        user.AvatarURL = loginDto.AvatarURL;
                        await _context.SaveChangesAsync();
                    }
                }

                // Generate JWT token
                var token = _authService.GenerateToken(user);

                var userDto = new UserDto
                {
                    UserID = user.UserID,
                    FullName = user.FullName,
                    Email = user.Email,
                    RoleName = user.SystemRole?.RoleName ?? "User",
                    CreatedAt = user.CreatedAt,
                    AvatarURL = user.AvatarURL
                };

                return Ok(new
                {
                    token,
                    isNewUser,
                    user = userDto
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error during external login", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/auth/logout
        // Logout (client-side only - JWT is stateless)
        [HttpPost("logout")]
        [Authorize]
        public IActionResult Logout()
        {
            // JWT is stateless, so logout is handled client-side by removing the token
            // This endpoint exists for:
            // 1. Logging purposes
            // 2. Future token blacklist implementation
            // 3. Consistent API design

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;

            // Log the logout event (optional)
            // _logger.LogInformation($"User {userEmail} (ID: {userId}) logged out at {DateTime.UtcNow}");

            return Ok(new { message = "Logged out successfully. Please remove token from client storage." });
        }

        // Action này chỉ để kiểm tra xem xác thực có hoạt động không
        [HttpGet("test")]
        [Authorize] // Yêu cầu người dùng phải đăng nhập (gửi token) mới gọi được
        public IActionResult TestAuthentication()
        {
            // Lấy thông tin UserID từ token
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;

            if (userId == null)
            {
                return Unauthorized(); // Không nên xảy ra nếu [Authorize] hoạt động đúng
            }

            return Ok($"Authentication working! User ID from token: {userId}, Email: {userEmail}");
        }
    }
}