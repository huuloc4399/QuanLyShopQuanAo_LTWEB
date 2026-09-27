-- =======================================================================
-- KỊCH BẢN NÂNG CẤP TOÀN DIỆN CSDL WebQuanLyQuanAoDb THEO bosung.md
-- BỔ SUNG 10 BẢNG MỚI & HOÀN THIỆN RÀNG BUỘC CHO 19 BẢNG HIỆN HỮU
-- =======================================================================

USE WebQuanLyQuanAoDb;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'>>> BẮT ĐẦU NÂNG CẤP CƠ SỞ DỮ LIỆU THEO TÀI LIỆU bosung.md...';
GO

-- =======================================================================
-- PHẦN 1: BỔ SUNG CỘT VÀ RÀNG BUỘC CHO 19 BẢNG HIỆN HỮU
-- =======================================================================

-- 1. Roles
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Roles') AND name = 'IsSystemRole')
BEGIN
    ALTER TABLE Roles ADD IsSystemRole BIT NOT NULL CONSTRAINT DF_Roles_IsSystemRole DEFAULT 0;
END
GO

-- 2. Permissions
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Permissions') AND name = 'IsActive')
BEGIN
    ALTER TABLE Permissions ADD IsActive BIT NOT NULL CONSTRAINT DF_Permissions_IsActive DEFAULT 1;
END
GO

-- 3. Users
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE Users ADD UpdatedAt DATETIME2 NULL;
    ALTER TABLE Users ADD LastLoginAt DATETIME2 NULL;
END
GO

-- 4. CustomerAddresses
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('CustomerAddresses') AND name = 'District')
BEGIN
    ALTER TABLE CustomerAddresses ADD District NVARCHAR(100) NULL;
    ALTER TABLE CustomerAddresses ADD Ward NVARCHAR(100) NULL;
    ALTER TABLE CustomerAddresses ADD IsActive BIT NOT NULL CONSTRAINT DF_CustomerAddresses_IsActive DEFAULT 1;
    ALTER TABLE CustomerAddresses ADD CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_CustomerAddresses_CreatedAt DEFAULT SYSDATETIME();
    ALTER TABLE CustomerAddresses ADD UpdatedAt DATETIME2 NULL;
END
GO

-- 5. Categories
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_Categories_Slug' AND object_id = OBJECT_ID('Categories'))
BEGIN
    CREATE UNIQUE INDEX UX_Categories_Slug ON Categories(Slug) WHERE Slug IS NOT NULL;
END
GO

-- 6. Products
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE Products ADD UpdatedAt DATETIME2 NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Products_Price')
BEGIN
    ALTER TABLE Products ADD CONSTRAINT CK_Products_Price CHECK (Price >= 0);
END
GO

-- 7. ProductVariants
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProductVariants') AND name = 'IsActive')
BEGIN
    ALTER TABLE ProductVariants ADD IsActive BIT NOT NULL CONSTRAINT DF_ProductVariants_IsActive DEFAULT 1;
    ALTER TABLE ProductVariants ADD CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ProductVariants_CreatedAt DEFAULT SYSDATETIME();
    ALTER TABLE ProductVariants ADD UpdatedAt DATETIME2 NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_ProductVariants_StockQuantity')
BEGIN
    ALTER TABLE ProductVariants ADD CONSTRAINT CK_ProductVariants_StockQuantity CHECK (StockQuantity >= 0);
END
GO

-- 8. Carts
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Carts') AND name = 'Status')
BEGIN
    ALTER TABLE Carts ADD Status VARCHAR(20) NOT NULL CONSTRAINT DF_Carts_Status DEFAULT 'ACTIVE';
    ALTER TABLE Carts ADD ExpiresAt DATETIME2 NULL;
END
GO

-- 9. CartItems
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('CartItems') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE CartItems ADD UpdatedAt DATETIME2 NULL;
END
GO

-- 10. Coupons
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Coupons') AND name = 'DiscountType')
BEGIN
    ALTER TABLE Coupons ADD DiscountType VARCHAR(20) NOT NULL CONSTRAINT DF_Coupons_DiscountType DEFAULT 'PERCENT';
    ALTER TABLE Coupons ADD DiscountValue DECIMAL(18,2) NOT NULL CONSTRAINT DF_Coupons_DiscountValue DEFAULT 0;
    ALTER TABLE Coupons ADD MaxDiscountAmount DECIMAL(18,2) NULL;
    ALTER TABLE Coupons ADD UsageLimitPerUser INT NOT NULL CONSTRAINT DF_Coupons_UsageLimitPerUser DEFAULT 1;
END
GO

-- 11. Orders
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'OrderCode')
BEGIN
    ALTER TABLE Orders ADD OrderCode VARCHAR(30) NULL;
    ALTER TABLE Orders ADD Subtotal DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_Subtotal DEFAULT 0;
    ALTER TABLE Orders ADD ShippingFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_ShippingFee DEFAULT 0;
    ALTER TABLE Orders ADD TaxAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_TaxAmount DEFAULT 0;
    ALTER TABLE Orders ADD CurrencyCode VARCHAR(10) NOT NULL CONSTRAINT DF_Orders_CurrencyCode DEFAULT 'VND';
    ALTER TABLE Orders ADD CustomerEmail VARCHAR(100) NULL;
    ALTER TABLE Orders ADD ApprovedByUserId INT NULL;
    ALTER TABLE Orders ADD ApprovedAt DATETIME2 NULL;
    ALTER TABLE Orders ADD CancelledByUserId INT NULL;
    ALTER TABLE Orders ADD CancelledAt DATETIME2 NULL;
    ALTER TABLE Orders ADD CancelReason NVARCHAR(500) NULL;
    ALTER TABLE Orders ADD UpdatedAt DATETIME2 NULL;
END
GO

-- Cập nhật mã đơn OrderCode và Subtotal cho các đơn hàng mẫu hiện tại
UPDATE Orders SET OrderCode = 'ORD-2026-' + RIGHT('0000' + CAST(OrderId AS VARCHAR(10)), 4) WHERE OrderCode IS NULL;
UPDATE Orders SET Subtotal = TotalAmount + DiscountAmount WHERE Subtotal = 0;
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'OrderCode' AND is_nullable = 1)
BEGIN
    ALTER TABLE Orders ALTER COLUMN OrderCode VARCHAR(30) NOT NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_Orders_OrderCode' AND object_id = OBJECT_ID('Orders'))
BEGIN
    CREATE UNIQUE INDEX UX_Orders_OrderCode ON Orders(OrderCode);
END
GO

-- 12. OrderDetails Snapshots
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('OrderDetails') AND name = 'ProductCodeSnapshot')
BEGIN
    ALTER TABLE OrderDetails ADD ProductCodeSnapshot VARCHAR(50) NULL;
    ALTER TABLE OrderDetails ADD ProductNameSnapshot NVARCHAR(200) NULL;
    ALTER TABLE OrderDetails ADD SKUSnapshot VARCHAR(50) NULL;
    ALTER TABLE OrderDetails ADD SizeNameSnapshot VARCHAR(20) NULL;
    ALTER TABLE OrderDetails ADD ColorNameSnapshot NVARCHAR(50) NULL;
END
GO

-- Điền dữ liệu snapshot cho các đơn hàng mẫu
UPDATE od
SET 
    od.ProductCodeSnapshot = p.ProductCode,
    od.ProductNameSnapshot = p.ProductName,
    od.SKUSnapshot = pv.SKU,
    od.SizeNameSnapshot = s.SizeName,
    od.ColorNameSnapshot = c.ColorName
FROM OrderDetails od
JOIN ProductVariants pv ON od.VariantId = pv.VariantId
JOIN Products p ON pv.ProductId = p.ProductId
JOIN Sizes s ON pv.SizeId = s.SizeId
JOIN Colors c ON pv.ColorId = c.ColorId
WHERE od.ProductNameSnapshot IS NULL;
GO

-- 13. ProductReviews
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProductReviews') AND name = 'OrderDetailId')
BEGIN
    ALTER TABLE ProductReviews ADD OrderDetailId INT NULL;
    ALTER TABLE ProductReviews ADD ApprovedByUserId INT NULL;
    ALTER TABLE ProductReviews ADD ApprovedAt DATETIME2 NULL;
    ALTER TABLE ProductReviews ADD UpdatedAt DATETIME2 NULL;
END
GO

-- 14. Suppliers
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Suppliers') AND name = 'SupplierCode')
BEGIN
    ALTER TABLE Suppliers ADD SupplierCode VARCHAR(50) NULL;
    ALTER TABLE Suppliers ADD IsActive BIT NOT NULL CONSTRAINT DF_Suppliers_IsActive DEFAULT 1;
END
GO
UPDATE Suppliers SET SupplierCode = 'SUP-' + RIGHT('000' + CAST(SupplierId AS VARCHAR(10)), 3) WHERE SupplierCode IS NULL;
GO

-- 15. ImportReceipts
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ImportReceipts') AND name = 'ImportCode')
BEGIN
    ALTER TABLE ImportReceipts ADD ImportCode VARCHAR(50) NULL;
    ALTER TABLE ImportReceipts ADD Status VARCHAR(20) NOT NULL CONSTRAINT DF_ImportReceipts_Status DEFAULT 'DRAFT';
    ALTER TABLE ImportReceipts ADD PostedAt DATETIME2 NULL;
    ALTER TABLE ImportReceipts ADD PostedByUserId INT NULL;
    ALTER TABLE ImportReceipts ADD CancelledAt DATETIME2 NULL;
    ALTER TABLE ImportReceipts ADD CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ImportReceipts_CreatedAt DEFAULT SYSDATETIME();
END
GO
UPDATE ImportReceipts SET ImportCode = 'IMP-2026-' + RIGHT('0000' + CAST(ImportId AS VARCHAR(10)), 4) WHERE ImportCode IS NULL;
GO


-- =======================================================================
-- PHẦN 2: TẠO 10 BẢNG BỔ SUNG MỚI THEO bosung.md
-- =======================================================================

-- -----------------------------------------------------------------------
-- BẢNG 20: UserRoles (Bảng liên kết Nhiều-Nhiều giữa Users và Roles)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRoles')
BEGIN
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

    -- Di chuyển dữ liệu RoleId hiện có từ Users sang UserRoles
    INSERT INTO UserRoles (UserId, RoleId)
    SELECT UserId, RoleId FROM Users WHERE RoleId IS NOT NULL;
    PRINT N'  -> Đã tạo bảng UserRoles và đồng bộ vai trò ban đầu.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 21: ProductImages (Bộ sưu tập ảnh chi tiết sản phẩm & biến thể)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductImages')
BEGIN
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

    -- Di chuyển ảnh chính MainImage của Products sang ProductImages
    INSERT INTO ProductImages (ProductId, ImageUrl, AltText, DisplayOrder, IsPrimary)
    SELECT ProductId, MainImage, ProductName, 1, 1 FROM Products WHERE MainImage IS NOT NULL;
    PRINT N'  -> Đã tạo bảng ProductImages.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 22: InventoryTransactions (Sổ giao dịch kho & Truy vết xuất nhập)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InventoryTransactions')
BEGIN
    CREATE TABLE InventoryTransactions (
        InventoryTransactionId BIGINT IDENTITY(1,1) PRIMARY KEY,
        VariantId INT NOT NULL,
        QuantityDelta INT NOT NULL,                     -- > 0: Nhập, < 0: Xuất
        TransactionType VARCHAR(30) NOT NULL,           -- PURCHASE_IN, SALE_OUT, RETURN_IN, ADJUSTMENT, SALE_REVERSAL, OPENING_BALANCE
        SourceType VARCHAR(30) NOT NULL,                -- IMPORT_DETAIL, ORDER_DETAIL, RETURN_ITEM, AUDIT
        SourceId BIGINT NOT NULL,
        IdempotencyKey VARCHAR(100) NOT NULL UNIQUE,    -- Chống nhân đôi ghi sổ
        CreatedByUserId INT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        Note NVARCHAR(500) NULL,
        CONSTRAINT FK_InvTrans_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId),
        CONSTRAINT FK_InvTrans_Users FOREIGN KEY (CreatedByUserId) REFERENCES Users(UserId),
        CONSTRAINT CK_InvTrans_QuantityDelta CHECK (QuantityDelta <> 0)
    );

    -- Khởi tạo số dư đầu kỳ (OPENING_BALANCE) từ tồn kho hiện tại
    INSERT INTO InventoryTransactions (VariantId, QuantityDelta, TransactionType, SourceType, SourceId, IdempotencyKey, Note)
    SELECT 
        VariantId, 
        StockQuantity, 
        'OPENING_BALANCE', 
        'SYSTEM_INIT', 
        VariantId, 
        'INIT_VAR_' + CAST(VariantId AS VARCHAR(10)),
        N'Số dư tồn kho khởi tạo ban đầu hệ thống'
    FROM ProductVariants
    WHERE StockQuantity > 0;

    PRINT N'  -> Đã tạo bảng InventoryTransactions và khởi tạo số dư đầu kỳ.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 23: InventoryReservations (Giữ tồn kho nguyên tử khi đặt hàng)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InventoryReservations')
BEGIN
    CREATE TABLE InventoryReservations (
        ReservationId BIGINT IDENTITY(1,1) PRIMARY KEY,
        OrderId INT NOT NULL,
        VariantId INT NOT NULL,
        Quantity INT NOT NULL CHECK (Quantity > 0),
        Status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',   -- ACTIVE, CONSUMED, RELEASED, EXPIRED
        ExpiresAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        ReleasedAt DATETIME2 NULL,
        CONSTRAINT FK_Reservations_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
        CONSTRAINT FK_Reservations_Variants FOREIGN KEY (VariantId) REFERENCES ProductVariants(VariantId),
        CONSTRAINT UQ_Reservation_Order_Variant UNIQUE (OrderId, VariantId)
    );
    PRINT N'  -> Đã tạo bảng InventoryReservations.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 24: CouponUsages (Kiểm soát lượt dùng voucher chính xác)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CouponUsages')
BEGIN
    CREATE TABLE CouponUsages (
        CouponUsageId BIGINT IDENTITY(1,1) PRIMARY KEY,
        CouponId INT NOT NULL,
        OrderId INT NOT NULL UNIQUE,                    -- Mỗi đơn tối đa 1 voucher
        UserId INT NULL,
        SessionId VARCHAR(100) NULL,
        DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        Status VARCHAR(20) NOT NULL DEFAULT 'RESERVED', -- RESERVED, USED, RELEASED
        ReservedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        UsedAt DATETIME2 NULL,
        ReleasedAt DATETIME2 NULL,
        CONSTRAINT FK_CouponUsages_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(CouponId),
        CONSTRAINT FK_CouponUsages_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
        CONSTRAINT FK_CouponUsages_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
    );

    -- Di chuyển các đơn hàng đã dùng voucher sang CouponUsages
    INSERT INTO CouponUsages (CouponId, OrderId, UserId, DiscountAmount, Status, ReservedAt, UsedAt)
    SELECT CouponId, OrderId, UserId, DiscountAmount, 'USED', OrderDate, OrderDate
    FROM Orders
    WHERE CouponId IS NOT NULL;

    PRINT N'  -> Đã tạo bảng CouponUsages.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 25: Payments (Lịch sử giao dịch thanh toán & Cổng thanh toán)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Payments')
BEGIN
    CREATE TABLE Payments (
        PaymentId BIGINT IDENTITY(1,1) PRIMARY KEY,
        OrderId INT NOT NULL,
        PaymentMethod VARCHAR(30) NOT NULL DEFAULT 'COD',
        Amount DECIMAL(18,2) NOT NULL DEFAULT 0,
        Status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, PAID, FAILED, CANCELLED, REFUNDED, PARTIALLY_REFUNDED
        GatewayTransactionId VARCHAR(100) NULL,
        IdempotencyKey VARCHAR(100) NOT NULL UNIQUE,
        RefundedAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        PaidAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE
    );

    -- Khởi tạo bản ghi thanh toán cho các đơn hàng hiện có
    INSERT INTO Payments (OrderId, PaymentMethod, Amount, Status, IdempotencyKey, PaidAt)
    SELECT 
        OrderId,
        CASE WHEN PaymentMethod = N'Chuyển khoản' THEN 'BANK_TRANSFER' ELSE 'COD' END,
        TotalAmount,
        CASE WHEN PaymentStatus = N'Đã thanh toán' THEN 'PAID' ELSE 'PENDING' END,
        'INIT_PAY_ORD_' + CAST(OrderId AS VARCHAR(10)),
        CASE WHEN PaymentStatus = N'Đã thanh toán' THEN OrderDate ELSE NULL END
    FROM Orders;

    PRINT N'  -> Đã tạo bảng Payments.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 26: OrderStatusHistory (Nhật ký theo dõi lịch sử trạng thái đơn)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrderStatusHistory')
BEGIN
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

    -- Ghi mốc trạng thái ban đầu cho các đơn mẫu
    INSERT INTO OrderStatusHistory (OrderId, FromStatus, ToStatus, ChangedAt, Note)
    SELECT OrderId, NULL, OrderStatus, OrderDate, N'Tạo đơn hàng ban đầu'
    FROM Orders;

    PRINT N'  -> Đã tạo bảng OrderStatusHistory.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 27: Returns (Yêu cầu đổi trả hàng & Khiếu nại khách hàng)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Returns')
BEGIN
    CREATE TABLE Returns (
        ReturnId INT IDENTITY(1,1) PRIMARY KEY,
        ReturnCode VARCHAR(30) NOT NULL UNIQUE,
        OrderId INT NOT NULL,
        UserId INT NULL,
        Reason NVARCHAR(500) NOT NULL,
        Status VARCHAR(30) NOT NULL DEFAULT 'REQUESTED', -- REQUESTED, APPROVED, REJECTED, RECEIVED, REFUNDING, COMPLETED, CANCELLED
        RequestedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        ApprovedByUserId INT NULL,
        ApprovedAt DATETIME2 NULL,
        ReceivedAt DATETIME2 NULL,
        CompletedAt DATETIME2 NULL,
        RefundAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        CONSTRAINT FK_Returns_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
        CONSTRAINT FK_Returns_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
        CONSTRAINT FK_Returns_ApprovedBy FOREIGN KEY (ApprovedByUserId) REFERENCES Users(UserId)
    );
    PRINT N'  -> Đã tạo bảng Returns.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 28: ReturnItems (Chi tiết từng món yêu cầu đổi trả)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReturnItems')
BEGIN
    CREATE TABLE ReturnItems (
        ReturnItemId INT IDENTITY(1,1) PRIMARY KEY,
        ReturnId INT NOT NULL,
        OrderDetailId INT NOT NULL,
        Quantity INT NOT NULL CHECK (Quantity > 0),
        Resolution VARCHAR(20) NOT NULL DEFAULT 'REFUND', -- REFUND, EXCHANGE, STORE_CREDIT
        ExchangeVariantId INT NULL,
        ItemCondition VARCHAR(30) NULL,                 -- RESELLABLE, DAMAGED, USED, DEFECTIVE
        RestockQuantity INT NOT NULL DEFAULT 0,
        RefundAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        Note NVARCHAR(500) NULL,
        CONSTRAINT FK_ReturnItems_Returns FOREIGN KEY (ReturnId) REFERENCES Returns(ReturnId) ON DELETE CASCADE,
        CONSTRAINT FK_ReturnItems_OrderDetails FOREIGN KEY (OrderDetailId) REFERENCES OrderDetails(OrderDetailId),
        CONSTRAINT FK_ReturnItems_ExchangeVariant FOREIGN KEY (ExchangeVariantId) REFERENCES ProductVariants(VariantId)
    );
    PRINT N'  -> Đã tạo bảng ReturnItems.';
END
GO

-- -----------------------------------------------------------------------
-- BẢNG 29: Shipments (Quản lý vận đơn & Đơn vị vận chuyển)
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Shipments')
BEGIN
    CREATE TABLE Shipments (
        ShipmentId BIGINT IDENTITY(1,1) PRIMARY KEY,
        OrderId INT NOT NULL,
        ProviderCode VARCHAR(30) NULL,                  -- GHN, GHTK, VIETTELPOST, INTERNAL
        TrackingCode VARCHAR(100) NULL,
        ShippingFee DECIMAL(18,2) NOT NULL DEFAULT 0,
        Status VARCHAR(30) NOT NULL DEFAULT 'PENDING',  -- PENDING, PICKED_UP, IN_TRANSIT, DELIVERED, FAILED, RETURNED
        ShippedAt DATETIME2 NULL,
        DeliveredAt DATETIME2 NULL,
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE
    );

    -- Tạo vận đơn mẫu cho đơn hàng đang giao
    INSERT INTO Shipments (OrderId, ProviderCode, TrackingCode, ShippingFee, Status, ShippedAt)
    SELECT OrderId, 'GHTK', 'GHTK-HUIT-998822', 30000, 'IN_TRANSIT', OrderDate
    FROM Orders
    WHERE OrderStatus = N'Đang giao';

    PRINT N'  -> Đã tạo bảng Shipments.';
END
GO


-- =======================================================================
-- PHẦN 3: TẠO CÁC INDEX TỐI ƯU HIỆU NĂNG VÀ TOÀN VẸN
-- =======================================================================

-- 1. Index 1 địa chỉ mặc định duy nhất cho mỗi khách hàng
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_CustomerAddresses_OneDefault' AND object_id = OBJECT_ID('CustomerAddresses'))
BEGIN
    CREATE UNIQUE INDEX UX_CustomerAddresses_OneDefault
    ON CustomerAddresses(UserId)
    WHERE IsDefault = 1;
END
GO

-- 2. Index cho Email không null
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_Users_Email_NotNull' AND object_id = OBJECT_ID('Users'))
BEGIN
    CREATE UNIQUE INDEX UX_Users_Email_NotNull
    ON Users(Email)
    WHERE Email IS NOT NULL;
END
GO

-- 3. Unique index ngăn trùng biến thể trong cùng 1 đơn hàng
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_OrderDetails_Order_Variant' AND object_id = OBJECT_ID('OrderDetails'))
BEGIN
    CREATE UNIQUE INDEX UX_OrderDetails_Order_Variant
    ON OrderDetails(OrderId, VariantId);
END
GO

-- 4. Unique index ngăn trùng biến thể trong cùng phiếu nhập
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_ImportDetails_Import_Variant' AND object_id = OBJECT_ID('ImportReceiptDetails'))
BEGIN
    CREATE UNIQUE INDEX UX_ImportDetails_Import_Variant
    ON ImportReceiptDetails(ImportId, VariantId);
END
GO

-- 5. Performance Indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Category_Active' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE INDEX IX_Products_Category_Active ON Products(CategoryId, IsActive);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_User_Date' AND object_id = OBJECT_ID('Orders'))
BEGIN
    CREATE INDEX IX_Orders_User_Date ON Orders(UserId, OrderDate DESC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_InvTrans_Variant_Date' AND object_id = OBJECT_ID('InventoryTransactions'))
BEGIN
    CREATE INDEX IX_InvTrans_Variant_Date ON InventoryTransactions(VariantId, CreatedAt);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Reservations_Variant_Status' AND object_id = OBJECT_ID('InventoryReservations'))
BEGIN
    CREATE INDEX IX_Reservations_Variant_Status ON InventoryReservations(VariantId, Status, ExpiresAt);
END
GO

PRINT N'========================================================================';
PRINT N'HOÀN TẤT NÂNG CẤP CƠ SỞ DỮ LIỆU [WebQuanLyQuanAoDb]!';
PRINT N'TỔNG SỐ BẢNG HIỆN TẠI: 29 BẢNG (19 bảng gốc chuẩn hóa + 10 bảng bổ sung)';
PRINT N'ĐÃ BẢO ĐẢM TOÀN VẸN RÀNG BUỘC THEO bosung.md!';
PRINT N'========================================================================';
GO
