using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Services.Payment
{
    public class MoMoService : IMoMoService
    {
        private readonly MoMoSettings _settings;
        private readonly HttpClient _httpClient;
        private readonly ILogger<MoMoService> _logger;

        public MoMoService(IOptions<MoMoSettings> settings, HttpClient httpClient, ILogger<MoMoService> logger)
        {
            _settings = settings.Value;
            _httpClient = httpClient;
            _logger = logger;
        }

        public async Task<(bool Success, string? PayUrl, string? Message)> CreatePaymentAsync(Order order, Models.Payment payment, HttpContext httpContext)
        {
            try
            {
                var partnerCode = _settings.GetEffectivePartnerCode();
                var accessKey = _settings.GetEffectiveAccessKey();
                var secretKey = _settings.GetEffectiveSecretKey();

                if (string.IsNullOrWhiteSpace(partnerCode) || string.IsNullOrWhiteSpace(secretKey) || string.IsNullOrWhiteSpace(accessKey))
                {
                    _logger.LogWarning("MoMo PartnerCode, AccessKey hoặc SecretKey chưa được cấu hình đầy đủ.");
                }

                var redirectUrl = BuildAbsoluteUrl(_settings.ReturnUrl, httpContext);
                var ipnUrl = BuildAbsoluteUrl(_settings.IpnUrl, httpContext);
                var requestId = Guid.NewGuid().ToString();
                var orderId = order.OrderCode;
                var orderInfo = $"Thanh toan don hang {order.OrderCode}";
                var amount = Convert.ToInt64(Math.Round(order.TotalAmount, 0));
                var extraData = string.Empty;
                var requestType = _settings.RequestType;

                // Chuỗi raw hash theo chuẩn MoMo v2 Create Payment
                var rawHash = $"accessKey={accessKey}&amount={amount}&extraData={extraData}&ipnUrl={ipnUrl}&orderId={orderId}&orderInfo={orderInfo}&partnerCode={partnerCode}&redirectUrl={redirectUrl}&requestId={requestId}&requestType={requestType}";

                var signature = HmacSha256(secretKey, rawHash);

                var requestBody = new
                {
                    partnerCode,
                    partnerName = _settings.PartnerName,
                    storeId = _settings.StoreId,
                    requestId,
                    amount,
                    orderId,
                    orderInfo,
                    redirectUrl,
                    ipnUrl,
                    lang = "vi",
                    extraData,
                    requestType,
                    signature
                };

                var jsonContent = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

                _logger.LogInformation("Gửi yêu cầu tạo thanh toán MoMo cho đơn hàng {OrderCode}, số tiền: {Amount}", orderId, amount);

                var response = await _httpClient.PostAsync(_settings.PaymentUrl, jsonContent);
                var responseContent = await response.Content.ReadAsStringAsync();

                _logger.LogInformation("Nhận phản hồi từ MoMo API: {Response}", responseContent);

                if (string.IsNullOrWhiteSpace(responseContent))
                {
                    return (false, null, "Không nhận được phản hồi từ cổng MoMo");
                }

                var momoResponse = JsonSerializer.Deserialize<MoMoCreatePaymentResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (momoResponse != null && momoResponse.ResultCode == 0 && !string.IsNullOrEmpty(momoResponse.PayUrl))
                {
                    return (true, momoResponse.PayUrl, "Khởi tạo thanh toán MoMo thành công");
                }

                var errorMsg = momoResponse?.Message ?? $"Lỗi mã {momoResponse?.ResultCode} từ MoMo";
                return (false, null, errorMsg);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi kết nối hoặc xử lý yêu cầu MoMo: {Message}", ex.Message);
                return (false, null, $"Lỗi kết nối cổng thanh toán MoMo: {ex.Message}");
            }
        }

        public PaymentCallbackResult ProcessCallback(IQueryCollection query)
        {
            var accessKey = _settings.GetEffectiveAccessKey();
            var secretKey = _settings.GetEffectiveSecretKey();

            var partnerCode = query["partnerCode"].ToString();
            var orderId = query["orderId"].ToString();
            var requestId = query["requestId"].ToString();
            var amountStr = query["amount"].ToString();
            var orderInfo = query["orderInfo"].ToString();
            var orderType = query["orderType"].ToString();
            var transId = query["transId"].ToString();
            var resultCodeStr = query["resultCode"].ToString();
            var message = query["message"].ToString();
            var payType = query["payType"].ToString();
            var responseTime = query["responseTime"].ToString();
            var extraData = query["extraData"].ToString();
            var signature = query["signature"].ToString();

            var result = new PaymentCallbackResult
            {
                PaymentMethod = "MOMO",
                OrderCode = orderId,
                TransactionId = transId,
                ResponseCode = resultCodeStr,
                Message = message
            };

            if (long.TryParse(amountStr, out var rawAmount))
            {
                result.Amount = rawAmount;
            }

            // Chuỗi raw hash theo chuẩn MoMo v2 Callback / IPN
            var rawHash = $"accessKey={accessKey}&amount={amountStr}&extraData={extraData}&message={message}&orderId={orderId}&orderInfo={orderInfo}&orderType={orderType}&partnerCode={partnerCode}&payType={payType}&requestId={requestId}&responseTime={responseTime}&resultCode={resultCodeStr}&transId={transId}";

            var calculatedSignature = HmacSha256(secretKey, rawHash);
            bool isValidSignature = calculatedSignature.Equals(signature, StringComparison.OrdinalIgnoreCase);

            if (!isValidSignature)
            {
                _logger.LogWarning("Chữ ký MoMo Callback không hợp lệ! OrderId: {OrderId}, Recv: {Recv}, Calc: {Calc}",
                    orderId, signature, calculatedSignature);
                result.IsSuccess = false;
                result.Message = "Chữ ký bảo mật MoMo không hợp lệ (Dữ liệu có thể bị can thiệp)!";
                return result;
            }

            if (int.TryParse(resultCodeStr, out var code) && code == 0)
            {
                result.IsSuccess = true;
                result.Message = "Thanh toán MoMo thành công.";
            }
            else
            {
                result.IsSuccess = false;
                result.Message = string.IsNullOrWhiteSpace(message) ? $"Thanh toán MoMo thất bại (Mã: {resultCodeStr})" : message;
            }

            return result;
        }

        public PaymentCallbackResult ProcessIpn(MoMoIpnRequest request)
        {
            var accessKey = _settings.GetEffectiveAccessKey();
            var secretKey = _settings.GetEffectiveSecretKey();

            var result = new PaymentCallbackResult
            {
                PaymentMethod = "MOMO",
                OrderCode = request.OrderId ?? string.Empty,
                TransactionId = request.TransId.ToString(),
                Amount = request.Amount,
                ResponseCode = request.ResultCode.ToString(),
                Message = request.Message ?? string.Empty
            };

            var rawHash = $"accessKey={accessKey}&amount={request.Amount}&extraData={request.ExtraData ?? string.Empty}&message={request.Message ?? string.Empty}&orderId={request.OrderId ?? string.Empty}&orderInfo={request.OrderInfo ?? string.Empty}&orderType={request.OrderType ?? string.Empty}&partnerCode={request.PartnerCode ?? string.Empty}&payType={request.PayType ?? string.Empty}&requestId={request.RequestId ?? string.Empty}&responseTime={request.ResponseTime}&resultCode={request.ResultCode}&transId={request.TransId}";

            var calculatedSignature = HmacSha256(secretKey, rawHash);
            bool isValidSignature = calculatedSignature.Equals(request.Signature, StringComparison.OrdinalIgnoreCase);

            if (!isValidSignature)
            {
                _logger.LogWarning("Chữ ký MoMo IPN không hợp lệ! OrderId: {OrderId}, Recv: {Recv}, Calc: {Calc}",
                    request.OrderId, request.Signature, calculatedSignature);
                result.IsSuccess = false;
                result.Message = "Chữ ký bảo mật MoMo IPN không hợp lệ!";
                return result;
            }

            if (request.ResultCode == 0)
            {
                result.IsSuccess = true;
                result.Message = "Thanh toán MoMo thành công.";
            }
            else
            {
                result.IsSuccess = false;
                result.Message = request.Message ?? $"Thanh toán MoMo không thành công (Mã: {request.ResultCode})";
            }

            return result;
        }

        private static string HmacSha256(string key, string inputData)
        {
            byte[] keyByte = Encoding.UTF8.GetBytes(key);
            byte[] messageBytes = Encoding.UTF8.GetBytes(inputData);
            using var hmacsha256 = new HMACSHA256(keyByte);
            byte[] hashmessage = hmacsha256.ComputeHash(messageBytes);
            return Convert.ToHexString(hashmessage).ToLowerInvariant();
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
    }
}
