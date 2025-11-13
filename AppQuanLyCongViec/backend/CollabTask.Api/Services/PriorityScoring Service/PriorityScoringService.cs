using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tasks;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Services.PriorityScoringService
{
    public class PriorityScoringService : IPriorityScoringService
    {
        private readonly CollabTaskDbContext _context;
        private readonly IMemoryCache _cache;

        // Trọng số mặc định
        private const decimal DefaultDeadlineWeight = 0.5m;
        private const decimal DefaultImportanceWeight = 0.3m;
        private const decimal DefaultEffortWeight = 0.2m;

        public PriorityScoringService(CollabTaskDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        public async Task<List<TaskDto>> GetSuggestedTasksAsync(Guid userId)
        {
            // 1. Lấy trọng số của người dùng
            var userWeights = await _context.UserTaskWeights.FindAsync(userId);
            if (userWeights == null)
            {
                userWeights = new UserTaskWeight
                {
                    UserID = userId,
                    DeadlineWeight = DefaultDeadlineWeight,
                    ImportanceWeight = DefaultImportanceWeight,
                    EffortWeight = DefaultEffortWeight
                };
            }

            // 2. Lấy các task phù hợp
            var relevantStatuses = new[] { "ToDo", "InProgress", "Overdue" };
            var userTasks = await _context.Tasks
                .Include(t => t.TaskAssignments)
                .Where(t => t.TaskAssignments.Any(ta => ta.AssigneeUserID == userId) 
                         && relevantStatuses.Contains(t.Status))
                .ToListAsync();

            // 3. Tính điểm cho từng task
            var scoredTasks = new List<(Task Task, decimal PriorityScore)>();

            foreach (var task in userTasks)
            {
                decimal deadlineScore = CalculateDeadlineScore(task);
                decimal importanceScore = CalculateImportanceScore(task);
                decimal effortScore = CalculateEffortScore(task);

                decimal priorityScore = (deadlineScore * userWeights.DeadlineWeight) +
                                       (importanceScore * userWeights.ImportanceWeight) +
                                       (effortScore * userWeights.EffortWeight);

                scoredTasks.Add((task, priorityScore));
            }

            // 4. Sắp xếp và chuyển sang DTO
            var sortedTasksWithScore = scoredTasks
                .OrderByDescending(t => t.PriorityScore)
                .ToList();

            var sortedTaskDtos = sortedTasksWithScore
                .Select(t => new TaskDto
                {
                    TaskId = t.Task.TaskID,
                    WorkspaceId = t.Task.WorkspaceID,
                    Title = t.Task.Title,
                    Description = t.Task.Description,
                    Status = t.Task.Status,
                    Priority = t.Task.Priority,
                    Deadline = t.Task.Deadline,
                    EstimatedTimeMinutes = t.Task.EstimatedTimeMinutes,
                    CreatorUserId = t.Task.CreatorUserID,
                    CreatedAt = t.Task.CreatedAt,
                    CompletedAt = t.Task.CompletedAt,
                    AssigneeUserIds = t.Task.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList(),
                    PriorityScore = t.PriorityScore
                })
                .ToList();

            // 5. Lưu vào cache để track WasSuggested
            var cacheKey = $"suggested_{userId}";
            var suggestedIds = sortedTaskDtos.Select(t => t.TaskId).ToList();
            _cache.Set(cacheKey, suggestedIds, TimeSpan.FromHours(24));

            return sortedTaskDtos;
        }

        public async System.Threading.Tasks.Task LogTaskCompletion(Task task, Guid userId)
        {
            // Kiểm tra user có phải assignee không
            var isAssignee = await _context.TaskAssignments
                .AnyAsync(ta => ta.TaskID == task.TaskID && ta.AssigneeUserID == userId);

            if (!isAssignee) return;

            // Tính các điểm số tại thời điểm hoàn thành
            decimal deadlineScore = CalculateDeadlineScore(task, task.CompletedAt ?? DateTime.UtcNow);
            decimal importanceScore = CalculateImportanceScore(task);
            decimal effortScore = CalculateEffortScore(task);

            // Kiểm tra cache để lấy WasSuggested
            var cacheKey = $"suggested_{userId}";
            bool wasSuggested = false;
            if (_cache.TryGetValue(cacheKey, out List<Guid>? suggestedIds))
            {
                if (suggestedIds != null && suggestedIds.Contains(task.TaskID))
                {
                    wasSuggested = true;
                }
            }

            // Lưu log vào database
            var completionLog = new UserTaskCompletionLog
            {
                UserID = userId,
                TaskID = task.TaskID,
                CompletedTimestamp = task.CompletedAt ?? DateTime.UtcNow,
                DeadlineScore = deadlineScore,
                ImportanceScore = importanceScore,
                EffortScore = effortScore,
                WasSuggested = wasSuggested
            };

            _context.UserTaskCompletionLogs.Add(completionLog);
            await _context.SaveChangesAsync();
        }

        // =================================================================
        // HÀM HELPER TÍNH ĐIỂM
        // =================================================================

        private decimal CalculateDeadlineScore(Task task, DateTime? completionTime = null)
        {
            if (task.Deadline == null)
                return 0.5m;

            var checkTime = completionTime ?? DateTime.UtcNow;
            var daysRemaining = (task.Deadline.Value - checkTime).TotalDays;

            if (daysRemaining < -7) return 0.1m;
            if (daysRemaining < 0) return 0.3m;
            if (daysRemaining < 1) return 1.0m;
            if (daysRemaining < 2) return 0.9m;
            if (daysRemaining < 7) return 0.7m;
            if (daysRemaining < 14) return 0.5m;

            return 0.3m;
        }

        private decimal CalculateImportanceScore(Task task)
        {
            switch (task.Priority?.ToLower())
            {
                case "high": return 1.0m;
                case "medium": return 0.6m;
                case "low": return 0.3m;
                default: return 0.5m;
            }
        }

        private decimal CalculateEffortScore(Task task)
        {
            if (task.EstimatedTimeMinutes == null || task.EstimatedTimeMinutes <= 0)
                return 0.5m;

            var minutes = task.EstimatedTimeMinutes.Value;

            if (minutes <= 60) return 1.0m;
            if (minutes <= 240) return 0.7m;

            return 0.4m;
        }
    }
}