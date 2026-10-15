using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;
using QuanLyQuanAoWeb.Models;
using QuanLyQuanAoWeb.Services.Payment;

namespace QuanLyQuanAoWeb.Controllers
{
    public class PaymentController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly IVNPayService _vnPayService;
        private readonly IMoMoService _moMoService;
        private readonly ILogger<PaymentController> _logger;

        public PaymentController(
            ApplicationDbContext context,
            IVNPayService vnPayService,
            IMoMoService moMoService,
            ILogger<PaymentController> logger)
        {
            _context = context;
            _vnPayService = vnPayService;
            _moMoService = moMoService;
            _logger = logger;
        }

        // ====================================================================
        // VNPAY CALLBACK & IPN
        // ====================================================================

        // GET: /Payment/VNPayCallback (Người dùng được chuyển hướng về trình duyệt)
        [HttpGet]
        public async Task<IActionResult> VNPayCallback()
        {
            _logger.LogInformation("Nhận VNPay Callback: {QueryString}", Request.QueryString.Value);

            var result = _vnPayService.ProcessCallback(Request.Query);

            if (string.IsNullOrWhiteSpace(result.OrderCode))
            {
                return RedirectToAction(nameof(PaymentFailed), new { message = "Không xác định được mã đơn hàng từ phản hồi VNPay!" });
            }

            var order = await _context.Orders
                .Include(o => o.Payments)
                .FirstOrDefaultAsync(o => o.OrderCode == result.OrderCode);

            if (order == null)
            {
                return RedirectToAction(nameof(PaymentFailed), new { message = $"Không tìm thấy đơn hàng {result.OrderCode} trong hệ thống!" });
            }

            if (!result.IsSuccess)
            {
                // Cập nhật trạng thái thanh toán thất bại nếu chưa thanh toán
                await ProcessPaymentFailureAsync(order, "VNPAY", result.TransactionId, result.Message);
                return RedirectToAction(nameof(PaymentFailed), new { orderId = order.OrderId, message = result.Message });
            }

            // Xử lý thành công (Đảm bảo chống xử lý giao dịch trùng lặp - Idempotent)
            await ProcessPaymentSuccessAsync(order, "VNPAY", result.TransactionId, result.BankCode);

            TempData["SuccessMessage"] = "Thanh toán qua cổng VNPay thành công!";
            return RedirectToAction("OrderSuccess", "Cart", new { id = order.OrderId });
        }

        // GET & POST: /Payment/VNPayIpn (Server-to-Server Instant Payment Notification)
        [HttpGet]
        [HttpPost]
        public async Task<IActionResult> VNPayIpn()
        {
            _logger.LogInformation("Nhận VNPay IPN webhook: {QueryString}", Request.QueryString.Value);

            var result = _vnPayService.ProcessIpn(Request.Query);

            // 1. Kiểm tra chữ ký bảo mật
            if (!result.IsSuccess && result.Message.Contains("Chữ ký", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("VNPay IPN: Chữ ký không hợp lệ!");
                return Json(new VNPayIpnResponse { RspCode = "97", Message = "Invalid Checksum" });
            }

            // 2. Tìm đơn hàng
            if (string.IsNullOrWhiteSpace(result.OrderCode))
            {
                return Json(new VNPayIpnResponse { RspCode = "01", Message = "Order not found" });
            }

            var order = await _context.Orders
                .Include(o => o.Payments)
                .FirstOrDefaultAsync(o => o.OrderCode == result.OrderCode);

            if (order == null)
            {
                _logger.LogWarning("VNPay IPN: Không tìm thấy đơn hàng {OrderCode}", result.OrderCode);
                return Json(new VNPayIpnResponse { RspCode = "01", Message = "Order not found" });
            }

            // 3. Kiểm tra số tiền giao dịch
            if (result.Amount > 0 && Math.Abs(order.TotalAmount - result.Amount) > 1.0m)
            {
                _logger.LogWarning("VNPay IPN: Số tiền không khớp! Đơn: {Expected}, Nhận: {Actual}",
                    order.TotalAmount, result.Amount);
                return Json(new VNPayIpnResponse { RspCode = "04", Message = "Invalid amount" });
            }

            // 4. Chống xử lý giao dịch trùng (Idempotency Check)
            var payment = order.Payments.FirstOrDefault(p => p.PaymentMethod == "VNPAY") 
                          ?? order.Payments.FirstOrDefault();

            if (order.PaymentStatus == "Đã thanh toán" || (payment != null && payment.Status == "PAID"))
            {
                _logger.LogInformation("VNPay IPN: Đơn hàng {OrderCode} đã được xác nhận thanh toán trước đó (Idempotent).", order.OrderCode);
                return Json(new VNPayIpnResponse { RspCode = "02", Message = "Order already confirmed" });
            }

            // 5. Cập nhật kết quả thanh toán
            if (result.IsSuccess)
            {
                await ProcessPaymentSuccessAsync(order, "VNPAY", result.TransactionId, result.BankCode);
                return Json(new VNPayIpnResponse { RspCode = "00", Message = "Confirm Success" });
            }
            else
            {
                await ProcessPaymentFailureAsync(order, "VNPAY", result.TransactionId, result.Message);
                return Json(new VNPayIpnResponse { RspCode = "00", Message = "Confirm Success" });
            }
        }

        // ====================================================================
        // MOMO CALLBACK & IPN
        // ====================================================================

        // GET: /Payment/MoMoCallback (Người dùng được chuyển hướng về trình duyệt)
        [HttpGet]
        public async Task<IActionResult> MoMoCallback()
        {
            _logger.LogInformation("Nhận MoMo Callback: {QueryString}", Request.QueryString.Value);

            var result = _moMoService.ProcessCallback(Request.Query);

            if (string.IsNullOrWhiteSpace(result.OrderCode))
            {
                return RedirectToAction(nameof(PaymentFailed), new { message = "Không xác định được mã đơn hàng từ MoMo!" });
            }

            var order = await _context.Orders
                .Include(o => o.Payments)
                .FirstOrDefaultAsync(o => o.OrderCode == result.OrderCode);

            if (order == null)
            {
                return RedirectToAction(nameof(PaymentFailed), new { message = $"Không tìm thấy đơn hàng {result.OrderCode}!" });
            }

            if (!result.IsSuccess)
            {
                await ProcessPaymentFailureAsync(order, "MOMO", result.TransactionId, result.Message);
                return RedirectToAction(nameof(PaymentFailed), new { orderId = order.OrderId, message = result.Message });
            }

            // Xử lý thành công chống trùng lặp
            await ProcessPaymentSuccessAsync(order, "MOMO", result.TransactionId, "Ví MoMo");

            TempData["SuccessMessage"] = "Thanh toán qua Ví MoMo thành công!";
            return RedirectToAction("OrderSuccess", "Cart", new { id = order.OrderId });
        }

        // POST: /Payment/MoMoIpn (Webhook server-to-server từ MoMo)
        [HttpPost]
        public async Task<IActionResult> MoMoIpn([FromBody] MoMoIpnRequest request)
        {
            _logger.LogInformation("Nhận MoMo IPN webhook cho đơn hàng {OrderId}, mã GD: {TransId}",
                request.OrderId, request.TransId);

            var result = _moMoService.ProcessIpn(request);

            // 1. Kiểm tra chữ ký bảo mật
            if (!result.IsSuccess && result.Message.Contains("Chữ ký", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("MoMo IPN: Chữ ký không hợp lệ!");
                return BadRequest(new MoMoIpnResponse { ResultCode = 97, Message = "Invalid signature" });
            }

            // 2. Tìm đơn hàng
            if (string.IsNullOrWhiteSpace(result.OrderCode))
            {
                return NotFound(new MoMoIpnResponse { ResultCode = 1, Message = "Order not found" });
            }

            var order = await _context.Orders
                .Include(o => o.Payments)
                .FirstOrDefaultAsync(o => o.OrderCode == result.OrderCode);

            if (order == null)
            {
                _logger.LogWarning("MoMo IPN: Không tìm thấy đơn hàng {OrderCode}", result.OrderCode);
                return NotFound(new MoMoIpnResponse { ResultCode = 1, Message = "Order not found" });
            }

            // 3. Kiểm tra số tiền
            if (result.Amount > 0 && Math.Abs(order.TotalAmount - result.Amount) > 1.0m)
            {
                _logger.LogWarning("MoMo IPN: Số tiền không khớp! Đơn: {Expected}, Nhận: {Actual}",
                    order.TotalAmount, result.Amount);
                return BadRequest(new MoMoIpnResponse { ResultCode = 4, Message = "Invalid amount" });
            }

            // 4. Chống xử lý giao dịch trùng (Idempotency Check)
            var payment = order.Payments.FirstOrDefault(p => p.PaymentMethod == "MOMO") 
                          ?? order.Payments.FirstOrDefault();

            if (order.PaymentStatus == "Đã thanh toán" || (payment != null && payment.Status == "PAID"))
            {
                _logger.LogInformation("MoMo IPN: Đơn hàng {OrderCode} đã thanh toán trước đó (Idempotent).", order.OrderCode);
                return Ok(new MoMoIpnResponse { ResultCode = 0, Message = "Order already confirmed" });
            }

            // 5. Cập nhật kết quả thanh toán
            if (result.IsSuccess)
            {
                await ProcessPaymentSuccessAsync(order, "MOMO", result.TransactionId, "Ví MoMo");
                return Ok(new MoMoIpnResponse { ResultCode = 0, Message = "Confirm Success" });
            }
            else
            {
                await ProcessPaymentFailureAsync(order, "MOMO", result.TransactionId, result.Message);
                return Ok(new MoMoIpnResponse { ResultCode = 0, Message = "Acknowledged" });
            }
        }

        // ====================================================================
        // THỬ LẠI HOẶC THAY ĐỔI PHƯƠNG THỨC THANH TOÁN
        // ====================================================================

        // POST: /Payment/RetryPayment
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RetryPayment(int orderId, string paymentMethod)
        {
            var order = await _context.Orders
                .Include(o => o.Payments)
                .FirstOrDefaultAsync(o => o.OrderId == orderId);

            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy đơn hàng!";
                return RedirectToAction("Index", "Home");
            }

            if (order.PaymentStatus == "Đã thanh toán")
            {
                TempData["SuccessMessage"] = "Đơn hàng này đã được thanh toán thành công!";
                return RedirectToAction("OrderSuccess", "Cart", new { id = order.OrderId });
            }

            order.PaymentMethod = paymentMethod;
            order.UpdatedAt = DateTime.Now;

            // Tìm hoặc tạo mới bản ghi Payment
            var payment = order.Payments.OrderByDescending(p => p.CreatedAt).FirstOrDefault();
            if (payment == null || payment.Status == "PAID")
            {
                payment = new Models.Payment
                {
                    OrderId = order.OrderId,
                    PaymentMethod = paymentMethod,
                    Amount = order.TotalAmount,
                    Status = "PENDING",
                    IdempotencyKey = $"PAY-{order.OrderCode}-{Guid.NewGuid():N}",
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };
                _context.Payments.Add(payment);
            }
            else
            {
                payment.PaymentMethod = paymentMethod;
                payment.Status = "PENDING";
                payment.UpdatedAt = DateTime.Now;
            }

            await _context.SaveChangesAsync();

            if (paymentMethod == "COD")
            {
                order.PaymentStatus = "Chưa thanh toán";
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Đã chuyển phương thức thanh toán sang nhận hàng trả tiền (COD).";
                return RedirectToAction("OrderSuccess", "Cart", new { id = order.OrderId });
            }
            else if (paymentMethod == "VNPAY")
            {
                var payUrl = _vnPayService.CreatePaymentUrl(order, payment, HttpContext);
                return Redirect(payUrl);
            }
            else if (paymentMethod == "MOMO")
            {
                var momoRes = await _moMoService.CreatePaymentAsync(order, payment, HttpContext);
                if (momoRes.Success && !string.IsNullOrEmpty(momoRes.PayUrl))
                {
                    return Redirect(momoRes.PayUrl);
                }
                TempData["ErrorMessage"] = $"Không thể mở cổng MoMo: {momoRes.Message}";
                return RedirectToAction(nameof(PaymentFailed), new { orderId = order.OrderId, message = momoRes.Message });
            }

            return RedirectToAction("OrderSuccess", "Cart", new { id = order.OrderId });
        }

        // GET: /Payment/PaymentFailed
        [HttpGet]
        public async Task<IActionResult> PaymentFailed(int? orderId, string? message)
        {
            ViewBag.ErrorMessage = message ?? "Giao dịch không thành công hoặc bị gián đoạn.";

            if (orderId.HasValue)
            {
                var order = await _context.Orders
                    .Include(o => o.OrderDetails)
                    .Include(o => o.Payments)
                    .FirstOrDefaultAsync(o => o.OrderId == orderId.Value);

                if (order != null)
                {
                    return View(order);
                }
            }

            return View(null as Order);
        }

        // ====================================================================
        // PRIVATE IDEMPOTENT TRANSACTION HELPERS
        // ====================================================================

        private async Task ProcessPaymentSuccessAsync(Order order, string method, string transactionId, string? bankCode)
        {
            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var payment = order.Payments.OrderByDescending(p => p.CreatedAt).FirstOrDefault();
                if (payment == null)
                {
                    payment = new Models.Payment
                    {
                        OrderId = order.OrderId,
                        PaymentMethod = method,
                        Amount = order.TotalAmount,
                        Status = "PAID",
                        GatewayTransactionId = transactionId,
                        IdempotencyKey = $"PAY-{order.OrderCode}-{Guid.NewGuid():N}",
                        PaidAt = DateTime.Now,
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    };
                    _context.Payments.Add(payment);
                }
                else
                {
                    payment.Status = "PAID";
                    payment.PaymentMethod = method;
                    payment.GatewayTransactionId = transactionId;
                    payment.PaidAt = DateTime.Now;
                    payment.UpdatedAt = DateTime.Now;
                }

                order.PaymentMethod = method;
                order.PaymentStatus = "Đã thanh toán";
                order.OrderStatus = "Đã xác nhận";
                order.UpdatedAt = DateTime.Now;

                // Cập nhật tồn kho: Chuyển InventoryReservation sang CONSUMED, trừ StockQuantity và ghi sổ InventoryTransaction
                var reservations = await _context.InventoryReservations
                    .Where(r => r.OrderId == order.OrderId && r.Status == "ACTIVE")
                    .ToListAsync();

                foreach (var res in reservations)
                {
                    res.Status = "CONSUMED";

                    var variant = await _context.ProductVariants.FindAsync(res.VariantId);
                    if (variant != null)
                    {
                        variant.StockQuantity = Math.Max(0, variant.StockQuantity - res.Quantity);
                        variant.UpdatedAt = DateTime.Now;
                    }

                    var invTxKey = $"INV-SALE-{order.OrderCode}-{res.VariantId}";
                    var existsInvTx = await _context.InventoryTransactions.AnyAsync(it => it.IdempotencyKey == invTxKey);
                    if (!existsInvTx)
                    {
                        var invTx = new InventoryTransaction
                        {
                            VariantId = res.VariantId,
                            QuantityDelta = -res.Quantity,
                            TransactionType = "SALE_OUT",
                            SourceType = "ORDER_DETAIL",
                            SourceId = order.OrderId,
                            IdempotencyKey = invTxKey,
                            CreatedByUserId = order.UserId,
                            CreatedAt = DateTime.Now,
                            Note = $"Xuất kho hoàn tất thanh toán trực tuyến qua {method} cho đơn hàng {order.OrderCode}"
                        };
                        _context.InventoryTransactions.Add(invTx);
                    }
                }

                // Cập nhật trạng thái voucher CouponUsage sang USED
                var couponUsage = await _context.CouponUsages
                    .FirstOrDefaultAsync(cu => cu.OrderId == order.OrderId && cu.Status == "RESERVED");
                if (couponUsage != null)
                {
                    couponUsage.Status = "USED";
                    couponUsage.UsedAt = DateTime.Now;
                }

                var history = new OrderStatusHistory
                {
                    OrderId = order.OrderId,
                    FromStatus = "Chờ xác nhận",
                    ToStatus = "Đã xác nhận",
                    ChangedByUserId = order.UserId,
                    ChangedAt = DateTime.Now,
                    Note = $"Đã thanh toán online thành công qua {method} (Mã GD: {transactionId}, Ngân hàng/Ví: {bankCode ?? "N/A"})"
                };
                _context.OrderStatusHistories.Add(history);

                await _context.SaveChangesAsync();
                await tx.CommitAsync();

                _logger.LogInformation("Đã cập nhật trạng thái PAID cho đơn hàng {OrderCode} qua {Method}", order.OrderCode, method);
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                _logger.LogError(ex, "Lỗi cập nhật trạng thái thanh toán thành công cho đơn {OrderCode}", order.OrderCode);
                throw;
            }
        }

        private async Task ProcessPaymentFailureAsync(Order order, string method, string? transactionId, string? reason)
        {
            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var payment = order.Payments.OrderByDescending(p => p.CreatedAt).FirstOrDefault();
                if (payment != null && payment.Status != "PAID")
                {
                    payment.Status = "FAILED";
                    payment.GatewayTransactionId = transactionId;
                    payment.UpdatedAt = DateTime.Now;
                }

                if (order.PaymentStatus != "Đã thanh toán")
                {
                    order.PaymentStatus = "Thanh toán thất bại";
                    order.UpdatedAt = DateTime.Now;

                    var history = new OrderStatusHistory
                    {
                        OrderId = order.OrderId,
                        FromStatus = order.OrderStatus,
                        ToStatus = order.OrderStatus,
                        ChangedByUserId = order.UserId,
                        ChangedAt = DateTime.Now,
                        Note = $"Giao dịch qua {method} không thành công: {reason}"
                    };
                    _context.OrderStatusHistories.Add(history);
                }

                await _context.SaveChangesAsync();
                await tx.CommitAsync();
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                _logger.LogError(ex, "Lỗi cập nhật trạng thái thanh toán thất bại cho đơn {OrderCode}", order.OrderCode);
            }
        }
    }
}
