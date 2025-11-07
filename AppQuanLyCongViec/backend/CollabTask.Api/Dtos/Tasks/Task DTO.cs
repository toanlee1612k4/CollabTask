namespace CollabTask.Api.Dtos.Tasks
{
    public class TaskDto
    {
        public Guid TaskID { get; set; }
        public Guid WorkspaceID { get; set; }
        public string Title { get; set; }
        public string? Description { get; set; }
        public string Status { get; set; }
        public string Priority { get; set; }
        public DateTime? Deadline { get; set; }
        public int? EstimatedTimeMinutes { get; set; }
        public Guid CreatorUserID { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public List<Guid> AssigneeUserIds { get; set; } = new List<Guid>();
        public decimal? PriorityScore { get; set; }

    }
}
