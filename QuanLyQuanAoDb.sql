-- =======================================================================
-- ĐỒ ÁN MÔN HỌC: LẬP TRÌNH WEB - TRƯỜNG ĐẠI HỌC CÔNG THƯƠNG TP.HCM (HUIT)
-- ĐỀ TÀI: WEBSITE QUẢN LÝ & KINH DOANH MẶT HÀNG QUẦN ÁO
-- THÀNH VIÊN SỐ 1: DATABASE & BACKEND NỀN TẢNG
-- HỆ QUẢN TRỊ CSDL: MICROSOFT SQL SERVER 2019 / 2022
-- =======================================================================

USE master;
GO

-- 1. TẠO DATABASE
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'WebQuanLyQuanAoDb')
BEGIN
    ALTER DATABASE WebQuanLyQuanAoDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WebQuanLyQuanAoDb;
END
GO

CREATE DATABASE WebQuanLyQuanAoDb COLLATE Vietnamese_CI_AS;
GO

USE WebQuanLyQuanAoDb;
GO

-- =======================================================================
-- 2. TẠO CÁC BẢNG CƠ SỞ DỮ LIỆU
-- =======================================================================

-- -----------------------------------------------------------------------
-- BẢNG 1: Roles (Phân quyền: Quản trị viên, Nhân viên, Khách hàng)
-- -----------------------------------------------------------------------
CREATE TABLE Roles (
    RoleId INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,          -- Admin, Staff, Customer
    Description NVARCHAR(255) NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 2: Permissions (Danh mục quyền chức năng hệ thống - RBAC)
-- -----------------------------------------------------------------------
CREATE TABLE Permissions (
    PermissionId INT IDENTITY(1,1) PRIMARY KEY,
    PermissionName NVARCHAR(100) NOT NULL,
    PermissionCode VARCHAR(50) NOT NULL UNIQUE,     -- PRODUCT_MANAGE, ORDER_MANAGE,...
    Module NVARCHAR(50) NOT NULL,                   -- Sản phẩm, Đơn hàng, Kho, Tài khoản, Thống kê
    Description NVARCHAR(255) NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 3: RolePermissions (Gán quyền cho từng vai trò)
-- -----------------------------------------------------------------------
CREATE TABLE RolePermissions (
    RolePermissionId INT IDENTITY(1,1) PRIMARY KEY,
    RoleId INT NOT NULL,
    PermissionId INT NOT NULL,
    CONSTRAINT FK_RolePermissions_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId) ON DELETE CASCADE,
    CONSTRAINT FK_RolePermissions_Permissions FOREIGN KEY (PermissionId) REFERENCES Permissions(PermissionId) ON DELETE CASCADE,
    CONSTRAINT UQ_Role_Permission UNIQUE (RoleId, PermissionId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 4: Users (Người dùng, nhân viên, quản trị viên, khách hàng)
-- -----------------------------------------------------------------------
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) NULL,
    PhoneNumber VARCHAR(20) NULL,
    Address NVARCHAR(255) NULL,
    Avatar VARCHAR(255) NULL,
    RoleId INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,                -- 1: Kích hoạt, 0: Đang khóa
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 5: CustomerAddresses (Sổ địa chỉ giao hàng của khách hàng)
-- -----------------------------------------------------------------------
CREATE TABLE CustomerAddresses (
    AddressId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    ReceiverName NVARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    SpecificAddress NVARCHAR(255) NOT NULL,
    City NVARCHAR(100) NULL,
    IsDefault BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 6: Categories (Danh mục sản phẩm quần áo)
-- -----------------------------------------------------------------------
CREATE TABLE Categories (
    CategoryId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Slug VARCHAR(100) NULL,                         -- ao-thun, ao-so-mi,...
    Description NVARCHAR(500) NULL,
    ImageUrl VARCHAR(255) NULL,
    DisplayOrder INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 7: Products (Mặt hàng quần áo chung)
-- -----------------------------------------------------------------------
CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId INT NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    ProductCode VARCHAR(50) NULL UNIQUE,            -- AT-001, QJ-002,...
    Description NVARCHAR(MAX) NULL,                 -- Mô tả chi tiết
    OriginalPrice DECIMAL(18,2) NOT NULL DEFAULT 0, -- Giá nhập vốn
    Price DECIMAL(18,2) NOT NULL,                   -- Giá bán niêm yết
    DiscountPercent INT NULL DEFAULT 0,             -- % Khuyến mãi
    MainImage VARCHAR(255) NULL,                    -- Ảnh chính
    IsFeatured BIT NOT NULL DEFAULT 0,              -- 1: Nổi bật trang chủ
    IsActive BIT NOT NULL DEFAULT 1,                -- 1: Đang bán, 0: Ẩn
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 8: Sizes (Kích cỡ quần áo: S, M, L, XL, XXL, 29, 30,...)
-- -----------------------------------------------------------------------
CREATE TABLE Sizes (
    SizeId INT IDENTITY(1,1) PRIMARY KEY,
    SizeName VARCHAR(20) NOT NULL UNIQUE,
    Description NVARCHAR(100) NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 9: Colors (Màu sắc quần áo: Đen, Trắng, Be, Xanh Navy,...)
-- -----------------------------------------------------------------------
CREATE TABLE Colors (
    ColorId INT IDENTITY(1,1) PRIMARY KEY,
    ColorName NVARCHAR(50) NOT NULL UNIQUE,
    ColorHex VARCHAR(10) NULL                       -- Mã màu HEX phục vụ Figma & Frontend
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 10: ProductVariants (Biến thể Sản phẩm: Quản lý chính xác Tồn kho)
-- -----------------------------------------------------------------------
CREATE TABLE ProductVariants (
    VariantId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    SizeId INT NOT NULL,
    ColorId INT NOT NULL,
    SKU VARCHAR(50) NULL UNIQUE,                    -- AT01-M-BLK
    StockQuantity INT NOT NULL DEFAULT 0,           -- Số lượng tồn kho
    VariantImage VARCHAR(255) NULL,
    CONSTRAINT FK_Variants_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    CONSTRAINT FK_Variants_Sizes FOREIGN KEY (SizeId) REFERENCES Sizes(SizeId),
    CONSTRAINT FK_Variants_Colors FOREIGN KEY (ColorId) REFERENCES Colors(ColorId),
    CONSTRAINT UQ_Product_Size_Color UNIQUE (ProductId, SizeId, ColorId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 11: Coupons (Mã giảm giá khuyến mãi / Voucher)
-- -----------------------------------------------------------------------
CREATE TABLE Coupons (
    CouponId INT IDENTITY(1,1) PRIMARY KEY,
    CouponCode VARCHAR(50) NOT NULL UNIQUE,
    DiscountPercent INT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,2) NULL DEFAULT 0,
    MinOrderAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    UsageLimit INT NOT NULL DEFAULT 100,
    UsedCount INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 12: Orders (Đơn đặt hàng)
-- -----------------------------------------------------------------------
CREATE TABLE Orders (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NULL,                                -- NULL nếu khách không đăng nhập
    CouponId INT NULL,                              -- Khóa ngoại Coupon nếu áp mã
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    ReceiverName NVARCHAR(100) NOT NULL,
    ReceiverPhone VARCHAR(20) NOT NULL,
    ShippingAddress NVARCHAR(255) NOT NULL,
    OrderNotes NVARCHAR(500) NULL,
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0, -- Số tiền được giảm
    PaymentMethod NVARCHAR(50) NOT NULL DEFAULT N'COD', -- COD, Chuyển khoản, VNPay
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán', -- Chưa thanh toán, Đã thanh toán
    OrderStatus NVARCHAR(50) NOT NULL DEFAULT N'Chờ xác nhận',     -- Chờ xác nhận, Đang giao, Đã giao, Đã hủy
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL,
    CONSTRAINT FK_Orders_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(CouponId) ON DELETE SET NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 13: OrderDetails (Chi tiết đơn hàng)
-- -----------------------------------------------------------------------
CREATE TABLE OrderDetails (
    OrderDetailId INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL,
    TotalPrice AS (Quantity * UnitPrice),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 14: Carts (Giỏ hàng người dùng / khách vãng lai)
-- -----------------------------------------------------------------------
CREATE TABLE Carts (
    CartId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NULL,                                -- NULL nếu là khách vãng lai
    SessionId VARCHAR(100) NULL,                    -- Mã session lưu giỏ tạm
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Carts_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 15: CartItems (Chi tiết từng món trong giỏ hàng)
-- -----------------------------------------------------------------------
CREATE TABLE CartItems (
    CartItemId INT IDENTITY(1,1) PRIMARY KEY,
    CartId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
    AddedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CartItems_Carts FOREIGN KEY (CartId) REFERENCES Carts(CartId) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId) ON DELETE CASCADE,
    CONSTRAINT UQ_Cart_Variant UNIQUE (CartId, VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 16: ProductReviews (Đánh giá & Bình luận sản phẩm)
-- -----------------------------------------------------------------------
CREATE TABLE ProductReviews (
    ReviewId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    UserId INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    Comment NVARCHAR(1000) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsApproved BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Reviews_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 17: Suppliers (Nhà cung cấp / Xưởng may thời trang)
-- -----------------------------------------------------------------------
CREATE TABLE Suppliers (
    SupplierId INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(150) NOT NULL,
    Phone VARCHAR(20) NULL,
    Email VARCHAR(100) NULL,
    Address NVARCHAR(255) NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 18 & 19: ImportReceipts & ImportReceiptDetails (Phiếu nhập kho)
-- -----------------------------------------------------------------------
CREATE TABLE ImportReceipts (
    ImportId INT IDENTITY(1,1) PRIMARY KEY,
    SupplierId INT NOT NULL,
    UserId INT NOT NULL,
    ImportDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    Notes NVARCHAR(500) NULL,
    CONSTRAINT FK_Imports_Suppliers FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
    CONSTRAINT FK_Imports_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO

CREATE TABLE ImportReceiptDetails (
    ImportDetailId INT IDENTITY(1,1) PRIMARY KEY,
    ImportId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    ImportPrice DECIMAL(18,2) NOT NULL,
    TotalPrice AS (Quantity * ImportPrice),
    CONSTRAINT FK_ImportDetails_Imports FOREIGN KEY (ImportId) REFERENCES ImportReceipts(ImportId) ON DELETE CASCADE,
    CONSTRAINT FK_ImportDetails_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId)
);
GO

-- =======================================================================
-- 3. CHÈN DỮ LIỆU MẪU BAN ĐẦU (SEED DATA ĐẦY ĐỦ CHO TẤT CẢ PHÂN HỆ)
-- =======================================================================

-- 1. Roles
INSERT INTO Roles (RoleName, Description) VALUES
(N'Admin', N'Quản trị viên toàn quyền hệ thống'),
(N'Staff', N'Nhân viên bán hàng và thủ kho'),
(N'Customer', N'Khách hàng thành viên');

-- 2. Permissions
INSERT INTO Permissions (PermissionName, PermissionCode, Module, Description) VALUES
(N'Quản lý sản phẩm', 'PRODUCT_MANAGE', N'Sản phẩm', N'Thêm, sửa, xóa sản phẩm và biến thể'),
(N'Xem danh sách sản phẩm', 'PRODUCT_VIEW', N'Sản phẩm', N'Xem sản phẩm và kiểm tra giá'),
(N'Quản lý danh mục', 'CATEGORY_MANAGE', N'Danh mục', N'Thêm, sửa, xóa danh mục quần áo'),
(N'Quản lý kho hàng', 'INVENTORY_MANAGE', N'Kho hàng', N'Quản lý tồn kho và tạo phiếu nhập'),
(N'Quản lý đơn hàng', 'ORDER_MANAGE', N'Đơn hàng', N'Duyệt đơn và cập nhật trạng thái giao hàng'),
(N'Xem báo cáo doanh thu', 'REPORT_VIEW', N'Báo cáo', N'Xem thống kê tổng quan và báo cáo bán hàng'),
(N'Quản lý người dùng & phân quyền', 'USER_MANAGE', N'Người dùng', N'Quản lý tài khoản, gán quyền');

-- 3. RolePermissions
-- Admin có tất cả quyền
INSERT INTO RolePermissions (RoleId, PermissionId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7);

-- Staff có quyền sản phẩm, kho và đơn hàng
INSERT INTO RolePermissions (RoleId, PermissionId) VALUES
(2, 1), (2, 2), (2, 4), (2, 5);

-- Customer có quyền xem sản phẩm
INSERT INTO RolePermissions (RoleId, PermissionId) VALUES
(3, 2);

-- 4. Users (Mật khẩu mặc định: 123456)
INSERT INTO Users (Username, PasswordHash, FullName, Email, PhoneNumber, Address, RoleId) VALUES
('admin', '123456', N'Quản Trị Viên HUIT', 'admin@shopquanao.vn', '0901234567', N'140 Lê Trọng Tấn, P. Tây Thạnh, Q. Tân Phú, TP.HCM', 1),
('nhanvien', '123456', N'Nguyễn Văn Quản Kho', 'kho@shopquanao.vn', '0912345678', N'Tân Phú, TP. Hồ Chí Minh', 2),
('khachhang', '123456', N'Trần Thị Mai', 'mai.tran@gmail.com', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', 3),
('lethiba', '123456', N'Lê Thị Ba', 'ba.le@gmail.com', '0933445566', N'456 Bạch Đằng, Bình Thạnh, TP. Hồ Chí Minh', 3);

-- 5. CustomerAddresses (Sổ địa chỉ của khách hàng)
INSERT INTO CustomerAddresses (UserId, ReceiverName, PhoneNumber, SpecificAddress, City, IsDefault) VALUES
(3, N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Phường Bến Thành', N'TP. Hồ Chí Minh', 1),
(3, N'Trần Thị Mai (Cơ quan)', '0987654321', N'Tòa nhà Bitexco, Số 2 Hải Triều', N'TP. Hồ Chí Minh', 0),
(4, N'Lê Thị Ba', '0933445566', N'456 Bạch Đằng, Phường 14', N'TP. Hồ Chí Minh', 1);

-- 6. Categories
INSERT INTO Categories (CategoryName, Slug, Description, ImageUrl, DisplayOrder) VALUES
(N'Áo Thun & Polo', 'ao-thun-polo', N'Các mẫu áo thun cotton, áo polo thời trang cao cấp', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500', 1),
(N'Áo Sơ Mi Nam Nữ', 'ao-so-mi', N'Áo sơ mi công sở, sơ mi tay dài, ngắn tay phong cách hiện đại', 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500', 2),
(N'Quần Jean Thời Trang', 'quan-jean', N'Quần jean ống suông, slimfit, co giãn thoải mái', 'https://images.unsplash.com/photo-1542272604-780c96856592?w=500', 3),
(N'Quần Tây & Kaki', 'quan-tay-kaki', N'Quần tây âu lịch lãm, quần kaki năng động', 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=500', 4),
(N'Áo Khoác & Blazer', 'ao-khoac-blazer', N'Áo khoác dù chống nước, áo khoác blazer thanh lịch', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500', 5);

-- 7. Sizes
INSERT INTO Sizes (SizeName, Description) VALUES
('S', N'Size S (45kg - 53kg, 1m50 - 1m60)'),
('M', N'Size M (54kg - 62kg, 1m60 - 1m68)'),
('L', N'Size L (63kg - 70kg, 1m68 - 1m75)'),
('XL', N'Size XL (71kg - 80kg, 1m75 - 1m82)'),
('XXL', N'Size XXL (> 80kg, trên 1m80)');

-- 8. Colors
INSERT INTO Colors (ColorName, ColorHex) VALUES
(N'Đen Classic', '#000000'),
(N'Trắng Tinh Khôi', '#FFFFFF'),
(N'Xanh Navy Trầm', '#000080'),
(N'Xám Khói Hiện Đại', '#708090'),
(N'Màu Be Thanh Lịch', '#F5F5DC');

-- 9. Suppliers
INSERT INTO Suppliers (SupplierName, Phone, Email, Address) VALUES
(N'Xưởng May Gia Công HUIT Fashion', '02838161673', 'huitfashion@gmail.com', N'140 Lê Trọng Tấn, Tân Phú, TP.HCM'),
(N'Công Ty Cổ Phần Dệt May Việt Nam', '02839998888', 'contact@detmayvn.com', N'KCN Tân Bình, Tân Phú, TP.HCM');

-- 10. Products
INSERT INTO Products (CategoryId, ProductName, ProductCode, Description, OriginalPrice, Price, DiscountPercent, MainImage, IsFeatured) VALUES
(1, N'Áo Thun Cotton Compact 100% Thoáng Mát Form Regular', 'AT-001', N'Áo thun trơn basic chất liệu 100% Cotton chải kỹ cao cấp, bề mặt mịn màng, thấm hút mồ hôi tốt, độ bền cao qua nhiều lần giặt.', 120000, 189000, 10, 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600', 1),
(1, N'Áo Polo Cổ Bẻ Dệt Phối Bo Phong Cách Hàn Quốc', 'PL-002', N'Chất vải cá sấu mè co giãn 4 chiều mềm mại, phom dáng slim-fit ôm gọn gàng, cổ bẻ thanh lịch thích hợp đi học, đi làm.', 160000, 249000, 0, 'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600', 1),
(2, N'Áo Sơ Mi Trắng Kháng Nhăn Dài Tay Oxford Cao Cấp', 'SM-001', N'Vải Oxford xử lý công nghệ chống nhăn Easy Care, giữ form chuẩn suốt cả ngày dài, đường may kép chắc chắn tỉ mỉ.', 190000, 299000, 15, 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600', 1),
(2, N'Áo Sơ Mi Denim Dáng Rộng Vintage Unisex', 'SM-002', N'Sơ mi chất bò denim mềm mại phong cách streetwear năng động, phù hợp khoác ngoài hoặc mặc đơn.', 210000, 320000, 0, 'https://images.unsplash.com/photo-1589310243389-96a5483213a8?w=600', 1),
(3, N'Quần Jean Nam Ống Suông Slimfit Wash Xanh Phong Cách', 'QJ-001', N'Chất denim co giãn nhẹ 12oz, kỹ thuật wash tạo hiệu ứng cổ điển bắt mắt, tôn dáng chân dài và dễ phối cùng áo thun, sơ mi.', 250000, 399000, 5, 'https://images.unsplash.com/photo-1542272604-780c96856592?w=600', 1),
(3, N'Quần Jean Ống Rộng Wide Leg Unisex Cá Tính', 'QJ-002', N'Form ống rộng thời thượng mang phong cách Y2K, chất jeans dầy dặn không xù lông.', 260000, 420000, 10, 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600', 0),
(4, N'Quần Tây Âu 2 Ly Xếp Dáng Hàn Quốc Sang Trọng', 'QT-001', N'Chất vải tuyết mưa nhập khẩu không nhăn, cạp quần có tăng đơ co giãn thông minh giúp người mặc thoải mái tối đa.', 230000, 350000, 0, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600', 0),
(5, N'Áo Khoác Gió Bomber 2 Lớp Chống Thấm Nước Thời Trang', 'AK-001', N'Chất vải trượt nước dệt mật độ cao cản gió mưa, lót lưới thông thoáng chống bí, khóa zip hợp kim bền bỉ.', 280000, 450000, 20, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600', 1);

-- 11. ProductVariants (Biến thể theo Size & Màu sắc + Quản lý Tồn kho)
INSERT INTO ProductVariants (ProductId, SizeId, ColorId, SKU, StockQuantity) VALUES
-- Áo thun Cotton (ProductId = 1)
(1, 1, 1, 'AT001-S-BLK', 20),
(1, 2, 1, 'AT001-M-BLK', 35),
(1, 3, 1, 'AT001-L-BLK', 40),
(1, 2, 2, 'AT001-M-WHT', 25),
(1, 3, 2, 'AT001-L-WHT', 30),
-- Áo Polo Hàn Quốc (ProductId = 2)
(2, 2, 3, 'PL002-M-NAVY', 15),
(2, 3, 3, 'PL002-L-NAVY', 25),
(2, 4, 3, 'PL002-XL-NAVY', 10),
(2, 2, 2, 'PL002-M-WHT', 18),
-- Áo Sơ Mi Oxford (ProductId = 3)
(3, 2, 2, 'SM001-M-WHT', 45),
(3, 3, 2, 'SM001-L-WHT', 50),
(3, 4, 2, 'SM001-XL-WHT', 20),
-- Sơ Mi Denim (ProductId = 4)
(4, 2, 3, 'SM002-M-NAVY', 15),
(4, 3, 3, 'SM002-L-NAVY', 20),
-- Quần Jean Slimfit (ProductId = 5)
(5, 2, 3, 'QJ001-M-NAVY', 12),
(5, 3, 3, 'QJ001-L-NAVY', 28),
(5, 4, 3, 'QJ001-XL-NAVY', 15),
-- Quần Jean Wide Leg (ProductId = 6)
(6, 2, 3, 'QJ002-M-NAVY', 14),
(6, 3, 3, 'QJ002-L-NAVY', 20),
-- Quần Tây 2 Ly (ProductId = 7)
(7, 2, 1, 'QT001-M-BLK', 30),
(7, 3, 1, 'QT001-L-BLK', 35),
-- Áo Khoác Bomber (ProductId = 8)
(8, 3, 4, 'AK001-L-GRY', 18),
(8, 4, 4, 'AK001-XL-GRY', 12),
(8, 3, 1, 'AK001-L-BLK', 25);

-- 12. Coupons (Mã khuyến mãi mẫu)
INSERT INTO Coupons (CouponCode, DiscountPercent, DiscountAmount, MinOrderAmount, StartDate, EndDate, UsageLimit, UsedCount, IsActive) VALUES
('HUIT2026', 15, 0, 300000, '2026-01-01', '2026-12-31', 500, 12, 1),
('FASHION50K', 0, 50000, 400000, '2026-01-01', '2026-12-31', 200, 8, 1),
('FREESHIP', 0, 30000, 200000, '2026-01-01', '2026-12-31', 1000, 45, 1);

-- 13. Orders & OrderDetails
INSERT INTO Orders (UserId, CouponId, OrderDate, ReceiverName, ReceiverPhone, ShippingAddress, OrderNotes, TotalAmount, DiscountAmount, PaymentMethod, PaymentStatus, OrderStatus) VALUES
(3, 1, DATEADD(DAY, -3, GETDATE()), N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', N'Giao giờ hành chính', 388000, 50000, N'COD', N'Đã thanh toán', N'Đã giao'),
(3, NULL, DATEADD(DAY, -1, GETDATE()), N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', N'Đóng gói cẩn thận', 749000, 0, N'Chuyển khoản', N'Đã thanh toán', N'Đang giao'),
(4, NULL, GETDATE(), N'Lê Thị Ba', '0933445566', N'456 Bạch Đằng, Bình Thạnh, TP. Hồ Chí Minh', N'Giao trước thứ 7', 399000, 0, N'COD', N'Chưa thanh toán', N'Chờ xác nhận');

INSERT INTO OrderDetails (OrderId, VariantId, Quantity, UnitPrice) VALUES
(1, 2, 1, 189000),
(1, 6, 1, 249000),
(2, 9, 1, 299000),
(2, 20, 1, 450000),
(3, 14, 1, 399000);

-- 14. Carts & CartItems (Giỏ hàng mẫu trong DB)
INSERT INTO Carts (UserId, SessionId, CreatedAt, UpdatedAt) VALUES
(3, 'session_khachhang_3', GETDATE(), GETDATE()),
(NULL, 'session_guest_anonymous', GETDATE(), GETDATE());

INSERT INTO CartItems (CartId, VariantId, Quantity) VALUES
(1, 1, 2), -- Khách 3 đang có 2 Áo thun đen size S
(1, 7, 1), -- và 1 Áo polo navy size XL
(2, 10, 1); -- Khách vãng lai đang có 1 Áo sơ mi trắng size L

-- 15. ProductReviews (Đánh giá sản phẩm mẫu)
INSERT INTO ProductReviews (ProductId, UserId, Rating, Comment, IsApproved) VALUES
(1, 3, 5, N'Áo thun mặc rất mát, chất vải cotton dày dặn và co giãn thoải mái, form đẹp!', 1),
(3, 4, 5, N'Sơ mi chống nhăn rất tốt, đi làm cả ngày không bị nhàu vải.', 1),
(5, 3, 4, N'Quần jean màu wash rất đẹp, dáng chuẩn slimfit nhưng hơi dài so với chiều cao 1m60.', 1);
GO

PRINT N'========================================================================';
PRINT N'ĐÃ CẬP NHẬT THÀNH CÔNG DATABASE [WebQuanLyQuanAoDb] VỚI 19 BẢNG HOÀN CHỈNH!';
PRINT N'ĐÃ BỔ SUNG: Permissions, RolePermissions, CustomerAddresses, Carts, CartItems, Coupons, ProductReviews';
PRINT N'========================================================================';
GO
