-- =======================================================
-- CSMS - Update script: QR ordering, member login, seed data
-- Chay duoc nhieu lan (idempotent), khong xoa du lieu cu.
-- Run: sqlcmd -S localhost -U sa -P 123 -d CSMS_DB -i database_update.sql -f 65001
-- =======================================================
USE CSMS_DB;
GO

-- 1. Member: them cot mat khau de thanh vien dang nhap
IF COL_LENGTH('Member', 'PasswordHash') IS NULL
BEGIN
    ALTER TABLE [Member] ADD PasswordHash VARCHAR(255) NULL;
END
GO

-- 2. Tables: moi ban co mot ma QR token rieng
IF COL_LENGTH('Tables', 'QRToken') IS NULL
BEGIN
    ALTER TABLE [Tables] ADD QRToken VARCHAR(64) NULL;
END
GO

-- 2b. Sua loi UNIQUE(TransactionID): rang buoc UNIQUE thuong chi cho phep
--     1 dong NULL -> khong the tao don thu 2. Doi sang filtered unique index.
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @uq NVARCHAR(128);
SELECT @uq = kc.name
FROM sys.key_constraints kc
JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID('Orders') AND kc.[type] = 'UQ' AND c.name = 'TransactionID';
IF @uq IS NOT NULL
    EXEC('ALTER TABLE Orders DROP CONSTRAINT [' + @uq + ']');
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UQ_Orders_TransactionID' AND object_id = OBJECT_ID('Orders'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Orders_TransactionID
        ON Orders(TransactionID) WHERE TransactionID IS NOT NULL;
GO

-- =======================================================
-- 3. Seed data (chi chen khi bang con trong)
-- =======================================================

-- 3.1 Categories
IF NOT EXISTS (SELECT 1 FROM [Category])
BEGIN
    INSERT INTO [Category] (CategoryName) VALUES
    (N'Cà phê'),
    (N'Trà & Trà sữa'),
    (N'Đá xay & Sữa chua'),
    (N'Bánh & Ăn vặt');
END
GO

-- 3.2 Products
IF NOT EXISTS (SELECT 1 FROM [Product])
BEGIN
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
    (N'Tiramisu',               35000, NULL, 0, 4), -- ngung ban (Status = 0)
    (N'Bông lan trứng muối',    30000, NULL, 1, 4),
    (N'Croissant bơ',           29000, NULL, 1, 4);
END
GO

-- 3.3 Inventory (Vai ngam = 0 de demo mon het nguyen lieu)
IF NOT EXISTS (SELECT 1 FROM [Inventory])
BEGIN
    INSERT INTO [Inventory] (IngredientName, StockQuantity, MinStockLevel, Unit) VALUES
    (N'Cà phê bột',              5000, 500, N'g'),     -- 1
    (N'Sữa đặc',                 4000, 400, N'ml'),    -- 2
    (N'Sữa tươi',                6000, 500, N'ml'),    -- 3
    (N'Đường',                   3000, 300, N'g'),     -- 4
    (N'Muối hồng',                500,  50, N'g'),     -- 5
    (N'Đào ngâm',                2000, 200, N'g'),     -- 6
    (N'Vải ngâm',                   0, 200, N'g'),     -- 7 (HET HANG)
    (N'Tắc tươi',                1000, 100, N'g'),     -- 8
    (N'Mật ong',                  800, 100, N'ml'),    -- 9
    (N'Trà đen',                 1500, 150, N'g'),     -- 10
    (N'Trà ô long',              1200, 150, N'g'),     -- 11
    (N'Trân châu',               2500, 250, N'g'),     -- 12
    (N'Bột matcha',               600, 100, N'g'),     -- 13
    (N'Bột cacao',                700, 100, N'g'),     -- 14
    (N'Sữa chua',                  40,   5, N'hộp'),   -- 15
    (N'Việt quất',                900, 100, N'g'),     -- 16
    (N'Bánh bông lan trứng muối',  12,   2, N'cái'),   -- 17
    (N'Bánh croissant',            10,   2, N'cái'),   -- 18
    (N'Bánh tiramisu',              8,   2, N'cái'),   -- 19
    (N'Cam vàng',                1500, 200, N'g'),     -- 20
    (N'Sả',                       800, 100, N'g');     -- 21
END
GO

-- 3.4 Recipes
IF NOT EXISTS (SELECT 1 FROM [Recipe])
BEGIN
    INSERT INTO [Recipe] (ProductID, IngredientID, QuantityNeeded) VALUES
    (1, 1, 20),
    (2, 1, 20), (2, 2, 30),
    (3, 1, 10), (3, 2, 40), (3, 3, 60),
    (4, 1, 20), (4, 2, 30), (4, 5, 3),
    (5, 1, 18),
    (6, 1, 18), (6, 3, 150),
    (7, 1, 18), (7, 3, 120),
    (8, 10, 8), (8, 6, 40), (8, 20, 30), (8, 21, 10),
    (9, 10, 8), (9, 7, 40),                            -- Tra vai -> het vai ngam
    (10, 10, 8), (10, 8, 30), (10, 9, 15),
    (11, 10, 8), (11, 3, 100), (11, 12, 40),
    (12, 11, 8), (12, 3, 100), (12, 12, 40),
    (13, 13, 15), (13, 3, 100), (13, 4, 20),
    (14, 14, 20), (14, 3, 100), (14, 4, 20),
    (15, 15, 1), (15, 16, 30),
    (16, 19, 1),
    (17, 17, 1),
    (18, 18, 1);
END
GO

-- 3.5 Tables + QR token rieng cho tung ban
IF NOT EXISTS (SELECT 1 FROM [Tables])
BEGIN
    INSERT INTO [Tables] (TableName, [Status], QRToken) VALUES
    (N'Bàn 01',      'AVAILABLE', 'tb01-k3f7a9d2'),
    (N'Bàn 02',      'AVAILABLE', 'tb02-m8x2q5w1'),
    (N'Bàn 03',      'AVAILABLE', 'tb03-p4j9c6t8'),
    (N'Bàn 04',      'AVAILABLE', 'tb04-r7v1z3n6'),
    (N'Bàn 05',      'AVAILABLE', 'tb05-s2h8b4y7'),
    (N'Bàn 06',      'AVAILABLE', 'tb06-d9g5e1u3'),
    (N'Sân vườn 01', 'AVAILABLE', 'gd01-w6t3k8f2'),
    (N'Sân vườn 02', 'AVAILABLE', 'gd02-q1n7m4x9');
END
ELSE
BEGIN
    -- Bang da ton tai nhung chua co token thi sinh token theo TableID
    UPDATE [Tables]
    SET QRToken = CONCAT('tbl', TableID, '-', LOWER(CONVERT(VARCHAR(8), ABS(CHECKSUM(NEWID())) % 99999999)))
    WHERE QRToken IS NULL;
END
GO

-- 3.6 Vouchers (CHAOBAN: moi khach | THANHVIEN15: chi thanh vien | GOLD20: hang Gold)
IF NOT EXISTS (SELECT 1 FROM [Voucher])
BEGIN
    INSERT INTO [Voucher] (VoucherCode, DiscountAmount, DiscountPercent, MinTierRequired, ExpiryDate, IsActive) VALUES
    ('CHAOBAN',     5000, NULL, NULL, '2027-12-31', 1),
    ('THANHVIEN15', NULL, 15,   1,    '2027-12-31', 1),
    ('GOLD20',      NULL, 20,   3,    '2027-12-31', 1);
END
GO

-- 3.7 Demo member (phone: 0901234567 / password: 123456)
IF NOT EXISTS (SELECT 1 FROM [Member])
BEGIN
    INSERT INTO [Member] (FullName, Phone, RewardPoints, TierID, IsActive, PasswordHash)
    VALUES (N'Nguyễn Minh Anh', '0901234567', 120, 2,  1,
            '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92');
END
GO

PRINT 'database_update.sql DONE';
GO
