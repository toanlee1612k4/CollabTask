// File: Models/Role.cs
using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Models
{
    public class SystemRole
    {
        [Key]
        public int RoleID { get; set; }

        [Required]
        [MaxLength(50)]
        public string RoleName { get; set; } = string.Empty;

        // Navigation properties
        public virtual ICollection<User> Users { get; set; } = new List<User>();
    }
}