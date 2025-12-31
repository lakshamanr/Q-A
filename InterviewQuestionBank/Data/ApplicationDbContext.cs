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
            // Original Categories
            new Category { Id = 1, Name = "C# Fundamentals", Description = "Core C# programming concepts", Icon = "fa-code", ColorCode = "#5B21B6", DisplayOrder = 1, QuestionRangeStart = 1, QuestionRangeEnd = 50 },
            new Category { Id = 2, Name = "ASP.NET MVC", Description = "ASP.NET MVC and Web Development", Icon = "fa-globe", ColorCode = "#059669", DisplayOrder = 2, QuestionRangeStart = 51, QuestionRangeEnd = 90 },
            new Category { Id = 3, Name = "Advanced .NET", Description = "Advanced .NET & ASP.NET Core", Icon = "fa-rocket", ColorCode = "#DC2626", DisplayOrder = 3, QuestionRangeStart = 91, QuestionRangeEnd = 99 },
            new Category { Id = 4, Name = "Azure Cloud", Description = "Azure Cloud Services", Icon = "fa-cloud", ColorCode = "#2563EB", DisplayOrder = 4, QuestionRangeStart = 100, QuestionRangeEnd = 120 },
            new Category { Id = 5, Name = "DevOps & Microservices", Description = "DevOps, CI/CD and Microservices", Icon = "fa-cubes", ColorCode = "#7C3AED", DisplayOrder = 5, QuestionRangeStart = 121, QuestionRangeEnd = 140 },
            new Category { Id = 6, Name = "Advanced Microservices", Description = "Advanced Microservices Patterns", Icon = "fa-project-diagram", ColorCode = "#EA580C", DisplayOrder = 6, QuestionRangeStart = 141, QuestionRangeEnd = 171 },
            new Category { Id = 7, Name = "SQL Server & Database", Description = "SQL Server and Database concepts", Icon = "fa-database", ColorCode = "#0891B2", DisplayOrder = 7, QuestionRangeStart = 172, QuestionRangeEnd = 200 },
            
            // Extended Categories (Q201-Q460)
            new Category { Id = 8, Name = "SQL & Entity Framework", Description = "Advanced SQL and EF Core", Icon = "fa-database", ColorCode = "#0891B2", DisplayOrder = 8, QuestionRangeStart = 201, QuestionRangeEnd = 220 },
            new Category { Id = 9, Name = "ASP.NET Core", Description = "Modern ASP.NET Core Development", Icon = "fa-globe", ColorCode = "#059669", DisplayOrder = 9, QuestionRangeStart = 221, QuestionRangeEnd = 240 },
            new Category { Id = 10, Name = "Design Patterns", Description = "Software Design Patterns", Icon = "fa-drafting-compass", ColorCode = "#F59E0B", DisplayOrder = 10, QuestionRangeStart = 241, QuestionRangeEnd = 260 },
            new Category { Id = 11, Name = "Testing & Quality", Description = "Testing Strategies and QA", Icon = "fa-check-circle", ColorCode = "#10B981", DisplayOrder = 11, QuestionRangeStart = 261, QuestionRangeEnd = 280 },
            new Category { Id = 12, Name = "Security", Description = "Application Security", Icon = "fa-shield-alt", ColorCode = "#EF4444", DisplayOrder = 12, QuestionRangeStart = 281, QuestionRangeEnd = 300 },
            new Category { Id = 13, Name = "Performance Optimization", Description = "Performance and Optimization", Icon = "fa-tachometer-alt", ColorCode = "#8B5CF6", DisplayOrder = 13, QuestionRangeStart = 301, QuestionRangeEnd = 320 },
            new Category { Id = 14, Name = "Microservices Architecture", Description = "Microservices Design", Icon = "fa-cubes", ColorCode = "#7C3AED", DisplayOrder = 14, QuestionRangeStart = 321, QuestionRangeEnd = 340 },
            new Category { Id = 15, Name = "Cloud & DevOps", Description = "Cloud Technologies and DevOps", Icon = "fa-cloud-upload-alt", ColorCode = "#2563EB", DisplayOrder = 15, QuestionRangeStart = 341, QuestionRangeEnd = 360 },
            new Category { Id = 16, Name = "Advanced .NET Topics", Description = "Advanced .NET Concepts", Icon = "fa-rocket", ColorCode = "#DC2626", DisplayOrder = 16, QuestionRangeStart = 361, QuestionRangeEnd = 380 },
            new Category { Id = 17, Name = "Architecture & Design", Description = "Software Architecture", Icon = "fa-sitemap", ColorCode = "#5B21B6", DisplayOrder = 17, QuestionRangeStart = 381, QuestionRangeEnd = 400 },
            new Category { Id = 18, Name = "Database Design", Description = "Database Architecture and Design", Icon = "fa-database", ColorCode = "#0891B2", DisplayOrder = 18, QuestionRangeStart = 401, QuestionRangeEnd = 420 },
            new Category { Id = 19, Name = "Testing & QA Practices", Description = "Testing Methodologies", Icon = "fa-clipboard-check", ColorCode = "#10B981", DisplayOrder = 19, QuestionRangeStart = 421, QuestionRangeEnd = 440 },
            new Category { Id = 20, Name = "System Design", Description = "Large Scale System Design", Icon = "fa-project-diagram", ColorCode = "#EA580C", DisplayOrder = 20, QuestionRangeStart = 441, QuestionRangeEnd = 460 },
            
            // Angular Category
            new Category { Id = 21, Name = "Angular Framework", Description = "Angular Development", Icon = "fa-angular", ColorCode = "#DD0031", DisplayOrder = 21, QuestionRangeStart = 352, QuestionRangeEnd = 376 },
            
            // Latest Categories (Q461-Q571)
            new Category { Id = 24, Name = "Advanced Testing & Leadership", Description = "Advanced Testing Strategies and Team Leadership", Icon = "fa-users-cog", ColorCode = "#8B5CF6", DisplayOrder = 24, QuestionRangeStart = 461, QuestionRangeEnd = 480 },
            new Category { Id = 25, Name = "Security & OWASP", Description = "Application Security and OWASP Standards", Icon = "fa-lock", ColorCode = "#EF4444", DisplayOrder = 25, QuestionRangeStart = 481, QuestionRangeEnd = 500 },
            new Category { Id = 26, Name = "Leadership & Team Management", Description = "Technical Leadership and Team Management", Icon = "fa-users", ColorCode = "#F59E0B", DisplayOrder = 26, QuestionRangeStart = 501, QuestionRangeEnd = 520 },
            new Category { Id = 27, Name = "System Design & Scalability", Description = "Large-Scale System Design and Scalability", Icon = "fa-network-wired", ColorCode = "#7C3AED", DisplayOrder = 27, QuestionRangeStart = 521, QuestionRangeEnd = 540 },
            new Category { Id = 28, Name = "Behavioral Questions - Core", Description = "Core Behavioral Interview Questions", Icon = "fa-comments", ColorCode = "#10B981", DisplayOrder = 28, QuestionRangeStart = 541, QuestionRangeEnd = 560 },
            new Category { Id = 29, Name = "Behavioral Questions - Advanced", Description = "Advanced Behavioral and Situational Questions", Icon = "fa-brain", ColorCode = "#2563EB", DisplayOrder = 29, QuestionRangeStart = 561, QuestionRangeEnd = 571 }
        );
    }
}
