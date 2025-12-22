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
        private readonly IPriorityScoringService _priorityScoringService;

        public TasksController(CollabTaskDbContext context, IPriorityScoringService priorityScoringService)
        {
            _context = context;
            _priorityScoringService = priorityScoringService;
        }
        [HttpGet("suggested")]
        public async Task<ActionResult<List<TaskDto>>> GetSuggestedTasks()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty)
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            var suggestedTasks = await _priorityScoringService.GetSuggestedTasksAsync(userId);
            return Ok(suggestedTasks);
        }

        // GET: api/workspaces/{workspaceId}/tasks
        [HttpGet("workspaces/{workspaceId}/tasks")]
        public async Task<ActionResult<PagedResult<TaskDto>>> GetTasksInWorkspace(
            Guid workspaceId, 
            [FromQuery] int page = 1, 
            [FromQuery] int pageSize = 50,
            [FromQuery] string? status = null,
            [FromQuery] string? priority = null)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

            // 🔒 SECURITY: Check membership AND get role
            var member = await _context.WorkspaceMembers
                .AsNoTracking()
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);

            if (member == null) return Forbid();

            // Validate pagination parameters
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 50;
            if (pageSize > 100) pageSize = 100; // Max 100 items per page

            // 🔒 SECURITY: Check if user is Owner/ProjectManager
            var workspace = await _context.Workspaces
                .AsNoTracking()
                .FirstOrDefaultAsync(w => w.WorkspaceID == workspaceId);

            bool isOwnerOrPM = workspace != null && 
                              (workspace.OwnerUserID == userId || 
                               member.Role == "Owner" || 
                               member.Role == "ProjectManager");

            IQueryable<Task> query;

            if (isOwnerOrPM)
            {
                // ✅ Owner/PM: See ALL tasks in workspace
                query = _context.Tasks
                    .AsNoTracking()
                    .Where(t => t.WorkspaceID == workspaceId);
            }
            else
            {
                // ✅ Member: Only see tasks ASSIGNED to them (SECURITY FIX)
                query = _context.TaskAssignments
                    .AsNoTracking()
                    .Where(ta => ta.AssigneeUserID == userId)
                    .Select(ta => ta.Task)
                    .Where(t => t.WorkspaceID == workspaceId)
                    .Distinct();
            }

            // Apply filters
            if (!string.IsNullOrEmpty(status))
                query = query.Where(t => t.Status == status);
            
            if (!string.IsNullOrEmpty(priority))
                query = query.Where(t => t.Priority == priority);

            // Get total count before pagination
            var totalCount = await query.CountAsync();

            // ⚡ PERFORMANCE: Use projection (.Select) to avoid loading full entities
            var tasks = await query
                .Include(t => t.TaskAssignments)
                .OrderByDescending(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
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
                    CompletedAt = t.CompletedAt,
                    AssigneeUserIds = t.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList()
                })
                .ToListAsync();

            return Ok(new PagedResult<TaskDto>
            {
                Items = tasks,
                TotalCount = totalCount,
                CurrentPage = page,
                PageSize = pageSize
            });
        }

        // GET: api/tasks/calendar - Lấy tasks theo lịch riêng của user (chỉ tasks được assign)
        [HttpGet("tasks/calendar")]
        public async Task<IActionResult> GetMyCalendarTasks(
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

                var start = startDate ?? DateTime.UtcNow.Date;
                var end = endDate ?? DateTime.UtcNow.Date.AddDays(30);

                // ✅ Chỉ lấy tasks được assign cho user (SECURE)
                // ⚡ PERFORMANCE: Add AsNoTracking()
                var calendarTasks = await _context.TaskAssignments
                    .AsNoTracking()
                    .Where(ta => ta.AssigneeUserID == userId
                        && ta.Task.Deadline.HasValue
                        && ta.Task.Deadline >= start
                        && ta.Task.Deadline <= end)
                    .Include(ta => ta.Task)
                    .ThenInclude(t => t.TaskAssignments)
                    .Select(ta => new
                    {
                        TaskId = ta.Task.TaskID,
                        WorkspaceId = ta.Task.WorkspaceID,
                        Title = ta.Task.Title,
                        Description = ta.Task.Description,
                        Status = ta.Task.Status,
                        Priority = ta.Task.Priority,
                        Deadline = ta.Task.Deadline,
                        EstimatedTimeMinutes = ta.Task.EstimatedTimeMinutes,
                        CreatorUserId = ta.Task.CreatorUserID,
                        CreatedAt = ta.Task.CreatedAt,
                        CompletedAt = ta.Task.CompletedAt,
                        AssignmentStatus = ta.Status.ToString(),
                        AssignedAt = ta.AssignedAt,
                        AssigneeUserIds = ta.Task.TaskAssignments.Select(a => a.AssigneeUserID).ToList()
                    })
                    .OrderBy(t => t.Deadline)
                    .ToListAsync();

                return Ok(new
                {
                    tasks = calendarTasks,
                    dateRange = new { start, end },
                    totalCount = calendarTasks.Count
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error fetching calendar tasks", error = ex.Message });
            }
        }

        // GET: api/tasks - Lấy tất cả tasks mà user đang được assign
        [HttpGet("tasks")]
        public async Task<ActionResult<PagedResult<TaskDto>>> GetMyTasks(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50,
            [FromQuery] string? status = null,
            [FromQuery] string? priority = null)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            // Validate pagination
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 50;
            if (pageSize > 100) pageSize = 100;

            var query = _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId)
                .Select(ta => ta.Task)
                .Distinct();

            // Apply filters
            if (!string.IsNullOrEmpty(status))
                query = query.Where(t => t.Status == status);
            
            if (!string.IsNullOrEmpty(priority))
                query = query.Where(t => t.Priority == priority);

            // Get total count
            var totalCount = await query.CountAsync();

            // Apply pagination
            var tasks = await query
                .Include(t => t.TaskAssignments)
                .OrderByDescending(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
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
                    CompletedAt = t.CompletedAt,
                    AssigneeUserIds = t.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList()
                })
                .ToListAsync();

            return Ok(new PagedResult<TaskDto>
            {
                Items = tasks,
                TotalCount = totalCount,
                CurrentPage = page,
                PageSize = pageSize
            });
        }

        // GET: api/tasks/{id}
        [HttpGet("tasks/{id}")]
        public async Task<ActionResult<TaskDto>> GetTaskById(Guid id)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

            // ⚡ PERFORMANCE: Use AsNoTracking for read-only query
            var task = await _context.Tasks
                .AsNoTracking()
                .Include(t => t.TaskAssignments)
                .FirstOrDefaultAsync(t => t.TaskID == id);

            if (task == null) return NotFound(new { message = "Task not found" });

            // 🔒 SECURITY: Check membership AND role
            var member = await _context.WorkspaceMembers
                .AsNoTracking()
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            
            if (member == null) return Forbid();

            // 🔒 SECURITY: Check if user has permission to view this specific task
            var workspace = await _context.Workspaces
                .AsNoTracking()
                .FirstOrDefaultAsync(w => w.WorkspaceID == task.WorkspaceID);

            bool isOwnerOrPM = workspace != null && 
                              (workspace.OwnerUserID == userId || 
                               member.Role == "Owner" || 
                               member.Role == "ProjectManager");

            // ✅ If Member role, check if assigned to this task (SECURITY FIX)
            if (!isOwnerOrPM)
            {
                bool isAssigned = task.TaskAssignments.Any(ta => ta.AssigneeUserID == userId);
                if (!isAssigned)
                {
                    return Forbid("Members can only view tasks assigned to them");
                }
            }

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
                    AssignerUserID = userId, // Người tạo task là assigner
                    Status = TaskAssignmentStatus.Pending,
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

            // Kiểm tra quyền: Chỉ Owner hoặc ProjectManager mới được sửa task
            var workspace = await _context.Workspaces.FindAsync(task.WorkspaceID);
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            
            if (member == null) return Forbid();
            
            bool isOwnerOrPM = workspace != null && 
                              (workspace.OwnerUserID == userId || 
                               member.Role == "Owner" || 
                               member.Role == "ProjectManager");
            
            if (!isOwnerOrPM)
            {
                return Forbid("Only Owner or ProjectManager can edit tasks. Members can only update task status.");
            }

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

            // Kiểm tra quyền: Chỉ Owner hoặc ProjectManager mới được xóa task
            var workspace = await _context.Workspaces.FindAsync(task.WorkspaceID);
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            
            if (member == null) return Forbid();
            
            bool isOwnerOrPM = workspace != null && 
                              (workspace.OwnerUserID == userId || 
                               member.Role == "Owner" || 
                               member.Role == "ProjectManager");
            
            if (!isOwnerOrPM)
            {
                return Forbid("Only Owner or ProjectManager can delete tasks.");
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

        // POST: api/tasks/{taskId}/assign - Assign task to multiple users (PM/Owner only)
        [HttpPost("tasks/{taskId}/assign")]
        public async Task<IActionResult> AssignTask(Guid taskId, [FromBody] AssignTaskRequestDto requestDto)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

                var task = await _context.Tasks.FindAsync(taskId);
                if (task == null) return NotFound(new { message = "Task not found" });

                // Check if user is Owner or ProjectManager
                var member = await _context.WorkspaceMembers
                    .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
                
                if (member == null) return Forbid();
                if (member.Role != "Owner" && member.Role != "ProjectManager")
                    return StatusCode(403, new { message = "Only Owner or ProjectManager can assign tasks" });

                var createdAssignments = new List<TaskAssignmentDto>();

                foreach (var assigneeId in requestDto.AssigneeUserIds)
                {
                    // Check if assignee is a member
                    var assigneeIsMember = await _context.WorkspaceMembers
                        .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == assigneeId);
                    if (!assigneeIsMember) continue;

                    // Check if already assigned
                    var existingAssignment = await _context.TaskAssignments
                        .FirstOrDefaultAsync(ta => ta.TaskID == taskId && ta.AssigneeUserID == assigneeId);
                    
                    if (existingAssignment != null) continue;

                    // Create new assignment
                    var assignment = new TaskAssignment
                    {
                        TaskID = taskId,
                        AssigneeUserID = assigneeId,
                        AssignerUserID = userId,
                        Status = TaskAssignmentStatus.Pending,
                        AssignedAt = DateTime.UtcNow
                    };

                    _context.TaskAssignments.Add(assignment);

                    // Create history record
                    var history = new TaskAssignmentHistory
                    {
                        HistoryID = Guid.NewGuid(),
                        TaskID = taskId,
                        AssigneeUserID = assigneeId,
                        ActionByUserID = userId,
                        Action = "Assigned",
                        NewStatus = "Pending",
                        Note = requestDto.Note,
                        ActionAt = DateTime.UtcNow
                    };
                    _context.TaskAssignmentHistories.Add(history);

                    // Create notification
                    var assignee = await _context.Users.FindAsync(assigneeId);
                    var notification = new Notification
                    {
                        NotificationID = Guid.NewGuid(),
                        UserID = assigneeId,
                        Message = $"Bạn được giao công việc: {task.Title}",
                        RelatedEntityType = "Task",
                        RelatedEntityID = taskId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Notifications.Add(notification);

                    // Activity Log
                    _context.ActivityLogs.Add(new ActivityLog
                    {
                        LogID = Guid.NewGuid(),
                        UserID = userId,
                        Action = $"đã gán '{assignee?.FullName ?? assignee?.Email}' vào công việc '{task.Title}'",
                        EntityType = "Task",
                        EntityID = taskId,
                        Timestamp = DateTime.UtcNow
                    });

                    createdAssignments.Add(new TaskAssignmentDto
                    {
                        TaskID = taskId,
                        AssigneeUserID = assigneeId,
                        AssigneeName = assignee?.FullName ?? "",
                        AssigneeEmail = assignee?.Email ?? "",
                        AssignerUserID = userId,
                        Status = "Pending",
                        AssignedAt = DateTime.UtcNow
                    });
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Task assigned successfully", assignments = createdAssignments });
            }
            catch (DbUpdateException ex)
            {
                return StatusCode(500, new { message = "Database error while assigning task", error = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while assigning task", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/tasks/{taskId}/respond - Accept or reject task assignment (assignee only)
        [HttpPost("tasks/{taskId}/respond")]
        public async Task<IActionResult> RespondToAssignment(Guid taskId, [FromBody] RespondToAssignmentDto responseDto)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

                var assignment = await _context.TaskAssignments
                    .Include(ta => ta.Task)
                    .Include(ta => ta.Assigner)
                    .FirstOrDefaultAsync(ta => ta.TaskID == taskId && ta.AssigneeUserID == userId);

                if (assignment == null) return NotFound(new { message = "Assignment not found" });

                if (assignment.Status != TaskAssignmentStatus.Pending)
                    return BadRequest(new { message = "Assignment has already been responded to" });

                var newStatus = responseDto.Accept ? TaskAssignmentStatus.Accepted : TaskAssignmentStatus.Rejected;
                assignment.Status = newStatus;
                assignment.ResponseAt = DateTime.UtcNow;
                assignment.ResponseNote = responseDto.Note;

                // Create history record
                var history = new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = taskId,
                    AssigneeUserID = userId,
                    ActionByUserID = userId,
                    Action = responseDto.Accept ? "Accepted" : "Rejected",
                    PreviousStatus = "Pending",
                    NewStatus = newStatus.ToString(),
                    Note = responseDto.Note,
                    ActionAt = DateTime.UtcNow
                };
                _context.TaskAssignmentHistories.Add(history);

                // Notify assigner
                var notification = new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = assignment.AssignerUserID,
                    Message = responseDto.Accept 
                    ? $"Người dùng đã chấp nhận công việc: {assignment.Task.Title}"
                        : $"Người dùng đã từ chối công việc: {assignment.Task.Title}",
                    RelatedEntityType = "Task",
                    RelatedEntityID = taskId,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);

                await _context.SaveChangesAsync();

                return Ok(new { message = responseDto.Accept ? "Assignment accepted" : "Assignment rejected" });
            }
            catch (DbUpdateException ex)
            {
                return StatusCode(500, new { message = "Database error while responding to assignment", error = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while responding to assignment", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/tasks/{taskId}/request-completion - Request task completion approval (assignee only)
        [HttpPost("tasks/{taskId}/request-completion")]
        public async Task<IActionResult> RequestTaskCompletion(Guid taskId, [FromBody] RequestTaskCompletionDto requestDto)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

                var assignment = await _context.TaskAssignments
                    .Include(ta => ta.Task)
                    .FirstOrDefaultAsync(ta => ta.TaskID == taskId && ta.AssigneeUserID == userId);

                if (assignment == null) return NotFound(new { message = "Assignment not found" });

                if (assignment.Status != TaskAssignmentStatus.Accepted && assignment.Status != TaskAssignmentStatus.InProgress)
                    return BadRequest(new { message = "Can only request completion for accepted or in-progress tasks" });

                assignment.Status = TaskAssignmentStatus.CompletionRequested;
                assignment.CompletionRequestedAt = DateTime.UtcNow;

                // Create history record
                var history = new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = taskId,
                    AssigneeUserID = userId,
                    ActionByUserID = userId,
                    Action = "CompletionRequested",
                    PreviousStatus = assignment.Status.ToString(),
                    NewStatus = "CompletionRequested",
                    Note = requestDto.Note,
                    ActionAt = DateTime.UtcNow
                };
                _context.TaskAssignmentHistories.Add(history);

                // Notify all PMs/Owners
                var pms = await _context.WorkspaceMembers
                    .Where(wm => wm.WorkspaceID == assignment.Task.WorkspaceID 
                        && (wm.Role == "Owner" || wm.Role == "ProjectManager"))
                    .Select(wm => wm.UserID)
                    .ToListAsync();

                foreach (var pmId in pms)
                {
                    var notification = new Notification
                    {
                        NotificationID = Guid.NewGuid(),
                        UserID = pmId,
                        Message = $"Yêu cầu duyệt hoàn thành công việc: {assignment.Task.Title}",
                        RelatedEntityType = "Task",
                        RelatedEntityID = taskId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Notifications.Add(notification);
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Completion request sent successfully" });
            }
            catch (DbUpdateException ex)
            {
                return StatusCode(500, new { message = "Database error while requesting completion", error = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while requesting completion", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/tasks/{taskId}/approve-completion - Approve or reject task completion (PM/Owner only)
        [HttpPost("tasks/{taskId}/approve-completion")]
        public async Task<IActionResult> ApproveTaskCompletion(Guid taskId, [FromBody] ApproveTaskCompletionDto approveDto)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

                var task = await _context.Tasks
                    .Include(t => t.TaskAssignments)
                    .FirstOrDefaultAsync(t => t.TaskID == taskId);
                
                if (task == null) return NotFound(new { message = "Task not found" });

                // Check if user is Owner or ProjectManager
                var member = await _context.WorkspaceMembers
                    .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
                
                if (member == null) return Forbid();
                if (member.Role != "Owner" && member.Role != "ProjectManager")
                    return StatusCode(403, new { message = "Only Owner or ProjectManager can approve completions" });

                // Update all assignments requesting completion
                var completionRequests = task.TaskAssignments
                    .Where(ta => ta.Status == TaskAssignmentStatus.CompletionRequested)
                    .ToList();

                if (!completionRequests.Any())
                    return BadRequest(new { message = "No completion requests found for this task" });

                foreach (var assignment in completionRequests)
                {
                    if (approveDto.Approve)
                    {
                        assignment.Status = TaskAssignmentStatus.Approved;
                        assignment.ApprovedAt = DateTime.UtcNow;
                        assignment.ApprovedByUserId = userId;
                        assignment.ApprovalNote = approveDto.Note;
                    }
                    else
                    {
                        assignment.Status = TaskAssignmentStatus.Accepted; // Back to accepted
                        assignment.ApprovalNote = approveDto.Note;
                    }

                    // Create history record
                    var history = new TaskAssignmentHistory
                    {
                        HistoryID = Guid.NewGuid(),
                        TaskID = taskId,
                        AssigneeUserID = assignment.AssigneeUserID,
                        ActionByUserID = userId,
                        Action = approveDto.Approve ? "Approved" : "Rejected",
                        PreviousStatus = "CompletionRequested",
                        NewStatus = approveDto.Approve ? "Approved" : "Accepted",
                        Note = approveDto.Note,
                        ActionAt = DateTime.UtcNow
                    };
                    _context.TaskAssignmentHistories.Add(history);

                    // Notify assignee
                    var notification = new Notification
                    {
                        NotificationID = Guid.NewGuid(),
                        UserID = assignment.AssigneeUserID,
                        Message = approveDto.Approve 
                            ? $"Công việc của bạn đã được duyệt: {task.Title}"
                            : $"Công việc của bạn bị từ chối: {task.Title}",
                        RelatedEntityType = "Task",
                        RelatedEntityID = taskId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Notifications.Add(notification);
                }

                // If approved, mark task as Done
                if (approveDto.Approve)
                {
                    task.Status = "Done";
                    task.CompletedAt = DateTime.UtcNow;
                    
                    // Log to AI system
                    foreach (var assignment in completionRequests)
                    {
                        await _priorityScoringService.LogTaskCompletion(task, assignment.AssigneeUserID);
                    }
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = approveDto.Approve ? "Task completion approved" : "Task completion rejected" });
            }
            catch (DbUpdateException ex)
            {
                return StatusCode(500, new { message = "Database error while approving completion", error = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while approving completion", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // GET: api/tasks/{taskId}/assignments
        [HttpGet("tasks/{taskId}/assignments")]
        public async Task<ActionResult<IEnumerable<TaskAssignmentDto>>> GetTaskAssignments(Guid taskId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Check permission
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var assignments = await _context.TaskAssignments
                .Where(ta => ta.TaskID == taskId)
                .Include(ta => ta.Assignee)
                .Include(ta => ta.Assigner)
                .Include(ta => ta.ApprovedBy)
                .Select(ta => new TaskAssignmentDto
                {
                    TaskID = ta.TaskID,
                    AssigneeUserID = ta.AssigneeUserID,
                    AssigneeName = ta.Assignee.FullName ?? "",
                    AssigneeEmail = ta.Assignee.Email,
                    AssignerUserID = ta.AssignerUserID,
                    AssignerName = ta.Assigner.FullName ?? "",
                    Status = ta.Status.ToString(),
                    AssignedAt = ta.AssignedAt,
                    ResponseAt = ta.ResponseAt,
                    ResponseNote = ta.ResponseNote,
                    CompletionRequestedAt = ta.CompletionRequestedAt,
                    ApprovedAt = ta.ApprovedAt,
                    ApprovedByUserId = ta.ApprovedByUserId,
                    ApprovedByName = ta.ApprovedBy != null ? ta.ApprovedBy.FullName : null,
                    ApprovalNote = ta.ApprovalNote
                })
                .ToListAsync();

            return Ok(assignments);
        }

        // GET: api/tasks/{taskId}/assignment-history
        [HttpGet("tasks/{taskId}/assignment-history")]
        public async Task<ActionResult<IEnumerable<TaskAssignmentHistoryDto>>> GetTaskAssignmentHistory(Guid taskId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Check permission
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var history = await _context.TaskAssignmentHistories
                .Where(tah => tah.TaskID == taskId)
                .Include(tah => tah.Task)
                .Include(tah => tah.Assignee)
                .Include(tah => tah.PreviousAssignee)
                .Include(tah => tah.ActionBy)
                .OrderByDescending(tah => tah.ActionAt)
                .Select(tah => new TaskAssignmentHistoryDto
                {
                    HistoryID = tah.HistoryID,
                    TaskID = tah.TaskID,
                    TaskTitle = tah.Task.Title,
                    AssigneeUserID = tah.AssigneeUserID,
                    AssigneeName = tah.Assignee.FullName ?? tah.Assignee.Email,
                    PreviousAssigneeUserID = tah.PreviousAssigneeUserID,
                    PreviousAssigneeName = tah.PreviousAssignee != null ? (tah.PreviousAssignee.FullName ?? tah.PreviousAssignee.Email) : null,
                    ActionByUserID = tah.ActionByUserID,
                    ActionByName = tah.ActionBy.FullName ?? tah.ActionBy.Email,
                    Action = tah.Action,
                    PreviousStatus = tah.PreviousStatus,
                    NewStatus = tah.NewStatus,
                    Note = tah.Note,
                    ActionAt = tah.ActionAt
                })
                .ToListAsync();

            return Ok(history);
        }

        // DELETE: api/tasks/{taskId}/assignments/{assigneeUserId} - Remove assignment (PM/Owner only)
        [HttpDelete("tasks/{taskId}/assignments/{assigneeUserId}")]
        public async Task<IActionResult> UnassignUserFromTask(Guid taskId, Guid assigneeUserId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Check if user is Owner or ProjectManager
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            
            if (member == null) return Forbid();
            if (member.Role != "Owner" && member.Role != "ProjectManager")
                return StatusCode(403, new { message = "Only Owner or ProjectManager can remove assignments" });

            var assignment = await _context.TaskAssignments
                .FirstOrDefaultAsync(ta => ta.TaskID == taskId && ta.AssigneeUserID == assigneeUserId);

            if (assignment == null) return NotFound("Assignment not found.");

            // Create history record
            var history = new TaskAssignmentHistory
            {
                HistoryID = Guid.NewGuid(),
                TaskID = taskId,
                AssigneeUserID = assigneeUserId,
                ActionByUserID = userId,
                Action = "Unassigned",
                PreviousStatus = assignment.Status.ToString(),
                NewStatus = "Removed",
                ActionAt = DateTime.UtcNow
            };
            _context.TaskAssignmentHistories.Add(history);

            _context.TaskAssignments.Remove(assignment);

            // Activity Log
            var assignee = await _context.Users.FindAsync(assigneeUserId);
            _context.ActivityLogs.Add(new ActivityLog
            {
                LogID = Guid.NewGuid(),
                UserID = userId,
                Action = $"đã gỡ '{assignee?.FullName ?? assignee?.Email}' khỏi công việc '{task.Title}'",
                EntityType = "Task",
                EntityID = taskId,
                Timestamp = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return NoContent();
        }

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

            // Kiểm tra membership và role
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            
            if (member == null) return Forbid();
            
            // Lấy workspace để check owner
            var workspace = await _context.Workspaces.FindAsync(task.WorkspaceID);
            bool isOwnerOrPM = workspace != null && 
                              (workspace.OwnerUserID == userId || 
                               member.Role == "Owner" || 
                               member.Role == "ProjectManager");
            
            // Kiểm tra xem user có được assign task này không
            bool isAssignee = task.TaskAssignments.Any(ta => ta.AssigneeUserID == userId);
            
            // PHÂN QUYỀN THEO ROLE:
            // - Owner/ProjectManager: Có thể đổi sang bất kỳ trạng thái nào
            // - Member: Chỉ có thể đổi task ĐƯỢC GIAO cho mình sang InProgress hoặc Review
            if (!isOwnerOrPM)
            {
                // Member thường: phải là assignee và chỉ được đổi sang InProgress/Review
                if (!isAssignee)
                {
                    return Forbid("Members can only update status of tasks assigned to them.");
                }
                
                string[] allowedMemberStatuses = { "InProgress", "Review" };
                if (!allowedMemberStatuses.Contains(statusDto.NewStatus))
                {
                    return Forbid($"Members can only change status to InProgress or Review. Use assignment workflow for completion approval.");
                }
            }

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

        // POST: api/tasks/{taskId}/tags/{tagId}
        [HttpPost("tasks/{taskId}/tags/{tagId}")]
        public async Task<IActionResult> AddTagToTask(Guid taskId, int tagId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Kiểm tra quyền (phải là member)
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            // Kiểm tra tag tồn tại và thuộc workspace
            var tag = await _context.Tags.FindAsync(tagId);
            if (tag == null || tag.WorkspaceID != task.WorkspaceID)
            {
                return BadRequest("Tag does not exist or does not belong to this workspace.");
            }

            // Kiểm tra đã gán chưa
            var alreadyTagged = await _context.TaskTags
                .AnyAsync(tt => tt.TaskID == taskId && tt.TagID == tagId);
            if (alreadyTagged) return Conflict("Tag is already assigned to this task.");

            var taskTag = new TaskTag
            {
                TaskID = taskId,
                TagID = tagId
            };

            _context.TaskTags.Add(taskTag);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tag added to task successfully" });
        }

        // DELETE: api/tasks/{taskId}/tags/{tagId}
        [HttpDelete("tasks/{taskId}/tags/{tagId}")]
        public async Task<IActionResult> RemoveTagFromTask(Guid taskId, int tagId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Kiểm tra quyền
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var taskTag = await _context.TaskTags
                .FirstOrDefaultAsync(tt => tt.TaskID == taskId && tt.TagID == tagId);

            if (taskTag == null) return NotFound("Tag is not assigned to this task.");

            _context.TaskTags.Remove(taskTag);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/tasks/{taskId}/tags
        [HttpGet("tasks/{taskId}/tags")]
        public async Task<ActionResult<IEnumerable<object>>> GetTaskTags(Guid taskId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Kiểm tra quyền
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var tags = await _context.TaskTags
                .Where(tt => tt.TaskID == taskId)
                .Include(tt => tt.Tag)
                .Select(tt => new
                {
                    TagId = tt.Tag.TagID,
                    TagName = tt.Tag.TagName,
                    Color = tt.Tag.Color
                })
                .ToListAsync();

            return Ok(tags);
        }

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