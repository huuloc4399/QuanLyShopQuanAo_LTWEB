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

        // GET: /Cart/Checkout
        [HttpGet]
        public async Task<IActionResult> Checkout(string? couponCode = null)
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

            if (!items.Any())
            {
                TempData["ErrorMessage"] = "Giỏ hàng của bạn đang trống!";
                return RedirectToAction(nameof(Index));
            }

            decimal subtotal = items.Sum(i => i.Quantity * (i.Variant?.Product?.FinalPrice ?? 0));
            decimal discountAmount = 0;
            decimal shippingFee = 0; // Miễn phí giao hàng toàn quốc

            var availableCoupons = await _context.Coupons
                .Where(c => c.IsActive && c.EndDate >= DateTime.Now)
                .ToListAsync();

            if (!string.IsNullOrWhiteSpace(couponCode))
            {
                var cp = availableCoupons.FirstOrDefault(c => c.CouponCode.Equals(couponCode.Trim(), StringComparison.OrdinalIgnoreCase));
                if (cp != null && subtotal >= cp.MinOrderAmount)
                {
                    if (cp.DiscountPercent.HasValue && cp.DiscountPercent > 0)
                    {
                        discountAmount = subtotal * (cp.DiscountPercent.Value / 100m);
                        if (cp.MaxDiscountAmount.HasValue && discountAmount > cp.MaxDiscountAmount.Value)
                        {
                            discountAmount = cp.MaxDiscountAmount.Value;
                        }
                    }
                    else if (cp.DiscountAmount.HasValue && cp.DiscountAmount > 0)
                    {
                        discountAmount = Math.Min(cp.DiscountAmount.Value, subtotal);
                    }
                }
            }

            var vm = new QuanLyQuanAoWeb.Models.ViewModels.CheckoutViewModel
            {
                Items = items,
                Subtotal = subtotal,
                ShippingFee = shippingFee,
                DiscountAmount = discountAmount,
                TotalAmount = Math.Max(0, subtotal + shippingFee - discountAmount),
                CouponCode = couponCode,
                AvailableCoupons = availableCoupons,
                PaymentMethod = "COD"
            };

            // Điền sẵn thông tin khách nếu đã đăng nhập
            if (User.Identity?.IsAuthenticated == true)
            {
                var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (int.TryParse(userIdStr, out int uid))
                {
                    var user = await _context.Users.FindAsync(uid);
                    if (user != null)
                    {
                        vm.ReceiverName = user.FullName;
                        vm.ReceiverPhone = user.PhoneNumber ?? string.Empty;
                        vm.CustomerEmail = user.Email;
                        vm.ShippingAddress = user.Address ?? string.Empty;
                    }
                }
            }

            return View(vm);
        }

        // POST: /Cart/Checkout
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Checkout(QuanLyQuanAoWeb.Models.ViewModels.CheckoutViewModel model)
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

            if (!items.Any())
            {
                TempData["ErrorMessage"] = "Giỏ hàng của bạn đang trống!";
                return RedirectToAction(nameof(Index));
            }

            if (!ModelState.IsValid)
            {
                model.Items = items;
                model.Subtotal = items.Sum(i => i.Quantity * (i.Variant?.Product?.FinalPrice ?? 0));
                model.AvailableCoupons = await _context.Coupons.Where(c => c.IsActive && c.EndDate >= DateTime.Now).ToListAsync();
                return View(model);
            }

            // Giao dịch nguyên tử Checkout theo mục 6.1 bosung.md
            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Kiểm tra tồn khả dụng AvailableQuantity = StockQuantity - ActiveReservedQuantity
                foreach (var item in items)
                {
                    if (item.Variant == null || !item.Variant.IsActive || item.Variant.Product == null || !item.Variant.Product.IsActive)
                    {
                        TempData["ErrorMessage"] = $"Sản phẩm {item.Variant?.Product?.ProductName ?? "trong giỏ"} hiện đã ngừng kinh doanh!";
                        return RedirectToAction(nameof(Index));
                    }

                    var activeReserved = await _context.InventoryReservations
                        .Where(ir => ir.VariantId == item.VariantId && ir.Status == "ACTIVE")
                        .SumAsync(ir => (int?)ir.Quantity) ?? 0;

                    int available = item.Variant.StockQuantity - activeReserved;
                    if (item.Quantity > available)
                    {
                        TempData["ErrorMessage"] = $"Sản phẩm {item.Variant.Product.ProductName} ({item.Variant.Size?.SizeName} - {item.Variant.Color?.ColorName}) chỉ còn {Math.Max(0, available)} sản phẩm có thể đặt!";
                        return RedirectToAction(nameof(Index));
                    }
                }

                // 2. Tính tiền hàng và kiểm tra voucher
                decimal subtotal = items.Sum(i => i.Quantity * (i.Variant?.Product?.FinalPrice ?? 0));
                decimal discountAmount = 0;
                decimal shippingFee = 0;
                Coupon? appliedCoupon = null;

                if (!string.IsNullOrWhiteSpace(model.CouponCode))
                {
                    var cpCode = model.CouponCode.Trim();
                    var cp = await _context.Coupons.FirstOrDefaultAsync(c => c.CouponCode == cpCode && c.IsActive);
                    var now = DateTime.Now;
                    if (cp != null && cp.StartDate <= now && cp.EndDate >= now && subtotal >= cp.MinOrderAmount && cp.UsedCount < cp.UsageLimit)
                    {
                        appliedCoupon = cp;
                        if (cp.DiscountPercent.HasValue && cp.DiscountPercent > 0)
                        {
                            discountAmount = subtotal * (cp.DiscountPercent.Value / 100m);
                            if (cp.MaxDiscountAmount.HasValue && discountAmount > cp.MaxDiscountAmount.Value)
                            {
                                discountAmount = cp.MaxDiscountAmount.Value;
                            }
                        }
                        else if (cp.DiscountAmount.HasValue && cp.DiscountAmount > 0)
                        {
                            discountAmount = Math.Min(cp.DiscountAmount.Value, subtotal);
                        }
                    }
                }

                decimal totalAmount = Math.Max(0, subtotal + shippingFee - discountAmount);

                // 3. Khởi tạo mã đơn hàng không lộ ID tuần tự
                string orderCode = $"ORD-{DateTime.Now:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";

                int? userId = null;
                if (User.Identity?.IsAuthenticated == true)
                {
                    var uidStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
                    if (int.TryParse(uidStr, out int uid)) userId = uid;
                }

                // 4. Tạo Order
                var order = new Order
                {
                    OrderCode = orderCode,
                    UserId = userId,
                    CouponId = appliedCoupon?.CouponId,
                    OrderDate = DateTime.Now,
                    ReceiverName = model.ReceiverName.Trim(),
                    ReceiverPhone = model.ReceiverPhone.Trim(),
                    ShippingAddress = model.ShippingAddress.Trim(),
                    OrderNotes = model.OrderNotes?.Trim(),
                    CustomerEmail = model.CustomerEmail?.Trim(),
                    Subtotal = subtotal,
                    DiscountAmount = discountAmount,
                    ShippingFee = shippingFee,
                    TaxAmount = 0,
                    TotalAmount = totalAmount,
                    CurrencyCode = "VND",
                    PaymentMethod = model.PaymentMethod,
                    PaymentStatus = model.PaymentMethod == "COD" ? "Chưa thanh toán" : "Chờ thanh toán",
                    OrderStatus = "Chờ xác nhận"
                };
                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                // 5. Tạo OrderDetails với 5 Snapshot lịch sử và tạo InventoryReservations
                foreach (var item in items)
                {
                    var unitPrice = item.Variant?.Product?.FinalPrice ?? 0;
                    var od = new OrderDetail
                    {
                        OrderId = order.OrderId,
                        VariantId = item.VariantId,
                        Quantity = item.Quantity,
                        UnitPrice = unitPrice,
                        // Snapshot lịch sử hóa đơn vĩnh viễn theo bosung.md
                        ProductCodeSnapshot = item.Variant?.Product?.ProductCode ?? string.Empty,
                        ProductNameSnapshot = item.Variant?.Product?.ProductName ?? "Sản phẩm",
                        SKUSnapshot = item.Variant?.SKU ?? string.Empty,
                        SizeNameSnapshot = item.Variant?.Size?.SizeName ?? string.Empty,
                        ColorNameSnapshot = item.Variant?.Color?.ColorName ?? string.Empty
                    };
                    _context.OrderDetails.Add(od);

                    // Giữ tồn nguyên tử
                    var reservation = new InventoryReservation
                    {
                        OrderId = order.OrderId,
                        VariantId = item.VariantId,
                        Quantity = item.Quantity,
                        Status = "ACTIVE",
                        ExpiresAt = DateTime.Now.AddHours(24),
                        CreatedAt = DateTime.Now
                    };
                    _context.InventoryReservations.Add(reservation);
                }

                // 6. Ghi nhận giữ voucher trong CouponUsages
                if (appliedCoupon != null)
                {
                    var usage = new CouponUsage
                    {
                        CouponId = appliedCoupon.CouponId,
                        OrderId = order.OrderId,
                        UserId = userId,
                        SessionId = cart.SessionId,
                        DiscountAmount = discountAmount,
                        Status = "RESERVED",
                        ReservedAt = DateTime.Now
                    };
                    _context.CouponUsages.Add(usage);
                    appliedCoupon.UsedCount += 1;
                }

                // 7. Khởi tạo Payment
                var payment = new Payment
                {
                    OrderId = order.OrderId,
                    PaymentMethod = model.PaymentMethod,
                    Amount = totalAmount,
                    Status = "PENDING",
                    IdempotencyKey = $"PAY-{order.OrderCode}-{Guid.NewGuid():N}",
                    RefundedAmount = 0,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };
                _context.Payments.Add(payment);

                // 8. Ghi nhật ký trạng thái đơn hàng OrderStatusHistory
                var history = new OrderStatusHistory
                {
                    OrderId = order.OrderId,
                    FromStatus = null,
                    ToStatus = "Chờ xác nhận",
                    ChangedByUserId = userId,
                    ChangedAt = DateTime.Now,
                    Note = $"Đơn hàng được khởi tạo thành công qua website (PTTT: {model.PaymentMethod})"
                };
                _context.OrderStatusHistories.Add(history);

                // 9. Dọn sạch giỏ hàng và commit transaction
                _context.CartItems.RemoveRange(items);
                cart.UpdatedAt = DateTime.Now;
                await _context.SaveChangesAsync();

                await tx.CommitAsync();

                return RedirectToAction(nameof(OrderSuccess), new { id = order.OrderId });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                TempData["ErrorMessage"] = $"Lỗi xử lý đặt hàng: {ex.Message}";
                return RedirectToAction(nameof(Index));
            }
        }

        // GET: /Cart/OrderSuccess/5
        [HttpGet]
        public async Task<IActionResult> OrderSuccess(int id)
        {
            var order = await _context.Orders
                .Include(o => o.OrderDetails)
                .Include(o => o.Payments)
                .Include(o => o.StatusHistories)
                .FirstOrDefaultAsync(o => o.OrderId == id);

            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy thông tin đơn hàng!";
                return RedirectToAction("Index", "Home");
            }

            return View(order);
        }
    }
}
