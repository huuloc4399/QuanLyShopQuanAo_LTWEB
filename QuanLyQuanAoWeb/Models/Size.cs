using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Sizes")]
    public class Size
    {
        [Key]
        public int SizeId { get; set; }

        [Required]
        [StringLength(20)]
        public string SizeName { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Description { get; set; }

        public virtual ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();
    }
}
