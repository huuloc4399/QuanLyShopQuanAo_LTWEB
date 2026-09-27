using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("OrderStatusHistory")]
    public class OrderStatusHistory
    {
        [Key]
        public long OrderStatusHistoryId { get; set; }

        public int OrderId { get; set; }

        [StringLength(30)]
        public string? FromStatus { get; set; }

        [Required]
        [StringLength(30)]
        public string ToStatus { get; set; } = string.Empty;

        public int? ChangedByUserId { get; set; }

        public DateTime ChangedAt { get; set; } = DateTime.Now;

        [StringLength(500)]
        public string? Note { get; set; }

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }

        [ForeignKey("ChangedByUserId")]
        public virtual User? ChangedByUser { get; set; }
    }
}
