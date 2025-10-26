using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Comments;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [Route("api/comments")] // Đặt route prefix riêng cho comments
    [ApiController]
    [Authorize]
    public class CommentsController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public CommentsController(CollabTaskDbContext context)
        {
            _context = context;
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
