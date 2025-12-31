namespace InterviewQuestionBank.ViewModels
{
    public class AdminDashboardViewModel
    {
        public int TotalQuestions { get; set; }
        public int TotalCategories { get; set; }
        public int PublishedQuestions { get; set; }
        public int TotalViews { get; set; }
        public List<CategoryStats> CategoryStats { get; set; } = new();
    }

    public class CategoryStats
    {
        public string CategoryName { get; set; } = string.Empty;
        public int QuestionCount { get; set; }
        public int RangeStart { get; set; }
        public int RangeEnd { get; set; }
    }

    public class ImportVerificationViewModel
    {
        public int TotalQuestions { get; set; }
        public string QuestionNumberRange { get; set; } = string.Empty;
        public List<string> MissingQuestions { get; set; } = new();
        public int MissingCount { get; set; }
        public List<CategoryBreakdown> CategoryBreakdown { get; set; } = new();
        public List<DifficultyBreakdown> DifficultyBreakdown { get; set; } = new();
    }

    public class CategoryBreakdown
    {
        public string CategoryName { get; set; } = string.Empty;
        public int QuestionCount { get; set; }
        public string ExpectedRange { get; set; } = string.Empty;
        public int ExpectedCount { get; set; }
    }

    public class DifficultyBreakdown
    {
        public string Difficulty { get; set; } = string.Empty;
        public int Count { get; set; }
    }
}
