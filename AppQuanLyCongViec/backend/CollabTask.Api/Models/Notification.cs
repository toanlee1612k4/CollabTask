using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class Notification
    {
        [Key]
        public Guid NotificationID { get; set; }

        [Required]
        public Guid UserID { get; set; }

        [Required]
        [MaxLength(512)]
        public string Message { get; set; } = string.Empty;

        public bool IsRead { get; set; } = false;

        [MaxLength(512)]
        public string? Link { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("UserID")]
        public virtual User User { get; set; } = null!;
    }
}
