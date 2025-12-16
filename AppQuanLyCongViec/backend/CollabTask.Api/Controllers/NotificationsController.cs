using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Notifications;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public NotificationsController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // GET: api/notifications
        [HttpGet]
        public async Task<ActionResult<IEnumerable<NotificationDto>>> GetMyNotifications([FromQuery] bool? isRead = null)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var query = _context.Notifications.Where(n => n.UserID == userId);

            // Lọc theo trạng thái đọc/chưa đọc
            if (isRead.HasValue)
            {
                query = query.Where(n => n.IsRead == isRead.Value);
            }

            var notifications = await query
                .OrderByDescending(n => n.CreatedAt)
                .Take(50) // Giới hạn 50 notification mới nhất
                .Select(n => new NotificationDto
                {
                    NotificationId = n.NotificationID,
                    Message = n.Message,
                    IsRead = n.IsRead,
                    Link = n.Link,
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();

            return Ok(notifications);
        }

        // PUT: api/notifications/{id}/read
        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(Guid id)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) return NotFound();

            // Chỉ chủ sở hữu notification mới được đánh dấu
            if (notification.UserID != userId) return Forbid();

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/notifications/read-all
        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var unreadNotifications = await _context.Notifications
                .Where(n => n.UserID == userId && !n.IsRead)
                .ToListAsync();

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = $"{unreadNotifications.Count} notifications marked as read" });
        }

        // DELETE: api/notifications/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNotification(Guid id)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) return NotFound();

            // Chỉ chủ sở hữu mới được xóa
            if (notification.UserID != userId) return Forbid();

            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/notifications/unread-count
        [HttpGet("unread-count")]
        public async Task<ActionResult<int>> GetUnreadCount()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var count = await _context.Notifications
                .CountAsync(n => n.UserID == userId && !n.IsRead);

            return Ok(new { count });
        }
    }
}
