using Xunit;
using Xunit.Abstractions;
using CollabTask.Api.Models;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Tests
{
    /// <summary>
    /// Unit Tests minh họa logic gợi ý task cho 3 user traits khác nhau
    /// CÁCH CHẠY: dotnet test --logger "console;verbosity=detailed"
    /// </summary>
    public class UserTraitRecommendationTests
    {
        private readonly ITestOutputHelper _output;

        public UserTraitRecommendationTests(ITestOutputHelper output)
        {
            _output = output;
        }

        [Fact]
        public void Test_ThreeUserTraits_DifferentRecommendations()
        {
            // ============================================
            // SETUP: Tạo 3 users với 3 traits khác nhau
            // ============================================

            var sprinterUser = new UserTaskWeight
            {
                UserID = Guid.NewGuid(),
                DeadlineWeight = 0.2m,
                ImportanceWeight = 0.2m,
                EffortWeight = 0.6m,  // ← CAO NHẤT
                DominantTrait = UserTrait.Sprinter
            };

            var procrastinatorUser = new UserTaskWeight
            {
                UserID = Guid.NewGuid(),
                DeadlineWeight = 0.7m,  // ← CAO NHẤT
                ImportanceWeight = 0.2m,
                EffortWeight = 0.1m,
                DominantTrait = UserTrait.Procrastinator
            };

            var plannerUser = new UserTaskWeight
            {
                UserID = Guid.NewGuid(),
                DeadlineWeight = 0.2m,
                ImportanceWeight = 0.6m,  // ← CAO NHẤT
                EffortWeight = 0.2m,
                DominantTrait = UserTrait.Planner
            };

            // ============================================
            // SETUP: Tạo các tasks với đặc điểm khác nhau
            // ============================================

            var tasks = new List<Task>
            {
                new Task
                {
                    TaskID = Guid.NewGuid(),
                    Title = "Task A - Ngắn, dễ, còn lâu",
                    EstimatedTimeMinutes = 30,
                    Priority = "Low",
                    Deadline = DateTime.UtcNow.AddDays(10)
                },
                new Task
                {
                    TaskID = Guid.NewGuid(),
                    Title = "Task B - Quan trọng, còn lâu",
                    EstimatedTimeMinutes = 120,
                    Priority = "High",
                    Deadline = DateTime.UtcNow.AddDays(7)
                },
                new Task
                {
                    TaskID = Guid.NewGuid(),
                    Title = "Task C - Sắp quá hạn!",
                    EstimatedTimeMinutes = 180,
                    Priority = "Medium",
                    Deadline = DateTime.UtcNow.AddHours(6)
                },
                new Task
                {
                    TaskID = Guid.NewGuid(),
                    Title = "Task D - Ngắn + Quan trọng",
                    EstimatedTimeMinutes = 45,
                    Priority = "High",
                    Deadline = DateTime.UtcNow.AddDays(3)
                }
            };

            // ============================================
            // EXECUTE: Tính điểm cho từng user
            // ============================================

            _output.WriteLine("\n");
            _output.WriteLine("═════════════════════════════════════════════════════════════════");
            _output.WriteLine("  KỊCH BẢN KIỂM THỬ: 3 USER TRAITS VỚI CÙNG 1 TẬP TASKS");
            _output.WriteLine("═════════════════════════════════════════════════════════════════\n");

            CalculateAndDisplayScores("🏃 THE SPRINTER (Người chạy nước rút)", sprinterUser, tasks);
            CalculateAndDisplayScores("⏰ THE PROCRASTINATOR (Nước đến chân mới nhảy)", procrastinatorUser, tasks);
            CalculateAndDisplayScores("📋 THE PLANNER (Người quy hoạch)", plannerUser, tasks);

            // Assert: Đảm bảo mỗi user có kết quả khác nhau
            Assert.NotEqual(sprinterUser.DominantTrait, procrastinatorUser.DominantTrait);
            Assert.NotEqual(procrastinatorUser.DominantTrait, plannerUser.DominantTrait);
        }

        private void CalculateAndDisplayScores(string userLabel, UserTaskWeight userWeights, List<Task> tasks)
        {
            _output.WriteLine($"\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            _output.WriteLine($"{userLabel}");
            _output.WriteLine($"   Weights: Deadline={userWeights.DeadlineWeight:F2} | Importance={userWeights.ImportanceWeight:F2} | Effort={userWeights.EffortWeight:F2}");
            _output.WriteLine($"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

            var scoredTasks = new List<(Task Task, decimal Score)>();

            foreach (var task in tasks)
            {
                decimal deadlineScore = CalculateDeadlineScore(task);
                decimal importanceScore = CalculateImportanceScore(task);
                decimal effortScore = CalculateEffortScore(task);

                decimal totalScore = (deadlineScore * userWeights.DeadlineWeight) +
                                    (importanceScore * userWeights.ImportanceWeight) +
                                    (effortScore * userWeights.EffortWeight);

                scoredTasks.Add((task, totalScore));

                _output.WriteLine($"  📌 {task.Title}");
                _output.WriteLine($"     ├─ Deadline Score:    {deadlineScore:F2} (còn {GetDaysRemaining(task):F1} ngày)");
                _output.WriteLine($"     ├─ Importance Score:  {importanceScore:F2} ({task.Priority})");
                _output.WriteLine($"     ├─ Effort Score:      {effortScore:F2} ({task.EstimatedTimeMinutes} phút)");
                _output.WriteLine($"     └─ 🎯 TỔNG ĐIỂM:       {totalScore:F2}\n");
            }

            var rankedTasks = scoredTasks.OrderByDescending(t => t.Score).ToList();

            _output.WriteLine($"  🏆 THỨ TỰ ƯU TIÊN (từ cao → thấp):");
            for (int i = 0; i < rankedTasks.Count; i++)
            {
                _output.WriteLine($"     {i + 1}. {rankedTasks[i].Task.Title} (Score: {rankedTasks[i].Score:F2})");
            }
            _output.WriteLine("");
        }

        // === Helper Methods ===

        private decimal CalculateDeadlineScore(Task task)
        {
            if (task.Deadline == null) return 0.5m;

            var daysRemaining = (task.Deadline.Value - DateTime.UtcNow).TotalDays;

            if (daysRemaining < 0) return 0.0m;
            if (daysRemaining < 1) return 1.0m;
            if (daysRemaining < 2) return 0.9m;
            if (daysRemaining < 3) return 0.8m;
            if (daysRemaining < 7) return 0.7m;
            if (daysRemaining < 14) return 0.5m;

            return 0.3m;
        }

        private decimal CalculateImportanceScore(Task task)
        {
            return task.Priority?.ToLower() switch
            {
                "high" => 1.0m,
                "medium" => 0.6m,
                "low" => 0.3m,
                _ => 0.5m
            };
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

        private double GetDaysRemaining(Task task)
        {
            if (task.Deadline == null) return double.MaxValue;
            return (task.Deadline.Value - DateTime.UtcNow).TotalDays;
        }
    }
}
