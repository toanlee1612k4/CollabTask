using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tasks;
using CollabTask.Api.Models;
using CollabTask.Api.Services.UserWeightService;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Services.PriorityScoringService
{
    public class PriorityScoringService : IPriorityScoringService
    {
        private readonly CollabTaskDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly IUserWeightService _userWeightService;

        // Trọng số mặc định
        private const decimal DefaultDeadlineWeight = 0.5m;
        private const decimal DefaultImportanceWeight = 0.3m;
        private const decimal DefaultEffortWeight = 0.2m;

        public PriorityScoringService(CollabTaskDbContext context, IMemoryCache cache, IUserWeightService userWeightService)
        {
            _context = context;
            _cache = cache;
            _userWeightService = userWeightService;
        }

        public async Task<List<TaskDto>> GetSuggestedTasksAsync(Guid userId)
        {
            // Try to get from cache first (5 minutes cache)
            var cacheKey = $"suggested_tasks_{userId}";
            if (_cache.TryGetValue(cacheKey, out List<TaskDto>? cachedTasks) && cachedTasks != null)
            {
                return cachedTasks;
            }

            // 1. Lấy trọng số của người dùng (đã được cá nhân hóa)
            var userWeights = await _userWeightService.GetOrCreateUserWeights(userId);

            // 2. Optimized query - lấy task chưa hoàn thành (BAO GỒM CẢ OVERDUE)
            // QUAN TRỌNG: Không filter theo Deadline >= now để Bob có thể thấy task overdue
            var relevantStatuses = new[] { "ToDo", "InProgress", "Review" };
            var now = DateTime.UtcNow;
            var userTasks = await _context.Tasks
                .AsNoTracking()
                .Where(t => t.TaskAssignments.Any(ta => ta.AssigneeUserID == userId) 
                         && relevantStatuses.Contains(t.Status))
                // REMOVED: && (!t.Deadline.HasValue || t.Deadline.Value >= now)
                // Lý do: Task overdue cần hiển thị với điểm ưu tiên CAO NHẤT
                .Select(t => new 
                {
                    Task = t,
                    AssigneeIds = t.TaskAssignments.Select(ta => ta.AssigneeUserID).ToList()
                })
                .Take(100)
                .ToListAsync();

            // 3. Tính điểm cho từng task
            var scoredTasks = new List<(Task Task, decimal PriorityScore, List<Guid> AssigneeIds)>();

            foreach (var item in userTasks)
            {
                decimal deadlineScore = CalculateDeadlineScore(item.Task);
                decimal importanceScore = CalculateImportanceScore(item.Task);
                decimal effortScore = CalculateEffortScore(item.Task);

                decimal priorityScore = (deadlineScore * userWeights.DeadlineWeight) +
                                       (importanceScore * userWeights.ImportanceWeight) +
                                       (effortScore * userWeights.EffortWeight);

                scoredTasks.Add((item.Task, priorityScore, item.AssigneeIds));
            }

            // 4. Sắp xếp và chuyển sang DTO (top 20 tasks only)
            var sortedTaskDtos = scoredTasks
                .OrderByDescending(t => t.PriorityScore)
                .Take(20) // Only return top 20 suggestions
                .Select(t => 
                {
                    var dto = new TaskDto
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
                        AssigneeUserIds = t.AssigneeIds,
                        PriorityScore = t.PriorityScore
                    };

                    // === EXPLAINABILITY: Giải thích lý do gợi ý ===
                    var (reason, matchedTrait) = GenerateRecommendationExplanation(
                        t.Task, 
                        userWeights, 
                        CalculateDeadlineScore(t.Task),
                        CalculateImportanceScore(t.Task),
                        CalculateEffortScore(t.Task)
                    );

                    dto.RecommendationReason = reason;
                    dto.MatchedTrait = matchedTrait;

                    return dto;
                })
                .ToList();

            // 5. Cache kết quả 5 phút với size tracking
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(5))
                .SetSize(1); // Set size for cache limit
            
            _cache.Set(cacheKey, sortedTaskDtos, cacheOptions);

            return sortedTaskDtos;
        }

        public async System.Threading.Tasks.Task LogTaskCompletion(Models.Task task, Guid userId)
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

            // Kích hoạt AI học từ hành vi người dùng
            await _userWeightService.LearnFromTaskCompletion(task, userId);
            
            // Invalidate cache sau khi hoàn thành task
            InvalidateSuggestedTasksCache(userId);
        }

        /// <summary>
        /// Xóa cache danh sách gợi ý của user để force recalculate
        /// </summary>
        public void InvalidateSuggestedTasksCache(Guid userId)
        {
            var cacheKey = $"suggested_tasks_{userId}";
            _cache.Remove(cacheKey);
        }

        /// <summary>
        /// Xóa cache danh sách gợi ý của nhiều users cùng lúc
        /// </summary>
        public void InvalidateSuggestedTasksCacheForUsers(IEnumerable<Guid> userIds)
        {
            foreach (var userId in userIds)
            {
                InvalidateSuggestedTasksCache(userId);
            }
        }

        // =================================================================
        // HÀM HELPER TÍNH ĐIỂM
        // =================================================================

        /// <summary>
        /// Tính điểm deadline - OVERDUE tasks có điểm CAO NHẤT (1.2-1.5)
        /// Logic: Càng quá hạn lâu → càng cần làm gấp → điểm càng cao
        /// </summary>
        private decimal CalculateDeadlineScore(Task task, DateTime? completionTime = null)
        {
            if (task.Deadline == null)
                return 0.5m;

            var checkTime = completionTime ?? DateTime.UtcNow;
            var daysRemaining = (task.Deadline.Value - checkTime).TotalDays;

            // === OVERDUE BONUS: Task quá hạn cần ưu tiên cao nhất ===
            if (daysRemaining < 0)
            {
                // Quá hạn > 7 ngày: Score = 1.5 (Cực kỳ nghiêm trọng)
                if (daysRemaining < -7) return 1.5m;
                // Quá hạn 3-7 ngày: Score = 1.4
                if (daysRemaining < -3) return 1.4m;
                // Quá hạn 1-3 ngày: Score = 1.3
                if (daysRemaining < -1) return 1.3m;
                // Quá hạn < 1 ngày (vài giờ): Score = 1.2
                return 1.2m;
            }

            // === NORMAL: Task chưa quá hạn ===
            if (daysRemaining < 1) return 1.0m;   // < 24h: Rất gấp
            if (daysRemaining < 2) return 0.9m;   // 1-2 ngày
            if (daysRemaining < 3) return 0.8m;   // 2-3 ngày
            if (daysRemaining < 7) return 0.7m;   // 3-7 ngày
            if (daysRemaining < 14) return 0.5m;  // 1-2 tuần

            return 0.3m; // > 2 tuần: Không gấp
        }

        /// <summary>
        /// Tính điểm độ quan trọng - Hỗ trợ cả "Urgent" priority
        /// </summary>
        private decimal CalculateImportanceScore(Task task)
        {
            switch (task.Priority?.ToLower())
            {
                case "urgent": return 1.2m;  // Cao hơn High
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

        /// <summary>
        /// Tạo lý do giải thích cho recommendation (Explainability)
        /// </summary>
        private (string Reason, string MatchedTrait) GenerateRecommendationExplanation(
            Task task,
            UserTaskWeight userWeights,
            decimal deadlineScore,
            decimal importanceScore,
            decimal effortScore)
        {
            var trait = userWeights.DominantTrait;
            string traitName = GetTraitDisplayName(trait);
            string reason;

            // === KIỂM TRA OVERDUE TRƯỚC - ĐÂY LÀ ƯU TIÊN CAO NHẤT ===
            var daysRemaining = task.Deadline.HasValue 
                ? (task.Deadline.Value - DateTime.UtcNow).TotalDays 
                : double.MaxValue;

            if (daysRemaining < 0)
            {
                var overdueDays = Math.Abs(daysRemaining);
                if (overdueDays >= 1)
                {
                    reason = $"🔴 CẢNH BÁO: Task này đã QUÁ HẠN {overdueDays:F0} ngày! Cần xử lý NGAY LẬP TỨC.";
                }
                else
                {
                    var overdueHours = overdueDays * 24;
                    reason = $"🔴 CẢNH BÁO: Task này đã QUÁ HẠN {overdueHours:F0} giờ! Cần xử lý NGAY LẬP TỨC.";
                }
                return (reason, "⚠️ OVERDUE");
            }

            // === NORMAL FLOW: Dựa theo User Trait ===
            switch (trait)
            {
                case UserTrait.Sprinter:
                    var minutes = task.EstimatedTimeMinutes ?? 0;
                    reason = minutes > 0 
                        ? $"⚡ Gợi ý vì bạn thích việc nhanh - Task này chỉ tốn {minutes} phút."
                        : $"⚡ Gợi ý vì bạn là '{traitName}' - thường ưu tiên task ngắn.";
                    break;

                case UserTrait.Procrastinator:
                    if (daysRemaining < 1)
                        reason = $"🔥 GẤP: Task này SẮP QUÁ HẠN trong {Math.Max(0, daysRemaining * 24):F1} giờ!";
                    else if (daysRemaining < 3)
                        reason = $"⏰ Gợi ý vì task này còn {daysRemaining:F1} ngày (sát deadline).";
                    else
                        reason = $"📅 Gợi ý dựa trên deadline - phù hợp với phong cách của bạn.";
                    break;

                case UserTrait.Planner:
                    var priority = task.Priority?.ToLower() ?? "medium";
                    if (priority == "urgent" || priority == "high")
                        reason = $"🎯 Gợi ý vì đây là task quan trọng (Priority: {task.Priority}).";
                    else
                        reason = $"📊 Gợi ý dựa trên độ ưu tiên - phù hợp với phong cách quy hoạch.";
                    break;

                default: // Unknown
                    reason = "🤖 Gợi ý dựa trên AI (đang học về phong cách làm việc của bạn).";
                    traitName = "Chưa xác định";
                    break;
            }

            return (reason, traitName);
        }

        private string GetTraitDisplayName(UserTrait trait)
        {
            return trait switch
            {
                UserTrait.Sprinter => "The Sprinter - Người chạy nước rút",
                UserTrait.Procrastinator => "The Procrastinator - Người nước đến chân mới nhảy",
                UserTrait.Planner => "The Planner - Người quy hoạch",
                _ => "Chưa xác định"
            };
        }
    }
}
