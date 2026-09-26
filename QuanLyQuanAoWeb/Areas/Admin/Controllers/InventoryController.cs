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

        // GET: Admin/Inventory
        public async Task<IActionResult> Index()
        {
            var products = await _context.Products
            .Include(p => p.Variants)
            .ToListAsync();
            return View(products);
        }
        // GET: Admin/Inventory/EditStock/5
        public async Task<IActionResult> EditStock(int id)
        {
            var product = await _context.Products
                .Include(p => p.Variants)
                .ThenInclude(v => v.Size)
                .Include(p => p.Variants)
                .ThenInclude(v => v.Color)
                .FirstOrDefaultAsync(m => m.ProductId == id);

            if (product == null)
            {
                return NotFound();
            }

            return View(product);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditStock(int ProductId, Dictionary<int, int> variantStock)
        {
            var product = await _context.Products
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(p => p.ProductId == ProductId);

            if (product == null)
            {
                return NotFound();
            }

            // Cập nhật số lượng cho từng biến thể
            foreach (var variant in product.Variants)
            {
                if (variantStock.ContainsKey(variant.VariantId))
                {
                    variant.StockQuantity = variantStock[variant.VariantId];
                }
            }

            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }
    }
}