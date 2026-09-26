using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;
using QuanLyQuanAoWeb.Models;

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

        // 1. Danh sách sản phẩm (Chỉ hiển thị sản phẩm đang hoạt động)
        public async Task<IActionResult> Index()
        {
            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Variants)
                .Where(p => p.IsActive == true) // Lọc bỏ các sản phẩm đã xóa mềm (IsActive = false)
                .ToListAsync();
            return View(products);
        }

        // 2. GET: Thêm mới (Create)
        public IActionResult Create()
        {
            ViewBag.CategoryId = new SelectList(_context.Categories, "CategoryId", "CategoryName"); // Sửa lại tên khóa/tên hiển thị của Category nếu cần
            return View();
        }

        // POST: Thêm mới (Create)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Product product, IFormFile? imageFile)
        {
            // ModelState.IsValid có thể vướng các trường như Category hoặc CreatedAt, ta có thể gán giá trị mặc định nếu cần
            product.CreatedAt = DateTime.Now;

            if (imageFile != null && imageFile.Length > 0)
            {
                string fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                string uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/products", fileName);

                // Đảm bảo thư mục tồn tại
                Directory.CreateDirectory(Path.GetDirectoryName(uploadPath)!);

                using (var stream = new FileStream(uploadPath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(stream);
                }
                product.MainImage = "/images/products/" + fileName;
            }

            _context.Add(product);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        // 3. GET: Chi tiết (Details)
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null) return NotFound();

            var product = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Variants)
                .FirstOrDefaultAsync(m => m.ProductId == id);

            if (product == null) return NotFound();

            return View(product);
        }

        // 4. GET: Sửa (Edit)
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null) return NotFound();

            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            ViewBag.CategoryId = new SelectList(_context.Categories, "CategoryId", "CategoryName", product.CategoryId);
            return View(product);
        }

        // POST: Sửa (Edit)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Product product, IFormFile? imageFile)
        {
            if (id != product.ProductId) return NotFound();

            // Lấy sản phẩm cũ từ DB để giữ lại thông tin nếu cần
            var existingProduct = await _context.Products.AsNoTracking().FirstOrDefaultAsync(p => p.ProductId == id);
            if (existingProduct == null) return NotFound();

            if (imageFile != null && imageFile.Length > 0)
            {
                string fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                string uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images/products", fileName);

                Directory.CreateDirectory(Path.GetDirectoryName(uploadPath)!);

                using (var stream = new FileStream(uploadPath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(stream);
                }
                product.MainImage = "/images/products/" + fileName;
            }
            else
            {
                product.MainImage = existingProduct.MainImage; // Giữ lại ảnh cũ nếu không chọn ảnh mới
            }

            _context.Update(product);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        // 5. Xóa (Delete)
        //1. GET: Hiển thị trang xác nhận xóa
        [HttpGet]
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null) return NotFound();

            var product = await _context.Products
                .Include(p => p.Category)
                .FirstOrDefaultAsync(m => m.ProductId == id);

            if (product == null) return NotFound();

            return View(product);
        }

        //2. POST: Thực hiện xóa mềm 
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                // Xóa mềm: Chuyển trạng thái kinh doanh thành false (ẩn khỏi web nhưng vẫn giữ trong SQL)
                product.IsActive = false;

                _context.Products.Update(product);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }
    }
}