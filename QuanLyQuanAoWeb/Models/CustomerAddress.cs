using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyQuanAoWeb.Models
{
    [Table("CustomerAddresses")]
    public class CustomerAddress
    {
        [Key]
        public int AddressId { get; set; }

        public int UserId { get; set; }

        [Required]
        [StringLength(100)]
        public string ReceiverName { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(255)]
        public string SpecificAddress { get; set; } = string.Empty;

        [StringLength(100)]
        public string? City { get; set; }

        public bool IsDefault { get; set; } = false;

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
