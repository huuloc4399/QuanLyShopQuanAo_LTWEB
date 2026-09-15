using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("ImportReceipts")]
    public class ImportReceipt
    {
        [Key]
        public int ImportId { get; set; }

        public int SupplierId { get; set; }

        public int UserId { get; set; }

        public DateTime ImportDate { get; set; } = DateTime.Now;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; } = 0;

        [StringLength(500)]
        public string? Notes { get; set; }

        [ForeignKey("SupplierId")]
        public virtual Supplier? Supplier { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        public virtual ICollection<ImportReceiptDetail> Details { get; set; } = new List<ImportReceiptDetail>();
    }
}
