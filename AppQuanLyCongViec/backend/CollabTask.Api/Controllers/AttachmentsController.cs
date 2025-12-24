using CollabTask.Api.Data;
using CollabTask.Api.Dtos.Attachments;
using CollabTask.Api.Helpers;
using CollabTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/tasks")]
    [Authorize]
    public class AttachmentsController : ControllerBase
    {
        private readonly CollabTaskDbContext _context;
        private readonly IWebHostEnvironment _environment;
        private const long MaxFileSize = 10 * 1024 * 1024; // 10MB
        private readonly string[] AllowedExtensions = { ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".png", ".jpg", ".jpeg", ".gif", ".txt", ".zip" };

        public AttachmentsController(CollabTaskDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        // GET: api/tasks/{taskId}/attachments
        [HttpGet("{taskId}/attachments")]
        public async Task<ActionResult<IEnumerable<AttachmentDto>>> GetTaskAttachments(Guid taskId)
        {
            try
            {
                var userId = User.GetUserId();

                // Check if user has access to this task
                var task = await _context.Tasks
                    .AsNoTracking()
                    .Include(t => t.Workspace)
                    .ThenInclude(w => w.Members)
                    .FirstOrDefaultAsync(t => t.TaskID == taskId);

                if (task == null)
                    return NotFound(new { message = "Task not found" });

                var isMember = task.Workspace.Members.Any(m => m.UserID == userId);
                if (!isMember)
                    return Forbid();

                // ⚡ PERFORMANCE: AsNoTracking() for read-only query
                var attachments = await _context.TaskAttachments
                    .AsNoTracking()
                    .Where(a => a.TaskID == taskId)
                    .Include(a => a.UploadedBy)
                    .OrderByDescending(a => a.UploadedAt)
                    .Select(a => new AttachmentDto
                    {
                        AttachmentID = a.AttachmentID,
                        TaskID = a.TaskID,
                        UploadedByUserID = a.UploadedByUserID,
                        UploadedByName = a.UploadedBy.FullName,
                        FileName = a.FileName,
                        FileType = a.FileType ?? "unknown",
                        FileSize = a.FileSize,
                        UploadedAt = a.UploadedAt,
                        DownloadUrl = $"/api/tasks/{taskId}/attachments/{a.AttachmentID}/download"
                    })
                    .ToListAsync();

                return Ok(attachments);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error fetching attachments", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // POST: api/tasks/{taskId}/attachments
        [HttpPost("{taskId}/attachments")]
        [ApiExplorerSettings(IgnoreApi = true)] // Hide from Swagger due to IFormFile limitations
        public async Task<ActionResult<AttachmentDto>> UploadAttachment(
            Guid taskId, 
            IFormFile file)
        {
            try
            {
                var userId = User.GetUserId();

                // Check if user has access to this task
                var task = await _context.Tasks
                    .Include(t => t.Workspace)
                    .ThenInclude(w => w.Members)
                    .Include(t => t.TaskAssignments)
                    .FirstOrDefaultAsync(t => t.TaskID == taskId);

                if (task == null)
                    return NotFound(new { message = "Task not found" });

                var isMember = task.Workspace.Members.Any(m => m.UserID == userId);
                if (!isMember)
                    return Forbid();

                // Only assignees can upload attachments
                var isAssignee = task.TaskAssignments.Any(ta => ta.AssigneeUserID == userId);
                if (!isAssignee)
                    return StatusCode(403, new { message = "Only users assigned to this task can upload attachments" });

                // Validate file
                if (file == null || file.Length == 0)
                    return BadRequest(new { message = "No file uploaded" });

                if (file.Length > MaxFileSize)
                    return BadRequest(new { message = $"File size exceeds {MaxFileSize / 1024 / 1024}MB limit" });

                var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!AllowedExtensions.Contains(extension))
                    return BadRequest(new { message = $"File type {extension} is not allowed" });

                // Create uploads directory if not exists
                var uploadsFolder = Path.Combine(_environment.ContentRootPath, "uploads", "tasks", taskId.ToString());
                Directory.CreateDirectory(uploadsFolder);

                // Generate unique filename
                var uniqueFileName = $"{Guid.NewGuid()}{extension}";
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                // Save file to disk
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Save to database
                var attachment = new TaskAttachment
                {
                    AttachmentID = Guid.NewGuid(),
                    TaskID = taskId,
                    UploadedByUserID = userId,
                    FileName = file.FileName,
                    FilePath = Path.Combine("uploads", "tasks", taskId.ToString(), uniqueFileName),
                    FileType = file.ContentType,
                    FileSize = file.Length,
                    UploadedAt = DateTime.UtcNow
                };

                _context.TaskAttachments.Add(attachment);

                // Log activity
                _context.ActivityLogs.Add(new ActivityLog
                {
                    LogID = Guid.NewGuid(),
                    UserID = userId,
                    Action = $"đã tải lên file: {file.FileName}",
                    EntityType = "Task",
                    EntityID = taskId,
                    Timestamp = DateTime.UtcNow
                });

                await _context.SaveChangesAsync();

                var user = await _context.Users.FindAsync(userId);
                var attachmentDto = new AttachmentDto
                {
                    AttachmentID = attachment.AttachmentID,
                    TaskID = attachment.TaskID,
                    UploadedByUserID = attachment.UploadedByUserID,
                    UploadedByName = user?.FullName ?? "Unknown",
                    FileName = attachment.FileName,
                    FileType = attachment.FileType ?? "unknown",
                    FileSize = attachment.FileSize,
                    UploadedAt = attachment.UploadedAt,
                    DownloadUrl = $"/api/tasks/{taskId}/attachments/{attachment.AttachmentID}/download"
                };

                return CreatedAtAction(nameof(GetTaskAttachments), new { taskId }, attachmentDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error uploading file", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        // GET: api/tasks/{taskId}/attachments/{attachmentId}/download
        [HttpGet("{taskId}/attachments/{attachmentId}/download")]
        public async Task<IActionResult> DownloadAttachment(Guid taskId, Guid attachmentId)
        {
            try
            {
                var userId = User.GetUserId();

                // Check access
                var task = await _context.Tasks
                    .Include(t => t.Workspace)
                    .ThenInclude(w => w.Members)
                    .FirstOrDefaultAsync(t => t.TaskID == taskId);

                if (task == null)
                    return NotFound(new { message = "Task not found" });

                var isMember = task.Workspace.Members.Any(m => m.UserID == userId);
                if (!isMember)
                    return Forbid();

                var attachment = await _context.TaskAttachments.FindAsync(attachmentId);
                if (attachment == null || attachment.TaskID != taskId)
                    return NotFound(new { message = "Attachment not found" });

                var filePath = Path.Combine(_environment.ContentRootPath, attachment.FilePath);
                if (!System.IO.File.Exists(filePath))
                    return NotFound(new { message = "File not found on server" });

                var fileBytes = await System.IO.File.ReadAllBytesAsync(filePath);
                var contentType = attachment.FileType ?? "application/octet-stream";

                return File(fileBytes, contentType, attachment.FileName);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error downloading file", error = ex.Message });
            }
        }

        // DELETE: api/tasks/{taskId}/attachments/{attachmentId}
        [HttpDelete("{taskId}/attachments/{attachmentId}")]
        public async Task<IActionResult> DeleteAttachment(Guid taskId, Guid attachmentId)
        {
            try
            {
                var userId = User.GetUserId();

                var attachment = await _context.TaskAttachments
                    .Include(a => a.Task)
                    .ThenInclude(t => t.Workspace)
                    .ThenInclude(w => w.Members)
                    .FirstOrDefaultAsync(a => a.AttachmentID == attachmentId && a.TaskID == taskId);

                if (attachment == null)
                    return NotFound(new { message = "Attachment not found" });

                // Only uploader, task creator, or workspace owner/PM can delete
                var member = attachment.Task.Workspace.Members.FirstOrDefault(m => m.UserID == userId);
                if (member == null)
                    return Forbid();

                var canDelete = attachment.UploadedByUserID == userId ||
                                attachment.Task.CreatorUserID == userId ||
                                member.Role == "Owner" ||
                                member.Role == "ProjectManager";

                if (!canDelete)
                    return Forbid();

                // Delete file from disk
                var filePath = Path.Combine(_environment.ContentRootPath, attachment.FilePath);
                if (System.IO.File.Exists(filePath))
                {
                    System.IO.File.Delete(filePath);
                }

                // Delete from database
                _context.TaskAttachments.Remove(attachment);

                // Log activity
                _context.ActivityLogs.Add(new ActivityLog
                {
                    LogID = Guid.NewGuid(),
                    UserID = userId,
                    Action = $"đã xóa file: {attachment.FileName}",
                    EntityType = "Task",
                    EntityID = taskId,
                    Timestamp = DateTime.UtcNow
                });

                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting attachment", error = ex.Message, stackTrace = ex.StackTrace });
            }
        }
    }
}
