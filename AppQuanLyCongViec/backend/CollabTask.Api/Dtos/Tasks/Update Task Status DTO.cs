using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tasks
{
    public class UpdateTaskStatusDto
    {
        [Required]
        // You might want to add validation here to ensure it's one of the allowed statuses
        public string NewStatus { get; set; } = string.Empty; 
    }
}
