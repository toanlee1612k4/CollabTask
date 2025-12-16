using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CollabTask.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTaskIndexesForPerformance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Index for AI priority scoring queries
            migrationBuilder.CreateIndex(
                name: "IX_Tasks_AI_Priority",
                table: "Tasks",
                columns: new[] { "CreatorUserID", "Status", "Priority", "Deadline" },
                filter: null);

            // Index for overdue task detection
            migrationBuilder.CreateIndex(
                name: "IX_Tasks_Overdue",
                table: "Tasks",
                columns: new[] { "Deadline", "Status" },
                filter: "[Deadline] IS NOT NULL");

            // Index for workspace queries
            migrationBuilder.CreateIndex(
                name: "IX_Tasks_Workspace_Status",
                table: "Tasks",
                columns: new[] { "WorkspaceID", "Status", "Priority" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Tasks_AI_Priority",
                table: "Tasks");

            migrationBuilder.DropIndex(
                name: "IX_Tasks_Overdue",
                table: "Tasks");

            migrationBuilder.DropIndex(
                name: "IX_Tasks_Workspace_Status",
                table: "Tasks");
        }
    }
}
