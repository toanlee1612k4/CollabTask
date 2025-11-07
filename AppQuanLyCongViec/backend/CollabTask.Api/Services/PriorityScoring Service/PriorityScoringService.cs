using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tasks;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory; // <-- THÊM USING NÀY
using Task = CollabTask.Api.Models.Task; // Alias

namespace CollabTask.Api.Services.PriorityScoringService
{
    public class PriorityScoringService : IPriorityScoringService
    {
        private readonly CollabTaskDbContext _context;
        private readonly IMemoryCache _cache; // <-- THÊM MEMORY CACHE

        // Trọng số mặc định (cho người dùng mới)
        private const decimal DefaultDeadlineWeight = 0.5m;
        private const decimal DefaultImportanceWeight = 0.3m;
        private const decimal DefaultEffortWeight = 0.2m;

        // Cập nhật Constructor
        public PriorityScoringService(CollabTaskDbContext context, IMemoryCache cache) // <-- INJECT CACHE
        {
            _context = context;
            _cache = cache; // <-- LƯU LẠI CACHE
        }

        public async Task<List<TaskDto>> GetSuggestedTasksAsync(Guid userId)
        {
            // 1. Lấy trọng số (W) của người dùng
            var userWeights = await _context.UserTaskWeights.FindAsync(userId);
            if (userWeights == null)
            {
                // Nếu không có, dùng trọng số mặc định
                userWeights = new UserTaskWeight
                {
                    UserID = userId,
                    DeadlineWeight = DefaultDeadlineWeight,
                    ImportanceWeight = DefaultImportanceWeight,
                    EffortWeight = DefaultEffortWeight
                };
            }

            // 2. Lấy các task phù hợp để gợi ý (ToDo, InProgress, Overdue)
            var relevantStatuses = new[] { "ToDo", "InProgress", "Overdue" };
            var userTasks = await _context.Tasks
                .Include(t => t.TaskAssignments)
                .Where(t => t.TaskAssignments.Any(ta => ta.AssigneeUserID == userId) && relevantStatuses.Contains(t.Status))
                .ToListAsync();

            // 3. Tính điểm cho từng task
            var scoredTasks = new List<(Task Task, decimal PriorityScore)>();

            foreach (var task in userTasks)
            {
                decimal deadlineScore = CalculateDeadlineScore(task);
                decimal importanceScore = CalculateImportanceScore(task);
                decimal effortScore = CalculateEffortScore(task);

                // Áp dụng công thức Weighted Scoring Model
                decimal priorityScore = (userWeights.DeadlineWeight * deadlineScore) +
                                        (userWeights.ImportanceWeight * importanceScore) +
                                        (userWeights.EffortWeight * effortScore);

                scoredTasks.Add((task, priorityScore));
            }

            // 4. Sắp xếp
            var sortedTasksWithScore = scoredTasks
                .OrderByDescending(t => t.PriorityScore)
                .ToList();

            // === SỬA LỖI LOGIC: LƯU LẠI GỢI Ý VÀO CACHE ===
            // Lưu Top 5 TaskID được gợi ý vào cache trong 1 giờ
            var suggestedTaskIds = sortedTasksWithScore
                                    .Select(t => t.Task.TaskID)
                                    .Take(5) // Chỉ lưu Top 5
                                    .ToList();
            
            var cacheKey = $"suggested_{userId}";
            _cache.Set(cacheKey, suggestedTaskIds, TimeSpan.FromHours(1));
            // ===============================================

            // 5. Trả về DTO
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
                    PriorityScore = priorityScore // Thêm điểm số để gỡ lỗi hoặc hiển thị
                })
                .ToList();

            return sortedTaskDtos;
        }

        // Giai đoạn 2: Thu thập dữ liệu
        public async System.Threading.Tasks.Task LogTaskCompletion(Task task, Guid userId) // Thêm System.Threading.Tasks.Task
        {
            // Kiểm tra xem user có phải là assignee không
            var isAssignee = await _context.TaskAssignments
                .AnyAsync(ta => ta.TaskID == task.TaskID && ta.AssigneeUserID == userId);

            if (!isAssignee) return; // Chỉ log nếu người hoàn thành là người được gán

            // Tính các điểm S_D, S_I, S_E tại thời điểm hoàn thành
            decimal deadlineScore = CalculateDeadlineScore(task, task.CompletedAt ?? DateTime.UtcNow);
            decimal importanceScore = CalculateImportanceScore(task);
            decimal effortScore = CalculateEffortScore(task);

            // === SỬA LỖI LOGIC: KIỂM TRA CACHE ĐỂ LẤY `WasSuggested` ===
            var cacheKey = $"suggested_{userId}";
            bool wasSuggested = false;
            if (_cache.TryGetValue(cacheKey, out List<Guid>? suggestedIds))
            {
                if (suggestedIds != null && suggestedIds.Contains(task.TaskID))
                {
                    wasSuggested = true;
                }
            }
            // =======================================================

            var interaction = new UserInteractionForAI
            {
                UserID = userId,
                TaskID = task.TaskID,
                CompletedTimestamp = task.CompletedAt ?? DateTime.UtcNow,
                DeadlineScore = deadlineScore,
                ImportanceScore = importanceScore,
                EffortScore = effortScore,
                WasSuggested = wasSuggested // <-- SỬ DỤNG GIÁ TRỊ ĐÚNG
            };

            _context.UserInteractionsForAI.Add(interaction);
            // SaveChangesAsync() sẽ được gọi ở Controller
        }


        // =================================================================
        // HÀM HELPER TÍNH ĐIỂM THÀNH PHẦN (S)
        // =================================================================

        // S_D - Điểm Deadline (Tính Khẩn cấp)
        private decimal CalculateDeadlineScore(Task task, DateTime? completionTime = null)
        {
            if (task.Deadline == null) return 0; // Không có deadline, không khẩn cấp

            var referenceTime = completionTime ?? DateTime.UtcNow;
            
            // Số ngày còn lại (có thể là số âm nếu quá hạn)
            double daysRemaining = (task.Deadline.Value - referenceTime).TotalDays;

            if (daysRemaining < -7) return 0; // Quá hạn quá 1 tuần, không tính
            if (daysRemaining < 0) return 10; // Đang quá hạn, điểm cao nhất
            if (daysRemaining < 1) return 9;  // Trong ngày hôm nay
            if (daysRemaining < 2) return 8;  // Trong 1-2 ngày
            if (daysRemaining < 7) return 5;  // Trong 1 tuần
            if (daysRemaining < 14) return 2; // Trong 2 tuần
            return 1; // Hơn 2 tuần
        }

        // S_I - Điểm Quan trọng (Do người dùng đặt)
        private decimal CalculateImportanceScore(Task task)
        {
            switch (task.Priority?.ToLower())
            {
                case "high": return 10;
                case "medium": return 5;
                case "low": return 1;
                default: return 5;
            }
        }

        // S_E - Điểm Nỗ lực (Thời gian ước tính)
        private decimal CalculateEffortScore(Task task)
        {
            if (task.EstimatedTimeMinutes == null || task.EstimatedTimeMinutes <= 0) return 1; // Không có ước tính, coi là > 4 giờ

            int minutes = task.EstimatedTimeMinutes.Value;

            if (minutes <= 60) return 10;        // Dưới 1 giờ
            if (minutes <= 240) return 5;       // Từ 1 - 4 giờ
            return 1;                           // Trên 4 giờ
        }
    }
}