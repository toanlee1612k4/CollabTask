using CollabTask.Api.Data;
using CollabTask.Api.Hubs;
using CollabTask.Api.Services.PriorityScoringService;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Services.BackgroundServices
{
    /// <summary>
    /// Background Service tự động đánh dấu task quá hạn
    /// 
    /// DESIGN NOTES:
    /// - BackgroundService là Singleton, còn DbContext là Scoped
    /// - Phải dùng IServiceScopeFactory để tạo scope mới mỗi lần chạy job
    /// - Chạy mỗi 30 phút (theo yêu cầu) thay vì 1 giờ
    /// 
    /// LIFECYCLE:
    /// - Start khi app khởi động
    /// - Chạy liên tục trong background
    /// - Stop gracefully khi app shutdown
    /// </summary>
    public class OverdueTaskService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<OverdueTaskService> _logger;
        
        // Interval: 30 phút (theo yêu cầu)
        private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(30);

        public OverdueTaskService(
            IServiceScopeFactory scopeFactory, 
            ILogger<OverdueTaskService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("⏰ OverdueTaskService STARTED. Checking every {Interval} minutes", _checkInterval.TotalMinutes);

            // Đợi 1 phút sau khi app start để DB hoàn tất init
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    _logger.LogInformation("🔍 Running overdue task check at {Time}", DateTime.UtcNow);
                    await CheckAndMarkOverdueTasks(stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    // Expected when stopping
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error occurred while checking overdue tasks");
                }

                // Chờ 30 phút trước khi check lại
                try
                {
                    await Task.Delay(_checkInterval, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }

            _logger.LogInformation("⏰ OverdueTaskService STOPPED.");
        }

        private async Task CheckAndMarkOverdueTasks(CancellationToken stoppingToken)
        {
            // ===== QUAN TRỌNG: Tạo scope mới để lấy scoped services =====
            using var scope = _scopeFactory.CreateScope();
            
            var context = scope.ServiceProvider.GetRequiredService<CollabTaskDbContext>();
            var priorityService = scope.ServiceProvider.GetRequiredService<IPriorityScoringService>();
            
            // Optional: Lấy NotificationService để gửi real-time notifications
            var notificationService = scope.ServiceProvider.GetService<INotificationService>();

            var now = DateTime.UtcNow;

            // Query: Lấy tasks quá hạn nhưng chưa marked
            // Status phải khác "Done" và "Overdue"
            var overdueTasks = await context.Tasks
                .Where(t => t.Deadline.HasValue 
                         && t.Deadline.Value < now 
                         && t.Status != "Done" 
                         && t.Status != "Overdue")
                .Include(t => t.TaskAssignments)
                .ToListAsync(stoppingToken);

            if (!overdueTasks.Any())
            {
                _logger.LogInformation("✅ No overdue tasks found. All tasks are on track.");
                return;
            }

            _logger.LogWarning("⚠️ Found {Count} overdue tasks. Updating status to 'Overdue'...", overdueTasks.Count);

            // Collect all affected user IDs for cache invalidation
            var affectedUserIds = new HashSet<Guid>();

            foreach (var task in overdueTasks)
            {
                var previousStatus = task.Status;
                task.Status = "Overdue";
                
                _logger.LogInformation(
                    "📌 Task '{Title}' (ID: {TaskId}) marked as Overdue. Previous status: {PreviousStatus}, Deadline: {Deadline}", 
                    task.Title, task.TaskID, previousStatus, task.Deadline);

                // Thu thập user IDs của assignees để invalidate cache
                foreach (var assignment in task.TaskAssignments)
                {
                    affectedUserIds.Add(assignment.AssigneeUserID);
                }

                // Gửi notification real-time cho assignees (nếu có NotificationService)
                if (notificationService != null)
                {
                    foreach (var assignment in task.TaskAssignments)
                    {
                        await notificationService.SendToUserAsync(assignment.AssigneeUserID, new NotificationPayload
                        {
                            Type = "TaskOverdue",
                            Message = $"⚠️ Task '{task.Title}' đã quá hạn!",
                            TaskId = task.TaskID,
                            TaskTitle = task.Title,
                            WorkspaceId = task.WorkspaceID,
                            CreatedAt = DateTime.UtcNow,
                            Metadata = new Dictionary<string, object>
                            {
                                { "deadline", task.Deadline?.ToString("o") ?? "" },
                                { "daysOverdue", (now - task.Deadline!.Value).TotalDays }
                            }
                        });
                    }
                }
            }

            // Save changes
            await context.SaveChangesAsync(stoppingToken);
            
            // Invalidate AI suggestion cache cho tất cả users bị ảnh hưởng
            // Vì task đã overdue, cần tính lại priority scores
            if (affectedUserIds.Any())
            {
                priorityService.InvalidateSuggestedTasksCacheForUsers(affectedUserIds);
                _logger.LogInformation("🔄 Invalidated suggestion cache for {Count} users", affectedUserIds.Count);
            }

            _logger.LogInformation("✅ Successfully marked {Count} tasks as Overdue", overdueTasks.Count);
        }

        public override async Task StopAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("⏰ OverdueTaskService is stopping...");
            await base.StopAsync(stoppingToken);
        }
    }
}
