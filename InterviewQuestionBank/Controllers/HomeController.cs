using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InterviewQuestionBank.Data;
using InterviewQuestionBank.Models;

namespace InterviewQuestionBank.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly ApplicationDbContext _context;

    public HomeController(ILogger<HomeController> logger, ApplicationDbContext context)
    {
        _logger = logger;
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var categories = await _context.Categories
            .Include(c => c.Questions)
            .OrderBy(c => c.DisplayOrder)
            .ToListAsync();

        var totalQuestions = await _context.Questions.CountAsync(q => q.IsPublished);
        var totalViews = await _context.Questions.SumAsync(q => q.ViewCount);

        ViewBag.TotalQuestions = totalQuestions;
        ViewBag.TotalCategories = categories.Count;
        ViewBag.TotalViews = totalViews;

        return View(categories);
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
