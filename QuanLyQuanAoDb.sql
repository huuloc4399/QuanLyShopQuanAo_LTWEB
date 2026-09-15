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
-- 2. TẠO CÁC BẢNG CƠ SỞ DỮ LIỆU (CHIA THEO MODULE CỦA 4 THÀNH VIÊN)
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
-- BẢNG 2: Users (Người dùng, nhân viên, quản trị viên, khách hàng)
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
-- BẢNG 3: Categories (Danh mục sản phẩm quần áo)
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
-- BẢNG 4: Products (Mặt hàng quần áo chung - Người 4 phụ trách)
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
-- BẢNG 5: Sizes (Kích thước quần áo: S, M, L, XL, XXL, 29, 30,...)
-- -----------------------------------------------------------------------
CREATE TABLE Sizes (
    SizeId INT IDENTITY(1,1) PRIMARY KEY,
    SizeName VARCHAR(20) NOT NULL UNIQUE,
    Description NVARCHAR(100) NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 6: Colors (Màu sắc quần áo: Đen, Trắng, Be, Xanh Navy,...)
-- -----------------------------------------------------------------------
CREATE TABLE Colors (
    ColorId INT IDENTITY(1,1) PRIMARY KEY,
    ColorName NVARCHAR(50) NOT NULL UNIQUE,
    ColorHex VARCHAR(10) NULL                       -- Mã màu HEX phục vụ Figma & Frontend
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 7: ProductVariants (Biến thể Sản phẩm: Quản lý chính xác Tồn kho)
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
-- BẢNG 8: Orders (Đơn đặt hàng - Người 3 phụ trách)
-- -----------------------------------------------------------------------
CREATE TABLE Orders (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NULL,                                -- NULL nếu khách không đăng nhập
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    ReceiverName NVARCHAR(100) NOT NULL,
    ReceiverPhone VARCHAR(20) NOT NULL,
    ShippingAddress NVARCHAR(255) NOT NULL,
    OrderNotes NVARCHAR(500) NULL,
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    PaymentMethod NVARCHAR(50) NOT NULL DEFAULT N'COD', -- COD, Chuyển khoản, VNPay
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán', -- Chưa thanh toán, Đã thanh toán
    OrderStatus NVARCHAR(50) NOT NULL DEFAULT N'Chờ xác nhận',     -- Chờ xác nhận, Đang giao, Đã giao, Đã hủy
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 9: OrderDetails (Chi tiết đơn hàng - Người 3 phụ trách)
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
-- BẢNG 10: Suppliers (Nhà cung cấp / Xưởng may thời trang - Kho hàng Người 4)
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
-- BẢNG 11 & 12: ImportReceipts & ImportReceiptDetails (Phiếu nhập kho)
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
-- 3. CHÈN DỮ LIỆU MẪU BAN ĐẦU (SEED DATA ĐỂ TEST FIGMA VÀ CODE CHẠY NGAY)
-- =======================================================================

-- 1. Roles
INSERT INTO Roles (RoleName, Description) VALUES
(N'Admin', N'Quản trị viên toàn quyền hệ thống'),
(N'Staff', N'Nhân viên bán hàng và thủ kho'),
(N'Customer', N'Khách hàng thành viên');

-- 2. Users (Mật khẩu mặc định: 123456)
INSERT INTO Users (Username, PasswordHash, FullName, Email, PhoneNumber, Address, RoleId) VALUES
('admin', '123456', N'Quản Trị Viên HUIT', 'admin@shopquanao.vn', '0901234567', N'140 Lê Trọng Tấn, P. Tây Thạnh, Q. Tân Phú, TP.HCM', 1),
('nhanvien', '123456', N'Nguyễn Văn Quản Kho', 'kho@shopquanao.vn', '0912345678', N'Tân Phú, TP. Hồ Chí Minh', 2),
('khachhang', '123456', N'Trần Thị Mai', 'mai.tran@gmail.com', '0987654321', N'Quận 1, TP. Hồ Chí Minh', 3),
('lethiba', '123456', N'Lê Thị Ba', 'ba.le@gmail.com', '0933445566', N'Bình Thạnh, TP. Hồ Chí Minh', 3);

-- 3. Categories
INSERT INTO Categories (CategoryName, Slug, Description, ImageUrl, DisplayOrder) VALUES
(N'Áo Thun & Polo', 'ao-thun-polo', N'Các mẫu áo thun cotton, áo polo thời trang cao cấp', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500', 1),
(N'Áo Sơ Mi Nam Nữ', 'ao-so-mi', N'Áo sơ mi công sở, sơ mi tay dài, ngắn tay phong cách hiện đại', 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500', 2),
(N'Quần Jean Thời Trang', 'quan-jean', N'Quần jean ống suông, slimfit, co giãn thoải mái', 'https://images.unsplash.com/photo-1542272604-780c96856592?w=500', 3),
(N'Quần Tây & Kaki', 'quan-tay-kaki', N'Quần tây âu lịch lãm, quần kaki năng động', 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=500', 4),
(N'Áo Khoác & Blazer', 'ao-khoac-blazer', N'Áo khoác dù chống nước, áo khoác blazer thanh lịch', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500', 5);

-- 4. Sizes
INSERT INTO Sizes (SizeName, Description) VALUES
('S', N'Size S (45kg - 53kg, 1m50 - 1m60)'),
('M', N'Size M (54kg - 62kg, 1m60 - 1m68)'),
('L', N'Size L (63kg - 70kg, 1m68 - 1m75)'),
('XL', N'Size XL (71kg - 80kg, 1m75 - 1m82)'),
('XXL', N'Size XXL (> 80kg, trên 1m80)');

-- 5. Colors
INSERT INTO Colors (ColorName, ColorHex) VALUES
(N'Đen Classic', '#000000'),
(N'Trắng Tinh Khôi', '#FFFFFF'),
(N'Xanh Navy Trầm', '#000080'),
(N'Xám Khói Hiện Đại', '#708090'),
(N'Màu Be Thanh Lịch', '#F5F5DC');

-- 6. Suppliers
INSERT INTO Suppliers (SupplierName, Phone, Email, Address) VALUES
(N'Xưởng May Gia Công HUIT Fashion', '02838161673', 'huitfashion@gmail.com', N'140 Lê Trọng Tấn, Tân Phú, TP.HCM'),
(N'Công Ty Cổ Phần Dệt May Việt Nam', '02839998888', 'contact@detmayvn.com', N'KCN Tân Bình, Tân Phú, TP.HCM');

-- 7. Products (Các mặt hàng mẫu)
INSERT INTO Products (CategoryId, ProductName, ProductCode, Description, OriginalPrice, Price, DiscountPercent, MainImage, IsFeatured) VALUES
(1, N'Áo Thun Cotton Compact 100% Thoáng Mát Form Regular', 'AT-001', N'Áo thun trơn basic chất liệu 100% Cotton chải kỹ cao cấp, bề mặt mịn màng, thấm hút mồ hôi tốt, độ bền cao qua nhiều lần giặt.', 120000, 189000, 10, 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600', 1),
(1, N'Áo Polo Cổ Bẻ Dệt Phối Bo Phong Cách Hàn Quốc', 'PL-002', N'Chất vải cá sấu mè co giãn 4 chiều mềm mại, phom dáng slim-fit ôm gọn gàng, cổ bẻ thanh lịch thích hợp đi học, đi làm.', 160000, 249000, 0, 'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600', 1),
(2, N'Áo Sơ Mi Trắng Kháng Nhăn Dài Tay Oxford Cao Cấp', 'SM-001', N'Vải Oxford xử lý công nghệ chống nhăn Easy Care, giữ form chuẩn suốt cả ngày dài, đường may kép chắc chắn tỉ mỉ.', 190000, 299000, 15, 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600', 1),
(2, N'Áo Sơ Mi Denim Dáng Rộng Vintage Unisex', 'SM-002', N'Sơ mi chất bò denim mềm mại phong cách streetwear năng động, phù hợp khoác ngoài hoặc mặc đơn.', 210000, 320000, 0, 'https://images.unsplash.com/photo-1589310243389-96a5483213a8?w=600', 1),
(3, N'Quần Jean Nam Ống Suông Slimfit Wash Xanh Phong Cách', 'QJ-001', N'Chất denim co giãn nhẹ 12oz, kỹ thuật wash tạo hiệu ứng cổ điển bắt mắt, tôn dáng chân dài và dễ phối cùng áo thun, sơ mi.', 250000, 399000, 5, 'https://images.unsplash.com/photo-1542272604-780c96856592?w=600', 1),
(3, N'Quần Jean Ống Rộng Wide Leg Unisex Cá Tính', 'QJ-002', N'Form ống rộng thời thượng mang phong cách Y2K, chất jeans dầy dặn không xù lông.', 260000, 420000, 10, 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600', 0),
(4, N'Quần Tây Âu 2 Ly Xếp Dáng Hàn Quốc Sang Trọng', 'QT-001', N'Chất vải tuyết mưa nhập khẩu không nhăn, cạp quần có tăng đơ co giãn thông minh giúp người mặc thoải mái tối đa.', 230000, 350000, 0, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600', 0),
(5, N'Áo Khoác Gió Bomber 2 Lớp Chống Thấm Nước Thời Trang', 'AK-001', N'Chất vải trượt nước dệt mật độ cao cản gió mưa, lót lưới thông thoáng chống bí, khóa zip hợp kim bền bỉ.', 280000, 450000, 20, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600', 1);

-- 8. ProductVariants (Biến thể theo Size & Màu sắc + Quản lý Tồn kho)
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

-- 9. Orders & OrderDetails (Dữ liệu mẫu cho Đơn hàng & Doanh thu của Người 3)
INSERT INTO Orders (UserId, OrderDate, ReceiverName, ReceiverPhone, ShippingAddress, OrderNotes, TotalAmount, PaymentMethod, PaymentStatus, OrderStatus) VALUES
(3, DATEADD(DAY, -3, GETDATE()), N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', N'Giao giờ hành chính giúp mình', 438000, N'COD', N'Đã thanh toán', N'Đã giao'),
(3, DATEADD(DAY, -1, GETDATE()), N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', N'Đóng gói cẩn thận', 749000, N'Chuyển khoản', N'Đã thanh toán', N'Đang giao'),
(4, GETDATE(), N'Lê Thị Ba', '0933445566', N'456 Bạch Đằng, Bình Thạnh, TP. Hồ Chí Minh', N'Giao trước thứ 7', 399000, N'COD', N'Chưa thanh toán', N'Chờ xác nhận');

INSERT INTO OrderDetails (OrderId, VariantId, Quantity, UnitPrice) VALUES
(1, 2, 1, 189000), -- 1 Áo thun đen size M
(1, 6, 1, 249000), -- 1 Áo polo navy size M
(2, 9, 1, 299000), -- 1 Áo sơ mi trắng size M
(2, 20, 1, 450000), -- 1 Áo khoác đen size L
(3, 14, 1, 399000); -- 1 Quần jean navy size L
GO

PRINT N'========================================================================';
PRINT N'ĐÃ TẠO VÀ NẠP DỮ LIỆU THÀNH CÔNG CHO DATABASE [WebQuanLyQuanAoDb]!';
PRINT N'BẢNG ĐÃ TẠO: Roles, Users, Categories, Products, Sizes, Colors, ProductVariants, Orders, OrderDetails, Suppliers, ImportReceipts, ImportReceiptDetails';
PRINT N'========================================================================';
GO
