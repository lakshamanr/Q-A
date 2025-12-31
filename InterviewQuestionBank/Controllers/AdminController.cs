using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InterviewQuestionBank.Data;
using InterviewQuestionBank.Services;
using InterviewQuestionBank.ViewModels;

namespace InterviewQuestionBank.Controllers
{
    public class AdminController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly QuestionImportService _importService;
        private readonly ILogger<AdminController> _logger;

        public AdminController(
            ApplicationDbContext context, 
            QuestionImportService importService,
            ILogger<AdminController> logger)
        {
            _context = context;
            _importService = importService;
            _logger = logger;
        }

        // GET: Admin
        public async Task<IActionResult> Index()
        {
            var stats = new AdminDashboardViewModel
            {
                TotalQuestions = await _context.Questions.CountAsync(),
                TotalCategories = await _context.Categories.CountAsync(),
                PublishedQuestions = await _context.Questions.CountAsync(q => q.IsPublished),
                TotalViews = await _context.Questions.SumAsync(q => q.ViewCount),
                CategoryStats = await _context.Categories
                    .Select(c => new CategoryStats
                    {
                        CategoryName = c.Name,
                        QuestionCount = c.Questions.Count,
                        RangeStart = c.QuestionRangeStart,
                        RangeEnd = c.QuestionRangeEnd
                    })
                    .OrderBy(c => c.RangeStart)
                    .ToListAsync()
            };

            return View(stats);
        }

        // GET: Admin/Import
        public IActionResult Import()
        {
            return View();
        }

        // POST: Admin/ImportQuestions
        [HttpPost]
        public async Task<IActionResult> ImportQuestions()
        {
            try
            {
                _logger.LogInformation("Starting question import from UI...");

                // Get the parent directory (Q-A folder)
                var baseDirectory = Path.Combine(Directory.GetCurrentDirectory(), "..");
                _logger.LogInformation($"Base directory: {baseDirectory}");

                var result = await _importService.ImportAllMarkdownFilesAsync(baseDirectory);

                TempData["ImportResult"] = $"Import Complete! Imported: {result.ImportedCount}, Skipped: {result.SkippedCount}, Errors: {result.ErrorCount}";
                
                if (!result.Success)
                {
                    TempData["ImportError"] = result.ErrorMessage;
                }

                _logger.LogInformation($"Import completed: {result}");

                return RedirectToAction(nameof(Import));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during import");
                TempData["ImportError"] = $"Error: {ex.Message}";
                return RedirectToAction(nameof(Import));
            }
        }

        // GET: Admin/VerifyImport
        public async Task<IActionResult> VerifyImport()
        {
            var verification = new ImportVerificationViewModel
            {
                TotalQuestions = await _context.Questions.CountAsync(),
                CategoryBreakdown = await _context.Categories
                    .Select(c => new CategoryBreakdown
                    {
                        CategoryName = c.Name,
                        QuestionCount = c.Questions.Count,
                        ExpectedRange = $"Q{c.QuestionRangeStart}-Q{c.QuestionRangeEnd}",
                        ExpectedCount = c.QuestionRangeEnd - c.QuestionRangeStart + 1
                    })
                    .OrderBy(c => c.CategoryName)
                    .ToListAsync(),
                DifficultyBreakdown = await _context.Questions
                    .GroupBy(q => q.Difficulty)
                    .Select(g => new DifficultyBreakdown
                    {
                        Difficulty = g.Key.ToString(),
                        Count = g.Count()
                    })
                    .ToListAsync()
            };

            // Calculate question number range
            var minQuestion = await _context.Questions.MinAsync(q => (int?)q.QuestionNumber) ?? 0;
            var maxQuestion = await _context.Questions.MaxAsync(q => (int?)q.QuestionNumber) ?? 0;
            verification.QuestionNumberRange = $"Q{minQuestion} - Q{maxQuestion}";

            // Find gaps
            var allQuestionNumbers = await _context.Questions
                .Where(q => q.QuestionNumber.HasValue)
                .OrderBy(q => q.QuestionNumber!.Value)
                .Select(q => q.QuestionNumber!.Value)
                .ToListAsync();

            if (allQuestionNumbers.Count > 0)
            {
                var gaps = new List<int>();
                for (int i = minQuestion; i <= maxQuestion; i++)
                {
                    if (!allQuestionNumbers.Contains(i))
                    {
                        gaps.Add(i);
                    }
                }

                if (gaps.Count > 0)
                {
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

                    verification.MissingQuestions = gapRanges;
                    verification.MissingCount = gaps.Count;
                }
            }

            return View(verification);
        }

        // POST: Admin/ClearAllQuestions
        [HttpPost]
        public async Task<IActionResult> ClearAllQuestions()
        {
            try
            {
                var questionCount = await _context.Questions.CountAsync();
                
                // Clear all questions
                _context.Questions.RemoveRange(_context.Questions);
                await _context.SaveChangesAsync();

                TempData["ImportResult"] = $"Successfully deleted {questionCount} questions from database.";
                _logger.LogInformation($"Cleared {questionCount} questions from database");

                return RedirectToAction(nameof(Import));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error clearing questions");
                TempData["ImportError"] = $"Error: {ex.Message}";
                return RedirectToAction(nameof(Import));
            }
        }
    }
}
