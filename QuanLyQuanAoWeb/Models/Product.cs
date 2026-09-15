using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Products")]
    public class Product
    {
        [Key]
        public int ProductId { get; set; }

        public int CategoryId { get; set; }

        [Required]
        [StringLength(200)]
        public string ProductName { get; set; } = string.Empty;

        [StringLength(50)]
        public string? ProductCode { get; set; }

        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal OriginalPrice { get; set; } = 0;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        public int? DiscountPercent { get; set; } = 0;

        [StringLength(255)]
        public string? MainImage { get; set; }

        public bool IsFeatured { get; set; } = false;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [ForeignKey("CategoryId")]
        public virtual Category? Category { get; set; }

        public virtual ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();

        [NotMapped]
        public decimal FinalPrice => DiscountPercent.HasValue && DiscountPercent.Value > 0
            ? Price * (100 - DiscountPercent.Value) / 100
            : Price;
    }
}
