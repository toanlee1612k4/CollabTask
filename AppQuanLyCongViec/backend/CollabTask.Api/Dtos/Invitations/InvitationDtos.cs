using System.ComponentModel.DataAnnotations;

namespace CollabTask.Api.Dtos.Invitations
{
    /// <summary>
    /// DTO for creating a new workspace invitation
    /// </summary>
    public class CreateInvitationDto
    {
        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Role is required")]
        [RegularExpression("^(Member|ProjectManager)$", ErrorMessage = "Role must be Member or ProjectManager")]
        public string Role { get; set; } = "Member";

        [MaxLength(500, ErrorMessage = "Message cannot exceed 500 characters")]
        public string? Message { get; set; }
    }

    /// <summary>
    /// DTO for invitation response
    /// </summary>
    public class InvitationDto
    {
        public Guid InvitationID { get; set; }
        public Guid WorkspaceID { get; set; }
        public string WorkspaceName { get; set; } = string.Empty;
        public string WorkspaceDescription { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public InviterDto InvitedBy { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public DateTime? RespondedAt { get; set; }
        public string? Message { get; set; }
    }

    /// <summary>
    /// DTO for the user who sent the invitation
    /// </summary>
    public class InviterDto
    {
        public Guid UserID { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? AvatarURL { get; set; }
    }

    /// <summary>
    /// DTO for accepting an invitation
    /// </summary>
    public class AcceptInvitationDto
    {
        public Guid InvitationID { get; set; }
    }

    /// <summary>
    /// DTO for rejecting an invitation
    /// </summary>
    public class RejectInvitationDto
    {
        public Guid InvitationID { get; set; }
        public string? Reason { get; set; }
    }

    /// <summary>
    /// DTO for invitation response after accept/reject
    /// </summary>
    public class InvitationResponseDto
    {
        public string Message { get; set; } = string.Empty;
        public WorkspaceInfoDto? Workspace { get; set; }
    }

    /// <summary>
    /// DTO for workspace info in invitation response
    /// </summary>
    public class WorkspaceInfoDto
    {
        public Guid WorkspaceID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public int MemberCount { get; set; }
    }
}
