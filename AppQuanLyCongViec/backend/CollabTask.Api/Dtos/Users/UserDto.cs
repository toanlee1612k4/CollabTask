    namespace CollabTask.Api.Dtos.Users
    {
        public class UserDto
        {
            public Guid UserID { get; set; }
            public string? FullName { get; set; }
            public string Email { get; set; } = string.Empty;
            public string RoleName { get; set; } = string.Empty; // Chỉ lấy tên Role
            public DateTime CreatedAt { get; set; }
            public string? AvatarURL { get; set; }
        }
    }
    