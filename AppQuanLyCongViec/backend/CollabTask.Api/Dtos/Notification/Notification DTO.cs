namespace CollabTask.Api.Dtos.Notifications
{
    public class NotificationDto
    {
        public Guid NotificationId { get; set; }
        public string Message { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public string? Link { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
