using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Returns")]
    public class Return
    {
        [Key]
        public int ReturnId { get; set; }

        [Required]
        [StringLength(30)]
        public string ReturnCode { get; set; } = string.Empty;

        public int OrderId { get; set; }

        public int? UserId { get; set; }

        [Required]
        [StringLength(500)]
        public string Reason { get; set; } = string.Empty;

        [Required]
        [StringLength(30)]
        public string Status { get; set; } = "REQUESTED"; // REQUESTED, APPROVED, REJECTED, RECEIVED, REFUNDING, COMPLETED, CANCELLED

        public DateTime RequestedAt { get; set; } = DateTime.Now;

        public int? ApprovedByUserId { get; set; }

        public DateTime? ApprovedAt { get; set; }

        public DateTime? ReceivedAt { get; set; }

        public DateTime? CompletedAt { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal RefundAmount { get; set; } = 0;

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        [ForeignKey("ApprovedByUserId")]
        public virtual User? ApprovedByUser { get; set; }

        public virtual ICollection<ReturnItem> ReturnItems { get; set; } = new List<ReturnItem>();
    }
}
