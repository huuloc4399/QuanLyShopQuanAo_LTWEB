using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("Suppliers")]
    public class Supplier
    {
        [Key]
        public int SupplierId { get; set; }

        [Required]
        [StringLength(150)]
        public string SupplierName { get; set; } = string.Empty;

        [StringLength(20)]
        public string? Phone { get; set; }

        [StringLength(100)]
        public string? Email { get; set; }

        [StringLength(255)]
        public string? Address { get; set; }

        public virtual ICollection<ImportReceipt> ImportReceipts { get; set; } = new List<ImportReceipt>();
    }
}
