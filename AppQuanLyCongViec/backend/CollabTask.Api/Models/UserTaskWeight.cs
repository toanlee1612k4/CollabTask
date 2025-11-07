using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class UserTaskWeight
    {
        [Key]
        public Guid UserID { get; set; } // Khóa chính cũng là khóa ngoại

        [Column(TypeName = "decimal(5, 2)")]
        public decimal DeadlineWeight { get; set; } = 0.5m; // W_D

        [Column(TypeName = "decimal(5, 2)")]
        public decimal ImportanceWeight { get; set; } = 0.3m; // W_I

        [Column(TypeName = "decimal(5, 2)")]
        public decimal EffortWeight { get; set; } = 0.2m; // W_E

        public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        [ForeignKey("UserID")]
        public virtual User User { get; set; } = null!;
    }
}