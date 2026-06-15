-- =======================================================
-- 1. Create Database
-- =======================================================
SET QUOTED_IDENTIFIER ON;
GO
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CSMS_DB')
BEGIN
    DROP DATABASE CSMS_DB;
END
GO

CREATE DATABASE CSMS_DB;
GO

USE CSMS_DB;
GO

-- =======================================================
-- 2. Create Tables (With Foreign Keys)
-- =======================================================

-- 2.1 Role Table
CREATE TABLE [Role] (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);

-- 2.2 Permission Table
CREATE TABLE [Permission] (
    PermissionID INT IDENTITY(1,1) PRIMARY KEY,
    PermissionName VARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(255) NULL
);

-- 2.3 RolePermission Table
CREATE TABLE [RolePermission] (
    RoleID INT NOT NULL,
    PermissionID INT NOT NULL,
    PRIMARY KEY (RoleID, PermissionID),
    CONSTRAINT FK_RolePermission_Role 
        FOREIGN KEY (RoleID) REFERENCES [Role](RoleID),
    CONSTRAINT FK_RolePermission_Permission 
        FOREIGN KEY (PermissionID) REFERENCES [Permission](PermissionID)
);

-- 2.4 Tier Table
CREATE TABLE [Tier] (
    TierID INT IDENTITY(1,1) PRIMARY KEY,
    TierName NVARCHAR(50) NOT NULL UNIQUE,
    MinPoints INT NOT NULL DEFAULT 0,
    DiscountPercent INT NOT NULL DEFAULT 0,
    CONSTRAINT CHK_Tier_MinPoints CHECK (MinPoints >= 0),
    CONSTRAINT CHK_Tier_Discount CHECK (DiscountPercent BETWEEN 0 AND 100)
);

-- 2.5 Staff Table
CREATE TABLE [Staff] (
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) UNIQUE NOT NULL,
    [Password] VARCHAR(255) NOT NULL,
    PIN_Code VARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    RoleID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,

    FailedPINAttempts INT NOT NULL DEFAULT 0,
    LockedUntil DATETIME NULL,
    LastFailedPINAt DATETIME NULL,

    CONSTRAINT FK_Staff_Role 
        FOREIGN KEY (RoleID) REFERENCES [Role](RoleID)
);

-- 2.6 Member Table
CREATE TABLE [Member] (
    MemberID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15) UNIQUE NOT NULL,
    RewardPoints INT NOT NULL DEFAULT 0,
    TierID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    PasswordHash VARCHAR(255) NULL,
    CONSTRAINT FK_Member_Tier 
        FOREIGN KEY (TierID) REFERENCES [Tier](TierID)
);

-- 2.7 Category Table
CREATE TABLE [Category] (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE
);

-- 2.8 Product Table
CREATE TABLE [Product] (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(150) NOT NULL,
    Price INT NOT NULL CHECK (Price >= 0),
    ImageURL VARCHAR(255) NULL,
    [Status] BIT NOT NULL DEFAULT 1,
    CategoryID INT NOT NULL,
    CONSTRAINT FK_Product_Category 
        FOREIGN KEY (CategoryID) REFERENCES [Category](CategoryID)
);

-- 2.9 Tables Table
CREATE TABLE [Tables] (
    TableID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50) NOT NULL UNIQUE,
    [Status] VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    QRToken VARCHAR(64) NULL,
    CONSTRAINT CHK_Table_Status 
        CHECK ([Status] IN ('AVAILABLE', 'OCCUPIED', 'CLEANING'))
);

-- 2.10 Voucher Table
CREATE TABLE [Voucher] (
    VoucherID INT IDENTITY(1,1) PRIMARY KEY,
    VoucherCode VARCHAR(50) NOT NULL UNIQUE,
    DiscountAmount INT NULL,
    DiscountPercent INT NULL,
    MinTierRequired INT NULL,
    ExpiryDate DATETIME NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Voucher_Tier 
        FOREIGN KEY (MinTierRequired) REFERENCES [Tier](TierID),

    CONSTRAINT CHK_Voucher_Discount CHECK (
        (DiscountAmount IS NOT NULL AND DiscountPercent IS NULL AND DiscountAmount > 0)
        OR
        (DiscountAmount IS NULL AND DiscountPercent IS NOT NULL AND DiscountPercent BETWEEN 1 AND 100)
    )
);

-- 2.11 Orders Table
CREATE TABLE [Orders] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount INT NOT NULL DEFAULT 0,
    DiscountAmount INT NOT NULL DEFAULT 0,
    FinalAmount AS (TotalAmount - DiscountAmount),

    PaymentMethod VARCHAR(20) NULL,
    TransactionID VARCHAR(100) NULL,

    OrderSource VARCHAR(20) NOT NULL DEFAULT 'POS',
    OrderStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'UNPAID',

    TableID INT NULL,
    CashierID INT NULL,
    MemberID INT NULL,
    VoucherID INT NULL,

    CONSTRAINT FK_Orders_Table 
        FOREIGN KEY (TableID) REFERENCES [Tables](TableID),

    CONSTRAINT FK_Orders_Cashier 
        FOREIGN KEY (CashierID) REFERENCES [Staff](StaffID),

    CONSTRAINT FK_Orders_Member 
        FOREIGN KEY (MemberID) REFERENCES [Member](MemberID),

    CONSTRAINT FK_Orders_Voucher 
        FOREIGN KEY (VoucherID) REFERENCES [Voucher](VoucherID),

    CONSTRAINT CHK_Order_Source 
        CHECK (OrderSource IN ('QR', 'POS', 'WAITER')),

    CONSTRAINT CHK_Order_Status 
        CHECK (OrderStatus IN ('PENDING', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED')),

    CONSTRAINT CHK_Payment_Status 
        CHECK (PaymentStatus IN ('UNPAID', 'PENDING', 'PAID', 'FAILED')),

    CONSTRAINT CHK_Payment_Method 
        CHECK (PaymentMethod IS NULL OR PaymentMethod IN ('CASH', 'VIETQR')),

    CONSTRAINT CHK_Order_Discount 
        CHECK (DiscountAmount >= 0 AND DiscountAmount <= TotalAmount)
);

-- TransactionID chi can duy nhat khi co gia tri (cho phep nhieu don NULL)
CREATE UNIQUE NONCLUSTERED INDEX UQ_Orders_TransactionID
    ON [Orders](TransactionID) WHERE TransactionID IS NOT NULL;

-- 2.12 OrderDetail Table
CREATE TABLE [OrderDetail] (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice INT NOT NULL CHECK (UnitPrice >= 0),
    Subtotal AS (Quantity * UnitPrice),
    Note NVARCHAR(255) NULL,
    ItemStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    CONSTRAINT FK_OrderDetail_Orders 
        FOREIGN KEY (OrderID) REFERENCES [Orders](OrderID),

    CONSTRAINT FK_OrderDetail_Product 
        FOREIGN KEY (ProductID) REFERENCES [Product](ProductID),

    CONSTRAINT CHK_Item_Status 
        CHECK (ItemStatus IN ('PENDING', 'PREPARING', 'READY', 'SERVED'))
);

-- 2.13 Shift Table
CREATE TABLE [Shift] (
    ShiftID INT IDENTITY(1,1) PRIMARY KEY,
    StartTime DATETIME NOT NULL DEFAULT GETDATE(),
    EndTime DATETIME NULL,
    StartingCash INT NOT NULL DEFAULT 0,
    ActualCash INT NULL,
    SystemCalculatedCash INT NULL,
    CashierID INT NOT NULL,

    CONSTRAINT FK_Shift_Cashier 
        FOREIGN KEY (CashierID) REFERENCES [Staff](StaffID)
);

-- 2.14 Inventory Table
CREATE TABLE [Inventory] (
    IngredientID INT IDENTITY(1,1) PRIMARY KEY,
    IngredientName NVARCHAR(100) NOT NULL,
    StockQuantity DECIMAL(10,2) NOT NULL DEFAULT 0,
    MinStockLevel DECIMAL(10,2) NOT NULL DEFAULT 0,
    Unit NVARCHAR(20) NOT NULL
);

-- 2.15 Recipe Table
CREATE TABLE [Recipe] (
    ProductID INT NOT NULL,
    IngredientID INT NOT NULL,
    QuantityNeeded DECIMAL(10,2) NOT NULL CHECK (QuantityNeeded > 0),

    PRIMARY KEY (ProductID, IngredientID),

    CONSTRAINT FK_Recipe_Product 
        FOREIGN KEY (ProductID) REFERENCES [Product](ProductID),

    CONSTRAINT FK_Recipe_Inventory 
        FOREIGN KEY (IngredientID) REFERENCES [Inventory](IngredientID)
);

-- 2.16 StaffSession Table
CREATE TABLE [StaffSession] (
    SessionID INT IDENTITY(1,1) PRIMARY KEY,
    StaffID INT NOT NULL,
    LoginTime DATETIME NOT NULL DEFAULT GETDATE(),
    LogoutTime DATETIME NULL,
    DeviceName NVARCHAR(100) NULL,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT FK_StaffSession_Staff 
        FOREIGN KEY (StaffID) REFERENCES [Staff](StaffID)
);

-- 2.17 RewardPointTransaction Table
CREATE TABLE [RewardPointTransaction] (
    PointTransactionID INT IDENTITY(1,1) PRIMARY KEY,
    MemberID INT NOT NULL,
    OrderID INT NULL,
    PointsChanged INT NOT NULL,
    Reason NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_PointTransaction_Member 
        FOREIGN KEY (MemberID) REFERENCES [Member](MemberID),

    CONSTRAINT FK_PointTransaction_Order 
        FOREIGN KEY (OrderID) REFERENCES [Orders](OrderID)
);

-- =======================================================
-- 3. Initial Seed Data (Tạo dữ liệu cơ bản)
-- =======================================================

-- Insert Roles
INSERT INTO [Role] (RoleName) VALUES ('MANAGER'), ('CASHIER'), ('BARISTA'), ('WAITER'), ('MEMBER');

-- Insert Tiers
INSERT INTO [Tier] (TierName, MinPoints, DiscountPercent) VALUES 
('Bronze', 0, 0), 
('Silver', 100, 5), 
('Gold', 500, 10);

-- Insert Demo Admin Staff (Password: 123456, PIN: 1234)
INSERT INTO [Staff] (Username, [Password], PIN_Code, FullName, RoleID, IsActive)
VALUES ('admin', 'hashed_password_here', 'hashed_pin_here', 'Manager Admin', 1, 1);
GO

UPDATE [Staff]
SET [Password] = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
    PIN_Code = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'
WHERE Username = 'admin';
GO

-- 3.1 Categories
INSERT INTO [Category] (CategoryName) VALUES
(N'Cà phê'),
(N'Trà & Trà sữa'),
(N'Đá xay & Sữa chua'),
(N'Bánh & Ăn vặt');
GO

-- 3.2 Products
INSERT INTO [Product] (ProductName, Price, ImageURL, [Status], CategoryID) VALUES
(N'Cà phê đen đá',          25000, NULL, 1, 1),
(N'Cà phê sữa đá',          29000, NULL, 1, 1),
(N'Bạc xỉu',                32000, NULL, 1, 1),
(N'Cà phê muối',            35000, NULL, 1, 1),
(N'Espresso',               40000, NULL, 1, 1),
(N'Latte nóng',             45000, NULL, 1, 1),
(N'Cappuccino',             45000, NULL, 1, 1),
(N'Trà đào cam sả',         45000, NULL, 1, 2),
(N'Trà vải',                42000, NULL, 1, 2),
(N'Trà tắc mật ong',        35000, NULL, 1, 2),
(N'Trà sữa trân châu',      38000, NULL, 1, 2),
(N'Ô long sữa trân châu',   40000, NULL, 1, 2),
(N'Matcha đá xay',          50000, NULL, 1, 3),
(N'Cacao đá xay',           48000, NULL, 1, 3),
(N'Sữa chua việt quất',     42000, NULL, 1, 3),
(N'Tiramisu',               35000, NULL, 0, 4),
(N'Bông lan trứng muối',    30000, NULL, 1, 4),
(N'Croissant bơ',           29000, NULL, 1, 4);
GO

-- 3.3 Inventory
INSERT INTO [Inventory] (IngredientName, StockQuantity, MinStockLevel, Unit) VALUES
(N'Cà phê bột',              5000, 500, N'g'),
(N'Sữa đặc',                 4000, 400, N'ml'),
(N'Sữa tươi',                6000, 500, N'ml'),
(N'Đường',                   3000, 300, N'g'),
(N'Muối hồng',                500,  50, N'g'),
(N'Đào ngâm',                2000, 200, N'g'),
(N'Vải ngâm',                   0, 200, N'g'),
(N'Tắc tươi',                1000, 100, N'g'),
(N'Mật ong',                  800, 100, N'ml'),
(N'Trà đen',                 1500, 150, N'g'),
(N'Trà ô long',              1200, 150, N'g'),
(N'Trân châu',               2500, 250, N'g'),
(N'Bột matcha',               600, 100, N'g'),
(N'Bột cacao',                700, 100, N'g'),
(N'Sữa chua',                  40,   5, N'hộp'),
(N'Việt quất',                900, 100, N'g'),
(N'Bánh bông lan trứng muối',  12,   2, N'cái'),
(N'Bánh croissant',            10,   2, N'cái'),
(N'Bánh tiramisu',              8,   2, N'cái'),
(N'Cam vàng',                1500, 200, N'g'),
(N'Sả',                       800, 100, N'g');
GO

-- 3.4 Recipes
INSERT INTO [Recipe] (ProductID, IngredientID, QuantityNeeded) VALUES
(1, 1, 20),
(2, 1, 20), (2, 2, 30),
(3, 1, 10), (3, 2, 40), (3, 3, 60),
(4, 1, 20), (4, 2, 30), (4, 5, 3),
(5, 1, 18),
(6, 1, 18), (6, 3, 150),
(7, 1, 18), (7, 3, 120),
(8, 10, 8), (8, 6, 40), (8, 20, 30), (8, 21, 10),
(9, 10, 8), (9, 7, 40),
(10, 10, 8), (10, 8, 30), (10, 9, 15),
(11, 10, 8), (11, 3, 100), (11, 12, 40),
(12, 11, 8), (12, 3, 100), (12, 12, 40),
(13, 13, 15), (13, 3, 100), (13, 4, 20),
(14, 14, 20), (14, 3, 100), (14, 4, 20),
(15, 15, 1), (15, 16, 30),
(16, 19, 1),
(17, 17, 1),
(18, 18, 1);
GO

-- 3.5 Tables + QR token rieng cho tung ban
INSERT INTO [Tables] (TableName, [Status], QRToken) VALUES
(N'Bàn 01',      'AVAILABLE', 'tb01-k3f7a9d2'),
(N'Bàn 02',      'AVAILABLE', 'tb02-m8x2q5w1'),
(N'Bàn 03',      'AVAILABLE', 'tb03-p4j9c6t8'),
(N'Bàn 04',      'AVAILABLE', 'tb04-r7v1z3n6'),
(N'Bàn 05',      'AVAILABLE', 'tb05-s2h8b4y7'),
(N'Bàn 06',      'AVAILABLE', 'tb06-d9g5e1u3'),
(N'Sân vườn 01', 'AVAILABLE', 'gd01-w6t3k8f2'),
(N'Sân vườn 02', 'AVAILABLE', 'gd02-q1n7m4x9');
GO

-- 3.6 Vouchers
INSERT INTO [Voucher] (VoucherCode, DiscountAmount, DiscountPercent, MinTierRequired, ExpiryDate, IsActive) VALUES
('CHAOBAN',     5000, NULL, NULL, '2027-12-31', 1),
('THANHVIEN15', NULL, 15,   1,    '2027-12-31', 1),
('GOLD20',      NULL, 20,   3,    '2027-12-31', 1);
GO

-- 3.7 Demo member
INSERT INTO [Member] (FullName, Phone, RewardPoints, TierID, IsActive, PasswordHash)
VALUES (N'Nguyễn Minh Anh', '0901234567', 120, 2,  1, '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92');
GO

PRINT 'create_table.sql DONE';
GO