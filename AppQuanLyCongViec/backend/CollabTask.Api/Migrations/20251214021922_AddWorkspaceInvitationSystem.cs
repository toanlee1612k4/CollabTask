using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CollabTask.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkspaceInvitationSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WorkspaceInvitations",
                columns: table => new
                {
                    InvitationID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    WorkspaceID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Role = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    InvitedByUserID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RespondedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Message = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkspaceInvitations", x => x.InvitationID);
                    table.ForeignKey(
                        name: "FK_WorkspaceInvitations_Users_InvitedByUserID",
                        column: x => x.InvitedByUserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WorkspaceInvitations_Workspaces_WorkspaceID",
                        column: x => x.WorkspaceID,
                        principalTable: "Workspaces",
                        principalColumn: "WorkspaceID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WorkspaceInvitation_Workspace_Email_Status",
                table: "WorkspaceInvitations",
                columns: new[] { "WorkspaceID", "Email", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_WorkspaceInvitations_InvitedByUserID",
                table: "WorkspaceInvitations",
                column: "InvitedByUserID");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WorkspaceInvitations");
        }
    }
}
