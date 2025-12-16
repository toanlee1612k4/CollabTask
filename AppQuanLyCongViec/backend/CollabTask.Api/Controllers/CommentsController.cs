using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Comments;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [Route("api")] // Fixed route to match /api/tasks/{taskId}/comments
    [ApiController]
    [Authorize]
    public class CommentsController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public CommentsController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // GET /api/tasks/{taskId}/comments
        [HttpGet("tasks/{taskId}/comments")]
        public async Task<ActionResult<IEnumerable<CommentDto>>> GetTaskComments(Guid taskId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Kiểm tra quyền truy cập task
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var comments = await _context.Comments
                .Where(c => c.TaskID == taskId)
                .Include(c => c.User)
                .OrderBy(c => c.CreatedAt)
                .Select(c => new CommentDto
                {
                    CommentId = c.CommentID,
                    TaskId = c.TaskID,
                    UserId = c.UserID,
                    UserFullName = c.User.FullName ?? c.User.Email,
                    UserAvatarUrl = c.User.AvatarURL,
                    Content = c.Content,
                    CreatedAt = c.CreatedAt
                })
                .ToListAsync();

            return Ok(comments);
        }

        // POST /api/tasks/{taskId}/comments
        [HttpPost("tasks/{taskId}/comments")]
        public async Task<ActionResult<CommentDto>> CreateComment(Guid taskId, [FromBody] CreateCommentDto createDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return NotFound("Task not found.");

            // Kiểm tra quyền (phải là member của workspace)
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == task.WorkspaceID && wm.UserID == userId);
            if (!isMember) return Forbid();

            var newComment = new Comment
            {
                CommentID = Guid.NewGuid(),
                TaskID = taskId,
                UserID = userId,
                Content = createDto.Content,
                CreatedAt = DateTime.UtcNow
            };

            _context.Comments.Add(newComment);
            await _context.SaveChangesAsync();

            var user = await _context.Users.FindAsync(userId);
            var commentDto = new CommentDto
            {
                CommentId = newComment.CommentID,
                TaskId = newComment.TaskID,
                UserId = newComment.UserID,
                UserFullName = user?.FullName ?? user?.Email ?? "Unknown",
                UserAvatarUrl = user?.AvatarURL,
                Content = newComment.Content,
                CreatedAt = newComment.CreatedAt
            };

            return CreatedAtAction(nameof(GetTaskComments), new { taskId }, commentDto);
        }

        // PUT /api/comments/{commentId}
        [HttpPut("{commentId}")]
        public async Task<IActionResult> UpdateComment(Guid commentId, [FromBody] UpdateCommentDto updateDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var comment = await _context.Comments.FindAsync(commentId);
            if (comment == null) return NotFound();

            // Chỉ chủ sở hữu comment mới được sửa
            if (comment.UserID != userId)
            {
                return Forbid();
            }

            comment.Content = updateDto.Content;
            // Có thể thêm logic cập nhật thời gian chỉnh sửa nếu cần

            await _context.SaveChangesAsync();
            return NoContent(); // Cập nhật thành công
        }

        // DELETE /api/comments/{commentId}
        [HttpDelete("{commentId}")]
        public async Task<IActionResult> DeleteComment(Guid commentId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var comment = await _context.Comments
                                    .Include(c => c.Task) // Include Task để lấy WorkspaceID
                                    .FirstOrDefaultAsync(c => c.CommentID == commentId);
            if (comment == null) return NotFound();

            // Kiểm tra quyền xóa: Chủ sở hữu comment HOẶC Project Manager của workspace chứa task
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == comment.Task.WorkspaceID && wm.UserID == userId);

            bool canDelete = (comment.UserID == userId) || (member != null && member.Role == "ProjectManager");

            if (!canDelete)
            {
                return Forbid();
            }

            _context.Comments.Remove(comment);
            // Có thể thêm Activity Log
            await _context.SaveChangesAsync();
            return NoContent(); // Xóa thành công
        }
    }
}
