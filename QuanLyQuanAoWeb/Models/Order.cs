using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Orders")]
    public class Order
    {
        [Key]
        public int OrderId { get; set; }

        public int? UserId { get; set; }

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
        public decimal TotalAmount { get; set; } = 0;

        [Required]
        [StringLength(50)]
        public string PaymentMethod { get; set; } = "COD";

        [Required]
        [StringLength(50)]
        public string PaymentStatus { get; set; } = "Chưa thanh toán";

        [Required]
        [StringLength(50)]
        public string OrderStatus { get; set; } = "Chờ xác nhận";

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        public virtual ICollection<OrderDetail> OrderDetails { get; set; } = new List<OrderDetail>();
    }
}
