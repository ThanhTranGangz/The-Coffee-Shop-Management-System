-- =======================================================
-- 1. Create Database
-- =======================================================
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
    TransactionID VARCHAR(100) UNIQUE NULL,

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