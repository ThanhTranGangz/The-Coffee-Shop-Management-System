IF DB_ID(N'CoffeeShopLite') IS NULL
    CREATE DATABASE CoffeeShopLite;
GO

USE CoffeeShopLite;
GO

IF OBJECT_ID('dbo.Users','U') IS NULL
CREATE TABLE dbo.Users (
    username VARCHAR(50) PRIMARY KEY,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL,
    fullName NVARCHAR(120) NOT NULL
);

IF OBJECT_ID('dbo.Tables','U') IS NULL
CREATE TABLE dbo.Tables (
    id INT IDENTITY PRIMARY KEY,
    name NVARCHAR(60) NOT NULL,
    code VARCHAR(40) NULL,
    active BIT NOT NULL DEFAULT 1
);

IF COL_LENGTH('dbo.Tables','code') IS NULL
ALTER TABLE dbo.Tables ADD code VARCHAR(40) NULL;
IF COL_LENGTH('dbo.Tables','floorNo') IS NULL
ALTER TABLE dbo.Tables ADD floorNo INT NULL;
IF COL_LENGTH('dbo.Tables','tableNo') IS NULL
ALTER TABLE dbo.Tables ADD tableNo INT NULL;

IF OBJECT_ID('dbo.MenuItems','U') IS NULL
CREATE TABLE dbo.MenuItems (
    id INT IDENTITY PRIMARY KEY,
    nameVi NVARCHAR(120) NOT NULL,
    nameEn NVARCHAR(120) NOT NULL,
    category NVARCHAR(60) NOT NULL,
    price INT NOT NULL,
    active BIT NOT NULL DEFAULT 1
);
IF COL_LENGTH('dbo.MenuItems','imagePath') IS NULL
ALTER TABLE dbo.MenuItems ADD imagePath VARCHAR(255) NULL;

IF OBJECT_ID('dbo.MenuItemSizes','U') IS NULL
CREATE TABLE dbo.MenuItemSizes (
    id INT IDENTITY PRIMARY KEY,
    menuItemId INT NOT NULL,
    sizeName NVARCHAR(20) NOT NULL,
    extraPrice INT NOT NULL DEFAULT 0,
    sortOrder INT NOT NULL DEFAULT 0,
    FOREIGN KEY(menuItemId) REFERENCES dbo.MenuItems(id)
);

IF OBJECT_ID('dbo.Orders','U') IS NULL
CREATE TABLE dbo.Orders (
    id INT IDENTITY PRIMARY KEY,
    orderNumber INT NULL UNIQUE,
    tableName NVARCHAR(60) NOT NULL,
    customerPhone VARCHAR(20) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    total INT NOT NULL DEFAULT 0,
    note NVARCHAR(255) NULL,
    createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.OrderItems','U') IS NULL
CREATE TABLE dbo.OrderItems (
    id INT IDENTITY PRIMARY KEY,
    orderId INT NOT NULL,
    menuItemId INT NOT NULL,
    itemName NVARCHAR(120) NOT NULL,
    itemSize VARCHAR(20) NULL,
    quantity INT NOT NULL,
    price INT NOT NULL,
    FOREIGN KEY(orderId) REFERENCES dbo.Orders(id)
);

IF COL_LENGTH('dbo.OrderItems','itemSize') IS NULL
ALTER TABLE dbo.OrderItems ADD itemSize VARCHAR(20) NULL;
ALTER TABLE dbo.OrderItems ALTER COLUMN itemSize VARCHAR(20) NULL;

IF OBJECT_ID('dbo.CashEvents','U') IS NULL
CREATE TABLE dbo.CashEvents (
    id INT IDENTITY PRIMARY KEY,
    eventType VARCHAR(30) NOT NULL,
    amount INT NOT NULL,
    balanceAfter INT NOT NULL,
    note NVARCHAR(255) NULL,
    actorRole VARCHAR(20) NULL,
    actorName NVARCHAR(120) NULL,
    seenByCashier BIT NOT NULL DEFAULT 1,
    createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF COL_LENGTH('dbo.CashEvents','seenByCashier') IS NULL
ALTER TABLE dbo.CashEvents ADD seenByCashier BIT NOT NULL DEFAULT 1;

IF OBJECT_ID('dbo.StoreState','U') IS NULL
CREATE TABLE dbo.StoreState (
    stateKey VARCHAR(50) PRIMARY KEY,
    intValue INT NOT NULL,
    updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.SystemLogs','U') IS NULL
CREATE TABLE dbo.SystemLogs (
    id INT IDENTITY PRIMARY KEY,
    actorRole VARCHAR(20) NOT NULL,
    actorName NVARCHAR(120) NULL,
    actionType VARCHAR(40) NOT NULL,
    messageVi NVARCHAR(400) NOT NULL,
    messageEn NVARCHAR(400) NOT NULL,
    refId INT NULL,
    createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.Staff','U') IS NULL
CREATE TABLE dbo.Staff (
    id INT PRIMARY KEY,
    name NVARCHAR(120) NOT NULL,
    role VARCHAR(20) NOT NULL,
    pin VARCHAR(20) NULL,
    shift NVARCHAR(100) NULL,
    active BIT NOT NULL DEFAULT 1,
    username VARCHAR(50) NULL,
    password VARCHAR(100) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Active',
    overtime BIT NOT NULL DEFAULT 0
);

IF OBJECT_ID('dbo.Shifts','U') IS NULL
CREATE TABLE dbo.Shifts (
    id VARCHAR(50) PRIMARY KEY,
    staffId INT NOT NULL,
    staffName NVARCHAR(120) NOT NULL,
    shiftDate VARCHAR(20) NOT NULL,
    shiftName NVARCHAR(50) NOT NULL,
    hours VARCHAR(50) NOT NULL,
    status NVARCHAR(30) NOT NULL,
    notes NVARCHAR(255) NULL,
    assignedRole VARCHAR(20) NULL
);

IF COL_LENGTH('dbo.Shifts','assignedRole') IS NULL
ALTER TABLE dbo.Shifts ADD assignedRole VARCHAR(20) NULL;


MERGE dbo.Users AS t
USING (VALUES
    ('admin', '8888', 'admin', N'Quản trị coffeshop'),
    ('barista', '1111', 'barista', N'Pha chế coffeshop'),
    ('cashier', '2222', 'cashier', N'Thu ngân coffeshop'),
    ('runner', '3333', 'runner', N'Bồi bàn coffeshop')
) AS s(username, password, role, fullName)
ON t.username=s.username
WHEN MATCHED THEN UPDATE SET password=s.password, role=s.role, fullName=s.fullName
WHEN NOT MATCHED THEN INSERT(username,password,role,fullName) VALUES(s.username,s.password,s.role,s.fullName);

IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='cupsAvailable')
INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('cupsAvailable', 120);
