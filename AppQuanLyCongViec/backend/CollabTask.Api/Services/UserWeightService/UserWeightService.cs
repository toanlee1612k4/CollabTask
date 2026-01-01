using CollabTask.Api.Data;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Task = System.Threading.Tasks.Task;

namespace CollabTask.Api.Services.UserWeightService
{
    public class UserWeightService : IUserWeightService
    {
        private readonly CollabTaskDbContext _context;

        // Trọng số mặc định
        private const decimal DefaultDeadlineWeight = 0.5m;
        private const decimal DefaultImportanceWeight = 0.3m;
        private const decimal DefaultEffortWeight = 0.2m;

        // Tham số học máy
        private const int MinimumInteractionsToLearn = 5; // Cần ít nhất 5 task để bắt đầu học
        private const decimal LearningRate = 0.1m; // Tốc độ học (0.1 = 10%)

        // Ngưỡng phân loại User Traits
        private const decimal TraitThreshold = 0.4m;

        public UserWeightService(CollabTaskDbContext context)
        {
            _context = context;
        }

        public async Task LearnFromTaskCompletion(CollabTask.Api.Models.Task task, Guid userId)
        {
            // Bước 1: Lấy weights hiện tại
            var userWeights = await GetOrCreateUserWeights(userId);

            // Bước 2: Tính toán các scores của task vừa hoàn thành
            decimal deadlineScore = CalculateDeadlineScore(task, task.CompletedAt ?? DateTime.UtcNow);
            decimal importanceScore = CalculateImportanceScore(task);
            decimal effortScore = CalculateEffortScore(task);

            // Bước 3: Lưu vào lịch sử học (đã được xử lý bởi PriorityScoringService)
            // Không cần thêm log ở đây vì LogTaskCompletion đã xử lý

            // Bước 4: Kiểm tra đủ dữ liệu chưa
            var totalInteractions = await _context.UserTaskCompletionLogs
                .CountAsync(log => log.UserID == userId);

            if (totalInteractions >= MinimumInteractionsToLearn)
            {
                // Bước 5: Học và cập nhật weights
                await RecalculateUserWeights(userId);
            }
        }

        public async Task RecalculateUserWeights(Guid userId)
        {
            // Lấy toàn bộ lịch sử completion của user
            var interactions = await _context.UserTaskCompletionLogs
                .Where(log => log.UserID == userId)
                .OrderByDescending(log => log.CompletedTimestamp)
                .Take(50) // Chỉ lấy 50 task gần nhất để tránh quá tải
                .ToListAsync();

            if (interactions.Count < MinimumInteractionsToLearn)
            {
                return; // Chưa đủ dữ liệu để học
            }

            // === THUẬT TOÁN HỌC MÁY ===
            
            // Ý tưởng: Task nào có score cao mà user vẫn complete 
            // → Nghĩa là user ưu tiên yếu tố đó
            
            // Tính trung bình weighted scores
            decimal avgDeadlineScore = interactions.Average(i => i.DeadlineScore);
            decimal avgImportanceScore = interactions.Average(i => i.ImportanceScore);
            decimal avgEffortScore = interactions.Average(i => i.EffortScore);

            // Chuẩn hóa (normalize) để tổng = 1
            decimal totalScore = avgDeadlineScore + avgImportanceScore + avgEffortScore;
            
            if (totalScore == 0)
            {
                return; // Tránh chia cho 0
            }

            // Tính weights mới dựa trên pattern
            decimal newDeadlineWeight = avgDeadlineScore / totalScore;
            decimal newImportanceWeight = avgImportanceScore / totalScore;
            decimal newEffortWeight = avgEffortScore / totalScore;

            // === ADAPTIVE LEARNING: Kết hợp weights cũ và mới ===
            // Công thức: new_weight = old_weight * (1 - learning_rate) + calculated_weight * learning_rate
            
            var userWeights = await GetOrCreateUserWeights(userId);

            userWeights.DeadlineWeight = userWeights.DeadlineWeight * (1 - LearningRate) + newDeadlineWeight * LearningRate;
            userWeights.ImportanceWeight = userWeights.ImportanceWeight * (1 - LearningRate) + newImportanceWeight * LearningRate;
            userWeights.EffortWeight = userWeights.EffortWeight * (1 - LearningRate) + newEffortWeight * LearningRate;

            // Đảm bảo tổng weights = 1 (chuẩn hóa lại)
            decimal sum = userWeights.DeadlineWeight + userWeights.ImportanceWeight + userWeights.EffortWeight;
            userWeights.DeadlineWeight /= sum;
            userWeights.ImportanceWeight /= sum;
            userWeights.EffortWeight /= sum;

            // Tự động phân loại User Trait
            userWeights.DominantTrait = DetermineUserTrait(userWeights);

            userWeights.LastUpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Xác định User Trait dựa trên weights
        /// </summary>
        public UserTrait DetermineUserTrait(UserTaskWeight weights)
        {
            // Procrastinator: DeadlineWeight cao nhất và > 0.4
            if (weights.DeadlineWeight > TraitThreshold && 
                weights.DeadlineWeight > weights.ImportanceWeight && 
                weights.DeadlineWeight > weights.EffortWeight)
            {
                return UserTrait.Procrastinator;
            }

            // Planner: ImportanceWeight cao nhất và > 0.4
            if (weights.ImportanceWeight > TraitThreshold && 
                weights.ImportanceWeight > weights.DeadlineWeight && 
                weights.ImportanceWeight > weights.EffortWeight)
            {
                return UserTrait.Planner;
            }

            // Sprinter: EffortWeight cao nhất và > 0.4
            if (weights.EffortWeight > TraitThreshold && 
                weights.EffortWeight > weights.DeadlineWeight && 
                weights.EffortWeight > weights.ImportanceWeight)
            {
                return UserTrait.Sprinter;
            }

            // Chưa đủ điều kiện phân loại
            return UserTrait.Unknown;
        }

        public async Task<UserTaskWeight> GetOrCreateUserWeights(Guid userId)
        {
            var weights = await _context.UserTaskWeights.FindAsync(userId);

            if (weights == null)
            {
                weights = new UserTaskWeight
                {
                    UserID = userId,
                    DeadlineWeight = DefaultDeadlineWeight,
                    ImportanceWeight = DefaultImportanceWeight,
                    EffortWeight = DefaultEffortWeight,
                    DominantTrait = UserTrait.Unknown,
                    LastUpdatedAt = DateTime.UtcNow
                };

                _context.UserTaskWeights.Add(weights);
                await _context.SaveChangesAsync();
            }

            return weights;
        }

        public async Task ResetUserWeights(Guid userId)
        {
            var weights = await _context.UserTaskWeights.FindAsync(userId);

            if (weights != null)
            {
                weights.DeadlineWeight = DefaultDeadlineWeight;
                weights.ImportanceWeight = DefaultImportanceWeight;
                weights.EffortWeight = DefaultEffortWeight;
                weights.DominantTrait = UserTrait.Unknown;
                weights.LastUpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
            }
        }

        // === HELPER METHODS ===

        private decimal CalculateDeadlineScore(CollabTask.Api.Models.Task task, DateTime completionTime)
        {
            if (task.Deadline == null)
                return 0.5m;

            var daysRemaining = (task.Deadline.Value - completionTime).TotalDays;

            if (daysRemaining < -7) return 0.1m;
            if (daysRemaining < 0) return 0.3m;
            if (daysRemaining < 1) return 1.0m;
            if (daysRemaining < 2) return 0.9m;
            if (daysRemaining < 7) return 0.7m;
            if (daysRemaining < 14) return 0.5m;

            return 0.3m;
        }

        private decimal CalculateImportanceScore(CollabTask.Api.Models.Task task)
        {
            switch (task.Priority?.ToLower())
            {
                case "high": return 1.0m;
                case "medium": return 0.6m;
                case "low": return 0.3m;
                default: return 0.5m;
            }
        }

        private decimal CalculateEffortScore(CollabTask.Api.Models.Task task)
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
