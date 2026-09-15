using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("ImportReceiptDetails")]
    public class ImportReceiptDetail
    {
        [Key]
        public int ImportDetailId { get; set; }

        public int ImportId { get; set; }

        public int VariantId { get; set; }

        public int Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal ImportPrice { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        [ForeignKey("ImportId")]
        public virtual ImportReceipt? ImportReceipt { get; set; }

        [ForeignKey("VariantId")]
        public virtual ProductVariant? Variant { get; set; }
    }
}
