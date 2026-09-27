using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("ImportReceipts")]
    public class ImportReceipt
    {
        [Key]
        public int ImportId { get; set; }

        [Required]
        [StringLength(50)]
        public string ImportCode { get; set; } = string.Empty;

        public int SupplierId { get; set; }

        public int UserId { get; set; }

        public DateTime ImportDate { get; set; } = DateTime.Now;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; } = 0;

        [Required]
        [StringLength(20)]
        public string Status { get; set; } = "DRAFT"; // DRAFT, POSTED, CANCELLED

        public DateTime? PostedAt { get; set; }

        public int? PostedByUserId { get; set; }

        public DateTime? CancelledAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [StringLength(500)]
        public string? Notes { get; set; }

        [ForeignKey("SupplierId")]
        public virtual Supplier? Supplier { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        [ForeignKey("PostedByUserId")]
        public virtual User? PostedByUser { get; set; }

        public virtual ICollection<ImportReceiptDetail> Details { get; set; } = new List<ImportReceiptDetail>();
    }
}
