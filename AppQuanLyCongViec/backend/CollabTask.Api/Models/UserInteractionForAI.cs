using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class UserInteractionForAI
    {
        [Key]
        public long InteractionID { get; set; }

        [Required]
        public Guid UserID { get; set; }

        [Required]
        public Guid TaskID { get; set; }

        public DateTime CompletedTimestamp { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal DeadlineScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal ImportanceScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal EffortScore { get; set; }

        public bool? WasSuggested { get; set; }

        // Navigation properties
        [ForeignKey("UserID")]
        public virtual User User { get; set; } = null!;

        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;
    }
}
