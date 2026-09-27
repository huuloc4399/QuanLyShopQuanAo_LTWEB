using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("ReturnItems")]
    public class ReturnItem
    {
        [Key]
        public int ReturnItemId { get; set; }

        public int ReturnId { get; set; }

        public int OrderDetailId { get; set; }

        public int Quantity { get; set; }

        [Required]
        [StringLength(20)]
        public string Resolution { get; set; } = "REFUND"; // REFUND, EXCHANGE, STORE_CREDIT

        public int? ExchangeVariantId { get; set; }

        [StringLength(30)]
        public string? ItemCondition { get; set; } // RESELLABLE, DAMAGED, USED, DEFECTIVE

        public int RestockQuantity { get; set; } = 0;

        [Column(TypeName = "decimal(18,2)")]
        public decimal RefundAmount { get; set; } = 0;

        [StringLength(500)]
        public string? Note { get; set; }

        [ForeignKey("ReturnId")]
        public virtual Return? Return { get; set; }

        [ForeignKey("OrderDetailId")]
        public virtual OrderDetail? OrderDetail { get; set; }

        [ForeignKey("ExchangeVariantId")]
        public virtual ProductVariant? ExchangeVariant { get; set; }
    }
}
