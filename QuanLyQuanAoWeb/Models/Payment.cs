using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Payments")]
    public class Payment
    {
        [Key]
        public long PaymentId { get; set; }

        public int OrderId { get; set; }

        [Required]
        [StringLength(30)]
        public string PaymentMethod { get; set; } = "COD"; // COD, BANK_TRANSFER, VNPAY, MOMO

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; } = 0;

        [Required]
        [StringLength(20)]
        public string Status { get; set; } = "PENDING"; // PENDING, PAID, FAILED, CANCELLED, REFUNDED, PARTIALLY_REFUNDED

        [StringLength(100)]
        public string? GatewayTransactionId { get; set; }

        [Required]
        [StringLength(100)]
        public string IdempotencyKey { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal RefundedAmount { get; set; } = 0;

        public DateTime? PaidAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }
    }
}
