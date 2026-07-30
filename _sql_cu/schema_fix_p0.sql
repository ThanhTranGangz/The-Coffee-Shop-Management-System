/* ══════════════════════════════════════════════════════════════
   CoffeeShopLite — SỬA 4 LỖI THIẾT KẾ MỨC NGHIÊM TRỌNG
   Chạy SAU setup_database.sql và customer_loyalty.sql.
   An toàn khi chạy lại nhiều lần.

   #1 Orders.tableId       — bảng Tables hết là hòn đảo trong ERD
   #2 Payments             — tầng thanh toán thật, nối được vào sổ quỹ
   #3 StockTransactions    — kho có sổ cái thay vì chỉ một ảnh chụp
   #4 Roles + Users.staffId— nhân sự và tài khoản không còn là hai thế giới

   ĐỌC TRƯỚC KHI CHẠY
   Script này KHÔNG xoá cột nào. Orders.tableName được giữ lại có chủ ý,
   trở thành BẢN CHỤP tên bàn tại thời điểm đặt đơn — cùng nguyên tắc với
   OrderItems.itemName/price. Quan hệ thật từ nay là Orders.tableId.
   ══════════════════════════════════════════════════════════════ */

USE CoffeeShopLite;
GO

/* ══════════════════════════════════════════════════════════════
   #1  ORDERS → TABLES
   ══════════════════════════════════════════════════════════════ */
PRINT N'── #1 Orders.tableId ──────────────────────────────────────';

IF COL_LENGTH('dbo.Orders','tableId') IS NULL
    ALTER TABLE dbo.Orders ADD tableId INT NULL;
GO

/* Backfill từ dữ liệu cũ: ghép theo tên bàn. Đây là lần DUY NHẤT
   được phép ghép bằng chuỗi — sau bước này mọi thứ đi qua khoá. */
UPDATE o
SET    o.tableId = t.id
FROM   dbo.Orders o
JOIN   dbo.Tables t ON t.name = o.tableName
WHERE  o.tableId IS NULL;
GO

/* Báo cáo đơn không ghép được (bàn đã bị đổi tên hoặc xoá).
   Chính những dòng này là bằng chứng cho hậu quả của việc lưu tên bàn
   bằng chuỗi: không có cách nào khôi phục chúng về đúng bàn. */
DECLARE @orphans INT = (SELECT COUNT(*) FROM dbo.Orders WHERE tableId IS NULL);
IF @orphans > 0
    PRINT N'   CẢNH BÁO: ' + CAST(@orphans AS NVARCHAR(10))
        + N' đơn không ghép được về bàn nào (tên bàn không còn tồn tại).';
ELSE
    PRINT N'   Tất cả đơn đã ghép được về bàn.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Tables')
    ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Tables
        FOREIGN KEY (tableId) REFERENCES dbo.Tables(id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_TableId' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_TableId ON dbo.Orders(tableId, status);
GO


/* ══════════════════════════════════════════════════════════════
   #2  TẦNG THANH TOÁN
   ══════════════════════════════════════════════════════════════ */
PRINT N'── #2 Payments ────────────────────────────────────────────';

IF OBJECT_ID('dbo.Payments','U') IS NULL
CREATE TABLE dbo.Payments (
    id              INT IDENTITY PRIMARY KEY,
    orderId         INT NOT NULL,
    method          VARCHAR(20)  NOT NULL,          -- CASH | TRANSFER
    amount          INT NOT NULL,                   -- số tiền phải trả
    receivedAmount  INT NOT NULL,                   -- khách đưa
    changeAmount    INT NOT NULL,                   -- tiền thối
    cashierUsername VARCHAR(50)  NULL,
    cashierName     NVARCHAR(120) NULL,
    staffId         INT NULL,                       -- ai thực sự đứng quầy
    note            NVARCHAR(255) NULL,
    paidAt          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Payments_Method')
    ALTER TABLE dbo.Payments ADD CONSTRAINT CK_Payments_Method
        CHECK (method IN ('CASH','TRANSFER'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Payments_Amounts')
    ALTER TABLE dbo.Payments ADD CONSTRAINT CK_Payments_Amounts
        CHECK (amount >= 0 AND receivedAmount >= 0 AND changeAmount >= 0);
GO

/* Một đơn chỉ được thanh toán một lần. Ràng buộc này là thứ chặn
   double-charge ở tầng CSDL, không phụ thuộc vào code ứng dụng. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Payments_Order' AND object_id=OBJECT_ID('dbo.Payments'))
    CREATE UNIQUE INDEX UQ_Payments_Order ON dbo.Payments(orderId);
GO

/* Nối sổ quỹ về đúng đơn — trước đây CashEvents không có đường nào
   dẫn ngược về đơn hàng, nên không đối soát ca được. */
IF COL_LENGTH('dbo.CashEvents','orderId')   IS NULL ALTER TABLE dbo.CashEvents ADD orderId INT NULL;
IF COL_LENGTH('dbo.CashEvents','paymentId') IS NULL ALTER TABLE dbo.CashEvents ADD paymentId INT NULL;
GO

DELETE FROM dbo.Payments WHERE orderId NOT IN (SELECT id FROM dbo.Orders);
UPDATE dbo.CashEvents SET orderId = NULL
    WHERE orderId IS NOT NULL AND orderId NOT IN (SELECT id FROM dbo.Orders);
UPDATE dbo.CashEvents SET paymentId = NULL
    WHERE paymentId IS NOT NULL AND paymentId NOT IN (SELECT id FROM dbo.Payments);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Orders')
    ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Orders
        FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Orders')
    ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Orders
        FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Payments')
    ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Payments
        FOREIGN KEY (paymentId) REFERENCES dbo.Payments(id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Payments_PaidAt' AND object_id=OBJECT_ID('dbo.Payments'))
    CREATE NONCLUSTERED INDEX IX_Payments_PaidAt ON dbo.Payments(paidAt DESC);
GO


/* ══════════════════════════════════════════════════════════════
   #3  SỔ CÁI KHO
   ══════════════════════════════════════════════════════════════ */
PRINT N'── #3 StockTransactions ───────────────────────────────────';

IF OBJECT_ID('dbo.StockTransactions','U') IS NULL
CREATE TABLE dbo.StockTransactions (
    id           INT IDENTITY PRIMARY KEY,
    ingredientId VARCHAR(50) NOT NULL,
    type         VARCHAR(10) NOT NULL,       -- IN | OUT | ADJUST
    quantity     INT NOT NULL,               -- IN dương, OUT âm
    stockAfter   INT NOT NULL,
    unitCost     INT NOT NULL DEFAULT 0,     -- giá nhập TẠI THỜI ĐIỂM ĐÓ
    orderId      INT NULL,                   -- xuất kho do đơn nào
    actorRole    VARCHAR(20)  NULL,
    actorName    NVARCHAR(120) NULL,
    note         NVARCHAR(255) NULL,
    createdAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_StockTx_Type')
    ALTER TABLE dbo.StockTransactions ADD CONSTRAINT CK_StockTx_Type
        CHECK (type IN ('IN','OUT','ADJUST'));
GO

DELETE FROM dbo.StockTransactions WHERE ingredientId NOT IN (SELECT id FROM dbo.Inventory);
UPDATE dbo.StockTransactions SET orderId = NULL
    WHERE orderId IS NOT NULL AND orderId NOT IN (SELECT id FROM dbo.Orders);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StockTx_Inventory')
    ALTER TABLE dbo.StockTransactions ADD CONSTRAINT FK_StockTx_Inventory
        FOREIGN KEY (ingredientId) REFERENCES dbo.Inventory(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StockTx_Orders')
    ALTER TABLE dbo.StockTransactions ADD CONSTRAINT FK_StockTx_Orders
        FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_StockTx_Ingredient' AND object_id=OBJECT_ID('dbo.StockTransactions'))
    CREATE NONCLUSTERED INDEX IX_StockTx_Ingredient ON dbo.StockTransactions(ingredientId, id DESC);
GO

/* Dòng mở sổ cho tồn kho hiện có. Không có bước này thì SUM(quantity)
   sẽ không bao giờ khớp Inventory.stock và mọi đối soát về sau đều sai. */
INSERT INTO dbo.StockTransactions (ingredientId, type, quantity, stockAfter, unitCost, actorRole, actorName, note)
SELECT i.id, 'ADJUST', i.stock, i.stock, i.importCost, 'system', N'Khởi tạo sổ',
       N'Số dư đầu kỳ khi bắt đầu ghi sổ cái'
FROM   dbo.Inventory i
WHERE  NOT EXISTS (SELECT 1 FROM dbo.StockTransactions s WHERE s.ingredientId = i.id);
GO


/* ══════════════════════════════════════════════════════════════
   #4  VAI TRÒ & LIÊN KẾT NHÂN SỰ ↔ TÀI KHOẢN
   ══════════════════════════════════════════════════════════════ */
PRINT N'── #4 Roles + Users.staffId ───────────────────────────────';

IF OBJECT_ID('dbo.Roles','U') IS NULL
CREATE TABLE dbo.Roles (
    code      VARCHAR(20) PRIMARY KEY,
    nameVi    NVARCHAR(50) NOT NULL,
    nameEn    VARCHAR(50)  NOT NULL,
    sortOrder INT NOT NULL DEFAULT 0
);
GO

MERGE dbo.Roles AS t
USING (VALUES
    ('admin',   N'Quản trị', 'Admin',   1),
    ('barista', N'Pha chế',  'Barista', 2),
    ('cashier', N'Thu ngân', 'Cashier', 3),
    ('runner',  N'Bồi bàn',  'Waiter',  4)
) AS s(code, nameVi, nameEn, sortOrder)
ON t.code = s.code
WHEN MATCHED THEN UPDATE SET nameVi=s.nameVi, nameEn=s.nameEn, sortOrder=s.sortOrder
WHEN NOT MATCHED THEN INSERT(code,nameVi,nameEn,sortOrder) VALUES(s.code,s.nameVi,s.nameEn,s.sortOrder);
GO

/* Chuẩn hoá Shifts.assignedRole về ĐÚNG mã trong Roles.
   Trước đây bảng này ghi 'Barista' còn Users ghi 'barista' — cùng khái niệm,
   khác cả chữ hoa thường, không bảng nào làm trọng tài. */
UPDATE dbo.Shifts SET assignedRole = 'barista' WHERE assignedRole IN ('Barista','BARISTA');
UPDATE dbo.Shifts SET assignedRole = 'cashier' WHERE assignedRole IN ('Cashier','CASHIER');
UPDATE dbo.Shifts SET assignedRole = 'runner'  WHERE assignedRole IN ('Waiter','WAITER','Runner','RUNNER');
UPDATE dbo.Shifts SET assignedRole = NULL
    WHERE assignedRole IS NOT NULL AND assignedRole NOT IN (SELECT code FROM dbo.Roles);
GO

IF COL_LENGTH('dbo.Users','staffId') IS NULL ALTER TABLE dbo.Users ADD staffId INT NULL;
GO

UPDATE dbo.Users SET staffId = NULL
    WHERE staffId IS NOT NULL AND staffId NOT IN (SELECT id FROM dbo.Staff);
UPDATE dbo.Users SET role = 'barista' WHERE role NOT IN (SELECT code FROM dbo.Roles);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Roles')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Roles
        FOREIGN KEY (role) REFERENCES dbo.Roles(code);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Staff')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Staff
        FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Roles')
    ALTER TABLE dbo.Shifts ADD CONSTRAINT FK_Shifts_Roles
        FOREIGN KEY (assignedRole) REFERENCES dbo.Roles(code);
GO

/* Trách nhiệm phải là QUAN HỆ, không phải một chuỗi tên chép vào log.
   Có staffId thì mới thống kê được "ai làm gì" mà không sợ trùng tên. */
IF COL_LENGTH('dbo.SystemLogs','staffId') IS NULL ALTER TABLE dbo.SystemLogs ADD staffId INT NULL;
IF COL_LENGTH('dbo.CashEvents','staffId') IS NULL ALTER TABLE dbo.CashEvents ADD staffId INT NULL;
GO

UPDATE dbo.SystemLogs SET staffId = NULL WHERE staffId IS NOT NULL AND staffId NOT IN (SELECT id FROM dbo.Staff);
UPDATE dbo.CashEvents SET staffId = NULL WHERE staffId IS NOT NULL AND staffId NOT IN (SELECT id FROM dbo.Staff);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_SystemLogs_Staff')
    ALTER TABLE dbo.SystemLogs ADD CONSTRAINT FK_SystemLogs_Staff
        FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Staff')
    ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Staff
        FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Staff')
    ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Staff
        FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Users')
    ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Users
        FOREIGN KEY (cashierUsername) REFERENCES dbo.Users(username);
GO


/* ══════════════════════════════════════════════════════════════
   KIỂM TRA
   ══════════════════════════════════════════════════════════════ */
PRINT N'── Kết quả ────────────────────────────────────────────────';

SELECT 'Bảng' AS muc, COUNT(*) AS so_luong FROM sys.tables
UNION ALL SELECT 'Khoá ngoại', COUNT(*) FROM sys.foreign_keys
UNION ALL SELECT 'Đơn đã có tableId', COUNT(*) FROM dbo.Orders WHERE tableId IS NOT NULL
UNION ALL SELECT 'Đơn CHƯA ghép được bàn', COUNT(*) FROM dbo.Orders WHERE tableId IS NULL
UNION ALL SELECT 'Dòng sổ cái kho', COUNT(*) FROM dbo.StockTransactions
UNION ALL SELECT 'Vai trò', COUNT(*) FROM dbo.Roles;

PRINT N'';
PRINT N'-- Doanh thu theo TẦNG: câu này trước đây KHÔNG viết được --';
SELECT  t.floorNo               AS tang,
        COUNT(DISTINCT o.id)    AS so_don,
        ISNULL(SUM(o.total), 0) AS doanh_thu
FROM    dbo.Orders o
JOIN    dbo.Tables t ON t.id = o.tableId
WHERE   o.status = 'Paid'
GROUP BY t.floorNo
ORDER BY t.floorNo;

PRINT N'';
PRINT N'-- Đối soát sổ cái kho: không dòng nào = tồn kho khớp sổ --';
SELECT  i.id, i.name, i.stock AS ton_hien_tai,
        ISNULL(SUM(s.quantity), 0) AS tong_so_cai,
        i.stock - ISNULL(SUM(s.quantity), 0) AS chenh_lech
FROM    dbo.Inventory i
LEFT JOIN dbo.StockTransactions s ON s.ingredientId = i.id
GROUP BY i.id, i.name, i.stock
HAVING  i.stock <> ISNULL(SUM(s.quantity), 0);
GO

PRINT N'';
PRINT N'XONG. Khởi động lại Tomcat.';
GO
