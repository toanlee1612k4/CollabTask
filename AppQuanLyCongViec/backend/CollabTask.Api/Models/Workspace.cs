using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class Workspace
    {
        [Key]
        public Guid WorkspaceID { get; set; }

        [Required]
        [MaxLength(150)]
        public string WorkspaceName { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public Guid OwnerUserID { get; set; }

        public bool IsPersonal { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("OwnerUserID")]
        public virtual User Owner { get; set; } = null!;

        public virtual ICollection<WorkspaceMember> Members { get; set; } = new List<WorkspaceMember>();
        public virtual ICollection<Task> Tasks { get; set; } = new List<Task>();
        public virtual ICollection<Tag> Tags { get; set; } = new List<Tag>();
    }
}
