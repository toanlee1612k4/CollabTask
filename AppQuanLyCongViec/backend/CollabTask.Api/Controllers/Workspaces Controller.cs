using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Workspaces;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Yêu cầu xác thực cho tất cả các API trong controller này
    public class WorkspacesController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public WorkspacesController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // GET: api/workspaces
        // Lấy tất cả workspaces mà người dùng hiện tại là thành viên
        [HttpGet]
        public async Task<ActionResult<IEnumerable<WorkspaceDto>>> GetMyWorkspaces()
        {
            try
            {
                var userId = User.GetUserId(); // Lấy UserId từ token

            var workspaces = await _context.WorkspaceMembers
                .Where(wm => wm.UserID == userId)
                .Include(wm => wm.Workspace)
                .Select(wm => new WorkspaceDto
                {
                    WorkspaceID = wm.Workspace.WorkspaceID,
                    WorkspaceName = wm.Workspace.WorkspaceName,
                    Description = wm.Workspace.Description,
                    OwnerUserID = wm.Workspace.OwnerUserID,
                    IsPersonal = wm.Workspace.IsPersonal,
                    CreatedAt = wm.Workspace.CreatedAt
                })
                .ToListAsync();

                return Ok(workspaces);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching workspaces", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/workspaces
        // Tạo một workspace mới
        [HttpPost]
        public async Task<ActionResult<WorkspaceDto>> CreateWorkspace(CreateWorkspaceDto createDto)
        {
            try
            {
                var userId = User.GetUserId();

            var newWorkspace = new Workspace
            {
                WorkspaceID = Guid.NewGuid(),
                WorkspaceName = createDto.WorkspaceName,
                Description = createDto.Description,
                OwnerUserID = userId,
                IsPersonal = false, // Mặc định là workspace đội nhóm khi tạo qua API
                CreatedAt = DateTime.UtcNow
            };

            // Tự động thêm người tạo làm ProjectManager
            var newMember = new WorkspaceMember
            {
                WorkspaceID = newWorkspace.WorkspaceID,
                UserID = userId,
                Role = "ProjectManager",
                JoinedAt = DateTime.UtcNow
            };

            _context.Workspaces.Add(newWorkspace);
            _context.WorkspaceMembers.Add(newMember);
            await _context.SaveChangesAsync();
            
            var workspaceDto = new WorkspaceDto
            {
                 WorkspaceID = newWorkspace.WorkspaceID,
                 WorkspaceName = newWorkspace.WorkspaceName,
                 Description = newWorkspace.Description,
                 OwnerUserID = newWorkspace.OwnerUserID,
                 IsPersonal = newWorkspace.IsPersonal,
                 CreatedAt = newWorkspace.CreatedAt
            };

                return CreatedAtAction(nameof(GetWorkspaceById), new { id = workspaceDto.WorkspaceID }, workspaceDto);
            }
            catch (DbUpdateException ex)
            {
                return StatusCode(500, new { message = "Database error while creating workspace", error = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while creating workspace", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // GET: api/workspaces/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<WorkspaceDto>> GetWorkspaceById(Guid id)
        {
            var userId = User.GetUserId();

            // Kiểm tra user có phải member không
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == id && wm.UserID == userId);

            if (!isMember) return Forbid();

            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null) return NotFound();

            var workspaceDto = new WorkspaceDto
            {
                WorkspaceID = workspace.WorkspaceID,
                WorkspaceName = workspace.WorkspaceName,
                Description = workspace.Description,
                OwnerUserID = workspace.OwnerUserID,
                IsPersonal = workspace.IsPersonal,
                CreatedAt = workspace.CreatedAt
            };

            return Ok(workspaceDto);
        }

        // PUT: api/workspaces/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateWorkspace(Guid id, [FromBody] CreateWorkspaceDto updateDto)
        {
            var userId = User.GetUserId();

            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null) return NotFound();

            // Chỉ owner hoặc PM mới được update
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == id && wm.UserID == userId);

            if (member == null || (workspace.OwnerUserID != userId && member.Role != "ProjectManager"))
            {
                return Forbid();
            }

            workspace.WorkspaceName = updateDto.WorkspaceName;
            workspace.Description = updateDto.Description;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/workspaces/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteWorkspace(Guid id)
        {
            var userId = User.GetUserId();

            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null) return NotFound();

            // Chỉ owner mới được xóa workspace
            if (workspace.OwnerUserID != userId)
            {
                return Forbid("Only the workspace owner can delete this workspace.");
            }

            _context.Workspaces.Remove(workspace);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        #region Member Management

        // GET: api/workspaces/{id}/members
        [HttpGet("{id}/members")]
        public async Task<ActionResult<IEnumerable<MemberDto>>> GetWorkspaceMembers(Guid id)
        {
            var userId = User.GetUserId();

            // Kiểm tra user có phải member không
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == id && wm.UserID == userId);

            if (!isMember) return Forbid();

            var members = await _context.WorkspaceMembers
                .Where(wm => wm.WorkspaceID == id)
                .Include(wm => wm.User)
                .Select(wm => new MemberDto
                {
                    UserId = wm.UserID,
                    FullName = wm.User.FullName,
                    Email = wm.User.Email,
                    Role = wm.Role,
                    JoinedAt = wm.JoinedAt
                })
                .ToListAsync();

            return Ok(members);
        }

        // POST: api/workspaces/{id}/members
        [HttpPost("{id}/members")]
        public async Task<ActionResult> AddMember(Guid id, [FromBody] AddMemberDto addDto)
        {
            var userId = User.GetUserId();

            // Chỉ PM hoặc Owner mới được thêm member
            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null) return NotFound();

            var currentMember = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == id && wm.UserID == userId);

            if (currentMember == null || (workspace.OwnerUserID != userId && currentMember.Role != "ProjectManager"))
            {
                return Forbid();
            }

            // Tìm user bằng email
            var userToAdd = await _context.Users.FirstOrDefaultAsync(u => u.Email == addDto.UserEmailToAdd);
            if (userToAdd == null) return BadRequest("User with this email does not exist.");

            // Kiểm tra đã là member chưa
            var alreadyMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == id && wm.UserID == userToAdd.UserID);

            if (alreadyMember) return Conflict("User is already a member of this workspace.");

            var newMember = new WorkspaceMember
            {
                WorkspaceID = id,
                UserID = userToAdd.UserID,
                Role = addDto.Role ?? "Member",
                JoinedAt = DateTime.UtcNow
            };

            _context.WorkspaceMembers.Add(newMember);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Member added successfully" });
        }

        // PUT: api/workspaces/{id}/members/{memberId}/role
        [HttpPut("{id}/members/{memberId}/role")]
        public async Task<IActionResult> UpdateMemberRole(Guid id, Guid memberId, [FromBody] UpdateMemberRoleDto updateDto)
        {
            var userId = User.GetUserId();

            // Chỉ Owner mới được đổi role
            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null) return NotFound();

            if (workspace.OwnerUserID != userId)
            {
                return Forbid("Only the workspace owner can change member roles.");
            }

            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == id && wm.UserID == memberId);

            if (member == null) return NotFound("Member not found.");

            // Không cho đổi role của owner
            if (member.UserID == workspace.OwnerUserID)
            {
                return BadRequest("Cannot change the role of the workspace owner.");
            }

            member.Role = updateDto.NewRole;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/workspaces/{id}/members/{memberId}
        [HttpDelete("{id}/members/{memberId}")]
        public async Task<IActionResult> RemoveMember(Guid id, Guid memberId)
        {
            var userId = User.GetUserId();

            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null) return NotFound();

            // PM hoặc Owner mới được xóa, hoặc tự xóa mình
            var currentMember = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == id && wm.UserID == userId);

            bool canRemove = userId == memberId || // Tự rời khỏi workspace
                           workspace.OwnerUserID == userId ||
                           (currentMember != null && currentMember.Role == "ProjectManager");

            if (!canRemove) return Forbid();

            // Không cho xóa owner
            if (memberId == workspace.OwnerUserID)
            {
                return BadRequest("Cannot remove the workspace owner.");
            }

            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == id && wm.UserID == memberId);

            if (member == null) return NotFound("Member not found.");

            _context.WorkspaceMembers.Remove(member);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/workspaces/{id}/members/{userId}/role
        // Get user's role in a specific workspace
        [HttpGet("{id}/members/{userId}/role")]
        public async Task<ActionResult<object>> GetUserWorkspaceRole(Guid id, Guid userId)
        {
            try
            {
                var currentUserId = User.GetUserId();

                // Check if current user has access to this workspace
                var isMember = await _context.WorkspaceMembers
                    .AnyAsync(wm => wm.WorkspaceID == id && wm.UserID == currentUserId);

                if (!isMember)
                    return Forbid();

                // Get target user's role
                var member = await _context.WorkspaceMembers
                    .FirstOrDefaultAsync(wm => wm.WorkspaceID == id && wm.UserID == userId);

                if (member == null)
                    return NotFound(new { message = "User is not a member of this workspace" });

                return Ok(new
                {
                    userId = member.UserID,
                    workspaceId = member.WorkspaceID,
                    role = member.Role,  // "Owner", "ProjectManager", or "Member"
                    joinedAt = member.JoinedAt
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error fetching user role", error = ex.Message });
            }
        }

        #endregion
    }
}
