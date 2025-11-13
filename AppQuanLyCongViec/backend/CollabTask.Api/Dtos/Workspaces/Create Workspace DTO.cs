using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Workspaces
{
    public class CreateWorkspaceDto
    {
        [Required]
        [MaxLength(150)]
        public string WorkspaceName { get; set; } = string.Empty;

        public string? Description { get; set; }
    }
}