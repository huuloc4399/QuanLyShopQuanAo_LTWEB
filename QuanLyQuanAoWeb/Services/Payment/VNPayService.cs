using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Services.Payment
{
    public class VNPayService : IVNPayService
    {
        private readonly VNPaySettings _settings;
        private readonly ILogger<VNPayService> _logger;

        public VNPayService(IOptions<VNPaySettings> settings, ILogger<VNPayService> logger)
        {
            _settings = settings.Value;
            _logger = logger;
        }

        public string CreatePaymentUrl(Order order, Models.Payment payment, HttpContext httpContext)
        {
            var tmnCode = _settings.GetEffectiveTmnCode();
            var hashSecret = _settings.GetEffectiveHashSecret();

            if (string.IsNullOrWhiteSpace(tmnCode) || string.IsNullOrWhiteSpace(hashSecret))
            {
                _logger.LogWarning("VNPay TmnCode hoặc HashSecret chưa được cấu hình. Đang dùng giá trị mặc định Sandbox.");
            }

            var returnUrl = BuildAbsoluteUrl(_settings.ReturnUrl, httpContext);
            var ipAddr = GetIpAddress(httpContext);
            var createDate = DateTime.Now.ToString("yyyyMMddHHmmss");
            var amountVal = Convert.ToInt64(Math.Round(order.TotalAmount * 100, 0));

            var payParams = new SortedDictionary<string, string>(StringComparer.Ordinal)
            {
                { "vnp_Version", _settings.Version },
                { "vnp_Command", _settings.Command },
                { "vnp_TmnCode", tmnCode },
                { "vnp_Amount", amountVal.ToString() },
                { "vnp_CreateDate", createDate },
                { "vnp_CurrCode", _settings.CurrCode },
                { "vnp_IpAddr", ipAddr },
                { "vnp_Locale", _settings.Locale },
                { "vnp_OrderInfo", $"Thanh toan don hang {order.OrderCode}" },
                { "vnp_OrderType", "other" },
                { "vnp_ReturnUrl", returnUrl },
                { "vnp_TxnRef", order.OrderCode }
            };

            var dataBuilder = new StringBuilder();
            var queryBuilder = new StringBuilder();

            foreach (var kv in payParams)
            {
                if (!string.IsNullOrEmpty(kv.Value))
                {
                    if (dataBuilder.Length > 0)
                    {
                        dataBuilder.Append('&');
                        queryBuilder.Append('&');
                    }

                    var key = WebUtility.UrlEncode(kv.Key);
                    var val = WebUtility.UrlEncode(kv.Value);

                    dataBuilder.Append($"{key}={val}");
                    queryBuilder.Append($"{key}={val}");
                }
            }

            var secureHash = HmacSha512(hashSecret, dataBuilder.ToString());
            var paymentUrl = $"{_settings.BaseUrl}?{queryBuilder}&vnp_SecureHash={secureHash}";

            _logger.LogInformation("Đã tạo VNPay URL cho đơn hàng {OrderCode}, số tiền {Amount}", order.OrderCode, order.TotalAmount);
            return paymentUrl;
        }

        public PaymentCallbackResult ProcessCallback(IQueryCollection query)
        {
            return ValidateResponse(query, isIpn: false);
        }

        public PaymentCallbackResult ProcessIpn(IQueryCollection query)
        {
            return ValidateResponse(query, isIpn: true);
        }

        private PaymentCallbackResult ValidateResponse(IQueryCollection query, bool isIpn)
        {
            var hashSecret = _settings.GetEffectiveHashSecret();
            var result = new PaymentCallbackResult
            {
                PaymentMethod = "VNPAY"
            };

            string secureHash = string.Empty;
            var sortedParams = new SortedDictionary<string, string>(StringComparer.Ordinal);

            foreach (var key in query.Keys)
            {
                if (string.IsNullOrEmpty(key)) continue;

                var value = query[key].ToString();
                if (key.Equals("vnp_SecureHash", StringComparison.OrdinalIgnoreCase))
                {
                    secureHash = value;
                }
                else if (key.StartsWith("vnp_", StringComparison.OrdinalIgnoreCase) &&
                         !key.Equals("vnp_SecureHashType", StringComparison.OrdinalIgnoreCase))
                {
                    sortedParams[key] = value;
                }
            }

            var orderCode = query["vnp_TxnRef"].ToString();
            var responseCode = query["vnp_ResponseCode"].ToString();
            var transactionNo = query["vnp_TransactionNo"].ToString();
            var bankCode = query["vnp_BankCode"].ToString();
            var payDateStr = query["vnp_PayDate"].ToString();
            var amountStr = query["vnp_Amount"].ToString();

            result.OrderCode = orderCode;
            result.ResponseCode = responseCode;
            result.TransactionId = transactionNo;
            result.BankCode = bankCode;

            if (long.TryParse(amountStr, out var rawAmount))
            {
                result.Amount = rawAmount / 100m;
            }

            if (DateTime.TryParseExact(payDateStr, "yyyyMMddHHmmss", CultureInfo.InvariantCulture, DateTimeStyles.None, out var payDate))
            {
                result.PayDate = payDate;
            }

            // Xây dựng chuỗi raw hash để kiểm tra chữ ký
            var rawDataBuilder = new StringBuilder();
            foreach (var kv in sortedParams)
            {
                if (!string.IsNullOrEmpty(kv.Value))
                {
                    if (rawDataBuilder.Length > 0)
                        rawDataBuilder.Append('&');

                    rawDataBuilder.Append($"{WebUtility.UrlEncode(kv.Key)}={WebUtility.UrlEncode(kv.Value)}");
                }
            }

            var calculatedHash = HmacSha512(hashSecret, rawDataBuilder.ToString());
            bool isValidSignature = calculatedHash.Equals(secureHash, StringComparison.OrdinalIgnoreCase);

            if (!isValidSignature)
            {
                _logger.LogWarning("Chữ ký VNPay không hợp lệ! OrderCode: {OrderCode}, Received: {Recv}, Calc: {Calc}",
                    orderCode, secureHash, calculatedHash);
                result.IsSuccess = false;
                result.Message = "Chữ ký bảo mật VNPay không hợp lệ (Dữ liệu có thể bị can thiệp)!";
                return result;
            }

            var transactionStatus = query["vnp_TransactionStatus"].ToString();

            if (responseCode == "00" && (string.IsNullOrEmpty(transactionStatus) || transactionStatus == "00"))
            {
                result.IsSuccess = true;
                result.Message = "Thanh toán VNPay thành công.";
            }
            else
            {
                result.IsSuccess = false;
                result.Message = GetVnPayErrorMessage(responseCode);
            }

            return result;
        }

        private static string HmacSha512(string key, string inputData)
        {
            var hash = new StringBuilder();
            byte[] keyBytes = Encoding.UTF8.GetBytes(key);
            byte[] inputBytes = Encoding.UTF8.GetBytes(inputData);
            using (var hmac = new HMACSHA512(keyBytes))
            {
                byte[] hashValue = hmac.ComputeHash(inputBytes);
                foreach (var theByte in hashValue)
                {
                    hash.Append(theByte.ToString("x2"));
                }
            }
            return hash.ToString();
        }

        private static string GetIpAddress(HttpContext context)
        {
            var ip = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
            if (string.IsNullOrWhiteSpace(ip))
            {
                ip = context.Connection.RemoteIpAddress?.ToString();
            }
            if (string.IsNullOrWhiteSpace(ip) || ip == "::1")
            {
                ip = "127.0.0.1";
            }
            return ip.Split(',')[0].Trim();
        }

        private static string BuildAbsoluteUrl(string relativeOrAbsoluteUrl, HttpContext httpContext)
        {
            if (Uri.TryCreate(relativeOrAbsoluteUrl, UriKind.Absolute, out var uri))
            {
                return uri.ToString();
            }

            var scheme = httpContext.Request.Scheme;
            var host = httpContext.Request.Host.Value;
            var pathBase = httpContext.Request.PathBase.Value?.TrimEnd('/') ?? string.Empty;
            var cleanPath = relativeOrAbsoluteUrl.StartsWith('/') ? relativeOrAbsoluteUrl : $"/{relativeOrAbsoluteUrl}";

            return $"{scheme}://{host}{pathBase}{cleanPath}";
        }

        private static string GetVnPayErrorMessage(string responseCode) => responseCode switch
        {
            "00" => "Giao dịch thành công",
            "07" => "Trừ tiền thành công. Giao dịch bị nghi ngờ gian lận",
            "09" => "Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking",
            "10" => "Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần",
            "11" => "Đã hết hạn chờ thanh toán",
            "12" => "Thẻ/Tài khoản của bạn đã bị khóa",
            "13" => "Quý khách nhập sai mật khẩu xác thực OTP",
            "24" => "Giao dịch đã bị khách hàng hủy bỏ",
            "51" => "Tài khoản của quý khách không đủ số dư để thực hiện giao dịch",
            "65" => "Tài khoản đã vượt quá hạn mức giao dịch trong ngày",
            "75" => "Ngân hàng thanh toán đang bảo trì",
            "79" => "Nhập sai mật khẩu thanh toán quá số lần quy định",
            _ => $"Lỗi thanh toán VNPay (Mã phản hồi: {responseCode})"
        };
    }
}
