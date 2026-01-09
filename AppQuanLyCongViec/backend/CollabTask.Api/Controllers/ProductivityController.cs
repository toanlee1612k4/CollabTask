using CollabTask.Api.Data;
using CollabTask.Api.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/productivity")]
    [Authorize]
    public class ProductivityController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public ProductivityController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // GET: api/productivity/dashboard - Get current user's productivity stats
        [HttpGet("dashboard")]
        [HttpGet("stats")]
        public async Task<IActionResult> GetMyProductivityDashboard([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

            var start = startDate ?? DateTime.UtcNow.AddMonths(-1);
            var end = endDate ?? DateTime.UtcNow;

            // ⚡ PERFORMANCE: Add AsNoTracking() to all read-only queries
            // Total tasks assigned (in date range for trend analysis)
            var totalAssigned = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.AssignedAt >= start 
                    && ta.AssignedAt <= end)
                .CountAsync();

            // ✅ Total tasks completed (ALL TIME - không filter theo date range)
            // Đây là tổng số task đã hoàn thành từ trước đến nay
            var totalCompleted = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Approved)
                .CountAsync();

            // Total completed in date range (for trend analysis)
            var completedInRange = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Approved
                    && ta.ApprovedAt >= start 
                    && ta.ApprovedAt <= end)
                .CountAsync();

            // Pending tasks
            var totalPending = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Pending)
                .CountAsync();

            // In progress tasks
            var totalInProgress = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && (ta.Status == Models.TaskAssignmentStatus.Accepted 
                        || ta.Status == Models.TaskAssignmentStatus.InProgress))
                .CountAsync();

            // Awaiting approval
            var totalAwaitingApproval = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.CompletionRequested)
                .CountAsync();

            // Rejected tasks
            var totalRejected = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Rejected)
                .CountAsync();

            // ✅ Total tasks ALL TIME (for overall completion rate)
            var totalAssignedAllTime = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId)
                .CountAsync();

            // Completion rate (ALL TIME)
            var completionRate = totalAssignedAllTime > 0 
                ? (double)totalCompleted / totalAssignedAllTime * 100 
                : 0;

            // Completion rate in current period (for trend)
            var completionRateInRange = totalAssigned > 0 
                ? (double)completedInRange / totalAssigned * 100 
                : 0;

            // Average completion time (in days)
            var completionTimes = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Approved
                    && ta.ApprovedAt.HasValue)
                .Select(ta => new 
                { 
                    AssignedAt = ta.AssignedAt,
                    CompletedAt = ta.ApprovedAt!.Value
                })
                .ToListAsync();

            var avgCompletionDays = completionTimes.Any() 
                ? completionTimes.Average(ct => (ct.CompletedAt - ct.AssignedAt).TotalDays)
                : 0;

            // Tasks by priority
            var tasksByPriority = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status != Models.TaskAssignmentStatus.Rejected)
                .Include(ta => ta.Task)
                .GroupBy(ta => ta.Task.Priority)
                .Select(g => new { Priority = g.Key, Count = g.Count() })
                .ToListAsync();

            // Recent completed tasks
            var recentCompleted = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Approved
                    && ta.ApprovedAt >= start 
                    && ta.ApprovedAt <= end)
                .Include(ta => ta.Task)
                .OrderByDescending(ta => ta.ApprovedAt)
                .Take(10)
                .Select(ta => new
                {
                    TaskId = ta.TaskID,
                    TaskTitle = ta.Task.Title,
                    Priority = ta.Task.Priority,
                    AssignedAt = ta.AssignedAt,
                    CompletedAt = ta.ApprovedAt,
                    CompletionDays = ta.ApprovedAt.HasValue 
                        ? (ta.ApprovedAt.Value - ta.AssignedAt).TotalDays 
                        : 0
                })
                .ToListAsync();

            // Task completion trend (last 30 days, grouped by day)
            var last30Days = DateTime.UtcNow.AddDays(-30);
            var completionTrend = await _context.TaskAssignments
                .AsNoTracking()
                .Where(ta => ta.AssigneeUserID == userId 
                    && ta.Status == Models.TaskAssignmentStatus.Approved
                    && ta.ApprovedAt.HasValue
                    && ta.ApprovedAt >= last30Days)
                .GroupBy(ta => ta.ApprovedAt!.Value.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .OrderBy(x => x.Date)
                .ToListAsync();

                return Ok(new
                {
                    summary = new
                    {
                        // Overall stats (ALL TIME)
                        totalCompleted, // Tổng số task hoàn thành từ trước đến nay
                        totalAssigned = totalAssignedAllTime, // Tổng số task được assign từ trước đến nay
                        completionRate = Math.Round(completionRate, 2), // Tỷ lệ hoàn thành ALL TIME
                        
                        // Current period stats (in date range)
                        totalAssignedInPeriod = totalAssigned,
                        completedInPeriod = completedInRange,
                        completionRateInPeriod = Math.Round(completionRateInRange, 2),
                        
                        // Current status
                        totalPending,
                        totalInProgress,
                        totalAwaitingApproval,
                        totalRejected,
                        
                        // Performance metrics
                        avgCompletionDays = Math.Round(avgCompletionDays, 2)
                    },
                    tasksByPriority,
                    recentCompleted,
                    completionTrend,
                    dateRange = new { start, end }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching dashboard data", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // GET: api/productivity/workspace/{workspaceId} - Get workspace productivity stats (PM/Owner only)
        [HttpGet("workspace/{workspaceId}")]
        public async Task<IActionResult> GetWorkspaceProductivity(Guid workspaceId, [FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

            // Check if user is Owner or ProjectManager
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);
            
            if (member == null) return Forbid();
            if (member.Role != "Owner" && member.Role != "ProjectManager")
                return StatusCode(403, new { message = "Only Owner or ProjectManager can view workspace productivity" });

            var start = startDate ?? DateTime.UtcNow.AddMonths(-1);
            var end = endDate ?? DateTime.UtcNow;

            // Get all tasks in workspace
            var workspaceTasks = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId)
                .Select(t => t.TaskID)
                .ToListAsync();

            // Member productivity
            var memberStats = await _context.TaskAssignments
                .Where(ta => workspaceTasks.Contains(ta.TaskID)
                    && ta.AssignedAt >= start 
                    && ta.AssignedAt <= end)
                .Include(ta => ta.Assignee)
                .GroupBy(ta => ta.AssigneeUserID)
                .Select(g => new
                {
                    UserId = g.Key,
                    UserName = g.First().Assignee.FullName ?? g.First().Assignee.Email,
                    TotalAssigned = g.Count(),
                    TotalCompleted = g.Count(ta => ta.Status == Models.TaskAssignmentStatus.Approved),
                    TotalPending = g.Count(ta => ta.Status == Models.TaskAssignmentStatus.Pending),
                    TotalInProgress = g.Count(ta => ta.Status == Models.TaskAssignmentStatus.Accepted 
                        || ta.Status == Models.TaskAssignmentStatus.InProgress),
                    TotalAwaitingApproval = g.Count(ta => ta.Status == Models.TaskAssignmentStatus.CompletionRequested),
                    CompletionRate = g.Count() > 0 
                        ? Math.Round((double)g.Count(ta => ta.Status == Models.TaskAssignmentStatus.Approved) / g.Count() * 100, 2)
                        : 0
                })
                .OrderByDescending(s => s.TotalCompleted)
                .ToListAsync();

            // Total workspace tasks
            var totalTasks = workspaceTasks.Count;
            var completedTasks = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId && t.Status == "Done")
                .CountAsync();

            // Tasks by status
            var tasksByStatus = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId)
                .GroupBy(t => t.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            // Overdue tasks
            var overdueTasks = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId 
                    && t.Status != "Done" 
                    && t.Deadline.HasValue 
                    && t.Deadline < DateTime.UtcNow)
                .Select(t => new
                {
                    TaskId = t.TaskID,
                    Title = t.Title,
                    Deadline = t.Deadline,
                    DaysOverdue = (DateTime.UtcNow - t.Deadline!.Value).TotalDays,
                    AssigneeCount = t.TaskAssignments.Count
                })
                .ToListAsync();

            return Ok(new
            {
                workspaceSummary = new
                {
                    totalTasks,
                    completedTasks,
                    completionRate = totalTasks > 0 ? Math.Round((double)completedTasks / totalTasks * 100, 2) : 0
                },
                tasksByStatus,
                memberStats,
                overdueTasks,
                dateRange = new { start, end }
            });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching workspace productivity", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // GET: api/productivity/user/{targetUserId}/history - Get user's task assignment history
        [HttpGet("user/{targetUserId}/history")]
        public async Task<IActionResult> GetUserTaskHistory(Guid targetUserId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

            // Users can only view their own history, or PMs/Owners can view team members
            if (userId != targetUserId)
            {
                // Check if requester is PM/Owner in any shared workspace
                var hasPermission = await _context.WorkspaceMembers
                    .Where(wm => wm.UserID == userId && (wm.Role == "Owner" || wm.Role == "ProjectManager"))
                    .Join(_context.WorkspaceMembers,
                        pm => pm.WorkspaceID,
                        member => member.WorkspaceID,
                        (pm, member) => new { pm, member })
                    .AnyAsync(x => x.member.UserID == targetUserId);

                if (!hasPermission)
                    return StatusCode(403, new { message = "You don't have permission to view this user's history" });
            }

            var skip = (page - 1) * pageSize;

            var history = await _context.TaskAssignmentHistories
                .Where(tah => tah.AssigneeUserID == targetUserId)
                .Include(tah => tah.Task)
                .Include(tah => tah.ActionBy)
                .OrderByDescending(tah => tah.ActionAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(tah => new
                {
                    HistoryId = tah.HistoryID,
                    TaskId = tah.TaskID,
                    TaskTitle = tah.Task.Title,
                    WorkspaceId = tah.Task.WorkspaceID,
                    Action = tah.Action,
                    PreviousStatus = tah.PreviousStatus,
                    NewStatus = tah.NewStatus,
                    Note = tah.Note,
                    ActionBy = tah.ActionBy.FullName ?? tah.ActionBy.Email,
                    ActionAt = tah.ActionAt
                })
                .ToListAsync();

            var totalCount = await _context.TaskAssignmentHistories
                .Where(tah => tah.AssigneeUserID == targetUserId)
                .CountAsync();

                return Ok(new
                {
                    history,
                    pagination = new
                    {
                        page,
                        pageSize,
                        totalCount,
                        totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching user task history", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // GET: api/productivity/suggested-tasks - AI suggest tasks cho user (chỉ tasks được assign)
        [HttpGet("suggested-tasks")]
        public async Task<IActionResult> GetSuggestedTasks([FromQuery] int limit = 10)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

                var now = DateTime.UtcNow;

                // ✅ SECURE: Lấy tasks được assign cho user và chưa hoàn thành
                // ⚡ PERFORMANCE: Add AsNoTracking()
                var relevantStatuses = new[] { "ToDo", "InProgress", "Review" };
                
                // Lấy task kèm danh sách assignees
                var assignedTasks = await _context.TaskAssignments
                    .AsNoTracking()
                    .Where(ta => ta.AssigneeUserID == userId
                        && (ta.Status == Models.TaskAssignmentStatus.Accepted
                            || ta.Status == Models.TaskAssignmentStatus.InProgress
                            || ta.Status == Models.TaskAssignmentStatus.Pending))
                    .Include(ta => ta.Task)
                        .ThenInclude(t => t.TaskAssignments)
                    .Where(ta => relevantStatuses.Contains(ta.Task.Status))
                    .Select(ta => new
                    {
                        TaskId = ta.Task.TaskID,
                        Title = ta.Task.Title,
                        Description = ta.Task.Description,
                        Priority = ta.Task.Priority,
                        Deadline = ta.Task.Deadline,
                        EstimatedTimeMinutes = ta.Task.EstimatedTimeMinutes,
                        Status = ta.Task.Status,
                        WorkspaceId = ta.Task.WorkspaceID,
                        AssignmentStatus = ta.Status.ToString(),
                        // ✅ FIX: Include AssigneeUserIds từ TaskAssignments
                        AssigneeUserIds = ta.Task.TaskAssignments.Select(x => x.AssigneeUserID).ToList(),
                        // AI Scoring:
                        // Priority: High=3, Medium=2, Low=1
                        // Deadline: Càng gần càng cao điểm (max 5 points)
                        // Status: InProgress > ToDo > Review
                        PriorityScore = ta.Task.Priority == "High" ? 3 : (ta.Task.Priority == "Medium" ? 2 : 1),
                        DeadlineScore = ta.Task.Deadline.HasValue
                            ? (ta.Task.Deadline.Value < now ? 5 : // Quá hạn = cao nhất
                               ta.Task.Deadline.Value <= now.AddDays(1) ? 4 : // Trong 1 ngày
                               ta.Task.Deadline.Value <= now.AddDays(3) ? 3 : // Trong 3 ngày
                               ta.Task.Deadline.Value <= now.AddDays(7) ? 2 : 1) // Trong tuần
                            : 0,
                        StatusScore = ta.Task.Status == "InProgress" ? 3 : (ta.Task.Status == "ToDo" ? 2 : 1)
                    })
                    .ToListAsync();

                // Tính tổng điểm và sắp xếp
                var suggestedTasks = assignedTasks
                    .Select(t => new
                    {
                        t.TaskId,
                        t.Title,
                        t.Description,
                        t.Priority,
                        t.Deadline,
                        t.EstimatedTimeMinutes,
                        t.Status,
                        t.WorkspaceId,
                        t.AssignmentStatus,
                        t.AssigneeUserIds, // ✅ FIX: Include in response
                        SuggestionScore = t.PriorityScore + t.DeadlineScore + t.StatusScore,
                        Reason = GetSuggestionReason(t.Deadline, t.Priority, t.Status, now)
                    })
                    .OrderByDescending(t => t.SuggestionScore)
                    .ThenBy(t => t.Deadline)
                    .Take(limit)
                    .ToList();

                return Ok(new
                {
                    suggestedTasks,
                    message = "Tasks are sorted by AI priority scoring (deadline urgency + priority + current status)",
                    totalCount = suggestedTasks.Count
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error generating task suggestions", error = ex.Message });
            }
        }

        private string GetSuggestionReason(DateTime? deadline, string priority, string status, DateTime now)
        {
            var reasons = new List<string>();
            
            if (deadline.HasValue)
            {
                if (deadline.Value < now)
                    reasons.Add("Overdue");
                else if (deadline.Value <= now.AddDays(1))
                    reasons.Add("Due within 24 hours");
                else if (deadline.Value <= now.AddDays(3))
                    reasons.Add("Due within 3 days");
            }
            
            if (priority == "High")
                reasons.Add("High priority");
            
            if (status == "InProgress")
                reasons.Add("Already in progress");
            
            return reasons.Any() ? string.Join(", ", reasons) : "Recommended";
        }

        // GET: api/productivity/leaderboard/{workspaceId} - Get workspace leaderboard
        [HttpGet("leaderboard/{workspaceId}")]
        public async Task<IActionResult> GetWorkspaceLeaderboard(Guid workspaceId, [FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var userId = User.GetUserId();
                if (userId == Guid.Empty) return Unauthorized(new { message = "Invalid user token" });

            // Check if user is a member
            var isMember = await _context.WorkspaceMembers
                .AsNoTracking()
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);
            
            if (!isMember) return Forbid();

            var start = startDate ?? DateTime.UtcNow.AddMonths(-1);
            var end = endDate ?? DateTime.UtcNow;

            var workspaceTasks = await _context.Tasks
                .Where(t => t.WorkspaceID == workspaceId)
                .Select(t => t.TaskID)
                .ToListAsync();

            var leaderboard = await _context.TaskAssignments
                .Where(ta => workspaceTasks.Contains(ta.TaskID)
                    && ta.Status == Models.TaskAssignmentStatus.Approved
                    && ta.ApprovedAt >= start 
                    && ta.ApprovedAt <= end)
                .Include(ta => ta.Assignee)
                .GroupBy(ta => ta.AssigneeUserID)
                .Select(g => new
                {
                    UserId = g.Key,
                    UserName = g.First().Assignee.FullName ?? g.First().Assignee.Email,
                    AvatarUrl = g.First().Assignee.AvatarURL,
                    TasksCompleted = g.Count(),
                    AvgCompletionDays = g.Average(ta => ta.ApprovedAt.HasValue 
                        ? (ta.ApprovedAt.Value - ta.AssignedAt).TotalDays 
                        : 0)
                })
                .OrderByDescending(s => s.TasksCompleted)
                .ThenBy(s => s.AvgCompletionDays)
                .Take(10)
                .ToListAsync();

                return Ok(new
                {
                    leaderboard,
                    dateRange = new { start, end }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching workspace leaderboard", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }
    }
}
