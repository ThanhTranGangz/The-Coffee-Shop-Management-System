/* ══════════════════════════════════════════════════════════════
   CoffeeShopLite — TÀI KHOẢN KHÁCH HÀNG & TÍCH ĐIỂM
   Chạy SAU setup_database.sql. An toàn khi chạy lại nhiều lần.

   Bổ sung:
     • dbo.Customers          — tài khoản khách (SĐT + mật khẩu đã hash)
     • dbo.PointTransactions  — SỔ CÁI điểm, mọi lần cộng/trừ đều có dòng
     • Orders.customerId      — khoá ngoại thật, thay cho customerPhone rời rạc
     • Orders.subtotal / discountAmount / pointsEarned / pointsRedeemed

   Quy tắc nghiệp vụ:
     • Tích điểm : 10.000đ (đã trả) = 1 điểm, cộng khi đơn chuyển Paid
     • Đổi điểm : 1 điểm = 1.000đ, tối thiểu 10 điểm,
                  không vượt quá 50% tiền hàng của đơn
     • Hạng     : Đồng < 1.000.000đ ≤ Bạc < 3.000.000đ ≤ Vàng (theo tổng chi tiêu)
   ══════════════════════════════════════════════════════════════ */

USE CoffeeShopLite;
GO

PRINT N'── A. Bảng Customers ──────────────────────────────────────';

IF OBJECT_ID('dbo.Customers','U') IS NULL
CREATE TABLE dbo.Customers (
    id           INT IDENTITY PRIMARY KEY,
    phone        VARCHAR(20)   NOT NULL,
    passwordHash VARCHAR(64)   NOT NULL,   -- SHA-256(salt + password), hex thường
    passwordSalt VARCHAR(32)   NOT NULL,   -- 16 byte ngẫu nhiên, hex thường
    fullName     NVARCHAR(120) NOT NULL,
    points       INT      NOT NULL DEFAULT 0,   -- số dư điểm hiện tại
    totalSpent   INT      NOT NULL DEFAULT 0,   -- luỹ kế tiền đã thanh toán
    orderCount   INT      NOT NULL DEFAULT 0,
    tier         VARCHAR(10) NOT NULL DEFAULT 'Bronze',  -- Bronze | Silver | Gold
    active       BIT      NOT NULL DEFAULT 1,
    createdAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

/* Một số điện thoại = một tài khoản. Đây là ràng buộc, không phải quy ước. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Customers_Phone' AND object_id=OBJECT_ID('dbo.Customers'))
    CREATE UNIQUE INDEX UQ_Customers_Phone ON dbo.Customers(phone);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Customers_Points')
    ALTER TABLE dbo.Customers ADD CONSTRAINT CK_Customers_Points CHECK (points >= 0);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Customers_Tier')
    ALTER TABLE dbo.Customers ADD CONSTRAINT CK_Customers_Tier CHECK (tier IN ('Bronze','Silver','Gold'));
GO

PRINT N'── B. Sổ cái điểm PointTransactions ───────────────────────';

IF OBJECT_ID('dbo.PointTransactions','U') IS NULL
CREATE TABLE dbo.PointTransactions (
    id           INT IDENTITY PRIMARY KEY,
    customerId   INT NOT NULL,
    orderId      INT NULL,
    type         VARCHAR(10)  NOT NULL,   -- EARN | REDEEM | ADJUST
    points       INT NOT NULL,            -- EARN dương, REDEEM âm
    balanceAfter INT NOT NULL,
    note         NVARCHAR(255) NULL,
    createdAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_PointTx_Type')
    ALTER TABLE dbo.PointTransactions ADD CONSTRAINT CK_PointTx_Type CHECK (type IN ('EARN','REDEEM','ADJUST'));
GO

PRINT N'── C. Bổ sung cột cho Orders ──────────────────────────────';

IF COL_LENGTH('dbo.Orders','customerId')     IS NULL ALTER TABLE dbo.Orders ADD customerId INT NULL;
IF COL_LENGTH('dbo.Orders','subtotal')       IS NULL ALTER TABLE dbo.Orders ADD subtotal INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','discountAmount') IS NULL ALTER TABLE dbo.Orders ADD discountAmount INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','pointsEarned')   IS NULL ALTER TABLE dbo.Orders ADD pointsEarned INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','pointsRedeemed') IS NULL ALTER TABLE dbo.Orders ADD pointsRedeemed INT NOT NULL DEFAULT 0;
GO

/* Đơn cũ chưa có subtotal: tiền hàng = tiền phải trả vì chưa từng có giảm giá. */
UPDATE dbo.Orders SET subtotal = total WHERE subtotal = 0 AND total > 0;
GO

PRINT N'── D. Khoá ngoại ──────────────────────────────────────────';

DELETE FROM dbo.PointTransactions WHERE customerId NOT IN (SELECT id FROM dbo.Customers);
UPDATE dbo.PointTransactions SET orderId = NULL
    WHERE orderId IS NOT NULL AND orderId NOT IN (SELECT id FROM dbo.Orders);
UPDATE dbo.Orders SET customerId = NULL
    WHERE customerId IS NOT NULL AND customerId NOT IN (SELECT id FROM dbo.Customers);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Customers')
    ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (customerId) REFERENCES dbo.Customers(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_PointTx_Customers')
    ALTER TABLE dbo.PointTransactions ADD CONSTRAINT FK_PointTx_Customers
        FOREIGN KEY (customerId) REFERENCES dbo.Customers(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_PointTx_Orders')
    ALTER TABLE dbo.PointTransactions ADD CONSTRAINT FK_PointTx_Orders
        FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);
GO

PRINT N'── E. Index ───────────────────────────────────────────────';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_Customer' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_Customer ON dbo.Orders(customerId, id DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PointTx_Customer' AND object_id=OBJECT_ID('dbo.PointTransactions'))
    CREATE NONCLUSTERED INDEX IX_PointTx_Customer ON dbo.PointTransactions(customerId, id DESC);
GO

PRINT N'── F. Tài khoản khách mẫu ─────────────────────────────────';

/* KHÔNG seed hash mật khẩu bằng SQL. Salt là ngẫu nhiên và hash phải do
   đúng thuật toán trong utils.PasswordUtils sinh ra — chép tay một chuỗi hex
   vào đây thì tài khoản sẽ không bao giờ đăng nhập được.
   Hai tài khoản demo (0901234567 / 0912345678, mật khẩu 123456) được
   CustomerDAO.seedDemoAccounts() tạo khi Tomcat khởi động. */

PRINT N'── G. Kiểm tra ────────────────────────────────────────────';

SELECT 'Khách hàng' AS muc, COUNT(*) AS so_luong FROM dbo.Customers
UNION ALL SELECT 'Giao dịch điểm', COUNT(*) FROM dbo.PointTransactions
UNION ALL SELECT 'Khoá ngoại (toàn DB)', COUNT(*) FROM sys.foreign_keys;
GO

PRINT N'';
PRINT N'XONG. Khởi động lại Tomcat — CustomerDAO sẽ tạo 2 tài khoản demo';
PRINT N'0901234567 và 0912345678, mật khẩu 123456.';
GO
