USE CoffeeShopLite;
GO

-- 1. Add assignedRole if missing
IF COL_LENGTH('dbo.Shifts','assignedRole') IS NULL
ALTER TABLE dbo.Shifts ADD assignedRole VARCHAR(20) NULL;
GO

-- 2. Clear old data to avoid inconsistencies
DELETE FROM dbo.Shifts;
DELETE FROM dbo.Staff;
GO

-- 3. Insert 10 dummy staff members (role = 'staff')
INSERT INTO dbo.Staff (id, name, role, pin, shift, active, username, password, status, overtime) VALUES
(1, N'Phạm Minh Tuấn', 'staff', '1111', '', 1, 'tuanpm', '123', 'Active', 1),
(2, N'Lê Quốc Bảo', 'staff', '1111', '', 1, 'baolq', '123', 'Active', 0),
(3, N'Nguyễn Thu Trà', 'staff', '1111', '', 1, 'trant', '123', 'Active', 0),
(4, N'Đặng Văn Phong', 'staff', '1111', '', 1, 'phongdv', '123', 'Active', 1),
(5, N'Trần Tuấn Dũng', 'staff', '1111', '', 1, 'dungtt', '123', 'Active', 0),
(6, N'Lý Thùy Linh', 'staff', '1111', '', 1, 'linhlt', '123', 'Active', 0),
(7, N'Bùi Quang Huy', 'staff', '1111', '', 1, 'huybq', '123', 'Active', 0),
(8, N'Võ Tấn Phát', 'staff', '1111', '', 1, 'phatvt', '123', 'Active', 0),
(9, N'Hồ Ngọc Mai', 'staff', '1111', '', 1, 'maihn', '123', 'Active', 1),
(10, N'Đỗ Minh Châu', 'staff', '1111', '', 1, 'chaudm', '123', 'Active', 0);
GO

-- 4. Insert dummy shifts for today and tomorrow
-- We need Barista, Cashier, Waiter for Ca Sáng, Ca Chiều, Ca Tối
INSERT INTO dbo.Shifts (id, staffId, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
-- 2026-07-17 Ca Sáng
('s1_b', 1, '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã phân công', '', 'Barista'),
('s1_c', 2, '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã phân công', '', 'Cashier'),
('s1_w1', 3, '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã phân công', '', 'Waiter'),
('s1_w2', 4, '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã phân công', '', 'Waiter'),

-- 2026-07-17 Ca Chiều
('s2_b', 5, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', '', 'Barista'),
('s2_c', 6, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', '', 'Cashier'),
('s2_w', 7, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', '', 'Waiter'),

-- 2026-07-18 Ca Tối (missing Waiter intentionally for UI testing)
('s3_b', 8, '2026-07-18', N'Ca Tối', '18:00 - 23:00', N'Đã phân công', '', 'Barista'),
('s3_c', 9, '2026-07-18', N'Ca Tối', '18:00 - 23:00', N'Đã phân công', '', 'Cashier');
GO
