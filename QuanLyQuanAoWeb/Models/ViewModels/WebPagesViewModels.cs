using System.ComponentModel.DataAnnotations;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Models.ViewModels
{
    public class ProductCatalogViewModel
    {
        public List<Category> Categories { get; set; } = new();
        public List<Product> Products { get; set; } = new();
        public int? SelectedCategoryId { get; set; }
        public string? SearchKeyword { get; set; }
        public string? SortOrder { get; set; }
        public int TotalCount { get; set; }
    }

    public class NewsViewModel
    {
        public List<NewsArticleItem> Articles { get; set; } = new();
        public List<string> Tags { get; set; } = new();
        public string? SelectedTag { get; set; }
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; } = 1;
    }

    public class NewsArticleItem
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Tag { get; set; } = string.Empty;
        public string TagColor { get; set; } = "navy"; // navy, orange, green, blue
        public string PublishedDate { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public string Author { get; set; } = "Ban Biên Tập HUIT";
        public int ReadTimeMinutes { get; set; } = 4;
        public int Views { get; set; } = 1250;
    }

    public class ContactRequestViewModel
    {
        [Required(ErrorMessage = "Vui lòng nhập họ và tên của bạn!")]
        [Display(Name = "Họ và tên")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập số điện thoại liên hệ!")]
        [Phone(ErrorMessage = "Số điện thoại không đúng định dạng!")]
        [Display(Name = "Số điện thoại")]
        public string PhoneNumber { get; set; } = string.Empty;

        [EmailAddress(ErrorMessage = "Địa chỉ email không hợp lệ!")]
        [Display(Name = "Email")]
        public string? Email { get; set; }

        [Display(Name = "Tên công ty / Doanh nghiệp")]
        public string? CompanyName { get; set; }

        [Display(Name = "Loại đồng phục")]
        public string? UniformType { get; set; }

        [Display(Name = "Số lượng dự kiến")]
        public string? Quantity { get; set; }

        [Display(Name = "Nội dung yêu cầu chi tiết")]
        public string? Note { get; set; }
    }
}
