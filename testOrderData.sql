-- =======================================================
-- CSMS - Demo Order Data for Reports
-- Tao du lieu don hang demo de bao cao co noi dung hien thi.
-- Chay SAU create_table.sql, testData.sql, va database_update.sql
-- Run: sqlcmd -S localhost -U sa -P 123 -d CSMS_DB -i testOrderData.sql -f 65001
-- =======================================================
USE CSMS_DB;
GO

-- Chi chen khi chua co don hang nao
IF NOT EXISTS (SELECT 1 FROM [Orders])
BEGIN
    PRINT 'Inserting demo order data...';

    -- ==========================================
    -- Tao 25 don hang trong 15 ngay gan day
    -- CashierID = 1 (admin, MANAGER)
    -- MemberID = 1 (Nguyen Minh Anh)
    -- ==========================================

    -- Don 1: Hom nay, POS, CASH, khach le
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME)), 74000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 1, 1, NULL, NULL);

    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (SCOPE_IDENTITY(), 1, 1, 25000, NULL, 'SERVED'),
           (SCOPE_IDENTITY(), 8, 1, 45000, NULL, 'SERVED');

    -- Don 2: Hom nay, QR, VIETQR, thanh vien
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 9, CAST(CAST(GETDATE() AS DATE) AS DATETIME)), 125000, 5000, 'VIETQR', 'TXN-TODAY-001', 'QR', 'COMPLETED', 'PAID', 2, 1, 1, 1);

    DECLARE @oid2 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid2, 3, 2, 32000, NULL, 'SERVED'),
           (@oid2, 7, 1, 45000, NULL, 'SERVED'),
           (@oid2, 17, 1, 30000, NULL, 'SERVED');

    -- Don 3: Hom nay, WAITER, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME)), 83000, 0, 'CASH', NULL, 'WAITER', 'COMPLETED', 'PAID', 3, 1, NULL, NULL);

    DECLARE @oid3 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid3, 2, 1, 29000, N'Ít đường', 'SERVED'),
           (@oid3, 11, 1, 38000, NULL, 'SERVED'),
           (@oid3, 17, 1, 30000, NULL, 'SERVED');

    -- Don 4: Hom qua, POS, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 14, CAST(DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) AS DATETIME)), 190000, 0, 'VIETQR', 'TXN-Y1-001', 'POS', 'COMPLETED', 'PAID', 1, 1, 1, NULL);

    DECLARE @oid4 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid4, 5, 2, 40000, NULL, 'SERVED'),
           (@oid4, 6, 1, 45000, NULL, 'SERVED'),
           (@oid4, 13, 1, 50000, NULL, 'SERVED'),
           (@oid4, 18, 1, 29000, NULL, 'SERVED');

    -- Don 5: Hom qua, QR, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 16, CAST(DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) AS DATETIME)), 67000, 0, 'CASH', NULL, 'QR', 'COMPLETED', 'PAID', 4, 1, NULL, NULL);

    DECLARE @oid5 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid5, 1, 1, 25000, NULL, 'SERVED'),
           (@oid5, 15, 1, 42000, NULL, 'SERVED');

    -- Don 6: 2 ngay truoc, POS, CASH, thanh vien
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 9, CAST(DATEADD(DAY, -2, CAST(GETDATE() AS DATE)) AS DATETIME)), 145000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 2, 1, 1, NULL);

    DECLARE @oid6 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid6, 4, 2, 35000, NULL, 'SERVED'),
           (@oid6, 8, 1, 45000, NULL, 'SERVED'),
           (@oid6, 17, 1, 30000, NULL, 'SERVED');

    -- Don 7: 2 ngay truoc, WAITER, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 11, CAST(DATEADD(DAY, -2, CAST(GETDATE() AS DATE)) AS DATETIME)), 97000, 0, 'VIETQR', 'TXN-D2-001', 'WAITER', 'COMPLETED', 'PAID', 5, 1, NULL, NULL);

    DECLARE @oid7 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid7, 10, 1, 35000, NULL, 'SERVED'),
           (@oid7, 12, 1, 40000, NULL, 'SERVED'),
           (@oid7, 18, 1, 29000, NULL, 'SERVED');

    -- Don 8: 3 ngay truoc, QR, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 8, CAST(DATEADD(DAY, -3, CAST(GETDATE() AS DATE)) AS DATETIME)), 210000, 0, 'VIETQR', 'TXN-D3-001', 'QR', 'COMPLETED', 'PAID', 1, 1, 1, NULL);

    DECLARE @oid8 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid8, 6, 2, 45000, NULL, 'SERVED'),
           (@oid8, 7, 2, 45000, NULL, 'SERVED'),
           (@oid8, 17, 1, 30000, NULL, 'SERVED');

    -- Don 9: 3 ngay truoc, POS, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 15, CAST(DATEADD(DAY, -3, CAST(GETDATE() AS DATE)) AS DATETIME)), 54000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 3, 1, NULL, NULL);

    DECLARE @oid9 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid9, 1, 1, 25000, NULL, 'SERVED'),
           (@oid9, 2, 1, 29000, NULL, 'SERVED');

    -- Don 10: 4 ngay truoc, POS, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 10, CAST(DATEADD(DAY, -4, CAST(GETDATE() AS DATE)) AS DATETIME)), 129000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 1, 1, NULL, NULL);

    DECLARE @oid10 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid10, 3, 1, 32000, NULL, 'SERVED'),
           (@oid10, 8, 1, 45000, NULL, 'SERVED'),
           (@oid10, 14, 1, 48000, NULL, 'SERVED');

    -- Don 11: 5 ngay truoc, QR, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 13, CAST(DATEADD(DAY, -5, CAST(GETDATE() AS DATE)) AS DATETIME)), 170000, 5000, 'VIETQR', 'TXN-D5-001', 'QR', 'COMPLETED', 'PAID', 2, 1, 1, 1);

    DECLARE @oid11 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid11, 5, 2, 40000, NULL, 'SERVED'),
           (@oid11, 13, 1, 50000, NULL, 'SERVED'),
           (@oid11, 11, 1, 38000, NULL, 'SERVED');

    -- Don 12: 5 ngay truoc, WAITER, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 17, CAST(DATEADD(DAY, -5, CAST(GETDATE() AS DATE)) AS DATETIME)), 64000, 0, 'CASH', NULL, 'WAITER', 'COMPLETED', 'PAID', 6, 1, NULL, NULL);

    DECLARE @oid12 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid12, 1, 1, 25000, NULL, 'SERVED'),
           (@oid12, 10, 1, 35000, NULL, 'SERVED');

    -- Don 13: 7 ngay truoc, POS, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 9, CAST(DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) AS DATETIME)), 250000, 0, 'VIETQR', 'TXN-D7-001', 'POS', 'COMPLETED', 'PAID', 1, 1, 1, NULL);

    DECLARE @oid13 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid13, 6, 2, 45000, NULL, 'SERVED'),
           (@oid13, 7, 2, 45000, NULL, 'SERVED'),
           (@oid13, 13, 1, 50000, NULL, 'SERVED'),
           (@oid13, 17, 1, 30000, NULL, 'SERVED');

    -- Don 14: 7 ngay truoc, QR, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 11, CAST(DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) AS DATETIME)), 77000, 0, 'CASH', NULL, 'QR', 'COMPLETED', 'PAID', 3, 1, NULL, NULL);

    DECLARE @oid14 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid14, 2, 1, 29000, NULL, 'SERVED'),
           (@oid14, 14, 1, 48000, NULL, 'SERVED');

    -- Don 15: 10 ngay truoc, POS, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 14, CAST(DATEADD(DAY, -10, CAST(GETDATE() AS DATE)) AS DATETIME)), 155000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 4, 1, NULL, NULL);

    DECLARE @oid15 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid15, 4, 1, 35000, NULL, 'SERVED'),
           (@oid15, 5, 1, 40000, NULL, 'SERVED'),
           (@oid15, 13, 1, 50000, NULL, 'SERVED'),
           (@oid15, 17, 1, 30000, NULL, 'SERVED');

    -- Don 16: 10 ngay truoc, WAITER, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 16, CAST(DATEADD(DAY, -10, CAST(GETDATE() AS DATE)) AS DATETIME)), 90000, 0, 'VIETQR', 'TXN-D10-001', 'WAITER', 'COMPLETED', 'PAID', 5, 1, 1, NULL);

    DECLARE @oid16 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid16, 6, 1, 45000, NULL, 'SERVED'),
           (@oid16, 8, 1, 45000, NULL, 'SERVED');

    -- Don 17: 12 ngay truoc, QR, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 10, CAST(DATEADD(DAY, -12, CAST(GETDATE() AS DATE)) AS DATETIME)), 138000, 0, 'VIETQR', 'TXN-D12-001', 'QR', 'COMPLETED', 'PAID', 2, 1, NULL, NULL);

    DECLARE @oid17 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid17, 3, 1, 32000, NULL, 'SERVED'),
           (@oid17, 12, 1, 40000, NULL, 'SERVED'),
           (@oid17, 11, 1, 38000, NULL, 'SERVED'),
           (@oid17, 18, 1, 29000, NULL, 'SERVED');

    -- Don 18: 14 ngay truoc, POS, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 8, CAST(DATEADD(DAY, -14, CAST(GETDATE() AS DATE)) AS DATETIME)), 95000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 1, 1, NULL, NULL);

    DECLARE @oid18 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid18, 7, 1, 45000, NULL, 'SERVED'),
           (@oid18, 13, 1, 50000, NULL, 'SERVED');

    -- Don 19: 14 ngay truoc, QR, VIETQR, thanh vien
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 12, CAST(DATEADD(DAY, -14, CAST(GETDATE() AS DATE)) AS DATETIME)), 185000, 0, 'VIETQR', 'TXN-D14-001', 'QR', 'COMPLETED', 'PAID', 3, 1, 1, NULL);

    DECLARE @oid19 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid19, 6, 2, 45000, NULL, 'SERVED'),
           (@oid19, 5, 1, 40000, NULL, 'SERVED'),
           (@oid19, 8, 1, 45000, NULL, 'SERVED'),
           (@oid19, 17, 1, 30000, NULL, 'SERVED');

    -- Don 20: 18 ngay truoc, POS, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 15, CAST(DATEADD(DAY, -18, CAST(GETDATE() AS DATE)) AS DATETIME)), 70000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 4, 1, NULL, NULL);

    DECLARE @oid20 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid20, 4, 1, 35000, NULL, 'SERVED'),
           (@oid20, 10, 1, 35000, NULL, 'SERVED');

    -- Don 21: 20 ngay truoc, WAITER, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 9, CAST(DATEADD(DAY, -20, CAST(GETDATE() AS DATE)) AS DATETIME)), 122000, 0, 'VIETQR', 'TXN-D20-001', 'WAITER', 'COMPLETED', 'PAID', 6, 1, NULL, NULL);

    DECLARE @oid21 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid21, 3, 2, 32000, NULL, 'SERVED'),
           (@oid21, 14, 1, 48000, NULL, 'SERVED'),
           (@oid21, 17, 1, 30000, NULL, 'SERVED');

    -- Don 22: 22 ngay truoc, QR, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 11, CAST(DATEADD(DAY, -22, CAST(GETDATE() AS DATE)) AS DATETIME)), 87000, 0, 'CASH', NULL, 'QR', 'COMPLETED', 'PAID', 2, 1, 1, NULL);

    DECLARE @oid22 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid22, 2, 1, 29000, NULL, 'SERVED'),
           (@oid22, 11, 1, 38000, NULL, 'SERVED'),
           (@oid22, 17, 1, 30000, NULL, 'SERVED');

    -- Don 23: 25 ngay truoc, POS, VIETQR
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 14, CAST(DATEADD(DAY, -25, CAST(GETDATE() AS DATE)) AS DATETIME)), 220000, 0, 'VIETQR', 'TXN-D25-001', 'POS', 'COMPLETED', 'PAID', 1, 1, 1, NULL);

    DECLARE @oid23 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid23, 5, 2, 40000, NULL, 'SERVED'),
           (@oid23, 6, 1, 45000, NULL, 'SERVED'),
           (@oid23, 7, 1, 45000, NULL, 'SERVED'),
           (@oid23, 13, 1, 50000, NULL, 'SERVED');

    -- Don 24: 27 ngay truoc, WAITER, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 16, CAST(DATEADD(DAY, -27, CAST(GETDATE() AS DATE)) AS DATETIME)), 58000, 0, 'CASH', NULL, 'WAITER', 'COMPLETED', 'PAID', 5, 1, NULL, NULL);

    DECLARE @oid24 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid24, 1, 1, 25000, NULL, 'SERVED'),
           (@oid24, 18, 1, 29000, NULL, 'SERVED');

    -- Don 25: 29 ngay truoc, POS, CASH
    INSERT INTO [Orders] (OrderDate, TotalAmount, DiscountAmount, PaymentMethod, TransactionID, OrderSource, OrderStatus, PaymentStatus, TableID, CashierID, MemberID, VoucherID)
    VALUES (DATEADD(HOUR, 10, CAST(DATEADD(DAY, -29, CAST(GETDATE() AS DATE)) AS DATETIME)), 115000, 0, 'CASH', NULL, 'POS', 'COMPLETED', 'PAID', 3, 1, NULL, NULL);

    DECLARE @oid25 INT = SCOPE_IDENTITY();
    INSERT INTO [OrderDetail] (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus)
    VALUES (@oid25, 4, 1, 35000, NULL, 'SERVED'),
           (@oid25, 8, 1, 45000, NULL, 'SERVED'),
           (@oid25, 10, 1, 35000, NULL, 'SERVED');

    PRINT 'Inserted 25 demo orders successfully!';
END
ELSE
BEGIN
    PRINT 'Orders already exist, skipping demo order data.';
END
GO

PRINT 'testOrderData.sql DONE';
GO
