namespace CollabTask.Api.Dtos.Tasks
{
    public class AssignTaskRequestDto
    {
        public List<Guid> AssigneeUserIds { get; set; } = new List<Guid>();
        public string? Note { get; set; }
    }
    
    public class RespondToAssignmentDto
    {
        public bool Accept { get; set; } // true = Accept, false = Reject
        public string? Note { get; set; }
    }
    
    public class RequestTaskCompletionDto
    {
        public string? Note { get; set; }
    }
    
    public class ApproveTaskCompletionDto
    {
        public bool Approve { get; set; } // true = Approve, false = Reject
        public string? Note { get; set; }
    }
    
    public class TaskAssignmentDto
    {
        public Guid TaskID { get; set; }
        public Guid AssigneeUserID { get; set; }
        public string AssigneeName { get; set; } = string.Empty;
        public string AssigneeEmail { get; set; } = string.Empty;
        public Guid AssignerUserID { get; set; }
        public string AssignerName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime AssignedAt { get; set; }
        public DateTime? ResponseAt { get; set; }
        public string? ResponseNote { get; set; }
        public DateTime? CompletionRequestedAt { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public Guid? ApprovedByUserId { get; set; }
        public string? ApprovedByName { get; set; }
        public string? ApprovalNote { get; set; }
    }
    
    public class TaskAssignmentHistoryDto
    {
        public Guid HistoryID { get; set; }
        public Guid TaskID { get; set; }
        public string TaskTitle { get; set; } = string.Empty;
        public Guid AssigneeUserID { get; set; }
        public string AssigneeName { get; set; } = string.Empty;
        public Guid? PreviousAssigneeUserID { get; set; }
        public string? PreviousAssigneeName { get; set; }
        public Guid ActionByUserID { get; set; }
        public string ActionByName { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty;
        public string? PreviousStatus { get; set; }
        public string? NewStatus { get; set; }
        public string? Note { get; set; }
        public DateTime ActionAt { get; set; }
    }
}
