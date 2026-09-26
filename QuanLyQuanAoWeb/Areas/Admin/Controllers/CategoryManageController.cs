using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;

namespace QuanLyQuanAoWeb.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class CategoryManageController : Controller
    {
        private readonly ApplicationDbContext _context;

        public CategoryManageController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var categories = await _context.Categories.ToListAsync();
            return View(categories);
        }
    }
}