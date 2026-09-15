using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Colors")]
    public class Color
    {
        [Key]
        public int ColorId { get; set; }

        [Required]
        [StringLength(50)]
        public string ColorName { get; set; } = string.Empty;

        [StringLength(10)]
        public string? ColorHex { get; set; }

        public virtual ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();
    }
}
