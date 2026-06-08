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

-- 2.2 Tier Table (New - Hạng thành viên)
CREATE TABLE [Tier] (
    TierID INT IDENTITY(1,1) PRIMARY KEY,
    TierName NVARCHAR(50) NOT NULL UNIQUE,
    MinPoints INT NOT NULL DEFAULT 0,
    DiscountPercent INT NOT NULL DEFAULT 0
);

-- 2.3 Staff Table
CREATE TABLE [Staff] (
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) UNIQUE NOT NULL,
    [Password] VARCHAR(255) NOT NULL,
    PIN_Code VARCHAR(64) NOT NULL, -- Encrypted 4-digit PIN
    FullName NVARCHAR(100) NOT NULL,
    RoleID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Staff_Role FOREIGN KEY (RoleID) REFERENCES [Role](RoleID)
);

-- 2.3b Member Table
CREATE TABLE [Member] (
    MemberID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15) UNIQUE NOT NULL,
    RewardPoints INT NOT NULL DEFAULT 0,
    TierID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Member_Tier FOREIGN KEY (TierID) REFERENCES [Tier](TierID)
);

-- 2.4 Category Table
CREATE TABLE [Category] (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE
);

-- 2.5 Product Table
CREATE TABLE [Product] (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(150) NOT NULL,
    Price INT NOT NULL CHECK (Price >= 0),
    ImageURL VARCHAR(255) NULL,
    [Status] BIT NOT NULL DEFAULT 1, -- 1: Active, 0: Inactive
    CategoryID INT NOT NULL,
    CONSTRAINT FK_Product_Category FOREIGN KEY (CategoryID) REFERENCES [Category](CategoryID)
);

-- 2.6 Tables Table (New - Quản lý Bàn)
CREATE TABLE [Tables] (
    TableID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50) NOT NULL UNIQUE,
    [Status] VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT CHK_Table_Status CHECK ([Status] IN ('AVAILABLE', 'OCCUPIED', 'CLEANING'))
);

-- 2.7 Voucher Table (New - Khuyến mãi)
CREATE TABLE [Voucher] (
    VoucherID INT IDENTITY(1,1) PRIMARY KEY,
    VoucherCode VARCHAR(50) NOT NULL UNIQUE,
    DiscountAmount INT NULL, -- Tiền mặt giảm
    DiscountPercent INT NULL, -- % giảm
    MinTierRequired INT NULL,
    ExpiryDate DATETIME NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Voucher_Tier FOREIGN KEY (MinTierRequired) REFERENCES [Tier](TierID),
    CONSTRAINT CHK_Voucher_Discount CHECK ((DiscountAmount IS NOT NULL AND DiscountPercent IS NULL) OR (DiscountAmount IS NULL AND DiscountPercent IS NOT NULL))
);

-- 2.8 Orders Table
CREATE TABLE [Orders] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount INT NOT NULL DEFAULT 0,
    DiscountAmount INT NOT NULL DEFAULT 0,
    FinalAmount AS (TotalAmount - DiscountAmount),
    PaymentMethod VARCHAR(20) NULL, -- CASH, VIETQR
    TransactionID VARCHAR(100) UNIQUE NULL, -- Bank Webhook transaction reference
    OrderSource VARCHAR(20) NOT NULL DEFAULT 'POS',
    OrderStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    TableID INT NULL,
    CashierID INT NULL, -- NULL if self-ordered via QR
    MemberID INT NULL,
    VoucherID INT NULL,
    CONSTRAINT FK_Orders_Table FOREIGN KEY (TableID) REFERENCES [Tables](TableID),
    CONSTRAINT FK_Orders_Cashier FOREIGN KEY (CashierID) REFERENCES [Staff](StaffID),
    CONSTRAINT FK_Orders_Member FOREIGN KEY (MemberID) REFERENCES [Member](MemberID),
    CONSTRAINT FK_Orders_Voucher FOREIGN KEY (VoucherID) REFERENCES [Voucher](VoucherID),
    CONSTRAINT CHK_Order_Source CHECK (OrderSource IN ('QR', 'POS', 'WAITER')),
    CONSTRAINT CHK_Order_Status CHECK (OrderStatus IN ('PENDING', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT CHK_Payment_Status CHECK (PaymentStatus IN ('UNPAID', 'PENDING', 'PAID', 'FAILED'))
);

-- 2.9 OrderDetail Table
CREATE TABLE [OrderDetail] (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice INT NOT NULL CHECK (UnitPrice >= 0),
    Subtotal AS (Quantity * UnitPrice),
    Note NVARCHAR(255) NULL, -- "Ít đường, ít đá"
    ItemStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT FK_OrderDetail_Orders FOREIGN KEY (OrderID) REFERENCES [Orders](OrderID),
    CONSTRAINT FK_OrderDetail_Product FOREIGN KEY (ProductID) REFERENCES [Product](ProductID),
    CONSTRAINT CHK_Item_Status CHECK (ItemStatus IN ('PENDING', 'PREPARING', 'READY', 'SERVED'))
);

-- 2.10 Shift Table
CREATE TABLE [Shift] (
    ShiftID INT IDENTITY(1,1) PRIMARY KEY,
    StartTime DATETIME NOT NULL DEFAULT GETDATE(),
    EndTime DATETIME NULL,
    StartingCash INT NOT NULL DEFAULT 0,
    ActualCash INT NULL,
    SystemCalculatedCash INT NULL, -- Expected cash at end of shift
    CashierID INT NOT NULL,
    CONSTRAINT FK_Shift_Cashier FOREIGN KEY (CashierID) REFERENCES [Staff](StaffID)
);

-- 2.11 Inventory Table
CREATE TABLE [Inventory] (
    IngredientID INT IDENTITY(1,1) PRIMARY KEY,
    IngredientName NVARCHAR(100) NOT NULL,
    StockQuantity DECIMAL(10,2) NOT NULL DEFAULT 0,
    MinStockLevel DECIMAL(10,2) NOT NULL DEFAULT 0,
    Unit NVARCHAR(20) NOT NULL
);

-- 2.12 Recipe Table
CREATE TABLE [Recipe] (
    ProductID INT NOT NULL,
    IngredientID INT NOT NULL,
    QuantityNeeded DECIMAL(10,2) NOT NULL CHECK (QuantityNeeded > 0),
    PRIMARY KEY (ProductID, IngredientID),
    CONSTRAINT FK_Recipe_Product FOREIGN KEY (ProductID) REFERENCES [Product](ProductID),
    CONSTRAINT FK_Recipe_Inventory FOREIGN KEY (IngredientID) REFERENCES [Inventory](IngredientID)
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