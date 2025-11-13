namespace CollabTask.Api.Dtos.Workspaces
{
    public class WorkspaceDto
    {
        public Guid WorkspaceID { get; set; }
        public int Id { get; set; }
        public string WorkspaceName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public Guid OwnerUserID { get; set; }
        public bool IsPersonal { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}