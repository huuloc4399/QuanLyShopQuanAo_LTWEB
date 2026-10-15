namespace QuanLyQuanAoWeb.Services.Payment
{
    public class VNPaySettings
    {
        public const string SectionName = "VNPay";

        public string TmnCode { get; set; } = string.Empty;
        public string HashSecret { get; set; } = string.Empty;
        public string BaseUrl { get; set; } = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
        public string Version { get; set; } = "2.1.0";
        public string Command { get; set; } = "pay";
        public string CurrCode { get; set; } = "VND";
        public string Locale { get; set; } = "vn";
        public string ReturnUrl { get; set; } = "/Payment/VNPayCallback";
        public string IpnUrl { get; set; } = "/Payment/VNPayIpn";

        /// <summary>
        /// Bảo vệ khóa bí mật: Ưu tiên đọc từ biến môi trường hệ thống (Environment Variable),
        /// nếu không có mới lấy từ appsettings.json
        /// </summary>
        public string GetEffectiveHashSecret()
        {
            var envSecret = Environment.GetEnvironmentVariable("VNPAY_HASH_SECRET");
            return !string.IsNullOrWhiteSpace(envSecret) ? envSecret.Trim() : (HashSecret ?? string.Empty).Trim();
        }

        public string GetEffectiveTmnCode()
        {
            var envCode = Environment.GetEnvironmentVariable("VNPAY_TMN_CODE");
            return !string.IsNullOrWhiteSpace(envCode) ? envCode.Trim() : (TmnCode ?? string.Empty).Trim();
        }
    }
}
