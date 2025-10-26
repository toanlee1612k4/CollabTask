using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tasks
{
    public class CreateTaskDto
    {
        [Required]
        [MaxLength(255)]
        public string Title { get; set; }

        public string? Description { get; set; }

        [Required]
        public string Priority { get; set; } = "Medium";
        
        public DateTime? Deadline { get; set; }
        
        public int? EstimatedTimeMinutes { get; set; }
    }
}
