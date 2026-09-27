using System.ComponentModel.DataAnnotations;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Models.ViewModels
{
    public class CheckoutViewModel
    {
        [Required(ErrorMessage = "Vui lòng nhập họ và tên người nhận!")]
        [Display(Name = "Họ và tên")]
        public string ReceiverName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập số điện thoại giao hàng!")]
        [Phone(ErrorMessage = "Số điện thoại không đúng định dạng!")]
        [Display(Name = "Số điện thoại")]
        public string ReceiverPhone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập địa chỉ nhận hàng chi tiết!")]
        [Display(Name = "Địa chỉ nhận hàng")]
        public string ShippingAddress { get; set; } = string.Empty;

        [EmailAddress(ErrorMessage = "Email không hợp lệ!")]
        [Display(Name = "Địa chỉ Email")]
        public string? CustomerEmail { get; set; }

        [Display(Name = "Ghi chú đơn hàng")]
        public string? OrderNotes { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn phương thức thanh toán!")]
        [Display(Name = "Phương thức thanh toán")]
        public string PaymentMethod { get; set; } = "COD";

        [Display(Name = "Mã voucher giảm giá")]
        public string? CouponCode { get; set; }

        // Hiển thị tóm tắt giỏ hàng
        public List<CartItem> Items { get; set; } = new();
        public decimal Subtotal { get; set; }
        public decimal ShippingFee { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal TotalAmount { get; set; }
        public List<Coupon> AvailableCoupons { get; set; } = new();
    }
}
