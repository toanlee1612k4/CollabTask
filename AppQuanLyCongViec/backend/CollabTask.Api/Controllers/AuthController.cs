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
            catch (Exception ex)
            {
                // Nên log lỗi ra console hoặc hệ thống logging
                // Console.WriteLine($"Error during registration: {ex.Message}");
                return BadRequest(ex.Message);
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
            catch (Exception ex)
            {
                // Nên log lỗi
                return BadRequest(ex.Message);
            }
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