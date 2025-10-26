using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tasks
{
    public class AssignTaskDto
    {
        [Required]
        public List<Guid> AssigneeUserIds { get; set; } = new List<Guid>();
    }
}
