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
IF OBJECT_ID('dbo.OrderItems', 'U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Tables', 'U') IS NOT NULL DROP TABLE dbo.Tables;
IF OBJECT_ID('dbo.MenuItems', 'U') IS NOT NULL DROP TABLE dbo.MenuItems;
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
    activeOrderId VARCHAR(50) NULL
);
GO

-- 4. CREATE ORDERS HEADER TABLE
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

-- 5. CREATE ORDER ITEMS DETAIL TABLE
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
INSERT INTO dbo.Tables (id, name, zone, status, capacity, activeOrderId) VALUES
('t1', N'Table 1', N'Ground Floor', 'empty', 2, NULL),
('t2', N'Table 2', N'Ground Floor', 'empty', 2, NULL),
('t3', N'Table 3', N'Ground Floor', 'empty', 4, NULL),
('t4', N'Table 4', N'Ground Floor', 'empty', 6, NULL),
('t5', N'Terrace A', N'Terrace', 'empty', 2, NULL),
('t6', N'Terrace B', N'Terrace', 'empty', 2, NULL),
('t7', N'Terrace C', N'Terrace', 'empty', 4, NULL),
('t8', N'Terrace Custom', N'Terrace', 'empty', 4, NULL),
('t9', N'Upper Room 1', N'Upper Floor', 'empty', 4, NULL),
('t10', N'Upper Room 2', N'Upper Floor', 'empty', 4, NULL),
('t11', N'Upper Balcony', N'Upper Floor', 'empty', 2, NULL),
('t12', N'Upper Lounge', N'Upper Floor', 'empty', 8, NULL);
GO

PRINT 'Database initialized successfully!';
