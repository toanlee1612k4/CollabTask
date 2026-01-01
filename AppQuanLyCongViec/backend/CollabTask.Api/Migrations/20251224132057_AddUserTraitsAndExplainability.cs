using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CollabTask.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddUserTraitsAndExplainability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DominantTrait",
                table: "UserTaskWeights",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DominantTrait",
                table: "UserTaskWeights");
        }
    }
}
