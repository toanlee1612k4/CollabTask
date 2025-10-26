namespace CollabTask.Api.Dtos.ActivityLogs
{
    public class ActivityLogDto
    {
        public Guid LogId { get; set; }
        public Guid UserId { get; set; }
        public string? UserFullName { get; set; } // Tên người thực hiện
        public string Action { get; set; } = string.Empty;
        public string? EntityType { get; set; }
        public Guid? EntityId { get; set; }
        public DateTime Timestamp { get; set; }
    }
}
