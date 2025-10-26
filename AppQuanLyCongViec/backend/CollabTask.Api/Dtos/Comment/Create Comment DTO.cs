using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Comments
{
    public class CreateCommentDto
    {
        [Required]
        public string Content { get; set; } = string.Empty;
    }
}
