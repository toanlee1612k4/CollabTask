using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tags
{
    public class UpdateTagDto
    {
        [Required]
        [MaxLength(50)]
        public string TagName { get; set; } = string.Empty;

        [MaxLength(7)]
        public string Color { get; set; } = "#CCCCCC";
    }
}
