using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public enum TaskAssignmentStatus
    {
        Pending,        // Task assigned, waiting for assignee response
        Accepted,       // Assignee accepted the task
        Rejected,       // Assignee rejected the task (needs PM approval)
        InProgress,     // Assignee is working on the task
        CompletionRequested, // Assignee requested completion approval
        Approved        // PM approved the completion
    }

    public class TaskAssignment
    {
        [Key]
        [Column(Order = 0)]
        public Guid TaskID { get; set; }

        [Key]
        [Column(Order = 1)]
        public Guid AssigneeUserID { get; set; }

        public Guid AssignerUserID { get; set; }
        
        public TaskAssignmentStatus Status { get; set; } = TaskAssignmentStatus.Pending;

        public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? ResponseAt { get; set; }
        
        public string? ResponseNote { get; set; }
        
        public DateTime? CompletionRequestedAt { get; set; }
        
        public DateTime? ApprovedAt { get; set; }
        
        public Guid? ApprovedByUserId { get; set; }
        
        public string? ApprovalNote { get; set; }

        // Navigation properties
        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;

        [ForeignKey("AssigneeUserID")]
        public virtual User Assignee { get; set; } = null!;
        
        [ForeignKey("AssignerUserID")]
        public virtual User Assigner { get; set; } = null!;
        
        [ForeignKey("ApprovedByUserId")]
        public virtual User? ApprovedBy { get; set; }
    }
}
