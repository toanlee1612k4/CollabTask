using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class Comment
    {
        [Key]
        public Guid CommentID { get; set; }

        [Required]
        public Guid TaskID { get; set; }

        [Required]
        public Guid UserID { get; set; }

        [Required]
        public string Content { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;

        [ForeignKey("UserID")]
        public virtual User User { get; set; } = null!;
    }
}
