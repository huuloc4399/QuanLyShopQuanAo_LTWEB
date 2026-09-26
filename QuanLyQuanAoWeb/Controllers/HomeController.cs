using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;
using QuanLyQuanAoWeb.Models.ViewModels;
using System.Diagnostics;

namespace QuanLyQuanAoWeb.Controllers
{
    public class HomeController : Controller
    {
        private readonly ApplicationDbContext _context;

        public HomeController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Home/Index
        public async Task<IActionResult> Index(int? categoryId, string? keyword, decimal? minPrice, decimal? maxPrice)
        {
            var categories = await _context.Categories
                .Where(c => c.IsActive)
                .OrderBy(c => c.DisplayOrder)
                .ToListAsync();

            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Variants)
                .Where(p => p.IsActive)
                .AsQueryable();

            if (categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                string search = keyword.Trim().ToLower();
                query = query.Where(p => p.ProductName.ToLower().Contains(search) || 
                                         (p.ProductCode != null && p.ProductCode.ToLower().Contains(search)));
            }

            if (minPrice.HasValue)
            {
                query = query.Where(p => p.Price >= minPrice.Value);
            }

            if (maxPrice.HasValue)
            {
                query = query.Where(p => p.Price <= maxPrice.Value);
            }

            var allProducts = await query.OrderByDescending(p => p.ProductId).ToListAsync();

            var featuredProducts = await _context.Products
                .Include(p => p.Category)
                .Where(p => p.IsActive && p.IsFeatured)
                .Take(4)
                .ToListAsync();

            var viewModel = new HomeViewModel
            {
                Categories = categories,
                FeaturedProducts = featuredProducts,
                AllProducts = allProducts,
                SelectedCategoryId = categoryId,
                SearchKeyword = keyword,
                MinPrice = minPrice,
                MaxPrice = maxPrice
            };

            return View(viewModel);
        }

        // GET: /Home/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var product = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Variants)
                    .ThenInclude(v => v.Size)
                .Include(p => p.Variants)
                    .ThenInclude(v => v.Color)
                .Include(p => p.Reviews)
                    .ThenInclude(r => r.User)
                .FirstOrDefaultAsync(p => p.ProductId == id && p.IsActive);

            if (product == null)
            {
                return NotFound();
            }

            // Sản phẩm liên quan cùng danh mục
            ViewBag.RelatedProducts = await _context.Products
                .Where(p => p.CategoryId == product.CategoryId && p.ProductId != product.ProductId && p.IsActive)
                .Take(4)
                .ToListAsync();

            return View(product);
        }

        // GET: /Home/Products
        public async Task<IActionResult> Products(int? categoryId, string? keyword, string? sortOrder)
        {
            var categories = await _context.Categories
                .Where(c => c.IsActive)
                .OrderBy(c => c.DisplayOrder)
                .ToListAsync();

            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Variants)
                .Include(p => p.Reviews)
                .Where(p => p.IsActive)
                .AsQueryable();

            if (categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                string search = keyword.Trim().ToLower();
                query = query.Where(p => p.ProductName.ToLower().Contains(search) || 
                                         (p.ProductCode != null && p.ProductCode.ToLower().Contains(search)));
            }

            switch (sortOrder)
            {
                case "price_asc":
                    query = query.OrderBy(p => p.Price);
                    break;
                case "price_desc":
                    query = query.OrderByDescending(p => p.Price);
                    break;
                case "name":
                    query = query.OrderBy(p => p.ProductName);
                    break;
                default:
                    query = query.OrderByDescending(p => p.IsFeatured).ThenByDescending(p => p.ProductId);
                    break;
            }

            var products = await query.ToListAsync();

            var viewModel = new ProductCatalogViewModel
            {
                Categories = categories,
                Products = products,
                SelectedCategoryId = categoryId,
                SearchKeyword = keyword,
                SortOrder = sortOrder,
                TotalCount = products.Count
            };

            return View(viewModel);
        }

        // GET: /Home/News
        public IActionResult News(string? tag, int page = 1)
        {
            var allArticles = GetSampleArticles();
            var tags = new List<string> { "Tất cả", "Kiến thức vải", "Xu hướng 2026", "Cẩm nang may", "Tin nội bộ" };

            var filtered = allArticles.AsQueryable();
            if (!string.IsNullOrWhiteSpace(tag) && tag != "Tất cả")
            {
                filtered = filtered.Where(a => a.Tag.Equals(tag, StringComparison.OrdinalIgnoreCase) || 
                                               a.Tag.Contains(tag, StringComparison.OrdinalIgnoreCase));
            }

            int pageSize = 9;
            int totalItems = filtered.Count();
            int totalPages = (int)Math.Ceiling((double)totalItems / pageSize);
            page = Math.Max(1, Math.Min(page, Math.Max(1, totalPages)));

            var pagedArticles = filtered
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            var viewModel = new NewsViewModel
            {
                Articles = pagedArticles,
                Tags = tags,
                SelectedTag = tag ?? "Tất cả",
                CurrentPage = page,
                TotalPages = totalPages
            };

            return View(viewModel);
        }

        // GET: /Home/Contact
        public IActionResult Contact()
        {
            return View(new ContactRequestViewModel());
        }

        // POST: /Home/Contact
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Contact(ContactRequestViewModel model)
        {
            if (ModelState.IsValid)
            {
                TempData["SuccessMessage"] = $"Cảm ơn Quý khách {model.FullName}! HUIT Uniform đã tiếp nhận yêu cầu báo giá và sẽ liên hệ lại qua số điện thoại {model.PhoneNumber} trong vòng 15 phút.";
                return RedirectToAction(nameof(Contact));
            }

            return View(model);
        }

        private List<NewsArticleItem> GetSampleArticles()
        {
            return new List<NewsArticleItem>
            {
                new NewsArticleItem
                {
                    Id = 1,
                    Title = "Chất liệu vải may áo thun đồng phục phổ biến nhất hiện nay",
                    Tag = "Kiến thức vải",
                    TagColor = "navy",
                    PublishedDate = "15/03/2026",
                    Summary = "So sánh chi tiết ưu nhược điểm giữa cotton 100%, CVC 65/35, TC và Poly Thái giúp doanh nghiệp chọn đúng chất liệu tối ưu chi phí và thẩm mỹ.",
                    ImageUrl = "https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600&auto=format&fit=crop&q=80",
                    Author = "Ban Biên Tập HUIT",
                    ReadTimeMinutes = 4,
                    Views = 1840
                },
                new NewsArticleItem
                {
                    Id = 2,
                    Title = "Ý nghĩa màu sắc trong thiết kế nhận diện thương hiệu",
                    Tag = "Xu hướng 2026",
                    TagColor = "orange",
                    PublishedDate = "12/03/2026",
                    Summary = "Màu sắc đồng phục là ngôn ngữ thị giác trực tiếp nhất truyền tải bản sắc văn hóa, sự chuyên nghiệp và tạo lòng tin vững chắc nơi đối tác khách hàng.",
                    ImageUrl = "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&auto=format&fit=crop&q=80",
                    Author = "Creative Team",
                    ReadTimeMinutes = 5,
                    Views = 2410
                },
                new NewsArticleItem
                {
                    Id = 3,
                    Title = "Tiêu chuẩn trang thiết bị bảo hộ lao động năm 2026",
                    Tag = "Cẩm nang may",
                    TagColor = "navy",
                    PublishedDate = "10/03/2026",
                    Summary = "Cập nhật các quy định bắt buộc theo tiêu chuẩn TCVN và ANSI Z87.1 về áo gile phản quang, nón bảo hộ và giày chống đinh bảo vệ người lao động.",
                    ImageUrl = "https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&auto=format&fit=crop&q=80",
                    Author = "Kỹ Sư An Toàn",
                    ReadTimeMinutes = 6,
                    Views = 1590
                },
                new NewsArticleItem
                {
                    Id = 4,
                    Title = "Cách chọn bảng size chuẩn cho nhân viên văn phòng",
                    Tag = "Cẩm nang may",
                    TagColor = "navy",
                    PublishedDate = "05/03/2026",
                    Summary = "Hướng dẫn chi tiết phương pháp lấy số đo 3 vòng, chiều cao, cân nặng và đối chiếu bảng size S - 3XL may sẵn giúp giảm tối đa tỷ lệ sửa chữa.",
                    ImageUrl = "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&auto=format&fit=crop&q=80",
                    Author = "Phòng Mẫu HUIT",
                    ReadTimeMinutes = 3,
                    Views = 3120
                },
                new NewsArticleItem
                {
                    Id = 5,
                    Title = "So sánh công nghệ in lụa và thêu vi tính logo",
                    Tag = "Kiến thức vải",
                    TagColor = "orange",
                    PublishedDate = "01/03/2026",
                    Summary = "Nên in lụa plastisol, in decal nhiệt hay thêu vi tính 3D? Bài viết phân tích độ bền, chi phí và tính ứng dụng cụ thể trên từng chất liệu áo.",
                    ImageUrl = "https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=600&auto=format&fit=crop&q=80",
                    Author = "Kỹ Thuật Xưởng In",
                    ReadTimeMinutes = 5,
                    Views = 1980
                },
                new NewsArticleItem
                {
                    Id = 6,
                    Title = "Top 10 mẫu đồng phục nhà hàng sang trọng nhất",
                    Tag = "Xu hướng 2026",
                    TagColor = "navy",
                    PublishedDate = "28/02/2026",
                    Summary = "Tổng hợp các thiết kế tạp dề canvas da bò, áo bếp cổ tàu và đồng phục phục vụ bàn được ưa chuộng nhất tại các chuỗi nhà hàng cao cấp.",
                    ImageUrl = "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=600&auto=format&fit=crop&q=80",
                    Author = "F&B Consultant",
                    ReadTimeMinutes = 4,
                    Views = 2760
                },
                new NewsArticleItem
                {
                    Id = 7,
                    Title = "Hướng dẫn giặt và bảo quản đồng phục bền màu lâu phai",
                    Tag = "Cẩm nang may",
                    TagColor = "navy",
                    PublishedDate = "20/02/2026",
                    Summary = "Những lưu ý cốt lõi khi giặt bằng máy, nhiệt độ nước, chất tẩy rửa và cách là ủi giúp trang phục công sở luôn phẳng phiu và giữ form nguyên bản.",
                    ImageUrl = "https://images.unsplash.com/photo-1545127398-14699f92334b?w=600&auto=format&fit=crop&q=80",
                    Author = "Chuyên Viên QC",
                    ReadTimeMinutes = 3,
                    Views = 1430
                },
                new NewsArticleItem
                {
                    Id = 8,
                    Title = "Xu hướng đồng phục công sở thân thiện môi trường",
                    Tag = "Xu hướng 2026",
                    TagColor = "orange",
                    PublishedDate = "15/02/2026",
                    Summary = "Khám phá xu hướng thời trang xanh bền vững với các dòng vải sợi tre bamboo kháng khuẩn tự nhiên, sợi bã cà phê và polyester tái chế.",
                    ImageUrl = "https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=600&auto=format&fit=crop&q=80",
                    Author = "Green Fashion HUIT",
                    ReadTimeMinutes = 5,
                    Views = 1890
                },
                new NewsArticleItem
                {
                    Id = 9,
                    Title = "Quy trình may đo đồng phục cao cấp cho lãnh đạo",
                    Tag = "Tin nội bộ",
                    TagColor = "navy",
                    PublishedDate = "10/02/2026",
                    Summary = "Bật mí quy trình may thủ công bespoke 8 bước cho các bộ veston, blazer lãnh đạo với chất liệu wool ngoại nhập chuẩn phong thái quý ông.",
                    ImageUrl = "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600&auto=format&fit=crop&q=80",
                    Author = "Master Tailor",
                    ReadTimeMinutes = 6,
                    Views = 2100
                }
            };
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new Models.ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
