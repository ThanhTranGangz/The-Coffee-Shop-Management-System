package service;

import context.DBContext;

import java.sql.*;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;

public class LiteService {
    private static final int MAX_ITEM_QUANTITY = 20;
    private static final ZoneId APP_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter SQL_TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    /**
     * Vào ca sớm / tan ca muộn bao nhiêu phút thì vẫn tính là trong ca.
     * Không có khoảng nới này thì người đến sớm 10 phút không mở được máy.
     */
    private static final int SHIFT_GRACE_MINUTES = 30;
    /** "06:00 - 12:00", "6h00 – 12h00"… — chỉ cần bắt được bốn con số. */
    private static final java.util.regex.Pattern SHIFT_HOURS_PATTERN =
            java.util.regex.Pattern.compile("(\\d{1,2})\\s*[:hH]\\s*(\\d{2})\\D+(\\d{1,2})\\s*[:hH]\\s*(\\d{2})");
    /** Đơn đang chiếm bàn / chưa xong vòng đời (không gồm Cancelled/Refunded). */
    static final String ST_OPEN = "('Pending','Preparing','Ready','Served','Paid')";
    /** Đơn chưa thanh toán (không gồm Paid/Cleared/Cancelled/Refunded). */
    static final String ST_PRE_PAID = "('Pending','Preparing','Ready','Served')";
    /** Doanh thu hợp lệ. */
    static final String ST_REVENUE = "('Paid','Cleared')";
    /** Đơn đang giữ chỗ kho. */
    static final String ST_RESERVING = "('Pending','Preparing')";
    static final String ORDER_TYPE_DINE_IN = "DINE_IN";
    static final String ORDER_TYPE_TAKEAWAY = "TAKEAWAY";
    private static final LiteService INSTANCE = new LiteService();
    private final DBContext db = new DBContext();
    /** SSE listeners — realtime thay polling. */
    private final List<java.util.function.Consumer<String>> eventListeners =
            Collections.synchronizedList(new ArrayList<>());

    public static LiteService getInstance() {
        return INSTANCE;
    }

    private LiteService() {
        init();
    }

    /**
     * Chạy một lệnh DDL, ghi log nếu hỏng nhưng không chặn các lệnh sau.
     * Từng ràng buộc phải độc lập: một cái tạo không được (do dữ liệu cũ)
     * không được phép kéo theo cả loạt còn lại biến mất trong im lặng.
     */
    private void tryExec(Statement st, String sql) {
        try {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("[LiteService] Bỏ qua DDL: " + e.getMessage()
                    + " | " + (sql.length() > 90 ? sql.substring(0, 90) + "..." : sql));
        }
    }

    private void init() {
        try (Connection con = db.getConnection(); Statement st = con.createStatement()) {
            st.execute("IF OBJECT_ID('dbo.Users','U') IS NULL CREATE TABLE dbo.Users (username VARCHAR(50) PRIMARY KEY, password VARCHAR(100) NOT NULL, role VARCHAR(20) NOT NULL, fullName NVARCHAR(120) NOT NULL)");
            st.execute("IF OBJECT_ID('dbo.Tables','U') IS NULL CREATE TABLE dbo.Tables (id INT IDENTITY PRIMARY KEY, name NVARCHAR(60) NOT NULL, code VARCHAR(40) NULL, active BIT NOT NULL DEFAULT 1)");
            st.execute("IF COL_LENGTH('dbo.Tables','code') IS NULL ALTER TABLE dbo.Tables ADD code VARCHAR(40) NULL");
            
            
            st.execute("IF OBJECT_ID('dbo.MenuItems','U') IS NULL CREATE TABLE dbo.MenuItems (id INT IDENTITY PRIMARY KEY, nameVi NVARCHAR(120) NOT NULL, nameEn NVARCHAR(120) NOT NULL, category NVARCHAR(60) NOT NULL, price INT NOT NULL, active BIT NOT NULL DEFAULT 1)");
            st.execute("IF COL_LENGTH('dbo.MenuItems','imagePath') IS NULL ALTER TABLE dbo.MenuItems ADD imagePath VARCHAR(255) NULL");
            st.execute("IF OBJECT_ID('dbo.MenuItemSizes','U') IS NULL CREATE TABLE dbo.MenuItemSizes (id INT IDENTITY PRIMARY KEY, menuItemId INT NOT NULL, sizeName NVARCHAR(20) NOT NULL, extraPrice INT NOT NULL DEFAULT 0, sortOrder INT NOT NULL DEFAULT 0, FOREIGN KEY(menuItemId) REFERENCES dbo.MenuItems(id))");
            st.execute("IF OBJECT_ID('dbo.Orders','U') IS NULL CREATE TABLE dbo.Orders (id INT IDENTITY PRIMARY KEY, orderNumber INT NULL UNIQUE, tableName NVARCHAR(60) NOT NULL, customerPhone VARCHAR(20) NULL, status VARCHAR(30) NOT NULL DEFAULT 'Pending', total INT NOT NULL DEFAULT 0, note NVARCHAR(255) NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF COL_LENGTH('dbo.Orders','splitLocked') IS NULL ALTER TABLE dbo.Orders ADD splitLocked BIT NOT NULL DEFAULT 0");
            st.execute("IF COL_LENGTH('dbo.Orders','invoicePrinted') IS NULL ALTER TABLE dbo.Orders ADD invoicePrinted BIT NOT NULL DEFAULT 0");
            st.execute("IF OBJECT_ID('dbo.OrderItems','U') IS NULL CREATE TABLE dbo.OrderItems (id INT IDENTITY PRIMARY KEY, orderId INT NOT NULL, menuItemId INT NOT NULL, itemName NVARCHAR(120) NOT NULL, itemSize VARCHAR(20) NULL, quantity INT NOT NULL, price INT NOT NULL, preparedQty INT NOT NULL DEFAULT 0, FOREIGN KEY(orderId) REFERENCES dbo.Orders(id), FOREIGN KEY(menuItemId) REFERENCES dbo.MenuItems(id))");
            st.execute("IF COL_LENGTH('dbo.OrderItems','itemSize') IS NULL ALTER TABLE dbo.OrderItems ADD itemSize VARCHAR(20) NULL");
            st.execute("IF COL_LENGTH('dbo.OrderItems','preparedQty') IS NULL ALTER TABLE dbo.OrderItems ADD preparedQty INT NOT NULL DEFAULT 0");
            st.execute("ALTER TABLE dbo.OrderItems ALTER COLUMN itemSize VARCHAR(20) NULL");
            st.execute("IF OBJECT_ID('dbo.CashEvents','U') IS NULL CREATE TABLE dbo.CashEvents (id INT IDENTITY PRIMARY KEY, eventType VARCHAR(30) NOT NULL, amount INT NOT NULL, balanceAfter INT NOT NULL, note NVARCHAR(255) NULL, actorRole VARCHAR(20) NULL, actorName NVARCHAR(120) NULL, seenByCashier BIT NOT NULL DEFAULT 1, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF COL_LENGTH('dbo.CashEvents','seenByCashier') IS NULL ALTER TABLE dbo.CashEvents ADD seenByCashier BIT NOT NULL DEFAULT 1");
            st.execute("IF OBJECT_ID('dbo.StoreState','U') IS NULL CREATE TABLE dbo.StoreState (stateKey VARCHAR(50) PRIMARY KEY, intValue INT NOT NULL, updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF OBJECT_ID('dbo.SystemLogs','U') IS NULL CREATE TABLE dbo.SystemLogs (id INT IDENTITY PRIMARY KEY, actorRole VARCHAR(20) NOT NULL, actorName NVARCHAR(120) NULL, actionType VARCHAR(40) NOT NULL, messageVi NVARCHAR(400) NOT NULL, messageEn NVARCHAR(400) NOT NULL, refId INT NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF OBJECT_ID('dbo.Staff','U') IS NULL CREATE TABLE dbo.Staff (id INT PRIMARY KEY, name NVARCHAR(120) NOT NULL, active BIT NOT NULL DEFAULT 1, status VARCHAR(30) NOT NULL DEFAULT 'Active')");
            // assignedRole PHẢI VARCHAR(20) khớp Roles.code — VARCHAR(30) làm FK_Shifts_Roles thất bại.
            st.execute("IF OBJECT_ID('dbo.Shifts','U') IS NULL CREATE TABLE dbo.Shifts (id VARCHAR(50) PRIMARY KEY, staffId INT NOT NULL, staffName NVARCHAR(120) NULL, shiftDate VARCHAR(20) NOT NULL, shiftName NVARCHAR(50) NOT NULL, hours VARCHAR(50) NOT NULL, status NVARCHAR(30) NOT NULL, notes NVARCHAR(255) NULL, assignedRole VARCHAR(20) NULL, FOREIGN KEY(staffId) REFERENCES dbo.Staff(id))");
            st.execute("IF COL_LENGTH('dbo.Shifts','assignedRole') IS NULL ALTER TABLE dbo.Shifts ADD assignedRole VARCHAR(20) NULL");

            // Inventory TRƯỚC StockTransactions — mở sổ cái cần bảng Inventory đã tồn tại.
            st.execute("IF OBJECT_ID('dbo.Inventory','U') IS NULL CREATE TABLE dbo.Inventory (id VARCHAR(50) PRIMARY KEY, name NVARCHAR(120) NOT NULL, unit NVARCHAR(20) NOT NULL, stock INT NOT NULL DEFAULT 0, minStock INT NOT NULL DEFAULT 0, importCost INT NOT NULL DEFAULT 0)");
            st.execute("IF OBJECT_ID('dbo.RecipeItems','U') IS NULL CREATE TABLE dbo.RecipeItems (id VARCHAR(50) PRIMARY KEY, menuItemId INT NOT NULL, ingredientId VARCHAR(50) NOT NULL, quantity INT NOT NULL)");

            // ── Tài khoản khách hàng & tích điểm ────────────────────────────
            st.execute("IF OBJECT_ID('dbo.Customers','U') IS NULL CREATE TABLE dbo.Customers (id INT IDENTITY PRIMARY KEY, phone VARCHAR(20) NOT NULL, passwordHash VARCHAR(64) NOT NULL, passwordSalt VARCHAR(32) NOT NULL, fullName NVARCHAR(120) NOT NULL, points INT NOT NULL DEFAULT 0, totalSpent INT NOT NULL DEFAULT 0, orderCount INT NOT NULL DEFAULT 0, tier VARCHAR(10) NOT NULL DEFAULT 'Bronze', active BIT NOT NULL DEFAULT 1, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Customers_Phone' AND object_id=OBJECT_ID('dbo.Customers')) CREATE UNIQUE INDEX UQ_Customers_Phone ON dbo.Customers(phone)");
            st.execute("IF OBJECT_ID('dbo.PointTransactions','U') IS NULL CREATE TABLE dbo.PointTransactions (id INT IDENTITY PRIMARY KEY, customerId INT NOT NULL, orderId INT NULL, type VARCHAR(10) NOT NULL, points INT NOT NULL, balanceAfter INT NOT NULL, note NVARCHAR(255) NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), FOREIGN KEY(customerId) REFERENCES dbo.Customers(id), FOREIGN KEY(orderId) REFERENCES dbo.Orders(id))");
            st.execute("IF COL_LENGTH('dbo.Orders','customerId') IS NULL ALTER TABLE dbo.Orders ADD customerId INT NULL");
            st.execute("IF COL_LENGTH('dbo.Orders','subtotal') IS NULL ALTER TABLE dbo.Orders ADD subtotal INT NOT NULL DEFAULT 0");
            st.execute("IF COL_LENGTH('dbo.Orders','discountAmount') IS NULL ALTER TABLE dbo.Orders ADD discountAmount INT NOT NULL DEFAULT 0");
            st.execute("IF COL_LENGTH('dbo.Orders','pointsEarned') IS NULL ALTER TABLE dbo.Orders ADD pointsEarned INT NOT NULL DEFAULT 0");
            st.execute("IF COL_LENGTH('dbo.Orders','pointsRedeemed') IS NULL ALTER TABLE dbo.Orders ADD pointsRedeemed INT NOT NULL DEFAULT 0");
            st.execute("UPDATE dbo.Orders SET subtotal = total WHERE subtotal = 0 AND total > 0");
            // #1 Orders → Tables: tableName = BẢN CHỤP, quan hệ thật là tableId.
            st.execute("IF COL_LENGTH('dbo.Orders','tableId') IS NULL ALTER TABLE dbo.Orders ADD tableId INT NULL");
            st.execute("UPDATE o SET o.tableId = t.id FROM dbo.Orders o JOIN dbo.Tables t ON t.name = o.tableName WHERE o.tableId IS NULL");

            // #2 Tầng thanh toán.
            st.execute("IF OBJECT_ID('dbo.Payments','U') IS NULL CREATE TABLE dbo.Payments (id INT IDENTITY PRIMARY KEY, orderId INT NOT NULL, method VARCHAR(20) NOT NULL, amount INT NOT NULL, receivedAmount INT NOT NULL, changeAmount INT NOT NULL, cashierUsername VARCHAR(50) NULL, cashierName NVARCHAR(120) NULL, staffId INT NULL, note NVARCHAR(255) NULL, paidAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Payments_Order' AND object_id=OBJECT_ID('dbo.Payments')) CREATE UNIQUE INDEX UQ_Payments_Order ON dbo.Payments(orderId)");
            st.execute("IF COL_LENGTH('dbo.CashEvents','orderId') IS NULL ALTER TABLE dbo.CashEvents ADD orderId INT NULL");
            st.execute("IF COL_LENGTH('dbo.CashEvents','paymentId') IS NULL ALTER TABLE dbo.CashEvents ADD paymentId INT NULL");

            // #3 Sổ cái kho — chỉ tạo bảng; mở sổ chạy SAU khi seed nguyên liệu.
            st.execute("IF OBJECT_ID('dbo.StockTransactions','U') IS NULL CREATE TABLE dbo.StockTransactions (id INT IDENTITY PRIMARY KEY, ingredientId VARCHAR(50) NOT NULL, type VARCHAR(10) NOT NULL, quantity INT NOT NULL, stockAfter INT NOT NULL, unitCost INT NOT NULL DEFAULT 0, orderId INT NULL, actorRole VARCHAR(20) NULL, actorName NVARCHAR(120) NULL, note NVARCHAR(255) NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");

            // #4 Vai trò + liên kết nhân sự ↔ tài khoản.
            st.execute("IF OBJECT_ID('dbo.Roles','U') IS NULL CREATE TABLE dbo.Roles (code VARCHAR(20) PRIMARY KEY, nameVi NVARCHAR(50) NOT NULL, nameEn VARCHAR(50) NOT NULL, sortOrder INT NOT NULL DEFAULT 0)");
            st.execute("MERGE dbo.Roles AS t USING (VALUES ('admin',N'Quản trị','Admin',1),('barista',N'Pha chế','Barista',2),('cashier',N'Thu ngân','Cashier',3),('runner',N'Bồi bàn','Waiter',4)) AS s(code,nameVi,nameEn,sortOrder) ON t.code=s.code WHEN MATCHED THEN UPDATE SET nameVi=s.nameVi,nameEn=s.nameEn,sortOrder=s.sortOrder WHEN NOT MATCHED THEN INSERT(code,nameVi,nameEn,sortOrder) VALUES(s.code,s.nameVi,s.nameEn,s.sortOrder);");
            st.execute("UPDATE dbo.Shifts SET assignedRole='barista' WHERE assignedRole IN ('Barista','BARISTA')");
            st.execute("UPDATE dbo.Shifts SET assignedRole='cashier' WHERE assignedRole IN ('Cashier','CASHIER')");
            st.execute("UPDATE dbo.Shifts SET assignedRole='runner'  WHERE assignedRole IN ('Waiter','WAITER','Runner','RUNNER')");
            // Ép độ dài khớp Roles.code trước khi tạo FK.
            tryExec(st, "IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Roles') ALTER TABLE dbo.Shifts DROP CONSTRAINT FK_Shifts_Roles");
            tryExec(st, "ALTER TABLE dbo.Shifts ALTER COLUMN assignedRole VARCHAR(20) NULL");
            st.execute("IF COL_LENGTH('dbo.Users','staffId') IS NULL ALTER TABLE dbo.Users ADD staffId INT NULL");
            st.execute("IF COL_LENGTH('dbo.SystemLogs','staffId') IS NULL ALTER TABLE dbo.SystemLogs ADD staffId INT NULL");
            st.execute("IF COL_LENGTH('dbo.CashEvents','staffId') IS NULL ALTER TABLE dbo.CashEvents ADD staffId INT NULL");

            // Dọn dữ liệu không hợp lệ TRƯỚC khi thêm khoá ngoại, nếu không
            // một dòng rác sẽ làm cả ràng buộc không tạo được.
            tryExec(st, "UPDATE dbo.Users SET role = 'barista' WHERE role NOT IN (SELECT code FROM dbo.Roles)");
            tryExec(st, "UPDATE dbo.Shifts SET assignedRole = NULL WHERE assignedRole IS NOT NULL AND assignedRole NOT IN (SELECT code FROM dbo.Roles)");
            tryExec(st, "UPDATE dbo.Orders SET tableId = NULL WHERE tableId IS NOT NULL AND tableId NOT IN (SELECT id FROM dbo.Tables)");

            // MỖI ràng buộc một try riêng. Gộp chung một try là sai: cái đầu
            // hỏng thì toàn bộ phần còn lại bị bỏ qua trong im lặng, và ta sẽ
            // tưởng CSDL có đủ khoá ngoại trong khi thực tế thiếu gần hết.
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Tables') ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Tables FOREIGN KEY (tableId) REFERENCES dbo.Tables(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_TableId' AND object_id=OBJECT_ID('dbo.Orders')) CREATE NONCLUSTERED INDEX IX_Orders_TableId ON dbo.Orders(tableId, status)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Orders') ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Orders') ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StockTx_Inventory') ALTER TABLE dbo.StockTransactions ADD CONSTRAINT FK_StockTx_Inventory FOREIGN KEY (ingredientId) REFERENCES dbo.Inventory(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StockTx_Orders') ALTER TABLE dbo.StockTransactions ADD CONSTRAINT FK_StockTx_Orders FOREIGN KEY (orderId) REFERENCES dbo.Orders(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_StockTx_Ingredient' AND object_id=OBJECT_ID('dbo.StockTransactions')) CREATE NONCLUSTERED INDEX IX_StockTx_Ingredient ON dbo.StockTransactions(ingredientId, id DESC)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Roles') ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Roles FOREIGN KEY (role) REFERENCES dbo.Roles(code)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Users_Staff') ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Shifts_Roles') ALTER TABLE dbo.Shifts ADD CONSTRAINT FK_Shifts_Roles FOREIGN KEY (assignedRole) REFERENCES dbo.Roles(code)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_SystemLogs_Staff') ALTER TABLE dbo.SystemLogs ADD CONSTRAINT FK_SystemLogs_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_CashEvents_Staff') ALTER TABLE dbo.CashEvents ADD CONSTRAINT FK_CashEvents_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Payments_Staff') ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id)");

            // ── Tài khoản riêng cho từng nhân viên (xem staff_accounts.sql) ──
            // Users.role đổi nghĩa: không còn là vai trò làm việc mà là LOẠI
            // TÀI KHOẢN (admin = quyền cố định, staff = quyền theo ca hôm nay).
            // isShiftRole tách hai khái niệm để một cột không gánh hai ý nghĩa.
            tryExec(st, "IF COL_LENGTH('dbo.Roles','isShiftRole') IS NULL ALTER TABLE dbo.Roles ADD isShiftRole BIT NOT NULL DEFAULT 1");
            tryExec(st, "MERGE dbo.Roles AS t USING (VALUES ('admin',N'Quản trị','Admin',1,0),('staff',N'Nhân viên','Staff',2,0),('barista',N'Pha chế','Barista',3,1),('cashier',N'Thu ngân','Cashier',4,1),('runner',N'Bồi bàn','Waiter',5,1)) AS s(code,nameVi,nameEn,sortOrder,isShiftRole) ON t.code=s.code WHEN MATCHED THEN UPDATE SET nameVi=s.nameVi,nameEn=s.nameEn,sortOrder=s.sortOrder,isShiftRole=s.isShiftRole WHEN NOT MATCHED THEN INSERT(code,nameVi,nameEn,sortOrder,isShiftRole) VALUES(s.code,s.nameVi,s.nameEn,s.sortOrder,s.isShiftRole);");
            tryExec(st, "IF COL_LENGTH('dbo.Users','pinHash') IS NULL ALTER TABLE dbo.Users ADD pinHash VARCHAR(64) NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Users','pinSalt') IS NULL ALTER TABLE dbo.Users ADD pinSalt VARCHAR(32) NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Users','active') IS NULL ALTER TABLE dbo.Users ADD active BIT NOT NULL DEFAULT 1");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Users_StaffId' AND object_id=OBJECT_ID('dbo.Users')) CREATE UNIQUE INDEX UQ_Users_StaffId ON dbo.Users(staffId) WHERE staffId IS NOT NULL");
            tryExec(st, "UPDATE dbo.Users SET active = 0 WHERE username IN ('barista','cashier','runner')");
            // Shifts.staffName là dữ liệu thừa: ShiftDAO.getAll() đã JOIN sang
            // dbo.Staff để lấy tên. Để NOT NULL chỉ tổ làm hỏng luồng thêm ca.
            tryExec(st, "UPDATE dbo.Shifts SET staffName = N'' WHERE staffName IS NULL");
            tryExec(st, "ALTER TABLE dbo.Shifts ALTER COLUMN staffName NVARCHAR(120) NULL");

            try {
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Customers') ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (customerId) REFERENCES dbo.Customers(id)");
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Orders_Customer' AND object_id=OBJECT_ID('dbo.Orders')) CREATE NONCLUSTERED INDEX IX_Orders_Customer ON dbo.Orders(customerId, id DESC)");
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PointTx_Customer' AND object_id=OBJECT_ID('dbo.PointTransactions')) CREATE NONCLUSTERED INDEX IX_PointTx_Customer ON dbo.PointTransactions(customerId, id DESC)");
            } catch (Exception ignored) {}
            try {
                st.execute("WITH d AS (SELECT id, ROW_NUMBER() OVER (PARTITION BY staffId, shiftDate, shiftName ORDER BY id) rn FROM dbo.Shifts) DELETE FROM dbo.Shifts WHERE id IN (SELECT id FROM d WHERE rn > 1)");
            } catch (Exception ignored) {}
            try {
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Shifts_StaffDateName' AND object_id=OBJECT_ID('dbo.Shifts')) CREATE UNIQUE INDEX UX_Shifts_StaffDateName ON dbo.Shifts(staffId, shiftDate, shiftName)");
            } catch (Exception ignored) {}

            // ── Hủy đơn / hoàn tiền / mang đi / khuyến mãi / thuế-tip ──
            tryExec(st, "IF COL_LENGTH('dbo.Orders','cancelReason') IS NULL ALTER TABLE dbo.Orders ADD cancelReason NVARCHAR(255) NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','cancelledAt') IS NULL ALTER TABLE dbo.Orders ADD cancelledAt DATETIME2 NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','cancelledByRole') IS NULL ALTER TABLE dbo.Orders ADD cancelledByRole VARCHAR(20) NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','cancelledByName') IS NULL ALTER TABLE dbo.Orders ADD cancelledByName NVARCHAR(120) NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','orderType') IS NULL ALTER TABLE dbo.Orders ADD orderType VARCHAR(20) NOT NULL CONSTRAINT DF_Orders_orderType DEFAULT 'DINE_IN'");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','promotionId') IS NULL ALTER TABLE dbo.Orders ADD promotionId INT NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','promoDiscount') IS NULL ALTER TABLE dbo.Orders ADD promoDiscount INT NOT NULL DEFAULT 0");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','manualDiscount') IS NULL ALTER TABLE dbo.Orders ADD manualDiscount INT NOT NULL DEFAULT 0");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','discountReason') IS NULL ALTER TABLE dbo.Orders ADD discountReason NVARCHAR(255) NULL");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','taxAmount') IS NULL ALTER TABLE dbo.Orders ADD taxAmount INT NOT NULL DEFAULT 0");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','serviceCharge') IS NULL ALTER TABLE dbo.Orders ADD serviceCharge INT NOT NULL DEFAULT 0");
            tryExec(st, "IF COL_LENGTH('dbo.Orders','tipAmount') IS NULL ALTER TABLE dbo.Orders ADD tipAmount INT NOT NULL DEFAULT 0");
            tryExec(st, "IF OBJECT_ID('dbo.Refunds','U') IS NULL CREATE TABLE dbo.Refunds ("
                    + "id INT IDENTITY PRIMARY KEY, orderId INT NOT NULL, paymentId INT NULL, "
                    + "amount INT NOT NULL, method VARCHAR(20) NULL, reason NVARCHAR(255) NOT NULL, "
                    + "restocked BIT NOT NULL DEFAULT 1, actorRole VARCHAR(20) NULL, actorName NVARCHAR(120) NULL, "
                    + "staffId INT NULL, refundedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), "
                    + "FOREIGN KEY(orderId) REFERENCES dbo.Orders(id))");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Refunds_Order' AND object_id=OBJECT_ID('dbo.Refunds')) "
                    + "CREATE UNIQUE INDEX UQ_Refunds_Order ON dbo.Refunds(orderId)");
            tryExec(st, "IF OBJECT_ID('dbo.Promotions','U') IS NULL CREATE TABLE dbo.Promotions ("
                    + "id INT IDENTITY PRIMARY KEY, code VARCHAR(40) NOT NULL, nameVi NVARCHAR(120) NOT NULL, "
                    + "nameEn NVARCHAR(120) NOT NULL, discountType VARCHAR(10) NOT NULL, discountValue INT NOT NULL, "
                    + "minSubtotal INT NOT NULL DEFAULT 0, maxDiscount INT NOT NULL DEFAULT 0, "
                    + "startAt DATETIME2 NULL, endAt DATETIME2 NULL, maxUses INT NOT NULL DEFAULT 0, "
                    + "usedCount INT NOT NULL DEFAULT 0, active BIT NOT NULL DEFAULT 1, "
                    + "createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Promotions_Code' AND object_id=OBJECT_ID('dbo.Promotions')) "
                    + "CREATE UNIQUE INDEX UQ_Promotions_Code ON dbo.Promotions(code)");
            tryExec(st, "IF OBJECT_ID('dbo.PromotionRedemptions','U') IS NULL CREATE TABLE dbo.PromotionRedemptions ("
                    + "id INT IDENTITY PRIMARY KEY, promotionId INT NOT NULL, orderId INT NOT NULL, "
                    + "discountAmount INT NOT NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), "
                    + "FOREIGN KEY(promotionId) REFERENCES dbo.Promotions(id), FOREIGN KEY(orderId) REFERENCES dbo.Orders(id))");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_PromoRedeem_Order' AND object_id=OBJECT_ID('dbo.PromotionRedemptions')) "
                    + "CREATE UNIQUE INDEX UQ_PromoRedeem_Order ON dbo.PromotionRedemptions(orderId)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Orders_Promotions') "
                    + "ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Promotions FOREIGN KEY (promotionId) REFERENCES dbo.Promotions(id)");
            // Cấu hình thuế / phí / tip (StoreState intValue: phần trăm hoặc cờ 0/1).
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='vatPercent') INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('vatPercent', 8)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='serviceChargePercent') INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('serviceChargePercent', 0)");
            tryExec(st, "IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey='tipEnabled') INSERT INTO dbo.StoreState (stateKey, intValue) VALUES ('tipEnabled', 1)");
            
            try {
                st.execute("DELETE FROM dbo.OrderItems WHERE menuItemId NOT IN (SELECT id FROM dbo.MenuItems)");
                st.execute("DELETE FROM dbo.Shifts WHERE staffId NOT IN (SELECT id FROM dbo.Staff)");
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrderItems_MenuItems') ALTER TABLE dbo.OrderItems ADD CONSTRAINT FK_OrderItems_MenuItems FOREIGN KEY (menuItemId) REFERENCES dbo.MenuItems(id)");
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Shifts_Staff') ALTER TABLE dbo.Shifts ADD CONSTRAINT FK_Shifts_Staff FOREIGN KEY (staffId) REFERENCES dbo.Staff(id)");
                st.execute("IF COL_LENGTH('dbo.Tables','floorNo') IS NULL ALTER TABLE dbo.Tables ADD floorNo INT NULL");
                st.execute("IF COL_LENGTH('dbo.Tables','tableNo') IS NULL ALTER TABLE dbo.Tables ADD tableNo INT NULL");
                st.execute("IF COL_LENGTH('dbo.Staff','shift') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN shift");
                st.execute("IF COL_LENGTH('dbo.Staff','username') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN username");
                st.execute("IF COL_LENGTH('dbo.Staff','password') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN password");
                st.execute("IF COL_LENGTH('dbo.Staff','role') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN role");
                st.execute("IF COL_LENGTH('dbo.Staff','pin') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN pin");
                st.execute("IF COL_LENGTH('dbo.Staff','overtime') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN overtime");
                st.execute("IF COL_LENGTH('dbo.Staff','phone') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN phone");
                st.execute("IF COL_LENGTH('dbo.Staff','email') IS NOT NULL ALTER TABLE dbo.Staff DROP COLUMN email");
            } catch (Exception e) {}
            seed(con);
            // Mở sổ cái SAU khi Inventory đã có dữ liệu — trước đây chạy lúc bảng chưa tồn tại.
            try (Statement ledger = con.createStatement()) {
                ledger.execute("INSERT INTO dbo.StockTransactions (ingredientId,type,quantity,stockAfter,unitCost,actorRole,actorName,note) "
                        + "SELECT i.id,'ADJUST',i.stock,i.stock,i.importCost,'system',N'Khởi tạo sổ',N'Số dư đầu kỳ khi bắt đầu ghi sổ cái' "
                        + "FROM dbo.Inventory i WHERE NOT EXISTS (SELECT 1 FROM dbo.StockTransactions s WHERE s.ingredientId = i.id)");
            }
        } catch (Exception e) {
            System.err.println("LiteService init failed: " + e.getMessage());
            e.printStackTrace(System.err);
        }
        // Tạo tài khoản khách demo sau khi bảng chắc chắn đã tồn tại.
        new dao.CustomerDAO().seedDemoAccounts();
        // Mỗi nhân viên một tài khoản riêng — nếu thiếu thì tạo bù.
        ensureStaffAccounts();
    }

    private void seed(Connection con) throws Exception {
        upsertUser(con, "admin", "8888", "admin", "Quản trị coffeshop");
        upsertUser(con, "barista", "1111", "barista", "Pha chế coffeshop");
        upsertUser(con, "cashier", "2222", "cashier", "Thu ngân coffeshop");
        upsertUser(con, "runner", "3333", "runner", "Bồi bàn coffeshop");
        ensureStandardTables(con);
        removeLegacyTables(con);
        clearOrphanActiveOrders(con);
        ensureTableCodes(con);
        seedMenu(con);
        ensureInventoryAndRecipes(con);
        seedSalesHistory(con);
        ensureState(con, "cupsAvailable", 120);
        try (Statement st = con.createStatement()) {
            st.execute("UPDATE dbo.Users SET role='admin', fullName=N'Quản trị coffeshop' WHERE username='admin'");
            st.execute("UPDATE dbo.Users SET password='1111', role='barista', fullName=N'Pha chế coffeshop' WHERE username='staff'");
        }
        seedStaffAndShifts(con);
    }

    private void seedStaffAndShifts(Connection con) throws Exception {
        // Step 1: Ensure at least 5 staff exist (use MERGE to avoid conflicts)
        boolean hadStaff;
        try (Statement st = con.createStatement()) {
            java.sql.ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM dbo.Staff");
            rs.next();
            hadStaff = rs.getInt(1) > 0;
        }

        if (!hadStaff) {
            String[][] staffData = {
                {"1", "Nguyễn Văn An", "Active"},
                {"2", "Trần Thị Bích", "Active"},
                {"3", "Lê Hoàng Cường", "Active"},
                {"4", "Phạm Minh Đức", "Active"},
                {"5", "Hoàng Thị Em", "Active"}
            };

            // Staff hiện chỉ còn id/name/active/status — cột role/pin/... đã bị DROP.
            String staffSql = "MERGE dbo.Staff AS t USING (SELECT ? AS id) AS s ON t.id = s.id "
                    + "WHEN NOT MATCHED THEN INSERT (id, name, active, status) VALUES (?, ?, 1, ?);";
            try (java.sql.PreparedStatement ps = con.prepareStatement(staffSql)) {
                for (String[] s : staffData) {
                    int id = Integer.parseInt(s[0]);
                    ps.setInt(1, id);
                    ps.setInt(2, id);
                    ps.setNString(3, s[1]);
                    ps.setString(4, s[2]);
                    ps.executeUpdate();
                }
            }
            System.out.println("[LiteService] Seeded 5 staff members.");
        }

        // Step 2: Seed shifts for this week if none exist yet
        java.time.LocalDate today = java.time.LocalDate.now();
        java.time.LocalDate monday = today.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
        String mondayStr = monday.toString();
        String sundayStr = monday.plusDays(6).toString();

        // Check if this week already has any shifts
        boolean weekHasShifts = false;
        try (java.sql.PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Shifts WHERE shiftDate BETWEEN ? AND ?")) {
            ps.setString(1, mondayStr);
            ps.setString(2, sundayStr);
            java.sql.ResultSet rs = ps.executeQuery();
            rs.next();
            weekHasShifts = rs.getInt(1) > 0;
        }

        if (weekHasShifts) {
            System.out.println("[LiteService] Week of " + mondayStr + " already has shifts, skipping seed.");
            return;
        }

        // Load actual staff from DB to use their real IDs and names
        java.util.List<int[]> staffIds = new java.util.ArrayList<>();
        java.util.Map<Integer, String> staffNames = new java.util.LinkedHashMap<>();
        try (Statement st = con.createStatement()) {
            java.sql.ResultSet rs = st.executeQuery("SELECT TOP 5 id, name FROM dbo.Staff WHERE active=1 AND (status='Active' OR status IS NULL OR status='') ORDER BY id");
            while (rs.next()) {
                int sid = rs.getInt("id");
                staffIds.add(new int[]{sid});
                staffNames.put(sid, rs.getString("name"));
            }
        }

        if (staffIds.size() < 3) {
            System.out.println("[LiteService] Not enough active staff (" + staffIds.size() + ") to seed shifts.");
            return;
        }

        // Build shift plan using actual staff IDs
        // Phải là MÃ trong dbo.Roles: Shifts.assignedRole nay có khoá ngoại
        // trỏ sang đó, ghi 'Barista' như trước sẽ bị CSDL từ chối.
        String[][] roles = {{"barista"}, {"cashier"}, {"runner"}};
        String[][] shifts = {
            {"Ca Sáng",  "06:00 - 12:00"},
            {"Ca Chiều", "12:00 - 18:00"},
            {"Ca Tối",   "18:00 - 23:00"}
        };

        String shiftSql = "INSERT INTO dbo.Shifts (id, staffId, shiftDate, shiftName, hours, status, notes, assignedRole) " +
                           "SELECT ?, ?, ?, ?, ?, N'Đã xếp lịch', '', ? " +
                           "WHERE NOT EXISTS (SELECT 1 FROM dbo.Shifts WHERE staffId=? AND shiftDate=? AND shiftName=?)";
        int count = 0;
        try (java.sql.PreparedStatement ps = con.prepareStatement(shiftSql)) {
            int staffCount = staffIds.size();
            int rotateIdx = 0;
            for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
                String date = monday.plusDays(dayOffset).toString();
                for (String[] shift : shifts) {
                    for (String[] role : roles) {
                        int staffId = staffIds.get(rotateIdx % staffCount)[0];
                        String staffName = staffNames.get(staffId);
                        String shiftId = "seed-" + (++count) + "-" + System.currentTimeMillis();

                        ps.setString(1, shiftId);
                        ps.setInt(2, staffId);
                        ps.setString(3, date);
                        ps.setNString(4, shift[0]);
                        ps.setString(5, shift[1]);
                        ps.setString(6, role[0]);
                        ps.setInt(7, staffId);
                        ps.setString(8, date);
                        ps.setNString(9, shift[0]);
                        ps.executeUpdate();
                        rotateIdx++;
                    }
                }
            }
        }
        System.out.println("[LiteService] Seeded " + count + " shifts for week of " + mondayStr);
    }

    private void ensureStandardTables(Connection con) throws Exception {
        try (java.sql.Statement st = con.createStatement(); java.sql.ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM dbo.Tables")) {
            if (rs.next() && rs.getInt(1) > 0) return; // Only seed if empty
        }
        for (int floor = 1; floor <= 2; floor++) {
            for (int table = 1; table <= 6; table++) {
                String name = "T\u1ea7ng " + floor + " - B\u00e0n " + table;
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Tables (name, floorNo, tableNo, active) VALUES (?, ?, ?, 1)")) {
                    ps.setString(1, name);
                    ps.setInt(2, floor);
                    ps.setInt(3, table);
                    ps.executeUpdate();
                }
            }
        }
    }

    private void removeLegacyTables(Connection con) throws Exception {}

    private void clearOrphanActiveOrders(Connection con) throws Exception {
        // Dùng tableId (quan hệ thật). Fallback tableName chỉ cho dữ liệu cũ chưa backfill.
        String sql = "UPDATE dbo.Orders SET status='Cleared' "
                + "WHERE status IN " + ST_OPEN + " "
                + "AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                + "AND NOT EXISTS ("
                + "  SELECT 1 FROM dbo.Tables t WHERE t.active=1 AND ("
                + "    (dbo.Orders.tableId IS NOT NULL AND t.id = dbo.Orders.tableId)"
                + "    OR (dbo.Orders.tableId IS NULL AND t.name = dbo.Orders.tableName)"
                + "  )"
                + ")";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.executeUpdate();
        }
    }

    private void seedMenu(Connection con) throws Exception {
        upsertMenuItem(con, "Cà phê sữa", "Milk Coffee", "Cà phê", 30000, "assets/img/menu/ca-phe-sua.jpg");
        upsertMenuItem(con, "Cà phê đen", "Black Coffee", "Cà phê", 28000, "assets/img/menu/ca-phe-den.jpg");
        upsertMenuItem(con, "Bạc xỉu", "White Coffee", "Cà phê", 32000, "assets/img/menu/bac-xiu.jpg");
        upsertMenuItem(con, "Espresso", "Espresso", "Cà phê", 30000, "assets/img/menu/espresso.jpg");
        upsertMenuItem(con, "Cappuccino", "Cappuccino", "Cà phê", 38000, "assets/img/menu/cappuccino.jpg");
        upsertMenuItem(con, "Latte", "Latte", "Cà phê", 40000, "assets/img/menu/latte.jpg");
        upsertMenuItem(con, "Trà đào", "Peach Tea", "Trà", 35000, "assets/img/menu/tra-dao.jpg");
        upsertMenuItem(con, "Trà vải", "Lychee Tea", "Trà", 36000, "assets/img/menu/tra-vai.jpg");
        upsertMenuItem(con, "Trà sen vàng", "Lotus Tea", "Trà", 39000, "assets/img/menu/tra-sen-vang.jpg");
        upsertMenuItem(con, "Matcha latte", "Matcha Latte", "Đặc biệt", 42000, "assets/img/menu/matcha-latte.jpg");
        upsertMenuItem(con, "Socola đá", "Iced Chocolate", "Đặc biệt", 40000, "assets/img/menu/socola-da.jpg");
        upsertMenuItem(con, "Sinh tố xoài", "Mango Smoothie", "Đặc biệt", 45000, "assets/img/menu/sinh-to-xoai.jpg");
        upsertMenuItem(con, "Bánh croissant", "Croissant", "Bánh ngọt", 28000, "assets/img/menu/banh-croissant.jpg");
        upsertMenuItem(con, "Tiramisu", "Tiramisu", "Bánh ngọt", 42000, "assets/img/menu/tiramisu.jpg");
        upsertMenuItem(con, "Cheesecake", "Cheesecake", "Bánh ngọt", 45000, "assets/img/menu/cheesecake.jpg");
    }

    private void ensureInventoryAndRecipes(Connection con) throws Exception {
        try (Statement st = con.createStatement()) {
            st.execute("IF OBJECT_ID('dbo.Inventory','U') IS NULL CREATE TABLE dbo.Inventory (id VARCHAR(50) PRIMARY KEY, name NVARCHAR(120) NOT NULL, unit NVARCHAR(20) NOT NULL, stock INT NOT NULL DEFAULT 0, minStock INT NOT NULL DEFAULT 0, importCost INT NOT NULL DEFAULT 0)");
            st.execute("IF OBJECT_ID('dbo.RecipeItems','U') IS NULL CREATE TABLE dbo.RecipeItems (id VARCHAR(50) PRIMARY KEY, menuItemId INT NOT NULL, ingredientId VARCHAR(50) NOT NULL, quantity INT NOT NULL, FOREIGN KEY(menuItemId) REFERENCES dbo.MenuItems(id), FOREIGN KEY(ingredientId) REFERENCES dbo.Inventory(id))");
            st.execute("DELETE FROM dbo.RecipeItems WHERE CAST(menuItemId AS VARCHAR) LIKE 'm%'");
            try {
                st.execute("IF COL_LENGTH('dbo.RecipeItems','menuItemId') IS NOT NULL AND (SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RecipeItems' AND COLUMN_NAME = 'menuItemId') = 'varchar' BEGIN DELETE FROM dbo.RecipeItems WHERE menuItemId LIKE 'm%'; ALTER TABLE dbo.RecipeItems ALTER COLUMN menuItemId INT NOT NULL; END");
                st.execute("DELETE FROM dbo.RecipeItems WHERE menuItemId NOT IN (SELECT id FROM dbo.MenuItems)");
                st.execute("DELETE FROM dbo.RecipeItems WHERE ingredientId NOT IN (SELECT id FROM dbo.Inventory)");
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RecipeItems_MenuItems') ALTER TABLE dbo.RecipeItems ADD CONSTRAINT FK_RecipeItems_MenuItems FOREIGN KEY (menuItemId) REFERENCES dbo.MenuItems(id)");
                st.execute("IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RecipeItems_Inventory') ALTER TABLE dbo.RecipeItems ADD CONSTRAINT FK_RecipeItems_Inventory FOREIGN KEY (ingredientId) REFERENCES dbo.Inventory(id)");
            } catch (Exception e) {}
        }
        insertIngredientIfMissing(con, "i1", "Hạt cà phê nguyên chất", "g", 1500, 300, 50);
        insertIngredientIfMissing(con, "i2", "Sữa đặc", "g", 1000, 200, 40);
        insertIngredientIfMissing(con, "i3", "Sữa tươi", "ml", 2000, 500, 20);
        insertIngredientIfMissing(con, "i4", "Kem muối", "ml", 600, 150, 80);
        insertIngredientIfMissing(con, "i5", "Siro đào", "ml", 600, 100, 60);
        insertIngredientIfMissing(con, "i6", "Sả tươi", "nhánh", 20, 5, 1000);
        insertIngredientIfMissing(con, "i7", "Bột matcha", "g", 500, 100, 200);
        insertIngredientIfMissing(con, "i8", "Lá trà ô long", "g", 500, 100, 100);
        insertIngredientIfMissing(con, "i9", "Vỏ croissant", "cái", 15, 4, 15000);
        insertIngredientIfMissing(con, "i10", "Bánh tiramisu", "lát", 15, 3, 25000);
        insertIngredientIfMissing(con, "i11", "Bột cacao", "g", 800, 150, 120);
        insertIngredientIfMissing(con, "i12", "Sinh tố xoài", "ml", 1200, 250, 80);
        insertIngredientIfMissing(con, "i13", "Siro vải", "ml", 800, 150, 60);
        insertIngredientIfMissing(con, "i14", "Nền trà sen", "ml", 800, 150, 70);
        insertIngredientIfMissing(con, "i15", "Bánh cheesecake", "lát", 15, 3, 28000);
        seedMissingRecipes(con);
    }

    private void insertIngredientIfMissing(Connection con, String id, String name, String unit, int stock, int minStock, int importCost) throws Exception {
        String sql = "IF NOT EXISTS (SELECT 1 FROM dbo.Inventory WHERE id=?) "
                + "INSERT INTO dbo.Inventory (id,name,unit,stock,minStock,importCost) VALUES (?,?,?,?,?,?)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setString(2, id);
            ps.setString(3, name);
            ps.setString(4, unit);
            ps.setInt(5, stock);
            ps.setInt(6, minStock);
            ps.setInt(7, importCost);
            ps.executeUpdate();
        }
    }

    private void seedMissingRecipes(Connection con) throws Exception {
        List<Map<String, Object>> menu = queryRows(con, "SELECT id, nameVi, category FROM dbo.MenuItems WHERE active=1");
        for (Map<String, Object> item : menu) {
            int menuId = readInt(item.get("id"), 0);
            if (menuId <= 0 || recipeLineCount(con, menuId) > 0) continue;
            List<Map<String, Object>> defaults = defaultRecipeRows(readString(item.get("nameVi"), ""), readString(item.get("category"), ""));
            if (defaults.isEmpty()) continue;
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.RecipeItems (id,menuItemId,ingredientId,quantity) VALUES (?,?,?,?)")) {
                for (Map<String, Object> row : defaults) {
                    String ingredientId = readString(row.get("ingredientId"), "");
                    int quantity = readInt(row.get("quantity"), 0);
                    if (ingredientId.isEmpty() || quantity <= 0) continue;
                    ps.setString(1, "AUTO-" + menuId + "-" + ingredientId);
                    ps.setString(2, String.valueOf(menuId));
                    ps.setString(3, ingredientId);
                    ps.setInt(4, quantity);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
        }
    }

    private int recipeLineCount(Connection con, int menuId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.RecipeItems WHERE menuItemId=?")) {
            ps.setString(1, String.valueOf(menuId));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private List<Map<String, Object>> defaultRecipeRows(String nameVi, String category) {
        String name = fold(nameVi);
        List<Map<String, Object>> rows = new ArrayList<>();
        if (name.contains("bac xiu")) return recipeRows(recipe("i1", 20), recipe("i2", 20), recipe("i4", 50));
        if (name.contains("ca phe sua")) return recipeRows(recipe("i1", 20), recipe("i2", 30));
        if (name.contains("ca phe den") || name.contains("espresso")) return recipeRows(recipe("i1", 20));
        if (name.contains("cappuccino") || (name.contains("latte") && !name.contains("matcha"))) return recipeRows(recipe("i1", 18), recipe("i3", 120));
        if (name.contains("matcha")) return recipeRows(recipe("i7", 10), recipe("i3", 150));
        if (name.contains("socola") || name.contains("chocolate")) return recipeRows(recipe("i11", 20), recipe("i3", 150));
        if (name.contains("xoai") || name.contains("mango")) return recipeRows(recipe("i12", 150));
        if (name.contains("tra dao")) return recipeRows(recipe("i5", 30), recipe("i6", 1));
        if (name.contains("tra vai")) return recipeRows(recipe("i13", 30), recipe("i8", 12));
        if (name.contains("tra sen")) return recipeRows(recipe("i14", 30), recipe("i8", 12));
        if (name.contains("tra sua")) return recipeRows(recipe("i8", 15), recipe("i3", 100));
        if (name.contains("croissant")) return recipeRows(recipe("i9", 1));
        if (name.contains("tiramisu")) return recipeRows(recipe("i10", 1));
        if (name.contains("cheesecake")) return recipeRows(recipe("i15", 1));
        if (isDrinkCategory(category)) rows.add(recipe("i3", 100));
        return rows;
    }

    @SafeVarargs
    private final List<Map<String, Object>> recipeRows(Map<String, Object>... rows) {
        return new ArrayList<>(Arrays.asList(rows));
    }

    private Map<String, Object> recipe(String ingredientId, int quantity) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("ingredientId", ingredientId);
        row.put("quantity", quantity);
        return row;
    }

    private void upsertMenuItem(Connection con, String nameVi, String nameEn, String category, int price, String imagePath) throws Exception {
        int id = 0;
        try (PreparedStatement ps = con.prepareStatement("MERGE dbo.MenuItems AS t USING (SELECT ? nameVi, ? nameEn, ? category, ? price, ? imagePath) AS s ON t.nameVi=s.nameVi WHEN MATCHED THEN UPDATE SET nameEn=s.nameEn, category=s.category, imagePath=CASE WHEN s.imagePath IS NULL OR LTRIM(RTRIM(s.imagePath))='' THEN t.imagePath ELSE s.imagePath END WHEN NOT MATCHED THEN INSERT(nameVi,nameEn,category,price,imagePath,active) VALUES(s.nameVi,s.nameEn,s.category,s.price,s.imagePath,1);")) {
            ps.setString(1, nameVi);
            ps.setString(2, nameEn);
            ps.setString(3, category);
            ps.setInt(4, price);
            ps.setString(5, imagePath);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.MenuItems WHERE nameVi=?")) {
            ps.setString(1, nameVi);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) id = rs.getInt("id");
            }
        }
        if (id > 0 && isDrinkCategory(category) && count(con, "SELECT COUNT(*) FROM dbo.MenuItemSizes WHERE menuItemId=" + id) == 0) {
            saveMenuSizes(con, id, Arrays.asList(sizeRow("S", 0), sizeRow("M", 5000), sizeRow("L", 10000)));
        }
    }

    private Map<String, Object> sizeRow(String name, int extraPrice) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("sizeName", name);
        row.put("extraPrice", extraPrice);
        return row;
    }

    private void seedSalesHistory(Connection con) throws Exception {
        LocalDate today = appToday();
        boolean enoughHistory = countSince(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status='Cleared' AND createdAt >= ?", today.minusDays(370)) >= 160;

        List<Map<String, Object>> menu = queryRows(con, "SELECT id, nameVi, category, price FROM dbo.MenuItems WHERE active=1 ORDER BY id");
        for (Map<String, Object> item : menu) {
            item.put("sizes", getMenuSizes(con, readInt(item.get("id"), 0)));
        }
        List<Map<String, Object>> tables = queryRows(con, "SELECT id, name FROM dbo.Tables WHERE active=1 ORDER BY name");
        if (menu.isEmpty() || tables.isEmpty()) return;

        Random random = new Random(205063);
        if (!enoughHistory) {
            LocalDate start = today.minusDays(360);
            for (int day = 0; day <= 360; day += 3) {
                int orders = 2 + random.nextInt(4);
                LocalDate date = start.plusDays(day);
                for (int i = 0; i < orders; i++) {
                    Map<String, Object> table = tables.get(random.nextInt(tables.size()));
                    String tableName = readString(table.get("name"), "Tầng 1 - Bàn 1");
                    int tableId = readInt(table.get("id"), 0);
                    String createdAt = date + "T" + String.format(Locale.ROOT, "%02d:%02d:00", 8 + random.nextInt(13), random.nextInt(60));
                    int orderId = insertSeedOrder(con, tableId, tableName, createdAt, "Cleared");
                    int lineCount = 1 + random.nextInt(3);
                    int total = 0;
                    Set<Integer> used = new HashSet<>();
                    for (int line = 0; line < lineCount; line++) {
                        Map<String, Object> item = menu.get(random.nextInt(menu.size()));
                        int menuId = readInt(item.get("id"), 0);
                        if (!used.add(menuId) && menu.size() > lineCount) continue;
                        int quantity = 1 + random.nextInt(2);
                        String size = isDrink(item) ? Arrays.asList("S", "M", "L").get(random.nextInt(3)) : "";
                        int price = priceForSize(item, size);
                        total += price * quantity;
                        insertSeedOrderItem(con, orderId, menuId, readString(item.get("nameVi"), ""), size, quantity, price);
                    }
                    finishSeedOrder(con, orderId, total);
                }
            }
        }

        if (count(con, "SELECT COUNT(*) FROM dbo.Orders o JOIN dbo.Tables t ON t.id=o.tableId WHERE o.status IN " + ST_OPEN + " AND t.active=1") == 0) {
            insertLiveOrder(con, tables, "Tầng 1 - Bàn 1", menu, "Pending", random);
            insertLiveOrder(con, tables, "Tầng 1 - Bàn 2", menu, "Ready", random);
            insertLiveOrder(con, tables, "Tầng 2 - Bàn 1", menu, "Served", random);
            insertLiveOrder(con, tables, "Tầng 2 - Bàn 2", menu, "Paid", random);
        }
    }

    private int insertSeedOrder(Connection con, int tableId, String tableName, String createdAt, String status) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO dbo.Orders (tableName, tableId, status, total, subtotal, createdAt) VALUES (?,?,?,0,0,?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, tableName);
            if (tableId > 0) ps.setInt(2, tableId); else ps.setNull(2, java.sql.Types.INTEGER);
            ps.setString(3, status);
            ps.setString(4, createdAt);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    private void insertSeedOrderItem(Connection con, int orderId, int menuId, String itemName, String size, int quantity, int price) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
            ps.setInt(1, orderId);
            ps.setInt(2, menuId);
            ps.setString(3, itemName);
            ps.setString(4, size == null || size.isEmpty() ? null : size);
            ps.setInt(5, quantity);
            ps.setInt(6, price);
            ps.executeUpdate();
        }
    }

    private void finishSeedOrder(Connection con, int orderId, int total) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET orderNumber=?, total=?, subtotal=? WHERE id=?")) {
            ps.setInt(1, 1000 + orderId);
            ps.setInt(2, total);
            ps.setInt(3, total);
            ps.setInt(4, orderId);
            ps.executeUpdate();
        }
    }

    private void insertLiveOrder(Connection con, List<Map<String, Object>> tables, String preferredName,
                                 List<Map<String, Object>> menu, String status, Random random) throws Exception {
        Map<String, Object> table = null;
        for (Map<String, Object> row : tables) {
            if (preferredName.equals(readString(row.get("name"), ""))) {
                table = row;
                break;
            }
        }
        if (table == null) table = tables.get(0);
        int tableId = readInt(table.get("id"), 0);
        String tableName = readString(table.get("name"), preferredName);
        int orderId = insertSeedOrder(con, tableId, tableName,
                appToday() + "T" + String.format(Locale.ROOT, "%02d:%02d:00", 9 + random.nextInt(8), random.nextInt(60)),
                status);
        Map<String, Object> item = menu.get(random.nextInt(menu.size()));
        String size = isDrink(item) ? "M" : "";
        int price = priceForSize(item, size);
        insertSeedOrderItem(con, orderId, readInt(item.get("id"), 0), readString(item.get("nameVi"), ""), size, 1, price);
        finishSeedOrder(con, orderId, price);
    }

    private int count(Connection con, String sql) throws Exception {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private int countSince(Connection con, String sql, LocalDate start) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private void upsertUser(Connection con, String username, String password, String role, String fullName) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("MERGE dbo.Users AS t USING (SELECT ? username, ? password, ? role, ? fullName) AS s ON t.username=s.username WHEN MATCHED THEN UPDATE SET password=s.password, role=s.role, fullName=s.fullName WHEN NOT MATCHED THEN INSERT(username,password,role,fullName) VALUES(s.username,s.password,s.role,s.fullName);")) {
            ps.setString(1, username);
            ps.setString(2, password);
            ps.setString(3, role);
            ps.setString(4, fullName);
            ps.executeUpdate();
        }
    }

    private void executeIfEmpty(Connection con, String table, String sql) throws Exception {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + table)) {
            rs.next();
            if (rs.getInt(1) == 0) {
                st.execute(sql);
            }
        }
    }

    private void ensureState(Connection con, String key, int value) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey=?) INSERT INTO dbo.StoreState (stateKey,intValue) VALUES (?,?)")) {
            ps.setString(1, key);
            ps.setString(2, key);
            ps.setInt(3, value);
            ps.executeUpdate();
        }
    }

    private void ensureTableCodes(Connection con) throws Exception {
        List<Integer> missing = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.Tables WHERE code IS NULL OR LTRIM(RTRIM(code))=''");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) missing.add(rs.getInt("id"));
        }
        for (Integer id : missing) {
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET code=? WHERE id=?")) {
                ps.setString(1, uniqueTableCode(con));
                ps.setInt(2, id);
                ps.executeUpdate();
            }
        }
    }

    private String uniqueTableCode(Connection con) throws Exception {
        for (int i = 0; i < 20; i++) {
            String code = "TB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase(Locale.ROOT);
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Tables WHERE code=?")) {
                ps.setString(1, code);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) == 0) return code;
                }
            }
        }
        throw new IllegalStateException("Không tạo được mã QR cho bàn.");
    }

    public Map<String, Object> login(String username, String password) throws Exception {
        String sql = "SELECT username, role, fullName FROM dbo.Users WHERE username=? AND password=?";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public List<Map<String, Object>> getMenu(boolean includeInactive) throws Exception {
        String sql = "SELECT id, nameVi, nameEn, category, price, active, imagePath FROM dbo.MenuItems " + (includeInactive ? "" : "WHERE active=1 ") + "ORDER BY category, nameVi";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> menu = rows(rs);
            Set<Integer> bestSellerIds = getBestSellerMenuIdsByCategory(con, menu);
            
            dao.RecipeDAO recipeDao = new dao.RecipeDAO();
            java.util.Map<String, java.util.List<model.RecipeItem>> allRecipes = recipeDao.getAllRecipesMappedByMenuItemId();
            java.util.Map<Integer, java.util.List<Map<String, Object>>> allSizes = getAllMenuSizesMapped(con);
            Map<String, Integer> stockMap = getIngredientStockMap(con);
            Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);
            
            List<Map<String, Object>> visible = new ArrayList<>();
            for (Map<String, Object> item : menu) {
                int itemId = readInt(item.get("id"), 0);
                List<model.RecipeItem> recipes = allRecipes.getOrDefault(String.valueOf(itemId), new java.util.ArrayList<>());
                int availableQty = availableQuantity(recipes, stockMap, reservedMap.getOrDefault(itemId, 0));
                item.put("sizes", allSizes.getOrDefault(itemId, new java.util.ArrayList<>()));
                item.put("recipes", recipes.stream().map(r -> r.toMap()).collect(java.util.stream.Collectors.toList()));
                item.put("bestSeller", bestSellerIds.contains(itemId));
                item.put("availableQty", availableQty);
                if (includeInactive || recipes.isEmpty() || availableQty > 0) {
                    visible.add(item);
                }
            }
            return visible;
        }
    }

    private Set<Integer> getBestSellerMenuIdsByCategory(Connection con, List<Map<String, Object>> menu) throws Exception {
        Set<Integer> ids = new LinkedHashSet<>();
        Set<Integer> menuIds = new HashSet<>();
        for (Map<String, Object> item : menu) {
            int itemId = readInt(item.get("id"), 0);
            if (itemId > 0) menuIds.add(itemId);
        }
        if (menuIds.isEmpty()) return ids;
        Set<String> claimedCategories = new HashSet<>();
        String sql = "SELECT m.category, oi.menuItemId, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.Orders o ON o.id = oi.orderId "
                + "JOIN dbo.MenuItems m ON m.id = oi.menuItemId "
                + "WHERE o.status IN " + ST_REVENUE + " AND oi.menuItemId IS NOT NULL AND oi.menuItemId > 0 "
                + "GROUP BY m.category, oi.menuItemId "
                + "ORDER BY m.category, SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC, oi.menuItemId";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String category = readString(rs.getString("category"), "");
                int menuItemId = rs.getInt("menuItemId");
                if (category.isEmpty() || menuItemId <= 0 || !menuIds.contains(menuItemId) || !claimedCategories.add(category)) continue;
                ids.add(menuItemId);
            }
        }
        return ids;
    }

    public Map<String, Object> saveMenuItem(Map<String, Object> data) throws Exception {
        int id = readInt(data.get("id"), 0);
        String nameVi = readString(data.get("nameVi"), "");
        String nameEn = readString(data.get("nameEn"), nameVi);
        String category = normalizeCategory(readString(data.get("category"), "Cà phê"));
        int price = readInt(data.get("price"), 0);
        boolean active = readBoolean(data.get("active"), true);
        String imagePath = readString(data.get("imagePath"), "");
        if (imagePath.isEmpty()) {
            imagePath = imagePathForMenuItem(nameVi, category);
        }
        boolean hasSizes = readBoolean(data.get("hasSizes"), false);
        List<Map<String, Object>> sizes = normalizeSizeRows(data.get("sizes"), hasSizes);
        validateMenuItem(id, nameVi, nameEn, category, price, imagePath);

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                if (menuNameExists(con, id, nameVi, nameEn)) {
                    throw new IllegalArgumentException("Tên món đã tồn tại.");
                }
                if (id > 0) {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.MenuItems SET nameVi=?, nameEn=?, category=?, price=?, active=?, imagePath=? WHERE id=?")) {
                        ps.setString(1, nameVi);
                        ps.setString(2, nameEn);
                        ps.setString(3, category);
                        ps.setInt(4, price);
                        ps.setBoolean(5, active);
                        ps.setString(6, imagePath);
                        ps.setInt(7, id);
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.MenuItems (nameVi,nameEn,category,price,active,imagePath) VALUES (?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                        ps.setString(1, nameVi);
                        ps.setString(2, nameEn);
                        ps.setString(3, category);
                        ps.setInt(4, price);
                        ps.setBoolean(5, active);
                        ps.setString(6, imagePath);
                        ps.executeUpdate();
                        try (ResultSet keys = ps.getGeneratedKeys()) {
                            if (keys.next()) id = keys.getInt(1);
                        }
                    }
                }
                saveMenuSizes(con, id, sizes);
                saveMenuRecipes(con, id, data.get("recipes"));
                con.commit();
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
        return getMenuItem(id);
    }

    private void saveMenuRecipes(Connection con, int menuItemId, Object recipesObj) throws Exception {
        List<model.RecipeItem> recipeItems = normalizeAndValidateRecipes(con, recipesObj);
        new dao.RecipeDAO().saveForMenuItem(con, String.valueOf(menuItemId), recipeItems);
    }

    private List<model.RecipeItem> normalizeAndValidateRecipes(Connection con, Object recipesObj) throws Exception {
        List<model.RecipeItem> recipeItems = new java.util.ArrayList<>();
        if (!(recipesObj instanceof List)) {
            return recipeItems;
        }

        List<?> list = (List<?>) recipesObj;
        java.util.Set<String> seenIngredientIds = new java.util.HashSet<>();
        for (Object raw : list) {
            if (!(raw instanceof Map)) continue;
            Map<String, Object> row = (Map<String, Object>) raw;
            String ingredientId = readString(row.get("ingredientId"), "").trim();
            int quantity = readInt(row.get("quantity"), 0);
            if (ingredientId.isEmpty() && quantity <= 0) continue;
            if (ingredientId.isEmpty()) {
                throw new IllegalArgumentException("Công thức thiếu mã nguyên liệu.");
            }
            if (quantity <= 0) {
                throw new IllegalArgumentException("Số lượng nguyên liệu trong công thức phải lớn hơn 0.");
            }
            String key = ingredientId.toLowerCase(java.util.Locale.ROOT);
            if (!seenIngredientIds.add(key)) {
                throw new IllegalArgumentException("Công thức bị trùng nguyên liệu: " + ingredientId);
            }
            if (!ingredientExists(con, ingredientId)) {
                throw new IllegalArgumentException("Nguyên liệu không tồn tại: " + ingredientId);
            }
            model.RecipeItem item = new model.RecipeItem();
            item.setIngredientId(ingredientId);
            item.setQuantity(quantity);
            recipeItems.add(item);
        }
        return recipeItems;
    }

    private boolean ingredientExists(Connection con, String ingredientId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM dbo.Inventory WHERE id = ?")) {
            ps.setString(1, ingredientId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public void deleteMenuItem(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("UPDATE dbo.MenuItems SET active=0 WHERE id=?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    public Map<String, Object> getMenuItem(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, nameVi, nameEn, category, price, active, imagePath FROM dbo.MenuItems WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> item = row(rs);
                item.put("sizes", getMenuSizes(con, id));
                item.put("recipes", new dao.RecipeDAO().getByMenuItemId(String.valueOf(id)).stream().map(r -> r.toMap()).collect(java.util.stream.Collectors.toList()));
                return item;
            }
        }
    }

    public Map<String, Object> importMenuItems(List<Map<String, Object>> rows) {
        List<Map<String, Object>> imported = new ArrayList<>();
        List<Map<String, Object>> skipped = new ArrayList<>();
        Map<String, String> ingredientLookup = loadIngredientLookup();
        int rowNumber = 1;
        for (Map<String, Object> data : rows) {
            rowNumber++;
            try {
                resolveImportRecipes(data, ingredientLookup);
                imported.add(saveMenuItem(data));
            } catch (Exception e) {
                Map<String, Object> failure = new LinkedHashMap<>();
                failure.put("row", rowNumber);
                failure.put("nameVi", readString(data.get("nameVi"), ""));
                failure.put("reason", e.getMessage());
                skipped.add(failure);
            }
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("importedCount", imported.size());
        result.put("skippedCount", skipped.size());
        result.put("imported", imported);
        result.put("skipped", skipped);
        return result;
    }

    // Builds a lookup of both ingredient code (id) and ingredient name -> real inventory id,
    // so an imported recipe cell can reference an ingredient by its friendly name or by its code.
    private Map<String, String> loadIngredientLookup() {
        Map<String, String> lookup = new HashMap<>();
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT id, name FROM dbo.Inventory");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String id = rs.getString("id");
                if (id == null) continue;
                lookup.put(fold(id), id);
                String name = rs.getString("name");
                if (name != null && !name.trim().isEmpty()) lookup.putIfAbsent(fold(name), id);
            }
        } catch (Exception e) {
            // Best effort: if the lookup can't be built, recipe tokens are passed through unchanged.
        }
        return lookup;
    }

    // Rewrites each recipe's ingredientId (which may be a name or a code from the Excel cell)
    // into a real inventory id. Throws with a clear reason when an ingredient can't be matched
    // so the row is reported in the import's skipped list.
    private void resolveImportRecipes(Map<String, Object> data, Map<String, String> lookup) {
        Object raw = data.get("recipes");
        if (!(raw instanceof List)) return;
        for (Object entry : (List<?>) raw) {
            if (!(entry instanceof Map)) continue;
            @SuppressWarnings("unchecked")
            Map<String, Object> row = (Map<String, Object>) entry;
            String token = readString(row.get("ingredientId"), "").trim();
            if (token.isEmpty()) continue;
            String resolved = lookup.get(fold(token));
            if (resolved == null) {
                throw new IllegalArgumentException("Không tìm thấy nguyên liệu: " + token);
            }
            row.put("ingredientId", resolved);
        }
    }

    private void validateMenuItem(int id, String nameVi, String nameEn, String category, int price, String imagePath) {
        if (nameVi.length() < 2 || nameVi.length() > 80) {
            throw new IllegalArgumentException("Tên tiếng Việt phải từ 2 đến 80 ký tự.");
        }
        if (nameEn.length() < 2 || nameEn.length() > 80) {
            throw new IllegalArgumentException("Tên tiếng Anh phải từ 2 đến 80 ký tự.");
        }
        if (!allowedCategories().contains(category)) {
            throw new IllegalArgumentException("Nhóm món không hợp lệ.");
        }
        if (price < 10000 || price > 200000 || price % 1000 != 0) {
            throw new IllegalArgumentException("Giá phải từ 10.000đ đến 200.000đ và chia hết cho 1.000đ.");
        }
        if (!imagePath.startsWith("assets/img/menu/") || !(imagePath.endsWith(".jpg") || imagePath.endsWith(".png"))) {
            throw new IllegalArgumentException("Ảnh món phải là ảnh thật JPG/PNG trong thư mục assets/img/menu.");
        }
    }

    private boolean menuNameExists(Connection con, int id, String nameVi, String nameEn) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.MenuItems WHERE id<>? AND (LOWER(nameVi)=LOWER(?) OR LOWER(nameEn)=LOWER(?))")) {
            ps.setInt(1, id);
            ps.setString(2, nameVi);
            ps.setString(3, nameEn);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private List<Map<String, Object>> getMenuSizes(Connection con, int menuItemId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT sizeName, extraPrice FROM dbo.MenuItemSizes WHERE menuItemId=? ORDER BY sortOrder, id")) {
            ps.setInt(1, menuItemId);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    private java.util.Map<Integer, java.util.List<Map<String, Object>>> getAllMenuSizesMapped(Connection con) throws Exception {
        java.util.Map<Integer, java.util.List<Map<String, Object>>> map = new java.util.HashMap<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT menuItemId, sizeName, extraPrice FROM dbo.MenuItemSizes ORDER BY sortOrder, id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int menuId = rs.getInt("menuItemId");
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("sizeName", rs.getString("sizeName"));
                row.put("extraPrice", rs.getInt("extraPrice"));
                map.computeIfAbsent(menuId, k -> new java.util.ArrayList<>()).add(row);
            }
        }
        return map;
    }

    private void saveMenuSizes(Connection con, int menuItemId, List<Map<String, Object>> sizes) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.MenuItemSizes WHERE menuItemId=?")) {
            ps.setInt(1, menuItemId);
            ps.executeUpdate();
        }
        int index = 0;
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.MenuItemSizes (menuItemId,sizeName,extraPrice,sortOrder) VALUES (?,?,?,?)")) {
            for (Map<String, Object> size : sizes) {
                ps.setInt(1, menuItemId);
                ps.setString(2, readString(size.get("sizeName"), "S"));
                ps.setInt(3, readInt(size.get("extraPrice"), 0));
                ps.setInt(4, index++);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private List<Map<String, Object>> normalizeSizeRows(Object raw, boolean hasSizes) {
        if (!hasSizes) return new ArrayList<>();
        List<Map<String, Object>> normalized = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        normalized.add(sizeRow("S", 0));
        seen.add("S");
        if (raw instanceof List<?>) {
            for (Object entry : (List<?>) raw) {
                if (!(entry instanceof Map<?, ?>)) continue;
                Map<?, ?> row = (Map<?, ?>) entry;
                String name = readString(row.get("sizeName"), "").trim().toUpperCase(Locale.ROOT);
                if (name.isEmpty() || name.length() > 12 || !name.matches("[A-Z0-9+\\- ]+")) {
                    throw new IllegalArgumentException("Tên size chỉ dùng chữ, số, dấu + hoặc - và tối đa 12 ký tự.");
                }
                int extra = readInt(row.get("extraPrice"), 0);
                if (extra < 0 || extra > 100000 || extra % 1000 != 0) {
                    throw new IllegalArgumentException("Tiền chênh size phải từ 0đ đến 100.000đ và chia hết cho 1.000đ.");
                }
                if ("S".equals(name)) {
                    if (extra != 0) throw new IllegalArgumentException("Size S là giá gốc nên tiền chênh phải bằng 0.");
                    continue;
                }
                if (seen.add(name)) normalized.add(sizeRow(name, extra));
            }
        }
        if (normalized.size() > 8) throw new IllegalArgumentException("Một sản phẩm chỉ nên có tối đa 8 size.");
        return normalized;
    }

    private List<String> allowedCategories() {
        return Arrays.asList("Cà phê", "Trà", "Đặc biệt", "Bánh ngọt");
    }

    private String normalizeCategory(String category) {
        String folded = fold(category);
        if (folded.contains("coffee") || folded.contains("ca phe")) return "Cà phê";
        if (folded.contains("tea") || folded.contains("tra")) return "Trà";
        if (folded.contains("special") || folded.contains("dac biet")) return "Đặc biệt";
        if (folded.contains("food") || folded.contains("pastry") || folded.contains("banh")) return "Bánh ngọt";
        return category;
    }

    private String imagePathForMenuItem(String nameVi, String category) {
        String foldedName = fold(nameVi);
        if (foldedName.contains("ca phe sua")) return "assets/img/menu/ca-phe-sua.jpg";
        if (foldedName.contains("ca phe den")) return "assets/img/menu/ca-phe-den.jpg";
        if (foldedName.contains("bac xiu")) return "assets/img/menu/bac-xiu.jpg";
        if (foldedName.contains("espresso")) return "assets/img/menu/espresso.jpg";
        if (foldedName.contains("cappuccino")) return "assets/img/menu/cappuccino.jpg";
        if (foldedName.contains("matcha")) return "assets/img/menu/matcha-latte.jpg";
        if (foldedName.equals("latte") || foldedName.startsWith("latte ")) return "assets/img/menu/latte.jpg";
        if (foldedName.contains("tra dao")) return "assets/img/menu/tra-dao.jpg";
        if (foldedName.contains("tra vai")) return "assets/img/menu/tra-vai.jpg";
        if (foldedName.contains("tra sen")) return "assets/img/menu/tra-sen-vang.jpg";
        if (foldedName.contains("socola") || foldedName.contains("chocolate")) return "assets/img/menu/socola-da.jpg";
        if (foldedName.contains("sinh to xoai") || foldedName.contains("mango")) return "assets/img/menu/sinh-to-xoai.jpg";
        if (foldedName.contains("croissant")) return "assets/img/menu/banh-croissant.jpg";
        if (foldedName.contains("tiramisu")) return "assets/img/menu/tiramisu.jpg";
        if (foldedName.contains("cheesecake")) return "assets/img/menu/cheesecake.jpg";
        return defaultImagePath(category);
    }

    private String defaultImagePath(String category) {
        String folded = fold(category);
        if (folded.contains("tra")) return "assets/img/menu/tea.jpg";
        if (folded.contains("dac biet")) return "assets/img/menu/matcha.jpg";
        if (folded.contains("banh")) return "assets/img/menu/pastry.jpg";
        return "assets/img/menu/coffee.jpg";
    }

    private String fold(String value) {
        String normalized = java.text.Normalizer.normalize(value == null ? "" : value, java.text.Normalizer.Form.NFD);
        return normalized.replaceAll("\\p{M}", "").replace('đ', 'd').replace('Đ', 'D').toLowerCase(Locale.ROOT);
    }

    public List<Map<String, Object>> getTables() throws Exception {
        return getTables(false);
    }

    /** Bản công khai cho khách: không lộ mã QR toàn sàn. */
    public List<Map<String, Object>> getPublicTables() throws Exception {
        List<Map<String, Object>> tables = getTables(false);
        List<Map<String, Object>> sanitized = new ArrayList<>();
        for (Map<String, Object> table : tables) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", table.get("id"));
            row.put("name", table.get("name"));
            row.put("floorNo", table.get("floorNo"));
            row.put("tableNo", table.get("tableNo"));
            row.put("active", table.get("active"));
            sanitized.add(row);
        }
        return sanitized;
    }

    public List<Map<String, Object>> getAllTables() throws Exception {
        return getTables(true);
    }

    public List<Map<String, Object>> getTableMap() throws Exception {
        String sql = "SELECT t.id, t.name, t.code, t.active, t.floorNo, t.tableNo, "
                + "activeOrder.id orderId, activeOrder.orderNumber, activeOrder.status, "
                + "ISNULL(openCnt.cnt,0) openOrderCount, ISNULL(unpaidCnt.cnt,0) unpaidCount "
                + "FROM dbo.Tables t "
                + "OUTER APPLY (SELECT TOP 1 id, orderNumber, status FROM dbo.Orders "
                + "  WHERE status IN " + ST_OPEN + " AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                + "    AND (tableId = t.id OR (tableId IS NULL AND tableName = t.name)) "
                + "  ORDER BY id DESC) activeOrder "
                + "OUTER APPLY (SELECT COUNT(*) cnt FROM dbo.Orders "
                + "  WHERE status IN " + ST_OPEN + " AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                + "    AND (tableId = t.id OR (tableId IS NULL AND tableName = t.name))) openCnt "
                + "OUTER APPLY (SELECT COUNT(*) cnt FROM dbo.Orders "
                + "  WHERE status IN " + ST_PRE_PAID + " AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                + "    AND (tableId = t.id OR (tableId IS NULL AND tableName = t.name))) unpaidCnt "
                + "WHERE t.active=1 "
                + "ORDER BY ISNULL(t.floorNo, 1), ISNULL(t.tableNo, 999), t.name";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> tables = rows(rs);
            for (Map<String, Object> table : tables) {
                int openCount = readInt(table.get("openOrderCount"), 0);
                table.put("busy", openCount > 0);
                table.put("hasUnpaid", readInt(table.get("unpaidCount"), 0) > 0);
            }
            return tables;
        }
    }

    public List<Map<String, Object>> getRunnerTableMap() throws Exception {
        List<Map<String, Object>> full = getTableMap();
        List<Map<String, Object>> sanitized = new java.util.ArrayList<>();
        for (Map<String, Object> table : full) {
            Map<String, Object> row = new java.util.LinkedHashMap<>();
            row.put("id", table.get("id"));
            row.put("name", table.get("name"));
            row.put("floorNo", table.get("floorNo"));
            row.put("tableNo", table.get("tableNo"));
            row.put("status", table.get("status"));
            row.put("busy", table.get("busy"));
            row.put("openOrderCount", table.get("openOrderCount"));
            row.put("hasUnpaid", table.get("hasUnpaid"));
            sanitized.add(row);
        }
        return sanitized;
    }

    public List<Map<String, Object>> getOpenOrdersByTable(String tableCode, String tableName) throws Exception {
        int tableId = 0;
        String resolvedTable = readString(tableName, "");
        if (!readString(tableCode, "").isEmpty()) {
            Map<String, Object> table = getTableByCode(tableCode);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            resolvedTable = readString(table.get("name"), "");
            tableId = readInt(table.get("id"), 0);
        } else if (!resolvedTable.isEmpty()) {
            Map<String, Object> table = getTableByName(resolvedTable);
            if (table != null) tableId = readInt(table.get("id"), 0);
        }
        if (resolvedTable.isEmpty() && tableId <= 0) throw new IllegalArgumentException("Không tìm thấy bàn.");
        String sql = "SELECT id, orderNumber, tableName, tableId, customerPhone, status, total, subtotal, discountAmount, pointsEarned, pointsRedeemed, customerId, note, createdAt, invoicePrinted, ISNULL(orderType,'DINE_IN') orderType, ISNULL(promoDiscount,0) promoDiscount, ISNULL(manualDiscount,0) manualDiscount, ISNULL(taxAmount,0) taxAmount, ISNULL(serviceCharge,0) serviceCharge, ISNULL(tipAmount,0) tipAmount FROM dbo.Orders "
                + "WHERE status IN " + ST_OPEN + " "
                + "AND ( (? > 0 AND tableId = ?) OR (tableId IS NULL AND tableName = ?) ) "
                + "ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, tableId);
            ps.setInt(2, tableId);
            ps.setString(3, resolvedTable);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> list = rows(rs);
                for (Map<String, Object> order : list) {
                    order.put("items", getOrderItems(readInt(order.get("id"), 0)));
                }
                return list;
            }
        }
    }

    public List<Map<String, Object>> getOpenOrdersByIds(List<Integer> orderIds) throws Exception {
        List<Integer> ids = cleanIds(orderIds);
        if (ids.isEmpty()) return new ArrayList<>();
        String sql = "SELECT id, orderNumber, tableName, tableId, customerPhone, status, total, subtotal, discountAmount, pointsEarned, pointsRedeemed, customerId, note, createdAt, invoicePrinted, splitLocked, ISNULL(orderType,'DINE_IN') orderType, ISNULL(promoDiscount,0) promoDiscount, ISNULL(manualDiscount,0) manualDiscount, discountReason, ISNULL(taxAmount,0) taxAmount, ISNULL(serviceCharge,0) serviceCharge, ISNULL(tipAmount,0) tipAmount, cancelReason, cancelledAt, promotionId FROM dbo.Orders "
                + "WHERE id IN (" + placeholders(ids.size()) + ") AND status IN " + ST_OPEN + " ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            bindIds(ps, ids);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> list = rows(rs);
                for (Map<String, Object> order : list) {
                    order.put("items", getOrderItems(readInt(order.get("id"), 0)));
                }
                return list;
            }
        }
    }

    /** Lấy đơn theo id, mọi trạng thái (dùng cho theo dõi phiên khách). */
    public List<Map<String, Object>> getOrdersByIds(List<Integer> orderIds) throws Exception {
        List<Integer> ids = cleanIds(orderIds);
        if (ids.isEmpty()) return new ArrayList<>();
        String sql = "SELECT id, orderNumber, tableName, tableId, customerPhone, status, total, subtotal, discountAmount, pointsEarned, pointsRedeemed, customerId, note, createdAt, invoicePrinted, splitLocked, ISNULL(orderType,'DINE_IN') orderType, ISNULL(promoDiscount,0) promoDiscount, ISNULL(manualDiscount,0) manualDiscount, discountReason, ISNULL(taxAmount,0) taxAmount, ISNULL(serviceCharge,0) serviceCharge, ISNULL(tipAmount,0) tipAmount, cancelReason, cancelledAt, promotionId FROM dbo.Orders "
                + "WHERE id IN (" + placeholders(ids.size()) + ") ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            bindIds(ps, ids);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> list = rows(rs);
                for (Map<String, Object> order : list) {
                    order.put("items", getOrderItems(readInt(order.get("id"), 0)));
                }
                return list;
            }
        }
    }

    public String currentTableForOrderIds(List<Integer> orderIds) throws Exception {
        List<Integer> ids = cleanIds(orderIds);
        if (ids.isEmpty()) return "";
        String sql = "SELECT TOP 1 tableName FROM dbo.Orders "
                + "WHERE id IN (" + placeholders(ids.size()) + ") AND status IN " + ST_OPEN + " ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            bindIds(ps, ids);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? readString(rs.getString("tableName"), "") : "";
            }
        }
    }

    public Map<String, Object> transferTable(int fromTableId, int toTableId) throws Exception {
        return transferTable(fromTableId, toTableId, "system", "system");
    }

    public Map<String, Object> transferTable(int fromTableId, int toTableId, String actorRole, String actorName) throws Exception {
        if (fromTableId == toTableId) throw new IllegalArgumentException("Bàn mới phải khác bàn hiện tại.");
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            Map<String, Object> from = tableRowForUpdate(con, fromTableId);
            Map<String, Object> to = tableRowForUpdate(con, toTableId);
            if (from == null || to == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            if (!readBoolean(from.get("active"), false) || !readBoolean(to.get("active"), false)) {
                throw new IllegalArgumentException("Bàn đã ẩn không thể đổi.");
            }
            String fromName = readString(from.get("name"), "");
            String toName = readString(to.get("name"), "");
            int sourceOrders = countOpenOrders(con, fromTableId, fromName, ST_PRE_PAID);
            if (sourceOrders == 0) throw new IllegalArgumentException("Bàn hiện tại không có đơn cần chuyển.");
            int targetOrders = countOpenOrders(con, toTableId, toName, ST_OPEN);
            if (targetOrders > 0) throw new IllegalArgumentException("Bàn mới đang có khách.");
            // Chuyển bàn giờ đổi KHOÁ NGOẠI, không phải sửa chuỗi tên.
            // tableName vẫn cập nhật theo để bản chụp khớp bàn hiện tại.
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Orders SET tableId=?, tableName=? WHERE tableId=? AND status IN " + ST_PRE_PAID
                            + " AND ISNULL(orderType,'DINE_IN')='DINE_IN'")) {
                ps.setInt(1, toTableId);
                ps.setString(2, toName);
                ps.setInt(3, fromTableId);
                ps.executeUpdate();
            }
            // Đơn cũ chưa có tableId (dữ liệu trước khi thêm khoá) thì vẫn ghép theo tên.
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Orders SET tableId=?, tableName=? WHERE tableId IS NULL AND tableName=? AND status IN " + ST_PRE_PAID
                            + " AND ISNULL(orderType,'DINE_IN')='DINE_IN'")) {
                ps.setInt(1, toTableId);
                ps.setString(2, toName);
                ps.setString(3, fromName);
                ps.executeUpdate();
            }
            insertSystemLog(con, actorRole, actorName, "TABLE_TRANSFER",
                    "Đổi " + sourceOrders + " đơn từ " + fromName + " sang " + toName + " lúc " + nowLabelVi(),
                    "Moved " + sourceOrders + " order(s) from " + fromName + " to " + toName + " at " + nowLabelEn(),
                    null);
            con.commit();
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("message", "Table transferred");
            result.put("fromTableId", fromTableId);
            result.put("fromTableName", fromName);
            result.put("toTableId", toTableId);
            result.put("toTableName", toName);
            result.put("movedOrders", sourceOrders);
            return result;
        }
    }

    private Map<String, Object> tableRowForUpdate(Connection con, int tableId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT id, name, active FROM dbo.Tables WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
            ps.setInt(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    private int countOpenOrders(Connection con, int tableId, String tableName, String statuses) throws Exception {
        String sql = "SELECT COUNT(*) FROM dbo.Orders WHERE status IN " + statuses
                + " AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                + " AND ( (? > 0 AND tableId = ?) OR (tableId IS NULL AND tableName = ?) )";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, tableId);
            ps.setInt(2, tableId);
            ps.setString(3, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    public Map<String, Object> clearServedTable(int tableId) throws Exception {
        return clearServedTable(tableId, "system", "system");
    }

    public Map<String, Object> clearServedTable(int tableId, String actorRole, String actorName) throws Exception {
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            Map<String, Object> table = tableRowForUpdate(con, tableId);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            String tableName = readString(table.get("name"), "");

            int notClearedYet = countOpenOrders(con, tableId, tableName, ST_PRE_PAID);
            if (notClearedYet > 0) {
                throw new IllegalArgumentException("Bàn vẫn còn đơn đang phục vụ, chưa thể dọn.");
            }

            List<Integer> orderIds = new ArrayList<>();
            List<Integer> orderNumbers = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id, orderNumber FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) "
                            + "WHERE status='Paid' AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                            + "AND (tableId=? OR (tableId IS NULL AND tableName=?)) ORDER BY id")) {
                ps.setInt(1, tableId);
                ps.setString(2, tableName);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        orderIds.add(rs.getInt("id"));
                        orderNumbers.add(rs.getInt("orderNumber"));
                    }
                }
            }
            if (orderIds.isEmpty()) throw new IllegalArgumentException("Bàn này không có đơn chờ dọn.");

            int clearedCount;
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Orders SET status='Cleared' WHERE status='Paid' AND ISNULL(orderType,'DINE_IN')='DINE_IN' "
                            + "AND (tableId=? OR (tableId IS NULL AND tableName=?))")) {
                ps.setInt(1, tableId);
                ps.setString(2, tableName);
                clearedCount = ps.executeUpdate();
                if (clearedCount == 0) {
                    throw new IllegalArgumentException("Bàn này vừa được cập nhật bởi thiết bị khác.");
                }
            }
            String orderLabel = orderNumbers.stream().map(number -> "#" + number).reduce((a, b) -> a + ", " + b).orElse("");
            insertSystemLog(con, actorRole, actorName, "TABLE_CLEAR",
                    "Bồi bàn dọn xong " + tableName + " cho " + clearedCount + " hóa đơn " + orderLabel + " lúc " + nowLabelVi(),
                    "Waiter cleared " + tableName + " for " + clearedCount + " bill(s) " + orderLabel + " at " + nowLabelEn(),
                    orderIds.get(0));
            con.commit();
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("message", "Table ready");
            result.put("tableId", tableId);
            result.put("tableName", tableName);
            result.put("busy", false);
            result.put("status", "Available");
            result.put("orderId", orderIds.get(0));
            result.put("orderNumber", orderNumbers.get(0));
            result.put("orderIds", orderIds);
            result.put("orderNumbers", orderNumbers);
            result.put("clearedOrders", clearedCount);
            result.put("orderStatus", "Cleared");
            return result;
        }
    }

    private List<Map<String, Object>> getTables(boolean includeInactive) throws Exception {
        String where = includeInactive ? "" : "WHERE active=1 ";
        String sql = "SELECT id, name, code, floorNo, tableNo, active FROM dbo.Tables " + where + "ORDER BY name";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    public Map<String, Object> getTableByCode(String code) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, name, code, floorNo, tableNo, active FROM dbo.Tables WHERE code=? AND active=1")) {
            ps.setString(1, readString(code, ""));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public Map<String, Object> getTableByName(String name) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, name, code, floorNo, tableNo, active FROM dbo.Tables WHERE name=? AND active=1")) {
            ps.setString(1, readString(name, ""));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public Map<String, Object> getTableById(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, name, code, floorNo, tableNo, active FROM dbo.Tables WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public Map<String, Object> saveTable(Map<String, Object> data) throws Exception {
        int id = readInt(data.get("id"), 0);
        String name = readString(data.get("name"), "");
        if (name.isEmpty()) throw new IllegalArgumentException("TÃªn bÃ n khÃ´ng há»£p lá»‡.");
        boolean active = readBoolean(data.get("active"), true);
        if (name.length() < 2 || name.length() > 60) throw new IllegalArgumentException("TÃªn bÃ n pháº£i tá»« 2 Ä‘áº¿n 60 kÃ½ tá»±.");
        int floorNo = readInt(data.get("floorNo"), 1);
        int tableNo = readInt(data.get("tableNo"), 1);
        try (Connection con = db.getConnection()) {
            if (id > 0) {
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET name=?, floorNo=?, tableNo=?, active=? WHERE id=?")) {
                    ps.setString(1, name);
                    ps.setInt(2, floorNo);
                    ps.setInt(3, tableNo);
                    ps.setBoolean(4, active);
                    ps.setInt(5, id);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Tables (name, code, floorNo, tableNo, active) VALUES (?,?,?,?,?)", java.sql.Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.setString(2, uniqueTableCode(con));
                    ps.setInt(3, floorNo);
                    ps.setInt(4, tableNo);
                    ps.setBoolean(5, active);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) id = keys.getInt(1);
                    }
                }
            }
        }
        Map<String, Object> result = new java.util.LinkedHashMap<>(data);
        result.put("id", id);
        result.put("name", name);
        result.put("active", active);
        return result;
    }

    

    

    private int[] parseTableLocation(String name) {
        String text = readString(name, "");
        java.util.regex.Matcher match = java.util.regex.Pattern.compile("T.*ng\\s*(\\d+)\\s*-\\s*B.*n\\s*(\\d+)", java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.UNICODE_CASE).matcher(text);
        if (match.find()) return new int[] { readInt(match.group(1), 0), readInt(match.group(2), 0) };
        match = java.util.regex.Pattern.compile("B.*n\\s*(\\d+)", java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.UNICODE_CASE).matcher(text);
        if (match.find()) return new int[] { 1, readInt(match.group(1), 0) };
        return new int[] { 0, 0 };
    }

    public Map<String, Object> regenerateTableCode(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET code=? WHERE id=?")) {
            ps.setString(1, uniqueTableCode(con));
            ps.setInt(2, id);
            ps.executeUpdate();
        }
        return getTableById(id);
    }

    public void deleteTable(int id) throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> table = getTableById(id);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            String name = readString(table.get("name"), "");
            int activeOrders = countOpenOrders(con, id, name, ST_OPEN);
            if (activeOrders > 0) throw new IllegalArgumentException("Bàn đang có đơn, không thể xoá.");
            // Soft-delete: giữ FK lịch sử Orders.tableId, chỉ ẩn bàn khỏi vận hành.
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET active=0 WHERE id=?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
        }
    }

    public Map<String, Object> createOrder(Map<String, Object> data) throws Exception {
        return createOrder(data, "guest", "");
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> createOrder(Map<String, Object> data, String actorRole, String actorName) throws Exception {
        String orderType = readString(data.get("orderType"), ORDER_TYPE_DINE_IN).trim().toUpperCase(Locale.ROOT);
        if (!ORDER_TYPE_TAKEAWAY.equals(orderType)) orderType = ORDER_TYPE_DINE_IN;
        String tableName;
        int orderTableId = 0;
        if (ORDER_TYPE_TAKEAWAY.equals(orderType)) {
            tableName = "Mang đi";
            orderTableId = 0;
        } else {
            tableName = readString(data.get("tableName"), "Bàn 1");
            // Lấy luôn bản ghi bàn để có KHOÁ, không chỉ để kiểm tra tồn tại.
            // tableName vẫn được lưu, nhưng từ nay chỉ là BẢN CHỤP tên tại thời
            // điểm đặt đơn — đổi tên bàn về sau không làm sai lịch sử nữa.
            Map<String, Object> orderTable = getTableByName(tableName);
            if (orderTable == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            orderTableId = readInt(orderTable.get("id"), 0);
        }
        String phone = readString(data.get("customerPhone"), "");
        String note = limitNote(readString(data.get("note"), ""));
        // Khách đã đăng nhập: servlet gắn sẵn customerId vào body, trình duyệt
        // không tự khai được. requestedRedeem là số điểm khách muốn dùng.
        int customerId = readInt(data.get("customerId"), 0);
        int requestedRedeem = Math.max(0, readInt(data.get("redeemPoints"), 0));
        if (customerId <= 0) requestedRedeem = 0;
        String promoCode = readString(data.get("promoCode"), "").trim().toUpperCase(Locale.ROOT);
        int manualDiscountReq = Math.max(0, readInt(data.get("manualDiscount"), 0));
        String discountReason = limitNote(readString(data.get("discountReason"), ""));
        if (manualDiscountReq > 0 && !"admin".equals(normalizeActor(actorRole))) {
            throw new IllegalArgumentException("Chỉ quản trị được giảm giá tay.");
        }
        if (manualDiscountReq > 0 && discountReason.isEmpty()) {
            throw new IllegalArgumentException("Giảm giá tay bắt buộc có lý do.");
        }
        List<?> items = data.get("items") instanceof List<?> ? (List<?>) data.get("items") : Collections.emptyList();
        if (items.isEmpty()) throw new IllegalArgumentException("Đơn hàng chưa có món.");

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                int orderId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO dbo.Orders (tableName,tableId,customerPhone,note,total,createdAt,customerId,orderType) VALUES (?,?,?,?,0,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, tableName);
                    if (orderTableId > 0) ps.setInt(2, orderTableId); else ps.setNull(2, java.sql.Types.INTEGER);
                    ps.setString(3, phone.isEmpty() ? null : phone);
                    ps.setString(4, note);
                    ps.setString(5, nowSqlTimestamp());
                    if (customerId > 0) ps.setInt(6, customerId); else ps.setNull(6, java.sql.Types.INTEGER);
                    ps.setString(7, orderType);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        orderId = keys.getInt(1);
                    }
                }

                int total = 0;
                int totalQuantity = 0;
                Map<String, Integer> variantQuantities = new LinkedHashMap<>();
                Map<Integer, Integer> requestedByMenu = new LinkedHashMap<>();
                Map<Integer, String> menuNames = new LinkedHashMap<>();
                List<Map<String, Object>> normalizedLines = new ArrayList<>();
                // Khoá toàn bộ Inventory trước khi tính khả dụng — tránh oversell đồng thời.
                Map<String, Integer> stockMap = getIngredientStockMapForUpdate(con);
                Map<String, Integer> reservedIngredients = getReservedIngredientQuantityMap(con);
                dao.RecipeDAO recipeDao = new dao.RecipeDAO();

                for (Object raw : items) {
                    if (!(raw instanceof Map<?, ?>)) continue;
                    Map<?, ?> item = (Map<?, ?>) raw;
                    int menuId = readInt(item.get("menuItemId"), 0);
                    int requestedQuantity = readInt(item.get("quantity"), 1);
                    if (requestedQuantity < 1) {
                        throw new IllegalArgumentException("Số lượng món phải lớn hơn 0.");
                    }
                    if (requestedQuantity > MAX_ITEM_QUANTITY) {
                        throw new IllegalArgumentException("Mỗi món chỉ được chọn tối đa " + MAX_ITEM_QUANTITY + " sản phẩm.");
                    }
                    int quantity = requestedQuantity;
                    Map<String, Object> menu = getMenuItem(menuId);
                    if (menu == null) {
                        throw new IllegalArgumentException("Món không tồn tại hoặc đã bị xoá.");
                    }
                    if (!readBoolean(menu.get("active"), false)) {
                        String itemName = readString(menu.get("nameVi"), "");
                        throw new IllegalArgumentException(itemName.isEmpty()
                                ? "Món hiện không còn phục vụ."
                                : ("Món \"" + itemName + "\" hiện không còn phục vụ."));
                    }
                    String size = normalizeSize(menu, readString(item.get("size"), ""));
                    String variantKey = menuId + "|" + size;
                    int variantTotal = variantQuantities.getOrDefault(variantKey, 0) + quantity;
                    if (variantTotal > MAX_ITEM_QUANTITY) {
                        throw new IllegalArgumentException("Mỗi món chỉ được chọn tối đa " + MAX_ITEM_QUANTITY + " sản phẩm.");
                    }
                    variantQuantities.put(variantKey, variantTotal);
                    requestedByMenu.put(menuId, requestedByMenu.getOrDefault(menuId, 0) + quantity);
                    menuNames.put(menuId, readString(menu.get("nameVi"), ""));
                    Map<String, Object> line = new LinkedHashMap<>();
                    line.put("menu", menu);
                    line.put("menuId", menuId);
                    line.put("size", size);
                    line.put("quantity", quantity);
                    line.put("price", priceForSize(menu, size));
                    normalizedLines.add(line);
                }

                // Cộng nhu cầu nguyên liệu của đơn này rồi so với tồn - đã đặt trước.
                Map<String, Integer> neededNow = new LinkedHashMap<>();
                for (Map.Entry<Integer, Integer> entry : requestedByMenu.entrySet()) {
                    int menuId = entry.getKey();
                    int requested = entry.getValue();
                    List<model.RecipeItem> recipes = recipeDao.getByMenuItemId(String.valueOf(menuId));
                    if (recipes.isEmpty()) continue;
                    for (model.RecipeItem recipe : recipes) {
                        int need = Math.max(0, recipe.getQuantity()) * requested;
                        if (need <= 0) continue;
                        neededNow.merge(recipe.getIngredientId(), need, Integer::sum);
                    }
                }
                for (Map.Entry<String, Integer> need : neededNow.entrySet()) {
                    int stock = stockMap.getOrDefault(need.getKey(), 0);
                    int reserved = reservedIngredients.getOrDefault(need.getKey(), 0);
                    int available = Math.max(0, stock - reserved);
                    if (need.getValue() > available) {
                        throw new IllegalArgumentException("Không đủ nguyên liệu trong kho để nhận đơn này (còn "
                                + available + ", cần " + need.getValue() + ").");
                    }
                }
                // Vẫn báo theo tên món nếu từng món hết suất (UX rõ hơn).
                Map<Integer, Integer> reservedMenuMap = getReservedMenuQuantityMap(con);
                for (Map.Entry<Integer, Integer> entry : requestedByMenu.entrySet()) {
                    int menuId = entry.getKey();
                    int requested = entry.getValue();
                    List<model.RecipeItem> recipes = recipeDao.getByMenuItemId(String.valueOf(menuId));
                    int available = availableQuantity(recipes, stockMap, reservedMenuMap.getOrDefault(menuId, 0));
                    if (!recipes.isEmpty() && requested > available) {
                        String itemName = menuNames.getOrDefault(menuId, "");
                        if (available <= 0) {
                            throw new IllegalArgumentException(itemName.isEmpty()
                                    ? "Món hiện không còn đủ hàng để phục vụ."
                                    : ("Món \"" + itemName + "\" hiện không còn đủ hàng để phục vụ."));
                        }
                        throw new IllegalArgumentException(itemName.isEmpty()
                                ? ("Chỉ còn " + available + " suất, không đủ số lượng đã chọn.")
                                : ("Món \"" + itemName + "\" chỉ còn " + available + " suất, không đủ số lượng đã chọn."));
                    }
                }

                for (Map<String, Object> line : normalizedLines) {
                    Map<String, Object> menu = (Map<String, Object>) line.get("menu");
                    int menuId = readInt(line.get("menuId"), 0);
                    String size = readString(line.get("size"), "");
                    int quantity = readInt(line.get("quantity"), 0);
                    int price = readInt(line.get("price"), 0);
                    total += price * quantity;
                    totalQuantity += quantity;
                    try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
                        ps.setInt(1, orderId);
                        ps.setInt(2, menuId);
                        ps.setString(3, readString(menu.get("nameVi"), ""));
                        ps.setString(4, size.isEmpty() ? null : size);
                        ps.setInt(5, quantity);
                        ps.setInt(6, price);
                        ps.executeUpdate();
                    }
                }
                if (totalQuantity == 0) throw new IllegalArgumentException("Đơn hàng chưa có món hợp lệ.");
                int orderNumber = 1000 + orderId;

                // ── Đổi điểm lấy giảm giá ───────────────────────────────────
                int subtotal = total;
                int redeemPoints = 0;
                int pointsDiscount = 0;
                if (customerId > 0 && requestedRedeem > 0) {
                    dao.CustomerDAO customerDao = new dao.CustomerDAO();
                    int balance = customerDao.currentPoints(con, customerId);
                    int held = pendingRedeemHold(con, customerId, 0);
                    int usable = Math.max(0, balance - held);
                    int maxAllowed = model.Customer.maxRedeemablePoints(usable, subtotal);
                    if (requestedRedeem > maxAllowed) {
                        if (maxAllowed <= 0) {
                            throw new IllegalArgumentException("Đơn này chưa đủ điều kiện dùng điểm (tối thiểu "
                                    + model.Customer.MIN_REDEEM_POINTS + " điểm và không quá "
                                    + model.Customer.MAX_REDEEM_PERCENT + "% giá trị đơn).");
                        }
                        throw new IllegalArgumentException("Đơn này chỉ dùng được tối đa " + maxAllowed + " điểm.");
                    }
                    redeemPoints = requestedRedeem;
                    pointsDiscount = redeemPoints * model.Customer.VALUE_PER_POINT;
                }

                int promotionId = 0;
                int promoDiscount = 0;
                if (!promoCode.isEmpty()) {
                    Map<String, Object> promo = lockPromotionByCode(con, promoCode);
                    promoDiscount = computePromoDiscount(promo, subtotal);
                    promotionId = readInt(promo.get("id"), 0);
                }

                int manualDiscount = Math.min(manualDiscountReq, Math.max(0, subtotal - pointsDiscount - promoDiscount));
                // Menu prices are VAT-inclusive: customer pays listed price (after discounts).
                // taxAmount is extracted for reporting only — never added on top.
                int payableBase = Math.max(0, subtotal - pointsDiscount - promoDiscount - manualDiscount);
                int vatPercent = stateValue(con, "vatPercent", 8);
                int servicePercent = stateValue(con, "serviceChargePercent", 0);
                int taxAmount = vatPercent > 0
                        ? (int) Math.round(payableBase * vatPercent / (100.0 + vatPercent))
                        : 0;
                int serviceCharge = (int) Math.round(payableBase * Math.max(0, servicePercent) / 100.0);
                total = payableBase + serviceCharge;

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE dbo.Orders SET orderNumber=?, subtotal=?, discountAmount=?, pointsRedeemed=?, "
                                + "promotionId=?, promoDiscount=?, manualDiscount=?, discountReason=?, "
                                + "taxAmount=?, serviceCharge=?, total=? WHERE id=?")) {
                    ps.setInt(1, orderNumber);
                    ps.setInt(2, subtotal);
                    ps.setInt(3, pointsDiscount);
                    ps.setInt(4, redeemPoints);
                    if (promotionId > 0) ps.setInt(5, promotionId); else ps.setNull(5, Types.INTEGER);
                    ps.setInt(6, promoDiscount);
                    ps.setInt(7, manualDiscount);
                    ps.setString(8, manualDiscount > 0 ? discountReason : null);
                    ps.setInt(9, taxAmount);
                    ps.setInt(10, serviceCharge);
                    ps.setInt(11, total);
                    ps.setInt(12, orderId);
                    ps.executeUpdate();
                }
                if (promotionId > 0) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO dbo.PromotionRedemptions (promotionId, orderId, discountAmount) VALUES (?,?,?)")) {
                        ps.setInt(1, promotionId);
                        ps.setInt(2, orderId);
                        ps.setInt(3, promoDiscount);
                        ps.executeUpdate();
                    }
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE dbo.Promotions SET usedCount = usedCount + 1 WHERE id=?")) {
                        ps.setInt(1, promotionId);
                        ps.executeUpdate();
                    }
                }
                String actor = normalizeActor(actorRole);
                if (actor.isEmpty() || "system".equals(actor)) actor = "guest";
                String actorDisplay = readString(actorName, "");
                if (actorDisplay.isEmpty()) actorDisplay = "guest".equals(actor) ? (phone.isEmpty() ? "Khách" : phone) : roleNameVi(actor);
                insertSystemLog(con, actor, actorDisplay, "ORDER_CREATE",
                        orderCreateLogVi(actor, tableName, orderNumber, totalQuantity),
                        orderCreateLogEn(actor, tableName, orderNumber, totalQuantity),
                        orderId);
                deactivateUnavailableMenuItems(con, requestedByMenu.keySet());
                con.commit();
                publishEvent("orders");
                return getOrderById(orderId);
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
    }

    private Map<String, Object> lockPromotionByCode(Connection con, String code) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id, code, discountType, discountValue, minSubtotal, maxDiscount, startAt, endAt, "
                        + "maxUses, usedCount, active FROM dbo.Promotions WITH (UPDLOCK, ROWLOCK) WHERE code=?")) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new IllegalArgumentException("Mã khuyến mãi không tồn tại.");
                Map<String, Object> promo = row(rs);
                if (!readBoolean(promo.get("active"), false)) {
                    throw new IllegalArgumentException("Mã khuyến mãi đã tắt.");
                }
                Timestamp startAt = rs.getTimestamp("startAt");
                Timestamp endAt = rs.getTimestamp("endAt");
                Timestamp now = Timestamp.valueOf(nowSqlTimestamp());
                if (startAt != null && now.before(startAt)) {
                    throw new IllegalArgumentException("Mã khuyến mãi chưa tới thời gian áp dụng.");
                }
                if (endAt != null && now.after(endAt)) {
                    throw new IllegalArgumentException("Mã khuyến mãi đã hết hạn.");
                }
                int maxUses = readInt(promo.get("maxUses"), 0);
                int usedCount = readInt(promo.get("usedCount"), 0);
                if (maxUses > 0 && usedCount >= maxUses) {
                    throw new IllegalArgumentException("Mã khuyến mãi đã hết lượt sử dụng.");
                }
                return promo;
            }
        }
    }

    private int computePromoDiscount(Map<String, Object> promo, int subtotal) {
        int minSubtotal = readInt(promo.get("minSubtotal"), 0);
        if (subtotal < minSubtotal) {
            throw new IllegalArgumentException("Đơn chưa đủ điều kiện tối thiểu để dùng mã khuyến mãi.");
        }
        String type = readString(promo.get("discountType"), "PERCENT").toUpperCase(Locale.ROOT);
        int value = Math.max(0, readInt(promo.get("discountValue"), 0));
        int discount;
        if ("AMOUNT".equals(type)) {
            discount = value;
        } else {
            discount = (int) Math.round(subtotal * value / 100.0);
        }
        int maxDiscount = readInt(promo.get("maxDiscount"), 0);
        if (maxDiscount > 0) discount = Math.min(discount, maxDiscount);
        return Math.min(Math.max(0, discount), subtotal);
    }

    public List<Map<String, Object>> getOrders() throws Exception {
        return getOrders("");
    }

    public List<Map<String, Object>> getOrders(String role) throws Exception {
        return getOrders(role, null);
    }

    public List<Map<String, Object>> getOrders(String role, List<Integer> cashierSessionPaidIds) throws Exception {
        String sql = "SELECT id, orderNumber, tableName, tableId, customerPhone, status, total, subtotal, discountAmount, pointsEarned, pointsRedeemed, customerId, note, createdAt, invoicePrinted, splitLocked, ISNULL(orderType,'DINE_IN') orderType, ISNULL(promoDiscount,0) promoDiscount, ISNULL(manualDiscount,0) manualDiscount, discountReason, ISNULL(taxAmount,0) taxAmount, ISNULL(serviceCharge,0) serviceCharge, ISNULL(tipAmount,0) tipAmount, cancelReason, cancelledAt, promotionId FROM dbo.Orders ";
        if ("barista".equals(role)) {
            sql += "WHERE status IN ('Pending','Preparing','Ready') ";
        } else if ("cashier".equals(role)) {
            String sessionPaid = paidIdList(cashierSessionPaidIds);
            sql += sessionPaid.isEmpty()
                    ? "WHERE status='Served' "
                    : "WHERE status='Served' OR id IN (" + sessionPaid + ") ";
        } else if ("runner".equals(role)) {
            sql += "WHERE status IN ('Ready','Served','Paid') ";
        }
        sql += "ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> list = rows(rs);
            for (Map<String, Object> order : list) {
                order.put("items", getOrderItems(readInt(order.get("id"), 0)));
            }
            if ("runner".equals(role)) sanitizeRunnerOrders(list);
            return list;
        }
    }

    private String paidIdList(List<Integer> ids) {
        if (ids == null || ids.isEmpty()) return "";
        StringJoiner joiner = new StringJoiner(",");
        Set<Integer> unique = new LinkedHashSet<>();
        for (Integer id : ids) {
            if (id != null && id > 0) unique.add(id);
        }
        for (Integer id : unique) joiner.add(String.valueOf(id));
        return joiner.toString();
    }

    @SuppressWarnings("unchecked")
    private void sanitizeRunnerOrders(List<Map<String, Object>> orders) {
        for (Map<String, Object> order : orders) {
            order.remove("total");
            order.remove("customerPhone");
            // Bồi bàn không nhìn thấy tiền: bỏ luôn các cột tiền mới thêm,
            // nếu không thì tiền hàng vẫn lộ qua subtotal.
            order.remove("subtotal");
            order.remove("discountAmount");
            order.remove("customerId");
            List<Map<String, Object>> items = (List<Map<String, Object>>) order.get("items");
            if (items == null) continue;
            for (Map<String, Object> item : items) {
                item.remove("price");
            }
        }
    }

    public Map<String, Object> getOrderByNumber(int orderNumber) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.Orders WHERE orderNumber=?")) {
            ps.setInt(1, orderNumber);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? getOrderById(rs.getInt("id")) : null;
            }
        }
    }

    public Map<String, Object> updateOrderStatus(int id, String status) throws Exception {
        return updateOrderStatus(id, status, "system", "system");
    }

    public Map<String, Object> updateOrderStatus(int id, String status, String actorRole, String actorName) throws Exception {
        return updateOrderStatus(id, status, actorRole, actorName, null);
    }

    /**
     * @param payment thông tin thanh toán, chỉ dùng khi status = "Paid".
     *                Khoá: method (CASH|TRANSFER), receivedAmount, cashierUsername, staffId, note.
     *                null = mặc định tiền mặt, khách đưa đúng số tiền.
     */
    public Map<String, Object> updateOrderStatus(int id, String status, String actorRole, String actorName,
                                                 Map<String, Object> payment) throws Exception {
        if (!Arrays.asList("Pending", "Preparing", "Ready", "Served", "Paid", "Cleared").contains(status)) {
            throw new IllegalArgumentException("Trạng thái đơn không hợp lệ.");
        }
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            String currentStatus = "";
            int total = 0;
            int orderNumber = 0;
            String tableName = "";
            String orderType = ORDER_TYPE_DINE_IN;
            int customerId = 0;
            int alreadyEarned = 0;
            int pointsRedeemed = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT status,total,orderNumber,tableName,ISNULL(orderType,'DINE_IN') orderType,"
                            + "customerId,pointsEarned,pointsRedeemed "
                            + "FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                    currentStatus = rs.getString("status");
                    total = rs.getInt("total");
                    orderNumber = rs.getInt("orderNumber");
                    tableName = rs.getString("tableName");
                    orderType = rs.getString("orderType");
                    customerId = rs.getInt("customerId");
                    alreadyEarned = rs.getInt("pointsEarned");
                    pointsRedeemed = rs.getInt("pointsRedeemed");
                }
            }
            if (!isAllowedStatusTransition(currentStatus, status)) {
                throw new IllegalArgumentException("Không thể chuyển từ \"" + currentStatus + "\" sang \"" + status + "\".");
            }
            if ("Preparing".equals(currentStatus) && "Ready".equals(status)) {
                int requiredCups = cupCountForOrder(con, id);
                int cups = stateValueForUpdate(con, "cupsAvailable", 0);
                if (requiredCups > cups) {
                    throw new IllegalArgumentException("Đơn này cần " + requiredCups + " cốc, hiện chỉ còn " + cups + " cốc.");
                }
                if (requiredCups > 0) {
                    setStateValue(con, "cupsAvailable", cups - requiredCups);
                }
                deductInventoryForOrder(con, id, actorRole, actorName);
                deactivateUnavailableMenuItems(con, null);
                markOrderItemsFullyPrepared(con, id);
            }
            // Optimistic: chỉ cập nhật nếu status vẫn đúng — chặn race hai thiết bị.
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status=? WHERE id=? AND status=?")) {
                ps.setString(1, status);
                ps.setInt(2, id);
                ps.setString(3, currentStatus);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Đơn vừa được cập nhật bởi thiết bị khác. Vui lòng tải lại.");
                }
            }

            // ── Ghi nhận thanh toán ─────────────────────────────────────────
            if ("Paid".equals(status) && !"Paid".equals(currentStatus)) {
                int tipAmount = Math.max(0, payment == null ? 0 : readInt(payment.get("tipAmount"), 0));
                if (tipAmount > 0 && stateValue(con, "tipEnabled", 1) <= 0) {
                    tipAmount = 0;
                }
                if (tipAmount > 0) {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET tipAmount=? WHERE id=?")) {
                        ps.setInt(1, tipAmount);
                        ps.setInt(2, id);
                        ps.executeUpdate();
                    }
                }
                recordPayment(con, id, orderNumber, total, tipAmount, payment, actorRole, actorName);

                // Trừ điểm đổi thưởng tại Paid (hoặc bỏ qua nếu đơn cũ đã trừ lúc tạo).
                if (customerId > 0 && pointsRedeemed > 0 && !hasPointTx(con, customerId, id, "REDEEM")) {
                    new dao.CustomerDAO().applyPointChange(con, customerId, -pointsRedeemed, "REDEEM", id,
                            "Đổi điểm giảm giá đơn #" + orderNumber, 0);
                }
            }

            // ── Tích điểm khi khách thực sự trả tiền ────────────────────────
            if ("Paid".equals(status) && !"Paid".equals(currentStatus) && customerId > 0 && alreadyEarned == 0) {
                int earned = model.Customer.pointsForSpend(total);
                dao.CustomerDAO customerDao = new dao.CustomerDAO();
                customerDao.applyPointChange(con, customerId, earned, "EARN", id,
                        "Tích điểm từ đơn #" + orderNumber, total);
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET pointsEarned=? WHERE id=?")) {
                    ps.setInt(1, earned);
                    ps.setInt(2, id);
                    ps.executeUpdate();
                }
            }

            // Mang đi: sau Paid chuyển thẳng Cleared (không cần bồi bàn dọn bàn).
            if ("Paid".equals(status) && ORDER_TYPE_TAKEAWAY.equals(orderType)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE dbo.Orders SET status='Cleared' WHERE id=? AND status='Paid'")) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
                status = "Cleared";
            }

            insertSystemLog(con, actorRole, actorName, "ORDER_STATUS",
                    statusLogVi(actorRole, currentStatus, status, orderNumber, tableName),
                    statusLogEn(actorRole, currentStatus, status, orderNumber, tableName),
                    id);
            con.commit();
            publishEvent("orders");
            return getOrderById(id);
        }
    }

    private boolean isAllowedStatusTransition(String from, String to) {
        if (from == null || to == null) return false;
        if (from.equals(to)) return false;
        switch (from) {
            case "Pending": return "Preparing".equals(to);
            case "Preparing": return "Ready".equals(to);
            case "Ready": return "Served".equals(to);
            case "Served": return "Paid".equals(to);
            case "Paid": return "Cleared".equals(to);
            default: return false;
        }
    }

    /** Phát sự kiện SSE tới mọi listener đang mở. */
    public void publishEvent(String eventType) {
        String payload = readString(eventType, "orders");
        List<java.util.function.Consumer<String>> snapshot;
        synchronized (eventListeners) {
            snapshot = new ArrayList<>(eventListeners);
        }
        for (java.util.function.Consumer<String> listener : snapshot) {
            try { listener.accept(payload); } catch (Exception ignored) {}
        }
    }

    public void addEventListener(java.util.function.Consumer<String> listener) {
        if (listener != null) eventListeners.add(listener);
    }

    public void removeEventListener(java.util.function.Consumer<String> listener) {
        eventListeners.remove(listener);
    }

    /**
     * Hoàn tác side-effect của đơn (kho / cốc / điểm / mã KM). Idempotent:
     * gọi lần hai không hoàn kho/cốc/điểm lần nữa nếu đã có bút toán đối ứng.
     */
    void reverseOrderSideEffects(Connection con, int orderId, boolean restock,
                                 String actorRole, String actorName) throws Exception {
        if (orderId <= 0) return;
        // ── Hoàn kho: chỉ khi đã có OUT và chưa có IN đối ứng ──
        if (restock) {
            boolean hasOut = false;
            boolean hasIn = false;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT type, COUNT(*) c FROM dbo.StockTransactions WHERE orderId=? AND type IN ('OUT','IN') GROUP BY type")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        if ("OUT".equals(rs.getString("type"))) hasOut = rs.getInt("c") > 0;
                        if ("IN".equals(rs.getString("type"))) hasIn = rs.getInt("c") > 0;
                    }
                }
            }
            if (hasOut && !hasIn) {
                Map<String, Integer> outs = new LinkedHashMap<>();
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT ingredientId, SUM(-quantity) qty FROM dbo.StockTransactions "
                                + "WHERE orderId=? AND type='OUT' GROUP BY ingredientId")) {
                    ps.setInt(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int qty = rs.getInt("qty");
                            if (qty > 0) outs.put(rs.getString("ingredientId"), qty);
                        }
                    }
                }
                for (Map.Entry<String, Integer> entry : outs.entrySet()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE dbo.Inventory SET stock = stock + ? WHERE id=?")) {
                        ps.setInt(1, entry.getValue());
                        ps.setString(2, entry.getKey());
                        ps.executeUpdate();
                    }
                    logStockChange(con, entry.getKey(), "IN", entry.getValue(), orderId, actorRole, actorName,
                            "Hoàn kho khi hủy/hoàn đơn #" + orderId);
                }
                reactivateAvailableMenuItems(con);
            }
        }

        // ── Hoàn cốc: chỉ nếu đã trừ lúc Ready và chưa hoàn ──
        boolean cupsAlreadyReversed = false;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.SystemLogs WHERE refId=? AND actionType='ORDER_CUPS_REVERSE'")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                cupsAlreadyReversed = rs.next() && rs.getInt(1) > 0;
            }
        }
        boolean wasReadyOrBeyond = false;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.StockTransactions WHERE orderId=? AND type='OUT'")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                wasReadyOrBeyond = rs.next() && rs.getInt(1) > 0;
            }
        }
        if (wasReadyOrBeyond && !cupsAlreadyReversed) {
            int cups = cupCountForOrder(con, orderId);
            if (cups > 0) {
                int current = stateValueForUpdate(con, "cupsAvailable", 0);
                setStateValue(con, "cupsAvailable", current + cups);
                insertSystemLog(con, actorRole, actorName, "ORDER_CUPS_REVERSE",
                        "Hoàn " + cups + " cốc cho đơn #" + orderId,
                        "Restored " + cups + " cups for order #" + orderId, orderId);
            }
        }

        // ── Hoàn điểm: đảo EARN/REDEEM nếu chưa đảo ──
        int customerId = 0;
        int orderNumber = 0;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT customerId, orderNumber FROM dbo.Orders WHERE id=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    customerId = rs.getInt("customerId");
                    orderNumber = rs.getInt("orderNumber");
                }
            }
        }
        if (customerId > 0) {
            dao.CustomerDAO customerDao = new dao.CustomerDAO();
            if (hasPointTx(con, customerId, orderId, "EARN") && !hasPointTx(con, customerId, orderId, "ADJUST")) {
                int earned = 0;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT TOP 1 points FROM dbo.PointTransactions WHERE customerId=? AND orderId=? AND type='EARN' ORDER BY id DESC")) {
                    ps.setInt(1, customerId);
                    ps.setInt(2, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) earned = rs.getInt(1);
                    }
                }
                if (earned > 0) {
                    customerDao.applyPointChange(con, customerId, -earned, "ADJUST", orderId,
                            "Thu hồi điểm đơn #" + orderNumber + " (hủy/hoàn)", 0);
                }
            }
            if (hasPointTx(con, customerId, orderId, "REDEEM") && !hasPointTxNote(con, customerId, orderId, "Hoàn điểm")) {
                int redeemed = 0;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT TOP 1 ABS(points) FROM dbo.PointTransactions WHERE customerId=? AND orderId=? AND type='REDEEM' ORDER BY id DESC")) {
                    ps.setInt(1, customerId);
                    ps.setInt(2, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) redeemed = rs.getInt(1);
                    }
                }
                if (redeemed > 0) {
                    customerDao.applyPointChange(con, customerId, redeemed, "ADJUST", orderId,
                            "Hoàn điểm đơn #" + orderNumber + " (hủy/hoàn)", 0);
                }
            }
        }

        // ── Hoàn lượt khuyến mãi ──
        releasePromotionForOrder(con, orderId);
    }

    private boolean hasPointTxNote(Connection con, int customerId, int orderId, String notePrefix) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.PointTransactions WHERE customerId=? AND orderId=? AND type='ADJUST' AND note LIKE ?")) {
            ps.setInt(1, customerId);
            ps.setInt(2, orderId);
            ps.setString(3, notePrefix + "%");
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private void reactivateAvailableMenuItems(Connection con) throws Exception {
        Map<String, Integer> stockMap = getIngredientStockMap(con);
        Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);
        dao.RecipeDAO recipeDao = new dao.RecipeDAO();
        java.util.Map<String, java.util.List<model.RecipeItem>> allRecipes = recipeDao.getAllRecipesMappedByMenuItemId();
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.MenuItems WHERE active=0");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int menuId = rs.getInt("id");
                List<model.RecipeItem> recipes = allRecipes.getOrDefault(String.valueOf(menuId), new ArrayList<>());
                if (recipes.isEmpty()) continue;
                int available = availableQuantity(recipes, stockMap, reservedMap.getOrDefault(menuId, 0));
                if (available <= 0) continue;
                try (PreparedStatement up = con.prepareStatement("UPDATE dbo.MenuItems SET active=1 WHERE id=? AND active=0")) {
                    up.setInt(1, menuId);
                    up.executeUpdate();
                }
            }
        }
    }

    private void releasePromotionForOrder(Connection con, int orderId) throws Exception {
        int promotionId = 0;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT promotionId FROM dbo.PromotionRedemptions WHERE orderId=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) promotionId = rs.getInt(1);
            }
        }
        if (promotionId <= 0) return;
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.PromotionRedemptions WHERE orderId=?")) {
            ps.setInt(1, orderId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Promotions SET usedCount = CASE WHEN usedCount > 0 THEN usedCount - 1 ELSE 0 END WHERE id=?")) {
            ps.setInt(1, promotionId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Orders SET promotionId=NULL WHERE id=? AND promotionId=?")) {
            ps.setInt(1, orderId);
            ps.setInt(2, promotionId);
            ps.executeUpdate();
        }
    }

    /**
     * Hủy đơn. Khách chỉ Pending; barista/cashier/runner: Pending+Preparing;
     * admin tới Served. Không hủy Paid/Cleared (dùng refund).
     */
    public Map<String, Object> cancelOrder(int id, String reason, String actorRole, String actorName) throws Exception {
        String cleanReason = limitNote(readString(reason, "").trim());
        if (cleanReason.isEmpty()) throw new IllegalArgumentException("Vui lòng nhập lý do hủy đơn.");
        String role = normalizeActor(actorRole);
        if (role.isEmpty()) role = "guest";
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            String status;
            int orderNumber;
            String tableName;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT status, orderNumber, tableName FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                    status = rs.getString("status");
                    orderNumber = rs.getInt("orderNumber");
                    tableName = rs.getString("tableName");
                }
            }
            if (!canCancelStatus(role, status)) {
                throw new IllegalArgumentException("Không được hủy đơn ở trạng thái \"" + status + "\".");
            }
            reverseOrderSideEffects(con, id, true, role, actorName);
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Orders SET status='Cancelled', cancelReason=?, cancelledAt=?, "
                            + "cancelledByRole=?, cancelledByName=? WHERE id=? AND status=?")) {
                ps.setString(1, cleanReason);
                ps.setString(2, nowSqlTimestamp());
                ps.setString(3, role);
                ps.setString(4, readString(actorName, role));
                ps.setInt(5, id);
                ps.setString(6, status);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Đơn vừa được cập nhật bởi thiết bị khác. Vui lòng tải lại.");
                }
            }
            insertSystemLog(con, role, actorName, "ORDER_CANCEL",
                    "Hủy đơn #" + orderNumber + " (" + tableName + "): " + cleanReason,
                    "Cancelled order #" + orderNumber + " (" + tableName + "): " + cleanReason, id);
            con.commit();
            publishEvent("orders");
            return getOrderById(id);
        }
    }

    private boolean canCancelStatus(String role, String status) {
        if ("Cancelled".equals(status) || "Refunded".equals(status) || "Paid".equals(status) || "Cleared".equals(status)) {
            return false;
        }
        if ("guest".equals(role) || role.isEmpty()) return "Pending".equals(status);
        if ("admin".equals(role)) {
            return "Pending".equals(status) || "Preparing".equals(status)
                    || "Ready".equals(status) || "Served".equals(status);
        }
        if ("barista".equals(role) || "runner".equals(role)) {
            return "Pending".equals(status) || "Preparing".equals(status);
        }
        if ("cashier".equals(role)) {
            return "Pending".equals(status) || "Preparing".equals(status)
                    || "Ready".equals(status) || "Served".equals(status);
        }
        return false;
    }

    /**
     * Hoàn tiền / void. Chỉ admin (hoặc cashier đã xác thực PIN admin ở tầng servlet).
     * Chỉ từ Paid hoặc Cleared. restock=true → hoàn kho.
     */
    public Map<String, Object> refundOrder(int orderId, String reason, boolean restock,
                                           String actorRole, String actorName) throws Exception {
        String cleanReason = limitNote(readString(reason, "").trim());
        if (cleanReason.isEmpty()) throw new IllegalArgumentException("Vui lòng nhập lý do hoàn tiền.");
        String role = normalizeActor(actorRole);
        if (!"admin".equals(role) && !"cashier".equals(role)) {
            throw new IllegalArgumentException("Chỉ quản trị hoặc thu ngân được hoàn tiền.");
        }
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            String status;
            int orderNumber;
            int total;
            int tipAmount;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT status, orderNumber, total, ISNULL(tipAmount,0) tipAmount "
                            + "FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                    status = rs.getString("status");
                    orderNumber = rs.getInt("orderNumber");
                    total = rs.getInt("total");
                    tipAmount = rs.getInt("tipAmount");
                }
            }
            if (!"Paid".equals(status) && !"Cleared".equals(status)) {
                throw new IllegalArgumentException("Chỉ hoàn tiền đơn đã thanh toán (Paid/Cleared).");
            }
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Refunds WHERE orderId=?")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("Đơn này đã được hoàn tiền.");
                    }
                }
            }
            int paymentId = 0;
            String method = "CASH";
            int payAmount = total;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT TOP 1 id, method, amount FROM dbo.Payments WHERE orderId=? ORDER BY id DESC")) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        paymentId = rs.getInt("id");
                        method = rs.getString("method");
                        payAmount = rs.getInt("amount");
                    }
                }
            }
            int refundAmount = payAmount + tipAmount;
            int staffId = actorStaffId();
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO dbo.Refunds (orderId,paymentId,amount,method,reason,restocked,actorRole,actorName,staffId) "
                            + "VALUES (?,?,?,?,?,?,?,?,?)")) {
                ps.setInt(1, orderId);
                if (paymentId > 0) ps.setInt(2, paymentId); else ps.setNull(2, Types.INTEGER);
                ps.setInt(3, refundAmount);
                ps.setString(4, method);
                ps.setString(5, cleanReason);
                ps.setBoolean(6, restock);
                ps.setString(7, role);
                ps.setString(8, readString(actorName, role));
                if (staffId > 0) ps.setInt(9, staffId); else ps.setNull(9, Types.INTEGER);
                ps.executeUpdate();
            }
            if ("CASH".equals(method) && refundAmount > 0) {
                int balance = currentCashBalance(con) - refundAmount;
                insertCashEvent(con, "REFUND", -refundAmount, balance,
                        "Hoàn tiền đơn #" + orderNumber + ": " + cleanReason,
                        role, actorName, true, orderId, paymentId, staffId);
            }
            reverseOrderSideEffects(con, orderId, restock, role, actorName);
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Orders SET status='Refunded', cancelReason=?, cancelledAt=?, "
                            + "cancelledByRole=?, cancelledByName=? WHERE id=? AND status=?")) {
                ps.setString(1, cleanReason);
                ps.setString(2, nowSqlTimestamp());
                ps.setString(3, role);
                ps.setString(4, readString(actorName, role));
                ps.setInt(5, orderId);
                ps.setString(6, status);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Đơn vừa được cập nhật bởi thiết bị khác. Vui lòng tải lại.");
                }
            }
            insertSystemLog(con, role, actorName, "ORDER_REFUND",
                    "Hoàn tiền đơn #" + orderNumber + " (" + refundAmount + "đ): " + cleanReason,
                    "Refunded order #" + orderNumber + " (" + refundAmount + " VND): " + cleanReason, orderId);
            con.commit();
            publishEvent("orders");
            return getOrderById(orderId);
        }
    }

    private boolean hasPointTx(Connection con, int customerId, int orderId, String type) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.PointTransactions WHERE customerId=? AND orderId=? AND type=?")) {
            ps.setInt(1, customerId);
            ps.setInt(2, orderId);
            ps.setString(3, type);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /** Điểm đang treo trên đơn chưa Paid (chưa có giao dịch REDEEM thật). */
    private int pendingRedeemHold(Connection con, int customerId, int excludeOrderId) throws Exception {
        if (customerId <= 0) return 0;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT ISNULL(SUM(o.pointsRedeemed),0) FROM dbo.Orders o "
                        + "WHERE o.customerId=? AND o.pointsRedeemed > 0 "
                        + "AND o.status IN " + ST_PRE_PAID + " "
                        + "AND o.id <> ? "
                        + "AND NOT EXISTS (SELECT 1 FROM dbo.PointTransactions pt "
                        + "  WHERE pt.orderId = o.id AND pt.type = 'REDEEM')")) {
            ps.setInt(1, customerId);
            ps.setInt(2, excludeOrderId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    /**
     * Tạo bản ghi thanh toán cho một đơn, trong cùng transaction với việc
     * đổi trạng thái. Nếu trả bằng tiền mặt thì đồng thời đẩy một sự kiện
     * PAYMENT vào sổ quỹ — trước đây quỹ chỉ đổi khi thu ngân kiểm đếm tay,
     * nên tiền bán hàng không bao giờ tự vào sổ và không thể đối soát ca.
     *
     * UNIQUE(orderId) ở tầng CSDL là thứ thật sự chặn thu tiền hai lần;
     * kiểm tra dưới đây chỉ để trả về thông báo dễ hiểu.
     */
    private void recordPayment(Connection con, int orderId, int orderNumber, int amount, int tipAmount,
                               Map<String, Object> payment, String actorRole, String actorName) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Payments WHERE orderId=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return;   // đã thu rồi, không thu lại
            }
        }

        Map<String, Object> info = payment == null ? new LinkedHashMap<String, Object>() : payment;
        String method = readString(info.get("method"), "CASH").toUpperCase(Locale.ROOT).trim();
        if (!"CASH".equals(method) && !"TRANSFER".equals(method)) {
            throw new IllegalArgumentException("Hình thức thanh toán không hợp lệ. Chỉ chấp nhận CASH hoặc TRANSFER.");
        }

        int due = amount + Math.max(0, tipAmount);
        int received = readInt(info.get("receivedAmount"), 0);
        if ("CASH".equals(method)) {
            if (received < due) {
                throw new IllegalArgumentException("Số tiền khách đưa (" + received + ") nhỏ hơn số phải thu (" + due + ").");
            }
        } else {
            // Chuyển khoản: mặc định nhận đúng số, không nhận âm.
            if (received <= 0) received = due;
            if (received < due) {
                throw new IllegalArgumentException("Số tiền chuyển khoản chưa đủ số phải thu.");
            }
        }
        int change = Math.max(0, received - due);
        int staffId = readInt(info.get("staffId"), 0);
        if (staffId <= 0) staffId = actorStaffId();
        String cashierUser = readString(info.get("cashierUsername"), "");
        if (cashierUser.isEmpty()) cashierUser = readString(actorRole, "");
        String cashierName = readString(info.get("cashierName"), readString(actorName, ""));
        if (cashierName.isEmpty()) cashierName = cashierUser;

        int paymentId;
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO dbo.Payments (orderId,method,amount,receivedAmount,changeAmount,cashierUsername,cashierName,staffId,note) "
                        + "VALUES (?,?,?,?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, orderId);
            ps.setString(2, method);
            ps.setInt(3, amount);
            ps.setInt(4, received);
            ps.setInt(5, change);
            if (cashierUser.isEmpty()) ps.setNull(6, java.sql.Types.VARCHAR); else ps.setString(6, cashierUser);
            ps.setString(7, cashierName);
            if (staffId > 0) ps.setInt(8, staffId); else ps.setNull(8, java.sql.Types.INTEGER);
            String payNote = limitNote(readString(info.get("note"), ""));
            if (tipAmount > 0) {
                payNote = (payNote.isEmpty() ? "" : payNote + " | ") + "Tip " + tipAmount;
            }
            ps.setString(9, payNote);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                paymentId = keys.next() ? keys.getInt(1) : 0;
            }
        }

        // Chuyển khoản không làm tăng tiền mặt trong ngăn kéo. Tip tiền mặt vào quỹ.
        if ("CASH".equals(method) && due > 0) {
            int balance = currentCashBalance(con) + due;
            insertCashEvent(con, "PAYMENT", due, balance,
                    "Thu tiền đơn #" + orderNumber + (tipAmount > 0 ? (" (gồm tip " + tipAmount + ")") : ""),
                    actorRole, cashierName, true,
                    orderId, paymentId, staffId);
        }

        insertSystemLog(con, actorRole, cashierName, "ORDER_PAYMENT",
                "Thu " + amount + "đ đơn #" + orderNumber + " bằng "
                        + ("CASH".equals(method) ? "tiền mặt" : "chuyển khoản") + " lúc " + nowLabelVi(),
                "Collected " + amount + " VND for order #" + orderNumber + " by "
                        + ("CASH".equals(method) ? "cash" : "bank transfer") + " at " + nowLabelEn(),
                orderId);
    }

    /** Hoá đơn thanh toán của một đơn, null nếu chưa thu tiền. */
    public Map<String, Object> getPaymentByOrder(int orderId) throws Exception {
        String sql = "SELECT id, orderId, method, amount, receivedAmount, changeAmount, "
                + "cashierUsername, cashierName, staffId, note, paidAt FROM dbo.Payments WHERE orderId=?";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    /**
     * Đối soát ca: tiền đã thu, tách theo hình thức thanh toán.
     * Câu này trước đây không viết được vì không có bảng nào ghi lại việc thu tiền.
     */
    public Map<String, Object> getPaymentSummary(String fromDate, String toDate) throws Exception {
        String from = readString(fromDate, appToday().toString());
        String to = readString(toDate, appToday().toString());
        String sql = "SELECT p.method, COUNT(*) AS soDon, SUM(p.amount) AS tongTien "
                + "FROM dbo.Payments p "
                + "WHERE CAST(p.paidAt AS DATE) BETWEEN ? AND ? GROUP BY p.method";
        Map<String, Object> result = new LinkedHashMap<>();
        List<Map<String, Object>> lines = new ArrayList<>();
        int total = 0;
        int cash = 0;
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, from);
            ps.setString(2, to);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> line = new LinkedHashMap<>();
                    String method = rs.getString("method");
                    int sum = rs.getInt("tongTien");
                    line.put("method", method);
                    line.put("orderCount", rs.getInt("soDon"));
                    line.put("amount", sum);
                    lines.add(line);
                    total += sum;
                    if ("CASH".equals(method)) cash = sum;
                }
            }
        }
        result.put("fromDate", from);
        result.put("toDate", to);
        result.put("lines", lines);
        result.put("totalAmount", total);
        result.put("cashAmount", cash);
        result.put("transferAmount", total - cash);
        return result;
    }

    /**
     * Doanh thu theo TẦNG. Đây là câu truy vấn mà thiết kế cũ không thể viết:
     * Orders chỉ có tên bàn dạng chuỗi nên không JOIN được sang Tables.floorNo.
     */
    public List<Map<String, Object>> getRevenueByFloor(String fromDate, String toDate) throws Exception {
        String from = readString(fromDate, appToday().toString());
        String to = readString(toDate, appToday().toString());
        String sql = "SELECT t.floorNo, COUNT(DISTINCT o.id) AS soDon, ISNULL(SUM(o.total),0) AS doanhThu "
                + "FROM dbo.Orders o JOIN dbo.Tables t ON t.id = o.tableId "
                + "WHERE o.status IN " + ST_REVENUE + " "
                + "AND CAST(ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=o.id), o.createdAt) AS DATE) BETWEEN ? AND ? "
                + "GROUP BY t.floorNo ORDER BY t.floorNo";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, from);
            ps.setString(2, to);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    private void deductInventoryForOrder(Connection con, int orderId) throws Exception {
        deductInventoryForOrder(con, orderId, "system", "system");
    }

    private void deductInventoryForOrder(Connection con, int orderId, String actorRole, String actorName) throws Exception {
        Map<String, Integer> deductions = new LinkedHashMap<>();
        // menuItemId đã là INT — JOIN trực tiếp, không CONVERT VARCHAR.
        String sql = "SELECT ri.ingredientId, SUM(ri.quantity * oi.quantity) usedQuantity "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.RecipeItems ri ON ri.menuItemId = oi.menuItemId "
                + "WHERE oi.orderId=? "
                + "GROUP BY ri.ingredientId";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    deductions.put(rs.getString("ingredientId"), Math.max(0, rs.getInt("usedQuantity")));
                }
            }
        }
        for (Map.Entry<String, Integer> entry : deductions.entrySet()) {
            int amount = entry.getValue();
            if (amount <= 0) continue;
            int stockBefore = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT stock FROM dbo.Inventory WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
                ps.setString(1, entry.getKey());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Thiếu nguyên liệu trong kho: " + entry.getKey());
                    }
                    stockBefore = rs.getInt("stock");
                }
            }
            if (stockBefore < amount) {
                throw new IllegalArgumentException("Không đủ tồn kho để xuất cho đơn (cần " + amount
                        + ", còn " + stockBefore + ").");
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Inventory SET stock = stock - ? WHERE id=? AND stock >= ?")) {
                ps.setInt(1, amount);
                ps.setString(2, entry.getKey());
                ps.setInt(3, amount);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Kho vừa bị cập nhật bởi thiết bị khác. Thử lại.");
                }
            }
            logStockChange(con, entry.getKey(), "OUT", -amount, orderId, actorRole, actorName,
                    "Xuất kho cho đơn #" + orderId);
        }
    }

    /**
     * Ghi một dòng vào sổ cái kho. stockAfter đọc lại từ Inventory SAU khi đã
     * cập nhật, nên sổ luôn phản ánh đúng tồn thực tế chứ không phải số tính tay.
     *
     * Bất biến cần giữ: SUM(StockTransactions.quantity) của một nguyên liệu
     * luôn bằng Inventory.stock. Lệch = có người sửa thẳng CSDL.
     */
    void logStockChange(Connection con, String ingredientId, String type, int quantity,
                        int orderId, String actorRole, String actorName, String note) throws Exception {
        if (readString(ingredientId, "").isEmpty()) return;
        int stockAfter = 0;
        int unitCost = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT stock, importCost FROM dbo.Inventory WHERE id=?")) {
            ps.setString(1, ingredientId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return;              // nguyên liệu đã bị xoá, không ghi sổ mồ côi
                stockAfter = rs.getInt("stock");
                unitCost = rs.getInt("importCost");
            }
        }
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO dbo.StockTransactions (ingredientId,type,quantity,stockAfter,unitCost,orderId,actorRole,actorName,note) "
                        + "VALUES (?,?,?,?,?,?,?,?,?)")) {
            ps.setString(1, ingredientId);
            ps.setString(2, type);
            ps.setInt(3, quantity);
            ps.setInt(4, stockAfter);
            ps.setInt(5, unitCost);
            if (orderId > 0) ps.setInt(6, orderId); else ps.setNull(6, java.sql.Types.INTEGER);
            ps.setString(7, readString(actorRole, "system"));
            ps.setString(8, readString(actorName, "system"));
            ps.setString(9, limitNote(note));
            ps.executeUpdate();
        }
    }

    /** Ghi sổ kho từ ngoài transaction (dùng cho luồng nhập/sửa kho của admin). */
    public void logStockChange(String ingredientId, String type, int quantity,
                               String actorRole, String actorName, String note) throws Exception {
        try (Connection con = db.getConnection()) {
            logStockChange(con, ingredientId, type, quantity, 0, actorRole, actorName, note);
        }
    }

    /** Sổ cái kho của một nguyên liệu, mới nhất trước. */
    public List<Map<String, Object>> getStockLedger(String ingredientId, int limit) throws Exception {
        int take = limit <= 0 || limit > 500 ? 100 : limit;
        String where = readString(ingredientId, "").isEmpty() ? "" : "WHERE s.ingredientId = ? ";
        String sql = "SELECT TOP " + take + " s.id, s.ingredientId, i.name AS ingredientName, i.unit, "
                + "s.type, s.quantity, s.stockAfter, s.unitCost, s.orderId, s.actorRole, s.actorName, s.note, s.createdAt "
                + "FROM dbo.StockTransactions s JOIN dbo.Inventory i ON i.id = s.ingredientId "
                + where + "ORDER BY s.id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            if (!where.isEmpty()) ps.setString(1, ingredientId);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    /**
     * Đối soát kho: trả về những nguyên liệu có tồn KHÔNG khớp sổ cái.
     * Danh sách rỗng là kết quả mong muốn.
     */
    public List<Map<String, Object>> getStockAudit() throws Exception {
        String sql = "SELECT i.id, i.name, i.unit, i.stock AS currentStock, "
                + "ISNULL(SUM(s.quantity),0) AS ledgerTotal, "
                + "i.stock - ISNULL(SUM(s.quantity),0) AS difference "
                + "FROM dbo.Inventory i LEFT JOIN dbo.StockTransactions s ON s.ingredientId = i.id "
                + "GROUP BY i.id, i.name, i.unit, i.stock "
                + "HAVING i.stock <> ISNULL(SUM(s.quantity),0) ORDER BY i.name";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    /**
     * Giá vốn hàng bán trong khoảng ngày, tính từ sổ cái kho.
     * Không có sổ cái thì con số này không tồn tại — dashboard chỉ có doanh thu gộp.
     */
    public Map<String, Object> getCostOfGoodsSold(String fromDate, String toDate) throws Exception {
        String from = readString(fromDate, appToday().toString());
        String to = readString(toDate, appToday().toString());
        String sql = "SELECT ISNULL(SUM(ABS(s.quantity) * s.unitCost),0) AS cogs "
                + "FROM dbo.StockTransactions s "
                + "WHERE s.type='OUT' AND CAST(s.createdAt AS DATE) BETWEEN ? AND ?";
        int cogs = 0;
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, from);
            ps.setString(2, to);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) cogs = rs.getInt("cogs");
            }
        }
        Map<String, Object> revenueRow = getPaymentSummary(from, to);
        int revenue = readInt(revenueRow.get("totalAmount"), 0);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("fromDate", from);
        result.put("toDate", to);
        result.put("revenue", revenue);
        result.put("cogs", cogs);
        result.put("grossProfit", revenue - cogs);
        return result;
    }

    public List<Map<String, Object>> getLowStockIngredients() throws Exception {
        try (Connection con = db.getConnection()) {
            return getLowStockIngredients(con);
        }
    }

    public int refreshMenuAvailability() throws Exception {
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                int disabled = deactivateUnavailableMenuItems(con, null);
                con.commit();
                return disabled;
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
    }

    private List<Map<String, Object>> getLowStockIngredients(Connection con) throws Exception {
        String sql = "SELECT id, name, unit, stock, minStock, importCost FROM dbo.Inventory "
                + "WHERE stock <= minStock ORDER BY stock ASC, name ASC";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    private Map<String, Integer> getIngredientStockMap(Connection con) throws Exception {
        Map<String, Integer> stock = new LinkedHashMap<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT id, stock FROM dbo.Inventory");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                stock.put(rs.getString("id"), Math.max(0, rs.getInt("stock")));
            }
        }
        return stock;
    }

    /** Khoá hàng Inventory trong transaction đặt đơn — chống oversell đồng thời. */
    private Map<String, Integer> getIngredientStockMapForUpdate(Connection con) throws Exception {
        Map<String, Integer> stock = new LinkedHashMap<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id, stock FROM dbo.Inventory WITH (UPDLOCK, HOLDLOCK) ORDER BY id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                stock.put(rs.getString("id"), Math.max(0, rs.getInt("stock")));
            }
        }
        return stock;
    }

    /** Nguyên liệu đã được “giữ” bởi đơn Pending/Preparing (công thức × số lượng). */
    private Map<String, Integer> getReservedIngredientQuantityMap(Connection con) throws Exception {
        Map<String, Integer> reserved = new LinkedHashMap<>();
        String sql = "SELECT ri.ingredientId, SUM(ri.quantity * oi.quantity) qty "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.Orders o ON o.id = oi.orderId "
                + "JOIN dbo.RecipeItems ri ON ri.menuItemId = oi.menuItemId "
                + "WHERE o.status IN " + ST_RESERVING + " "
                + "GROUP BY ri.ingredientId";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                reserved.put(rs.getString("ingredientId"), Math.max(0, rs.getInt("qty")));
            }
        }
        return reserved;
    }

    private Map<Integer, Integer> getReservedMenuQuantityMap(Connection con) throws Exception {
        Map<Integer, Integer> reserved = new LinkedHashMap<>();
        String sql = "SELECT oi.menuItemId, SUM(oi.quantity) quantity "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.Orders o ON o.id = oi.orderId "
                + "WHERE o.status IN " + ST_RESERVING + " AND oi.menuItemId IS NOT NULL AND oi.menuItemId > 0 "
                + "GROUP BY oi.menuItemId";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                reserved.put(rs.getInt("menuItemId"), Math.max(0, rs.getInt("quantity")));
            }
        }
        return reserved;
    }

    private int availableQuantity(List<model.RecipeItem> recipes, Map<String, Integer> stockMap, int reservedServings) {
        if (recipes == null || recipes.isEmpty()) return MAX_ITEM_QUANTITY;
        int maxByStock = Integer.MAX_VALUE;
        boolean hasRequirement = false;
        for (model.RecipeItem recipe : recipes) {
            int need = Math.max(0, recipe.getQuantity());
            if (need <= 0) continue;
            hasRequirement = true;
            int stock = stockMap.getOrDefault(recipe.getIngredientId(), 0);
            maxByStock = Math.min(maxByStock, stock / need);
        }
        if (!hasRequirement) return MAX_ITEM_QUANTITY;
        return Math.max(0, Math.min(MAX_ITEM_QUANTITY, maxByStock - Math.max(0, reservedServings)));
    }

    private int deactivateUnavailableMenuItems(Connection con, Collection<Integer> menuItemIds) throws Exception {
        Map<String, Integer> stockMap = getIngredientStockMap(con);
        Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);
        dao.RecipeDAO recipeDao = new dao.RecipeDAO();
        java.util.Map<String, java.util.List<model.RecipeItem>> allRecipes = recipeDao.getAllRecipesMappedByMenuItemId();
        List<Integer> candidates = new ArrayList<>();
        if (menuItemIds == null) {
            try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.MenuItems WHERE active=1");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) candidates.add(rs.getInt("id"));
            }
        } else {
            for (Integer id : menuItemIds) {
                if (id != null && id > 0) candidates.add(id);
            }
        }
        int disabled = 0;
        for (Integer menuId : candidates) {
            List<model.RecipeItem> recipes = allRecipes.getOrDefault(String.valueOf(menuId), new ArrayList<>());
            if (recipes.isEmpty()) continue;
            int available = availableQuantity(recipes, stockMap, reservedMap.getOrDefault(menuId, 0));
            if (available > 0) continue;
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.MenuItems SET active=0 WHERE id=? AND active=1")) {
                ps.setInt(1, menuId);
                disabled += ps.executeUpdate();
            }
        }
        return disabled;
    }

    private String nowSqlTimestamp() {
        return java.time.LocalDateTime.now(APP_ZONE).format(SQL_TIMESTAMP_FORMAT);
    }

    private LocalDate appToday() {
        return LocalDate.now(APP_ZONE);
    }

    private java.time.LocalTime appNowTime() {
        return java.time.LocalTime.now(APP_ZONE);
    }

    /**
     * Khung giờ của ca, đọc từ chuỗi "HH:mm - HH:mm" trong Shifts.hours.
     *
     * Trả về {phút bắt đầu, phút kết thúc} tính từ nửa đêm. Ca qua đêm
     * (22:00 - 02:00) có phút kết thúc lớn hơn 1440 để phép so sánh vẫn là
     * một đoạn liền mạch. null = chuỗi giờ không đọc được.
     */
    private int[] parseShiftWindow(String hours) {
        java.util.regex.Matcher m = SHIFT_HOURS_PATTERN.matcher(readString(hours, ""));
        if (!m.find()) return null;
        int start = Integer.parseInt(m.group(1)) * 60 + Integer.parseInt(m.group(2));
        int end = Integer.parseInt(m.group(3)) * 60 + Integer.parseInt(m.group(4));
        if (end <= start) end += 24 * 60;
        return new int[]{start, end};
    }

    /**
     * Ca này có đang diễn ra tại thời điểm {@code now} không.
     *
     * Đây là thứ trước đây bị thiếu: hệ thống chỉ so ngày, nên người của ca
     * tối vẫn đăng nhập được lúc 8 giờ sáng và cầm luôn quyền của ca đó.
     *
     * Chuỗi giờ hỏng thì coi như ca kéo dài cả ngày — dữ liệu bẩn không nên
     * khoá chết người đang đứng ở quầy.
     */
    private boolean isShiftActiveNow(String hours, java.time.LocalTime now) {
        return isShiftActiveNow(hours, now, SHIFT_GRACE_MINUTES);
    }

    private boolean isShiftActiveNow(String hours, java.time.LocalTime now, int graceMinutes) {
        int[] window = parseShiftWindow(hours);
        if (window == null) return true;
        int from = window[0] - graceMinutes;
        int to = window[1] + graceMinutes;
        int nowMinutes = now.getHour() * 60 + now.getMinute();
        // Nửa khoảng [from, to): đúng 12:00 là ca chiều, không phải đuôi ca sáng.
        // Kiểm tra thêm nowMinutes + 24h để bắt được ca qua đêm: 00:30 nằm
        // trong ca 22:00 - 02:00 của NGÀY HÔM TRƯỚC lẫn khung đã cộng dồn.
        return (nowMinutes >= from && nowMinutes < to)
                || (nowMinutes + 24 * 60 >= from && nowMinutes + 24 * 60 < to);
    }

    /**
     * Trong các ca của một ngày, ca đang thực sự diễn ra tại {@code now}.
     *
     * Xét khung giờ chính trước, hết mới xét tới khoảng nới: lúc giao ca 12:00
     * cả ca sáng lẫn ca chiều đều nằm trong khoảng nới của nhau, chọn nhầm là
     * trao quyền của ca vừa tan.
     */
    private Map<String, Object> pickActiveShift(List<Map<String, Object>> shifts, java.time.LocalTime now) {
        for (Map<String, Object> shift : shifts) {
            if (isShiftActiveNow(readString(shift.get("hours"), ""), now, 0)) return shift;
        }
        for (Map<String, Object> shift : shifts) {
            if (isShiftActiveNow(readString(shift.get("hours"), ""), now)) return shift;
        }
        return null;
    }

    /** Nhãn "Ca Tối · 18:00 - 23:00" để báo cho người đăng nhập nhầm giờ. */
    private String shiftLabel(Map<String, Object> shift) {
        if (shift == null) return "";
        String name = readString(shift.get("shiftName"), "");
        String hours = readString(shift.get("hours"), "");
        if (name.isEmpty()) return hours;
        return hours.isEmpty() ? name : name + " " + hours;
    }

    public Map<String, Object> splitOrder(int sourceOrderId, List<Map<String, Object>> selections, String actorRole, String actorName) throws Exception {
        if (selections == null || selections.isEmpty()) {
            throw new IllegalArgumentException("Chưa chọn món nào để tách.");
        }
        // Gộp số lượng theo orderItemId để tránh trùng dòng trong lựa chọn.
        Map<Integer, Integer> wanted = new LinkedHashMap<>();
        for (Map<String, Object> sel : selections) {
            int itemId = readInt(sel.get("id"), 0);
            int qty = readInt(sel.get("quantity"), 0);
            if (itemId <= 0 || qty <= 0) continue;
            wanted.merge(itemId, qty, Integer::sum);
        }
        if (wanted.isEmpty()) {
            throw new IllegalArgumentException("Số lượng tách không hợp lệ.");
        }

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);

            int sourceNumber;
            String tableName;
            int sourceCustomerId;
            int sourceTableId;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT orderNumber, tableName, pointsRedeemed, customerId, tableId, splitLocked "
                            + "FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=? AND status='Served'")) {
                ps.setInt(1, sourceOrderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Chỉ tách được hóa đơn đang chờ thanh toán.");
                    if (rs.getBoolean("splitLocked")) {
                        throw new IllegalArgumentException("Hóa đơn này đã bị khóa tách (đã tách trước đó).");
                    }
                    // Đơn đã dùng điểm giảm giá thì không tách. Tách ra sẽ phải
                    // chia phần giảm giá giữa hai đơn — chưa có quy tắc nghiệp vụ
                    // cho việc đó, nên chặn thẳng còn hơn chia sai rồi lệch tiền.
                    if (rs.getInt("pointsRedeemed") > 0) {
                        throw new IllegalArgumentException("Đơn đã dùng điểm giảm giá nên không thể tách. Vui lòng thanh toán nguyên đơn.");
                    }
                    sourceNumber = rs.getInt("orderNumber");
                    tableName = rs.getString("tableName");
                    sourceCustomerId = rs.getInt("customerId");
                    sourceTableId = rs.getInt("tableId");
                }
            }

            // Đọc & khóa các dòng của đơn nguồn.
            Map<Integer, Map<String, Object>> sourceLines = new LinkedHashMap<>();
            try (PreparedStatement ps = con.prepareStatement("SELECT id, menuItemId, itemName, itemSize, quantity, price FROM dbo.OrderItems WITH (UPDLOCK, ROWLOCK) WHERE orderId=? ORDER BY id")) {
                ps.setInt(1, sourceOrderId);
                try (ResultSet rs = ps.executeQuery()) {
                    for (Map<String, Object> line : rows(rs)) {
                        sourceLines.put(readInt(line.get("id"), 0), line);
                    }
                }
            }
            if (sourceLines.isEmpty()) throw new IllegalArgumentException("Hóa đơn nguồn không có món.");

            // Validate lựa chọn thuộc đơn nguồn và số lượng hợp lệ; đồng thời kiểm tra không tách hết mọi thứ.
            boolean leavesRemainder = false;
            for (Map.Entry<Integer, Map<String, Object>> entry : sourceLines.entrySet()) {
                int available = readInt(entry.getValue().get("quantity"), 0);
                int take = wanted.getOrDefault(entry.getKey(), 0);
                if (take < available) leavesRemainder = true;
            }
            for (Map.Entry<Integer, Integer> req : wanted.entrySet()) {
                Map<String, Object> line = sourceLines.get(req.getKey());
                if (line == null) throw new IllegalArgumentException("Món tách không thuộc hóa đơn này.");
                int available = readInt(line.get("quantity"), 0);
                if (req.getValue() > available) {
                    throw new IllegalArgumentException("Số lượng tách vượt quá số lượng của món.");
                }
            }
            if (!leavesRemainder) {
                throw new IllegalArgumentException("Phải để lại ít nhất 1 món trên hóa đơn gốc.");
            }

            // Tạo hóa đơn mới từ phần tách.
            int newId;
            // Hóa đơn tách kế thừa chủ tài khoản: nếu không, phần tách ra sẽ
            // không được tích điểm và khách mất điểm một cách vô lý.
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Orders (tableName,tableId,customerPhone,note,total,status,splitLocked,customerId) VALUES (?,?,NULL,?,0,'Served',1,?)", Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, tableName);
                if (sourceTableId > 0) ps.setInt(2, sourceTableId); else ps.setNull(2, java.sql.Types.INTEGER);
                ps.setString(3, limitNote("Tách từ #" + sourceNumber));
                if (sourceCustomerId > 0) ps.setInt(4, sourceCustomerId); else ps.setNull(4, java.sql.Types.INTEGER);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    newId = keys.getInt(1);
                }
            }

            // Chuyển số lượng sang hóa đơn mới.
            for (Map.Entry<Integer, Integer> req : wanted.entrySet()) {
                Map<String, Object> line = sourceLines.get(req.getKey());
                int take = req.getValue();
                int available = readInt(line.get("quantity"), 0);
                if (take >= available) {
                    try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.OrderItems WHERE id=?")) {
                        ps.setInt(1, req.getKey());
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.OrderItems SET quantity=quantity-? WHERE id=?")) {
                        ps.setInt(1, take);
                        ps.setInt(2, req.getKey());
                        ps.executeUpdate();
                    }
                }
                int menuItemId = readInt(line.get("menuItemId"), 0);
                String size = readString(line.get("itemSize"), "");
                int price = readInt(line.get("price"), 0);
                int existingId = findMatchingOrderItem(con, newId, menuItemId, size, price);
                if (existingId > 0) {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.OrderItems SET quantity=quantity+? WHERE id=?")) {
                        ps.setInt(1, take);
                        ps.setInt(2, existingId);
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
                        ps.setInt(1, newId);
                        ps.setInt(2, menuItemId);
                        ps.setString(3, readString(line.get("itemName"), ""));
                        ps.setString(4, size.isEmpty() ? null : size);
                        ps.setInt(5, take);
                        ps.setInt(6, price);
                        ps.executeUpdate();
                    }
                }
            }

            // Tính lại tổng cho cả hai hóa đơn.
            updateOrderTotal(con, sourceOrderId);
            updateOrderTotal(con, newId);
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET orderNumber=?, splitLocked=1 WHERE id=?")) {
                ps.setInt(1, 1000 + newId);
                ps.setInt(2, newId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET splitLocked=1 WHERE id=?")) {
                ps.setInt(1, sourceOrderId);
                ps.executeUpdate();
            }

            insertSystemLog(con, actorRole, actorName, "ORDER_SPLIT",
                    "Tách hóa đơn #" + sourceNumber + " thành hóa đơn mới #" + (1000 + newId) + " tại " + tableName + " lúc " + nowLabelVi(),
                    "Split bill #" + sourceNumber + " into new bill #" + (1000 + newId) + " at " + tableName + " at " + nowLabelEn(),
                    newId);
            con.commit();

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("source", getOrderById(sourceOrderId));
            result.put("created", getOrderById(newId));
            return result;
        }
    }

    private void updateOrderTotal(Connection con, int orderId) throws Exception {
        int total = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT ISNULL(SUM(quantity*price),0) AS total FROM dbo.OrderItems WHERE orderId=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) total = rs.getInt("total");
            }
        }
        // subtotal đi kèm total. Hàm này chỉ được gọi từ splitOrder, mà splitOrder
        // đã chặn đơn có giảm giá, nên ở đây discount luôn = 0 và subtotal = total.
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET total=?, subtotal=? WHERE id=?")) {
            ps.setInt(1, total);
            ps.setInt(2, total);
            ps.setInt(3, orderId);
            ps.executeUpdate();
        }
    }

    private int findMatchingOrderItem(Connection con, int orderId, int menuItemId, String size, int price) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT TOP 1 id FROM dbo.OrderItems WHERE orderId=? AND menuItemId=? AND ISNULL(itemSize,'')=? AND price=? ORDER BY id")) {
            ps.setInt(1, orderId);
            ps.setInt(2, menuItemId);
            ps.setString(3, readString(size, ""));
            ps.setInt(4, price);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("id") : 0;
            }
        }
    }

    private int cupCountForOrder(Connection con, int orderId) throws Exception {
        String sql = "SELECT oi.quantity, mi.category "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.MenuItems mi ON mi.id=oi.menuItemId "
                + "WHERE oi.orderId=?";
        int cups = 0;
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    if (isDrinkCategory(rs.getString("category"))) {
                        cups += Math.max(0, rs.getInt("quantity"));
                    }
                }
            }
        }
        return cups;
    }

    public Map<String, Object> getCashStatus(String role) throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> status = new LinkedHashMap<>();
            status.put("balance", currentCashBalance(con));
            status.put("recentWithdrawals", cashEvents(con, "ADMIN_WITHDRAW", 8, false));
            status.put("recentEvents", cashEvents(con, "", 12, false));
            status.put("pendingWithdrawals", "cashier".equals(role) ? cashEvents(con, "ADMIN_WITHDRAW", 8, true) : new ArrayList<>());
            return status;
        }
    }

    public Map<String, Object> recordCashierCount(int countedCash, String actorName) throws Exception {
        if (countedCash < 0 || countedCash > 1000000000) throw new IllegalArgumentException("Số tiền mặt không hợp lệ.");
        try (Connection con = db.getConnection()) {
            int current = currentCashBalance(con);
            int diff = countedCash - current;
            insertCashEvent(con, "CASHIER_COUNT", diff, countedCash, "Cashier cash count", "cashier", actorName, true);
            insertSystemLog(con, "cashier", actorName, "CASH_COUNT",
                    "Thu ngân chốt tiền mặt " + countedCash + "đ lúc " + nowLabelVi(),
                    "Cashier counted cash at " + countedCash + " VND at " + nowLabelEn(),
                    null);
            return getCashStatus("cashier");
        }
    }

    public Map<String, Object> withdrawCash(int amount, String actorName) throws Exception {
        if (amount <= 0 || amount > 1000000000) throw new IllegalArgumentException("Số tiền rút không hợp lệ.");
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            int current = currentCashBalance(con);
            if (amount > current) throw new IllegalArgumentException("Số tiền rút lớn hơn tiền mặt hiện có.");
            int balance = current - amount;
            insertCashEvent(con, "ADMIN_WITHDRAW", -amount, balance, "Admin withdraw", "admin", actorName, false);
            insertSystemLog(con, "admin", actorName, "CASH_WITHDRAW",
                    "Admin rút " + amount + "đ tiền mặt lúc " + nowLabelVi(),
                    "Admin withdrew " + amount + " VND cash at " + nowLabelEn(),
                    null);
            con.commit();
            return getCashStatus("admin");
        }
    }

    public void acknowledgeCashierWithdrawals() throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("UPDATE dbo.CashEvents SET seenByCashier=1 WHERE eventType='ADMIN_WITHDRAW' AND seenByCashier=0")) {
            ps.executeUpdate();
        }
    }

    private int currentCashBalance(Connection con) throws Exception {
        // PAYMENT phải nằm trong danh sách này. Thiếu nó thì tiền bán hàng
        // không bao giờ vào sổ quỹ và mọi lần chốt ca đều lệch.
        try (PreparedStatement ps = con.prepareStatement("SELECT TOP 1 balanceAfter FROM dbo.CashEvents WHERE eventType IN ('CASHIER_COUNT','ADMIN_WITHDRAW','PAYMENT') ORDER BY id DESC");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt("balanceAfter") : 0;
        }
    }

    private void insertCashEvent(Connection con, String type, int amount, int balanceAfter, String note, String actorRole, String actorName, boolean seenByCashier) throws Exception {
        insertCashEvent(con, type, amount, balanceAfter, note, actorRole, actorName, seenByCashier, 0, 0, actorStaffId());
    }

    private void insertCashEvent(Connection con, String type, int amount, int balanceAfter, String note,
                                 String actorRole, String actorName, boolean seenByCashier,
                                 int orderId, int paymentId, int staffId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.CashEvents (eventType,amount,balanceAfter,note,actorRole,actorName,seenByCashier,orderId,paymentId,staffId) VALUES (?,?,?,?,?,?,?,?,?,?)")) {
            ps.setString(1, type);
            ps.setInt(2, amount);
            ps.setInt(3, balanceAfter);
            ps.setString(4, limitNote(note));
            ps.setString(5, actorRole);
            ps.setString(6, actorName);
            ps.setBoolean(7, seenByCashier);
            if (orderId > 0) ps.setInt(8, orderId); else ps.setNull(8, java.sql.Types.INTEGER);
            if (paymentId > 0) ps.setInt(9, paymentId); else ps.setNull(9, java.sql.Types.INTEGER);
            if (staffId > 0) ps.setInt(10, staffId); else ps.setNull(10, java.sql.Types.INTEGER);
            ps.executeUpdate();
        }
    }

    private List<Map<String, Object>> cashEvents(Connection con, String type, int limit, boolean unseenOnly) throws Exception {
        String where = "";
        if (!readString(type, "").isEmpty()) where = "WHERE eventType=? ";
        if (unseenOnly) where += where.isEmpty() ? "WHERE seenByCashier=0 " : "AND seenByCashier=0 ";
        String sql = "SELECT TOP " + Math.max(1, limit) + " id,eventType,amount,balanceAfter,note,actorRole,actorName,seenByCashier,orderId,paymentId,staffId,createdAt FROM dbo.CashEvents " + where + "ORDER BY id DESC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            if (!readString(type, "").isEmpty()) ps.setString(1, type);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    public Map<String, Object> getCupStatus() throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> status = new LinkedHashMap<>();
            status.put("cupsAvailable", stateValue(con, "cupsAvailable", 0));
            return status;
        }
    }

    public Map<String, Object> updateCupStock(int amount, String mode, String actorName) throws Exception {
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            int current = stateValueForUpdate(con, "cupsAvailable", 0);
            int next = "adjust".equalsIgnoreCase(readString(mode, "")) ? current + amount : amount;
            if (next < 0 || next > 100000) throw new IllegalArgumentException("Số lượng cốc không hợp lệ.");
            setStateValue(con, "cupsAvailable", next);
            insertSystemLog(con, "admin", actorName, "CUP_STOCK",
                    "Admin cập nhật số cốc từ " + current + " thành " + next + " lúc " + nowLabelVi(),
                    "Admin changed cup stock from " + current + " to " + next + " at " + nowLabelEn(),
                    null);
            con.commit();
            Map<String, Object> status = new LinkedHashMap<>();
            status.put("cupsAvailable", next);
            return status;
        }
    }

    public List<Map<String, Object>> getSystemLogs(String actor) throws Exception {
        String normalized = normalizeActor(actor);
        String where = normalized.isEmpty() ? "" : "WHERE actorRole=? ";
        String sql = "SELECT TOP 200 id,actorRole,actorName,actionType,messageVi,messageEn,refId,createdAt FROM dbo.SystemLogs " + where + "ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            if (!normalized.isEmpty()) ps.setString(1, normalized);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    public void addSystemLog(String actorRole, String actorName, String actionType, String messageVi, String messageEn, Integer refId) throws Exception {
        try (Connection con = db.getConnection()) {
            insertSystemLog(con, actorRole, actorName, actionType, messageVi, messageEn, refId);
        }
    }

    private int stateValue(Connection con, String key, int fallback) throws Exception {
        ensureState(con, key, fallback);
        try (PreparedStatement ps = con.prepareStatement("SELECT intValue FROM dbo.StoreState WHERE stateKey=?")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("intValue") : fallback;
            }
        }
    }

    private int stateValueForUpdate(Connection con, String key, int fallback) throws Exception {
        ensureState(con, key, fallback);
        try (PreparedStatement ps = con.prepareStatement("SELECT intValue FROM dbo.StoreState WITH (UPDLOCK, ROWLOCK) WHERE stateKey=?")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("intValue") : fallback;
            }
        }
    }

    private void setStateValue(Connection con, String key, int value) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.StoreState SET intValue=?, updatedAt=SYSUTCDATETIME() WHERE stateKey=?")) {
            ps.setInt(1, value);
            ps.setString(2, key);
            ps.executeUpdate();
        }
    }

    // ── Ai đang thao tác ────────────────────────────────────────────────
    // Bốn tài khoản admin/barista/cashier/runner là tài khoản VỊ TRÍ, dùng
    // chung cho nhiều người. Nên actorName trước đây chỉ ghi "Thu ngân
    // coffeshop" — không quy được trách nhiệm cho ai.
    //
    // Servlet đặt staffId của người thật vào đây ở đầu mỗi request, nhờ vậy
    // hơn 50 chỗ gọi insertSystemLog không phải sửa chữ ký. Bắt buộc phải
    // clear ở cuối request vì Tomcat tái sử dụng thread cho request khác.
    private static final ThreadLocal<Integer> ACTOR_STAFF_ID = new ThreadLocal<>();

    public static void setActorStaffId(int staffId) {
        if (staffId > 0) ACTOR_STAFF_ID.set(staffId); else ACTOR_STAFF_ID.remove();
    }

    public static void clearActorStaffId() {
        ACTOR_STAFF_ID.remove();
    }

    private static int actorStaffId() {
        Integer value = ACTOR_STAFF_ID.get();
        return value == null ? 0 : value;
    }

    private void insertSystemLog(Connection con, String actorRole, String actorName, String actionType, String messageVi, String messageEn, Integer refId) throws Exception {
        String role = normalizeActor(actorRole);
        if (role.isEmpty()) role = "system";
        int staffId = actorStaffId();
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.SystemLogs (actorRole,actorName,actionType,messageVi,messageEn,refId,staffId) VALUES (?,?,?,?,?,?,?)")) {
            ps.setString(1, role);
            ps.setString(2, limitLog(actorName));
            ps.setString(3, limitLog(readString(actionType, "ACTION")));
            ps.setString(4, limitLog(messageVi));
            ps.setString(5, limitLog(messageEn));
            if (refId == null || refId <= 0) ps.setNull(6, Types.INTEGER);
            else ps.setInt(6, refId);
            if (staffId > 0) ps.setInt(7, staffId); else ps.setNull(7, Types.INTEGER);
            ps.executeUpdate();
        }
    }

    /**
     * Đưa mọi cách viết vai trò về đúng mã trong dbo.Roles.
     * Cần thiết vì Shifts.assignedRole nay có khoá ngoại: chuỗi lạ sẽ bị CSDL
     * từ chối, và dữ liệu cũ vẫn còn ghi 'Barista'/'Waiter' kiểu chữ hoa.
     * Trả về chuỗi rỗng nếu không nhận ra — gọi bên ngoài tự quyết định.
     */
    public static String normalizeRoleCode(String raw) {
        String value = raw == null ? "" : raw.trim().toLowerCase(Locale.ROOT);
        if (value.isEmpty()) return "";
        if (value.equals("waiter") || value.equals("runner")) return "runner";
        if (value.equals("barista")) return "barista";
        if (value.equals("cashier")) return "cashier";
        if (value.equals("admin")) return "admin";
        return "";
    }

    // ══════════════════════════════════════════════════════════════
    //  TÀI KHOẢN CÁ NHÂN CỦA NHÂN VIÊN
    //
    //  Trước đây 10 nhân viên dùng chung 3 tài khoản vị trí. Hệ quả: không
    //  quy được trách nhiệm cho ai, và không thực thi được luật "chỉ người
    //  đang trong ca mới thao tác được" vì hệ thống không biết ai đang đăng nhập.
    //
    //  Giờ mỗi nhân viên có một dòng Users riêng, PIN được băm, và VAI TRÒ
    //  của phiên làm việc suy ra từ ca được xếp HÔM NAY.
    // ══════════════════════════════════════════════════════════════

    /** PIN mặc định khi tạo tài khoản lần đầu. Admin nên đổi ngay sau demo. */
    public static String defaultPinFor(int staffId) {
        return String.valueOf(1000 + Math.max(0, staffId));
    }

    /**
     * Đảm bảo mỗi nhân viên đang làm việc đều có một tài khoản.
     * Chạy mỗi lần khởi động để tạo bù cho dữ liệu cũ.
     */
    public void ensureStaffAccounts() {
        try (Connection con = db.getConnection()) {
            List<Map<String, Object>> staff;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT s.id, s.name FROM dbo.Staff s WHERE s.active = 1 "
                            + "AND NOT EXISTS (SELECT 1 FROM dbo.Users u WHERE u.staffId = s.id) ORDER BY s.id");
                 ResultSet rs = ps.executeQuery()) {
                staff = rows(rs);
            }
            int created = 0;
            for (Map<String, Object> row : staff) {
                if (createAccountFor(con, readInt(row.get("id"), 0), readString(row.get("name"), ""))) created++;
            }
            if (created > 0) {
                System.out.println("[LiteService] Đã tạo " + created
                        + " tài khoản nhân viên (PIN mặc định = 1000 + id).");
            }
            // Tài khoản đã có nhưng chưa có PIN băm (dữ liệu từ bản cũ).
            backfillMissingPins(con);
        } catch (Exception e) {
            System.err.println("[LiteService] ensureStaffAccounts bỏ qua: " + e.getMessage());
        }
    }

    /**
     * Tạo tài khoản NGAY khi admin thêm nhân viên mới.
     *
     * Trước đây việc này chỉ chạy lúc Tomcat khởi động, nên nhân viên vừa thêm
     * xong không có tài khoản và đăng nhập luôn báo "Sai mã PIN" — thông báo
     * sai hoàn toàn với nguyên nhân thật.
     *
     * @return PIN mặc định nếu vừa tạo, chuỗi rỗng nếu đã có tài khoản.
     */
    public String ensureAccountForStaff(int staffId, String staffName) {
        if (staffId <= 0) return "";
        try (Connection con = db.getConnection()) {
            // Nhận lại người cũ: tài khoản của họ đã bị khoá và xoá PIN lúc
            // nghỉ việc. Không có nhánh này thì hàng Users cũ chặn việc tạo
            // mới, và người được nhận lại vĩnh viễn không đăng nhập được.
            if (reactivateAccountFor(con, staffId)) return defaultPinFor(staffId);
            return createAccountFor(con, staffId, staffName) ? defaultPinFor(staffId) : "";
        } catch (Exception e) {
            System.err.println("[LiteService] ensureAccountForStaff bỏ qua: " + e.getMessage());
            return "";
        }
    }

    /** @return true nếu vừa mở lại một tài khoản bị khoá của nhân viên đang làm việc. */
    private boolean reactivateAccountFor(Connection con, int staffId) {
        try (PreparedStatement check = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.Users u JOIN dbo.Staff s ON s.id = u.staffId "
                        + "WHERE u.staffId = ? AND u.active = 0 AND s.active = 1")) {
            check.setInt(1, staffId);
            try (ResultSet rs = check.executeQuery()) {
                if (!rs.next() || rs.getInt(1) == 0) return false;
            }
        } catch (Exception e) {
            return false;
        }
        String salt = utils.PasswordUtils.newSalt();
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Users SET active = 1, pinHash = ?, pinSalt = ? WHERE staffId = ?")) {
            ps.setString(1, utils.PasswordUtils.hash(defaultPinFor(staffId), salt));
            ps.setString(2, salt);
            ps.setInt(3, staffId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            System.err.println("[LiteService] Không mở lại được tài khoản cho nhân viên "
                    + staffId + ": " + e.getMessage());
            return false;
        }
    }

    /** @return true nếu vừa tạo mới; false nếu đã tồn tại hoặc lỗi. */
    private boolean createAccountFor(Connection con, int staffId, String name) {
        if (staffId <= 0) return false;
        // Người đang nghỉ việc thì KHÔNG cấp lại tài khoản. Admin mở hồ sơ cũ
        // ra sửa vài chữ rồi bấm Lưu là đủ để dựng lại tài khoản vừa gỡ nếu
        // thiếu chỗ kiểm tra này.
        try (PreparedStatement check = con.prepareStatement("SELECT active FROM dbo.Staff WHERE id = ?")) {
            check.setInt(1, staffId);
            try (ResultSet rs = check.executeQuery()) {
                if (rs.next() && !rs.getBoolean("active")) return false;
            }
        } catch (Exception e) {
            return false;
        }
        try (PreparedStatement check = con.prepareStatement("SELECT COUNT(*) FROM dbo.Users WHERE staffId = ?")) {
            check.setInt(1, staffId);
            try (ResultSet rs = check.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return false;
            }
        } catch (Exception e) {
            return false;
        }
        String username = "nv" + String.format(Locale.ROOT, "%03d", staffId);
        String salt = utils.PasswordUtils.newSalt();
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO dbo.Users (username, password, role, fullName, staffId, pinHash, pinSalt, active) "
                        + "VALUES (?,?, 'staff', ?, ?, ?, ?, 1)")) {
            ps.setString(1, username);
            // Cột password cũ vẫn NOT NULL. Không lưu PIN thật vào đây —
            // chỗ dùng để xác thực là pinHash/pinSalt.
            ps.setString(2, "-");
            ps.setString(3, readString(name, username));
            ps.setInt(4, staffId);
            ps.setString(5, utils.PasswordUtils.hash(defaultPinFor(staffId), salt));
            ps.setString(6, salt);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.err.println("[LiteService] Không tạo được tài khoản cho nhân viên "
                    + staffId + ": " + e.getMessage());
            return false;
        }
    }

    private void backfillMissingPins(Connection con) throws Exception {
        List<Map<String, Object>> rows;
        // active = 1 là BẮT BUỘC. Tài khoản của người đã nghỉ bị xoá PIN có
        // chủ đích; thiếu điều kiện này thì lần khởi động sau nó lại được cấp
        // PIN mặc định 1000+id, tức là tự mở khoá lại tài khoản vừa gỡ.
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT username, staffId FROM dbo.Users WHERE staffId IS NOT NULL AND active = 1 "
                        + "AND (pinHash IS NULL OR pinSalt IS NULL)");
             ResultSet rs = ps.executeQuery()) {
            rows = rows(rs);
        }
        for (Map<String, Object> row : rows) {
            String salt = utils.PasswordUtils.newSalt();
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Users SET pinHash=?, pinSalt=? WHERE username=?")) {
                ps.setString(1, utils.PasswordUtils.hash(defaultPinFor(readInt(row.get("staffId"), 0)), salt));
                ps.setString(2, salt);
                ps.setString(3, readString(row.get("username"), ""));
                ps.executeUpdate();
            }
        }
    }

    /**
     * Các ca HÔM NAY của một nhân viên, sớm nhất trước.
     * Chỉ nhận ca đang xếp lịch / đang làm; bỏ qua Vắng mặt / Nghỉ.
     */
    private List<Map<String, Object>> todayShifts(int staffId) throws Exception {
        if (staffId <= 0) return new ArrayList<>();
        String sql = "SELECT sh.assignedRole, sh.shiftName, sh.hours FROM dbo.Shifts sh "
                + "WHERE sh.staffId = ? AND sh.shiftDate = ? AND sh.assignedRole IS NOT NULL "
                + "AND (sh.status IS NULL OR sh.status NOT IN (N'Vắng', N'Vắng mặt', N'Nghỉ', N'Cancelled', N'Absent')) "
                + "ORDER BY sh.hours";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, staffId);
            ps.setString(2, appToday().toString());
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    /**
     * Ca mà nhân viên đang thực sự đứng, tính theo ĐỒNG HỒ chứ không chỉ theo
     * ngày. null = hôm nay không có ca, hoặc có nhưng chưa tới / đã qua giờ.
     */
    private Map<String, Object> currentShift(int staffId) throws Exception {
        return pickActiveShift(todayShifts(staffId), appNowTime());
    }

    /**
     * Vai trò của nhân viên TẠI THỜI ĐIỂM NÀY, lấy từ bảng phân ca.
     * Chuỗi rỗng = đang ngoài ca.
     *
     * Đây là chỗ luật "chỉ người trong ca mới thao tác được" thực sự được
     * thực thi: ngoài ca thì không có vai trò, không có vai trò thì
     * SecurityFilter chặn hết mọi trang nghiệp vụ.
     *
     * Trước đây hàm này chỉ so shiftDate với hôm nay nên cột hours bị bỏ qua
     * hoàn toàn: người của ca tối đăng nhập lúc sáng vẫn lọt, và còn nhận
     * đúng vai trò của ca tối vì ORDER BY hours lấy bừa ca đầu ngày.
     */
    public String resolveShiftRole(int staffId) throws Exception {
        Map<String, Object> shift = currentShift(staffId);
        return shift == null ? "" : readString(shift.get("assignedRole"), "");
    }

    /**
     * Danh sách hiện trên màn đăng nhập: nhân viên đang làm việc, kèm vai trò
     * hôm nay nếu có. KHÔNG trả về pinHash — dữ liệu này công khai trước khi
     * đăng nhập nên chỉ được chứa thứ đủ để bấm chọn.
     */
    public List<Map<String, Object>> getLoginRoster() throws Exception {
        String today = appToday().toString();
        String sql = "SELECT s.id, s.name, "
                + "(SELECT TOP 1 sh.shiftDate FROM dbo.Shifts sh "
                + " WHERE sh.staffId = s.id AND sh.shiftDate > ? AND sh.assignedRole IS NOT NULL ORDER BY sh.shiftDate) AS nextShiftDate, "
                + "(SELECT COUNT(*) FROM dbo.Users u WHERE u.staffId = s.id AND u.active = 1) AS accountCount "
                + "FROM dbo.Staff s WHERE s.active = 1 AND s.status = 'Active' ORDER BY s.name";
        List<Map<String, Object>> list;
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, today);
            try (ResultSet rs = ps.executeQuery()) {
                list = rows(rs);
            }
        }

        // Ca của cả quán trong hôm nay, gom theo nhân viên. Lấy một lượt rồi
        // lọc theo giờ trong Java: cột hours là chuỗi "HH:mm - HH:mm" nên SQL
        // không so sánh được, và danh sách này chỉ vài chục dòng.
        Map<Integer, List<Map<String, Object>>> byStaff = new LinkedHashMap<>();
        String shiftSql = "SELECT sh.staffId, sh.assignedRole, sh.shiftName, sh.hours FROM dbo.Shifts sh "
                + "WHERE sh.shiftDate = ? AND sh.assignedRole IS NOT NULL "
                + "AND (sh.status IS NULL OR sh.status NOT IN (N'Vắng', N'Vắng mặt', N'Nghỉ', N'Cancelled', N'Absent')) "
                + "ORDER BY sh.hours";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(shiftSql)) {
            ps.setString(1, today);
            try (ResultSet rs = ps.executeQuery()) {
                for (Map<String, Object> shift : rows(rs)) {
                    byStaff.computeIfAbsent(readInt(shift.get("staffId"), 0), k -> new ArrayList<>()).add(shift);
                }
            }
        }

        java.time.LocalTime now = appNowTime();
        int nowMinutes = now.getHour() * 60 + now.getMinute();
        for (Map<String, Object> row : list) {
            List<Map<String, Object>> shifts = byStaff.getOrDefault(readInt(row.get("id"), 0), new ArrayList<>());
            Map<String, Object> active = pickActiveShift(shifts, now);
            Map<String, Object> upcoming = null;
            for (Map<String, Object> shift : shifts) {
                if (shift == active) continue;
                int[] window = parseShiftWindow(readString(shift.get("hours"), ""));
                if (window != null && window[0] > nowMinutes) {
                    upcoming = shift;
                    break;
                }
            }
            // todayRole chỉ được có giá trị khi người này ĐANG trong ca — giao
            // diện dùng đúng nó để quyết định bấm vào có vào được hay không.
            row.put("todayRole", active == null ? null : active.get("assignedRole"));
            row.put("todayShift", active == null ? null : active.get("shiftName"));
            row.put("todayHours", active == null ? null : active.get("hours"));
            row.put("onDuty", active != null);
            // Ca sau trong cùng ngày: người đến sớm cần biết mình phải chờ đến
            // mấy giờ, chứ không phải đọc "hôm nay không có ca".
            row.put("upcomingShift", upcoming == null ? null : upcoming.get("shiftName"));
            row.put("upcomingHours", upcoming == null ? null : upcoming.get("hours"));
            // Có ca hôm nay nhưng đã tan hết: khác hẳn "hôm nay không có ca",
            // và người vừa tan ca cần đọc đúng câu đó chứ không phải ngày ca sau.
            row.put("shiftEnded", active == null && upcoming == null && !shifts.isEmpty());
            row.put("hasAccount", readInt(row.get("accountCount"), 0) > 0);
            row.remove("accountCount");
        }
        return list;
    }

    /**
     * Câu từ chối khi PIN đúng nhưng đang ngoài ca.
     *
     * "Hôm nay không có ca" và "chưa tới giờ ca của bạn" là hai tình huống
     * khác hẳn nhau: cái đầu là xếp lịch sai, cái sau chỉ là đến sớm. Nói
     * gộp một câu thì người ta đi tìm quản lý một cách vô ích.
     */
    private String offShiftMessage(int staffId) throws Exception {
        List<Map<String, Object>> shifts = todayShifts(staffId);
        if (shifts.isEmpty()) {
            return "Hôm nay bạn không được xếp ca. Cần quản lý mở khoá để đăng nhập.";
        }
        java.time.LocalTime now = appNowTime();
        int nowMinutes = now.getHour() * 60 + now.getMinute();
        Map<String, Object> upcoming = null;
        for (Map<String, Object> shift : shifts) {
            int[] window = parseShiftWindow(readString(shift.get("hours"), ""));
            if (window != null && window[0] > nowMinutes) {
                upcoming = shift;
                break;
            }
        }
        if (upcoming != null) {
            return "Chưa tới giờ ca của bạn (" + shiftLabel(upcoming)
                    + "). Cần quản lý mở khoá nếu muốn vào sớm.";
        }
        return "Ca của bạn hôm nay (" + shiftLabel(shifts.get(shifts.size() - 1))
                + ") đã kết thúc. Cần quản lý mở khoá để đăng nhập.";
    }

    /**
     * Đăng nhập bằng tài khoản cá nhân.
     *
     * @param adminOverride true khi admin đã nhập PIN quản trị để mở khoá cho
     *                      người làm thay ngoài ca. Vẫn ghi rõ vào nhật ký.
     * @return thông tin phiên, hoặc null nếu sai PIN.
     * @throws IllegalStateException nếu PIN đúng nhưng hôm nay không có ca.
     */
    public Map<String, Object> loginStaff(int staffId, String pin, boolean adminOverride) throws Exception {
        if (staffId <= 0) return null;
        String hash;
        String salt;
        String fullName;
        String username;
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
                "SELECT u.username, u.fullName, u.pinHash, u.pinSalt, u.active, s.name AS staffName, s.active AS staffActive "
                        + "FROM dbo.Users u JOIN dbo.Staff s ON s.id = u.staffId WHERE u.staffId = ?")) {
            ps.setInt(1, staffId);
            try (ResultSet rs = ps.executeQuery()) {
                // Chưa có tài khoản KHÁC HẲN sai PIN. Gộp hai thứ này lại chỉ
                // che mất lỗi cài đặt và làm người dùng gõ lại PIN vô ích.
                // Ở đây không có gì để lộ: danh sách tên vốn đã công khai trên
                // chính màn hình đăng nhập.
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            "Nhân viên này chưa có tài khoản. Quản lý vào màn hình Nhân viên để tạo.");
                }
                if (!rs.getBoolean("active") || !rs.getBoolean("staffActive")) {
                    throw new IllegalArgumentException("Tài khoản đã bị vô hiệu hoá.");
                }
                hash = readString(rs.getString("pinHash"), "");
                salt = readString(rs.getString("pinSalt"), "");
                username = readString(rs.getString("username"), "");
                fullName = readString(rs.getString("staffName"), readString(rs.getString("fullName"), ""));
            }
        }
        if (hash.isEmpty() || !utils.PasswordUtils.matches(pin, salt, hash)) return null;

        String role = resolveShiftRole(staffId);
        if (role.isEmpty()) {
            if (!adminOverride) {
                throw new IllegalStateException(offShiftMessage(staffId));
            }
            // Mở khoá ngoài ca: cho vào với quyền thấp nhất, không đoán bừa
            // vai trò. Bồi bàn là vai trò ít quyền nhất trong ba vai trò.
            role = "runner";
        }

        Map<String, Object> session = new LinkedHashMap<>();
        session.put("staffId", staffId);
        session.put("staffName", fullName);
        session.put("username", username);
        session.put("role", role);
        session.put("fullName", fullName);
        session.put("adminOverride", adminOverride);
        return session;
    }

    /** Trạng thái hợp lệ của một nhân viên. Chuỗi lạ đưa hết về 'Active'. */
    private String normalizeStaffStatus(String raw) {
        String status = readString(raw, "").trim();
        if ("Temp_Inactive".equalsIgnoreCase(status)) return "Temp_Inactive";
        if ("Inactive".equalsIgnoreCase(status)) return "Inactive";
        if ("Perm_Inactive".equalsIgnoreCase(status)) return "Perm_Inactive";
        return "Active";
    }

    /**
     * Thêm mới hoặc sửa nhân viên.
     *
     * MÃ NHÂN VIÊN DO HỆ THỐNG CẤP. Trước đây admin tự gõ mã, còn hàm lưu thì
     * chỉ hỏi "mã này có sẵn chưa": có sẵn thì UPDATE. Nghĩa là thêm người mới
     * mang mã 8 thực chất là ĐỔI TÊN người mang mã 8 — toàn bộ ca làm, hoá đơn,
     * bút toán quỹ và nhật ký gắn với staffId = 8 lập tức đổi chủ, không một
     * lời cảnh báo. Trùng mã với người đã nghỉ hay người đang làm đều dính.
     *
     * Nay hai việc tách hẳn nhau:
     *   • id <= 0 → THÊM MỚI, mã lấy từ MAX(id)+1, không ai chọn hộ được;
     *   • id > 0  → SỬA người đang có; không tìm thấy thì báo lỗi chứ tuyệt
     *     đối không âm thầm tạo hàng mới mang mã do client gửi lên.
     *
     * @return hồ sơ đã lưu, kèm cờ "created" để giao diện biết mã vừa được cấp.
     */
    public Map<String, Object> saveStaff(int id, String rawName, String rawStatus) throws Exception {
        String name = readString(rawName, "").trim();
        if (name.isEmpty()) throw new IllegalArgumentException("Tên nhân viên không được để trống.");
        if (name.length() > 120) throw new IllegalArgumentException("Tên nhân viên dài quá 120 ký tự.");
        String status = normalizeStaffStatus(rawStatus);
        boolean active = "Active".equals(status);

        try (Connection con = db.getConnection()) {
            boolean created = false;
            int staffId = id;
            if (staffId > 0) {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE dbo.Staff SET name = ?, active = ?, status = ? WHERE id = ?")) {
                    ps.setNString(1, name);
                    ps.setBoolean(2, active);
                    ps.setString(3, status);
                    ps.setInt(4, staffId);
                    if (ps.executeUpdate() == 0) {
                        throw new IllegalArgumentException("Không tìm thấy nhân viên #" + staffId + " để sửa.");
                    }
                }
            } else {
                staffId = insertStaffWithNewId(con, name, active, status);
                created = true;
            }

            // Tên hiển thị của tài khoản phải đi theo tên nhân viên, nếu không
            // đổi tên xong là nhật ký và tài khoản nói hai cái tên khác nhau.
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Users SET fullName = ? WHERE staffId = ?")) {
                ps.setNString(1, name);
                ps.setInt(2, staffId);
                ps.executeUpdate();
            } catch (Exception ignored) {
                // Chưa có tài khoản thì thôi, không phải lỗi.
            }

            Map<String, Object> saved = new LinkedHashMap<>();
            saved.put("id", staffId);
            saved.put("name", name);
            saved.put("status", status);
            saved.put("active", active);
            saved.put("created", created);
            return saved;
        }
    }

    /**
     * Chèn nhân viên mới với mã kế tiếp.
     *
     * dbo.Staff.id không phải IDENTITY (dữ liệu cũ chèn mã tường minh), nên
     * phải tự tính MAX(id)+1. UPDLOCK/HOLDLOCK khoá khoảng giá trị để hai admin
     * bấm Lưu cùng lúc không nhận cùng một mã; vẫn thử lại vài lần phòng khi
     * đụng khoá chính.
     */
    private int insertStaffWithNewId(Connection con, String name, boolean active, String status) throws Exception {
        Exception last = null;
        for (int attempt = 0; attempt < 3; attempt++) {
            con.setAutoCommit(false);
            try {
                int nextId;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT ISNULL(MAX(id), 0) + 1 FROM dbo.Staff WITH (UPDLOCK, HOLDLOCK)");
                     ResultSet rs = ps.executeQuery()) {
                    nextId = rs.next() ? rs.getInt(1) : 1;
                }
                if (nextId <= 0) nextId = 1;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO dbo.Staff (id, name, active, status) VALUES (?, ?, ?, ?)")) {
                    ps.setInt(1, nextId);
                    ps.setNString(2, name);
                    ps.setBoolean(3, active);
                    ps.setString(4, status);
                    ps.executeUpdate();
                }
                con.commit();
                return nextId;
            } catch (Exception e) {
                con.rollback();
                last = e;
            } finally {
                con.setAutoCommit(true);
            }
        }
        throw new IllegalStateException("Không cấp được mã nhân viên mới: "
                + (last == null ? "" : last.getMessage()), last);
    }

    /**
     * Xoá nhân viên — xoá CỨNG khi làm vậy là an toàn.
     *
     * Trước đây "xoá" chỉ là UPDATE active=0: hàng dữ liệu nằm lại vĩnh viễn,
     * kể cả người tạo nhầm chưa từng làm gì, và tài khoản đăng nhập của họ
     * vẫn sống nguyên với PIN dùng được. Nghìn người nghỉ là nghìn hàng rác.
     *
     * Luật bây giờ:
     *   • không còn dấu vết nào (ca làm, thanh toán, sổ quỹ, nhật ký)
     *     → xoá hẳn cả hàng Staff lẫn tài khoản Users;
     *   • còn lịch sử → giữ hàng Staff, vì Payments.staffId / CashEvents /
     *     Shifts / SystemLogs đều trỏ vào đó: xoá đi là mất bảng công và mất
     *     dấu ai đứng quầy thu tiền. Nhưng TÀI KHOẢN ĐĂNG NHẬP thì gỡ hẳn —
     *     người đã nghỉ không có lý do gì còn một dòng Users bấm vào được.
     *
     * @return chi tiết việc đã làm, để admin đọc được thay vì đoán.
     */
    public Map<String, Object> deleteStaff(int staffId) throws Exception {
        if (staffId <= 0) throw new IllegalArgumentException("Thiếu mã nhân viên.");
        try (Connection con = db.getConnection()) {
            String name;
            try (PreparedStatement ps = con.prepareStatement("SELECT name FROM dbo.Staff WHERE id = ?")) {
                ps.setInt(1, staffId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy nhân viên #" + staffId + ".");
                    name = readString(rs.getString("name"), "");
                }
            }

            Map<String, Object> refs = countStaffReferences(con, staffId);
            int total = 0;
            for (Object value : refs.values()) total += readInt(value, 0);

            con.setAutoCommit(false);
            try {
                String account = removeStaffAccount(con, staffId);
                // Tài khoản không gỡ được (còn hoá đơn ghi tên nó) thì hàng
                // Users vẫn trỏ vào Staff — xoá cứng chắc chắn vỡ khoá ngoại.
                boolean hard = total == 0 && !"disabled".equals(account);
                if (hard) {
                    try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.Staff WHERE id = ?")) {
                        ps.setInt(1, staffId);
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE dbo.Staff SET active = 0, status = 'Inactive' WHERE id = ?")) {
                        ps.setInt(1, staffId);
                        ps.executeUpdate();
                    }
                }
                con.commit();

                Map<String, Object> result = new LinkedHashMap<>();
                result.put("id", staffId);
                result.put("name", name);
                result.put("hardDeleted", hard);
                result.put("account", account);
                result.put("references", refs);
                return result;
            } catch (Exception e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    /** Đếm mọi thứ đang trỏ vào một nhân viên. Rỗng hết = xoá cứng được. */
    private Map<String, Object> countStaffReferences(Connection con, int staffId) throws Exception {
        Map<String, Object> refs = new LinkedHashMap<>();
        refs.put("shifts", countByStaffId(con, "dbo.Shifts", staffId));
        refs.put("payments", countByStaffId(con, "dbo.Payments", staffId));
        refs.put("cashEvents", countByStaffId(con, "dbo.CashEvents", staffId));
        refs.put("logs", countByStaffId(con, "dbo.SystemLogs", staffId));
        // Refunds.staffId không có khoá ngoại nên xoá Staff vẫn chạy, nhưng
        // sẽ để lại một mã trỏ vào hư không. Tính luôn cho khỏi mất dấu.
        refs.put("refunds", countByStaffId(con, "dbo.Refunds", staffId));
        return refs;
    }

    /** Bảng hoặc cột không tồn tại ở CSDL cũ thì coi như không có tham chiếu. */
    private int countByStaffId(Connection con, String table, int staffId) {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM " + table + " WHERE staffId = ?")) {
            ps.setInt(1, staffId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * Gỡ tài khoản đăng nhập của một nhân viên.
     *
     * @return "deleted" xoá hẳn dòng Users · "disabled" chỉ khoá được vì
     *         Payments.cashierUsername có khoá ngoại trỏ vào Users(username),
     *         còn hoá đơn ghi tên tài khoản này thì không xoá dòng đó được ·
     *         "none" người này vốn chưa có tài khoản.
     */
    private String removeStaffAccount(Connection con, int staffId) throws Exception {
        String username;
        try (PreparedStatement ps = con.prepareStatement("SELECT username FROM dbo.Users WHERE staffId = ?")) {
            ps.setInt(1, staffId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return "none";
                username = readString(rs.getString("username"), "");
            }
        }

        int paymentsByUsername = 0;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.Payments WHERE cashierUsername = ?")) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) paymentsByUsername = rs.getInt(1);
            }
        } catch (Exception e) {
            // Không đếm được thì chọn phương án an toàn: khoá, đừng xoá.
            paymentsByUsername = 1;
        }

        if (paymentsByUsername == 0) {
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.Users WHERE staffId = ?")) {
                ps.setInt(1, staffId);
                ps.executeUpdate();
            }
            return "deleted";
        }
        // Xoá mã PIN chứ không chỉ hạ cờ active: PIN của người đã nghỉ không
        // được phép còn là chuỗi dùng được trong CSDL.
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Users SET active = 0, pinHash = NULL, pinSalt = NULL WHERE staffId = ?")) {
            ps.setInt(1, staffId);
            ps.executeUpdate();
        }
        return "disabled";
    }

    /** Admin đặt lại PIN cho một nhân viên. Trả về PIN mới. */
    public String resetStaffPin(int staffId, String newPin) throws Exception {
        String pin = readString(newPin, "").replaceAll("[^0-9]", "");
        if (pin.isEmpty()) pin = defaultPinFor(staffId);
        if (pin.length() < 4 || pin.length() > 8) {
            throw new IllegalArgumentException("PIN phải có từ 4 đến 8 chữ số.");
        }
        String salt = utils.PasswordUtils.newSalt();
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Users SET pinHash=?, pinSalt=? WHERE staffId=?")) {
            ps.setString(1, utils.PasswordUtils.hash(pin, salt));
            ps.setString(2, salt);
            ps.setInt(3, staffId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Nhân viên này chưa có tài khoản.");
            }
        }
        return pin;
    }

    /** Danh sách vai trò — nguồn duy nhất, thay cho các chuỗi rải rác trong code. */
    public List<Map<String, Object>> getRoles() throws Exception {
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT code, nameVi, nameEn, sortOrder FROM dbo.Roles ORDER BY sortOrder");
             ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    /**
     * Nhân viên được xếp làm vai trò này trong ngày hôm nay.
     * Dùng cho màn đăng nhập: chọn đúng người đang trong ca, nhờ đó log ghi
     * được tên thật thay vì tên tài khoản vị trí dùng chung.
     */
    public List<Map<String, Object>> getStaffOnDuty(String roleCode) throws Exception {
        String role = readString(roleCode, "").toLowerCase(Locale.ROOT);
        String today = appToday().toString();
        String sql = "SELECT DISTINCT s.id, s.name, sh.shiftName, sh.hours "
                + "FROM dbo.Staff s JOIN dbo.Shifts sh ON sh.staffId = s.id "
                + "WHERE sh.shiftDate = ? AND s.active = 1 AND s.status = 'Active' "
                + (role.isEmpty() ? "" : "AND sh.assignedRole = ? ")
                + "ORDER BY s.name";
        java.time.LocalTime now = appNowTime();
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, today);
            if (!role.isEmpty()) ps.setString(2, role);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> list = rows(rs);
                // "Đang trong ca" phải tính cả giờ, không chỉ ngày.
                list.removeIf(row -> !isShiftActiveNow(readString(row.get("hours"), ""), now));
                return list;
            }
        }
    }

    /** Nhân viên này có thật sự đang trong ca với vai trò đó không. */
    public boolean isStaffOnDuty(int staffId, String roleCode) throws Exception {
        if (staffId <= 0) return false;
        String role = readString(roleCode, "").toLowerCase(Locale.ROOT);
        String sql = "SELECT sh.hours FROM dbo.Shifts sh JOIN dbo.Staff s ON s.id = sh.staffId "
                + "WHERE sh.staffId = ? AND sh.shiftDate = ? AND sh.assignedRole = ? AND s.active = 1";
        java.time.LocalTime now = appNowTime();
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, staffId);
            ps.setString(2, appToday().toString());
            ps.setString(3, role);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    if (isShiftActiveNow(readString(rs.getString("hours"), ""), now)) return true;
                }
                return false;
            }
        }
    }

    public String getStaffName(int staffId) throws Exception {
        if (staffId <= 0) return "";
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT name FROM dbo.Staff WHERE id=?")) {
            ps.setInt(1, staffId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? readString(rs.getString("name"), "") : "";
            }
        }
    }

    private String normalizeActor(String actor) {
        String value = readString(actor, "").toLowerCase(Locale.ROOT);
        if (Arrays.asList("guest", "admin", "barista", "cashier", "runner", "system").contains(value)) return value;
        return "";
    }

    private String orderCreateLogVi(String actorRole, String tableName, int orderNumber, int totalQuantity) {
        String actor = normalizeActor(actorRole);
        if ("guest".equals(actor)) {
            return tableName + " gọi đơn #" + orderNumber + " (" + totalQuantity + " sản phẩm) lúc " + nowLabelVi();
        }
        return roleNameVi(actor) + " tạo đơn #" + orderNumber + " cho " + tableName + " (" + totalQuantity + " sản phẩm) lúc " + nowLabelVi();
    }

    private String orderCreateLogEn(String actorRole, String tableName, int orderNumber, int totalQuantity) {
        String actor = normalizeActor(actorRole);
        if ("guest".equals(actor)) {
            return tableName + " placed order #" + orderNumber + " (" + totalQuantity + " products) at " + nowLabelEn();
        }
        return roleNameEn(actor) + " created order #" + orderNumber + " for " + tableName + " (" + totalQuantity + " products) at " + nowLabelEn();
    }

    private String statusLogVi(String actorRole, String from, String to, int orderNumber, String tableName) {
        String actor = normalizeActor(actorRole);
        if ("barista".equals(actor) && "Pending".equals(from) && "Preparing".equals(to)) {
            return "Pha chế nhận đơn #" + orderNumber + " của " + tableName + " lúc " + nowLabelVi();
        }
        if ("barista".equals(actor) && "Preparing".equals(from) && "Ready".equals(to)) {
            return "Pha chế hoàn thành đơn #" + orderNumber + " của " + tableName + " lúc " + nowLabelVi();
        }
        if ("runner".equals(actor) && "Ready".equals(from) && "Served".equals(to)) {
            return "Bồi bàn phục vụ đơn #" + orderNumber + " cho " + tableName + " lúc " + nowLabelVi();
        }
        if ("cashier".equals(actor) && "Served".equals(from) && "Paid".equals(to)) {
            return "Thu ngân xác nhận đơn #" + orderNumber + " đã thanh toán lúc " + nowLabelVi();
        }
        return roleNameVi(actor) + " chuyển đơn #" + orderNumber + " từ " + from + " sang " + to + " lúc " + nowLabelVi();
    }

    private String statusLogEn(String actorRole, String from, String to, int orderNumber, String tableName) {
        String actor = normalizeActor(actorRole);
        if ("barista".equals(actor) && "Pending".equals(from) && "Preparing".equals(to)) {
            return "Barista accepted order #" + orderNumber + " at " + tableName + " at " + nowLabelEn();
        }
        if ("barista".equals(actor) && "Preparing".equals(from) && "Ready".equals(to)) {
            return "Barista completed order #" + orderNumber + " at " + tableName + " at " + nowLabelEn();
        }
        if ("runner".equals(actor) && "Ready".equals(from) && "Served".equals(to)) {
            return "Waiter served order #" + orderNumber + " to " + tableName + " at " + nowLabelEn();
        }
        if ("cashier".equals(actor) && "Served".equals(from) && "Paid".equals(to)) {
            return "Cashier marked order #" + orderNumber + " as paid at " + nowLabelEn();
        }
        return roleNameEn(actor) + " moved order #" + orderNumber + " from " + from + " to " + to + " at " + nowLabelEn();
    }

    private String roleNameVi(String role) {
        if ("guest".equals(role)) return "Khách";
        if ("admin".equals(role)) return "Admin";
        if ("barista".equals(role)) return "Pha chế";
        if ("cashier".equals(role)) return "Thu ngân";
        if ("runner".equals(role)) return "Bồi bàn";
        return "Hệ thống";
    }

    private String roleNameEn(String role) {
        if ("guest".equals(role)) return "Guest";
        if ("admin".equals(role)) return "Admin";
        if ("barista".equals(role)) return "Barista";
        if ("cashier".equals(role)) return "Cashier";
        if ("runner".equals(role)) return "Waiter";
        return "System";
    }

    private String nowLabelVi() {
        return java.time.LocalDateTime.now(APP_ZONE).format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy"));
    }

    private String nowLabelEn() {
        return java.time.LocalDateTime.now(APP_ZONE).format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy"));
    }

    private String limitLog(String text) {
        String clean = readString(text, "");
        return clean.length() > 380 ? clean.substring(0, 380) : clean;
    }

    public Map<String, Object> getOrderById(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, orderNumber, tableName, tableId, customerPhone, status, total, subtotal, discountAmount, pointsEarned, pointsRedeemed, customerId, note, createdAt, invoicePrinted, splitLocked, ISNULL(orderType,'DINE_IN') orderType, ISNULL(promoDiscount,0) promoDiscount, ISNULL(manualDiscount,0) manualDiscount, discountReason, ISNULL(taxAmount,0) taxAmount, ISNULL(serviceCharge,0) serviceCharge, ISNULL(tipAmount,0) tipAmount, cancelReason, cancelledAt, promotionId FROM dbo.Orders WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> order = row(rs);
                order.put("items", getOrderItems(id));
                return order;
            }
        }
    }

    public Map<String, Object> getStoreTaxConfig() throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> cfg = new LinkedHashMap<>();
            cfg.put("vatPercent", stateValue(con, "vatPercent", 8));
            cfg.put("serviceChargePercent", stateValue(con, "serviceChargePercent", 0));
            cfg.put("tipEnabled", stateValue(con, "tipEnabled", 1) > 0);
            return cfg;
        }
    }

    public Map<String, Object> saveStoreTaxConfig(Map<String, Object> data) throws Exception {
        try (Connection con = db.getConnection()) {
            ensureState(con, "vatPercent", 8);
            ensureState(con, "serviceChargePercent", 0);
            ensureState(con, "tipEnabled", 1);
            setStateValue(con, "vatPercent", Math.max(0, Math.min(100, readInt(data.get("vatPercent"), 8))));
            setStateValue(con, "serviceChargePercent", Math.max(0, Math.min(100, readInt(data.get("serviceChargePercent"), 0))));
            setStateValue(con, "tipEnabled", readBoolean(data.get("tipEnabled"), true) ? 1 : 0);
            return getStoreTaxConfig();
        }
    }

    public List<Map<String, Object>> getPromotions() throws Exception {
        String sql = "SELECT id, code, nameVi, nameEn, discountType, discountValue, minSubtotal, maxDiscount, "
                + "startAt, endAt, maxUses, usedCount, active, createdAt FROM dbo.Promotions ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    public Map<String, Object> savePromotion(Map<String, Object> data) throws Exception {
        int id = readInt(data.get("id"), 0);
        String code = readString(data.get("code"), "").trim().toUpperCase(Locale.ROOT);
        if (code.isEmpty()) throw new IllegalArgumentException("Mã khuyến mãi không được trống.");
        String nameVi = readString(data.get("nameVi"), code);
        String nameEn = readString(data.get("nameEn"), code);
        String discountType = readString(data.get("discountType"), "PERCENT").toUpperCase(Locale.ROOT);
        if (!"PERCENT".equals(discountType) && !"AMOUNT".equals(discountType)) {
            throw new IllegalArgumentException("Loại giảm giá phải là PERCENT hoặc AMOUNT.");
        }
        int discountValue = Math.max(0, readInt(data.get("discountValue"), 0));
        int minSubtotal = Math.max(0, readInt(data.get("minSubtotal"), 0));
        int maxDiscount = Math.max(0, readInt(data.get("maxDiscount"), 0));
        int maxUses = Math.max(0, readInt(data.get("maxUses"), 0));
        boolean active = readBoolean(data.get("active"), true);
        String startAt = readString(data.get("startAt"), "");
        String endAt = readString(data.get("endAt"), "");
        try (Connection con = db.getConnection()) {
            if (id > 0) {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE dbo.Promotions SET code=?, nameVi=?, nameEn=?, discountType=?, discountValue=?, "
                                + "minSubtotal=?, maxDiscount=?, startAt=?, endAt=?, maxUses=?, active=? WHERE id=?")) {
                    ps.setString(1, code);
                    ps.setString(2, nameVi);
                    ps.setString(3, nameEn);
                    ps.setString(4, discountType);
                    ps.setInt(5, discountValue);
                    ps.setInt(6, minSubtotal);
                    ps.setInt(7, maxDiscount);
                    if (startAt.isEmpty()) ps.setNull(8, Types.TIMESTAMP); else ps.setString(8, startAt);
                    if (endAt.isEmpty()) ps.setNull(9, Types.TIMESTAMP); else ps.setString(9, endAt);
                    ps.setInt(10, maxUses);
                    ps.setBoolean(11, active);
                    ps.setInt(12, id);
                    if (ps.executeUpdate() == 0) throw new IllegalArgumentException("Không tìm thấy khuyến mãi.");
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO dbo.Promotions (code,nameVi,nameEn,discountType,discountValue,minSubtotal,maxDiscount,startAt,endAt,maxUses,active) "
                                + "VALUES (?,?,?,?,?,?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, code);
                    ps.setString(2, nameVi);
                    ps.setString(3, nameEn);
                    ps.setString(4, discountType);
                    ps.setInt(5, discountValue);
                    ps.setInt(6, minSubtotal);
                    ps.setInt(7, maxDiscount);
                    if (startAt.isEmpty()) ps.setNull(8, Types.TIMESTAMP); else ps.setString(8, startAt);
                    if (endAt.isEmpty()) ps.setNull(9, Types.TIMESTAMP); else ps.setString(9, endAt);
                    ps.setInt(10, maxUses);
                    ps.setBoolean(11, active);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) id = keys.getInt(1);
                    }
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id, code, nameVi, nameEn, discountType, discountValue, minSubtotal, maxDiscount, "
                            + "startAt, endAt, maxUses, usedCount, active, createdAt FROM dbo.Promotions WHERE id=?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next() ? row(rs) : null;
                }
            }
        }
    }

    public void deletePromotion(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Promotions SET active=0 WHERE id=?")) {
            ps.setInt(1, id);
            if (ps.executeUpdate() == 0) throw new IllegalArgumentException("Không tìm thấy khuyến mãi.");
        }
    }

    public Map<String, Object> getOrderInvoice(int id) throws Exception {
        Map<String, Object> order = getOrderById(id);
        if (order == null) return null;
        order.remove("customerPhone");
        return order;
    }

    public Map<String, Object> markInvoicePrinted(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Orders SET invoicePrinted=1 WHERE id=? AND status IN ('Ready','Served')")) {
            ps.setInt(1, id);
            int updated = ps.executeUpdate();
            if (updated == 0) {
                Map<String, Object> order = getOrderById(id);
                if (order == null) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                throw new IllegalArgumentException("Chỉ đánh dấu đã in cho đơn Ready hoặc Served.");
            }
        }
        return getOrderInvoice(id);
    }

    private List<Map<String, Object>> getOrderItems(int orderId) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
                "SELECT id, menuItemId, itemName, itemSize, quantity, price, ISNULL(preparedQty,0) preparedQty FROM dbo.OrderItems WHERE orderId=? ORDER BY id")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    public Map<String, Object> prepareOrderItem(int orderId, int menuItemId, String itemSize, String actorRole, String actorName) throws Exception {
        if (orderId <= 0 || menuItemId <= 0) {
            throw new IllegalArgumentException("Thông tin món pha chế không hợp lệ.");
        }
        String size = itemSize == null ? "" : itemSize.trim();
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                String currentStatus = "";
                int orderNumber = 0;
                String tableName = "";
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT status, orderNumber, tableName FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
                    ps.setInt(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                        currentStatus = rs.getString("status");
                        orderNumber = rs.getInt("orderNumber");
                        tableName = rs.getString("tableName");
                    }
                }
                // Item-level prep starts only after the order has been accepted into Preparing.
                if (!"Preparing".equals(currentStatus)) {
                    throw new IllegalStateException("Chỉ pha được món khi đơn đang pha. Hãy nhận đơn từ Chờ xử lý trước.");
                }

                int itemId = 0;
                int quantity = 0;
                int preparedQty = 0;
                String itemName = "";
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT TOP 1 id, itemName, quantity, ISNULL(preparedQty,0) preparedQty "
                                + "FROM dbo.OrderItems WITH (UPDLOCK, ROWLOCK) "
                                + "WHERE orderId=? AND menuItemId=? AND ISNULL(itemSize,'')=? "
                                + "AND ISNULL(preparedQty,0) < quantity ORDER BY id")) {
                    ps.setInt(1, orderId);
                    ps.setInt(2, menuItemId);
                    ps.setString(3, size);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException("Món này đã pha xong hoặc không có trong đơn.");
                        }
                        itemId = rs.getInt("id");
                        itemName = rs.getString("itemName");
                        quantity = rs.getInt("quantity");
                        preparedQty = rs.getInt("preparedQty");
                    }
                }

                int nextPrepared = preparedQty + 1;
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.OrderItems SET preparedQty=? WHERE id=?")) {
                    ps.setInt(1, nextPrepared);
                    ps.setInt(2, itemId);
                    ps.executeUpdate();
                }

                String nextStatus = currentStatus;
                if (isOrderFullyPrepared(con, orderId)) {
                    int requiredCups = cupCountForOrder(con, orderId);
                    int cups = stateValueForUpdate(con, "cupsAvailable", 0);
                    if (requiredCups > cups) {
                        throw new IllegalArgumentException("Đơn này cần " + requiredCups + " cốc, hiện chỉ còn " + cups + " cốc.");
                    }
                    if (requiredCups > 0) {
                        setStateValue(con, "cupsAvailable", cups - requiredCups);
                    }
                    deductInventoryForOrder(con, orderId);
                    deactivateUnavailableMenuItems(con, null);
                    nextStatus = "Ready";
                }

                if (!nextStatus.equals(currentStatus)) {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status=? WHERE id=? AND status=?")) {
                        ps.setString(1, nextStatus);
                        ps.setInt(2, orderId);
                        ps.setString(3, currentStatus);
                        if (ps.executeUpdate() == 0) {
                            throw new IllegalArgumentException("Đơn vừa được cập nhật bởi thiết bị khác. Vui lòng tải lại.");
                        }
                    }
                    insertSystemLog(con, actorRole, actorName, "ORDER_STATUS",
                            statusLogVi(actorRole, currentStatus, nextStatus, orderNumber, tableName),
                            statusLogEn(actorRole, currentStatus, nextStatus, orderNumber, tableName),
                            orderId);
                } else {
                    insertSystemLog(con, actorRole, actorName, "ITEM_PREPARE",
                            "Pha chế hoàn thành " + itemName + " (" + nextPrepared + "/" + quantity + ") của đơn #" + orderNumber + " lúc " + nowLabelVi(),
                            "Barista prepared " + itemName + " (" + nextPrepared + "/" + quantity + ") for order #" + orderNumber + " at " + nowLabelEn(),
                            orderId);
                }

                con.commit();
                return getOrderById(orderId);
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
    }

    private boolean isOrderFullyPrepared(Connection con, int orderId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM dbo.OrderItems WHERE orderId=? AND ISNULL(preparedQty,0) < quantity")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) == 0;
            }
        }
    }

    private void markOrderItemsFullyPrepared(Connection con, int orderId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.OrderItems SET preparedQty = quantity WHERE orderId=? AND ISNULL(preparedQty,0) < quantity")) {
            ps.setInt(1, orderId);
            ps.executeUpdate();
        }
    }

    public Map<String, Object> getDashboard() throws Exception {
        return getDashboard(null, null);
    }

    public Map<String, Object> getDashboard(String customStartRaw, String customEndRaw) throws Exception {
        Map<String, Object> stats = new LinkedHashMap<>();
        LocalDate customStart = readDate(customStartRaw);
        LocalDate customEnd = readDate(customEndRaw);
        if (customStart != null && customEnd != null && customEnd.isBefore(customStart)) {
            LocalDate tmp = customStart;
            customStart = customEnd;
            customEnd = tmp;
        }
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate yearStart = today.withDayOfYear(1);
        try (Connection con = db.getConnection()) {
            int pending = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Pending'");
            int preparing = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Preparing'");
            int ready = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Ready'");
            int served = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Served'");
            int paid = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Paid'");
            int cleared = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Cleared'");
            stats.put("menuCount", scalar(con, "SELECT COUNT(*) FROM dbo.MenuItems WHERE active=1"));
            stats.put("orderCount", pending + preparing + ready + served + paid + cleared);
            stats.put("pendingOrderCount", pending);
            stats.put("preparingOrderCount", preparing);
            stats.put("readyOrderCount", ready);
            stats.put("unpaidOrderCount", served);
            stats.put("servedOrderCount", paid + cleared);
            stats.put("unclearedOrderCount", paid);
            stats.put("clearedOrderCount", cleared);
            stats.put("activeOrderCount", pending + preparing + ready + served + paid);
            int cancelled = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Cancelled'");
            int refunded = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Refunded'");
            stats.put("cancelledOrderCount", cancelled);
            stats.put("refundedOrderCount", refunded);
            stats.put("cancelledToday", scalarBetween(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status='Cancelled' AND cancelledAt >= ? AND cancelledAt < ?", today, tomorrow));
            stats.put("refundedToday", scalarBetween(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status='Refunded' AND cancelledAt >= ? AND cancelledAt < ?", today, tomorrow));
            stats.put("taxToday", scalarBetween(con, "SELECT ISNULL(SUM(ISNULL(taxAmount,0)),0) FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt) >= ? AND ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt) < ?", today, tomorrow));
            stats.put("revenueBeforeTaxToday", scalarBetween(con, "SELECT ISNULL(SUM(total - ISNULL(taxAmount,0)),0) FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt) >= ? AND ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt) < ?", today, tomorrow));
            stats.put("revenue", scalar(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN " + ST_REVENUE + ""));
            // Ngày doanh thu theo lúc thu tiền (Payments.paidAt), fallback createdAt cho dữ liệu seed cũ.
            String paidAtExpr = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt)";
            stats.put("revenueToday", scalarBetween(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + paidAtExpr + " >= ? AND " + paidAtExpr + " < ?", today, tomorrow));
            stats.put("revenueMonth", scalarBetween(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + paidAtExpr + " >= ? AND " + paidAtExpr + " < ?", monthStart, tomorrow));
            stats.put("revenueYear", scalarBetween(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + paidAtExpr + " >= ? AND " + paidAtExpr + " < ?", yearStart, tomorrow));
            stats.put("unpaidRevenue", scalar(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status = 'Served'"));
            stats.put("openRevenue", scalar(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Pending','Preparing','Ready')"));
            // openRevenue stays barista-pipeline only; Cancelled/Refunded excluded by omission.
            stats.put("soldItemCount", scalar(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + ""));
            String oiPaidAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=o.id), o.createdAt)";
            stats.put("soldItemToday", scalarBetween(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + " AND " + oiPaidAt + " >= ? AND " + oiPaidAt + " < ?", today, tomorrow));
            stats.put("soldItemMonth", scalarBetween(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + " AND " + oiPaidAt + " >= ? AND " + oiPaidAt + " < ?", monthStart, tomorrow));
            stats.put("soldItemYear", scalarBetween(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + " AND " + oiPaidAt + " >= ? AND " + oiPaidAt + " < ?", yearStart, tomorrow));
            stats.put("bestSeller", firstRow(con, "SELECT TOP 1 oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + " GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC"));
            stats.put("topProducts", queryRows(con, "SELECT TOP 8 oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + " GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC"));
            stats.put("topProductsByRange", getTopProductsByRangeMap(con, customStart, customEnd));
            stats.put("rangeDetails", getRangeDetailsMap(con, customStart, customEnd));
            stats.put("revenueSeries", getRevenueSeriesMap(con, customStart, customEnd));
            stats.put("lowStockItems", getLowStockIngredients(con));
            stats.put("today", today.toString());
            if (customStart != null && customEnd != null) {
                stats.put("customStart", customStart.toString());
                stats.put("customEnd", customEnd.toString());
            }
        }
        return stats;
    }

    private int scalar(String sql) throws Exception {
        try (Connection con = db.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private int scalar(Connection con, String sql) throws Exception {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private int scalarBetween(Connection con, String sql, LocalDate start, LocalDate endExclusive) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private Map<String, Object> firstRow(String sql) throws Exception {
        List<Map<String, Object>> list = queryRows(sql);
        return list.isEmpty() ? new LinkedHashMap<>() : list.get(0);
    }

    private Map<String, Object> firstRow(Connection con, String sql) throws Exception {
        List<Map<String, Object>> list = queryRows(con, sql);
        return list.isEmpty() ? new LinkedHashMap<>() : list.get(0);
    }

    private List<Map<String, Object>> queryRows(String sql) throws Exception {
        try (Connection con = db.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            return rows(rs);
        }
    }

    private List<Map<String, Object>> queryRows(Connection con, String sql) throws Exception {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            return rows(rs);
        }
    }

    private Map<String, Object> getRevenueSeriesMap(Connection con, LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(con, firstMonth);

        Map<String, Object> series = new LinkedHashMap<>();
        series.put("day", revenueByHour(con, today, tomorrow));
        series.put("week", revenueByDay(con, today.minusDays(6), tomorrow));
        series.put("month", revenueByDay(con, today.minusDays(29), tomorrow));
        series.put("year", revenueByMonth(con, firstMonth, nextMonth));
        series.put("all", revenueByMonth(con, allFirstMonth, nextMonth));
        if (customStart != null && customEnd != null) {
            series.put("custom", revenueCustom(con, customStart, customEnd.plusDays(1)));
        }
        return series;
    }

    private Map<String, Object> getTopProductsByRangeMap(Connection con, LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(con, firstMonth);

        Map<String, Object> products = new LinkedHashMap<>();
        products.put("day", topProductsBetween(con, today, tomorrow, 8));
        products.put("week", topProductsBetween(con, today.minusDays(6), tomorrow, 8));
        products.put("month", topProductsBetween(con, today.minusDays(29), tomorrow, 8));
        products.put("year", topProductsBetween(con, firstMonth.atDay(1), nextMonth.atDay(1), 8));
        products.put("all", topProductsBetween(con, allFirstMonth.atDay(1), nextMonth.atDay(1), 8));
        if (customStart != null && customEnd != null) {
            products.put("custom", topProductsBetween(con, customStart, customEnd.plusDays(1), 8));
        }
        return products;
    }

    private Map<String, Object> getRangeDetailsMap(Connection con, LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(con, firstMonth);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("day", rangeDetailBetween(con, today, tomorrow));
        details.put("week", rangeDetailBetween(con, today.minusDays(6), tomorrow));
        details.put("month", rangeDetailBetween(con, today.minusDays(29), tomorrow));
        details.put("year", rangeDetailBetween(con, firstMonth.atDay(1), nextMonth.atDay(1)));
        details.put("all", rangeDetailBetween(con, allFirstMonth.atDay(1), nextMonth.atDay(1)));
        if (customStart != null && customEnd != null) {
            details.put("custom", rangeDetailBetween(con, customStart, customEnd.plusDays(1)));
        }
        return details;
    }

    private Map<String, Object> rangeDetailBetween(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Object> detail = new LinkedHashMap<>();
        String saleAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt)";
        String orderSql = "SELECT COUNT(*) paidOrders, ISNULL(SUM(total),0) revenue FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + saleAt + " >= ? AND " + saleAt + " < ?";
        try (PreparedStatement ps = con.prepareStatement(orderSql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    detail.put("paidOrders", rs.getInt("paidOrders"));
                    detail.put("revenue", rs.getInt("revenue"));
                }
            }
        }
        String oiSaleAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=o.id), o.createdAt)";
        String itemSql = "SELECT ISNULL(SUM(oi.quantity),0) soldProducts FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN " + ST_REVENUE + " AND " + oiSaleAt + " >= ? AND " + oiSaleAt + " < ?";
        try (PreparedStatement ps = con.prepareStatement(itemSql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) detail.put("soldProducts", rs.getInt("soldProducts"));
            }
        }
        detail.putIfAbsent("paidOrders", 0);
        detail.putIfAbsent("revenue", 0);
        detail.putIfAbsent("soldProducts", 0);
        return detail;
    }

    private List<Map<String, Object>> revenueCustom(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        long days = ChronoUnit.DAYS.between(start, endExclusive);
        if (days <= 1) return revenueByHour(con, start, endExclusive);
        if (days <= 120) return revenueByDay(con, start, endExclusive);
        return revenueByMonth(con, YearMonth.from(start), YearMonth.from(endExclusive.minusDays(1)).plusMonths(1));
    }

    private YearMonth firstPaidMonth(Connection con, YearMonth fallback) throws Exception {
        String sql = "SELECT MIN(CONVERT(date, createdAt)) firstDate FROM dbo.Orders WHERE status IN " + ST_REVENUE + "";
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                LocalDate date = readDate(rs.getObject("firstDate"));
                if (date != null) return YearMonth.from(date);
            }
        }
        return fallback;
    }

    private List<Map<String, Object>> revenueByHour(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (int hour = 0; hour < 24; hour++) {
            values.put(String.format(Locale.ROOT, "%02d:00", hour), 0);
        }
        String saleAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt)";
        String sql = "SELECT DATEPART(hour, " + saleAt + ") saleHour, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + saleAt + " >= ? AND " + saleAt + " < ? "
                + "GROUP BY DATEPART(hour, " + saleAt + ")";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    values.put(String.format(Locale.ROOT, "%02d:00", rs.getInt("saleHour")), rs.getInt("revenue"));
                }
            }
        }
        return seriesRows(values);
    }

    private List<Map<String, Object>> revenueByDay(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (LocalDate day = start; day.isBefore(endExclusive); day = day.plusDays(1)) {
            values.put(day.toString(), 0);
        }
        String saleAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt)";
        String sql = "SELECT CONVERT(date, " + saleAt + ") saleDate, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + saleAt + " >= ? AND " + saleAt + " < ? "
                + "GROUP BY CONVERT(date, " + saleAt + ")";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalDate date = rs.getDate("saleDate").toLocalDate();
                    if (values.containsKey(date.toString())) values.put(date.toString(), rs.getInt("revenue"));
                }
            }
        }
        return seriesRows(values);
    }

    private List<Map<String, Object>> revenueByMonth(Connection con, YearMonth start, YearMonth endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (YearMonth month = start; month.isBefore(endExclusive); month = month.plusMonths(1)) {
            values.put(month.toString(), 0);
        }
        String saleAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=dbo.Orders.id), createdAt)";
        String sql = "SELECT CONVERT(char(7), " + saleAt + ", 120) saleMonth, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN " + ST_REVENUE + " AND " + saleAt + " >= ? AND " + saleAt + " < ? "
                + "GROUP BY CONVERT(char(7), " + saleAt + ", 120)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atDay(1).atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atDay(1).atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String month = rs.getString("saleMonth");
                    if (values.containsKey(month)) values.put(month, rs.getInt("revenue"));
                }
            }
        }
        return seriesRows(values);
    }

    private List<Map<String, Object>> topProductsBetween(Connection con, LocalDate start, LocalDate endExclusive, int limit) throws Exception {
        String oiSaleAt = "ISNULL((SELECT TOP 1 p.paidAt FROM dbo.Payments p WHERE p.orderId=o.id), o.createdAt)";
        String sql = "SELECT TOP " + Math.max(1, limit) + " oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue "
                + "FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId "
                + "WHERE o.status IN " + ST_REVENUE + " AND " + oiSaleAt + " >= ? AND " + oiSaleAt + " < ? "
                + "GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    private List<Map<String, Object>> seriesRows(Map<String, Integer> values) {
        List<Map<String, Object>> series = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : values.entrySet()) {
            Map<String, Object> point = new LinkedHashMap<>();
            point.put("label", entry.getKey());
            point.put("revenue", entry.getValue());
            series.add(point);
        }
        return series;
    }

    private String weekKey(LocalDate date) {
        return date.minusDays(date.getDayOfWeek().getValue() - 1L).toString();
    }

    private LocalDate readDate(Object value) {
        if (value instanceof java.sql.Date) return ((java.sql.Date) value).toLocalDate();
        if (value == null) return null;
        try {
            return LocalDate.parse(String.valueOf(value).substring(0, 10));
        } catch (Exception e) {
            return null;
        }
    }

    private List<Map<String, Object>> rows(ResultSet rs) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        while (rs.next()) list.add(row(rs));
        return list;
    }

    private Map<String, Object> row(ResultSet rs) throws Exception {
        Map<String, Object> map = new LinkedHashMap<>();
        ResultSetMetaData md = rs.getMetaData();
        for (int i = 1; i <= md.getColumnCount(); i++) {
            Object val = rs.getObject(i);
            if (val instanceof java.sql.Timestamp) val = val.toString();
            map.put(md.getColumnLabel(i), val);
        }
        return map;
    }

    private String readString(Object value, String fallback) {
        return value == null ? fallback : String.valueOf(value).trim();
    }

    private int readInt(Object value, int fallback) {
        if (value instanceof Number) return ((Number) value).intValue();
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception e) {
            return fallback;
        }
    }

    private List<Integer> cleanIds(List<Integer> ids) {
        List<Integer> clean = new ArrayList<>();
        if (ids == null) return clean;
        for (Integer id : ids) {
            if (id != null && id > 0 && !clean.contains(id)) clean.add(id);
            if (clean.size() >= 50) break;
        }
        return clean;
    }

    private String placeholders(int count) {
        StringJoiner joiner = new StringJoiner(",");
        for (int i = 0; i < count; i++) joiner.add("?");
        return joiner.toString();
    }

    private void bindIds(PreparedStatement ps, List<Integer> ids) throws Exception {
        for (int i = 0; i < ids.size(); i++) {
            ps.setInt(i + 1, ids.get(i));
        }
    }

    private String limitNote(String note) {
        String clean = readString(note, "");
        return clean.length() > 255 ? clean.substring(0, 255) : clean;
    }

    private String normalizeSize(Map<String, Object> menu, String size) {
        List<Map<String, Object>> sizes = menuSizes(menu);
        if (sizes.isEmpty()) return "";
        String normalized = size == null ? "" : size.trim().toUpperCase(Locale.ROOT);
        for (Map<String, Object> row : sizes) {
            String name = readString(row.get("sizeName"), "").toUpperCase(Locale.ROOT);
            if (name.equals(normalized)) return name;
        }
        return readString(sizes.get(0).get("sizeName"), "S").toUpperCase(Locale.ROOT);
    }

    private boolean isDrink(Map<String, Object> menu) {
        return isDrinkCategory(readString(menu.get("category"), ""));
    }

    private boolean isDrinkCategory(String category) {
        String folded = fold(category);
        return !(folded.equals("food") || folded.equals("pastry") || folded.contains("banh"));
    }

    private int priceForSize(Map<String, Object> menu, String size) {
        int base = readInt(menu.get("price"), 0);
        for (Map<String, Object> row : menuSizes(menu)) {
            if (readString(row.get("sizeName"), "").equalsIgnoreCase(readString(size, ""))) {
                return base + readInt(row.get("extraPrice"), 0);
            }
        }
        return base;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> menuSizes(Map<String, Object> menu) {
        Object sizes = menu.get("sizes");
        if (sizes instanceof List<?>) return (List<Map<String, Object>>) sizes;
        return new ArrayList<>();
    }

    private boolean readBoolean(Object value, boolean fallback) {
        if (value instanceof Boolean) return (Boolean) value;
        if (value instanceof Number) return ((Number) value).intValue() != 0;
        if (value == null) return fallback;
        String text = String.valueOf(value).trim();
        if ("1".equals(text) || "true".equalsIgnoreCase(text)) return true;
        if ("0".equals(text) || "false".equalsIgnoreCase(text)) return false;
        return Boolean.parseBoolean(text);
    }
}
