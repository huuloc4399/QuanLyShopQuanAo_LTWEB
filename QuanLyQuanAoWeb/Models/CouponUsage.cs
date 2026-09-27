using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("CouponUsages")]
    public class CouponUsage
    {
        [Key]
        public long CouponUsageId { get; set; }

        public int CouponId { get; set; }

        public int OrderId { get; set; }

        public int? UserId { get; set; }

        [StringLength(100)]
        public string? SessionId { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal DiscountAmount { get; set; } = 0;

        [Required]
        [StringLength(20)]
        public string Status { get; set; } = "RESERVED"; // RESERVED, USED, RELEASED

        public DateTime ReservedAt { get; set; } = DateTime.Now;

        public DateTime? UsedAt { get; set; }

        public DateTime? ReleasedAt { get; set; }

        [ForeignKey("CouponId")]
        public virtual Coupon? Coupon { get; set; }

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
