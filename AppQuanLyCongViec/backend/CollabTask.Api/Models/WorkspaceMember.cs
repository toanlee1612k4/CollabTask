using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class WorkspaceMember
    {
        [Key]
        [Column(Order = 0)]
        public Guid WorkspaceID { get; set; }

        [Key]
        [Column(Order = 1)]
        public Guid UserID { get; set; }

        [Required]
        [MaxLength(50)]
        public string Role { get; set; } = "Member";

        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("WorkspaceID")]
        public virtual Workspace Workspace { get; set; } = null!;

        [ForeignKey("UserID")]
        public virtual User User { get; set; } = null!;
    }
}
