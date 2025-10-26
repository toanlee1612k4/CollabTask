using System.ComponentModel.DataAnnotations;

// THÊM NAMESPACE ĐỂ KHAI BÁO KHÔNG GIAN TÊN
namespace CollabTask.Api.Dtos.Auth
{
    public class UserLoginDto
    {
        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }
}