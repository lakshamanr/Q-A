using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using InterviewQuestionBank.Models;

namespace InterviewQuestionBank.Data;

public class ApplicationDbContext : IdentityDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Category> Categories { get; set; }
    public DbSet<Question> Questions { get; set; }
    public DbSet<UserFavorite> UserFavorites { get; set; }
    public DbSet<UserProgress> UserProgresses { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Configure Question entity
        builder.Entity<Question>()
            .HasOne(q => q.Category)
            .WithMany(c => c.Questions)
            .HasForeignKey(q => q.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure UserFavorite entity
        builder.Entity<UserFavorite>()
            .HasOne(uf => uf.Question)
            .WithMany(q => q.Favorites)
            .HasForeignKey(uf => uf.QuestionId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure UserProgress entity
        builder.Entity<UserProgress>()
            .HasOne(up => up.Question)
            .WithMany(q => q.UserProgresses)
            .HasForeignKey(up => up.QuestionId)
            .OnDelete(DeleteBehavior.Cascade);

        // Seed Categories
        builder.Entity<Category>().HasData(
            new Category { Id = 1, Name = "C# Fundamentals", Description = "Core C# programming concepts", Icon = "fa-code", ColorCode = "#5B21B6", DisplayOrder = 1, QuestionRangeStart = 21, QuestionRangeEnd = 50 },
            new Category { Id = 2, Name = "ASP.NET MVC", Description = "ASP.NET MVC and Web Development", Icon = "fa-globe", ColorCode = "#059669", DisplayOrder = 2, QuestionRangeStart = 51, QuestionRangeEnd = 90 },
            new Category { Id = 3, Name = "Advanced .NET", Description = "Advanced .NET & ASP.NET Core", Icon = "fa-rocket", ColorCode = "#DC2626", DisplayOrder = 3, QuestionRangeStart = 91, QuestionRangeEnd = 99 },
            new Category { Id = 4, Name = "Azure Cloud", Description = "Azure Cloud Services", Icon = "fa-cloud", ColorCode = "#2563EB", DisplayOrder = 4, QuestionRangeStart = 100, QuestionRangeEnd = 120 },
            new Category { Id = 5, Name = "DevOps & Microservices", Description = "DevOps, CI/CD and Microservices", Icon = "fa-cubes", ColorCode = "#7C3AED", DisplayOrder = 5, QuestionRangeStart = 121, QuestionRangeEnd = 140 },
            new Category { Id = 6, Name = "Advanced Microservices", Description = "Advanced Microservices Patterns", Icon = "fa-project-diagram", ColorCode = "#EA580C", DisplayOrder = 6, QuestionRangeStart = 141, QuestionRangeEnd = 171 },
            new Category { Id = 7, Name = "SQL Server & Database", Description = "SQL Server and Database concepts", Icon = "fa-database", ColorCode = "#0891B2", DisplayOrder = 7, QuestionRangeStart = 172, QuestionRangeEnd = 200 }
        );
    }
}
