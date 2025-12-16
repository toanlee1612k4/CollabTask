using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tasks
{
    public class AssignTaskDto
    {
        [Required]
        public Guid AssigneeUserId { get; set; }
    }
}
