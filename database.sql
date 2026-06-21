-- ========================================================
-- DATABASE CREATION AND INITIALIZATION SCRIPT FOR SQL SERVER
-- Project: nhà cà phê (Coffee Shop KDS & Wait Station)
-- Course Reference: HE200531_DoHoaiThu_Lab03UT (SWT301 / SWP391)
-- ========================================================

-- Create database
CREATE DATABASE ArtisanBrew;
GO

USE ArtisanBrew;
GO

-- 1. DROP TABLES IF THEY EXIST TO ENSURE CLEAN RESET
IF OBJECT_ID('dbo.Shifts', 'U') IS NOT NULL DROP TABLE dbo.Shifts;
IF OBJECT_ID('dbo.InventoryExpenses', 'U') IS NOT NULL DROP TABLE dbo.InventoryExpenses;
IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL DROP TABLE dbo.Inventory;
IF OBJECT_ID('dbo.OrderItems', 'U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Tables', 'U') IS NOT NULL DROP TABLE dbo.Tables;
IF OBJECT_ID('dbo.MenuItems', 'U') IS NOT NULL DROP TABLE dbo.MenuItems;
IF OBJECT_ID('dbo.Staff', 'U') IS NOT NULL DROP TABLE dbo.Staff;
IF OBJECT_ID('dbo.Members', 'U') IS NOT NULL DROP TABLE dbo.Members;
GO

-- 2. CREATE MENU ITEMS TABLE
CREATE TABLE dbo.MenuItems (
    id VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    category NVARCHAR(100) NOT NULL,
    price INT NOT NULL,
    description NVARCHAR(MAX),
    availableSizes VARCHAR(100) NOT NULL, -- Comma-separated sizes e.g. "S,M,L"
    image VARCHAR(500)
);
GO

-- 3. CREATE COFFEE SHOP TABLES TABLE
CREATE TABLE dbo.Tables (
    id VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    zone NVARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'empty', -- empty, serving, ready_to_serve, dirty
    capacity INT NOT NULL,
    activeOrderId VARCHAR(50) NULL,
    tableCode VARCHAR(50) NULL UNIQUE
);
GO

-- 4. CREATE STAFF TABLE
CREATE TABLE dbo.Staff (
    id INT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    pin VARCHAR(10) NOT NULL,
    shift NVARCHAR(100) NOT NULL,
    active BIT NOT NULL DEFAULT 1,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    overtime BIT NOT NULL DEFAULT 0
);
GO

-- 5. CREATE MEMBERS/CRM TABLE
CREATE TABLE dbo.Members (
    phone VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    rank VARCHAR(50) NOT NULL DEFAULT 'Silver',
    points INT NOT NULL DEFAULT 0,
    email VARCHAR(255) NULL,
    pref NVARCHAR(255) NULL,
    discount NVARCHAR(255) NULL,
    password VARCHAR(255) NOT NULL DEFAULT '123456',
    vouchers NVARCHAR(MAX) NULL
);
GO

-- 5A. CREATE INVENTORY ITEMS TABLE
CREATE TABLE dbo.Inventory (
    id VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    unit NVARCHAR(50) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    minStock INT NOT NULL DEFAULT 0,
    importCost INT NOT NULL DEFAULT 0
);
GO

-- 5B. CREATE INVENTORY EXPENSES TABLE
CREATE TABLE dbo.InventoryExpenses (
    id VARCHAR(50) PRIMARY KEY,
    amount INT NOT NULL DEFAULT 0,
    details NVARCHAR(MAX) NOT NULL,
    timestamp VARCHAR(50) NOT NULL
);
GO

-- 5C. CREATE STAFF SHIFTS SCHEDULE TABLE
CREATE TABLE dbo.Shifts (
    id VARCHAR(50) PRIMARY KEY,
    staffId INT NOT NULL,
    staffName NVARCHAR(255) NOT NULL,
    shiftDate VARCHAR(50) NOT NULL, -- YYYY-MM-DD
    shiftName NVARCHAR(100) NOT NULL, -- e.g. Ca sáng, Ca chiều, Ca tối
    hours NVARCHAR(100) NOT NULL, -- e.g. 06:00 - 12:00
    status NVARCHAR(50) NOT NULL DEFAULT N'Hoạt động', -- Hoạt động, Tăng ca, Tan ca
    notes NVARCHAR(MAX) NULL
);
GO

-- 6. CREATE ORDERS HEADER TABLE
CREATE TABLE dbo.Orders (
    id VARCHAR(50) PRIMARY KEY,
    tableId VARCHAR(50) NULL,
    tableName NVARCHAR(100) NULL,
    orderNumber INT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending', -- Pending, Preparing, Ready, Served
    createdAt VARCHAR(50) NOT NULL,
    updatedAt VARCHAR(50) NOT NULL,
    notes NVARCHAR(MAX) NULL,
    totalAmount INT NOT NULL DEFAULT 0
);
GO

-- 7. CREATE ORDER ITEMS DETAIL TABLE
CREATE TABLE dbo.OrderItems (
    id VARCHAR(100) PRIMARY KEY,
    orderId VARCHAR(50) NOT NULL,
    menuItemId VARCHAR(50) NOT NULL,
    name NVARCHAR(255) NOT NULL,
    price INT NOT NULL,
    quantity INT NOT NULL,
    size VARCHAR(10) NOT NULL DEFAULT 'M',
    sugar VARCHAR(10) NOT NULL DEFAULT '100%',
    ice VARCHAR(10) NOT NULL DEFAULT '100%',
    notes NVARCHAR(MAX) NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending', -- Pending, Preparing, Ready, Served
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_MenuItems FOREIGN KEY (menuItemId) REFERENCES dbo.MenuItems(id)
);
GO

-- ========================================================
-- SEED INITIAL DATA
-- ========================================================

-- Insert Menu Items
INSERT INTO dbo.MenuItems (id, name, category, price, description, availableSizes, image) VALUES
('m1', N'Traditional Black Coffee (Café Đen)', N'Coffee', 29000, N'Bold, dark-roasted Vietnamese coffee beans brewed with a traditional phin filter.', 'S,M,L', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=600&auto=format&fit=crop'),
('m2', N'Vietnamese Milk Coffee (Café Sữa Đá)', N'Coffee', 35000, N'Traditional Vietnamese drip coffee sweetened with rich condensed milk, served over ice.', 'S,M,L', 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=600&auto=format&fit=crop'),
('m3', N'Salted Cream Coffee (Café Muối)', N'Coffee', 45000, N'A unique combination of bold coffee with sweet condensed milk, topped with a velvety, slightly salty whipping cream.', 'S,M', 'https://images.unsplash.com/photo-1572286258217-40142c1c6a70?q=80&w=600&auto=format&fit=crop'),
('m4', N'Coconut Cold Brew', N'Coffee', 49000, N'Slow-steeped cold brew coffee paired with sweet and aromatic fresh coconut water.', 'M,L', 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=600&auto=format&fit=crop'),
('m5', N'Peach Tea Lemongrass (Trà Đào Cam Sả)', N'Tea', 45000, N'Refreshing black tea infused with peach syrup, fresh orange juice, and a fragrant stalk of lemongrass.', 'M,L', 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=600&auto=format&fit=crop'),
('m6', N'Matcha Latte', N'Specialty', 49000, N'Premium Japanese Uji matcha whisked with warm or iced milk and a hint of sweetness.', 'S,M,L', 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=600&auto=format&fit=crop'),
('m7', N'Oolong Milk Tea Cordial', N'Tea', 45000, N'Roasted oolong tea leaves blended with gourmet milk powder, topped with cream cheese cap.', 'M,L', 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=600&auto=format&fit=crop'),
('m8', N'Butter Croissant', N'Pastry', 29000, N'Flaky, buttery, golden French pastry baked fresh daily.', 'S', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=600&auto=format&fit=crop'),
('m9', N'Tiramisu Slice', N'Pastry', 45000, N'Espresso-soaked ladyfingers nested in a light and airy mascarpone cream, dusted with cocoa powder.', 'S', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?q=80&w=600&auto=format&fit=crop');
GO

-- Insert Tables
INSERT INTO dbo.Tables (id, name, zone, status, capacity, activeOrderId, tableCode) VALUES
('t1', N'Table 1', N'Ground Floor', 'empty', 2, NULL, 'TBL-T1-1001'),
('t2', N'Table 2', N'Ground Floor', 'empty', 2, NULL, 'TBL-T2-1002'),
('t3', N'Table 3', N'Ground Floor', 'empty', 4, NULL, 'TBL-T3-1003'),
('t4', N'Table 4', N'Ground Floor', 'empty', 6, NULL, 'TBL-T4-1004'),
('t5', N'Terrace A', N'Terrace', 'empty', 2, NULL, 'TBL-T5-1005'),
('t6', N'Terrace B', N'Terrace', 'empty', 2, NULL, 'TBL-T6-1006'),
('t7', N'Terrace C', N'Terrace', 'empty', 4, NULL, 'TBL-T7-1007'),
('t8', N'Terrace Custom', N'Terrace', 'empty', 4, NULL, 'TBL-T8-1008'),
('t9', N'Upper Room 1', N'Upper Floor', 'empty', 4, NULL, 'TBL-T9-1009'),
('t10', N'Upper Room 2', N'Upper Floor', 'empty', 4, NULL, 'TBL-T10-1010'),
('t11', N'Upper Balcony', N'Upper Floor', 'empty', 2, NULL, 'TBL-T11-1011'),
('t12', N'Upper Lounge', N'Upper Floor', 'empty', 8, NULL, 'TBL-T12-1012');
GO

-- Insert Staff
INSERT INTO dbo.Staff (id, name, role, pin, shift, active, username, password, status, overtime) VALUES
(1, N'Quản lý Hệ Thống', 'manager', '8888', N'Toàn thời gian', 1, 'admin', '123456', 'Active', 0),
(2, N'Nguyễn Văn A (Phục vụ)', 'waiter', '9999', N'Ca chiều (12:00 - 18:00)', 1, 'nguyenvana', '123456', 'Active', 0),
(3, N'Phạm Minh waiter (Ca sáng)', 'waiter', '1234', N'Ca sáng (06:00 - 12:00)', 1, 'waiter1', '123456', 'Active', 0),
(4, N'Nguyễn Thị B (Ca chiều)', 'waiter', '2222', N'Ca chiều (12:00 - 18:00)', 1, 'waiter2', '123456', 'Active', 0),
(5, N'Lê Hoàng D (Ca tối)', 'waiter', '5555', N'Ca tối (18:00 - 24:00)', 1, 'waiter3', '123456', 'Active', 0),
(6, N'Trần Văn C (Ca sáng)', 'barista', '4444', N'Ca sáng (06:00 - 12:00)', 1, 'barista2', '123456', 'Active', 0),
(7, N'Phan Anh barista (Ca chiều)', 'barista', '3333', N'Ca chiều (12:00 - 18:00)', 1, 'barista1', '123456', 'Active', 0),
(8, N'Ngô Quốc Bảo (Pha chế Ca tối)', 'barista', '7777', N'Ca tối (18:00 - 24:00)', 1, 'barista3', '123456', 'Active', 0);
GO

-- Insert Members/CRM
INSERT INTO dbo.Members (phone, name, rank, points, email, pref, discount, password, vouchers) VALUES
('0909123456', N'Trần Thị Thuỷ Tiên', 'Platinum', 740, 'thuytien@gmail.com', N'Espresso', N'Giảm 15% tổng hoá đơn', '123456', 'CAFE15'),
('0901234567', N'Lê Hoàng Phong', 'Gold', 320, 'hoangphong@gmail.com', N'Tea', N'Giảm 10% tổng hoá đơn', '123456', ''),
('0987654321', N'Nguyễn Minh Quân', 'Silver', 120, 'minhquan@gmail.com', N'Special', N'Giảm 5% tổng hoá đơn', '123456', '');
GO

-- Insert Initial Inventory Raw Materials
INSERT INTO dbo.Inventory (id, name, unit, stock, minStock, importCost) VALUES
('i1', N'Hạt cà phê nguyên chất', 'g', 1500, 300, 50),
('i2', N'Sữa đặc đặc sánh', 'g', 1000, 200, 40),
('i3', N'Sữa tươi tiệt trùng', 'ml', 2000, 500, 20),
('i4', N'Kem béo muối biển', 'ml', 80, 150, 80),
('i5', N'Siro đào thơm mát', 'ml', 600, 100, 60),
('i6', N'Sả tươi thơm nồng', N'nhánh', 20, 5, 1000),
('i7', N'Bột Trà xanh Matcha Uji', 'g', 0, 100, 200),
('i8', N'Lá trà Ô long khô', 'g', 500, 100, 100),
('i9', N'Vỏ bánh sừng bò sấy', N'cái', 15, 4, 15000),
('i10', N'Bánh Tiramisu cắt sẵn', N'lát', 1, 3, 25000);
GO

-- Insert Active Shifts Schedule
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes) VALUES
('s1', 2, N'Nguyễn Văn A (Phục vụ)', '2026-06-20', N'Ca chiều', '12:00 - 18:00', N'Hoạt động', N'Trực bàn tầng trệt'),
('s2', 3, N'Phạm Minh waiter (Ca sáng)', '2026-06-20', N'Ca sáng', '06:00 - 12:00', N'Hoạt động', N'Mở cửa hàng'),
('s3', 4, N'Nguyễn Thị B (Ca chiều)', '2026-06-20', N'Ca chiều', '12:00 - 18:00', N'Hoạt động', N'Bàn terrace'),
('s4', 5, N'Lê Hoàng D (Ca tối)', '2026-06-20', N'Ca tối', '18:00 - 24:00', N'Hoạt động', N'Dọn dẹp đóng cửa'),
('s5', 6, N'Trần Văn C (Ca sáng)', '2026-06-20', N'Ca sáng', '06:00 - 12:00', N'Hoạt động', N'Barista chính ca sáng'),
('s6', 7, N'Phan Anh barista (Ca chiều)', '2026-06-20', N'Ca chiều', '12:00 - 18:00', N'Hoạt động', N'Pha chế ca chiều'),
('s7', 8, N'Ngô Quốc Bảo (Pha chế Ca tối)', '2026-06-20', N'Ca tối', '18:00 - 24:00', N'Hoạt động', N'Pha chế ca tối');
GO

PRINT 'Database initialized successfully!';
