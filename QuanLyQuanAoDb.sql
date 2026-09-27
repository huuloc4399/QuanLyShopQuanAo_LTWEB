-- =======================================================================
-- ĐỒ ÁN MÔN HỌC: LẬP TRÌNH WEB - TRƯỜNG ĐẠI HỌC CÔNG THƯƠNG TP.HCM (HUIT)
-- ĐỀ TÀI: WEBSITE QUẢN LÝ & KINH DOANH MẶT HÀNG QUẦN ÁO (HUIT UNIFORM & WORKWEAR)
-- THÀNH VIÊN SỐ 1: DATABASE & BACKEND NỀN TẢNG (THEO CHUẨN bosung.md)
-- HỆ QUẢN TRỊ CSDL: MICROSOFT SQL SERVER 2019 / 2022 / LOCALDB
-- TỔNG SỐ BẢNG: 29 BẢNG HOÀN CHỈNH
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

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =======================================================================
-- 2. TẠO CÁC BẢNG CƠ SỞ DỮ LIỆU (29 BẢNG)
-- =======================================================================

-- -----------------------------------------------------------------------
-- BẢNG 1: Roles (Phân quyền vai trò người dùng)
-- -----------------------------------------------------------------------
CREATE TABLE Roles (
    RoleId INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,          -- Admin, Staff, Customer
    Description NVARCHAR(255) NULL,
    IsSystemRole BIT NOT NULL DEFAULT 0             -- 1: Ngăn xóa vai trò hệ thống
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
    Description NVARCHAR(255) NULL,
    IsActive BIT NOT NULL DEFAULT 1
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
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    LastLoginAt DATETIME2 NULL,
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 5: UserRoles (Bảng quan hệ nhiều-nhiều User và Role theo RBAC chuẩn)
-- -----------------------------------------------------------------------
CREATE TABLE UserRoles (
    UserId INT NOT NULL,
    RoleId INT NOT NULL,
    AssignedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    AssignedByUserId INT NULL,
    CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_AssignedBy FOREIGN KEY (AssignedByUserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 6: CustomerAddresses (Sổ địa chỉ giao hàng của khách hàng)
-- -----------------------------------------------------------------------
CREATE TABLE CustomerAddresses (
    AddressId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    ReceiverName NVARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    SpecificAddress NVARCHAR(255) NOT NULL,
    City NVARCHAR(100) NULL,
    District NVARCHAR(100) NULL,
    Ward NVARCHAR(100) NULL,
    IsDefault BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 7: Categories (Danh mục sản phẩm quần áo & đồng phục)
-- -----------------------------------------------------------------------
CREATE TABLE Categories (
    CategoryId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Slug VARCHAR(100) NULL,                         -- ao-thun, ao-so-mi,...
    Description NVARCHAR(500) NULL,
    ImageUrl VARCHAR(255) NULL,
    DisplayOrder INT NOT NULL DEFAULT 0 CHECK (DisplayOrder >= 0),
    IsActive BIT NOT NULL DEFAULT 1
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 8: Products (Mặt hàng quần áo chung)
-- -----------------------------------------------------------------------
CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId INT NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    ProductCode VARCHAR(50) NULL,                   -- AT-001, QJ-002,...
    Description NVARCHAR(MAX) NULL,                 -- Mô tả chi tiết
    OriginalPrice DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (OriginalPrice >= 0), -- Giá nhập vốn
    Price DECIMAL(18,2) NOT NULL CHECK (Price >= 0),                           -- Giá bán niêm yết
    DiscountPercent INT NULL DEFAULT 0 CHECK (DiscountPercent >= 0 AND DiscountPercent <= 100),
    MainImage VARCHAR(255) NULL,                    -- Ảnh chính hiển thị catalog
    IsFeatured BIT NOT NULL DEFAULT 0,              -- 1: Nổi bật trang chủ
    IsActive BIT NOT NULL DEFAULT 1,                -- 1: Đang bán, 0: Ẩn
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 9: Sizes (Kích cỡ quần áo: S, M, L, XL, XXL, 3XL,...)
-- -----------------------------------------------------------------------
CREATE TABLE Sizes (
    SizeId INT IDENTITY(1,1) PRIMARY KEY,
    SizeName VARCHAR(20) NOT NULL UNIQUE,
    Description NVARCHAR(100) NULL
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 10: Colors (Màu sắc quần áo: Đen, Trắng, Be, Xanh Navy,...)
-- -----------------------------------------------------------------------
CREATE TABLE Colors (
    ColorId INT IDENTITY(1,1) PRIMARY KEY,
    ColorName NVARCHAR(50) NOT NULL UNIQUE,
    ColorHex VARCHAR(10) NULL                       -- Mã màu HEX phục vụ Figma & Frontend
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 11: ProductVariants (Biến thể Sản phẩm: Quản lý chính xác Tồn kho)
-- -----------------------------------------------------------------------
CREATE TABLE ProductVariants (
    VariantId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    SizeId INT NOT NULL,
    ColorId INT NOT NULL,
    SKU VARCHAR(50) NULL,                           -- AT01-M-BLK
    StockQuantity INT NOT NULL DEFAULT 0 CHECK (StockQuantity >= 0),
    VariantImage VARCHAR(255) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Variants_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    CONSTRAINT FK_Variants_Sizes FOREIGN KEY (SizeId) REFERENCES Sizes(SizeId),
    CONSTRAINT FK_Variants_Colors FOREIGN KEY (ColorId) REFERENCES Colors(ColorId),
    CONSTRAINT UQ_Product_Size_Color UNIQUE (ProductId, SizeId, ColorId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 12: ProductImages (Bộ sưu tập ảnh chi tiết sản phẩm & biến thể)
-- -----------------------------------------------------------------------
CREATE TABLE ProductImages (
    ProductImageId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    VariantId INT NULL,
    ImageUrl VARCHAR(500) NOT NULL,
    AltText NVARCHAR(200) NULL,
    DisplayOrder INT NOT NULL DEFAULT 0,
    IsPrimary BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_ProductImages_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    CONSTRAINT FK_ProductImages_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 13: Coupons (Mã giảm giá khuyến mãi / Voucher)
-- -----------------------------------------------------------------------
CREATE TABLE Coupons (
    CouponId INT IDENTITY(1,1) PRIMARY KEY,
    CouponCode VARCHAR(50) NOT NULL UNIQUE,
    DiscountType VARCHAR(20) NOT NULL DEFAULT 'PERCENT', -- PERCENT, FIXED_AMOUNT
    DiscountValue DECIMAL(18,2) NOT NULL DEFAULT 0,
    DiscountPercent INT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,2) NULL DEFAULT 0,
    MaxDiscountAmount DECIMAL(18,2) NULL,
    MinOrderAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (MinOrderAmount >= 0),
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    UsageLimit INT NOT NULL DEFAULT 100 CHECK (UsageLimit > 0),
    UsedCount INT NOT NULL DEFAULT 0 CHECK (UsedCount >= 0),
    UsageLimitPerUser INT NOT NULL DEFAULT 1,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_Coupons_Dates CHECK (EndDate > StartDate)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 14: Orders (Đơn đặt hàng & Theo dõi vận hành)
-- -----------------------------------------------------------------------
CREATE TABLE Orders (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
    OrderCode VARCHAR(30) NOT NULL UNIQUE,          -- ORD-2026-0001
    UserId INT NULL,                                -- NULL nếu khách vãng lai
    CouponId INT NULL,                              -- Khóa ngoại Coupon nếu áp mã
    OrderDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ReceiverName NVARCHAR(100) NOT NULL,
    ReceiverPhone VARCHAR(20) NOT NULL,
    ShippingAddress NVARCHAR(255) NOT NULL,
    OrderNotes NVARCHAR(500) NULL,
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (Subtotal >= 0),
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (DiscountAmount >= 0),
    ShippingFee DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (ShippingFee >= 0),
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TaxAmount >= 0),
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0),
    CurrencyCode VARCHAR(10) NOT NULL DEFAULT 'VND',
    CustomerEmail VARCHAR(100) NULL,
    PaymentMethod NVARCHAR(50) NOT NULL DEFAULT N'COD', -- COD, Chuyển khoản, VNPay
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán', -- Chưa thanh toán, Đã thanh toán
    OrderStatus NVARCHAR(50) NOT NULL DEFAULT N'Chờ xác nhận',     -- PENDING, CONFIRMED, PACKING, SHIPPING, COMPLETED, CANCELLED
    ApprovedByUserId INT NULL,
    ApprovedAt DATETIME2 NULL,
    CancelledByUserId INT NULL,
    CancelledAt DATETIME2 NULL,
    CancelReason NVARCHAR(500) NULL,
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL,
    CONSTRAINT FK_Orders_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(CouponId) ON DELETE SET NULL,
    CONSTRAINT FK_Orders_ApprovedBy FOREIGN KEY (ApprovedByUserId) REFERENCES Users(UserId),
    CONSTRAINT FK_Orders_CancelledBy FOREIGN KEY (CancelledByUserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 15: OrderDetails (Chi tiết đơn hàng kèm Snapshot lịch sử)
-- -----------------------------------------------------------------------
CREATE TABLE OrderDetails (
    OrderDetailId INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL CHECK (UnitPrice >= 0),
    TotalPrice AS (Quantity * UnitPrice),
    ProductCodeSnapshot VARCHAR(50) NULL,
    ProductNameSnapshot NVARCHAR(200) NULL,
    SKUSnapshot VARCHAR(50) NULL,
    SizeNameSnapshot VARCHAR(20) NULL,
    ColorNameSnapshot NVARCHAR(50) NULL,
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId),
    CONSTRAINT UQ_OrderDetails_Order_Variant UNIQUE (OrderId, VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 16: OrderStatusHistory (Nhật ký theo dõi lịch sử trạng thái đơn)
-- -----------------------------------------------------------------------
CREATE TABLE OrderStatusHistory (
    OrderStatusHistoryId BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    FromStatus VARCHAR(30) NULL,
    ToStatus VARCHAR(30) NOT NULL,
    ChangedByUserId INT NULL,
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Note NVARCHAR(500) NULL,
    CONSTRAINT FK_StatusHistory_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_StatusHistory_Users FOREIGN KEY (ChangedByUserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 17: InventoryTransactions (Sổ giao dịch kho & Truy vết xuất nhập)
-- -----------------------------------------------------------------------
CREATE TABLE InventoryTransactions (
    InventoryTransactionId BIGINT IDENTITY(1,1) PRIMARY KEY,
    VariantId INT NOT NULL,
    QuantityDelta INT NOT NULL CHECK (QuantityDelta <> 0), -- > 0: Nhập, < 0: Xuất
    TransactionType VARCHAR(30) NOT NULL,                 -- PURCHASE_IN, SALE_OUT, RETURN_IN, ADJUSTMENT, OPENING_BALANCE
    SourceType VARCHAR(30) NOT NULL,                      -- IMPORT_DETAIL, ORDER_DETAIL, RETURN_ITEM, AUDIT
    SourceId BIGINT NOT NULL,
    IdempotencyKey VARCHAR(100) NOT NULL UNIQUE,          -- Chống nhân đôi ghi sổ
    CreatedByUserId INT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Note NVARCHAR(500) NULL,
    CONSTRAINT FK_InvTrans_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId),
    CONSTRAINT FK_InvTrans_Users FOREIGN KEY (CreatedByUserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 18: InventoryReservations (Giữ tồn kho nguyên tử khi đặt hàng)
-- -----------------------------------------------------------------------
CREATE TABLE InventoryReservations (
    ReservationId BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',         -- ACTIVE, CONSUMED, RELEASED, EXPIRED
    ExpiresAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ReleasedAt DATETIME2 NULL,
    CONSTRAINT FK_Reservations_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_Reservations_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId),
    CONSTRAINT UQ_Reservation_Order_Variant UNIQUE (OrderId, VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 19: CouponUsages (Kiểm soát lượt dùng voucher chính xác)
-- -----------------------------------------------------------------------
CREATE TABLE CouponUsages (
    CouponUsageId BIGINT IDENTITY(1,1) PRIMARY KEY,
    CouponId INT NOT NULL,
    OrderId INT NOT NULL UNIQUE,                          -- Mỗi đơn tối đa 1 voucher
    UserId INT NULL,
    SessionId VARCHAR(100) NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (DiscountAmount >= 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'RESERVED',       -- RESERVED, USED, RELEASED
    ReservedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsedAt DATETIME2 NULL,
    ReleasedAt DATETIME2 NULL,
    CONSTRAINT FK_CouponUsages_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(CouponId),
    CONSTRAINT FK_CouponUsages_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_CouponUsages_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 20: Payments (Lịch sử giao dịch thanh toán & Cổng thanh toán)
-- -----------------------------------------------------------------------
CREATE TABLE Payments (
    PaymentId BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    PaymentMethod VARCHAR(30) NOT NULL DEFAULT 'COD',     -- COD, BANK_TRANSFER, VNPAY, MOMO
    Amount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (Amount >= 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'PENDING',        -- PENDING, PAID, FAILED, CANCELLED, REFUNDED, PARTIALLY_REFUNDED
    GatewayTransactionId VARCHAR(100) NULL,
    IdempotencyKey VARCHAR(100) NOT NULL UNIQUE,
    RefundedAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (RefundedAmount >= 0),
    PaidAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 21: Returns (Yêu cầu đổi trả hàng & Khiếu nại khách hàng)
-- -----------------------------------------------------------------------
CREATE TABLE Returns (
    ReturnId INT IDENTITY(1,1) PRIMARY KEY,
    ReturnCode VARCHAR(30) NOT NULL UNIQUE,
    OrderId INT NOT NULL,
    UserId INT NULL,
    Reason NVARCHAR(500) NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'REQUESTED',      -- REQUESTED, APPROVED, REJECTED, RECEIVED, REFUNDING, COMPLETED, CANCELLED
    RequestedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ApprovedByUserId INT NULL,
    ApprovedAt DATETIME2 NULL,
    ReceivedAt DATETIME2 NULL,
    CompletedAt DATETIME2 NULL,
    RefundAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (RefundAmount >= 0),
    CONSTRAINT FK_Returns_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    CONSTRAINT FK_Returns_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_Returns_ApprovedBy FOREIGN KEY (ApprovedByUserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 22: ReturnItems (Chi tiết từng món yêu cầu đổi trả)
-- -----------------------------------------------------------------------
CREATE TABLE ReturnItems (
    ReturnItemId INT IDENTITY(1,1) PRIMARY KEY,
    ReturnId INT NOT NULL,
    OrderDetailId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Resolution VARCHAR(20) NOT NULL DEFAULT 'REFUND',     -- REFUND, EXCHANGE, STORE_CREDIT
    ExchangeVariantId INT NULL,
    ItemCondition VARCHAR(30) NULL,                       -- RESELLABLE, DAMAGED, USED, DEFECTIVE
    RestockQuantity INT NOT NULL DEFAULT 0 CHECK (RestockQuantity >= 0),
    RefundAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (RefundAmount >= 0),
    Note NVARCHAR(500) NULL,
    CONSTRAINT FK_ReturnItems_Returns FOREIGN KEY (ReturnId) REFERENCES Returns(ReturnId) ON DELETE CASCADE,
    CONSTRAINT FK_ReturnItems_OrderDetails FOREIGN KEY (OrderDetailId) REFERENCES OrderDetails(OrderDetailId),
    CONSTRAINT FK_ReturnItems_ExchangeVariant FOREIGN KEY (ExchangeVariantId) REFERENCES ProductVariants(VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 23: Shipments (Quản lý vận đơn & Đơn vị vận chuyển)
-- -----------------------------------------------------------------------
CREATE TABLE Shipments (
    ShipmentId BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    ProviderCode VARCHAR(30) NULL,                        -- GHN, GHTK, VIETTELPOST, INTERNAL
    TrackingCode VARCHAR(100) NULL,
    ShippingFee DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (ShippingFee >= 0),
    Status VARCHAR(30) NOT NULL DEFAULT 'PENDING',        -- PENDING, PICKED_UP, IN_TRANSIT, DELIVERED, FAILED, RETURNED
    ShippedAt DATETIME2 NULL,
    DeliveredAt DATETIME2 NULL,
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 24: Carts (Giỏ hàng người dùng / khách vãng lai)
-- -----------------------------------------------------------------------
CREATE TABLE Carts (
    CartId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NULL,                                      -- NULL nếu là khách vãng lai
    SessionId VARCHAR(100) NULL,                          -- Mã session lưu giỏ tạm
    Status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',         -- ACTIVE, CONVERTED, ABANDONED, EXPIRED
    ExpiresAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Carts_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT CK_Carts_Owner CHECK (
        (UserId IS NOT NULL AND SessionId IS NULL)
     OR (UserId IS NULL AND SessionId IS NOT NULL)
    )
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 25: CartItems (Chi tiết từng món trong giỏ hàng)
-- -----------------------------------------------------------------------
CREATE TABLE CartItems (
    CartItemId INT IDENTITY(1,1) PRIMARY KEY,
    CartId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
    AddedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_CartItems_Carts FOREIGN KEY (CartId) REFERENCES Carts(CartId) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId) ON DELETE CASCADE,
    CONSTRAINT UQ_Cart_Variant UNIQUE (CartId, VariantId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 26: ProductReviews (Đánh giá & Bình luận sản phẩm)
-- -----------------------------------------------------------------------
CREATE TABLE ProductReviews (
    ReviewId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    UserId INT NOT NULL,
    OrderDetailId INT NULL,
    Rating INT NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    Comment NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IsApproved BIT NOT NULL DEFAULT 1,
    ApprovedByUserId INT NULL,
    ApprovedAt DATETIME2 NULL,
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Reviews_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_OrderDetails FOREIGN KEY (OrderDetailId) REFERENCES OrderDetails(OrderDetailId),
    CONSTRAINT FK_Reviews_ApprovedBy FOREIGN KEY (ApprovedByUserId) REFERENCES Users(UserId)
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 27: Suppliers (Nhà cung cấp / Xưởng may gia công)
-- -----------------------------------------------------------------------
CREATE TABLE Suppliers (
    SupplierId INT IDENTITY(1,1) PRIMARY KEY,
    SupplierCode VARCHAR(50) NULL,
    SupplierName NVARCHAR(150) NOT NULL,
    Phone VARCHAR(20) NULL,
    Email VARCHAR(100) NULL,
    Address NVARCHAR(255) NULL,
    IsActive BIT NOT NULL DEFAULT 1
);
GO

-- -----------------------------------------------------------------------
-- BẢNG 28 & 29: ImportReceipts & ImportReceiptDetails (Phiếu nhập kho)
-- -----------------------------------------------------------------------
CREATE TABLE ImportReceipts (
    ImportId INT IDENTITY(1,1) PRIMARY KEY,
    ImportCode VARCHAR(50) NULL,
    SupplierId INT NOT NULL,
    UserId INT NOT NULL,
    ImportDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',          -- DRAFT, POSTED, CANCELLED
    PostedAt DATETIME2 NULL,
    PostedByUserId INT NULL,
    CancelledAt DATETIME2 NULL,
    Notes NVARCHAR(500) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Imports_Suppliers FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
    CONSTRAINT FK_Imports_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_Imports_PostedBy FOREIGN KEY (PostedByUserId) REFERENCES Users(UserId)
);
GO

CREATE TABLE ImportReceiptDetails (
    ImportDetailId INT IDENTITY(1,1) PRIMARY KEY,
    ImportId INT NOT NULL,
    VariantId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    ImportPrice DECIMAL(18,2) NOT NULL CHECK (ImportPrice >= 0),
    TotalPrice AS (Quantity * ImportPrice),
    CONSTRAINT FK_ImportDetails_Imports FOREIGN KEY (ImportId) REFERENCES ImportReceipts(ImportId) ON DELETE CASCADE,
    CONSTRAINT FK_ImportDetails_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId),
    CONSTRAINT UQ_ImportDetails_Import_Variant UNIQUE (ImportId, VariantId)
);
GO

-- =======================================================================
-- 3. CÁC INDEX TOÀN VẸN & TỐI ƯU TRUY VẤN
-- =======================================================================

CREATE UNIQUE INDEX UX_Categories_Slug ON Categories(Slug) WHERE Slug IS NOT NULL;
CREATE UNIQUE INDEX UX_Products_ProductCode_NotNull ON Products(ProductCode) WHERE ProductCode IS NOT NULL;
CREATE UNIQUE INDEX UX_ProductVariants_SKU_NotNull ON ProductVariants(SKU) WHERE SKU IS NOT NULL;
CREATE UNIQUE INDEX UX_Users_Email_NotNull ON Users(Email) WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_CustomerAddresses_OneDefault ON CustomerAddresses(UserId) WHERE IsDefault = 1;
CREATE UNIQUE INDEX UX_Suppliers_SupplierCode_NotNull ON Suppliers(SupplierCode) WHERE SupplierCode IS NOT NULL;
CREATE UNIQUE INDEX UX_ImportReceipts_ImportCode_NotNull ON ImportReceipts(ImportCode) WHERE ImportCode IS NOT NULL;

CREATE INDEX IX_Products_Category_Active ON Products(CategoryId, IsActive);
CREATE INDEX IX_Orders_User_Date ON Orders(UserId, OrderDate DESC);
CREATE INDEX IX_InvTrans_Variant_Date ON InventoryTransactions(VariantId, CreatedAt);
CREATE INDEX IX_Reservations_Variant_Status ON InventoryReservations(VariantId, Status, ExpiresAt);
GO

-- =======================================================================
-- 4. CHÈN DỮ LIỆU MẪU BAN ĐẦU (SEED DATA ĐẦY ĐỦ 29 BẢNG)
-- =======================================================================

-- 1. Roles
INSERT INTO Roles (RoleName, Description, IsSystemRole) VALUES
(N'Admin', N'Quản trị viên toàn quyền hệ thống', 1),
(N'Staff', N'Nhân viên bán hàng và thủ kho', 1),
(N'Customer', N'Khách hàng thành viên', 1);

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
INSERT INTO RolePermissions (RoleId, PermissionId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
(2, 1), (2, 2), (2, 4), (2, 5),
(3, 2);

-- 4. Users (Mật khẩu mặc định: 123456)
INSERT INTO Users (Username, PasswordHash, FullName, Email, PhoneNumber, Address, RoleId) VALUES
('admin', '123456', N'Quản Trị Viên HUIT', 'admin@shopquanao.vn', '0901234567', N'140 Lê Trọng Tấn, P. Tây Thạnh, Q. Tân Phú, TP.HCM', 1),
('nhanvien', '123456', N'Nguyễn Văn Quản Kho', 'kho@shopquanao.vn', '0912345678', N'Tân Phú, TP. Hồ Chí Minh', 2),
('khachhang', '123456', N'Trần Thị Mai', 'mai.tran@gmail.com', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', 3),
('lethiba', '123456', N'Lê Thị Ba', 'ba.le@gmail.com', '0933445566', N'456 Bạch Đằng, Bình Thạnh, TP. Hồ Chí Minh', 3);

-- 5. UserRoles
INSERT INTO UserRoles (UserId, RoleId) VALUES
(1, 1), (2, 2), (3, 3), (4, 3);

-- 6. CustomerAddresses
INSERT INTO CustomerAddresses (UserId, ReceiverName, PhoneNumber, SpecificAddress, City, District, Ward, IsDefault) VALUES
(3, N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi', N'TP. Hồ Chí Minh', N'Quận 1', N'Phường Bến Thành', 1),
(3, N'Trần Thị Mai (Cơ quan)', '0987654321', N'Tòa nhà Bitexco, Số 2 Hải Triều', N'TP. Hồ Chí Minh', N'Quận 1', N'Phường Bến Nghé', 0),
(4, N'Lê Thị Ba', '0933445566', N'456 Bạch Đằng', N'TP. Hồ Chí Minh', N'Bình Thạnh', N'Phường 14', 1);

-- 7. Categories
INSERT INTO Categories (CategoryName, Slug, Description, ImageUrl, DisplayOrder) VALUES
(N'Áo Thun & Polo Doanh Nghiệp', 'ao-thun-polo', N'Các mẫu áo thun cotton, áo polo thời trang cao cấp', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500', 1),
(N'Áo Sơ Mi & Vest Công Sở', 'ao-so-mi-cong-so', N'Áo sơ mi công sở, vest cao cấp phong cách hiện đại', 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500', 2),
(N'Đồ Bảo Hộ & Áo Phản Quang', 'do-bao-ho-lao-dong', N'Trang phục bảo hộ lao động đạt chuẩn kiểm định an toàn kỹ thuật', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500', 3),
(N'Đồng Phục Nhà Hàng & Cafe', 'dong-phuc-nha-hang-cafe', N'Tạp dề, áo bếp và trang phục phục vụ bàn chuyên nghiệp', 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500', 4),
(N'Áo Khoác Gió & Mũ Nón', 'ao-khoac-gio-mu-non', N'Áo khoác gió 2 lớp cản mưa gió và mũ nón thương hiệu', 'https://images.unsplash.com/photo-1544441893-675973e31985?w=500', 5);

-- 8. Sizes
INSERT INTO Sizes (SizeName, Description) VALUES
('S', N'Size S (45kg - 53kg, 1m50 - 1m60)'),
('M', N'Size M (54kg - 62kg, 1m60 - 1m68)'),
('L', N'Size L (63kg - 70kg, 1m68 - 1m75)'),
('XL', N'Size XL (71kg - 80kg, 1m75 - 1m82)'),
('XXL', N'Size XXL (78kg - 88kg, 1m78 - 1m85)'),
('3XL', N'Size 3XL (> 88kg, trên 1m80)');

-- 9. Colors
INSERT INTO Colors (ColorName, ColorHex) VALUES
(N'Đen Classic', '#000000'),
(N'Trắng Tinh Khôi', '#FFFFFF'),
(N'Xanh Navy Trầm', '#000080'),
(N'Xám Khói Hiện Đại', '#708090'),
(N'Màu Be Thanh Lịch', '#F5F5DC'),
(N'Cam Thương Hiệu', '#E67E22');

-- 10. Suppliers
INSERT INTO Suppliers (SupplierCode, SupplierName, Phone, Email, Address) VALUES
('SUP-001', N'Xưởng May Gia Công HUIT Uniform', '02838161673', 'huitfashion@gmail.com', N'140 Lê Trọng Tấn, Tân Phú, TP.HCM'),
('SUP-002', N'Công Ty Cổ Phần Dệt May Việt Nam', '02839998888', 'contact@detmayvn.com', N'KCN Tân Bình, Tân Phú, TP.HCM');

-- 11. Products
INSERT INTO Products (CategoryId, ProductName, ProductCode, Description, OriginalPrice, Price, DiscountPercent, MainImage, IsFeatured) VALUES
(1, N'Áo Polo Cổ Bẻ Dệt Phối Bo Doanh Nghiệp', 'PL-002', N'Vải cá sấu poly thái hoặc CVC cao cấp, giữ form dáng chuẩn, thêu logo ngực độ nét cao, thoáng mát suốt ngày làm việc.', 120000, 189000, 10, 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600', 1),
(1, N'Áo Thun Cổ Tròn Sự Kiện Team Building', 'AT-001', N'Vải cotton 100% mềm mịn, co giãn 4 chiều, thấm hút mồ hôi tối đa, chuyên may áo thun sự kiện công ty.', 160000, 249000, 0, 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600', 1),
(2, N'Áo Sơ Mi Trắng Kháng Nhăn Dài Tay Oxford', 'SM-001', N'Vải Kate Ý cao cấp, bề mặt sáng mịn, chống nhăn tự nhiên, phom dáng Slimfit & Regular chuẩn công sở hiện đại.', 190000, 299000, 15, 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600', 1),
(4, N'Áo Sơ Mi Denim Dáng Rộng Vintage Cho Quán Cafe', 'SM-002', N'Vải denim cotton mềm mát, phong cách năng động hiện đại cho nhân viên phục vụ, pha chế quán cafe.', 210000, 320000, 0, 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600', 1),
(3, N'Quần Kaki Kỹ Thuật Túi Hộp Bảo Hộ Lao Động', 'QJ-001', N'Vải Kaki Pangrim Hàn Quốc dày dặn chống rách, thiết kế nhiều túi hộp tiện dụng cho kỹ sư công trường.', 250000, 399000, 5, 'https://images.unsplash.com/photo-1517445312882-bc9910d016b7?w=600', 1),
(2, N'Quần Tây Âu 2 Ly Xếp Dáng Hàn Quốc Sang Trọng', 'QJ-002', N'Vải tuyết mưa co giãn nhẹ, bề mặt không bám bụi, giữ nếp ly phẳng phiu suốt cả ngày làm việc tại văn phòng.', 260000, 420000, 10, 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=600', 0),
(3, N'Áo Gile Phản Quang 3M Kỹ Sư Công Trình TCVN', 'QT-001', N'Dải phản quang 3M siêu sáng ban đêm, may kèm túi đựng bộ đàm và bút, đạt chuẩn kiểm định an toàn lao động.', 230000, 350000, 0, 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600', 1),
(5, N'Áo Khoác Gió Bomber 2 Lớp Chống Thấm & Cản Gió', 'AK-001', N'Vải dù micro 2 lớp chống gió, trượt nước hiệu quả, bo thun cổ tay và gấu áo cản gió lạnh cho nhân viên giao hàng.', 280000, 450000, 20, 'https://images.unsplash.com/photo-1544441893-675973e31985?w=600', 1);

-- 12. ProductVariants
INSERT INTO ProductVariants (ProductId, SizeId, ColorId, SKU, StockQuantity) VALUES
(1, 1, 1, 'PL002-S-BLK', 20),
(1, 2, 1, 'PL002-M-BLK', 35),
(1, 3, 1, 'PL002-L-BLK', 40),
(1, 2, 2, 'PL002-M-WHT', 25),
(2, 2, 3, 'AT001-M-NAVY', 15),
(2, 3, 3, 'AT001-L-NAVY', 25),
(2, 4, 3, 'AT001-XL-NAVY', 10),
(3, 2, 2, 'SM001-M-WHT', 45),
(3, 3, 2, 'SM001-L-WHT', 50),
(3, 4, 2, 'SM001-XL-WHT', 20),
(4, 2, 3, 'SM002-M-NAVY', 15),
(4, 3, 3, 'SM002-L-NAVY', 20),
(5, 2, 3, 'QJ001-M-NAVY', 12),
(5, 3, 3, 'QJ001-L-NAVY', 28),
(6, 2, 1, 'QJ002-M-BLK', 30),
(6, 3, 1, 'QJ002-L-BLK', 35),
(7, 2, 6, 'QT001-M-ORG', 25),
(7, 3, 6, 'QT001-L-ORG', 30),
(8, 3, 4, 'AK001-L-GRY', 18),
(8, 4, 4, 'AK001-XL-GRY', 12);

-- 13. ProductImages
INSERT INTO ProductImages (ProductId, ImageUrl, AltText, DisplayOrder, IsPrimary)
SELECT ProductId, MainImage, ProductName, 1, 1 FROM Products;

-- 14. Coupons
INSERT INTO Coupons (CouponCode, DiscountType, DiscountValue, DiscountPercent, DiscountAmount, MinOrderAmount, StartDate, EndDate, UsageLimit, UsedCount, IsActive) VALUES
('HUIT2026', 'PERCENT', 15, 15, 0, 300000, '2026-01-01', '2026-12-31', 500, 12, 1),
('FASHION50K', 'FIXED_AMOUNT', 50000, 0, 50000, 400000, '2026-01-01', '2026-12-31', 200, 8, 1),
('FREESHIP', 'FIXED_AMOUNT', 30000, 0, 30000, 200000, '2026-01-01', '2026-12-31', 1000, 45, 1);

-- 15. Orders
INSERT INTO Orders (OrderCode, UserId, CouponId, OrderDate, ReceiverName, ReceiverPhone, ShippingAddress, OrderNotes, Subtotal, DiscountAmount, ShippingFee, TaxAmount, TotalAmount, PaymentMethod, PaymentStatus, OrderStatus) VALUES
('ORD-2026-0001', 3, 1, DATEADD(DAY, -3, GETDATE()), N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', N'Giao giờ hành chính', 438000, 50000, 0, 0, 388000, N'COD', N'Đã thanh toán', N'COMPLETED'),
('ORD-2026-0002', 3, NULL, DATEADD(DAY, -1, GETDATE()), N'Trần Thị Mai', '0987654321', N'123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh', N'Đóng gói cẩn thận', 749000, 0, 0, 0, 749000, N'Chuyển khoản', N'Đã thanh toán', N'SHIPPING'),
('ORD-2026-0003', 4, NULL, GETDATE(), N'Lê Thị Ba', '0933445566', N'456 Bạch Đằng, Bình Thạnh, TP. Hồ Chí Minh', N'Giao trước thứ 7', 399000, 0, 0, 0, 399000, N'COD', N'Chưa thanh toán', N'PENDING_CONFIRMATION');

-- 16. OrderDetails kèm Snapshots
INSERT INTO OrderDetails (OrderId, VariantId, Quantity, UnitPrice, ProductCodeSnapshot, ProductNameSnapshot, SKUSnapshot, SizeNameSnapshot, ColorNameSnapshot) VALUES
(1, 2, 1, 189000, 'PL-002', N'Áo Polo Cổ Bẻ Dệt Phối Bo Doanh Nghiệp', 'PL002-M-BLK', 'M', N'Đen Classic'),
(1, 6, 1, 249000, 'AT-001', N'Áo Thun Cổ Tròn Sự Kiện Team Building', 'AT001-L-NAVY', 'L', N'Xanh Navy Trầm'),
(2, 8, 1, 299000, 'SM-001', N'Áo Sơ Mi Trắng Kháng Nhăn Dài Tay Oxford', 'SM001-M-WHT', 'M', N'Trắng Tinh Khôi'),
(2, 20, 1, 450000, 'AK-001', N'Áo Khoác Gió Bomber 2 Lớp Chống Thấm & Cản Gió', 'AK001-XL-GRY', 'XL', N'Xám Khói Hiện Đại'),
(3, 13, 1, 399000, 'QJ-001', N'Quần Kaki Kỹ Thuật Túi Hộp Bảo Hộ Lao Động', 'QJ001-M-NAVY', 'M', N'Xanh Navy Trầm');

-- 17. InventoryTransactions (Khởi tạo số dư sổ kho)
INSERT INTO InventoryTransactions (VariantId, QuantityDelta, TransactionType, SourceType, SourceId, IdempotencyKey, Note)
SELECT 
    VariantId, 
    StockQuantity, 
    'OPENING_BALANCE', 
    'SYSTEM_INIT', 
    VariantId, 
    'INIT_VAR_' + CAST(VariantId AS VARCHAR(10)),
    N'Khởi tạo số dư sổ kho ban đầu'
FROM ProductVariants;

-- 18. CouponUsages
INSERT INTO CouponUsages (CouponId, OrderId, UserId, DiscountAmount, Status, ReservedAt, UsedAt) VALUES
(1, 1, 3, 50000, 'USED', DATEADD(DAY, -3, GETDATE()), DATEADD(DAY, -3, GETDATE()));

-- 19. Payments
INSERT INTO Payments (OrderId, PaymentMethod, Amount, Status, IdempotencyKey, PaidAt) VALUES
(1, 'COD', 388000, 'PAID', 'PAY_ORD_0001', DATEADD(DAY, -3, GETDATE())),
(2, 'BANK_TRANSFER', 749000, 'PAID', 'PAY_ORD_0002', DATEADD(DAY, -1, GETDATE())),
(3, 'COD', 399000, 'PENDING', 'PAY_ORD_0003', NULL);

-- 20. OrderStatusHistory
INSERT INTO OrderStatusHistory (OrderId, FromStatus, ToStatus, ChangedAt, Note) VALUES
(1, NULL, 'COMPLETED', DATEADD(DAY, -3, GETDATE()), N'Đơn hàng giao thành công và thu tiền'),
(2, NULL, 'SHIPPING', DATEADD(DAY, -1, GETDATE()), N'Đã bàn giao đơn vị vận chuyển GHTK'),
(3, NULL, 'PENDING_CONFIRMATION', GETDATE(), N'Đơn đặt hàng mới từ khách');

-- 21. Shipments
INSERT INTO Shipments (OrderId, ProviderCode, TrackingCode, ShippingFee, Status, ShippedAt) VALUES
(2, 'GHTK', 'GHTK-HUIT-889922', 30000, 'IN_TRANSIT', DATEADD(DAY, -1, GETDATE()));

-- 22. Carts & CartItems
INSERT INTO Carts (UserId, SessionId, Status, CreatedAt, UpdatedAt) VALUES
(3, NULL, 'ACTIVE', GETDATE(), GETDATE()),
(NULL, 'session_guest_anonymous', 'ACTIVE', GETDATE(), GETDATE());

INSERT INTO CartItems (CartId, VariantId, Quantity) VALUES
(1, 1, 2),
(1, 7, 1),
(2, 9, 1);

-- 23. ProductReviews
INSERT INTO ProductReviews (ProductId, UserId, OrderDetailId, Rating, Comment, IsApproved) VALUES
(1, 3, 1, 5, N'Áo polo mặc rất mát, chất vải cá sấu dày dặn và co giãn thoải mái, form đẹp!', 1),
(3, 3, 3, 5, N'Sơ mi chống nhăn rất tốt, đi làm cả ngày không bị nhàu vải.', 1);
GO

PRINT N'========================================================================';
PRINT N'ĐÃ TẠO DATABASE [WebQuanLyQuanAoDb] VỚI 29 BẢNG HOÀN CHỈNH THEO bosung.md!';
PRINT N'========================================================================';
GO
