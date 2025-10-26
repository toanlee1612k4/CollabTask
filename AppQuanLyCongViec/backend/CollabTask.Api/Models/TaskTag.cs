using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class TaskTag
    {
        [Key]
        [Column(Order = 0)]
        public Guid TaskID { get; set; }

        [Key]
        [Column(Order = 1)]
        public int TagID { get; set; }

        // Navigation properties
        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;

        [ForeignKey("TagID")]
        public virtual Tag Tag { get; set; } = null!;
    }
}
