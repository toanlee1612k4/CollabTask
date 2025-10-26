using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class Tag
    {
        [Key]
        public int TagID { get; set; }

        [Required]
        public Guid WorkspaceID { get; set; }

        [Required]
        [MaxLength(50)]
        public string TagName { get; set; } = string.Empty;

        [MaxLength(7)]
        public string Color { get; set; } = "#CCCCCC";

        // Navigation properties
        [ForeignKey("WorkspaceID")]
        public virtual Workspace Workspace { get; set; } = null!;

        public virtual ICollection<TaskTag> TaskTags { get; set; } = new List<TaskTag>();
    }
}
