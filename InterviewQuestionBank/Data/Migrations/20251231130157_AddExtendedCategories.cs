using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace InterviewQuestionBank.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddExtendedCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 1,
                column: "QuestionRangeStart",
                value: 1);

            migrationBuilder.InsertData(
                table: "Categories",
                columns: new[] { "Id", "ColorCode", "Description", "DisplayOrder", "Icon", "Name", "QuestionRangeEnd", "QuestionRangeStart" },
                values: new object[,]
                {
                    { 8, "#0891B2", "Advanced SQL and EF Core", 8, "fa-database", "SQL & Entity Framework", 220, 201 },
                    { 9, "#059669", "Modern ASP.NET Core Development", 9, "fa-globe", "ASP.NET Core", 240, 221 },
                    { 10, "#F59E0B", "Software Design Patterns", 10, "fa-drafting-compass", "Design Patterns", 260, 241 },
                    { 11, "#10B981", "Testing Strategies and QA", 11, "fa-check-circle", "Testing & Quality", 280, 261 },
                    { 12, "#EF4444", "Application Security", 12, "fa-shield-alt", "Security", 300, 281 },
                    { 13, "#8B5CF6", "Performance and Optimization", 13, "fa-tachometer-alt", "Performance Optimization", 320, 301 },
                    { 14, "#7C3AED", "Microservices Design", 14, "fa-cubes", "Microservices Architecture", 340, 321 },
                    { 15, "#2563EB", "Cloud Technologies and DevOps", 15, "fa-cloud-upload-alt", "Cloud & DevOps", 360, 341 },
                    { 16, "#DC2626", "Advanced .NET Concepts", 16, "fa-rocket", "Advanced .NET Topics", 380, 361 },
                    { 17, "#5B21B6", "Software Architecture", 17, "fa-sitemap", "Architecture & Design", 400, 381 },
                    { 18, "#0891B2", "Database Architecture and Design", 18, "fa-database", "Database Design", 420, 401 },
                    { 19, "#10B981", "Testing Methodologies", 19, "fa-clipboard-check", "Testing & QA Practices", 440, 421 },
                    { 20, "#EA580C", "Large Scale System Design", 20, "fa-project-diagram", "System Design", 460, 441 },
                    { 21, "#DD0031", "Angular Development", 21, "fa-angular", "Angular Framework", 376, 352 },
                    { 24, "#8B5CF6", "Advanced Testing Strategies and Team Leadership", 24, "fa-users-cog", "Advanced Testing & Leadership", 480, 461 },
                    { 25, "#EF4444", "Application Security and OWASP Standards", 25, "fa-lock", "Security & OWASP", 500, 481 },
                    { 26, "#F59E0B", "Technical Leadership and Team Management", 26, "fa-users", "Leadership & Team Management", 520, 501 },
                    { 27, "#7C3AED", "Large-Scale System Design and Scalability", 27, "fa-network-wired", "System Design & Scalability", 540, 521 },
                    { 28, "#10B981", "Core Behavioral Interview Questions", 28, "fa-comments", "Behavioral Questions - Core", 560, 541 },
                    { 29, "#2563EB", "Advanced Behavioral and Situational Questions", 29, "fa-brain", "Behavioral Questions - Advanced", 571, 561 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 1,
                column: "QuestionRangeStart",
                value: 21);
        }
    }
}
