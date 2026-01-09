using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace CollabTask.Api.Hubs
{
    /// <summary>
    /// SignalR Hub cho Real-time Notifications
    /// 
    /// Client Events (Server -> Client):
    /// - ReceiveNotification: Nhận thông báo mới
    /// - TaskAssigned: Nhận thông báo khi được gán task
    /// - TaskUpdated: Nhận thông báo khi task được cập nhật
    /// - TaskDeleted: Nhận thông báo khi task bị xóa
    /// 
    /// Server Methods (Client -> Server):
    /// - JoinWorkspace: Join vào group workspace để nhận updates
    /// - LeaveWorkspace: Rời khỏi group workspace
    /// - JoinUserChannel: Join vào channel cá nhân (userId)
    /// </summary>
    [Authorize]
    public class NotificationHub : Hub
    {
        private readonly ILogger<NotificationHub> _logger;

        public NotificationHub(ILogger<NotificationHub> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Được gọi khi client connect
        /// Tự động join vào channel cá nhân của user
        /// </summary>
        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            if (userId != Guid.Empty)
            {
                // Join user vào channel cá nhân để nhận notification riêng
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation("👤 User {UserId} connected to NotificationHub (ConnectionId: {ConnectionId})", 
                    userId, Context.ConnectionId);
            }
            
            await base.OnConnectedAsync();
        }

        /// <summary>
        /// Được gọi khi client disconnect
        /// </summary>
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = GetUserId();
            if (userId != Guid.Empty)
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation("👤 User {UserId} disconnected from NotificationHub", userId);
            }

            if (exception != null)
            {
                _logger.LogError(exception, "❌ User disconnected with error");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Client gọi để join vào workspace channel
        /// Dùng để nhận real-time updates về tasks trong workspace
        /// </summary>
        public async Task JoinWorkspace(string workspaceId)
        {
            if (!Guid.TryParse(workspaceId, out var wsId))
            {
                _logger.LogWarning("❌ Invalid workspaceId format: {WorkspaceId}", workspaceId);
                return;
            }

            await Groups.AddToGroupAsync(Context.ConnectionId, $"workspace_{workspaceId}");
            _logger.LogInformation("🏢 User {UserId} joined workspace {WorkspaceId}", GetUserId(), workspaceId);
            
            // Thông báo cho client biết đã join thành công
            await Clients.Caller.SendAsync("JoinedWorkspace", new { workspaceId, success = true });
        }

        /// <summary>
        /// Client gọi để rời khỏi workspace channel
        /// </summary>
        public async Task LeaveWorkspace(string workspaceId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"workspace_{workspaceId}");
            _logger.LogInformation("🏢 User {UserId} left workspace {WorkspaceId}", GetUserId(), workspaceId);
            
            await Clients.Caller.SendAsync("LeftWorkspace", new { workspaceId, success = true });
        }

        /// <summary>
        /// Lấy UserId từ JWT Claims
        /// </summary>
        private Guid GetUserId()
        {
            var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier) 
                           ?? Context.User?.FindFirst("nameid");
                           
            if (userIdClaim != null && Guid.TryParse(userIdClaim.Value, out var userId))
            {
                return userId;
            }
            return Guid.Empty;
        }
    }

    /// <summary>
    /// Interface để inject vào Controllers/Services
    /// Cung cấp methods để send notifications từ backend
    /// </summary>
    public interface INotificationService
    {
        /// <summary>
        /// Gửi notification đến 1 user cụ thể
        /// </summary>
        Task SendToUserAsync(Guid userId, NotificationPayload payload);
        
        /// <summary>
        /// Gửi notification đến nhiều users
        /// </summary>
        Task SendToUsersAsync(IEnumerable<Guid> userIds, NotificationPayload payload);
        
        /// <summary>
        /// Gửi notification đến tất cả members trong workspace
        /// </summary>
        Task SendToWorkspaceAsync(Guid workspaceId, NotificationPayload payload);
        
        /// <summary>
        /// Broadcast đến tất cả connected users
        /// </summary>
        Task BroadcastAsync(NotificationPayload payload);
    }

    /// <summary>
    /// Implementation của INotificationService
    /// Sử dụng IHubContext để gửi messages từ bên ngoài Hub
    /// </summary>
    public class NotificationService : INotificationService
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(IHubContext<NotificationHub> hubContext, ILogger<NotificationService> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task SendToUserAsync(Guid userId, NotificationPayload payload)
        {
            try
            {
                await _hubContext.Clients
                    .Group($"user_{userId}")
                    .SendAsync("ReceiveNotification", payload);
                    
                _logger.LogInformation("📤 Sent notification to user {UserId}: {Type}", userId, payload.Type);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to send notification to user {UserId}", userId);
            }
        }

        public async Task SendToUsersAsync(IEnumerable<Guid> userIds, NotificationPayload payload)
        {
            var tasks = userIds.Select(userId => SendToUserAsync(userId, payload));
            await Task.WhenAll(tasks);
        }

        public async Task SendToWorkspaceAsync(Guid workspaceId, NotificationPayload payload)
        {
            try
            {
                await _hubContext.Clients
                    .Group($"workspace_{workspaceId}")
                    .SendAsync("ReceiveNotification", payload);
                    
                _logger.LogInformation("📤 Sent notification to workspace {WorkspaceId}: {Type}", workspaceId, payload.Type);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to send notification to workspace {WorkspaceId}", workspaceId);
            }
        }

        public async Task BroadcastAsync(NotificationPayload payload)
        {
            try
            {
                await _hubContext.Clients.All.SendAsync("ReceiveNotification", payload);
                _logger.LogInformation("📤 Broadcasted notification: {Type}", payload.Type);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to broadcast notification");
            }
        }
    }

    /// <summary>
    /// Payload cho notifications
    /// </summary>
    public class NotificationPayload
    {
        public string Type { get; set; } = string.Empty; // "TaskAssigned", "TaskUpdated", "TaskDeleted", "Comment", etc.
        public string Message { get; set; } = string.Empty;
        public Guid? TaskId { get; set; }
        public Guid? WorkspaceId { get; set; }
        public string? TaskTitle { get; set; }
        public string? WorkspaceName { get; set; }
        public Guid? ActorId { get; set; } // Người thực hiện action
        public string? ActorName { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public Dictionary<string, object>? Metadata { get; set; }
    }
}
