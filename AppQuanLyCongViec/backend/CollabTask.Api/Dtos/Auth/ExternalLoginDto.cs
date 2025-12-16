using CollabTask.Api.Dtos.Users;

namespace CollabTask.Api.Dtos.Auth
{
    public class ExternalLoginDto
    {
        public string Provider { get; set; } = string.Empty; // "google" or "facebook"
        public string IdToken { get; set; } = string.Empty;  // ID token from provider
        public string? Email { get; set; }
        public string? FullName { get; set; }
        public string? AvatarURL { get; set; }
    }

    public class ExternalLoginResultDto
    {
        public string Token { get; set; } = string.Empty;  // JWT token
        public bool IsNewUser { get; set; }  // true if registered, false if existing user
        public UserDto User { get; set; } = null!;
    }
}
