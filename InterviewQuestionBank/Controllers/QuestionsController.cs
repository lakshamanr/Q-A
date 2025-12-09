using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InterviewQuestionBank.Data;
using InterviewQuestionBank.Models;
using Markdig;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace InterviewQuestionBank.Controllers
{
    public class QuestionsController : Controller
    {
        private readonly ApplicationDbContext _context;

        public QuestionsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: Questions
        public async Task<IActionResult> Index(int? categoryId, string? difficulty, string? searchTerm, int page = 1)
        {
            int pageSize = 15;

            var query = _context.Questions
                .Include(q => q.Category)
                .Where(q => q.IsPublished)
                .AsQueryable();

            // Apply filters
            if (categoryId.HasValue)
            {
                query = query.Where(q => q.CategoryId == categoryId);
            }

            if (!string.IsNullOrEmpty(difficulty) && Enum.TryParse<DifficultyLevel>(difficulty, out var difficultyLevel))
            {
                query = query.Where(q => q.Difficulty == difficultyLevel);
            }

            if (!string.IsNullOrEmpty(searchTerm))
            {
                query = query.Where(q =>
                    q.Title.Contains(searchTerm) ||
                    q.Content.Contains(searchTerm) ||
                    q.QuestionNumber.ToString().Contains(searchTerm));
            }

            query = query.OrderBy(q => q.QuestionNumber);

            var totalQuestions = await query.CountAsync();
            var questions = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(totalQuestions / (double)pageSize);
            ViewBag.CategoryId = categoryId;
            ViewBag.Difficulty = difficulty;
            ViewBag.SearchTerm = searchTerm;
            ViewBag.Categories = await _context.Categories.OrderBy(c => c.DisplayOrder).ToListAsync();

            return View(questions);
        }

        // GET: Questions/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var question = await _context.Questions
                .Include(q => q.Category)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (question == null)
            {
                return NotFound();
            }

            // Increment view count
            question.ViewCount++;
            await _context.SaveChangesAsync();

            // Convert markdown to HTML
            var pipeline = new MarkdownPipelineBuilder()
                .UseAdvancedExtensions()
                .Build();
            question.ContentHtml = Markdown.ToHtml(question.Content, pipeline);

            // Check if user has favorited this question
            if (User.Identity?.IsAuthenticated == true)
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                ViewBag.IsFavorite = await _context.UserFavorites
                    .AnyAsync(uf => uf.UserId == userId && uf.QuestionId == id);
                ViewBag.IsCompleted = await _context.UserProgresses
                    .AnyAsync(up => up.UserId == userId && up.QuestionId == id && up.IsCompleted);
            }

            return View(question);
        }

        // GET: Questions/Category/1
        public async Task<IActionResult> Category(int id, int page = 1)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
            {
                return NotFound();
            }

            int pageSize = 15;
            var query = _context.Questions
                .Include(q => q.Category)
                .Where(q => q.CategoryId == id && q.IsPublished)
                .OrderBy(q => q.QuestionNumber);

            var totalQuestions = await query.CountAsync();
            var questions = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(totalQuestions / (double)pageSize);
            ViewBag.Category = category;

            return View("Index", questions);
        }

        // POST: Questions/ToggleFavorite
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> ToggleFavorite(int questionId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized();
            }

            var favorite = await _context.UserFavorites
                .FirstOrDefaultAsync(uf => uf.UserId == userId && uf.QuestionId == questionId);

            if (favorite == null)
            {
                // Add to favorites
                _context.UserFavorites.Add(new UserFavorite
                {
                    UserId = userId,
                    QuestionId = questionId
                });
            }
            else
            {
                // Remove from favorites
                _context.UserFavorites.Remove(favorite);
            }

            await _context.SaveChangesAsync();
            return Json(new { success = true, isFavorite = favorite == null });
        }

        // POST: Questions/ToggleCompleted
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> ToggleCompleted(int questionId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized();
            }

            var progress = await _context.UserProgresses
                .FirstOrDefaultAsync(up => up.UserId == userId && up.QuestionId == questionId);

            if (progress == null)
            {
                // Mark as completed
                _context.UserProgresses.Add(new UserProgress
                {
                    UserId = userId,
                    QuestionId = questionId,
                    IsCompleted = true,
                    CompletedDate = DateTime.UtcNow
                });
            }
            else
            {
                // Toggle completion status
                progress.IsCompleted = !progress.IsCompleted;
                progress.CompletedDate = progress.IsCompleted ? DateTime.UtcNow : null;
            }

            await _context.SaveChangesAsync();
            return Json(new { success = true, isCompleted = progress?.IsCompleted ?? true });
        }

        // GET: Questions/MyFavorites
        [Authorize]
        public async Task<IActionResult> MyFavorites()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var favorites = await _context.UserFavorites
                .Include(uf => uf.Question)
                .ThenInclude(q => q.Category)
                .Where(uf => uf.UserId == userId)
                .OrderByDescending(uf => uf.AddedDate)
                .ToListAsync();

            return View(favorites);
        }

        // GET: Questions/MyProgress
        [Authorize]
        public async Task<IActionResult> MyProgress()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var progress = await _context.UserProgresses
                .Include(up => up.Question)
                .ThenInclude(q => q.Category)
                .Where(up => up.UserId == userId && up.IsCompleted)
                .OrderByDescending(up => up.CompletedDate)
                .ToListAsync();

            var totalQuestions = await _context.Questions.CountAsync();
            var completedCount = progress.Count;
            var progressPercentage = totalQuestions > 0 ? (completedCount * 100.0 / totalQuestions) : 0;

            ViewBag.TotalQuestions = totalQuestions;
            ViewBag.CompletedCount = completedCount;
            ViewBag.ProgressPercentage = Math.Round(progressPercentage, 1);

            return View(progress);
        }
    }
}
