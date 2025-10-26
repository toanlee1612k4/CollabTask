namespace CollabTask.Api.Dtos.Workspaces
{
    public class MemberDto
    {
        public Guid UserId { get; set; }
        public string? FullName { get; set; } // Lấy từ User
        public string Email { get; set; } = string.Empty; // Lấy từ User
        public string? AvatarUrl { get; set; } // Lấy từ User
        public string Role { get; set; } = string.Empty; // Vai trò trong Workspace
        public DateTime JoinedAt { get; set; }
    }
}
