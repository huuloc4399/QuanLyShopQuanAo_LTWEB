using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;
using QuanLyQuanAoWeb.Models;
using System.Security.Claims;

namespace QuanLyQuanAoWeb.Controllers
{
    public class CartController : Controller
    {
        private readonly ApplicationDbContext _context;

        public CartController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Lấy hoặc tạo mới Giỏ hàng cho User hoặc Khách vãng lai qua Session
        private async Task<Cart> GetOrCreateCartAsync()
        {
            Cart? cart = null;

            if (User.Identity?.IsAuthenticated == true)
            {
                var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (int.TryParse(userIdStr, out int userId))
                {
                    cart = await _context.Carts
                        .Include(c => c.CartItems)
                        .FirstOrDefaultAsync(c => c.UserId == userId);

                    if (cart == null)
                    {
                        cart = new Cart
                        {
                            UserId = userId,
                            CreatedAt = DateTime.Now,
                            UpdatedAt = DateTime.Now
                        };
                        _context.Carts.Add(cart);
                        await _context.SaveChangesAsync();
                    }
                    return cart;
                }
            }

            // Khách vãng lai qua Session
            var sessionId = HttpContext.Session.GetString("CartSessionId");
            if (string.IsNullOrEmpty(sessionId))
            {
                sessionId = Guid.NewGuid().ToString();
                HttpContext.Session.SetString("CartSessionId", sessionId);
            }

            cart = await _context.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.SessionId == sessionId);

            if (cart == null)
            {
                cart = new Cart
                {
                    SessionId = sessionId,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };
                _context.Carts.Add(cart);
                await _context.SaveChangesAsync();
            }

            return cart;
        }

        // GET: /Cart
        public async Task<IActionResult> Index()
        {
            var cart = await GetOrCreateCartAsync();

            var items = await _context.CartItems
                .Where(ci => ci.CartId == cart.CartId)
                .Include(ci => ci.Variant)
                    .ThenInclude(v => v!.Product)
                .Include(ci => ci.Variant)
                    .ThenInclude(v => v!.Size)
                .Include(ci => ci.Variant)
                    .ThenInclude(v => v!.Color)
                .ToListAsync();

            var coupons = await _context.Coupons
                .Where(c => c.IsActive && c.EndDate >= DateTime.Now)
                .ToListAsync();

            ViewBag.Coupons = coupons;
            ViewBag.CartId = cart.CartId;

            return View(items);
        }

        // POST: /Cart/AddToCart
        [HttpPost]
        public async Task<IActionResult> AddToCart(int variantId, int quantity = 1)
        {
            if (quantity <= 0) quantity = 1;

            var variant = await _context.ProductVariants
                .Include(v => v.Product)
                .FirstOrDefaultAsync(v => v.VariantId == variantId);

            if (variant == null)
            {
                TempData["ErrorMessage"] = "Biến thể sản phẩm không tồn tại!";
                return RedirectToAction("Index", "Home");
            }

            if (variant.StockQuantity < quantity)
            {
                TempData["ErrorMessage"] = $"Số lượng trong kho chỉ còn {variant.StockQuantity} sản phẩm!";
                return RedirectToAction("Details", "Home", new { id = variant.ProductId });
            }

            var cart = await GetOrCreateCartAsync();

            var cartItem = await _context.CartItems
                .FirstOrDefaultAsync(ci => ci.CartId == cart.CartId && ci.VariantId == variantId);

            if (cartItem == null)
            {
                cartItem = new CartItem
                {
                    CartId = cart.CartId,
                    VariantId = variantId,
                    Quantity = quantity,
                    AddedAt = DateTime.Now
                };
                _context.CartItems.Add(cartItem);
            }
            else
            {
                cartItem.Quantity += quantity;
            }

            cart.UpdatedAt = DateTime.Now;
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = $"Đã thêm {variant.Product?.ProductName} vào giỏ hàng!";
            return RedirectToAction(nameof(Index));
        }

        // POST: /Cart/UpdateQuantity
        [HttpPost]
        public async Task<IActionResult> UpdateQuantity(int cartItemId, int quantity)
        {
            var cartItem = await _context.CartItems
                .Include(ci => ci.Variant)
                .FirstOrDefaultAsync(ci => ci.CartItemId == cartItemId);

            if (cartItem != null)
            {
                if (quantity <= 0)
                {
                    _context.CartItems.Remove(cartItem);
                }
                else
                {
                    if (cartItem.Variant != null && cartItem.Variant.StockQuantity < quantity)
                    {
                        TempData["ErrorMessage"] = $"Kho chỉ còn {cartItem.Variant.StockQuantity} sản phẩm!";
                        return RedirectToAction(nameof(Index));
                    }
                    cartItem.Quantity = quantity;
                }
                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: /Cart/RemoveItem
        [HttpPost]
        public async Task<IActionResult> RemoveItem(int cartItemId)
        {
            var cartItem = await _context.CartItems.FindAsync(cartItemId);
            if (cartItem != null)
            {
                _context.CartItems.Remove(cartItem);
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Đã xóa sản phẩm khỏi giỏ hàng!";
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
