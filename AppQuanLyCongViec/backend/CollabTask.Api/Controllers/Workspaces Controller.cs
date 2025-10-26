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

        // POST: api/workspaces
        // Tạo một workspace mới
        [HttpPost]
        public async Task<ActionResult<WorkspaceDto>> CreateWorkspace(CreateWorkspaceDto createDto)
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

            return CreatedAtAction(nameof(GetMyWorkspaces), new { id = workspaceDto.WorkspaceID }, workspaceDto);
        }
    }
}
