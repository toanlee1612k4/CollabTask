using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class TaskAssignment
    {
        [Key]
        [Column(Order = 0)]
        public Guid TaskID { get; set; }

        [Key]
        [Column(Order = 1)]
        public Guid AssigneeUserID { get; set; }

        public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;

        [ForeignKey("AssigneeUserID")]
        public virtual User Assignee { get; set; } = null!;
    }
}
