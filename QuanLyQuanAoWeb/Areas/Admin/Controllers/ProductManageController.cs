using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data; 

namespace QuanLyQuanAoWeb.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class ProductManageController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ProductManageController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            // Lấy danh sách sản phẩm kèm theo thông tin biến thể (Variants) để tính tồn kho nếu cần
            var products = await _context.Products
                .Include(p => p.Variants)
                .ToListAsync();

            return View(products);
        }
    }
}