using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tasks;
using CollabTask.Api.Dtos.Comments; 
using CollabTask.Api.Helpers;
using CollabTask.Api.Models; 
using CollabTask.Api.Services.PriorityScoringService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api")]
    [Authorize]
    public class TasksController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;
        private readonly IPriorityScoringService _priorityScoringService; // SỬA TÊN BIẾN

        public TasksController(CollabTaskDbContext context, IPriorityScoringService priorityScoringService)
        {
            _context = context;
            _priorityScoringService = priorityScoringService; // SỬA TÊN BIẾN
        }
        
        // === GIAI ĐOẠN 1: API GỢI Ý ===
        [HttpGet("suggested")]
        public async Task<ActionResult<List<TaskDto>>> GetSuggestedTasks()
        {
            var userIdClaim = User.FindFirst("UserID")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            var suggestedTasks = await _priorityScoringService.GetSuggestedTasksAsync(userId);
            return Ok(suggestedTasks);
        }

        // GET: api/workspaces/{workspaceId}/tasks
        [HttpGet("workspaces/{workspaceId}/tasks")]
        public async Task<ActionResult<IEnumerable<TaskDto>>> GetTasksInWorkspace(Guid workspaceId)
        {
            var userId = User.GetUserId();
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);

            if (!isMember) return Forbid(); 

            var tasks = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId)
                .Include(t => t.TaskAssignments) // Thêm Include
                .Select(t => new TaskDto
                {
                    TaskId = t.TaskID,
                    WorkspaceId = t.WorkspaceID,
                    Title = t.Title,
                    Description = t.Description,
                    Status = t.Status,
                    Priority = t.Priority,
                    Deadline = t.Deadline,
                    EstimatedTimeMinutes = t.EstimatedTimeMinutes,
                    CreatorUserId = t.CreatorUserID,
                    CreatedAt = t.CreatedAt,
                    CompletedAt = t.CompletedAt, // Thêm
                    AssigneeUserIds = t.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList() // Thêm
                })
                .ToListAsync();

            return Ok(tasks);
        }

        // GET: api/tasks/{id}
        [HttpGet("tasks/{id}")]
        public async Task<ActionResult<TaskDto>> GetTaskById(Guid id)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks
                .Include(t => t.TaskAssignments)
                .FirstOrDefaultAsync(t => t.TaskID == id);

            if (task == null) return NotFound();

            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var taskDto = new TaskDto
            {
                TaskId = task.TaskID,
                WorkspaceId = task.WorkspaceID,
                Title = task.Title,
                Description = task.Description,
                Status = task.Status,
                Priority = task.Priority,
                Deadline = task.Deadline,
                EstimatedTimeMinutes = task.EstimatedTimeMinutes,
                CreatorUserId = task.CreatorUserID,
                CreatedAt = task.CreatedAt,
                CompletedAt = task.CompletedAt,
                AssigneeUserIds = task.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList()
            };

            return Ok(taskDto);
        }

        // POST: api/workspaces/{workspaceId}/tasks
        [HttpPost("workspaces/{workspaceId}/tasks")]
        public async Task<ActionResult<TaskDto>> CreateTask(Guid workspaceId, CreateTaskDto createDto)
        {
            var userId = User.GetUserId();
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);

            if (!isMember) return Forbid();

            var newTask = new Task
            {
                TaskID = Guid.NewGuid(),
                WorkspaceID = workspaceId,
                Title = createDto.Title,
                Description = createDto.Description,
                Status = "ToDo",
                Priority = createDto.Priority,
                Deadline = createDto.Deadline,
                EstimatedTimeMinutes = createDto.EstimatedTimeMinutes,
                CreatorUserID = userId,
                CreatedAt = DateTime.UtcNow
            };
            _context.Tasks.Add(newTask);

            // Xử lý gán người dùng
            var assignees = new List<Guid>();
            if (createDto.AssigneeUserIds != null && createDto.AssigneeUserIds.Any())
            {
                // TODO: Kiểm tra xem các assignee có phải là member của workspace không
                assignees.AddRange(createDto.AssigneeUserIds);
            }
            else
            {
                assignees.Add(userId); // Tự động gán cho người tạo nếu không chọn ai
            }

            foreach (var assigneeId in assignees)
            {
                _context.TaskAssignments.Add(new TaskAssignment
                {
                    TaskID = newTask.TaskID,
                    AssigneeUserID = assigneeId,
                    AssignedAt = DateTime.UtcNow
                });
            }

            // Ghi Activity Log
            _context.ActivityLogs.Add(new ActivityLog
            {
                LogID = Guid.NewGuid(),
                UserID = userId,
                Action = $"đã tạo công việc: '{newTask.Title}'",
                EntityType = "Task",
                EntityID = newTask.TaskID,
                Timestamp = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            var taskDto = new TaskDto
            {
                TaskId = newTask.TaskID,
                WorkspaceId = newTask.WorkspaceID,
                Title = newTask.Title,
                Description = newTask.Description,
                Status = newTask.Status,
                Priority = newTask.Priority,
                Deadline = newTask.Deadline,
                EstimatedTimeMinutes = newTask.EstimatedTimeMinutes,
                CreatorUserId = newTask.CreatorUserID,
                CreatedAt = newTask.CreatedAt,
                AssigneeUserIds = assignees
            };
            
            return CreatedAtAction(nameof(GetTaskById), new { id = taskDto.TaskId }, taskDto);
        }

        // PUT: api/tasks/{id}
        [HttpPut("tasks/{id}")]
        public async Task<IActionResult> UpdateTask(Guid id, [FromBody] UpdateTaskDto updateDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();
            
            var task = await _context.Tasks
                .Include(t => t.TaskAssignments) // Thêm
                .FirstOrDefaultAsync(t => t.TaskID == id);
            
            if (task == null) return NotFound();

            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();
            // TODO: Thêm logic phân quyền (chỉ PM hoặc người tạo/gán được sửa)

            // Cập nhật các trường
            task.Title = updateDto.Title;
            task.Description = updateDto.Description;
            task.Priority = updateDto.Priority;
            task.Deadline = updateDto.Deadline;
            task.EstimatedTimeMinutes = updateDto.EstimatedTimeMinutes;
            
            // Xử lý cập nhật danh sách assignee
            if (updateDto.AssigneeUserIds != null)
            {
                // TODO: Kiểm tra các ID mới có phải là member không
                var currentAssigneeIds = task.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList();
                var newAssigneeIds = updateDto.AssigneeUserIds;

                var toRemove = task.TaskAssignments.Where(ta => !newAssigneeIds.Contains(ta.AssigneeUserID)).ToList();
                var toAdd = newAssigneeIds.Where(id => !currentAssigneeIds.Contains(id))
                                        .Select(id => new TaskAssignment { TaskID = id, AssigneeUserID = id, AssignedAt = DateTime.UtcNow })
                                        .ToList();
                
                _context.TaskAssignments.RemoveRange(toRemove);
                _context.TaskAssignments.AddRange(toAdd);
            }

            // Ghi Activity Log
            _context.ActivityLogs.Add(new ActivityLog
            {
                LogID = Guid.NewGuid(),
                UserID = userId,
                Action = $"đã cập nhật thông tin công việc: '{task.Title}'",
                EntityType = "Task",
                EntityID = task.TaskID,
                Timestamp = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/tasks/{id}
        [HttpDelete("tasks/{id}")]
        public async Task<IActionResult> DeleteTask(Guid id)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(id);
            if (task == null) return NotFound();

            // Kiểm tra quyền (ví dụ: chỉ Creator hoặc ProjectManager)
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            
            if (member == null || (task.CreatorUserID != userId && member.Role != "ProjectManager"))
            {
                return Forbid("Only the task creator or a project manager can delete this task.");
            }

            _context.Tasks.Remove(task);
            
            // Ghi Activity Log
            _context.ActivityLogs.Add(new ActivityLog
            {
                LogID = Guid.NewGuid(),
                UserID = userId,
                Action = $"đã xóa công việc: '{task.Title}'",
                EntityType = "Task",
                EntityID = task.TaskID,
                Timestamp = DateTime.UtcNow
            });
            
            await _context.SaveChangesAsync();
            return NoContent();
        }

        #region Task Assignments
        // ... (Code gán task từ file trước của tôi) ...
        #endregion

        #region Task Status

        // GIAI ĐOẠN 2: API Cập nhật trạng thái
        [HttpPut("tasks/{taskId}/status")]
        public async Task<IActionResult> UpdateTaskStatus(Guid taskId, [FromBody] UpdateTaskStatusDto statusDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks
                .Include(t => t.TaskAssignments) 
                .FirstOrDefaultAsync(t => t.TaskID == taskId);

            if (task == null) return NotFound("Task not found.");

            // Kiểm tra quyền
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

             // Validate NewStatus
             string[] allowedStatuses = { "ToDo", "InProgress", "InReview", "Done", "Canceled", "Rejected", "Overdue" };
             if (!allowedStatuses.Contains(statusDto.NewStatus))
             {
                 return BadRequest($"Invalid status value: {statusDto.NewStatus}.");
             }
            
            string oldStatus = task.Status;
            
            // Nếu không thay đổi thì không làm gì
            if (oldStatus == statusDto.NewStatus) return Ok(task); 

            task.Status = statusDto.NewStatus;

            // Cập nhật CompletedAt nếu trạng thái là Done
            if (statusDto.NewStatus == "Done")
            {
                task.CompletedAt = DateTime.UtcNow;
                
                // SỬA TÊN BIẾN Ở ĐÂY
                await _priorityScoringService.LogTaskCompletion(task, userId); 
            }
            else
            {
                task.CompletedAt = null; // Reset nếu chuyển khỏi Done
            }

            // Thêm Activity Log
            var log = new ActivityLog
            {
                LogID = Guid.NewGuid(),
                UserID = userId,
                Action = $"đã cập nhật trạng thái từ '{oldStatus}' thành '{task.Status}'",
                EntityType = "Task",
                EntityID = taskId,
                Timestamp = DateTime.UtcNow
            };
            _context.ActivityLogs.Add(log);

            await _context.SaveChangesAsync();

            // Trả về TaskDto đã cập nhật
             var taskDto = new TaskDto
             {
                 TaskId = task.TaskID,
                 WorkspaceId = task.WorkspaceID,
                 Title = task.Title,
                 Description = task.Description,
                 Status = task.Status,
                 Priority = task.Priority,
                 Deadline = task.Deadline,
                 EstimatedTimeMinutes = task.EstimatedTimeMinutes,
                 CreatorUserId = task.CreatorUserID,
                 CreatedAt = task.CreatedAt,
                 CompletedAt = task.CompletedAt,
                 AssigneeUserIds = task.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList()
             };

            return Ok(taskDto);
        }

        #endregion

        #region Task Tags
        // ... (Code gán/gỡ tag từ file trước của tôi) ...
        #endregion

        #region Task Comments
        // ... (Code comment từ file trước của tôi) ...
        #endregion

        [HttpPatch("{taskId}/complete")]
        public async Task<IActionResult> CompleteTask(Guid taskId)
        {
            var userIdClaim = User.FindFirst("UserID")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            var task = await _context.Tasks
                .Include(t => t.TaskAssignments)
                .FirstOrDefaultAsync(t => t.TaskID == taskId);

            if (task == null)
                return NotFound(new { message = "Task not found" });

            // Kiểm tra quyền
            var isAssignee = task.TaskAssignments.Any(ta => ta.AssigneeUserID == userId);
            if (!isAssignee)
                return Forbid();

            // Cập nhật status và CompletedAt
            task.Status = "Done";
            task.CompletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Gọi service để log completion
            await _priorityScoringService.LogTaskCompletion(task, userId);

            return Ok(new { message = "Task completed successfully" });
        }
    }
}