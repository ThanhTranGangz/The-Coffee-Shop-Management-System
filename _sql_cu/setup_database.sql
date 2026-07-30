/* ══════════════════════════════════════════════════════════════
   CoffeeShopLite — SCRIPT DỰNG DATABASE HOÀN CHỈNH
   Chạy một lần trên SSMS. An toàn khi chạy lại nhiều lần.
   Thay thế: database_lite.sql, update_db.sql, test_data.sql
   ══════════════════════════════════════════════════════════════ */

IF DB_ID(N'CoffeeShopLite') IS NULL CREATE DATABASE CoffeeShopLite;
GO
USE CoffeeShopLite;
GO

PRINT N'── A. Tạo bảng ────────────────────────────────────────────';

IF OBJECT_ID('dbo.Users','U') IS NULL
CREATE TABLE dbo.Users (
    username VARCHAR(50)  PRIMARY KEY,
    password VARCHAR(100) NOT NULL,
    role     VARCHAR(20)  NOT NULL,          -- database_lite.sql THIẾU cột này
    fullName NVARCHAR(120) NOT NULL
);

IF OBJECT_ID('dbo.Tables','U') IS NULL
CREATE TABLE dbo.Tables (
    id       INT IDENTITY PRIMARY KEY,
    name     NVARCHAR(60) NOT NULL,
    code     VARCHAR(40)  NULL,
    floorNo  INT NULL,
    tableNo  INT NULL,
    active   BIT NOT NULL DEFAULT 1
);

IF OBJECT_ID('dbo.MenuItems','U') IS NULL
CREATE TABLE dbo.MenuItems (
    id        INT IDENTITY PRIMARY KEY,
    nameVi    NVARCHAR(120) NOT NULL,
    nameEn    NVARCHAR(120) NOT NULL,
    category  NVARCHAR(60)  NOT NULL,
    price     INT NOT NULL,
    active    BIT NOT NULL DEFAULT 1,
    imagePath VARCHAR(255) NULL
);

IF OBJECT_ID('dbo.MenuItemSizes','U') IS NULL
CREATE TABLE dbo.MenuItemSizes (
    id         INT IDENTITY PRIMARY KEY,
    menuItemId INT NOT NULL,
    sizeName   NVARCHAR(20) NOT NULL,
    extraPrice INT NOT NULL DEFAULT 0,
    sortOrder  INT NOT NULL DEFAULT 0
);

IF OBJECT_ID('dbo.Orders','U') IS NULL
CREATE TABLE dbo.Orders (
    id             INT IDENTITY PRIMARY KEY,
    orderNumber    INT NULL UNIQUE,
    tableName      NVARCHAR(60) NOT NULL,
    customerPhone  VARCHAR(20) NULL,
    status         VARCHAR(30) NOT NULL DEFAULT 'Pending',
    total          INT NOT NULL DEFAULT 0,
    note           NVARCHAR(255) NULL,
    createdAt      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    splitLocked    BIT NOT NULL DEFAULT 0,
    invoicePrinted BIT NOT NULL DEFAULT 0
);

IF OBJECT_ID('dbo.OrderItems','U') IS NULL
CREATE TABLE dbo.OrderItems (
    id          INT IDENTITY PRIMARY KEY,
    orderId     INT NOT NULL,
    menuItemId  INT NOT NULL,
    itemName    NVARCHAR(120) NOT NULL,
    itemSize    VARCHAR(20) NULL,
    quantity    INT NOT NULL,
    price       INT NOT NULL,
    preparedQty INT NOT NULL DEFAULT 0
);

IF OBJECT_ID('dbo.Inventory','U') IS NULL
CREATE TABLE dbo.Inventory (
    id         VARCHAR(50) PRIMARY KEY,
    name       NVARCHAR(120) NOT NULL,
    unit       NVARCHAR(20)  NOT NULL,
    stock      INT NOT NULL DEFAULT 0,
    minStock   INT NOT NULL DEFAULT 0,
    importCost INT NOT NULL DEFAULT 0
);

IF OBJECT_ID('dbo.RecipeItems','U') IS NULL
CREATE TABLE dbo.RecipeItems (
    id           VARCHAR(50) PRIMARY KEY,
    menuItemId   INT NOT NULL,
    ingredientId VARCHAR(50) NOT NULL,
    quantity     INT NOT NULL
);

IF OBJECT_ID('dbo.CashEvents','U') IS NULL
CREATE TABLE dbo.CashEvents (
    id            INT IDENTITY PRIMARY KEY,
    eventType     VARCHAR(30) NOT NULL,
    amount        INT NOT NULL,
    balanceAfter  INT NOT NULL,
    note          NVARCHAR(255) NULL,
    actorRole     VARCHAR(20) NULL,
    actorName     NVARCHAR(120) NULL,
    seenByCashier BIT NOT NULL DEFAULT 1,
    createdAt     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.StoreState','U') IS NULL
CREATE TABLE dbo.StoreState (
    stateKey  VARCHAR(50) PRIMARY KEY,
    intValue  INT NOT NULL,
    updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.SystemLogs','U') IS NULL
CREATE TABLE dbo.SystemLogs (
    id         INT IDENTITY PRIMARY KEY,
    actorRole  VARCHAR(20) NOT NULL,
    actorName  NVARCHAR(120) NULL,
    actionType VARCHAR(40) NOT NULL,
    messageVi  NVARCHAR(400) NOT NULL,
    messageEn  NVARCHAR(400) NOT NULL,
    refId      INT NULL,
    createdAt  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.Staff','U') IS NULL
CREATE TABLE dbo.Staff (
    id     INT PRIMARY KEY,
    name   NVARCHAR(120) NOT NULL,
    active BIT NOT NULL DEFAULT 1,
    status VARCHAR(30) NOT NULL DEFAULT 'Active'
);

IF OBJECT_ID('dbo.Shifts','U') IS NULL
CREATE TABLE dbo.Shifts (
    id           VARCHAR(50) PRIMARY KEY,
    staffId      INT NOT NULL,
    staffName    NVARCHAR(120) NOT NULL,
    shiftDate    VARCHAR(20) NOT NULL,
    shiftName    NVARCHAR(50) NOT NULL,
    hours        VARCHAR(50) NOT NULL,
    status       NVARCHAR(30) NOT NULL,
    notes        NVARCHAR(255) NULL,
    assignedRole VARCHAR(30) NULL
);
GO

PRINT N'── B. Bổ sung cột còn thiếu (cho DB cũ) ───────────────────';

IF COL_LENGTH('dbo.Users','role')            IS NULL ALTER TABLE dbo.Users      ADD role VARCHAR(20) NOT NULL DEFAULT 'barista';
IF COL_LENGTH('dbo.Tables','code')           IS NULL ALTER TABLE dbo.Tables     ADD code VARCHAR(40) NULL;
IF COL_LENGTH('dbo.Tables','floorNo')        IS NULL ALTER TABLE dbo.Tables     ADD floorNo INT NULL;
IF COL_LENGTH('dbo.Tables','tableNo')        IS NULL ALTER TABLE dbo.Tables     ADD tableNo INT NULL;
IF COL_LENGTH('dbo.MenuItems','imagePath')   IS NULL ALTER TABLE dbo.MenuItems  ADD imagePath VARCHAR(255) NULL;
IF COL_LENGTH('dbo.Orders','splitLocked')    IS NULL ALTER TABLE dbo.Orders     ADD splitLocked BIT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','invoicePrinted') IS NULL ALTER TABLE dbo.Orders     ADD invoicePrinted BIT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.OrderItems','itemSize')   IS NULL ALTER TABLE dbo.OrderItems ADD itemSize VARCHAR(20) NULL;
IF COL_LENGTH('dbo.OrderItems','preparedQty')IS NULL ALTER TABLE dbo.OrderItems ADD preparedQty INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.CashEvents','seenByCashier') IS NULL ALTER TABLE dbo.CashEvents ADD seenByCashier BIT NOT NULL DEFAULT 1;
IF COL_LENGTH('dbo.Shifts','staffName')      IS NULL ALTER TABLE dbo.Shifts     ADD staffName NVARCHAR(120) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Shifts','assignedRole')   IS NULL ALTER TABLE dbo.Shifts     ADD assignedRole VARCHAR(30) NULL;
GO

PRINT N'── C. Dọn dữ liệu mồ côi rồi thêm 6 KHOÁ NGOẠI ────────────';

DELETE FROM dbo.MenuItemSizes WHERE menuItemId   NOT IN (SELECT id FROM dbo.MenuItems);
DELETE FROM dbo.OrderItems    WHERE orderId      NOT IN (SELECT id FROM dbo.Orders);
DELETE FROM dbo.OrderItems    WHERE menuItemId   NOT IN (SELECT id FROM dbo.MenuItems);
DELETE FROM dbo.RecipeItems   WHERE menuItemId   NOT IN (SELECT id FROM dbo.MenuItems);
DELETE FROM dbo.RecipeItems   WHERE ingredientId NOT IN (SELECT id FROM dbo.Inventory);
DELETE FROM dbo.Shifts        WHERE staffId      NOT IN (SELECT id FROM dbo.Staff);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_MenuItemSizes_MenuItems')
    ALTER TABLE dbo.MenuItemSizes ADD CONSTRAINT FK_MenuItemSizes_MenuItems FOREIGN KEY (menuItemId)   REFERENCES dbo.MenuItems(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_OrderItems_Orders')
    ALTER TABLE dbo.OrderItems    ADD CONSTRAINT FK_OrderItems_Orders       FOREIGN KEY (orderId)      REFERENCES dbo.Orders(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_OrderItems_MenuItems')
    ALTER TABLE dbo.OrderItems    ADD CONSTRAINT FK_OrderItems_MenuItems    FOREIGN KEY (menuItemId)   REFERENCES dbo.MenuItems(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RecipeItems_MenuItems')
    ALTER TABLE dbo.RecipeItems   ADD CONSTRAINT FK_RecipeItems_MenuItems   FOREIGN KEY (menuItemId)   REFERENCES dbo.MenuItems(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RecipeItems_Inventory')
    ALTER TABLE dbo.RecipeItems   ADD CONSTRAINT FK_RecipeItems_Inventory   FOREIGN KEY (ingredientId) REFERENCES dbo.Inventory(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Staff')
    ALTER TABLE dbo.Shifts        ADD CONSTRAINT FK_Shifts_Staff            FOREIGN KEY (staffId)      REFERENCES dbo.Staff(id);
GO

PRINT N'── D. Index cho các cột query nhiều nhất ──────────────────';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_OrderItems_Order' AND object_id=OBJECT_ID('dbo.OrderItems'))
    CREATE NONCLUSTERED INDEX IX_OrderItems_Order ON dbo.OrderItems(orderId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_Status' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_Status ON dbo.Orders(status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_Table' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_Table ON dbo.Orders(tableName, status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_RecipeItems_Ingredient' AND object_id=OBJECT_ID('dbo.RecipeItems'))
    CREATE NONCLUSTERED INDEX IX_RecipeItems_Ingredient ON dbo.RecipeItems(ingredientId);
GO

PRINT N'── E. Dữ liệu: tài khoản, số cốc ──────────────────────────';

MERGE dbo.Users AS t
USING (VALUES
    ('admin',   '8888', 'admin',   N'Quản trị coffeshop'),
    ('barista', '1111', 'barista', N'Pha chế coffeshop'),
    ('cashier', '2222', 'cashier', N'Thu ngân coffeshop'),
    ('runner',  '3333', 'runner',  N'Bồi bàn coffeshop')
) AS s(username, password, role, fullName)
ON t.username = s.username
WHEN MATCHED THEN UPDATE SET password=s.password, role=s.role, fullName=s.fullName
WHEN NOT MATCHED THEN INSERT(username,password,role,fullName) VALUES(s.username,s.password,s.role,s.fullName);

IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='cupsAvailable')
    INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('cupsAvailable', 120);
GO

PRINT N'── F. Dữ liệu: 10 nhân viên ───────────────────────────────';

MERGE dbo.Staff AS t
USING (VALUES
    ( 1, N'Phạm Minh Tuấn'), ( 2, N'Lê Quốc Bảo'),   ( 3, N'Nguyễn Thu Trà'),
    ( 4, N'Đặng Văn Phong'), ( 5, N'Trần Tuấn Dũng'),( 6, N'Lý Thùy Linh'),
    ( 7, N'Bùi Quang Huy'),  ( 8, N'Võ Tấn Phát'),   ( 9, N'Hồ Ngọc Mai'),
    (10, N'Đỗ Minh Châu')
) AS s(id, name)
ON t.id = s.id
WHEN MATCHED THEN UPDATE SET name = s.name
WHEN NOT MATCHED THEN INSERT(id, name, active, status) VALUES(s.id, s.name, 1, 'Active');
GO

PRINT N'── G. Dữ liệu: ca làm (không trùng staffId+ngày+ca) ───────';

DELETE FROM dbo.Shifts WHERE shiftDate BETWEEN '2026-07-17' AND '2026-07-19';

INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole)
SELECT v.id, v.staffId, s.name, v.shiftDate, v.shiftName, v.hours, v.status, N'', v.assignedRole
FROM (VALUES
    ('sh-17-sang-b', 1, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', 'Barista'),
    ('sh-17-sang-c', 2, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', 'Cashier'),
    ('sh-17-sang-w', 3, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', 'Waiter'),
    ('sh-17-chieu-b',4, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', 'Barista'),
    ('sh-17-chieu-c',5, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', 'Cashier'),
    ('sh-17-chieu-w',6, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', 'Waiter'),
    ('sh-17-toi-b',  7, '2026-07-17', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', 'Barista'),
    ('sh-17-toi-c',  8, '2026-07-17', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', 'Cashier'),
    ('sh-17-toi-w',  9, '2026-07-17', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', 'Waiter'),
    ('sh-18-sang-b',10, '2026-07-18', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', 'Barista'),
    ('sh-18-sang-c', 1, '2026-07-18', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', 'Cashier'),
    ('sh-18-sang-w', 2, '2026-07-18', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', 'Waiter'),
    ('sh-18-toi-b',  3, '2026-07-18', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', 'Barista'),
    ('sh-18-toi-c',  4, '2026-07-18', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', 'Cashier')
    -- 2026-07-18 Ca Tối cố tình THIẾU Waiter để test giao diện cảnh báo
) AS v(id, staffId, shiftDate, shiftName, hours, status, assignedRole)
JOIN dbo.Staff s ON s.id = v.staffId;
GO

PRINT N'── H. Kiểm tra kết quả ────────────────────────────────────';

SELECT 'Khoá ngoại' AS muc, COUNT(*) AS so_luong FROM sys.foreign_keys
UNION ALL SELECT 'Bảng',       COUNT(*) FROM sys.tables
UNION ALL SELECT 'Tài khoản',  COUNT(*) FROM dbo.Users
UNION ALL SELECT 'Nhân viên',  COUNT(*) FROM dbo.Staff
UNION ALL SELECT 'Ca làm',     COUNT(*) FROM dbo.Shifts;

SELECT fk.name AS ten_khoa_ngoai,
       OBJECT_NAME(fk.parent_object_id)     AS bang_con,
       OBJECT_NAME(fk.referenced_object_id) AS bang_cha
FROM sys.foreign_keys fk ORDER BY bang_con;
GO

PRINT N'';
PRINT N'XONG. Khởi động lại Tomcat — ứng dụng sẽ tự seed bàn, thực đơn,';
PRINT N'nguyên liệu và công thức qua LiteService.init().';
GO
