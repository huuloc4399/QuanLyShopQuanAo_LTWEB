using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;

namespace QuanLyQuanAoWeb.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class InventoryController : Controller
    {
        private readonly ApplicationDbContext _context;

        public InventoryController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 1. Hiển thị danh sách tồn kho tổng quan của các sản phẩm
        public async Task<IActionResult> Index()
        {
            var products = await _context.Products
                .Include(p => p.Variants) // Nạp kèm các biến thể (Size, Màu, Tồn kho)
                .Where(p => p.IsActive == true) // Chỉ lấy sản phẩm đang hoạt động
                .ToListAsync();

            return View(products);
        }

        // 2. GET: Hiển thị trang cập nhật kho kèm theo Size và Color
        public async Task<IActionResult> EditStock(int? id)
        {
            if (id == null) return NotFound();

            var product = await _context.Products
                .Include(p => p.Variants)
                    .ThenInclude(v => v.Size)   // Nạp thông tin Size
                .Include(p => p.Variants)
                    .ThenInclude(v => v.Color)  // Nạp thông tin Color
                .FirstOrDefaultAsync(p => p.ProductId == id);

            if (product == null) return NotFound();

            return View(product);
        }

        // 3. POST: Lưu số lượng tồn kho mới cho từng biến thể
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditStock(int ProductId, Dictionary<int, int> variantQuantities)
        {
            var product = await _context.Products
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.ProductId == ProductId);

            if (product == null) return NotFound();

            // Cập nhật số lượng cho từng biến thể dựa vào Dictionary gửi lên từ form
            foreach (var variant in product.Variants)
            {
                if (variantQuantities.ContainsKey(variant.VariantId))
                {
                    variant.StockQuantity = variantQuantities[variant.VariantId];
                    _context.Update(variant);
                }
            }

            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }
    }
}