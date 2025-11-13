using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class UserTaskWeight
    {
        [Key]
        public Guid UserID { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal DeadlineWeight { get; set; } = 0.5m;

        [Column(TypeName = "decimal(5,2)")]
        public decimal ImportanceWeight { get; set; } = 0.3m;

        [Column(TypeName = "decimal(5,2)")]
        public decimal EffortWeight { get; set; } = 0.2m;

        public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        [ForeignKey("UserID")]
        public User? User { get; set; }
    }
}