namespace CollabTask.Api.Dtos.Tasks
{
    public class TaskDto
    {
        public Guid TaskId { get; set; } // Lỗi CS0117 xảy ra vì thiếu các thuộc tính này (do file gốc bị lỗi)
        public Guid WorkspaceId { get; set; }
        public string Title { get; set; } = string.Empty; // Gán mặc định để hết warning
        public string? Description { get; set; }
        public string Status { get; set; } = string.Empty; // Gán mặc định để hết warning
        public string Priority { get; set; } = string.Empty; // Gán mặc định để hết warning
        public DateTime? Deadline { get; set; }
        public int? EstimatedTimeMinutes { get; set; }
        public Guid CreatorUserId { get; set; } // Lỗi CS0117 xảy ra vì thiếu thuộc tính này
        public DateTime CreatedAt { get; set; } 
        // DÒNG "CreatedAt" BỊ TRÙNG LẶP ĐÃ ĐƯỢC XÓA BỎ (Lỗi CS0102)

        public DateTime? CompletedAt { get; set; } 
        public List<Guid> AssigneeUserIds { get; set; } = new List<Guid>(); 
        public decimal? PriorityScore { get; set; } // Lỗi CS0103 xảy ra vì thiếu thuộc tính này

        /// <summary>
        /// Lý do tại sao task này được gợi ý (Explainability)
        /// VD: "Task này được gợi ý vì bạn là 'The Sprinter' và task này chỉ tốn 30 phút."
        /// </summary>
        public string? RecommendationReason { get; set; }

        /// <summary>
        /// Key Trait phù hợp với task này (Sprinter, Procrastinator, Planner)
        /// </summary>
        public string? MatchedTrait { get; set; }
    }
}