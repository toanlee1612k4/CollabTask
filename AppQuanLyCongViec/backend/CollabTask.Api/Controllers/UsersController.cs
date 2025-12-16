using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Users;
using CollabTask.Api.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public UsersController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // GET: api/users/me
        [HttpGet("me")]
        public async Task<ActionResult<UserDto>> GetCurrentUser()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var user = await _context.Users
                .Include(u => u.SystemRole)
                .FirstOrDefaultAsync(u => u.UserID == userId);

            if (user == null) return NotFound();

            var userDto = new UserDto
            {
                UserID = user.UserID,
                FullName = user.FullName,
                Email = user.Email,
                RoleName = user.SystemRole?.RoleName ?? "User",
                CreatedAt = user.CreatedAt,
                AvatarURL = user.AvatarURL
            };

            return Ok(userDto);
        }

        // GET: api/users/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetUserById(Guid id)
        {
            var user = await _context.Users
                .Include(u => u.SystemRole)
                .FirstOrDefaultAsync(u => u.UserID == id);

            if (user == null) return NotFound();

            var userDto = new UserDto
            {
                UserID = user.UserID,
                FullName = user.FullName,
                Email = user.Email,
                RoleName = user.SystemRole?.RoleName ?? "User",
                CreatedAt = user.CreatedAt,
                AvatarURL = user.AvatarURL
            };

            return Ok(userDto);
        }

        // PUT: api/users/me
        [HttpPut("me")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserDto updateDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound();

            // Cập nhật thông tin
            if (!string.IsNullOrWhiteSpace(updateDto.FullName))
            {
                user.FullName = updateDto.FullName;
            }

            if (!string.IsNullOrWhiteSpace(updateDto.AvatarURL))
            {
                user.AvatarURL = updateDto.AvatarURL;
            }

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/users/search?email={email}
        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<UserDto>>> SearchUsersByEmail([FromQuery] string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return BadRequest("Email query parameter is required.");
            }

            var users = await _context.Users
                .Where(u => u.Email.Contains(email))
                .Take(10) // Giới hạn kết quả
                .Select(u => new UserDto
                {
                    UserID = u.UserID,
                    FullName = u.FullName,
                    Email = u.Email,
                    AvatarURL = u.AvatarURL
                })
                .ToListAsync();

            return Ok(users);
        }
    }
}
