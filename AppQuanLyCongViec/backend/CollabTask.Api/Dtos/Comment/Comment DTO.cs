namespace CollabTask.Api.Dtos.Comments
{
    public class CommentDto
    {
        public Guid CommentId { get; set; }
        public Guid TaskId { get; set; }
        public Guid UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty; // Display user name
        public string? UserAvatarUrl { get; set; } // Display avatar
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
