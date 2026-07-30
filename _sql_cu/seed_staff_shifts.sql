/* ============================================================
   Seed dữ liệu Nhân viên & Ca làm  —  CoffeeShopLite
   Khớp schema hiện tại do LiteService.init() tạo ra:
     Staff  (id, name, active, status)
     Shifts (id, staffId, staffName, shiftDate, shiftName,
             hours, status, notes, assignedRole)
   ============================================================ */
USE CoffeeShopLite;
GO

/* ---------- 0. Xem schema thật trước khi chạy (tuỳ chọn) ---------- */
-- SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
-- FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Staff'  ORDER BY ORDINAL_POSITION;
-- SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
-- FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Shifts' ORDER BY ORDINAL_POSITION;

/* ---------- 1. Bổ sung cột nếu thiếu ---------- */
IF COL_LENGTH('dbo.Shifts','assignedRole') IS NULL
    ALTER TABLE dbo.Shifts ADD assignedRole VARCHAR(30) NULL;
GO
IF COL_LENGTH('dbo.Shifts','staffName') IS NULL
    ALTER TABLE dbo.Shifts ADD staffName NVARCHAR(120) NOT NULL DEFAULT N'';
GO

/* ---------- 2. Xoá dữ liệu cũ (Shifts TRƯỚC vì có FK tới Staff) ---------- */
DELETE FROM dbo.Shifts;
DELETE FROM dbo.Staff;
GO

/* ---------- 3. 10 nhân viên — CHỈ 4 cột ---------- */
INSERT INTO dbo.Staff (id, name, active, status) VALUES
( 1, N'Phạm Minh Tuấn',  1, 'Active'),
( 2, N'Lê Quốc Bảo',     1, 'Active'),
( 3, N'Nguyễn Thu Trà',  1, 'Active'),
( 4, N'Đặng Văn Phong',  1, 'Active'),
( 5, N'Trần Tuấn Dũng',  1, 'Active'),
( 6, N'Lý Thùy Linh',    1, 'Active'),
( 7, N'Bùi Quang Huy',   1, 'Active'),
( 8, N'Võ Tấn Phát',     1, 'Active'),
( 9, N'Hồ Ngọc Mai',     1, 'Active'),
(10, N'Đỗ Minh Châu',    1, 'Active');
GO

/* ---------- 4. Ca làm — có staffName, lấy từ Staff cho khớp ---------- */
INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole)
SELECT v.id, v.staffId, s.name, v.shiftDate, v.shiftName, v.hours, v.status, v.notes, v.assignedRole
FROM (VALUES
    -- 2026-07-17  Ca Sáng
    ('s1_b',  1, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', N'', 'Barista'),
    ('s1_c',  2, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', N'', 'Cashier'),
    ('s1_w1', 3, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', N'', 'Waiter'),
    ('s1_w2', 4, '2026-07-17', N'Ca Sáng',  '06:00 - 12:00', N'Đã phân công', N'', 'Waiter'),
    -- 2026-07-17  Ca Chiều
    ('s2_b',  5, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', N'', 'Barista'),
    ('s2_c',  6, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', N'', 'Cashier'),
    ('s2_w',  7, '2026-07-17', N'Ca Chiều', '12:00 - 18:00', N'Đã phân công', N'', 'Waiter'),
    -- 2026-07-18  Ca Tối  (cố tình thiếu Waiter để test giao diện)
    ('s3_b',  8, '2026-07-18', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', N'', 'Barista'),
    ('s3_c',  9, '2026-07-18', N'Ca Tối',   '18:00 - 23:00', N'Đã phân công', N'', 'Cashier')
) AS v(id, staffId, shiftDate, shiftName, hours, status, notes, assignedRole)
JOIN dbo.Staff s ON s.id = v.staffId;
GO

/* ---------- 5. Kiểm tra kết quả ---------- */
SELECT COUNT(*) AS so_nhan_vien FROM dbo.Staff;
SELECT COUNT(*) AS so_ca_lam    FROM dbo.Shifts;

SELECT sh.shiftDate, sh.shiftName, sh.assignedRole, sh.staffName, sh.hours
FROM dbo.Shifts sh
ORDER BY sh.shiftDate, sh.shiftName, sh.assignedRole;
GO
