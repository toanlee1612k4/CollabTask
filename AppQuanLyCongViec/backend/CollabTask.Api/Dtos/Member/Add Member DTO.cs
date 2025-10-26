using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Workspaces
{
    public class AddMemberDto
    {
        [Required]
        [EmailAddress]
        public string UserEmailToAdd { get; set; } = string.Empty; // Dùng Email để mời/thêm

        [Required]
        public string Role { get; set; } = "Member"; // Vai trò mặc định khi thêm
    }
}
