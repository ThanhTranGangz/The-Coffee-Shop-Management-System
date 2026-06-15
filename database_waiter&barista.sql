-- =======================================================
-- CSMS - Update script: thêm nhân viên Waiter và Barista
-- Chạy nhiều lần không lỗi, chỉ thêm nếu chưa có
-- =======================================================
USE CSMS_DB;
GO

-- 1. Thêm cột WaiterID và BaristaID vào Orders nếu chưa có
IF COL_LENGTH('Orders', 'WaiterID') IS NULL
BEGIN
    ALTER TABLE [Orders] ADD WaiterID INT NULL;
    ALTER TABLE [Orders] ADD CONSTRAINT FK_Orders_Waiter FOREIGN KEY (WaiterID) REFERENCES [Staff](StaffID);
END
GO

IF COL_LENGTH('Orders', 'BaristaID') IS NULL
BEGIN
    ALTER TABLE [Orders] ADD BaristaID INT NULL;
    ALTER TABLE [Orders] ADD CONSTRAINT FK_Orders_Barista FOREIGN KEY (BaristaID) REFERENCES [Staff](StaffID);
END
GO

-- 2. Seed data cho Staff: thêm demo Waiter và Barista nếu chưa có
IF NOT EXISTS (SELECT 1 FROM [Staff] WHERE Username = 'waiter1')
BEGIN
    INSERT INTO [Staff] (Username, [Password], PIN_Code, FullName, RoleID, IsActive)
    VALUES ('waiter1',
            '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', -- password: 123456
            '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', -- pin: 1234
            N'Nguyễn Văn A (Waiter)',
            (SELECT RoleID FROM [Role] WHERE RoleName = 'WAITER'),
            1);
END
GO

IF NOT EXISTS (SELECT 1 FROM [Staff] WHERE Username = 'barista1')
BEGIN
    INSERT INTO [Staff] (Username, [Password], PIN_Code, FullName, RoleID, IsActive)
    VALUES ('barista1',
            '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', -- password: 123456
            '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', -- pin: 1234
            N'Trần Thị B (Barista)',
            (SELECT RoleID FROM [Role] WHERE RoleName = 'BARISTA'),
            1);
END
GO

PRINT 'database_update_waiter_barista.sql DONE';
GO
