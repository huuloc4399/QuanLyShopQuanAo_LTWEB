using System.ComponentModel.DataAnnotations;

namespace QuanLyQuanAoWeb.Models.ViewModels
{
    public class LoginViewModel
    {
        [Required(ErrorMessage = "Vui lòng nhập tên đăng nhập!")]
        [Display(Name = "Tên đăng nhập")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu!")]
        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu")]
        public string Password { get; set; } = string.Empty;

        [Display(Name = "Ghi nhớ đăng nhập")]
        public bool RememberMe { get; set; }

        public string? ReturnUrl { get; set; }
    }

    public class RegisterViewModel
    {
        [Required(ErrorMessage = "Vui lòng nhập họ và tên!")]
        [Display(Name = "Họ và tên")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập tên đăng nhập!")]
        [Display(Name = "Tên đăng nhập")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập email!")]
        [EmailAddress(ErrorMessage = "Địa chỉ email không hợp lệ!")]
        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;

        [Display(Name = "Số điện thoại")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ!")]
        public string? PhoneNumber { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu!")]
        [StringLength(100, ErrorMessage = "{0} phải có ít nhất {2} ký tự.", MinimumLength = 6)]
        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu")]
        public string Password { get; set; } = string.Empty;

        [DataType(DataType.Password)]
        [Display(Name = "Xác nhận mật khẩu")]
        [Compare("Password", ErrorMessage = "Mật khẩu xác nhận không khớp!")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }

    public class HomeViewModel
    {
        public List<Category> Categories { get; set; } = new();
        public List<Product> FeaturedProducts { get; set; } = new();
        public List<Product> AllProducts { get; set; } = new();
        public int? SelectedCategoryId { get; set; }
        public string? SearchKeyword { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
    }

    public class AdminDashboardViewModel
    {
        public int TotalProducts { get; set; }
        public int TotalCategories { get; set; }
        public int TotalOrders { get; set; }
        public int TotalUsers { get; set; }
        public decimal TotalRevenue { get; set; }
        public int LowStockProductsCount { get; set; }
        public List<Order> RecentOrders { get; set; } = new();
        public List<ProductVariant> LowStockVariants { get; set; } = new();
    }
}
