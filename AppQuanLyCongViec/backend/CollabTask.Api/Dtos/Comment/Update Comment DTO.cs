using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Comments
{
    public class UpdateCommentDto
    {
        [Required]
        public string Content { get; set; } = string.Empty;
    }
}
