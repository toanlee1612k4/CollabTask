using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tasks;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api")]
    [Authorize]
    public class TasksController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public TasksController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // GET: api/workspaces/{workspaceId}/tasks
        // Lấy tất cả tasks trong một workspace cụ thể
        [HttpGet("workspaces/{workspaceId}/tasks")]
        public async Task<ActionResult<IEnumerable<TaskDto>>> GetTasksInWorkspace(Guid workspaceId)
        {
            var userId = User.GetUserId();

            // Kiểm tra xem người dùng có phải là thành viên của workspace không
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);

            if (!isMember)
            {
                return Forbid(); // 403 Forbidden nếu không phải thành viên
            }

            var tasks = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId)
                .Select(t => new TaskDto
                {
                    TaskID = t.TaskID,
                    WorkspaceID = t.WorkspaceID,
                    Title = t.Title,
                    Description = t.Description,
                    Status = t.Status,
                    Priority = t.Priority,
                    Deadline = t.Deadline,
                    EstimatedTimeMinutes = t.EstimatedTimeMinutes,
                    CreatorUserID = t.CreatorUserID,
                    CreatedAt = t.CreatedAt
                })
                .ToListAsync();

            return Ok(tasks);
        }

        // POST: api/workspaces/{workspaceId}/tasks
        // Tạo một task mới trong workspace
        [HttpPost("workspaces/{workspaceId}/tasks")]
        public async Task<ActionResult<TaskDto>> CreateTask(Guid workspaceId, CreateTaskDto createDto)
        {
            var userId = User.GetUserId();

            // Kiểm tra xem người dùng có phải là thành viên của workspace không
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);

            if (!isMember)
            {
                return Forbid();
            }

            var newTask = new Models.Task
            {
                TaskID = Guid.NewGuid(),
                WorkspaceID = workspaceId,
                Title = createDto.Title,
                Description = createDto.Description,
                Status = "ToDo", // Trạng thái mặc định
                Priority = createDto.Priority,
                Deadline = createDto.Deadline,
                EstimatedTimeMinutes = createDto.EstimatedTimeMinutes,
                CreatorUserID = userId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Tasks.Add(newTask);
            await _context.SaveChangesAsync();

            var taskDto = new TaskDto
            {
                TaskID = newTask.TaskID,
                WorkspaceID = newTask.WorkspaceID,
                Title = newTask.Title,
                Description = newTask.Description,
                Status = newTask.Status,
                Priority = newTask.Priority,
                Deadline = newTask.Deadline,
                EstimatedTimeMinutes = newTask.EstimatedTimeMinutes,
                CreatorUserID = newTask.CreatorUserID,
                CreatedAt = newTask.CreatedAt
            };
            
            // Trả về task đã được tạo
            return CreatedAtAction(nameof(GetTasksInWorkspace), new { workspaceId = taskDto.WorkspaceID }, taskDto);
        }
    }
}
