using Microsoft.AspNetCore.Http;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Services.Payment
{
    public interface IMoMoService
    {
        Task<(bool Success, string? PayUrl, string? Message)> CreatePaymentAsync(Order order, Models.Payment payment, HttpContext httpContext);
        PaymentCallbackResult ProcessCallback(IQueryCollection query);
        PaymentCallbackResult ProcessIpn(MoMoIpnRequest request);
    }
}
