namespace CollabTask.Api.Dtos.Tags
{
    public class TagDto
    {
        public int TagId { get; set; }
        public Guid WorkspaceId { get; set; }
        public string TagName { get; set; } = string.Empty;
        public string Color { get; set; } = string.Empty;
    }
}
