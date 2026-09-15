using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("OrderDetails")]
    public class OrderDetail
    {
        [Key]
        public int OrderDetailId { get; set; }

        public int OrderId { get; set; }

        public int VariantId { get; set; }

        public int Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }

        [ForeignKey("VariantId")]
        public virtual ProductVariant? Variant { get; set; }
    }
}
