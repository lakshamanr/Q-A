using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using InterviewQuestionBank.Data;
using InterviewQuestionBank.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlite(connectionString));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();

builder.Services.AddDefaultIdentity<IdentityUser>(options => options.SignIn.RequireConfirmedAccount = true)
    .AddEntityFrameworkStores<ApplicationDbContext>();

// Register QuestionImportService
builder.Services.AddScoped<QuestionImportService>();

builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();

app.MapRazorPages()
   .WithStaticAssets();

// CLI command to import questions
if (args.Contains("--import-questions"))
{
    using var scope = app.Services.CreateScope();
    var importService = scope.ServiceProvider.GetRequiredService<QuestionImportService>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    logger.LogInformation("Starting question import from markdown files...");

    // Get the parent directory (Q-A folder)
    var baseDirectory = Path.Combine(Directory.GetCurrentDirectory(), "..");
    logger.LogInformation($"Base directory: {baseDirectory}");

    var result = await importService.ImportAllMarkdownFilesAsync(baseDirectory);

    logger.LogInformation($"\n=== Import Complete ===");
    logger.LogInformation($"Imported: {result.ImportedCount}");
    logger.LogInformation($"Skipped: {result.SkippedCount}");
    logger.LogInformation($"Errors: {result.ErrorCount}");
    logger.LogInformation($"Success: {result.Success}");

    if (!string.IsNullOrEmpty(result.ErrorMessage))
    {
        logger.LogError($"Error: {result.ErrorMessage}");
    }

    return;
}

// CLI command to verify imported questions
if (args.Contains("--verify-import"))
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    logger.LogInformation("\n=== Question Import Verification ===\n");

    var totalQuestions = await context.Questions.CountAsync();
    logger.LogInformation($"Total Questions: {totalQuestions}");

    var categoriesWithCounts = await context.Categories
        .Select(c => new { c.Name, QuestionCount = c.Questions.Count })
        .ToListAsync();

    logger.LogInformation("\nQuestions by Category:");
    foreach (var cat in categoriesWithCounts)
    {
        logger.LogInformation($"  {cat.Name}: {cat.QuestionCount} questions");
    }

    var difficultyCount = await context.Questions
        .GroupBy(q => q.Difficulty)
        .Select(g => new { Difficulty = g.Key, Count = g.Count() })
        .ToListAsync();

    logger.LogInformation("\nQuestions by Difficulty:");
    foreach (var diff in difficultyCount)
    {
        logger.LogInformation($"  {diff.Difficulty}: {diff.Count} questions");
    }

    var minQuestion = await context.Questions.MinAsync(q => (int?)q.QuestionNumber) ?? 0;
    var maxQuestion = await context.Questions.MaxAsync(q => (int?)q.QuestionNumber) ?? 0;
    logger.LogInformation($"\nQuestion Number Range: Q{minQuestion} - Q{maxQuestion}");

    return;
}

// CLI command to list all question numbers and find gaps
if (args.Contains("--list-questions"))
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    logger.LogInformation("\n=== Question Numbers Analysis ===\n");

    var allQuestionNumbers = await context.Questions
        .Where(q => q.QuestionNumber.HasValue)
        .OrderBy(q => q.QuestionNumber!.Value)
        .Select(q => q.QuestionNumber!.Value)
        .ToListAsync();

    logger.LogInformation($"Total Questions in Database: {allQuestionNumbers.Count}");

    if (allQuestionNumbers.Count > 0)
    {
        var min = allQuestionNumbers.Min();
        var max = allQuestionNumbers.Max();
        logger.LogInformation($"Range: Q{min} - Q{max}");
        logger.LogInformation($"Expected Total (if no gaps): {max - min + 1}");
        logger.LogInformation($"Actual Total: {allQuestionNumbers.Count}");
        logger.LogInformation($"Missing Questions: {(max - min + 1) - allQuestionNumbers.Count}\n");

        // Find gaps
        var gaps = new List<int>();
        for (int i = min; i <= max; i++)
        {
            if (!allQuestionNumbers.Contains(i))
            {
                gaps.Add(i);
            }
        }

        if (gaps.Count > 0)
        {
            logger.LogInformation("Missing Question Numbers:");
            var gapRanges = new List<string>();
            int rangeStart = gaps[0];
            int rangeEnd = gaps[0];

            for (int i = 1; i < gaps.Count; i++)
            {
                if (gaps[i] == rangeEnd + 1)
                {
                    rangeEnd = gaps[i];
                }
                else
                {
                    gapRanges.Add(rangeStart == rangeEnd ? $"Q{rangeStart}" : $"Q{rangeStart}-Q{rangeEnd}");
                    rangeStart = gaps[i];
                    rangeEnd = gaps[i];
                }
            }
            gapRanges.Add(rangeStart == rangeEnd ? $"Q{rangeStart}" : $"Q{rangeStart}-Q{rangeEnd}");

            foreach (var range in gapRanges)
            {
                logger.LogInformation($"  {range}");
            }
            logger.LogInformation($"\nTotal Missing: {gaps.Count} questions");
        }
        else
        {
            logger.LogInformation("✓ No gaps found - all questions from Q{0} to Q{1} are present!", min, max);
        }
    }

    return;
}

app.Run();
