using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tags
{
    public class CreateTagDto
    {
        [Required]
        [MaxLength(50)]
        public string TagName { get; set; } = string.Empty;

        [MaxLength(7)] // e.g., #RRGGBB
        public string Color { get; set; } = "#CCCCCC";
    }
}
