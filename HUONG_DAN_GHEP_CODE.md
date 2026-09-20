# CẨM NANG HƯỚNG DẪN GIT & GHÉP CODE DỰ ÁN NHÓM (HUIT)
*Đề tài: Website Quản lý & Kinh doanh Mặt hàng Quần áo (ASP.NET Core MVC .NET 8)*  
*Biên soạn: Người 1 (Database & Backend Nền tảng)*

---

Tài liệu này hướng dẫn chi tiết từng bước cho **cả 4 thành viên** từ việc Clone code từ GitHub, tạo nhánh riêng, commit/push code, tạo Pull Request ghép code, đến cách thay thế giao diện Figma và cắm tính năng riêng.

---

## MỤC LỤC
1. [Bước 1: Clone dự án từ GitHub về máy cá nhân](#bước-1-clone-dự-án-từ-github-về-máy-cá-nhân)
2. [Bước 2: Nạp CSDL SQL Server trên máy bạn](#bước-2-nạp-csdl-sql-server-trên-máy-bạn)
3. [Bước 3: Tạo nhánh riêng (Branch) để làm việc](#bước-3-tạo-nhánh-riêng-branch-để-làm-việc)
4. [Bước 4: Quy trình Code, Commit và Push lên GitHub](#bước-4-quy-trình-code-commit-và-push-lên-github)
5. [Bước 5: Tạo Pull Request (PR) để ghép code vào nhóm](#bước-5-tạo-pull-request-pr-để-ghép-code-vào-nhóm)
6. [Bước 6: Kéo code mới nhất của cả nhóm về máy](#bước-6-kéo-code-mới-nhất-của-cả-nhóm-về-máy)
7. [Hướng dẫn cụ thể cho từng thành viên thay code](#hướng-dẫn-cụ-thể-cho-từng-thành-viên-thay-code)
8. [Các lỗi thường gặp và cách khắc phục nhanh](#các-lỗi-thường-gặp-và-cách-khắc-phục-nhanh)

---

## Bước 1: Clone dự án từ GitHub về máy cá nhân

### Cách 1: Dùng dòng lệnh Git (Git Bash / PowerShell / Terminal)
1. Mở thư mục muốn lưu bài (ví dụ `D:\DoAnWeb`), nhấn chuột phải chọn **Open Git Bash here** hoặc **Open in Terminal**.
2. Gõ lệnh clone:
   ```bash
   git clone https://github.com/<tai-khoan-nguoi-1>/LT_Web_QuanLyQuanAo.git
   cd LT_Web_QuanLyQuanAo
   ```
3. Chuyển sang nhánh tập kết chung `develop`:
   ```bash
   git checkout develop
   ```

### Cách 2: Dùng Visual Studio (2019 / 2022)
1. Mở Visual Studio $\rightarrow$ Chọn **Clone a repository** ở màn hình khởi động.
2. Dán đường link GitHub của repo vào ô **Repository location**.
3. Chọn thư mục lưu trên máy $\rightarrow$ Nhấn nút **Clone**.
4. Mở cửa sổ **Git Changes** (hoặc góc dưới cùng bên phải), chuyển nhánh từ `main` sang **`develop`**.

---

## Bước 2: Nạp CSDL SQL Server trên máy bạn

Tất cả các máy đều phải nạp cùng một cơ sở dữ liệu để web chạy được dữ liệu mẫu:
1. Mở phần mềm **SQL Server Management Studio (SSMS)**.
2. Đăng nhập vào SQL Server trên máy của bạn (hoặc `(localdb)\mssqllocaldb`).
3. Nhấn **File -> Open -> File...** $\rightarrow$ Chọn file `QuanLyQuanAoDb.sql` trong thư mục vừa tải về.
4. Nhấn nút **Execute (F5)** để chạy.
   - Kết quả hiện thông báo xanh: `ĐÃ CẬP NHẬT THÀNH CÔNG DATABASE [WebQuanLyQuanAoDb]!` là thành công.
5. Mở file `appsettings.json` trong project `QuanLyQuanAoWeb`, kiểm tra dòng `DefaultConnection`:
   - Mặc định là: `"Server=(localdb)\\mssqllocaldb;Database=WebQuanLyQuanAoDb;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"`
   - Nếu máy bạn dùng SQL Express riêng (VD: `DESKTOP-ABC\SQLEXPRESS`), hãy đổi lại tên Server cho khớp với máy bạn.

---

## Bước 3: Tạo nhánh riêng (Branch) để làm việc

**QUY TẮC SỐNG CÒN:** Tuyệt đối **KHÔNG** code trực tiếp trên nhánh `main` hoặc `develop`. Mỗi người phải tạo một nhánh riêng mang tên mình/tính năng của mình!

### Quy ước đặt tên nhánh cho 4 thành viên:
- **Người 2 (Figma & Frontend):** `feature/frontend-ui`
- **Người 3 (Khách hàng & Đơn hàng):** `feature/orders-customers`
- **Người 4 (Sản phẩm & Kho hàng):** `feature/products-inventory`

### Lệnh tạo nhánh (Terminal):
```bash
# Đảm bảo đang ở develop và có code mới nhất
git checkout develop
git pull origin develop

# Tạo và nhảy sang nhánh mới của bạn
git checkout -b feature/orders-customers
```

*(Trên Visual Studio GUI: Nhấn vào tên nhánh góc dưới bên phải $\rightarrow$ Chọn **New Branch...** $\rightarrow$ Điền tên nhánh $\rightarrow$ Chọn Base từ `develop` $\rightarrow$ Nhấn **Create**).*

---

## Bước 4: Quy trình Code, Commit và Push lên GitHub

Sau khi bạn code xong hoặc hết một buổi làm việc:

### Bước 4.1: Kiểm tra build trước khi gửi code
- Trên Visual Studio: Nhấn `Ctrl + Shift + B` (Build Solution).
- Hoặc trên Terminal gõ: `dotnet build`
- **BẮT BUỘC** phải thấy: `Build succeeded. 0 Error(s)` thì mới được commit! (Nếu có lỗi đỏ thì sửa hết trước khi commit, không đẩy code lỗi làm sập app của cả nhóm).

### Bước 4.2: Commit & Push code lên GitHub

#### Bằng Terminal:
```bash
# 1. Xem những file bạn vừa thay đổi hoặc thêm mới
git status

# 2. Thêm toàn bộ file thay đổi vào hàng đợi
git add .

# 3. Đóng gói commit và ghi chú rõ ràng đã làm gì
git commit -m "feat(order): Them giao dien danh sach don hang va chi tiet don"

# 4. Đẩy nhánh của bạn lên GitHub
git push -u origin feature/orders-customers
```
*(Từ lần thứ 2 trở đi, chỉ cần gõ `git push`).*

#### Bằng Visual Studio GUI:
1. Mở tab **Git Changes** bên phải màn hình.
2. Nhập ghi chú (Commit message) vào ô trống (VD: `Hoan thanh CRUD don hang`).
3. Nhấn vào nút mũi tên cạnh nút Commit $\rightarrow$ Chọn **Commit All and Push**.

---

## Bước 5: Tạo Pull Request (PR) để ghép code vào nhóm

Khi tính năng của bạn đã hoàn thành và muốn ghép vào sản phẩm chung:

1. Mở trình duyệt, truy cập vào trang GitHub của dự án.
2. Bạn sẽ thấy một thanh màu vàng hiện lên kèm nút **Compare & pull request** $\rightarrow$ Nhấn vào đó.
3. **Cực kỳ quan trọng:**
   - **Base branch (nhánh đích):** Chọn **`develop`** (Không chọn `main`).
   - **Compare branch (nhánh của bạn):** Chọn nhánh của bạn (ví dụ `feature/orders-customers`).
4. Viết mô tả ngắn gọn: Các trang/chức năng vừa hoàn thành $\rightarrow$ Nhấn **Create pull request**.
5. Nhắn tin vào nhóm Zalo để **Người 1 (hoặc trưởng nhóm)** vào kiểm tra.
6. Trưởng nhóm duyệt code thấy ổn thì nhấn nút **Merge pull request** $\rightarrow$ **Confirm merge**.
   *(Lúc này code của bạn đã chính thức nằm trong nhánh `develop` của cả nhóm).*

---

## Bước 6: Kéo code mới nhất của cả nhóm về máy

Mỗi khi có bạn khác vừa ghép xong một tính năng mới vào `develop`, bạn muốn lấy code mới đó về máy mình:

```bash
# 1. Chuyển về nhánh develop
git checkout develop

# 2. Kéo toàn bộ code mới nhất về
git pull origin develop

# 3. Cập nhật code mới đó vào nhánh tính năng bạn đang làm
git checkout feature/orders-customers
git merge develop
```
*(Lúc này nhánh của bạn vừa giữ nguyên phần code bạn đang làm, vừa có thêm các màn hình/tính năng mới mà bạn khác vừa viết).*

---

## Hướng dẫn cụ thể cho từng thành viên thay code

### 1. Dành cho Người 2 (Figma & Frontend)
- **Đổi màu, font, CSS theo Figma:** Chỉ cần sửa `wwwroot/css/site.css` hoặc tạo `wwwroot/css/custom.css`.
- **Thay đổi khung Header/Footer:** Mở `Views/Shared/_Layout.cshtml` (khách) và `_AdminLayout.cshtml` (quản trị). Xóa hoặc thay HTML theo Figma, **chỉ cần giữ nguyên thẻ `@RenderBody()`**.
- **Thay giao diện trang chủ/chi tiết:** Mở `Views/Home/Index.cshtml` và `Details.cshtml`. Thay đổi thẻ `div`, `class`, giữ lại các biểu thức in dữ liệu Razor `@product.ProductName`, `@product.Price`, `@foreach(...)`.

### 2. Dành cho Người 3 (Khách hàng & Đơn hàng)
- **Không sửa đè file của bạn khác.** Tạo mới:
  - `Controllers/OrdersController.cs` và `Controllers/CustomersController.cs`
  - `Views/Orders/Index.cshtml`, `Views/Orders/Details.cshtml`
  - `Views/Customers/Index.cshtml`
- Gọi dữ liệu từ `_context.Orders` và `_context.Users` có sẵn trong `ApplicationDbContext`.

### 3. Dành cho Người 4 (Sản phẩm & Kho hàng)
- Tạo mới các file trong khu vực Quản trị Admin:
  - `Areas/Admin/Controllers/ProductManageController.cs`
  - `Areas/Admin/Controllers/CategoryManageController.cs`
  - `Areas/Admin/Controllers/InventoryController.cs`
  - Các Views tương ứng trong `Areas/Admin/Views/...`
- Đầu mỗi View chỉ cần đặt:
  ```html
  @{
      Layout = "_AdminLayout";
      ViewData["Title"] = "Quản lý sản phẩm";
  }
  ```
  Trang của bạn sẽ tự động có sẵn Sidebar Admin cực đẹp đã thiết kế theo chuẩn Figma!

---

## Các lỗi thường gặp và cách khắc phục nhanh

### 1. Lỗi xung đột code (Merge Conflict)
- **Nguyên nhân:** Hai bạn cùng sửa vào cùng một dòng code trong cùng một file (VD: cùng sửa `_Layout.cshtml`).
- **Cách xử lý:** Mở file bị conflict trên Visual Studio hoặc VS Code. Bạn sẽ thấy các dấu `<<<<<<< HEAD` và `>>>>>>>`. Thảo luận với bạn kia xem giữ lại đoạn code nào, xóa các dấu ngăn cách đi, sau đó lưu file và commit lại.

### 2. Lỗi không kết nối được Database (Cannot open database / Login failed)
- **Cách xử lý:**
  1. Kiểm tra service SQL Server trên máy bạn đã bật chưa.
  2. Mở file `QuanLyQuanAoDb.sql` trên SSMS và chạy lại `F5` để đảm bảo DB `WebQuanLyQuanAoDb` đã tồn tại.
  3. Kiểm tra tên Server trong `appsettings.json` đã đúng với tên máy mình chưa.

### 3. Lỗi không Push được lên GitHub (Permission denied / 403)
- **Cách xử lý:**
  - Nhắc Người 1 (chủ repo) vào mục **Settings -> Collaborators** trên GitHub và gửi lời mời (Invite) vào email/tài khoản GitHub của bạn.
  - Bạn phải mở email và nhấn nút **Accept Invitation** thì mới có quyền push code lên repo.

---
*Chúc cả nhóm hoàn thành xuất sắc đồ án môn Lập trình Web!*
