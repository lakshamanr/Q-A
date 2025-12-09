using Microsoft.AspNetCore.Identity;

namespace InterviewQuestionBank.Models
{
    public class UserFavorite
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int QuestionId { get; set; }
        public DateTime AddedDate { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual IdentityUser User { get; set; } = null!;
        public virtual Question Question { get; set; } = null!;
    }

    public class UserProgress
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int QuestionId { get; set; }
        public bool IsCompleted { get; set; }
        public DateTime? CompletedDate { get; set; }
        public string? Notes { get; set; }

        // Navigation properties
        public virtual IdentityUser User { get; set; } = null!;
        public virtual Question Question { get; set; } = null!;
    }
}
