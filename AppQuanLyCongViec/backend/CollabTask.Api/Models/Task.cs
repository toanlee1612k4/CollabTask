using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class Task
    {
        [Key]
        public Guid TaskID { get; set; }

        [Required]
        public Guid WorkspaceID { get; set; }

        [Required]
        [MaxLength(255)]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "ToDo";

        [Required]
        [MaxLength(50)]
        public string Priority { get; set; } = "Medium";

        public DateTime? Deadline { get; set; }

        public int? EstimatedTimeMinutes { get; set; }

        [Required]
        public Guid CreatorUserID { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? CompletedAt { get; set; }

        // Navigation properties
        [ForeignKey("WorkspaceID")]
        public virtual Workspace Workspace { get; set; } = null!;

        [ForeignKey("CreatorUserID")]
        public virtual User Creator { get; set; } = null!;

        public virtual ICollection<TaskAssignment> TaskAssignments { get; set; } = new List<TaskAssignment>();
        public virtual ICollection<TaskTag> TaskTags { get; set; } = new List<TaskTag>();
        public virtual ICollection<Comment> Comments { get; set; } = new List<Comment>();
    }
}
