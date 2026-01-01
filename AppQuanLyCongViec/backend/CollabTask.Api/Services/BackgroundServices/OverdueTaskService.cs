using CollabTask.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Services.BackgroundServices
{
    /// <summary>
    /// Background Service tự động đánh dấu task quá hạn
    /// Chạy mỗi giờ để cập nhật status
    /// </summary>
    public class OverdueTaskService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<OverdueTaskService> _logger;
        private readonly TimeSpan _checkInterval = TimeSpan.FromHours(1);

        public OverdueTaskService(IServiceProvider serviceProvider, ILogger<OverdueTaskService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("⏰ OverdueTaskService started. Will check every {Interval}", _checkInterval);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckAndMarkOverdueTasks();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error occurred while checking overdue tasks");
                }

                // Chờ 1 giờ trước khi check lại
                await Task.Delay(_checkInterval, stoppingToken);
            }

            _logger.LogInformation("⏰ OverdueTaskService stopped.");
        }

        private async Task CheckAndMarkOverdueTasks()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<CollabTaskDbContext>();

            var now = DateTime.UtcNow;

            // Tìm tasks quá hạn nhưng chưa hoàn thành
            var overdueTasks = await context.Tasks
                .Where(t => t.Deadline.HasValue 
                         && t.Deadline.Value < now 
                         && t.Status != "Done" 
                         && t.Status != "Overdue")
                .ToListAsync();

            if (overdueTasks.Any())
            {
                _logger.LogWarning("⚠️ Found {Count} overdue tasks. Updating status to 'Overdue'...", overdueTasks.Count);

                foreach (var task in overdueTasks)
                {
                    task.Status = "Overdue";
                    _logger.LogInformation("📌 Task '{Title}' (ID: {TaskId}) marked as Overdue", task.Title, task.TaskID);
                }

                await context.SaveChangesAsync();
                _logger.LogInformation("✅ Successfully marked {Count} tasks as Overdue", overdueTasks.Count);
            }
            else
            {
                _logger.LogInformation("✅ No overdue tasks found. All tasks are on track.");
            }
        }
    }
}
