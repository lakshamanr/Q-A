using System.ComponentModel.DataAnnotations;

namespace InterviewQuestionBank.Models
{
    public class Category
    {
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(50)]
        public string? Icon { get; set; }

        [StringLength(50)]
        public string? ColorCode { get; set; }

        public int DisplayOrder { get; set; }

        public int QuestionRangeStart { get; set; }
        public int QuestionRangeEnd { get; set; }

        // Navigation property
        public virtual ICollection<Question> Questions { get; set; } = new List<Question>();
    }
}
