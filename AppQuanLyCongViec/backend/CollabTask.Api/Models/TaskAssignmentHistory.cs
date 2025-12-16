using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class TaskAssignmentHistory
    {
        [Key]
        public Guid HistoryID { get; set; }
        
        [Required]
        public Guid TaskID { get; set; }
        
        [Required]
        public Guid AssigneeUserID { get; set; }
        
        public Guid? PreviousAssigneeUserID { get; set; }
        
        [Required]
        public Guid ActionByUserID { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Action { get; set; } = string.Empty; // Assigned, Accepted, Rejected, StatusChanged, Transferred, CompletionRequested, Approved
        
        [MaxLength(50)]
        public string? PreviousStatus { get; set; }
        
        [MaxLength(50)]
        public string? NewStatus { get; set; }
        
        public string? Note { get; set; }
        
        public DateTime ActionAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;
        
        [ForeignKey("AssigneeUserID")]
        public virtual User Assignee { get; set; } = null!;
        
        [ForeignKey("PreviousAssigneeUserID")]
        public virtual User? PreviousAssignee { get; set; }
        
        [ForeignKey("ActionByUserID")]
        public virtual User ActionBy { get; set; } = null!;
    }
}
