using System.ComponentModel.DataAnnotations;

namespace InterviewQuestionBank.Models
{
    public enum DifficultyLevel
    {
        Beginner,
        Intermediate,
        Advanced
    }

    public class Question
    {
        public int Id { get; set; }

        public int QuestionNumber { get; set; }

        [Required]
        [StringLength(500)]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Content { get; set; } = string.Empty;

        public string? ContentHtml { get; set; }

        public DifficultyLevel Difficulty { get; set; } = DifficultyLevel.Intermediate;

        [StringLength(200)]
        public string? Tags { get; set; }

        public int CategoryId { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        public DateTime? ModifiedDate { get; set; }

        public bool IsPublished { get; set; } = true;

        public int ViewCount { get; set; } = 0;

        // Navigation properties
        public virtual Category Category { get; set; } = null!;
        public virtual ICollection<UserFavorite> Favorites { get; set; } = new List<UserFavorite>();
        public virtual ICollection<UserProgress> UserProgresses { get; set; } = new List<UserProgress>();
    }
}
