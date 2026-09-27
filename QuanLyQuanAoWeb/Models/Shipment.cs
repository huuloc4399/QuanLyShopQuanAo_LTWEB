using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Shipments")]
    public class Shipment
    {
        [Key]
        public long ShipmentId { get; set; }

        public int OrderId { get; set; }

        [StringLength(30)]
        public string? ProviderCode { get; set; } // GHN, GHTK, VIETTELPOST, INTERNAL

        [StringLength(100)]
        public string? TrackingCode { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal ShippingFee { get; set; } = 0;

        [Required]
        [StringLength(30)]
        public string Status { get; set; } = "PENDING"; // PENDING, PICKED_UP, IN_TRANSIT, DELIVERED, FAILED, RETURNED

        public DateTime? ShippedAt { get; set; }

        public DateTime? DeliveredAt { get; set; }

        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }
    }
}
