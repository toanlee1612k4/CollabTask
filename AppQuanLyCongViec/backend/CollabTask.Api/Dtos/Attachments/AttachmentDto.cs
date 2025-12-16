namespace CollabTask.Api.Dtos.Attachments
{
    public class AttachmentDto
    {
        public Guid AttachmentID { get; set; }
        public Guid TaskID { get; set; }
        public Guid UploadedByUserID { get; set; }
        public string UploadedByName { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string FileType { get; set; } = string.Empty;
        public long FileSize { get; set; }
        public DateTime UploadedAt { get; set; }
        public string DownloadUrl { get; set; } = string.Empty;
    }
}
