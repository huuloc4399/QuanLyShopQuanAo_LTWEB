# HƯỚNG DẪN DÀNH CHO CÁC THÀNH VIÊN GHÉP CODE (NHÓM 4)
*Dự án: Website Quản lý & Kinh doanh Quần áo (ASP.NET Core MVC .NET 8)*  
*Biên soạn: Người 1 (Database & Backend Nền)*

---

Chào các bạn, phần code nền tảng (Database SQL Server, Entity Models, kết nối DbContext, xác thực Đăng nhập/Đăng ký/Phân quyền, Giỏ hàng và các Layout khung) đã được hoàn thiện và chạy ổn định.

Giao diện hiện tại trong code là **giao diện mẫu (Template)** để các bạn hình dung luồng dữ liệu. Dưới đây là hướng dẫn cụ thể để mỗi bạn dễ dàng thay thế giao diện Figma hoặc cắm tính năng của mình vào mà **không sợ làm hỏng code của nhau**.

---

## 1. Dành cho Người 2 (Figma & Frontend)

Bạn không cần biết nhiều về C# Backend. Giao diện của bạn làm việc chủ yếu ở 2 phần:

### A. Nếu muốn đổi màu sắc, font chữ, style giao diện theo Figma:
- Bạn chỉ cần vào thư mục: `QuanLyQuanAoWeb/wwwroot/css/`
- Mở file `site.css` hoặc tạo file mới `custom.css` (sau đó link vào `_Layout.cshtml`).
- Viết CSS đè lên theo đúng màu sắc và style của bản Figma.

### B. Nếu muốn thay đổi bố cục Header, Footer, Navbar:
- Mở file `Views/Shared/_Layout.cshtml` (dành cho khách hàng) hoặc `Areas/Admin/Views/Shared/_AdminLayout.cshtml` (dành cho trang quản trị).
- Bạn có thể thoải mái sửa HTML của Navbar, Header, Banner, Footer theo Figma.
- **LƯU Ý DUY NHẤT:** Giữ lại dòng `@RenderBody()` ở giữa trang. Dòng này là nơi nội dung các trang con được nhúng vào.

### C. Nếu muốn thay đổi giao diện Trang chủ hoặc Chi tiết sản phẩm:
- Mở file `Views/Home/Index.cshtml` (Trang chủ) hoặc `Views/Home/Details.cshtml` (Chi tiết SP).
- Bạn có thể thay đổi toàn bộ mã HTML thẻ `<div>`, `class`, `card` theo Figma.
- Chỉ cần giữ lại các vị trí in dữ liệu Razor:
  - `@Model.ProductName` (In tên sản phẩm)
  - `@Model.FinalPrice.ToString("N0") đ` (In giá tiền)
  - Vòng lặp: `@foreach (var item in Model.AllProducts) { ... }`

---

## 2. Dành cho Người 3 (Khách hàng & Đơn hàng)

Bạn phụ trách 2 module: **Quản lý Đơn hàng** và **Quản lý Khách hàng**.

### A. Bạn tạo các file mới hoàn toàn (Không đụng vào file cũ):
1. **Controllers:**
   - Tạo `Controllers/OrdersController.cs` (Xem danh sách đơn, chi tiết đơn, cập nhật trạng thái đơn).
   - Tạo `Controllers/CustomersController.cs` (Xem danh sách khách hàng, khóa/mở tài khoản).
2. **Views:**
   - Tạo thư mục `Views/Orders/` $\rightarrow$ Thêm `Index.cshtml` (Danh sách đơn), `Details.cshtml` (Chi tiết đơn).
   - Tạo thư mục `Views/Customers/` $\rightarrow$ Thêm `Index.cshtml`.

### B. Cách bạn lấy dữ liệu từ Backend có sẵn của Người 1:
Trong Controller của bạn, bạn chỉ cần gọi `ApplicationDbContext` đã được tạo sẵn:
```csharp
public class OrdersController : Controller
{
    private readonly ApplicationDbContext _context;

    public OrdersController(ApplicationDbContext context)
    {
        _context = context;
    }

    // Danh sách đơn hàng
    public async Task<IActionResult> Index()
    {
        var orders = await _context.Orders
            .Include(o => o.User)
            .OrderByDescending(o => o.OrderDate)
            .ToListAsync();
        return View(orders);
    }
}
```

---

## 3. Dành cho Người 4 (Sản phẩm & Kho hàng)

Bạn phụ trách: **Danh mục**, **Sản phẩm (CRUD)**, **Biến thể Size/Màu**, và **Tồn kho**.

### A. Bạn tạo các Controller và View riêng trong Quản trị:
1. **Controllers:**
   - Tạo `Areas/Admin/Controllers/ProductManageController.cs` (Thêm, sửa, xóa sản phẩm).
   - Tạo `Areas/Admin/Controllers/CategoryManageController.cs` (Quản lý danh mục).
   - Tạo `Areas/Admin/Controllers/InventoryController.cs` (Cập nhật tồn kho theo biến thể).
2. **Views:**
   - Tạo thư mục `Areas/Admin/Views/ProductManage/`: chứa `Index.cshtml`, `Create.cshtml`, `Edit.cshtml`.
   - Tạo thư mục `Areas/Admin/Views/CategoryManage/`: chứa `Index.cshtml`, `Create.cshtml`.
   - Tạo thư mục `Areas/Admin/Views/Inventory/`: chứa `Index.cshtml` (Bảng chỉnh sửa số lượng tồn kho).

### B. Tận dụng giao diện Admin có sẵn:
Ở đầu các file View của bạn, chỉ cần khai báo:
```html
@{
    Layout = "_AdminLayout";
    ViewData["Title"] = "Quản lý sản phẩm";
}
```
Trang của bạn sẽ tự động có đầy đủ Sidebar Admin và Topbar đẹp mắt theo chuẩn của nhóm!

---

## 4. Tóm tắt 3 Nguyên Tắc Vàng Khi Làm Nhóm
1. **Không sửa trực tiếp file của người khác** (trừ khi có trao đổi trước).
2. **Mỗi tính năng tạo file Controller & View mới** theo tên module của mình.
3. **Trước khi commit code lên Git:** Nhấn `Ctrl + Shift + B` (hoặc chạy lệnh `dotnet build`) trên máy của mình. Nếu thấy báo `0 Error` thì mới được commit và push lên nhánh `feature/...` của mình.
