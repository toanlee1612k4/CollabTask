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

        /// <summary>
        /// Key Trait (đặc điểm làm việc) của user dựa trên weights
        /// Được tự động tính toán khi weights thay đổi
        /// </summary>
        public UserTrait DominantTrait { get; set; } = UserTrait.Unknown;

        // Navigation property
        [ForeignKey("UserID")]
        public User? User { get; set; }
    }
}