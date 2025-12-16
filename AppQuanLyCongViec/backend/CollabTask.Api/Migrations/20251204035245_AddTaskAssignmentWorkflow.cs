using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CollabTask.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTaskAssignmentWorkflow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ApprovalNote",
                table: "TaskAssignments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ApprovedAt",
                table: "TaskAssignments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ApprovedByUserId",
                table: "TaskAssignments",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "AssignerUserID",
                table: "TaskAssignments",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            // Update existing TaskAssignments to set AssignerUserID to the task creator
            migrationBuilder.Sql(@"
                UPDATE ta
                SET ta.AssignerUserID = t.CreatorUserID
                FROM TaskAssignments ta
                INNER JOIN Tasks t ON ta.TaskID = t.TaskID
                WHERE ta.AssignerUserID = '00000000-0000-0000-0000-000000000000'
            ");

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletionRequestedAt",
                table: "TaskAssignments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ResponseAt",
                table: "TaskAssignments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResponseNote",
                table: "TaskAssignments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "TaskAssignments",
                type: "int",
                nullable: false,
                defaultValue: 0);
                
            // Update existing TaskAssignments status to Accepted (1) instead of Pending (0)
            migrationBuilder.Sql(@"
                UPDATE TaskAssignments
                SET Status = 1
                WHERE Status = 0
            ");

            migrationBuilder.AddColumn<Guid>(
                name: "RelatedEntityID",
                table: "Notifications",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RelatedEntityType",
                table: "Notifications",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TaskAssignmentHistories",
                columns: table => new
                {
                    HistoryID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TaskID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AssigneeUserID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PreviousAssigneeUserID = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ActionByUserID = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PreviousStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    NewStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ActionAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskAssignmentHistories", x => x.HistoryID);
                    table.ForeignKey(
                        name: "FK_TaskAssignmentHistories_Tasks_TaskID",
                        column: x => x.TaskID,
                        principalTable: "Tasks",
                        principalColumn: "TaskID",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TaskAssignmentHistories_Users_ActionByUserID",
                        column: x => x.ActionByUserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TaskAssignmentHistories_Users_AssigneeUserID",
                        column: x => x.AssigneeUserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TaskAssignmentHistories_Users_PreviousAssigneeUserID",
                        column: x => x.PreviousAssigneeUserID,
                        principalTable: "Users",
                        principalColumn: "UserID",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TaskAssignments_ApprovedByUserId",
                table: "TaskAssignments",
                column: "ApprovedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_TaskAssignments_AssignerUserID",
                table: "TaskAssignments",
                column: "AssignerUserID");

            migrationBuilder.CreateIndex(
                name: "IX_TaskAssignmentHistories_ActionByUserID",
                table: "TaskAssignmentHistories",
                column: "ActionByUserID");

            migrationBuilder.CreateIndex(
                name: "IX_TaskAssignmentHistories_AssigneeUserID",
                table: "TaskAssignmentHistories",
                column: "AssigneeUserID");

            migrationBuilder.CreateIndex(
                name: "IX_TaskAssignmentHistories_PreviousAssigneeUserID",
                table: "TaskAssignmentHistories",
                column: "PreviousAssigneeUserID");

            migrationBuilder.CreateIndex(
                name: "IX_TaskAssignmentHistories_TaskID",
                table: "TaskAssignmentHistories",
                column: "TaskID");

            migrationBuilder.AddForeignKey(
                name: "FK_TaskAssignments_Users_ApprovedByUserId",
                table: "TaskAssignments",
                column: "ApprovedByUserId",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_TaskAssignments_Users_AssignerUserID",
                table: "TaskAssignments",
                column: "AssignerUserID",
                principalTable: "Users",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TaskAssignments_Users_ApprovedByUserId",
                table: "TaskAssignments");

            migrationBuilder.DropForeignKey(
                name: "FK_TaskAssignments_Users_AssignerUserID",
                table: "TaskAssignments");

            migrationBuilder.DropTable(
                name: "TaskAssignmentHistories");

            migrationBuilder.DropIndex(
                name: "IX_TaskAssignments_ApprovedByUserId",
                table: "TaskAssignments");

            migrationBuilder.DropIndex(
                name: "IX_TaskAssignments_AssignerUserID",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ApprovalNote",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ApprovedAt",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ApprovedByUserId",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "AssignerUserID",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "CompletionRequestedAt",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ResponseAt",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ResponseNote",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "RelatedEntityID",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "RelatedEntityType",
                table: "Notifications");
        }
    }
}
