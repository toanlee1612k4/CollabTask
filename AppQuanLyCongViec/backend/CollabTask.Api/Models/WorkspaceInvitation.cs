using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CollabTask.Api.Models
{
    /// <summary>
    /// Represents an invitation to join a workspace.
    /// Supports the workflow: Send → Pending → Accept/Reject
    /// </summary>
    public class WorkspaceInvitation
    {
        [Key]
        public Guid InvitationID { get; set; }

        [Required]
        public Guid WorkspaceID { get; set; }

        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// The role the user will have if they accept the invitation
        /// </summary>
        [Required]
        [MaxLength(50)]
        public string Role { get; set; } = "Member"; // Member, ProjectManager

        /// <summary>
        /// Current status of the invitation
        /// </summary>
        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, Cancelled

        /// <summary>
        /// User who sent the invitation (Owner or ProjectManager)
        /// </summary>
        [Required]
        public Guid InvitedByUserID { get; set; }

        /// <summary>
        /// When the invitation was created
        /// </summary>
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// When the user responded to the invitation (accepted/rejected)
        /// </summary>
        public DateTime? RespondedAt { get; set; }

        /// <summary>
        /// Optional message from the inviter
        /// </summary>
        [MaxLength(500)]
        public string? Message { get; set; }

        // Navigation properties
        [ForeignKey(nameof(WorkspaceID))]
        public Workspace Workspace { get; set; } = null!;

        [ForeignKey(nameof(InvitedByUserID))]
        public User InvitedBy { get; set; } = null!;
    }

    /// <summary>
    /// Invitation status enum for type safety
    /// </summary>
    public static class InvitationStatus
    {
        public const string Pending = "Pending";
        public const string Accepted = "Accepted";
        public const string Rejected = "Rejected";
        public const string Cancelled = "Cancelled";
    }
}
