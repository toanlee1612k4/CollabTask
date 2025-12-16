using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    public class TaskAttachment
    {
        [Key]
        public Guid AttachmentID { get; set; }

        [Required]
        public Guid TaskID { get; set; }

        [Required]
        public Guid UploadedByUserID { get; set; }

        [Required]
        [MaxLength(255)]
        public string FileName { get; set; } = string.Empty;

        [Required]
        [MaxLength(500)]
        public string FilePath { get; set; } = string.Empty; // Relative path on server

        [MaxLength(100)]
        public string? FileType { get; set; } // MIME type: image/png, application/pdf

        public long FileSize { get; set; } // Size in bytes

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("TaskID")]
        public virtual Task Task { get; set; } = null!;

        [ForeignKey("UploadedByUserID")]
        public virtual User UploadedBy { get; set; } = null!;
    }
}
