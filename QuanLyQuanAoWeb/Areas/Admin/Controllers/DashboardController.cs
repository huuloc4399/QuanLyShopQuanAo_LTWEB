using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;
using QuanLyQuanAoWeb.Models.ViewModels;

namespace QuanLyQuanAoWeb.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin,Staff")]
    public class DashboardController : Controller
    {
        private readonly ApplicationDbContext _context;

        public DashboardController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Admin/Dashboard
        public async Task<IActionResult> Index()
        {
            var totalProducts = await _context.Products.CountAsync();
            var totalCategories = await _context.Categories.CountAsync();
            var totalOrders = await _context.Orders.CountAsync();
            var totalUsers = await _context.Users.CountAsync();

            // Tổng doanh thu từ các đơn hàng không bị hủy
            var totalRevenue = await _context.Orders
                .Where(o => o.OrderStatus != "Đã hủy")
                .SumAsync(o => (decimal?)o.TotalAmount) ?? 0;

            // Biến thể có tồn kho thấp (< 20 cái)
            var lowStockVariants = await _context.ProductVariants
                .Include(pv => pv.Product)
                .Include(pv => pv.Size)
                .Include(pv => pv.Color)
                .Where(pv => pv.StockQuantity < 20)
                .OrderBy(pv => pv.StockQuantity)
                .Take(10)
                .ToListAsync();

            // Đơn hàng mới nhất
            var recentOrders = await _context.Orders
                .OrderByDescending(o => o.OrderDate)
                .Take(5)
                .ToListAsync();

            var viewModel = new AdminDashboardViewModel
            {
                TotalProducts = totalProducts,
                TotalCategories = totalCategories,
                TotalOrders = totalOrders,
                TotalUsers = totalUsers,
                TotalRevenue = totalRevenue,
                LowStockProductsCount = lowStockVariants.Count,
                RecentOrders = recentOrders,
                LowStockVariants = lowStockVariants
            };

            return View(viewModel);
        }
    }
}
