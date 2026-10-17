using System.Text.Json.Serialization;

namespace QuanLyQuanAoWeb.Services.Payment
{
    public class PaymentCallbackResult
    {
        public bool IsSuccess { get; set; }
        public int OrderId { get; set; }
        public string OrderCode { get; set; } = string.Empty;
        public string PaymentMethod { get; set; } = string.Empty;
        public string TransactionId { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string ResponseCode { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string? BankCode { get; set; }
        public DateTime? PayDate { get; set; }
    }

    public class VNPayIpnResponse
    {
        [JsonPropertyName("RspCode")]
        public string RspCode { get; set; } = "99";

        [JsonPropertyName("Message")]
        public string Message { get; set; } = "Unknown Error";
    }

    public class MoMoCreatePaymentResponse
    {
        [JsonPropertyName("partnerCode")]
        public string? PartnerCode { get; set; }

        [JsonPropertyName("orderId")]
        public string? OrderId { get; set; }

        [JsonPropertyName("requestId")]
        public string? RequestId { get; set; }

        [JsonPropertyName("amount")]
        public long Amount { get; set; }

        [JsonPropertyName("responseTime")]
        public long ResponseTime { get; set; }

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        [JsonPropertyName("resultCode")]
        public int ResultCode { get; set; }

        [JsonPropertyName("payUrl")]
        public string? PayUrl { get; set; }

        [JsonPropertyName("deeplink")]
        public string? Deeplink { get; set; }

        [JsonPropertyName("qrCodeUrl")]
        public string? QrCodeUrl { get; set; }
    }

    public class MoMoIpnRequest
    {
        [JsonPropertyName("partnerCode")]
        public string? PartnerCode { get; set; }

        [JsonPropertyName("orderId")]
        public string? OrderId { get; set; }

        [JsonPropertyName("requestId")]
        public string? RequestId { get; set; }

        [JsonPropertyName("amount")]
        public long Amount { get; set; }

        [JsonPropertyName("orderInfo")]
        public string? OrderInfo { get; set; }

        [JsonPropertyName("orderType")]
        public string? OrderType { get; set; }

        [JsonPropertyName("transId")]
        public long TransId { get; set; }

        [JsonPropertyName("resultCode")]
        public int ResultCode { get; set; }

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        [JsonPropertyName("payType")]
        public string? PayType { get; set; }

        [JsonPropertyName("responseTime")]
        public long ResponseTime { get; set; }

        [JsonPropertyName("extraData")]
        public string? ExtraData { get; set; }

        [JsonPropertyName("signature")]
        public string? Signature { get; set; }
    }

    public class MoMoIpnResponse
    {
        [JsonPropertyName("resultCode")]
        public int ResultCode { get; set; }

        [JsonPropertyName("message")]
        public string Message { get; set; } = string.Empty;
    }
}
