using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Tags;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [Route("api")]
    [ApiController]
    [Authorize]
    public class TagsController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;

        public TagsController(CollabTaskDbContext context)
        {
            _context = context;
        }

        // POST /api/workspaces/{workspaceId}/tags
        [HttpPost("workspaces/{workspaceId}/tags")]
        public async Task<ActionResult<TagDto>> CreateTag(Guid workspaceId, [FromBody] CreateTagDto createDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            // Kiểm tra xem user có phải là member của workspace không
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);
            if (!isMember) return Forbid();

            // Kiểm tra tag name đã tồn tại trong workspace chưa
            var exists = await _context.Tags
                .AnyAsync(t => t.WorkspaceID == workspaceId && t.TagName == createDto.TagName);
            if (exists)
            {
                return Conflict($"Tag with name '{createDto.TagName}' already exists in this workspace.");
            }

            var newTag = new Tag
            {
                WorkspaceID = workspaceId,
                TagName = createDto.TagName,
                Color = createDto.Color ?? "#CCCCCC"
            };

            _context.Tags.Add(newTag);
            await _context.SaveChangesAsync();

            var tagDto = new TagDto
            {
                TagId = newTag.TagID,
                WorkspaceId = newTag.WorkspaceID,
                TagName = newTag.TagName,
                Color = newTag.Color
            };

            // Trả về kèm theo route để lấy tag mới tạo (best practice)
            return CreatedAtAction(nameof(GetTagById), new { tagId = newTag.TagID }, tagDto);
        }

        // GET /api/workspaces/{workspaceId}/tags
        [HttpGet("workspaces/{workspaceId}/tags")]
        public async Task<ActionResult<IEnumerable<TagDto>>> GetTagsInWorkspace(Guid workspaceId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            // Kiểm tra xem user có phải là member của workspace không
            var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == workspaceId && wm.UserID == userId);
            if (!isMember) return Forbid();

            var tags = await _context.Tags
                .Where(t => t.WorkspaceID == workspaceId)
                .OrderBy(t => t.TagName)
                .Select(t => new TagDto
                {
                    TagId = t.TagID,
                    WorkspaceId = t.WorkspaceID,
                    TagName = t.TagName,
                    Color = t.Color
                })
                .ToListAsync();

            return Ok(tags);
        }

        // GET /api/tags/{tagId} - Helper để CreatedAtAction hoạt động
        [HttpGet("tags/{tagId}", Name = "GetTagById")]
        [ApiExplorerSettings(IgnoreApi = true)] // Ẩn khỏi Swagger nếu không cần public
        public async Task<ActionResult<TagDto>> GetTagById(int tagId)
        {
             var userId = User.GetUserId();
             if (userId == Guid.Empty) return Unauthorized();

             var tag = await _context.Tags.FindAsync(tagId);
             if (tag == null) return NotFound();

             // Kiểm tra quyền truy cập tag (phải là member của workspace chứa tag)
             var isMember = await _context.WorkspaceMembers
                .AnyAsync(wm => wm.WorkspaceID == tag.WorkspaceID && wm.UserID == userId);
             if (!isMember) return Forbid();

             var tagDto = new TagDto
             {
                 TagId = tag.TagID,
                 WorkspaceId = tag.WorkspaceID,
                 TagName = tag.TagName,
                 Color = tag.Color
             };
             return Ok(tagDto);
        }

        // PUT /api/tags/{tagId}
        [HttpPut("tags/{tagId}")]
        public async Task<IActionResult> UpdateTag(int tagId, [FromBody] UpdateTagDto updateDto)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var tag = await _context.Tags.FindAsync(tagId);
            if (tag == null) return NotFound();

            // Kiểm tra quyền (phải là member/PM của workspace chứa tag)
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == tag.WorkspaceID && wm.UserID == userId);
            if (member == null) return Forbid();
            // Có thể thêm logic chỉ PM mới được sửa tag nếu cần
            // if (member.Role != "ProjectManager") return Forbid();

            // Kiểm tra tên tag mới có bị trùng không (trừ chính nó)
             var exists = await _context.Tags
                .AnyAsync(t => t.WorkspaceID == tag.WorkspaceID && t.TagName == updateDto.TagName && t.TagID != tagId);
            if (exists)
            {
                return Conflict($"Tag with name '{updateDto.TagName}' already exists in this workspace.");
            }

            tag.TagName = updateDto.TagName;
            tag.Color = updateDto.Color ?? tag.Color;

            await _context.SaveChangesAsync();
            return NoContent(); // Cập nhật thành công
        }

        // DELETE /api/tags/{tagId}
        [HttpDelete("tags/{tagId}")]
        public async Task<IActionResult> DeleteTag(int tagId)
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var tag = await _context.Tags.FindAsync(tagId);
            if (tag == null) return NotFound();

            // Kiểm tra quyền (phải là member/PM của workspace chứa tag)
            var member = await _context.WorkspaceMembers
                .FirstOrDefaultAsync(wm => wm.WorkspaceID == tag.WorkspaceID && wm.UserID == userId);
            if (member == null) return Forbid();
             // Có thể thêm logic chỉ PM mới được xóa tag nếu cần
            // if (member.Role != "ProjectManager") return Forbid();

            // Lưu ý: Do ràng buộc FK_TaskTags_Tag là NO ACTION,
            // việc xóa tag sẽ thất bại nếu tag đó đang được gán cho task nào đó.
            // Bạn cần xử lý việc này:
            // 1. Hoặc là báo lỗi cho người dùng.
            // 2. Hoặc là tự động gỡ tag khỏi các task trước khi xóa tag (cần thận trọng).

            // Cách 1: Báo lỗi nếu tag đang được sử dụng
            var isUsed = await _context.TaskTags.AnyAsync(tt => tt.TagID == tagId);
            if (isUsed)
            {
                 return BadRequest("Cannot delete tag because it is currently assigned to one or more tasks.");
            }

            _context.Tags.Remove(tag);
            await _context.SaveChangesAsync();
            return NoContent(); // Xóa thành công
        }
    }
}
