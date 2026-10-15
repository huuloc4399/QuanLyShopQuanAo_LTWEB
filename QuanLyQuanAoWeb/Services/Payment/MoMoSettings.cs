namespace QuanLyQuanAoWeb.Services.Payment
{
    public class MoMoSettings
    {
        public const string SectionName = "MoMo";

        public string PartnerCode { get; set; } = string.Empty;
        public string AccessKey { get; set; } = string.Empty;
        public string SecretKey { get; set; } = string.Empty;
        public string PaymentUrl { get; set; } = "https://test-payment.momo.vn/v2/gateway/api/create";
        public string ReturnUrl { get; set; } = "/Payment/MoMoCallback";
        public string IpnUrl { get; set; } = "/Payment/MoMoIpn";
        public string PartnerName { get; set; } = "Shop Dong Phuc HUIT";
        public string StoreId { get; set; } = "MomoStore";
        public string RequestType { get; set; } = "captureWallet";

        /// <summary>
        /// Bảo vệ khóa bí mật: Ưu tiên lấy từ biến môi trường hệ thống (Environment Variable),
        /// nếu không có mới lấy từ appsettings.json
        /// </summary>
        public string GetEffectiveSecretKey()
        {
            var envSecret = Environment.GetEnvironmentVariable("MOMO_SECRET_KEY");
            return !string.IsNullOrWhiteSpace(envSecret) ? envSecret.Trim() : (SecretKey ?? string.Empty).Trim();
        }

        public string GetEffectiveAccessKey()
        {
            var envKey = Environment.GetEnvironmentVariable("MOMO_ACCESS_KEY");
            return !string.IsNullOrWhiteSpace(envKey) ? envKey.Trim() : (AccessKey ?? string.Empty).Trim();
        }

        public string GetEffectivePartnerCode()
        {
            var envPartner = Environment.GetEnvironmentVariable("MOMO_PARTNER_CODE");
            return !string.IsNullOrWhiteSpace(envPartner) ? envPartner.Trim() : (PartnerCode ?? string.Empty).Trim();
        }
    }
}
