using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Workspaces
{
    public class UpdateMemberRoleDto
    {
        [Required]
        // Thêm validation để đảm bảo Role hợp lệ ('ProjectManager', 'Member') nếu cần
        public string NewRole { get; set; } = string.Empty;
    }
}
