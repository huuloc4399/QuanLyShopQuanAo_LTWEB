using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("InventoryTransactions")]
    public class InventoryTransaction
    {
        [Key]
        public long InventoryTransactionId { get; set; }

        public int VariantId { get; set; }

        public int QuantityDelta { get; set; }

        [Required]
        [StringLength(30)]
        public string TransactionType { get; set; } = string.Empty; // PURCHASE_IN, SALE_OUT, RETURN_IN, ADJUSTMENT, OPENING_BALANCE

        [Required]
        [StringLength(30)]
        public string SourceType { get; set; } = string.Empty; // IMPORT_DETAIL, ORDER_DETAIL, RETURN_ITEM, AUDIT

        public long SourceId { get; set; }

        [Required]
        [StringLength(100)]
        public string IdempotencyKey { get; set; } = string.Empty;

        public int? CreatedByUserId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [StringLength(500)]
        public string? Note { get; set; }

        [ForeignKey("VariantId")]
        public virtual ProductVariant? Variant { get; set; }

        [ForeignKey("CreatedByUserId")]
        public virtual User? CreatedByUser { get; set; }
    }
}
