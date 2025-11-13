using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    [Table("UserInteractionsForAI")] // Map tới bảng UserInteractionsForAI trong DB
    public class UserTaskCompletionLog
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long InteractionID { get; set; }

        [Required]
        public Guid UserID { get; set; }

        [Required]
        public Guid TaskID { get; set; }

        [Required]
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
        public User? User { get; set; }

        [ForeignKey("TaskID")]
        public Task? Task { get; set; }
    }
}