/* ══════════════════════════════════════════════════════════════════════════
   CoffeeShopLite — SCRIPT CƠ SỞ DỮ LIỆU DUY NHẤT
   ══════════════════════════════════════════════════════════════════════════

   Chạy MỘT file này là đủ. An toàn khi chạy lại nhiều lần (idempotent).

   FILE NÀY THAY THẾ TOÀN BỘ:
     setup_database.sql · customer_loyalty.sql · schema_fix_p0.sql
     staff_accounts.sql · database_lite.sql · update_db.sql
     test_data.sql · seed_staff_shifts.sql

   BA FILE CŨ ĐÃ HỎNG, KHÔNG GỘP VÀO — chạy chúng hôm nay sẽ lỗi:
     • update_db.sql  và  test_data.sql
       Chèn vào dbo.Staff các cột role, pin, shift, username, password,
       overtime. LiteService.init() đã DROP hết những cột đó.
       → "Invalid column name 'role'"
     • database_lite.sql
       Tạo dbo.Users KHÔNG có cột role nhưng câu MERGE bên dưới lại chèn
       role → lỗi ngay trên CSDL mới tinh.
     • seed_staff_shifts.sql
       Trùng với phần seed nhân viên ở đây, và ghi vai trò kiểu 'Barista'
       (chữ hoa) đã bị thay bằng mã 'barista'.
     • CoffeeShopLite_backup.sql là bản dump toàn bộ CSDL để khôi phục,
       KHÔNG phải script cài đặt. Giữ riêng, đừng chạy chung.

   PHẦN NÀY KHÔNG LÀM: Bàn, Thực đơn, Nguyên liệu và Công thức do
   LiteService.init() tự sinh khi Tomcat khởi động. Chạy script xong thì
   khởi động lại Tomcat.

   ──────────────────────────────────────────────────────────────────────────
   THỨ TỰ THỰC HIỆN (quan trọng, đừng đảo)
     1. Tạo CSDL và bảng
     2. Bổ sung cột cho CSDL cũ
     3. Dữ liệu tham chiếu (Roles trước, vì khoá ngoại phụ thuộc)
     4. Dọn dữ liệu rác  ←  BẮT BUỘC trước bước 5
     5. Khoá ngoại, CHECK, index
     6. Dữ liệu mẫu
     7. Kiểm tra
   ══════════════════════════════════════════════════════════════════════════ */

IF DB_ID(N'CoffeeShopLite') IS NULL CREATE DATABASE CoffeeShopLite;
GO
USE CoffeeShopLite;
GO
SET NOCOUNT ON;
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 1 — TẠO BẢNG
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 1 — Tạo bảng                                       ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

/* ---------- 1.1 Vai trò & tài khoản ---------- */

/* Nguồn sự thật DUY NHẤT cho vai trò. Trước đây mã vai trò nằm rải rác
   dạng chuỗi trong Users.role và Shifts.assignedRole, viết khác nhau
   ('barista' vs 'Barista') mà không bảng nào làm trọng tài.

   isShiftRole tách hai khái niệm bị lẫn lộn:
     • LOẠI TÀI KHOẢN   : admin, staff        (isShiftRole = 0)
     • VAI TRÒ XẾP CA   : barista, cashier, runner (isShiftRole = 1) */
IF OBJECT_ID('dbo.Roles','U') IS NULL
CREATE TABLE dbo.Roles (
    code        VARCHAR(20)  PRIMARY KEY,
    nameVi      NVARCHAR(50) NOT NULL,
    nameEn      VARCHAR(50)  NOT NULL,
    sortOrder   INT NOT NULL DEFAULT 0,
    isShiftRole BIT NOT NULL DEFAULT 1
);

IF OBJECT_ID('dbo.Staff','U') IS NULL
CREATE TABLE dbo.Staff (
    id     INT PRIMARY KEY,
    name   NVARCHAR(120) NOT NULL,
    active BIT NOT NULL DEFAULT 1,
    status VARCHAR(30) NOT NULL DEFAULT 'Active'
);

/* Mỗi nhân viên MỘT tài khoản riêng.
   PIN được băm SHA-256 + salt riêng — không lưu thô như cột password cũ. */
IF OBJECT_ID('dbo.Users','U') IS NULL
CREATE TABLE dbo.Users (
    username VARCHAR(50)   PRIMARY KEY,
    password VARCHAR(100)  NOT NULL,          -- di sản, không dùng để xác thực nữa
    role     VARCHAR(20)   NOT NULL,          -- loại tài khoản, FK → Roles.code
    fullName NVARCHAR(120) NOT NULL,
    staffId  INT NULL,                        -- FK → Staff.id
    pinHash  VARCHAR(64) NULL,                -- SHA-256(salt + pin)
    pinSalt  VARCHAR(32) NULL,
    active   BIT NOT NULL DEFAULT 1
);

IF OBJECT_ID('dbo.Shifts','U') IS NULL
CREATE TABLE dbo.Shifts (
    id           VARCHAR(50)  PRIMARY KEY,
    staffId      INT NOT NULL,
    staffName    NVARCHAR(120) NULL,          -- bản chụp; nguồn thật là Staff.name
    shiftDate    VARCHAR(20)  NOT NULL,
    shiftName    NVARCHAR(50) NOT NULL,
    hours        VARCHAR(50)  NOT NULL,
    status       NVARCHAR(30) NOT NULL,
    notes        NVARCHAR(255) NULL,
    assignedRole VARCHAR(20) NULL             -- FK → Roles.code, PHẢI cùng VARCHAR(20)
);

/* ---------- 1.2 Bàn, thực đơn, kho ---------- */

IF OBJECT_ID('dbo.Tables','U') IS NULL
CREATE TABLE dbo.Tables (
    id      INT IDENTITY PRIMARY KEY,
    name    NVARCHAR(60) NOT NULL,
    code    VARCHAR(40) NULL,
    floorNo INT NULL,
    tableNo INT NULL,
    active  BIT NOT NULL DEFAULT 1
);

IF OBJECT_ID('dbo.MenuItems','U') IS NULL
CREATE TABLE dbo.MenuItems (
    id        INT IDENTITY PRIMARY KEY,
    nameVi    NVARCHAR(120) NOT NULL,
    nameEn    NVARCHAR(120) NOT NULL,
    category  NVARCHAR(60) NOT NULL,
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

IF OBJECT_ID('dbo.Inventory','U') IS NULL
CREATE TABLE dbo.Inventory (
    id         VARCHAR(50) PRIMARY KEY,
    name       NVARCHAR(120) NOT NULL,
    unit       NVARCHAR(20) NOT NULL,
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

/* SỔ CÁI KHO. Trước đây Inventory chỉ có một con số tồn hiện tại — không
   biết ai xuất, xuất khi nào, giá vốn bao nhiêu.
   Bất biến cần giữ: SUM(quantity) của một nguyên liệu = Inventory.stock. */
IF OBJECT_ID('dbo.StockTransactions','U') IS NULL
CREATE TABLE dbo.StockTransactions (
    id           INT IDENTITY PRIMARY KEY,
    ingredientId VARCHAR(50) NOT NULL,
    type         VARCHAR(10) NOT NULL,        -- IN | OUT | ADJUST
    quantity     INT NOT NULL,                -- IN dương, OUT âm
    stockAfter   INT NOT NULL,
    unitCost     INT NOT NULL DEFAULT 0,      -- giá nhập TẠI THỜI ĐIỂM ĐÓ
    orderId      INT NULL,
    actorRole    VARCHAR(20) NULL,
    actorName    NVARCHAR(120) NULL,
    note         NVARCHAR(255) NULL,
    createdAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ---------- 1.3 Khách hàng & tích điểm ---------- */

IF OBJECT_ID('dbo.Customers','U') IS NULL
CREATE TABLE dbo.Customers (
    id           INT IDENTITY PRIMARY KEY,
    phone        VARCHAR(20) NOT NULL,
    passwordHash VARCHAR(64) NOT NULL,        -- SHA-256(salt + password)
    passwordSalt VARCHAR(32) NOT NULL,
    fullName     NVARCHAR(120) NOT NULL,
    points       INT NOT NULL DEFAULT 0,
    totalSpent   INT NOT NULL DEFAULT 0,
    orderCount   INT NOT NULL DEFAULT 0,
    tier         VARCHAR(10) NOT NULL DEFAULT 'Bronze',
    active       BIT NOT NULL DEFAULT 1,
    createdAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* SỔ CÁI ĐIỂM. Số dư điểm không bao giờ được sửa bằng UPDATE đơn lẻ —
   mọi thay đổi đều sinh một dòng ở đây để đối soát lại được. */
IF OBJECT_ID('dbo.PointTransactions','U') IS NULL
CREATE TABLE dbo.PointTransactions (
    id           INT IDENTITY PRIMARY KEY,
    customerId   INT NOT NULL,
    orderId      INT NULL,
    type         VARCHAR(10) NOT NULL,        -- EARN | REDEEM | ADJUST
    points       INT NOT NULL,                -- EARN dương, REDEEM âm
    balanceAfter INT NOT NULL,
    note         NVARCHAR(255) NULL,
    createdAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ---------- 1.4 Đơn hàng & thanh toán ---------- */

/* tableName ĐƯỢC GIỮ CÓ CHỦ Ý: từ nay nó là BẢN CHỤP tên bàn lúc đặt đơn,
   cùng nguyên tắc với OrderItems.itemName/price. Quan hệ thật là tableId. */
IF OBJECT_ID('dbo.Orders','U') IS NULL
CREATE TABLE dbo.Orders (
    id             INT IDENTITY PRIMARY KEY,
    orderNumber    INT NULL UNIQUE,
    tableId        INT NULL,                  -- FK → Tables.id
    tableName      NVARCHAR(60) NOT NULL,     -- bản chụp
    customerId     INT NULL,                  -- FK → Customers.id
    customerPhone  VARCHAR(20) NULL,
    status         VARCHAR(30) NOT NULL DEFAULT 'Pending',
    orderType      VARCHAR(20) NOT NULL DEFAULT 'DINE_IN', -- DINE_IN | TAKEAWAY
    subtotal       INT NOT NULL DEFAULT 0,    -- tiền hàng TRƯỚC giảm giá
    discountAmount INT NOT NULL DEFAULT 0,    -- giảm từ điểm
    promoDiscount  INT NOT NULL DEFAULT 0,
    manualDiscount INT NOT NULL DEFAULT 0,
    discountReason NVARCHAR(255) NULL,
    promotionId    INT NULL,
    taxAmount      INT NOT NULL DEFAULT 0,
    serviceCharge  INT NOT NULL DEFAULT 0,
    tipAmount      INT NOT NULL DEFAULT 0,
    total          INT NOT NULL DEFAULT 0,    -- số tiền PHẢI TRẢ (chưa gồm tip)
    pointsEarned   INT NOT NULL DEFAULT 0,
    pointsRedeemed INT NOT NULL DEFAULT 0,
    note           NVARCHAR(255) NULL,
    createdAt      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    splitLocked    BIT NOT NULL DEFAULT 0,
    invoicePrinted BIT NOT NULL DEFAULT 0,
    cancelReason   NVARCHAR(255) NULL,
    cancelledAt    DATETIME2 NULL,
    cancelledByRole VARCHAR(20) NULL,
    cancelledByName NVARCHAR(120) NULL
);

IF OBJECT_ID('dbo.OrderItems','U') IS NULL
CREATE TABLE dbo.OrderItems (
    id          INT IDENTITY PRIMARY KEY,
    orderId     INT NOT NULL,
    menuItemId  INT NOT NULL,
    itemName    NVARCHAR(120) NOT NULL,       -- bản chụp, giữ giá lịch sử
    itemSize    VARCHAR(20) NULL,
    quantity    INT NOT NULL,
    price       INT NOT NULL,                 -- bản chụp
    preparedQty INT NOT NULL DEFAULT 0
);

/* TẦNG THANH TOÁN. Trước đây "đã trả" chỉ là chuỗi 'Paid' trong Orders.status:
   không biết trả bằng gì, khách đưa bao nhiêu, ai thu. */
IF OBJECT_ID('dbo.Payments','U') IS NULL
CREATE TABLE dbo.Payments (
    id              INT IDENTITY PRIMARY KEY,
    orderId         INT NOT NULL,
    method          VARCHAR(20) NOT NULL,     -- CASH | TRANSFER
    amount          INT NOT NULL,
    receivedAmount  INT NOT NULL,
    changeAmount    INT NOT NULL,
    cashierUsername VARCHAR(50) NULL,
    cashierName     NVARCHAR(120) NULL,
    staffId         INT NULL,                 -- ai thực sự đứng quầy
    note            NVARCHAR(255) NULL,
    paidAt          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.Refunds','U') IS NULL
CREATE TABLE dbo.Refunds (
    id         INT IDENTITY PRIMARY KEY,
    orderId    INT NOT NULL,
    paymentId  INT NULL,
    amount     INT NOT NULL,
    method     VARCHAR(20) NULL,
    reason     NVARCHAR(255) NOT NULL,
    restocked  BIT NOT NULL DEFAULT 1,
    actorRole  VARCHAR(20) NULL,
    actorName  NVARCHAR(120) NULL,
    staffId    INT NULL,
    refundedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.Promotions','U') IS NULL
CREATE TABLE dbo.Promotions (
    id            INT IDENTITY PRIMARY KEY,
    code          VARCHAR(40) NOT NULL,
    nameVi        NVARCHAR(120) NOT NULL,
    nameEn        NVARCHAR(120) NOT NULL,
    discountType  VARCHAR(10) NOT NULL,       -- PERCENT | AMOUNT
    discountValue INT NOT NULL,
    minSubtotal   INT NOT NULL DEFAULT 0,
    maxDiscount   INT NOT NULL DEFAULT 0,
    startAt       DATETIME2 NULL,
    endAt         DATETIME2 NULL,
    maxUses       INT NOT NULL DEFAULT 0,
    usedCount     INT NOT NULL DEFAULT 0,
    active        BIT NOT NULL DEFAULT 1,
    createdAt     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.PromotionRedemptions','U') IS NULL
CREATE TABLE dbo.PromotionRedemptions (
    id             INT IDENTITY PRIMARY KEY,
    promotionId    INT NOT NULL,
    orderId        INT NOT NULL,
    discountAmount INT NOT NULL,
    createdAt      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ---------- 1.5 Sổ quỹ, nhật ký, trạng thái ---------- */

IF OBJECT_ID('dbo.CashEvents','U') IS NULL
CREATE TABLE dbo.CashEvents (
    id            INT IDENTITY PRIMARY KEY,
    eventType     VARCHAR(30) NOT NULL,       -- PAYMENT | CASHIER_COUNT | ADMIN_WITHDRAW
    amount        INT NOT NULL,
    balanceAfter  INT NOT NULL,
    note          NVARCHAR(255) NULL,
    actorRole     VARCHAR(20) NULL,
    actorName     NVARCHAR(120) NULL,
    staffId       INT NULL,
    orderId       INT NULL,
    paymentId     INT NULL,
    seenByCashier BIT NOT NULL DEFAULT 1,
    createdAt     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.SystemLogs','U') IS NULL
CREATE TABLE dbo.SystemLogs (
    id         INT IDENTITY PRIMARY KEY,
    actorRole  VARCHAR(20) NOT NULL,
    actorName  NVARCHAR(120) NULL,
    staffId    INT NULL,                      -- trách nhiệm là QUAN HỆ, không phải chuỗi tên
    actionType VARCHAR(40) NOT NULL,
    messageVi  NVARCHAR(400) NOT NULL,
    messageEn  NVARCHAR(400) NOT NULL,
    refId      INT NULL,
    createdAt  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.StoreState','U') IS NULL
CREATE TABLE dbo.StoreState (
    stateKey  VARCHAR(50) PRIMARY KEY,
    intValue  INT NOT NULL,
    updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 2 — BỔ SUNG CỘT CHO CSDL CŨ
   Chỉ chạy thật sự khi nâng cấp từ bản cũ. CSDL mới tinh sẽ bỏ qua hết.
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 2 — Bổ sung cột cho CSDL cũ                        ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

IF COL_LENGTH('dbo.Roles','isShiftRole')        IS NULL ALTER TABLE dbo.Roles ADD isShiftRole BIT NOT NULL DEFAULT 1;

IF COL_LENGTH('dbo.Users','role')               IS NULL ALTER TABLE dbo.Users ADD role VARCHAR(20) NOT NULL DEFAULT 'staff';
IF COL_LENGTH('dbo.Users','staffId')            IS NULL ALTER TABLE dbo.Users ADD staffId INT NULL;
IF COL_LENGTH('dbo.Users','pinHash')            IS NULL ALTER TABLE dbo.Users ADD pinHash VARCHAR(64) NULL;
IF COL_LENGTH('dbo.Users','pinSalt')            IS NULL ALTER TABLE dbo.Users ADD pinSalt VARCHAR(32) NULL;
IF COL_LENGTH('dbo.Users','active')             IS NULL ALTER TABLE dbo.Users ADD active BIT NOT NULL DEFAULT 1;

IF COL_LENGTH('dbo.Tables','code')              IS NULL ALTER TABLE dbo.Tables ADD code VARCHAR(40) NULL;
IF COL_LENGTH('dbo.Tables','floorNo')           IS NULL ALTER TABLE dbo.Tables ADD floorNo INT NULL;
IF COL_LENGTH('dbo.Tables','tableNo')           IS NULL ALTER TABLE dbo.Tables ADD tableNo INT NULL;

IF COL_LENGTH('dbo.MenuItems','imagePath')      IS NULL ALTER TABLE dbo.MenuItems ADD imagePath VARCHAR(255) NULL;

IF COL_LENGTH('dbo.Orders','tableId')           IS NULL ALTER TABLE dbo.Orders ADD tableId INT NULL;
IF COL_LENGTH('dbo.Orders','customerId')        IS NULL ALTER TABLE dbo.Orders ADD customerId INT NULL;
IF COL_LENGTH('dbo.Orders','subtotal')          IS NULL ALTER TABLE dbo.Orders ADD subtotal INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','discountAmount')    IS NULL ALTER TABLE dbo.Orders ADD discountAmount INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','pointsEarned')      IS NULL ALTER TABLE dbo.Orders ADD pointsEarned INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','pointsRedeemed')    IS NULL ALTER TABLE dbo.Orders ADD pointsRedeemed INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','splitLocked')       IS NULL ALTER TABLE dbo.Orders ADD splitLocked BIT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','invoicePrinted')    IS NULL ALTER TABLE dbo.Orders ADD invoicePrinted BIT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','orderType')         IS NULL ALTER TABLE dbo.Orders ADD orderType VARCHAR(20) NOT NULL CONSTRAINT DF_Orders_orderType_mig DEFAULT 'DINE_IN';
IF COL_LENGTH('dbo.Orders','cancelReason')      IS NULL ALTER TABLE dbo.Orders ADD cancelReason NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.Orders','cancelledAt')       IS NULL ALTER TABLE dbo.Orders ADD cancelledAt DATETIME2 NULL;
IF COL_LENGTH('dbo.Orders','cancelledByRole')   IS NULL ALTER TABLE dbo.Orders ADD cancelledByRole VARCHAR(20) NULL;
IF COL_LENGTH('dbo.Orders','cancelledByName')   IS NULL ALTER TABLE dbo.Orders ADD cancelledByName NVARCHAR(120) NULL;
IF COL_LENGTH('dbo.Orders','promotionId')       IS NULL ALTER TABLE dbo.Orders ADD promotionId INT NULL;
IF COL_LENGTH('dbo.Orders','promoDiscount')     IS NULL ALTER TABLE dbo.Orders ADD promoDiscount INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','manualDiscount')    IS NULL ALTER TABLE dbo.Orders ADD manualDiscount INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','discountReason')    IS NULL ALTER TABLE dbo.Orders ADD discountReason NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.Orders','taxAmount')         IS NULL ALTER TABLE dbo.Orders ADD taxAmount INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','serviceCharge')     IS NULL ALTER TABLE dbo.Orders ADD serviceCharge INT NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Orders','tipAmount')         IS NULL ALTER TABLE dbo.Orders ADD tipAmount INT NOT NULL DEFAULT 0;

IF OBJECT_ID('dbo.Refunds','U') IS NULL
CREATE TABLE dbo.Refunds (
    id INT IDENTITY PRIMARY KEY, orderId INT NOT NULL, paymentId INT NULL, amount INT NOT NULL,
    method VARCHAR(20) NULL, reason NVARCHAR(255) NOT NULL, restocked BIT NOT NULL DEFAULT 1,
    actorRole VARCHAR(20) NULL, actorName NVARCHAR(120) NULL, staffId INT NULL,
    refundedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
IF OBJECT_ID('dbo.Promotions','U') IS NULL
CREATE TABLE dbo.Promotions (
    id INT IDENTITY PRIMARY KEY, code VARCHAR(40) NOT NULL, nameVi NVARCHAR(120) NOT NULL, nameEn NVARCHAR(120) NOT NULL,
    discountType VARCHAR(10) NOT NULL, discountValue INT NOT NULL, minSubtotal INT NOT NULL DEFAULT 0,
    maxDiscount INT NOT NULL DEFAULT 0, startAt DATETIME2 NULL, endAt DATETIME2 NULL,
    maxUses INT NOT NULL DEFAULT 0, usedCount INT NOT NULL DEFAULT 0, active BIT NOT NULL DEFAULT 1,
    createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
IF OBJECT_ID('dbo.PromotionRedemptions','U') IS NULL
CREATE TABLE dbo.PromotionRedemptions (
    id INT IDENTITY PRIMARY KEY, promotionId INT NOT NULL, orderId INT NOT NULL,
    discountAmount INT NOT NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

IF COL_LENGTH('dbo.OrderItems','itemSize')      IS NULL ALTER TABLE dbo.OrderItems ADD itemSize VARCHAR(20) NULL;
IF COL_LENGTH('dbo.OrderItems','preparedQty')   IS NULL ALTER TABLE dbo.OrderItems ADD preparedQty INT NOT NULL DEFAULT 0;

IF COL_LENGTH('dbo.CashEvents','seenByCashier') IS NULL ALTER TABLE dbo.CashEvents ADD seenByCashier BIT NOT NULL DEFAULT 1;
IF COL_LENGTH('dbo.CashEvents','orderId')       IS NULL ALTER TABLE dbo.CashEvents ADD orderId INT NULL;
IF COL_LENGTH('dbo.CashEvents','paymentId')     IS NULL ALTER TABLE dbo.CashEvents ADD paymentId INT NULL;
IF COL_LENGTH('dbo.CashEvents','staffId')       IS NULL ALTER TABLE dbo.CashEvents ADD staffId INT NULL;

IF COL_LENGTH('dbo.SystemLogs','staffId')       IS NULL ALTER TABLE dbo.SystemLogs ADD staffId INT NULL;

IF COL_LENGTH('dbo.Shifts','staffName')         IS NULL ALTER TABLE dbo.Shifts ADD staffName NVARCHAR(120) NULL;
IF COL_LENGTH('dbo.Shifts','assignedRole')      IS NULL ALTER TABLE dbo.Shifts ADD assignedRole VARCHAR(20) NULL;
GO

/* SQL Server đòi hai đầu khoá ngoại phải CÙNG kiểu VÀ CÙNG ĐỘ DÀI.
   Bản cũ tạo Shifts.assignedRole là VARCHAR(30) trong khi Roles.code là
   VARCHAR(20) → tạo FK_Shifts_Roles sẽ lỗi:
     Msg 1753 — Column 'dbo.Roles.code' is not the same length or scale
                as referencing column 'Shifts.assignedRole'
   Phải gỡ khoá ngoại và index đang bám vào cột trước khi đổi kiểu. */
IF COL_LENGTH('dbo.Shifts','assignedRole') <> 20
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Roles')
        ALTER TABLE dbo.Shifts DROP CONSTRAINT FK_Shifts_Roles;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Shifts_Date' AND object_id=OBJECT_ID('dbo.Shifts'))
        DROP INDEX IX_Shifts_Date ON dbo.Shifts;
    ALTER TABLE dbo.Shifts ALTER COLUMN assignedRole VARCHAR(20) NULL;
    PRINT N'   Đã ép Shifts.assignedRole về VARCHAR(20) cho khớp Roles.code.';
END
GO

/* Cùng lý do: Users.role phải khớp Roles.code. */
IF COL_LENGTH('dbo.Users','role') <> 20
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Roles')
        ALTER TABLE dbo.Users DROP CONSTRAINT FK_Users_Roles;
    ALTER TABLE dbo.Users ALTER COLUMN role VARCHAR(20) NOT NULL;
    PRINT N'   Đã ép Users.role về VARCHAR(20) cho khớp Roles.code.';
END
GO

/* Shifts.staffName phải cho phép NULL.
   Nó là dữ liệu thừa (ShiftDAO.getAll() đã JOIN sang Staff để lấy tên),
   nhưng để NOT NULL thì mọi lần thêm ca mới đều chết với
   "Cannot insert the value NULL into column 'staffName'". */
UPDATE dbo.Shifts SET staffName = N'' WHERE staffName IS NULL;
GO
ALTER TABLE dbo.Shifts ALTER COLUMN staffName NVARCHAR(120) NULL;
GO

ALTER TABLE dbo.OrderItems ALTER COLUMN itemSize VARCHAR(20) NULL;
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 3 — DỮ LIỆU THAM CHIẾU
   Roles phải có TRƯỚC vì khoá ngoại ở Phần 5 phụ thuộc vào nó.
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 3 — Dữ liệu tham chiếu                             ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

MERGE dbo.Roles AS t
USING (VALUES
    ('admin',   N'Quản trị',  'Admin',   1, 0),   -- loại tài khoản
    ('staff',   N'Nhân viên', 'Staff',   2, 0),   -- loại tài khoản
    ('barista', N'Pha chế',   'Barista', 3, 1),   -- vai trò xếp ca
    ('cashier', N'Thu ngân',  'Cashier', 4, 1),
    ('runner',  N'Bồi bàn',   'Waiter',  5, 1)
) AS s(code, nameVi, nameEn, sortOrder, isShiftRole)
ON t.code = s.code
WHEN MATCHED THEN UPDATE SET nameVi=s.nameVi, nameEn=s.nameEn,
                             sortOrder=s.sortOrder, isShiftRole=s.isShiftRole
WHEN NOT MATCHED THEN INSERT(code,nameVi,nameEn,sortOrder,isShiftRole)
     VALUES(s.code,s.nameVi,s.nameEn,s.sortOrder,s.isShiftRole);

PRINT N'   Vai trò: 5 (2 loại tài khoản + 3 vai trò xếp ca)';
GO

/* 10 nhân viên mẫu. Bỏ qua nếu bạn đã tự thêm nhân viên riêng. */
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

/* Tài khoản admin. Ba tài khoản vị trí dùng chung (barista/cashier/runner)
   được tạo rồi TẮT ngay: không xoá được vì Payments.cashierUsername của dữ
   liệu cũ đang trỏ tới chúng, nhưng cũng không cho đăng nhập nữa.

   Tài khoản CÁ NHÂN của từng nhân viên do LiteService.ensureStaffAccounts()
   tạo khi Tomcat khởi động, vì PIN phải băm bằng đúng thuật toán trong
   utils.PasswordUtils — chép tay chuỗi hex vào đây thì không đăng nhập được. */
MERGE dbo.Users AS t
USING (VALUES
    ('admin',   '8888', 'admin', N'Quản trị coffeshop', 1),
    ('barista', '1111', 'staff', N'Pha chế coffeshop',  0),
    ('cashier', '2222', 'staff', N'Thu ngân coffeshop', 0),
    ('runner',  '3333', 'staff', N'Bồi bàn coffeshop',  0)
) AS s(username, password, role, fullName, active)
ON t.username = s.username
WHEN MATCHED THEN UPDATE SET role = s.role, fullName = s.fullName, active = s.active
WHEN NOT MATCHED THEN INSERT(username,password,role,fullName,active)
     VALUES(s.username,s.password,s.role,s.fullName,s.active);
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 4 — DỌN DỮ LIỆU RÁC
   BẮT BUỘC chạy trước Phần 5: chỉ một dòng rác là cả ràng buộc không tạo được.
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 4 — Dọn dữ liệu rác                                ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

/* 4.1 Chuẩn hoá vai trò về đúng mã trong Roles.
       Trước đây Shifts ghi 'Barista' còn Users ghi 'barista'. */
UPDATE dbo.Shifts SET assignedRole = 'barista' WHERE assignedRole IN ('Barista','BARISTA');
UPDATE dbo.Shifts SET assignedRole = 'cashier' WHERE assignedRole IN ('Cashier','CASHIER');
UPDATE dbo.Shifts SET assignedRole = 'runner'  WHERE assignedRole IN ('Waiter','WAITER','Runner','RUNNER');
UPDATE dbo.Shifts SET assignedRole = NULL
    WHERE assignedRole IS NOT NULL AND assignedRole NOT IN (SELECT code FROM dbo.Roles);

UPDATE dbo.Users SET role = 'staff' WHERE role NOT IN (SELECT code FROM dbo.Roles);
GO

/* 4.2 Ghép đơn cũ về đúng bàn.
       Đây là lần DUY NHẤT được phép ghép bằng tên — sau bước này mọi thứ
       đi qua khoá ngoại Orders.tableId. */
UPDATE o SET o.tableId = t.id
FROM dbo.Orders o JOIN dbo.Tables t ON t.name = o.tableName
WHERE o.tableId IS NULL;

/* Đơn cũ chưa có subtotal: tiền hàng = tiền phải trả vì chưa từng có giảm giá. */
UPDATE dbo.Orders SET subtotal = total WHERE subtotal = 0 AND total > 0;
GO

/* 4.3 Xoá / gỡ tham chiếu mồ côi */
DELETE FROM dbo.MenuItemSizes     WHERE menuItemId   NOT IN (SELECT id FROM dbo.MenuItems);
DELETE FROM dbo.OrderItems        WHERE orderId      NOT IN (SELECT id FROM dbo.Orders);
DELETE FROM dbo.OrderItems        WHERE menuItemId   NOT IN (SELECT id FROM dbo.MenuItems);
DELETE FROM dbo.RecipeItems       WHERE menuItemId   NOT IN (SELECT id FROM dbo.MenuItems);
DELETE FROM dbo.RecipeItems       WHERE ingredientId NOT IN (SELECT id FROM dbo.Inventory);
DELETE FROM dbo.Shifts            WHERE staffId      NOT IN (SELECT id FROM dbo.Staff);
DELETE FROM dbo.Payments          WHERE orderId      NOT IN (SELECT id FROM dbo.Orders);
DELETE FROM dbo.PointTransactions WHERE customerId   NOT IN (SELECT id FROM dbo.Customers);
DELETE FROM dbo.StockTransactions WHERE ingredientId NOT IN (SELECT id FROM dbo.Inventory);

UPDATE dbo.Orders            SET tableId    = NULL WHERE tableId    IS NOT NULL AND tableId    NOT IN (SELECT id FROM dbo.Tables);
UPDATE dbo.Orders            SET customerId = NULL WHERE customerId IS NOT NULL AND customerId NOT IN (SELECT id FROM dbo.Customers);
UPDATE dbo.Users             SET staffId    = NULL WHERE staffId    IS NOT NULL AND staffId    NOT IN (SELECT id FROM dbo.Staff);
UPDATE dbo.SystemLogs        SET staffId    = NULL WHERE staffId    IS NOT NULL AND staffId    NOT IN (SELECT id FROM dbo.Staff);
UPDATE dbo.CashEvents        SET staffId    = NULL WHERE staffId    IS NOT NULL AND staffId    NOT IN (SELECT id FROM dbo.Staff);
UPDATE dbo.CashEvents        SET orderId    = NULL WHERE orderId    IS NOT NULL AND orderId    NOT IN (SELECT id FROM dbo.Orders);
UPDATE dbo.CashEvents        SET paymentId  = NULL WHERE paymentId  IS NOT NULL AND paymentId  NOT IN (SELECT id FROM dbo.Payments);
UPDATE dbo.PointTransactions SET orderId    = NULL WHERE orderId    IS NOT NULL AND orderId    NOT IN (SELECT id FROM dbo.Orders);
UPDATE dbo.StockTransactions SET orderId    = NULL WHERE orderId    IS NOT NULL AND orderId    NOT IN (SELECT id FROM dbo.Orders);
GO

/* Đơn không ghép được về bàn nào chính là bằng chứng cho hậu quả của việc
   lưu tên bàn bằng chuỗi: đổi tên bàn là mất dấu, không khôi phục được. */
DECLARE @orphanOrders INT = (SELECT COUNT(*) FROM dbo.Orders WHERE tableId IS NULL);
IF @orphanOrders > 0
    PRINT N'   CẢNH BÁO: ' + CAST(@orphanOrders AS NVARCHAR(10)) + N' đơn không ghép được về bàn nào.';
ELSE
    PRINT N'   Tất cả đơn đã ghép được về bàn.';
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 5 — KHOÁ NGOẠI, CHECK, INDEX
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 5 — Khoá ngoại, CHECK, index                       ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

/* ---------- 5.1 Khoá ngoại ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_MenuItemSizes_MenuItems')
    ALTER TABLE dbo.MenuItemSizes ADD CONSTRAINT FK_MenuItemSizes_MenuItems FOREIGN KEY (menuItemId) REFERENCES dbo.MenuItems(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_OrderItems_Orders')
    ALTER TABLE dbo.OrderItems ADD CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_OrderItems_MenuItems')
    ALTER TABLE dbo.OrderItems ADD CONSTRAINT FK_OrderItems_MenuItems FOREIGN KEY (menuItemId) REFERENCES dbo.MenuItems(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RecipeItems_MenuItems')
    ALTER TABLE dbo.RecipeItems ADD CONSTRAINT FK_RecipeItems_MenuItems FOREIGN KEY (menuItemId) REFERENCES dbo.MenuItems(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RecipeItems_Inventory')
    ALTER TABLE dbo.RecipeItems ADD CONSTRAINT FK_RecipeItems_Inventory FOREIGN KEY (ingredientId) REFERENCES dbo.Inventory(id);

/* Orders → Tables: bảng Tables hết là hòn đảo trong ERD */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Tables')
    ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Tables FOREIGN KEY (tableId) REFERENCES dbo.Tables(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Customers')
    ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (customerId) REFERENCES dbo.Customers(id);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Orders')
    ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Staff')
    ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Users')
    ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Users FOREIGN KEY (cashierUsername) REFERENCES dbo.Users(username);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Orders')
    ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Payments')
    ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Payments FOREIGN KEY (paymentId) REFERENCES dbo.Payments(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Staff')
    ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_PointTx_Customers')
    ALTER TABLE dbo.PointTransactions ADD CONSTRAINT FK_PointTx_Customers FOREIGN KEY (customerId) REFERENCES dbo.Customers(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_PointTx_Orders')
    ALTER TABLE dbo.PointTransactions ADD CONSTRAINT FK_PointTx_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StockTx_Inventory')
    ALTER TABLE dbo.StockTransactions ADD CONSTRAINT FK_StockTx_Inventory FOREIGN KEY (ingredientId) REFERENCES dbo.Inventory(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StockTx_Orders')
    ALTER TABLE dbo.StockTransactions ADD CONSTRAINT FK_StockTx_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Staff')
    ALTER TABLE dbo.Shifts ADD CONSTRAINT FK_Shifts_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Roles')
    ALTER TABLE dbo.Shifts ADD CONSTRAINT FK_Shifts_Roles FOREIGN KEY (assignedRole) REFERENCES dbo.Roles(code);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Roles')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Roles FOREIGN KEY (role) REFERENCES dbo.Roles(code);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Staff')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_SystemLogs_Staff')
    ALTER TABLE dbo.SystemLogs ADD CONSTRAINT FK_SystemLogs_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id);
GO

/* ---------- 5.2 CHECK: luật nghiệp vụ nằm ở CSDL, không chỉ ở code ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Payments_Method')
    ALTER TABLE dbo.Payments ADD CONSTRAINT CK_Payments_Method CHECK (method IN ('CASH','TRANSFER'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Payments_Amounts')
    ALTER TABLE dbo.Payments ADD CONSTRAINT CK_Payments_Amounts CHECK (amount >= 0 AND receivedAmount >= 0 AND changeAmount >= 0);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_StockTx_Type')
    ALTER TABLE dbo.StockTransactions ADD CONSTRAINT CK_StockTx_Type CHECK (type IN ('IN','OUT','ADJUST'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_PointTx_Type')
    ALTER TABLE dbo.PointTransactions ADD CONSTRAINT CK_PointTx_Type CHECK (type IN ('EARN','REDEEM','ADJUST'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Customers_Points')
    ALTER TABLE dbo.Customers ADD CONSTRAINT CK_Customers_Points CHECK (points >= 0);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Customers_Tier')
    ALTER TABLE dbo.Customers ADD CONSTRAINT CK_Customers_Tier CHECK (tier IN ('Bronze','Silver','Gold'));
GO

/* ---------- 5.3 UNIQUE: những ràng buộc thật sự chặn lỗi nghiệp vụ ---------- */

/* Một đơn chỉ được thu tiền MỘT lần. Đây là thứ chặn double-charge ở tầng
   CSDL, không phụ thuộc code ứng dụng nhớ kiểm tra. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Payments_Order' AND object_id=OBJECT_ID('dbo.Payments'))
    CREATE UNIQUE INDEX UQ_Payments_Order ON dbo.Payments(orderId);

/* Một số điện thoại = một tài khoản khách. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Customers_Phone' AND object_id=OBJECT_ID('dbo.Customers'))
    CREATE UNIQUE INDEX UQ_Customers_Phone ON dbo.Customers(phone);

/* Một nhân viên = một tài khoản đăng nhập. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Users_StaffId' AND object_id=OBJECT_ID('dbo.Users'))
    CREATE UNIQUE INDEX UQ_Users_StaffId ON dbo.Users(staffId) WHERE staffId IS NOT NULL;
GO

/* Một người không thể có hai ca cùng ngày cùng buổi.
   Phải dọn trùng trước, nếu không index không tạo được. */
;WITH dup AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY staffId, shiftDate, shiftName ORDER BY id) AS rn
    FROM dbo.Shifts
)
DELETE FROM dbo.Shifts WHERE id IN (SELECT id FROM dup WHERE rn > 1);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Shifts_StaffDateName' AND object_id=OBJECT_ID('dbo.Shifts'))
    CREATE UNIQUE INDEX UX_Shifts_StaffDateName ON dbo.Shifts(staffId, shiftDate, shiftName);
GO

/* ---------- 5.4 Index cho các cột truy vấn nhiều nhất ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_OrderItems_Order' AND object_id=OBJECT_ID('dbo.OrderItems'))
    CREATE NONCLUSTERED INDEX IX_OrderItems_Order ON dbo.OrderItems(orderId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_Status' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_Status ON dbo.Orders(status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_TableId' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_TableId ON dbo.Orders(tableId, status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_Customer' AND object_id=OBJECT_ID('dbo.Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_Customer ON dbo.Orders(customerId, id DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_RecipeItems_Ingredient' AND object_id=OBJECT_ID('dbo.RecipeItems'))
    CREATE NONCLUSTERED INDEX IX_RecipeItems_Ingredient ON dbo.RecipeItems(ingredientId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Payments_PaidAt' AND object_id=OBJECT_ID('dbo.Payments'))
    CREATE NONCLUSTERED INDEX IX_Payments_PaidAt ON dbo.Payments(paidAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PointTx_Customer' AND object_id=OBJECT_ID('dbo.PointTransactions'))
    CREATE NONCLUSTERED INDEX IX_PointTx_Customer ON dbo.PointTransactions(customerId, id DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_StockTx_Ingredient' AND object_id=OBJECT_ID('dbo.StockTransactions'))
    CREATE NONCLUSTERED INDEX IX_StockTx_Ingredient ON dbo.StockTransactions(ingredientId, id DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Shifts_Date' AND object_id=OBJECT_ID('dbo.Shifts'))
    CREATE NONCLUSTERED INDEX IX_Shifts_Date ON dbo.Shifts(shiftDate, assignedRole);
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 6 — DỮ LIỆU MẪU
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 6 — Dữ liệu mẫu                                    ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='cupsAvailable')
    INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('cupsAvailable', 120);
IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='vatPercent')
    INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('vatPercent', 8);
IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='serviceChargePercent')
    INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('serviceChargePercent', 0);
IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='tipEnabled')
    INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('tipEnabled', 1);
GO

/* Số dư đầu kỳ cho sổ cái kho.
   Không có bước này thì SUM(quantity) không bao giờ khớp Inventory.stock
   và mọi lần đối soát về sau đều báo lệch.
   Lần đầu chạy, Inventory còn trống (LiteService seed nguyên liệu) nên
   sẽ không chèn gì — Java làm y hệt việc này lúc khởi động. */
INSERT INTO dbo.StockTransactions (ingredientId, type, quantity, stockAfter, unitCost, actorRole, actorName, note)
SELECT i.id, 'ADJUST', i.stock, i.stock, i.importCost, 'system', N'Khởi tạo sổ',
       N'Số dư đầu kỳ khi bắt đầu ghi sổ cái'
FROM dbo.Inventory i
WHERE NOT EXISTS (SELECT 1 FROM dbo.StockTransactions s WHERE s.ingredientId = i.id);
GO

/* ---------- Ca làm cho TUẦN HIỆN TẠI ----------
   Các script cũ cắm cứng ngày 2026-07-17. Ai chạy sau ngày đó sẽ thấy
   "Hôm nay không có ca" và không đăng nhập được — vì vai trò của phiên
   làm việc lấy từ ca của NGÀY HÔM NAY.
   Ở đây tính theo GETDATE() nên luôn có ca cho hôm nay.

   Chỉ chạy khi tuần này CHƯA có ca nào, để không đè lịch bạn đã xếp. */
DECLARE @monday DATE = DATEADD(DAY, -((DATEPART(WEEKDAY, GETDATE()) + @@DATEFIRST - 2) % 7), CAST(GETDATE() AS DATE));
DECLARE @sunday DATE = DATEADD(DAY, 6, @monday);
DECLARE @staffCount INT = (SELECT COUNT(*) FROM dbo.Staff WHERE active = 1);
DECLARE @weekShifts INT = (
    SELECT COUNT(*) FROM dbo.Shifts
    WHERE shiftDate BETWEEN CONVERT(VARCHAR(10), @monday, 23) AND CONVERT(VARCHAR(10), @sunday, 23));

IF @staffCount < 3
    PRINT N'   BỎ QUA xếp ca: cần ít nhất 3 nhân viên đang làm việc (hiện có '
        + CAST(@staffCount AS NVARCHAR(10)) + N').';
ELSE IF @weekShifts > 0
    PRINT N'   BỎ QUA xếp ca: tuần này đã có ' + CAST(@weekShifts AS NVARCHAR(10)) + N' ca.';
ELSE
BEGIN
    /* 7 ngày × 3 buổi × 3 vai trò = 63 ca, xoay vòng qua danh sách nhân viên.
       Ba vai trò trong cùng một buổi nhận 3 chỉ số liên tiếp nên chắc chắn
       là ba người khác nhau — không vi phạm UX_Shifts_StaffDateName. */
    INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole)
    SELECT
        'auto-' + CONVERT(VARCHAR(8), DATEADD(DAY, d.n, @monday), 112)
                + '-' + CAST(sh.ord AS VARCHAR(2)) + '-' + r.code,
        st.id,
        st.name,
        CONVERT(VARCHAR(10), DATEADD(DAY, d.n, @monday), 23),
        sh.nm,
        sh.hrs,
        N'Đã xếp lịch',
        N'',
        r.code
    FROM      (VALUES (0),(1),(2),(3),(4),(5),(6)) AS d(n)
    CROSS JOIN (VALUES (1, N'Ca Sáng',  '06:00 - 12:00'),
                       (2, N'Ca Chiều', '12:00 - 18:00'),
                       (3, N'Ca Tối',   '18:00 - 23:00')) AS sh(ord, nm, hrs)
    CROSS JOIN (VALUES (1, 'barista'), (2, 'cashier'), (3, 'runner')) AS r(ord, code)
    JOIN (SELECT id, name, ROW_NUMBER() OVER (ORDER BY id) - 1 AS idx
          FROM dbo.Staff WHERE active = 1) AS st
      ON st.idx = ((d.n * 9) + (sh.ord - 1) * 3 + (r.ord - 1)) % @staffCount;

    PRINT N'   Đã xếp ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' ca cho tuần '
        + CONVERT(VARCHAR(10), @monday, 23) + N' → ' + CONVERT(VARCHAR(10), @sunday, 23);
END
GO


/* ══════════════════════════════════════════════════════════════════════════
   PHẦN 7 — KIỂM TRA
   ══════════════════════════════════════════════════════════════════════════ */
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════╗';
PRINT N'║  PHẦN 7 — Kiểm tra                                       ║';
PRINT N'╚══════════════════════════════════════════════════════════╝';

SELECT 'Bảng'                     AS muc, COUNT(*) AS so_luong FROM sys.tables
UNION ALL SELECT 'Khoá ngoại',    COUNT(*) FROM sys.foreign_keys
UNION ALL SELECT 'Ràng buộc CHECK', COUNT(*) FROM sys.check_constraints
UNION ALL SELECT 'Vai trò',       COUNT(*) FROM dbo.Roles
UNION ALL SELECT 'Nhân viên',     COUNT(*) FROM dbo.Staff WHERE active = 1
UNION ALL SELECT 'Ca làm HÔM NAY', COUNT(*) FROM dbo.Shifts WHERE shiftDate = CONVERT(VARCHAR(10), GETDATE(), 23)
UNION ALL SELECT 'Tài khoản cá nhân', COUNT(*) FROM dbo.Users WHERE staffId IS NOT NULL
UNION ALL SELECT 'Đơn đã có tableId', COUNT(*) FROM dbo.Orders WHERE tableId IS NOT NULL
UNION ALL SELECT 'Đơn CHƯA ghép bàn', COUNT(*) FROM dbo.Orders WHERE tableId IS NULL;
GO

PRINT N'';
PRINT N'-- Ai làm ca gì HÔM NAY (danh sách này chính là màn hình đăng nhập) --';
SELECT s.id AS ma_nv, s.name AS ten, sh.assignedRole AS vai_tro,
       sh.shiftName AS ca, sh.hours AS gio
FROM dbo.Staff s
JOIN dbo.Shifts sh ON sh.staffId = s.id
WHERE sh.shiftDate = CONVERT(VARCHAR(10), GETDATE(), 23) AND s.active = 1
ORDER BY sh.hours, sh.assignedRole;
GO

PRINT N'';
PRINT N'-- Doanh thu theo TẦNG: thiết kế cũ KHÔNG viết được câu này --';
SELECT t.floorNo AS tang, COUNT(DISTINCT o.id) AS so_don, ISNULL(SUM(o.total), 0) AS doanh_thu
FROM dbo.Orders o JOIN dbo.Tables t ON t.id = o.tableId
WHERE o.status = 'Paid'
GROUP BY t.floorNo ORDER BY t.floorNo;
GO

PRINT N'';
PRINT N'-- Đối soát sổ cái kho: KHÔNG dòng nào = tồn kho khớp sổ --';
SELECT i.id, i.name, i.stock AS ton_hien_tai,
       ISNULL(SUM(s.quantity), 0) AS tong_so_cai,
       i.stock - ISNULL(SUM(s.quantity), 0) AS chenh_lech
FROM dbo.Inventory i
LEFT JOIN dbo.StockTransactions s ON s.ingredientId = i.id
GROUP BY i.id, i.name, i.stock
HAVING i.stock <> ISNULL(SUM(s.quantity), 0);
GO

PRINT N'';
PRINT N'-- Đối soát sổ cái điểm: KHÔNG dòng nào = số dư khớp sổ --';
SELECT c.id, c.phone, c.points AS so_du,
       ISNULL(SUM(pt.points), 0) AS tong_so_cai,
       c.points - ISNULL(SUM(pt.points), 0) AS chenh_lech
FROM dbo.Customers c
LEFT JOIN dbo.PointTransactions pt ON pt.customerId = c.id
GROUP BY c.id, c.phone, c.points
HAVING c.points <> ISNULL(SUM(pt.points), 0);
GO

PRINT N'';
PRINT N'════════════════════════════════════════════════════════════';
PRINT N'  XONG.';
PRINT N'';
PRINT N'  BƯỚC TIẾP THEO — KHỞI ĐỘNG LẠI TOMCAT.';
PRINT N'  Lúc đó LiteService.init() sẽ tự tạo:';
PRINT N'    • Bàn, thực đơn, nguyên liệu, công thức';
PRINT N'    • Tài khoản CÁ NHÂN cho từng nhân viên';
PRINT N'      PIN mặc định = 1000 + mã nhân viên  (nhân viên #1 → 1001)';
PRINT N'    • 2 tài khoản khách demo';
PRINT N'      0901234567 / 0912345678  —  mật khẩu 123456';
PRINT N'';
PRINT N'  PIN quản trị: 8888  (mở dashboard, và mở khoá đăng nhập ngoài ca)';
PRINT N'════════════════════════════════════════════════════════════';
GO
