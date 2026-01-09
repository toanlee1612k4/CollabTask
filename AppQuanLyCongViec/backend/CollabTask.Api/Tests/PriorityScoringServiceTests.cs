using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tasks;
using CollabTask.Api.Models;
using CollabTask.Api.Services.PriorityScoringService;
using CollabTask.Api.Services.UserWeightService;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Moq;
using Xunit;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Tests
{
    /// <summary>
    /// Unit Tests cho AI Priority Scoring Algorithm
    /// Test các scenarios khác nhau dựa trên User Traits
    /// </summary>
    public class PriorityScoringServiceTests : IDisposable
    {
        private readonly CollabTaskDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly Mock<IUserWeightService> _mockUserWeightService;
        private readonly PriorityScoringService _service;
        private readonly Guid _testUserId;

        public PriorityScoringServiceTests()
        {
            // Setup InMemory Database
            var options = new DbContextOptionsBuilder<CollabTaskDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            
            _context = new CollabTaskDbContext(options);
            
            // Setup Memory Cache
            _cache = new MemoryCache(new MemoryCacheOptions
            {
                SizeLimit = 1024 // Set size limit for testing
            });
            
            // Setup Mock UserWeightService
            _mockUserWeightService = new Mock<IUserWeightService>();
            
            // Create test user ID
            _testUserId = Guid.NewGuid();

            // Create service instance
            _service = new PriorityScoringService(_context, _cache, _mockUserWeightService.Object);
        }

        public void Dispose()
        {
            _context.Database.EnsureDeleted();
            _context.Dispose();
            _cache.Dispose();
        }

        #region Helper Methods

        /// <summary>
        /// Tạo test task với các tham số cơ bản
        /// </summary>
        private Task CreateTestTask(
            string title, 
            DateTime? deadline = null, 
            string priority = "Medium",
            int? estimatedMinutes = null,
            Guid? workspaceId = null)
        {
            var wsId = workspaceId ?? Guid.NewGuid();
            var taskId = Guid.NewGuid();
            
            var task = new Task
            {
                TaskID = taskId,
                WorkspaceID = wsId,
                Title = title,
                Description = $"Test task: {title}",
                Status = "ToDo",
                Priority = priority,
                Deadline = deadline,
                EstimatedTimeMinutes = estimatedMinutes,
                CreatorUserID = _testUserId,
                CreatedAt = DateTime.UtcNow
            };

            return task;
        }

        /// <summary>
        /// Thêm task và assignment vào context
        /// </summary>
        private async System.Threading.Tasks.Task AddTaskWithAssignment(Task task)
        {
            _context.Tasks.Add(task);
            
            var assignment = new TaskAssignment
            {
                TaskID = task.TaskID,
                AssigneeUserID = _testUserId,
                AssignedAt = DateTime.UtcNow,
                AssignerUserID = _testUserId
            };
            
            _context.TaskAssignments.Add(assignment);
            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Setup mock để trả về UserTaskWeight với trait cụ thể
        /// </summary>
        private void SetupUserWeightMock(
            decimal deadlineWeight, 
            decimal importanceWeight, 
            decimal effortWeight,
            UserTrait trait)
        {
            var weights = new UserTaskWeight
            {
                UserID = _testUserId,
                DeadlineWeight = deadlineWeight,
                ImportanceWeight = importanceWeight,
                EffortWeight = effortWeight,
                DominantTrait = trait,
                LastUpdatedAt = DateTime.UtcNow
            };

            _mockUserWeightService
                .Setup(s => s.GetOrCreateUserWeights(_testUserId))
                .ReturnsAsync(weights);
        }

        #endregion

        #region Test Case 1: The Procrastinator

        /// <summary>
        /// TEST CASE 1: "The Procrastinator" - Người nước đến chân mới nhảy
        /// 
        /// User Profile:
        /// - DeadlineWeight = 0.8 (ưu tiên deadline cao)
        /// - ImportanceWeight = 0.1
        /// - EffortWeight = 0.1
        /// - DominantTrait = Procrastinator
        /// 
        /// Scenario:
        /// - Task A: Deadline 1 giờ nữa (urgent)
        /// - Task B: Deadline 5 ngày nữa (not urgent)
        /// 
        /// Expected Result: Task A có PriorityScore CAO HƠN Task B
        /// Lý do: Procrastinator ưu tiên làm task sát deadline
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_Procrastinator_ShouldPrioritizeUrgentDeadline()
        {
            // Arrange
            // Setup user weights cho "The Procrastinator"
            SetupUserWeightMock(
                deadlineWeight: 0.8m,
                importanceWeight: 0.1m,
                effortWeight: 0.1m,
                trait: UserTrait.Procrastinator
            );

            var workspaceId = Guid.NewGuid();

            // Task A: Deadline 1 giờ nữa (very urgent)
            var taskA = CreateTestTask(
                title: "Task A - 1 hour deadline",
                deadline: DateTime.UtcNow.AddHours(1),
                priority: "Medium",
                estimatedMinutes: 60,
                workspaceId: workspaceId
            );

            // Task B: Deadline 5 ngày nữa (not urgent)
            var taskB = CreateTestTask(
                title: "Task B - 5 days deadline",
                deadline: DateTime.UtcNow.AddDays(5),
                priority: "Medium",
                estimatedMinutes: 60,
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(taskA);
            await AddTaskWithAssignment(taskB);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.NotNull(suggestedTasks);
            Assert.Equal(2, suggestedTasks.Count);

            // Task A (1 hour deadline) should be ranked higher
            var taskAResult = suggestedTasks.First(t => t.Title == "Task A - 1 hour deadline");
            var taskBResult = suggestedTasks.First(t => t.Title == "Task B - 5 days deadline");

            Assert.True(taskAResult.PriorityScore > taskBResult.PriorityScore,
                $"Task A (urgent) score {taskAResult.PriorityScore} should be higher than Task B score {taskBResult.PriorityScore}");

            // Task A should be first in the list
            Assert.Equal("Task A - 1 hour deadline", suggestedTasks[0].Title);

            // Verify recommendation reason contains "Procrastinator"
            Assert.Contains("Procrastinator", taskAResult.MatchedTrait);
        }

        /// <summary>
        /// Test Procrastinator với task overdue (đã quá hạn)
        /// NEW LOGIC: Task quá hạn có score CAO NHẤT (1.2-1.5) để hiện lên đầu
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_Procrastinator_ShouldPrioritizeOverdueTasks()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.8m,
                importanceWeight: 0.1m,
                effortWeight: 0.1m,
                trait: UserTrait.Procrastinator
            );

            var workspaceId = Guid.NewGuid();

            // Task A: Already overdue (1 day ago) - DeadlineScore = 1.3
            var overdueTask = CreateTestTask(
                title: "Overdue Task",
                deadline: DateTime.UtcNow.AddDays(-1),
                workspaceId: workspaceId
            );

            // Task B: Due tomorrow - DeadlineScore = 1.0
            var validTask = CreateTestTask(
                title: "Valid Task",
                deadline: DateTime.UtcNow.AddDays(1),
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(overdueTask);
            await AddTaskWithAssignment(validTask);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert - Overdue task should be FIRST (highest score)
            Assert.Equal(2, suggestedTasks.Count);
            Assert.Equal("Overdue Task", suggestedTasks[0].Title);
            Assert.True(suggestedTasks[0].PriorityScore > suggestedTasks[1].PriorityScore,
                $"Overdue ({suggestedTasks[0].PriorityScore}) should score higher than Valid ({suggestedTasks[1].PriorityScore})");
        }

        #endregion

        #region Test Case 2: The Sprinter

        /// <summary>
        /// TEST CASE 2: "The Sprinter" - Người chạy nước rút
        /// 
        /// User Profile:
        /// - DeadlineWeight = 0.1
        /// - ImportanceWeight = 0.1
        /// - EffortWeight = 0.8 (ưu tiên task ngắn)
        /// - DominantTrait = Sprinter
        /// 
        /// Scenario:
        /// - Task A: EstimatedTime = 30 phút (quick task)
        /// - Task B: EstimatedTime = 240 phút (4 giờ - long task)
        /// 
        /// Expected Result: Task A có PriorityScore CAO HƠN Task B
        /// Lý do: Sprinter thích làm task ngắn để "clear" nhanh
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_Sprinter_ShouldPrioritizeQuickTasks()
        {
            // Arrange
            // Setup user weights cho "The Sprinter"
            SetupUserWeightMock(
                deadlineWeight: 0.1m,
                importanceWeight: 0.1m,
                effortWeight: 0.8m,
                trait: UserTrait.Sprinter
            );

            var workspaceId = Guid.NewGuid();

            // Task A: Quick task (30 minutes)
            var taskA = CreateTestTask(
                title: "Task A - Quick 30min",
                deadline: DateTime.UtcNow.AddDays(7),
                priority: "Medium",
                estimatedMinutes: 30,
                workspaceId: workspaceId
            );

            // Task B: Long task (4 hours = 240 minutes)
            var taskB = CreateTestTask(
                title: "Task B - Long 4hours",
                deadline: DateTime.UtcNow.AddDays(7),
                priority: "Medium",
                estimatedMinutes: 240,
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(taskA);
            await AddTaskWithAssignment(taskB);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.NotNull(suggestedTasks);
            Assert.Equal(2, suggestedTasks.Count);

            // Task A (30min) should be ranked higher than Task B (4 hours)
            var taskAResult = suggestedTasks.First(t => t.Title == "Task A - Quick 30min");
            var taskBResult = suggestedTasks.First(t => t.Title == "Task B - Long 4hours");

            Assert.True(taskAResult.PriorityScore > taskBResult.PriorityScore,
                $"Task A (quick) score {taskAResult.PriorityScore} should be higher than Task B (long) score {taskBResult.PriorityScore}");

            // Task A should be first in the list
            Assert.Equal("Task A - Quick 30min", suggestedTasks[0].Title);

            // Verify recommendation reason contains "Sprinter"
            Assert.Contains("Sprinter", taskAResult.MatchedTrait);
        }

        /// <summary>
        /// Test Sprinter với nhiều task có effort khác nhau
        /// Verify thứ tự dựa trên algorithm thực tế:
        /// - <= 60 min: score 1.0
        /// - <= 240 min: score 0.7
        /// - > 240 min: score 0.4
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_Sprinter_ShouldSortByEffortCorrectly()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.1m,
                importanceWeight: 0.1m,
                effortWeight: 0.8m,
                trait: UserTrait.Sprinter
            );

            var workspaceId = Guid.NewGuid();

            // Create tasks with different effort levels
            var task30min = CreateTestTask("Task 30min", estimatedMinutes: 30, workspaceId: workspaceId);
            var task60min = CreateTestTask("Task 60min", estimatedMinutes: 60, workspaceId: workspaceId);
            var task120min = CreateTestTask("Task 120min", estimatedMinutes: 120, workspaceId: workspaceId);
            var task480min = CreateTestTask("Task 480min", estimatedMinutes: 480, workspaceId: workspaceId); // > 240

            // Add in random order
            await AddTaskWithAssignment(task480min);
            await AddTaskWithAssignment(task60min);
            await AddTaskWithAssignment(task30min);
            await AddTaskWithAssignment(task120min);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.Equal(4, suggestedTasks.Count);

            var score30 = suggestedTasks.First(t => t.Title == "Task 30min").PriorityScore;
            var score60 = suggestedTasks.First(t => t.Title == "Task 60min").PriorityScore;
            var score120 = suggestedTasks.First(t => t.Title == "Task 120min").PriorityScore;
            var score480 = suggestedTasks.First(t => t.Title == "Task 480min").PriorityScore;

            // Tasks <= 60 min have effort score 1.0, so both 30min and 60min have same high score
            Assert.Equal(score30, score60);
            
            // Tasks 61-240 min have effort score 0.7
            Assert.True(score60 > score120, $"60min ({score60}) should score higher than 120min ({score120})");
            
            // 120min (score 0.7) should equal any task <= 240 min
            // But > 240 min (like 480min) has score 0.4
            Assert.True(score120 > score480, $"120min ({score120}) should score higher than 480min ({score480})");
        }

        #endregion

        #region Test Case 3: The Planner

        /// <summary>
        /// TEST CASE 3: "The Planner" - Người quy hoạch
        /// 
        /// User Profile:
        /// - DeadlineWeight = 0.1
        /// - ImportanceWeight = 0.8 (ưu tiên task quan trọng)
        /// - EffortWeight = 0.1
        /// - DominantTrait = Planner
        /// 
        /// Scenario:
        /// - Task A: Priority = High
        /// - Task B: Priority = Low
        /// 
        /// Expected Result: Task A có PriorityScore CAO HƠN Task B
        /// Lý do: Planner làm việc theo độ ưu tiên/quan trọng
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_Planner_ShouldPrioritizeHighPriorityTasks()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.1m,
                importanceWeight: 0.8m,
                effortWeight: 0.1m,
                trait: UserTrait.Planner
            );

            var workspaceId = Guid.NewGuid();

            // Task A: High Priority
            var taskA = CreateTestTask(
                title: "Task A - High Priority",
                deadline: DateTime.UtcNow.AddDays(14),
                priority: "High",
                estimatedMinutes: 60,
                workspaceId: workspaceId
            );

            // Task B: Low Priority
            var taskB = CreateTestTask(
                title: "Task B - Low Priority",
                deadline: DateTime.UtcNow.AddDays(1), // Even closer deadline, but low priority
                priority: "Low",
                estimatedMinutes: 60,
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(taskA);
            await AddTaskWithAssignment(taskB);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.NotNull(suggestedTasks);
            Assert.Equal(2, suggestedTasks.Count);

            var taskAResult = suggestedTasks.First(t => t.Title == "Task A - High Priority");
            var taskBResult = suggestedTasks.First(t => t.Title == "Task B - Low Priority");

            Assert.True(taskAResult.PriorityScore > taskBResult.PriorityScore,
                $"Task A (High Priority) score {taskAResult.PriorityScore} should be higher than Task B (Low Priority) score {taskBResult.PriorityScore}");

            // Verify recommendation reason contains "Planner"
            Assert.Contains("Planner", taskAResult.MatchedTrait);
        }

        #endregion

        #region Cache Tests

        /// <summary>
        /// Test cache invalidation
        /// Sau khi invalidate, gọi lại phải tính toán lại từ đầu
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task InvalidateSuggestedTasksCache_ShouldClearCacheCorrectly()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.5m,
                importanceWeight: 0.3m,
                effortWeight: 0.2m,
                trait: UserTrait.Unknown
            );

            var workspaceId = Guid.NewGuid();
            var task = CreateTestTask("Test Task", workspaceId: workspaceId);
            await AddTaskWithAssignment(task);

            // Act - First call (populate cache)
            var firstResult = await _service.GetSuggestedTasksAsync(_testUserId);

            // Invalidate cache
            _service.InvalidateSuggestedTasksCache(_testUserId);

            // Thêm task mới
            var newTask = CreateTestTask("New Task", workspaceId: workspaceId);
            await AddTaskWithAssignment(newTask);

            // Call again
            var secondResult = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.Single(firstResult);
            Assert.Equal(2, secondResult.Count); // Should include new task
        }

        /// <summary>
        /// Test cache được sử dụng đúng cách
        /// Gọi 2 lần liên tiếp không nên query DB lần 2
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_ShouldUseCacheOnSecondCall()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.5m,
                importanceWeight: 0.3m,
                effortWeight: 0.2m,
                trait: UserTrait.Unknown
            );

            var workspaceId = Guid.NewGuid();
            var task = CreateTestTask("Test Task", workspaceId: workspaceId);
            await AddTaskWithAssignment(task);

            // Act
            var firstResult = await _service.GetSuggestedTasksAsync(_testUserId);
            var secondResult = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert - Same reference from cache
            Assert.Same(firstResult, secondResult);
        }

        /// <summary>
        /// Test batch cache invalidation cho nhiều users
        /// </summary>
        [Fact]
        public void InvalidateSuggestedTasksCacheForUsers_ShouldClearAllUserCaches()
        {
            // Arrange
            var userIds = new List<Guid>
            {
                Guid.NewGuid(),
                Guid.NewGuid(),
                Guid.NewGuid()
            };

            // Populate cache manually
            foreach (var userId in userIds)
            {
                var cacheKey = $"suggested_tasks_{userId}";
                _cache.Set(cacheKey, new List<TaskDto>(), new MemoryCacheEntryOptions().SetSize(1));
            }

            // Act
            _service.InvalidateSuggestedTasksCacheForUsers(userIds);

            // Assert - All caches should be cleared
            foreach (var userId in userIds)
            {
                var cacheKey = $"suggested_tasks_{userId}";
                Assert.False(_cache.TryGetValue(cacheKey, out _));
            }
        }

        #endregion

        #region Edge Cases

        /// <summary>
        /// Test với task không có deadline
        /// Task không deadline nên có deadlineScore = 0.5
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_TaskWithoutDeadline_ShouldGetDefaultScore()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.8m,
                importanceWeight: 0.1m,
                effortWeight: 0.1m,
                trait: UserTrait.Procrastinator
            );

            var workspaceId = Guid.NewGuid();

            // Task without deadline
            var taskNoDeadline = CreateTestTask(
                title: "No Deadline Task",
                deadline: null,
                priority: "High",
                workspaceId: workspaceId
            );

            // Task with urgent deadline
            var taskUrgent = CreateTestTask(
                title: "Urgent Task",
                deadline: DateTime.UtcNow.AddHours(1),
                priority: "Low",
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(taskNoDeadline);
            await AddTaskWithAssignment(taskUrgent);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            var noDeadlineResult = suggestedTasks.First(t => t.Title == "No Deadline Task");
            var urgentResult = suggestedTasks.First(t => t.Title == "Urgent Task");

            // Urgent task should still be higher due to deadline score 1.0 vs 0.5
            Assert.True(urgentResult.PriorityScore > noDeadlineResult.PriorityScore);
        }

        /// <summary>
        /// Test với task không có EstimatedTimeMinutes
        /// Task không có estimate nên có effortScore = 0.5
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_TaskWithoutEstimate_ShouldGetDefaultScore()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.1m,
                importanceWeight: 0.1m,
                effortWeight: 0.8m,
                trait: UserTrait.Sprinter
            );

            var workspaceId = Guid.NewGuid();

            // Task without estimate
            var taskNoEstimate = CreateTestTask(
                title: "No Estimate Task",
                estimatedMinutes: null,
                workspaceId: workspaceId
            );

            // Quick task with estimate
            var taskQuick = CreateTestTask(
                title: "Quick Task",
                estimatedMinutes: 30,
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(taskNoEstimate);
            await AddTaskWithAssignment(taskQuick);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            var noEstimateResult = suggestedTasks.First(t => t.Title == "No Estimate Task");
            var quickResult = suggestedTasks.First(t => t.Title == "Quick Task");

            // Quick task should be higher due to effort score 1.0 vs 0.5
            Assert.True(quickResult.PriorityScore > noEstimateResult.PriorityScore);
        }

        /// <summary>
        /// Test với user không có task nào
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_NoTasks_ShouldReturnEmptyList()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.5m,
                importanceWeight: 0.3m,
                effortWeight: 0.2m,
                trait: UserTrait.Unknown
            );

            // No tasks added

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.NotNull(suggestedTasks);
            Assert.Empty(suggestedTasks);
        }

        /// <summary>
        /// Test với task có status "Done" - không nên xuất hiện
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_CompletedTasks_ShouldBeExcluded()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.5m,
                importanceWeight: 0.3m,
                effortWeight: 0.2m,
                trait: UserTrait.Unknown
            );

            var workspaceId = Guid.NewGuid();

            // Completed task
            var completedTask = CreateTestTask("Completed Task", workspaceId: workspaceId);
            completedTask.Status = "Done";
            completedTask.CompletedAt = DateTime.UtcNow;

            // Active task
            var activeTask = CreateTestTask("Active Task", workspaceId: workspaceId);
            activeTask.Status = "ToDo";

            await AddTaskWithAssignment(completedTask);
            await AddTaskWithAssignment(activeTask);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            Assert.Single(suggestedTasks);
            Assert.Equal("Active Task", suggestedTasks[0].Title);
        }

        #endregion

        #region Score Calculation Verification

        /// <summary>
        /// Verify công thức tính điểm:
        /// PriorityScore = (DeadlineScore * DeadlineWeight) + 
        ///                 (ImportanceScore * ImportanceWeight) + 
        ///                 (EffortScore * EffortWeight)
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_ShouldCalculateScoreCorrectly()
        {
            // Arrange
            // Balanced weights
            SetupUserWeightMock(
                deadlineWeight: 0.5m,
                importanceWeight: 0.3m,
                effortWeight: 0.2m,
                trait: UserTrait.Unknown
            );

            var workspaceId = Guid.NewGuid();

            // Task with known scores:
            // - Deadline < 1 day => DeadlineScore = 1.0
            // - Priority = High => ImportanceScore = 1.0
            // - EstimatedTime <= 60 => EffortScore = 1.0
            var perfectTask = CreateTestTask(
                title: "Perfect Task",
                deadline: DateTime.UtcNow.AddHours(12),
                priority: "High",
                estimatedMinutes: 30,
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(perfectTask);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            var result = suggestedTasks.First();

            // Expected score = (1.0 * 0.5) + (1.0 * 0.3) + (1.0 * 0.2) = 1.0
            Assert.Equal(1.0m, result.PriorityScore);
        }

        /// <summary>
        /// Verify với task có tất cả scores thấp
        /// </summary>
        [Fact]
        public async System.Threading.Tasks.Task GetSuggestedTasks_LowScoreTask_ShouldCalculateCorrectly()
        {
            // Arrange
            SetupUserWeightMock(
                deadlineWeight: 0.5m,
                importanceWeight: 0.3m,
                effortWeight: 0.2m,
                trait: UserTrait.Unknown
            );

            var workspaceId = Guid.NewGuid();

            // Task with low scores:
            // - Deadline > 14 days => DeadlineScore = 0.3
            // - Priority = Low => ImportanceScore = 0.3
            // - EstimatedTime > 240 => EffortScore = 0.4
            var lowScoreTask = CreateTestTask(
                title: "Low Score Task",
                deadline: DateTime.UtcNow.AddDays(30),
                priority: "Low",
                estimatedMinutes: 480, // 8 hours
                workspaceId: workspaceId
            );

            await AddTaskWithAssignment(lowScoreTask);

            // Act
            var suggestedTasks = await _service.GetSuggestedTasksAsync(_testUserId);

            // Assert
            var result = suggestedTasks.First();

            // Expected score = (0.3 * 0.5) + (0.3 * 0.3) + (0.4 * 0.2) = 0.15 + 0.09 + 0.08 = 0.32
            Assert.Equal(0.32m, result.PriorityScore);
        }

        #endregion
    }
}
