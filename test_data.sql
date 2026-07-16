USE CoffeeShopLite;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Staff)
BEGIN
    INSERT INTO dbo.Staff (id, name, role, pin, shift, active, username, password, status, overtime) VALUES
    (1, N'Nguyễn Văn A', 'barista', '1111', N'Sáng (06:00 - 12:00)', 1, 'nva', '123', 'Active', 0),
    (2, N'Trần Thị B', 'cashier', '2222', N'Chiều (12:00 - 18:00)', 1, 'ttb', '123', 'Active', 0),
    (3, N'Lê Văn C', 'runner', '3333', N'Tối (18:00 - 23:00)', 1, 'lvc', '123', 'Active', 1),
    (4, N'Phạm Thị D', 'barista', '4444', N'Sáng (06:00 - 12:00)', 1, 'ptd', '123', 'Inactive', 0),
    (5, N'Hoàng Văn E', 'manager', '8888', N'Toàn thời gian', 1, 'admin2', '123', 'Active', 0);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Shifts)
BEGIN
    INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes) VALUES
    ('s1', 1, N'Nguyễn Văn A', '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã phân công', N'Đi đúng giờ'),
    ('s2', 2, N'Trần Thị B', '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', ''),
    ('s3', 3, N'Lê Văn C', '2026-07-17', N'Ca Tối', '18:00 - 23:00', N'Đã phân công', N'Tăng ca 1 tiếng'),
    ('s4', 1, N'Nguyễn Văn A', '2026-07-18', N'Ca Sáng', '06:00 - 12:00', N'Xin nghỉ', N'Báo ốm'),
    ('s5', 4, N'Phạm Thị D', '2026-07-18', N'Ca Sáng', '06:00 - 12:00', N'Đã phân công', N'Làm thay A');
END
GO


-- =========================================
-- MOCK SHIFTS DATA
-- =========================================

-- Past Week: 2026-07-06 to 2026-07-12
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
('mock-1', 1, N'Phạm Minh Tuấn', '2026-07-06', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-2', 2, N'Lê Quốc Bảo', '2026-07-06', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-3', 3, N'Nguyễn Thu Trà', '2026-07-06', N'Ca Chiều', '12:00 - 18:00', N'Vắng', N'Bệnh', 'Waiter'),
('mock-4', 4, N'Đặng Văn Phong', '2026-07-08', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-5', 5, N'Trần Tuấn Dũng', '2026-07-08', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-6', 6, N'Lý Thùy Linh', '2026-07-08', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-7', 7, N'Bùi Quang Huy', '2026-07-10', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-8', 8, N'Võ Tấn Phát', '2026-07-10', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-9', 9, N'Hồ Ngọc Mai', '2026-07-10', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-10', 10, N'Đỗ Minh Châu', '2026-07-12', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-11', 1, N'Phạm Minh Tuấn', '2026-07-12', N'Ca Chiều', '12:00 - 18:00', N'Vắng', '', 'Barista'),

-- Next Week: 2026-07-20 to 2026-07-26
('mock-12', 2, N'Lê Quốc Bảo', '2026-07-21', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-13', 3, N'Nguyễn Thu Trà', '2026-07-21', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-14', 4, N'Đặng Văn Phong', '2026-07-21', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Barista'),
('mock-15', 5, N'Trần Tuấn Dũng', '2026-07-23', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Barista'),
('mock-16', 6, N'Lý Thùy Linh', '2026-07-23', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-17', 7, N'Bùi Quang Huy', '2026-07-23', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-18', 8, N'Võ Tấn Phát', '2026-07-25', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Barista'),
('mock-19', 9, N'Hồ Ngọc Mai', '2026-07-25', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-20', 10, N'Đỗ Minh Châu', '2026-07-25', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Waiter');
DELETE FROM dbo.Shifts WHERE shiftDate >= '2026-07-06' AND shiftDate <= '2026-07-12';
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
('mock-full-100', 1, N'Phạm Minh Tuấn', '2026-07-06', N'Ca Sáng', '06:00 - 12:00', N'Vắng', '', 'Barista'),
('mock-full-101', 2, N'Lê Quốc Bảo', '2026-07-06', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-102', 3, N'Nguyễn Thu Trà', '2026-07-06', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-full-103', 4, N'Đặng Văn Phong', '2026-07-06', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-full-104', 5, N'Trần Tuấn Dũng', '2026-07-06', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-full-105', 6, N'Lý Thùy Linh', '2026-07-06', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-106', 7, N'Bùi Quang Huy', '2026-07-06', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-107', 8, N'Võ Tấn Phát', '2026-07-06', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-108', 9, N'Hồ Ngọc Mai', '2026-07-06', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-full-109', 10, N'Đỗ Minh Châu', '2026-07-07', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-full-110', 1, N'Phạm Minh Tuấn', '2026-07-07', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-111', 2, N'Lê Quốc Bảo', '2026-07-07', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-full-112', 3, N'Nguyễn Thu Trà', '2026-07-07', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-full-113', 4, N'Đặng Văn Phong', '2026-07-07', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-full-114', 5, N'Trần Tuấn Dũng', '2026-07-07', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-115', 6, N'Lý Thùy Linh', '2026-07-07', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-116', 7, N'Bùi Quang Huy', '2026-07-07', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-117', 8, N'Võ Tấn Phát', '2026-07-07', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-full-118', 9, N'Hồ Ngọc Mai', '2026-07-08', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-full-119', 10, N'Đỗ Minh Châu', '2026-07-08', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-120', 1, N'Phạm Minh Tuấn', '2026-07-08', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-full-121', 2, N'Lê Quốc Bảo', '2026-07-08', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-full-122', 3, N'Nguyễn Thu Trà', '2026-07-08', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-full-123', 4, N'Đặng Văn Phong', '2026-07-08', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-124', 5, N'Trần Tuấn Dũng', '2026-07-08', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-125', 6, N'Lý Thùy Linh', '2026-07-08', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-126', 7, N'Bùi Quang Huy', '2026-07-08', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-full-127', 8, N'Võ Tấn Phát', '2026-07-09', N'Ca Sáng', '06:00 - 12:00', N'Vắng', '', 'Barista'),
('mock-full-128', 9, N'Hồ Ngọc Mai', '2026-07-09', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-129', 10, N'Đỗ Minh Châu', '2026-07-09', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-full-130', 1, N'Phạm Minh Tuấn', '2026-07-09', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-full-131', 2, N'Lê Quốc Bảo', '2026-07-09', N'Ca Chiều', '12:00 - 18:00', N'Vắng', '', 'Cashier'),
('mock-full-132', 3, N'Nguyễn Thu Trà', '2026-07-09', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-133', 4, N'Đặng Văn Phong', '2026-07-09', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-134', 5, N'Trần Tuấn Dũng', '2026-07-09', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-135', 6, N'Lý Thùy Linh', '2026-07-09', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-full-136', 7, N'Bùi Quang Huy', '2026-07-10', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-full-137', 8, N'Võ Tấn Phát', '2026-07-10', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-138', 9, N'Hồ Ngọc Mai', '2026-07-10', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-full-139', 10, N'Đỗ Minh Châu', '2026-07-10', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-full-140', 1, N'Phạm Minh Tuấn', '2026-07-10', N'Ca Chiều', '12:00 - 18:00', N'Vắng', '', 'Cashier'),
('mock-full-141', 2, N'Lê Quốc Bảo', '2026-07-10', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-142', 3, N'Nguyễn Thu Trà', '2026-07-10', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-143', 4, N'Đặng Văn Phong', '2026-07-10', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-144', 5, N'Trần Tuấn Dũng', '2026-07-10', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-full-145', 6, N'Lý Thùy Linh', '2026-07-11', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-full-146', 7, N'Bùi Quang Huy', '2026-07-11', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-147', 8, N'Võ Tấn Phát', '2026-07-11', N'Ca Sáng', '06:00 - 12:00', N'Vắng', '', 'Waiter'),
('mock-full-148', 9, N'Hồ Ngọc Mai', '2026-07-11', N'Ca Chiều', '12:00 - 18:00', N'Vắng', '', 'Barista'),
('mock-full-149', 10, N'Đỗ Minh Châu', '2026-07-11', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-full-150', 1, N'Phạm Minh Tuấn', '2026-07-11', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-151', 2, N'Lê Quốc Bảo', '2026-07-11', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-152', 3, N'Nguyễn Thu Trà', '2026-07-11', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-153', 4, N'Đặng Văn Phong', '2026-07-11', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-full-154', 5, N'Trần Tuấn Dũng', '2026-07-12', N'Ca Sáng', '06:00 - 12:00', N'Vắng', '', 'Barista'),
('mock-full-155', 6, N'Lý Thùy Linh', '2026-07-12', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-full-156', 7, N'Bùi Quang Huy', '2026-07-12', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-full-157', 8, N'Võ Tấn Phát', '2026-07-12', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-full-158', 9, N'Hồ Ngọc Mai', '2026-07-12', N'Ca Chiều', '12:00 - 18:00', N'Vắng', '', 'Cashier'),
('mock-full-159', 10, N'Đỗ Minh Châu', '2026-07-12', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-full-160', 1, N'Phạm Minh Tuấn', '2026-07-12', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-full-161', 2, N'Lê Quốc Bảo', '2026-07-12', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-full-162', 3, N'Nguyễn Thu Trà', '2026-07-12', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter');

-- Make everyone currently scheduled for last week "Đã làm" to ensure at least 1 present
UPDATE dbo.Shifts 
SET status = N'Đã làm' 
WHERE shiftDate >= '2026-07-06' AND shiftDate <= '2026-07-12';

-- Add a few "Vắng" shifts as extras so we still have absent data
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
('mock-extra-1', 2, N'Lê Quốc Bảo', '2026-07-06', N'Ca Sáng', '06:00 - 12:00', N'Vắng', N'Nghỉ ốm', 'Barista'),
('mock-extra-2', 4, N'Đặng Văn Phong', '2026-07-08', N'Ca Tối', '18:00 - 23:00', N'Vắng', N'Xe hỏng', 'Cashier'),
('mock-extra-3', 10, N'Đỗ Minh Châu', '2026-07-12', N'Ca Chiều', '12:00 - 18:00', N'Vắng', '', 'Waiter');
DELETE FROM dbo.Shifts WHERE shiftDate >= '2026-07-13' AND shiftDate <= '2026-07-16';
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
('mock-current-300', 6, N'Lý Thùy Linh', '2026-07-13', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-current-301', 7, N'Bùi Quang Huy', '2026-07-13', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-current-302', 8, N'Võ Tấn Phát', '2026-07-13', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-current-303', 9, N'Hồ Ngọc Mai', '2026-07-13', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-current-304', 10, N'Đỗ Minh Châu', '2026-07-13', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-current-305', 1, N'Phạm Minh Tuấn', '2026-07-13', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-current-306', 2, N'Lê Quốc Bảo', '2026-07-13', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-current-307', 3, N'Nguyễn Thu Trà', '2026-07-13', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-current-308', 4, N'Đặng Văn Phong', '2026-07-13', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-current-309', 5, N'Trần Tuấn Dũng', '2026-07-14', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-current-310', 6, N'Lý Thùy Linh', '2026-07-14', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-current-311', 7, N'Bùi Quang Huy', '2026-07-14', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-current-312', 8, N'Võ Tấn Phát', '2026-07-14', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-current-313', 9, N'Hồ Ngọc Mai', '2026-07-14', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-current-314', 10, N'Đỗ Minh Châu', '2026-07-14', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-current-315', 1, N'Phạm Minh Tuấn', '2026-07-14', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-current-316', 2, N'Lê Quốc Bảo', '2026-07-14', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-current-317', 3, N'Nguyễn Thu Trà', '2026-07-14', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-current-318', 4, N'Đặng Văn Phong', '2026-07-15', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-current-319', 5, N'Trần Tuấn Dũng', '2026-07-15', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-current-320', 6, N'Lý Thùy Linh', '2026-07-15', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-current-321', 7, N'Bùi Quang Huy', '2026-07-15', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-current-322', 8, N'Võ Tấn Phát', '2026-07-15', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-current-323', 9, N'Hồ Ngọc Mai', '2026-07-15', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-current-324', 10, N'Đỗ Minh Châu', '2026-07-15', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-current-325', 1, N'Phạm Minh Tuấn', '2026-07-15', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-current-326', 2, N'Lê Quốc Bảo', '2026-07-15', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter'),
('mock-current-327', 3, N'Nguyễn Thu Trà', '2026-07-16', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Barista'),
('mock-current-328', 4, N'Đặng Văn Phong', '2026-07-16', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Cashier'),
('mock-current-329', 5, N'Trần Tuấn Dũng', '2026-07-16', N'Ca Sáng', '06:00 - 12:00', N'Đã làm', '', 'Waiter'),
('mock-current-330', 6, N'Lý Thùy Linh', '2026-07-16', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Barista'),
('mock-current-331', 7, N'Bùi Quang Huy', '2026-07-16', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Cashier'),
('mock-current-332', 8, N'Võ Tấn Phát', '2026-07-16', N'Ca Chiều', '12:00 - 18:00', N'Đã làm', '', 'Waiter'),
('mock-current-333', 9, N'Hồ Ngọc Mai', '2026-07-16', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Barista'),
('mock-current-334', 10, N'Đỗ Minh Châu', '2026-07-16', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Cashier'),
('mock-current-335', 1, N'Phạm Minh Tuấn', '2026-07-16', N'Ca Tối', '18:00 - 23:00', N'Đã làm', '', 'Waiter');
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
('mock-curr-ex-1', 1, N'Phạm Minh Tuấn', '2026-07-14', N'Ca Sáng', '06:00 - 12:00', N'Vắng', N'Nghỉ ốm', 'Barista'),
('mock-curr-ex-2', 7, N'Bùi Quang Huy', '2026-07-15', N'Ca Tối', '18:00 - 23:00', N'Vắng', N'Xe hỏng', 'Waiter');



-- Rest of current week

DELETE FROM dbo.Shifts WHERE shiftDate >= '2026-07-17' AND shiftDate <= '2026-07-19';
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES
('mock-rest-curr-500', 9, N'Hồ Ngọc Mai', '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-501', 10, N'Đỗ Minh Châu', '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-502', 1, N'Phạm Minh Tuấn', '2026-07-17', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-503', 2, N'Lê Quốc Bảo', '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-504', 3, N'Nguyễn Thu Trà', '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-505', 4, N'Đặng Văn Phong', '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-506', 5, N'Trần Tuấn Dũng', '2026-07-17', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-507', 6, N'Lý Thùy Linh', '2026-07-17', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-508', 7, N'Bùi Quang Huy', '2026-07-17', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-509', 8, N'Võ Tấn Phát', '2026-07-18', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-510', 9, N'Hồ Ngọc Mai', '2026-07-18', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-511', 10, N'Đỗ Minh Châu', '2026-07-18', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-512', 1, N'Phạm Minh Tuấn', '2026-07-18', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-513', 2, N'Lê Quốc Bảo', '2026-07-18', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-514', 3, N'Nguyễn Thu Trà', '2026-07-18', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-515', 4, N'Đặng Văn Phong', '2026-07-18', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-516', 5, N'Trần Tuấn Dũng', '2026-07-18', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-517', 6, N'Lý Thùy Linh', '2026-07-18', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-518', 7, N'Bùi Quang Huy', '2026-07-19', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-519', 8, N'Võ Tấn Phát', '2026-07-19', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-520', 9, N'Hồ Ngọc Mai', '2026-07-19', N'Ca Sáng', '06:00 - 12:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-521', 10, N'Đỗ Minh Châu', '2026-07-19', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-522', 1, N'Phạm Minh Tuấn', '2026-07-19', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-523', 2, N'Lê Quốc Bảo', '2026-07-19', N'Ca Chiều', '12:00 - 18:00', N'Đã xếp lịch', '', 'Waiter'),
('mock-rest-curr-524', 3, N'Nguyễn Thu Trà', '2026-07-19', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Barista'),
('mock-rest-curr-525', 4, N'Đặng Văn Phong', '2026-07-19', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Cashier'),
('mock-rest-curr-526', 5, N'Trần Tuấn Dũng', '2026-07-19', N'Ca Tối', '18:00 - 23:00', N'Đã xếp lịch', '', 'Waiter');

