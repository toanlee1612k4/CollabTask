using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Tasks
{
    // DTO này dùng cho API PUT /api/tasks/{id} (sửa thông tin chung)
    // Lỗi CS0246 xảy ra vì file này bị thiếu
    public class UpdateTaskDto
    {
        [Required]
        [MaxLength(255)]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public string Priority { get; set; } = "Medium";
        
        public DateTime? Deadline { get; set; }
        
        public int? EstimatedTimeMinutes { get; set; }

        // Cho phép cập nhật danh sách người được gán
        public List<Guid>? AssigneeUserIds { get; set; }
    }
}