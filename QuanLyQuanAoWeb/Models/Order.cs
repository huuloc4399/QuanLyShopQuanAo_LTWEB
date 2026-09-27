using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Orders")]
    public class Order
    {
        [Key]
        public int OrderId { get; set; }

        [Required]
        [StringLength(30)]
        public string OrderCode { get; set; } = string.Empty;

        public int? UserId { get; set; }

        public int? CouponId { get; set; }

        public DateTime OrderDate { get; set; } = DateTime.Now;

        [Required]
        [StringLength(100)]
        public string ReceiverName { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        public string ReceiverPhone { get; set; } = string.Empty;

        [Required]
        [StringLength(255)]
        public string ShippingAddress { get; set; } = string.Empty;

        [StringLength(500)]
        public string? OrderNotes { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Subtotal { get; set; } = 0;

        [Column(TypeName = "decimal(18,2)")]
        public decimal DiscountAmount { get; set; } = 0;

        [Column(TypeName = "decimal(18,2)")]
        public decimal ShippingFee { get; set; } = 0;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TaxAmount { get; set; } = 0;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; } = 0;

        [Required]
        [StringLength(10)]
        public string CurrencyCode { get; set; } = "VND";

        [StringLength(100)]
        public string? CustomerEmail { get; set; }

        [Required]
        [StringLength(50)]
        public string PaymentMethod { get; set; } = "COD";

        [Required]
        [StringLength(50)]
        public string PaymentStatus { get; set; } = "Chưa thanh toán";

        [Required]
        [StringLength(50)]
        public string OrderStatus { get; set; } = "Chờ xác nhận";

        public int? ApprovedByUserId { get; set; }

        public DateTime? ApprovedAt { get; set; }

        public int? CancelledByUserId { get; set; }

        public DateTime? CancelledAt { get; set; }

        [StringLength(500)]
        public string? CancelReason { get; set; }

        public DateTime? UpdatedAt { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        [ForeignKey("CouponId")]
        public virtual Coupon? Coupon { get; set; }

        [ForeignKey("ApprovedByUserId")]
        public virtual User? ApprovedByUser { get; set; }

        [ForeignKey("CancelledByUserId")]
        public virtual User? CancelledByUser { get; set; }

        public virtual ICollection<OrderDetail> OrderDetails { get; set; } = new List<OrderDetail>();
        public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public virtual ICollection<OrderStatusHistory> StatusHistories { get; set; } = new List<OrderStatusHistory>();
        public virtual ICollection<InventoryReservation> Reservations { get; set; } = new List<InventoryReservation>();
        public virtual ICollection<Shipment> Shipments { get; set; } = new List<Shipment>();
        public virtual ICollection<Return> Returns { get; set; } = new List<Return>();
    }
}
