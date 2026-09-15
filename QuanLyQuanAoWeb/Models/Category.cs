using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Categories")]
    public class Category
    {
        [Key]
        public int CategoryId { get; set; }

        [Required]
        [StringLength(100)]
        public string CategoryName { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Slug { get; set; }

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(255)]
        public string? ImageUrl { get; set; }

        public int DisplayOrder { get; set; } = 0;

        public bool IsActive { get; set; } = true;

        public virtual ICollection<Product> Products { get; set; } = new List<Product>();
    }
}
