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
            return newUser;
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