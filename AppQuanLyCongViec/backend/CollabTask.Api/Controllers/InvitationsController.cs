using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Invitations;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [Route("api/workspaces")]
    [ApiController]
    [Authorize]
    public class InvitationsController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public InvitationsController(CollabTaskDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Send an invitation to join a workspace
        /// </summary>
        [HttpPost("{workspaceId}/invitations")]
        public async Task<ActionResult<InvitationDto>> SendInvitation(
            Guid workspaceId,
            [FromBody] CreateInvitationDto createDto)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId == Guid.Empty) return Unauthorized();

            // Check if workspace exists
            var workspace = await _context.Workspaces.FindAsync(workspaceId);
            if (workspace == null)
                return NotFound(new { message = "Workspace not found" });

            // Check if current user is Owner or ProjectManager
            var currentMember = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == currentUserId);

            if (currentMember == null)
                return Forbid();

            if (currentMember.Role != "Owner" && currentMember.Role != "ProjectManager")
                return StatusCode(403, new { message = "Only Owner or ProjectManager can send invitations" });

            // Check if user with this email exists
            var inviteeUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == createDto.Email);

            if (inviteeUser == null)
                return BadRequest(new { message = "User with this email does not exist in the system. They need to register first." });

            // Check if user is already a member
            var existingMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == inviteeUser.UserID);

            if (existingMember)
                return BadRequest(new { message = "User is already a member of this workspace" });

            // Check if there's already a pending invitation
            var existingInvitation = await _context.WorkspaceInvitations
                .FirstOrDefaultAsync(wi => wi.WorkspaceID == workspaceId
                    && wi.Email == createDto.Email
                    && wi.Status == InvitationStatus.Pending);

            if (existingInvitation != null)
                return BadRequest(new { message = "There is already a pending invitation for this user" });

            // Create invitation
            var invitation = new WorkspaceInvitation
            {
                InvitationID = Guid.NewGuid(),
                WorkspaceID = workspaceId,
                Email = createDto.Email,
                Role = createDto.Role,
                Status = InvitationStatus.Pending,
                InvitedByUserID = currentUserId,
                Message = createDto.Message,
                CreatedAt = DateTime.UtcNow
            };

            _context.WorkspaceInvitations.Add(invitation);

            // Create notification for invitee
            var notification = new Notification
            {
                NotificationID = Guid.NewGuid(),
                UserID = inviteeUser.UserID,
                Message = $"You have been invited to join workspace '{workspace.WorkspaceName}'",
                RelatedEntityType = "WorkspaceInvitation",
                RelatedEntityID = invitation.InvitationID,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Load navigation properties for response
            await _context.Entry(invitation).Reference(i => i.InvitedBy).LoadAsync();
            await _context.Entry(invitation).Reference(i => i.Workspace).LoadAsync();

            var responseDto = new InvitationDto
            {
                InvitationID = invitation.InvitationID,
                WorkspaceID = invitation.WorkspaceID,
                WorkspaceName = invitation.Workspace.WorkspaceName,
                WorkspaceDescription = invitation.Workspace.Description ?? "",
                Email = invitation.Email,
                Role = invitation.Role,
                Status = invitation.Status,
                InvitedBy = new InviterDto
                {
                    UserID = invitation.InvitedBy.UserID,
                    FullName = invitation.InvitedBy.FullName ?? invitation.InvitedBy.Email,
                    Email = invitation.InvitedBy.Email,
                    AvatarURL = invitation.InvitedBy.AvatarURL
                },
                CreatedAt = invitation.CreatedAt,
                Message = invitation.Message
            };

            return CreatedAtAction(nameof(GetMyInvitations), new { }, responseDto);
        }

        /// <summary>
        /// Get all pending invitations for the current user
        /// </summary>
        [HttpGet("invitations")]
        public async Task<ActionResult<IEnumerable<InvitationDto>>> GetMyInvitations()
        {
            var currentUserId = User.GetUserId();
            if (currentUserId == Guid.Empty) return Unauthorized();

            var currentUser = await _context.Users.FindAsync(currentUserId);
            if (currentUser == null) return Unauthorized();

            var invitations = await _context.WorkspaceInvitations
                .Include(wi => wi.Workspace)
                .Include(wi => wi.InvitedBy)
                .Where(wi => wi.Email == currentUser.Email && wi.Status == InvitationStatus.Pending)
                .OrderByDescending(wi => wi.CreatedAt)
                .Select(wi => new InvitationDto
                {
                    InvitationID = wi.InvitationID,
                    WorkspaceID = wi.WorkspaceID,
                    WorkspaceName = wi.Workspace.WorkspaceName,
                    WorkspaceDescription = wi.Workspace.Description ?? "",
                    Email = wi.Email,
                    Role = wi.Role,
                    Status = wi.Status,
                    InvitedBy = new InviterDto
                    {
                        UserID = wi.InvitedBy.UserID,
                        FullName = wi.InvitedBy.FullName ?? wi.InvitedBy.Email,
                        Email = wi.InvitedBy.Email,
                        AvatarURL = wi.InvitedBy.AvatarURL
                    },
                    CreatedAt = wi.CreatedAt,
                    Message = wi.Message
                })
                .ToListAsync();

            return Ok(invitations);
        }

        /// <summary>
        /// Get all invitations sent for a workspace (Owner/PM only)
        /// </summary>
        [HttpGet("{workspaceId}/invitations")]
        public async Task<ActionResult<IEnumerable<InvitationDto>>> GetWorkspaceInvitations(Guid workspaceId)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId == Guid.Empty) return Unauthorized();

            // Check permission
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == currentUserId);

            if (member == null) return Forbid();

            if (member.Role != "Owner" && member.Role != "ProjectManager")
                return StatusCode(403, new { message = "Only Owner or ProjectManager can view invitations" });

            var invitations = await _context.WorkspaceInvitations
                .Include(wi => wi.Workspace)
                .Include(wi => wi.InvitedBy)
                .Where(wi => wi.WorkspaceID == workspaceId)
                .OrderByDescending(wi => wi.CreatedAt)
                .Select(wi => new InvitationDto
                {
                    InvitationID = wi.InvitationID,
                    WorkspaceID = wi.WorkspaceID,
                    WorkspaceName = wi.Workspace.WorkspaceName,
                    WorkspaceDescription = wi.Workspace.Description ?? "",
                    Email = wi.Email,
                    Role = wi.Role,
                    Status = wi.Status,
                    InvitedBy = new InviterDto
                    {
                        UserID = wi.InvitedBy.UserID,
                        FullName = wi.InvitedBy.FullName ?? wi.InvitedBy.Email,
                        Email = wi.InvitedBy.Email,
                        AvatarURL = wi.InvitedBy.AvatarURL
                    },
                    CreatedAt = wi.CreatedAt,
                    RespondedAt = wi.RespondedAt,
                    Message = wi.Message
                })
                .ToListAsync();

            return Ok(invitations);
        }

        /// <summary>
        /// Accept a workspace invitation
        /// </summary>
        [HttpPost("invitations/{invitationId}/accept")]
        public async Task<ActionResult<InvitationResponseDto>> AcceptInvitation(Guid invitationId)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId == Guid.Empty) return Unauthorized();

            var currentUser = await _context.Users.FindAsync(currentUserId);
            if (currentUser == null) return Unauthorized();

            var invitation = await _context.WorkspaceInvitations
                .Include(wi => wi.Workspace)
                .FirstOrDefaultAsync(wi => wi.InvitationID == invitationId);

            if (invitation == null)
                return NotFound(new { message = "Invitation not found" });

            // Verify the invitation is for this user
            if (invitation.Email != currentUser.Email)
                return StatusCode(403, new { message = "This invitation is not for you" });

            // Check status
            if (invitation.Status != InvitationStatus.Pending)
                return BadRequest(new { message = $"Invitation has already been {invitation.Status.ToLower()}" });

            // Check if user is already a member (in case they were added directly)
            var existingMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == invitation.WorkspaceID && wm.UserID == currentUserId);

            if (existingMember)
            {
                invitation.Status = InvitationStatus.Accepted;
                invitation.RespondedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return BadRequest(new { message = "You are already a member of this workspace" });
            }

            // Add user to workspace
            var newMember = new WorkspaceMember
            {
                WorkspaceID = invitation.WorkspaceID,
                UserID = currentUserId,
                Role = invitation.Role,
                JoinedAt = DateTime.UtcNow
            };

            _context.WorkspaceMembers.Add(newMember);

            // Update invitation status
            invitation.Status = InvitationStatus.Accepted;
            invitation.RespondedAt = DateTime.UtcNow;

            // Create notification for inviter
            var notification = new Notification
            {
                NotificationID = Guid.NewGuid(),
                UserID = invitation.InvitedByUserID,
                Message = $"{currentUser.FullName ?? currentUser.Email} accepted your invitation to join '{invitation.Workspace.WorkspaceName}'",
                RelatedEntityType = "InvitationAccepted",
                RelatedEntityID = invitation.WorkspaceID,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            var memberCount = await _context.WorkspaceMembers
                .CountAsync(wm => wm.WorkspaceID == invitation.WorkspaceID);

            return Ok(new InvitationResponseDto
            {
                Message = "Successfully joined workspace",
                Workspace = new WorkspaceInfoDto
                {
                    WorkspaceID = invitation.WorkspaceID,
                    Name = invitation.Workspace.WorkspaceName,
                    Role = invitation.Role,
                    MemberCount = memberCount
                }
            });
        }

        /// <summary>
        /// Reject a workspace invitation
        /// </summary>
        [HttpPost("invitations/{invitationId}/reject")]
        public async Task<ActionResult<InvitationResponseDto>> RejectInvitation(Guid invitationId)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId == Guid.Empty) return Unauthorized();

            var currentUser = await _context.Users.FindAsync(currentUserId);
            if (currentUser == null) return Unauthorized();

            var invitation = await _context.WorkspaceInvitations
                .Include(wi => wi.Workspace)
                .FirstOrDefaultAsync(wi => wi.InvitationID == invitationId);

            if (invitation == null)
                return NotFound(new { message = "Invitation not found" });

            // Verify the invitation is for this user
            if (invitation.Email != currentUser.Email)
                return StatusCode(403, new { message = "This invitation is not for you" });

            // Check status
            if (invitation.Status != InvitationStatus.Pending)
                return BadRequest(new { message = $"Invitation has already been {invitation.Status.ToLower()}" });

            // Update invitation status
            invitation.Status = InvitationStatus.Rejected;
            invitation.RespondedAt = DateTime.UtcNow;

            // Create notification for inviter
            var notification = new Notification
            {
                NotificationID = Guid.NewGuid(),
                UserID = invitation.InvitedByUserID,
                Message = $"{currentUser.FullName ?? currentUser.Email} declined your invitation to join '{invitation.Workspace.WorkspaceName}'",
                RelatedEntityType = "InvitationRejected",
                RelatedEntityID = invitation.WorkspaceID,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            return Ok(new InvitationResponseDto
            {
                Message = "Invitation rejected successfully"
            });
        }

        /// <summary>
        /// Cancel an invitation (Owner/PM only)
        /// </summary>
        [HttpDelete("{workspaceId}/invitations/{invitationId}")]
        public async Task<IActionResult> CancelInvitation(Guid workspaceId, Guid invitationId)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId == Guid.Empty) return Unauthorized();

            // Check permission
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == currentUserId);

            if (member == null) return Forbid();

            if (member.Role != "Owner" && member.Role != "ProjectManager")
                return StatusCode(403, new { message = "Only Owner or ProjectManager can cancel invitations" });

            var invitation = await _context.WorkspaceInvitations
                .FirstOrDefaultAsync(wi => wi.InvitationID == invitationId && wi.WorkspaceID == workspaceId);

            if (invitation == null)
                return NotFound(new { message = "Invitation not found" });

            if (invitation.Status != InvitationStatus.Pending)
                return BadRequest(new { message = "Can only cancel pending invitations" });

            invitation.Status = InvitationStatus.Cancelled;
            invitation.RespondedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Invitation cancelled successfully" });
        }
    }
}
