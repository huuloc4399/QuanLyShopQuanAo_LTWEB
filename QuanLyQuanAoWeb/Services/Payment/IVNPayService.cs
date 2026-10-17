using Microsoft.AspNetCore.Http;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Services.Payment
{
    public interface IVNPayService
    {
        string CreatePaymentUrl(Order order, Models.Payment payment, HttpContext httpContext);
        PaymentCallbackResult ProcessCallback(IQueryCollection query);
        PaymentCallbackResult ProcessIpn(IQueryCollection query);
    }
}
