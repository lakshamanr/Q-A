using System.Text.RegularExpressions;
using InterviewQuestionBank.Data;
using InterviewQuestionBank.Models;
using Microsoft.EntityFrameworkCore;

namespace InterviewQuestionBank.Services
{
    public class QuestionImportService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<QuestionImportService> _logger;

        public QuestionImportService(ApplicationDbContext context, ILogger<QuestionImportService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<ImportResult> ImportFromMarkdownAsync(string markdownFilePath, int categoryId)
        {
            var result = new ImportResult();

            try
            {
                if (!File.Exists(markdownFilePath))
                {
                    result.ErrorMessage = $"File not found: {markdownFilePath}";
                    return result;
                }

                var content = await File.ReadAllTextAsync(markdownFilePath);
                var questions = ParseQuestions(content, categoryId);

                _logger.LogInformation($"Parsed {questions.Count} questions from {markdownFilePath}");

                foreach (var question in questions)
                {
                    try
                    {
                        // Check if question already exists
                        var existing = await _context.Questions
                            .FirstOrDefaultAsync(q => q.QuestionNumber == question.QuestionNumber);

                        if (existing != null)
                        {
                            _logger.LogWarning($"Question {question.QuestionNumber} already exists, skipping");
                            result.SkippedCount++;
                            continue;
                        }

                        _context.Questions.Add(question);
                        result.ImportedCount++;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error importing question {question.QuestionNumber}");
                        result.ErrorCount++;
                    }
                }

                await _context.SaveChangesAsync();
                result.Success = true;
                _logger.LogInformation($"Import completed: {result.ImportedCount} imported, {result.SkippedCount} skipped, {result.ErrorCount} errors");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during import");
                result.ErrorMessage = ex.Message;
            }

            return result;
        }

        private List<Question> ParseQuestions(string content, int categoryId)
        {
            var questions = new List<Question>();

            // Pattern 1: Single question - ## Q123:, ## **Q123:**, ### Q123:
            // Negative lookahead to avoid matching ranges like Q79-Q80
            var singlePattern = @"#{2,3}\s+\*{0,2}Q(\d+)(?!-Q\d+):\*{0,2}\s+(.+?)(?=\n#{2,3}\s+\*{0,2}Q[\d\-]+:|\Z)";
            var singleMatches = Regex.Matches(content, singlePattern, RegexOptions.Singleline);

            foreach (Match match in singleMatches)
            {
                try
                {
                    var questionNumber = int.Parse(match.Groups[1].Value);
                    var questionContent = match.Groups[2].Value.Trim();

                    // Extract title (first line)
                    var lines = questionContent.Split('\n', StringSplitOptions.RemoveEmptyEntries);
                    var title = lines.FirstOrDefault()?.Trim() ?? $"Question {questionNumber}";

                    // Limit title length
                    if (title.Length > 500)
                    {
                        title = title.Substring(0, 497) + "...";
                    }

                    // Determine difficulty based on content
                    var difficulty = DetermineDifficulty(questionContent);

                    var question = new Question
                    {
                        QuestionNumber = questionNumber,
                        Title = title,
                        Content = questionContent,
                        CategoryId = categoryId,
                        Difficulty = difficulty,
                        IsPublished = true,
                        CreatedDate = DateTime.UtcNow,
                        ViewCount = 0
                    };

                    questions.Add(question);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error parsing single question: {match.Value.Substring(0, Math.Min(100, match.Value.Length))}");
                }
            }

            // Pattern 2: Question ranges - ## Q77-Q80:, ## **Q77-Q80:**
            var rangePattern = @"#{2,3}\s+\*{0,2}Q(\d+)-Q(\d+):\*{0,2}\s+(.+?)(?=\n#{2,3}\s+\*{0,2}Q[\d\-]+:|\Z)";
            var rangeMatches = Regex.Matches(content, rangePattern, RegexOptions.Singleline);

            foreach (Match match in rangeMatches)
            {
                try
                {
                    var startNum = int.Parse(match.Groups[1].Value);
                    var endNum = int.Parse(match.Groups[2].Value);
                    var questionContent = match.Groups[3].Value.Trim();

                    // Extract title (first line)
                    var lines = questionContent.Split('\n', StringSplitOptions.RemoveEmptyEntries);
                    var baseTitle = lines.FirstOrDefault()?.Trim() ?? $"Questions {startNum}-{endNum}";

                    // Create separate questions for each number in the range
                    for (int qNum = startNum; qNum <= endNum; qNum++)
                    {
                        var title = baseTitle.Replace("(Combined)", $"(Part {qNum - startNum + 1})").Trim();

                        // Limit title length
                        if (title.Length > 500)
                        {
                            title = title.Substring(0, 497) + "...";
                        }

                        var difficulty = DetermineDifficulty(questionContent);

                        var question = new Question
                        {
                            QuestionNumber = qNum,
                            Title = title,
                            Content = questionContent,
                            CategoryId = categoryId,
                            Difficulty = difficulty,
                            IsPublished = true,
                            CreatedDate = DateTime.UtcNow,
                            ViewCount = 0
                        };

                        questions.Add(question);
                    }

                    _logger.LogInformation($"Expanded range Q{startNum}-Q{endNum} into {endNum - startNum + 1} individual questions");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error parsing question range: {match.Value.Substring(0, Math.Min(100, match.Value.Length))}");
                }
            }

            return questions;
        }

        private DifficultyLevel DetermineDifficulty(string content)
        {
            var lowerContent = content.ToLower();

            // Advanced keywords
            if (lowerContent.Contains("advanced") ||
                lowerContent.Contains("optimization") ||
                lowerContent.Contains("performance") ||
                lowerContent.Contains("architecture") ||
                lowerContent.Contains("complex") ||
                lowerContent.Contains("distributed") ||
                lowerContent.Contains("microservices") ||
                lowerContent.Contains("saga pattern") ||
                lowerContent.Contains("event sourcing") ||
                lowerContent.Contains("cqrs"))
            {
                return DifficultyLevel.Advanced;
            }

            // Beginner keywords
            if (lowerContent.Contains("basic") ||
                lowerContent.Contains("fundamental") ||
                lowerContent.Contains("introduction") ||
                lowerContent.Contains("simple") ||
                lowerContent.Contains("what is") ||
                lowerContent.Contains("define"))
            {
                return DifficultyLevel.Beginner;
            }

            // Default to Intermediate
            return DifficultyLevel.Intermediate;
        }

        public async Task<ImportResult> ImportAllMarkdownFilesAsync(string baseDirectory)
        {
            var totalResult = new ImportResult();

            // Mapping of markdown files to categories
            var fileMapping = new Dictionary<string, int>
            {
                // Comprehensive file with Q1-Q53 (maps to C# Fundamentals for Q1-20, then appropriate categories)
                { "Comprehensive_Interview_Answers.md", 1 },

                // Category 1: C# Fundamentals (Q1-Q50)
                { "Q21_Q25_C#.md", 1 },
                { "Q26_Q30_C#.md", 1 },
                { "Q31_Q34_C#.md", 1 },
                { "Q35_Q43_async_C#.md", 1 },
                { "Q44_Q50_C#.md", 1 },

                // Category 2: ASP.NET MVC (Q51-Q90)
                { "Q51_Q60_mvc_batch.md", 2 },
                { "Q61_Q70_mvc_batch.md", 2 },
                { "Q71_Q80_mvc_batch.md", 2 },
                { "Q81_Q90_mvc_batch.md", 2 },

                // Category 3: Advanced .NET (Q91-Q99)
                { "Q91_Q99_DotNet_Advanced.md", 3 },

                // Category 4: Azure Cloud (Q100-Q120)
                { "Q100_Q115_Azure_Cloud.md", 4 },
                { "Q108-Q115_Azure.md", 4 },
                { "Q111_Q120_continuation.md", 4 },
                { "Q113_Q120_final.md", 4 },

                // Category 5: DevOps & Microservices (Q121-Q140)
                { "Q121_Q140_DevOps_Microservices.md", 5 },
                { "Q125_Q140_complete.md", 5 },

                // Category 6: Advanced Microservices (Q141-Q171)
                { "Q141_Q171_Microservices_Advanced.md", 6 },

                // Category 7: SQL Server & Database (Q172-Q200)
                { "Q172_Q200_SQL_Database.md", 7 },

                // Category 8: SQL & Entity Framework (Q201-Q220)
                { "Q200_Q220_SQL_EF.md", 8 },
                { "Q206_Q220_SQL_Performance.md", 8 },

                // Category 9: ASP.NET Core (Q221-Q240)
                { "Q221_Q240_ASP_NET_Core.md", 9 },

                // Category 10: Design Patterns (Q241-Q260)
                { "Q241_Q260_Design_Patterns.md", 10 },

                // Category 11: Testing & Quality (Q261-Q280)
                { "Q261_Q280_Testing.md", 11 },

                // Category 12: Security (Q281-Q300)
                { "Q281_Q300_Security.md", 12 },

                // Category 13: Performance Optimization (Q301-Q320)
                { "Q301_Q320_Performance.md", 13 },

                // Category 14: Microservices Architecture (Q321-Q340)
                { "Q321_Q340_Microservices.md", 14 },

                // Category 15: Cloud & DevOps (Q341-Q360)
                { "Q341_Q360_Cloud_DevOps.md", 15 },

                // Category 21: Angular Framework (Q352-Q376)
                { "Q352_Q376_Angular_Complete.md", 21 },

                // Category 16: Advanced .NET Topics (Q361-Q380)
                { "Q361_Q380_Advanced_NET.md", 16 },

                // Category 17: Architecture & Design (Q381-Q400)
                { "Q381_Q400_Architecture_Design.md", 17 },

                // Category 18: Database Design (Q401-Q420)
                { "Q401_Q420_Database_Design.md", 18 },

                // Category 19: Testing & QA Practices (Q421-Q440)
                { "Q421_Q440_Testing_QA.md", 19 },

                // Category 20: System Design (Q441-Q460)
                { "Q441_Q460_System_Design.md", 20 },

                // Category 24: Advanced Testing & Leadership (Q461-Q480)
                { "Q461_Q480_Advanced_Testing_Leadership.md", 24 },

                // Category 25: Security & OWASP (Q481-Q500)
                { "Q481_Q500_Security_OWASP.md", 25 },

                // Category 26: Leadership & Team Management (Q501-Q520)
                { "Q501_Q520_Leadership_Team_Management.md", 26 },

                // Category 27: System Design & Scalability (Q521-Q540)
                { "Q521_Q540_System_Design_Scalability.md", 27 },

                // Category 28: Behavioral Questions - Core (Q541-Q560)
                { "Q541_Q560_Behavioral_Questions.md", 28 },

                // Category 29: Behavioral Questions - Advanced (Q561-Q571)
                { "Q561_Q571_Final_Behavioral_Questions.md", 29 }
            };

            foreach (var mapping in fileMapping)
            {
                var filePath = Path.Combine(baseDirectory, mapping.Key);
                _logger.LogInformation($"Processing file: {filePath}");

                var result = await ImportFromMarkdownAsync(filePath, mapping.Value);

                totalResult.ImportedCount += result.ImportedCount;
                totalResult.SkippedCount += result.SkippedCount;
                totalResult.ErrorCount += result.ErrorCount;

                if (!result.Success)
                {
                    _logger.LogError($"Failed to import {mapping.Key}: {result.ErrorMessage}");
                }
            }

            totalResult.Success = totalResult.ErrorCount == 0;
            return totalResult;
        }
    }

    public class ImportResult
    {
        public bool Success { get; set; }
        public int ImportedCount { get; set; }
        public int SkippedCount { get; set; }
        public int ErrorCount { get; set; }
        public string? ErrorMessage { get; set; }

        public override string ToString()
        {
            return $"Success: {Success}, Imported: {ImportedCount}, Skipped: {SkippedCount}, Errors: {ErrorCount}";
        }
    }
}
