/* ══════════════════════════════════════════════════════════════
   CoffeeShopLite — TÀI KHOẢN RIÊNG CHO TỪNG NHÂN VIÊN
   Chạy SAU schema_fix_p0.sql. An toàn khi chạy lại nhiều lần.

   VẤN ĐỀ ĐANG SỬA
   Bốn tài khoản barista/cashier/runner dùng chung cho 10 nhân viên.
   Ai biết PIN cũng thao tác được, và nhật ký chỉ ghi "Thu ngân coffeshop".
   Không có cách nào biết người nào với người nào.

   THIẾT KẾ MỚI
   • Mỗi nhân viên một dòng trong dbo.Users, khoá ngoại sang dbo.Staff.
   • PIN được BĂM (SHA-256 + salt riêng), không lưu thô như trước.
   • Users.role không còn là vai trò làm việc mà là LOẠI TÀI KHOẢN:
       admin = quyền cố định
       staff = quyền phụ thuộc ca làm hôm nay
   • Vai trò thực tế của mỗi phiên lấy từ Shifts.assignedRole của NGÀY HÔM NAY.
     Nhờ vậy luật "chỉ người đang trong ca mới thao tác được" là thứ hệ thống
     tự thực thi, không phải lời hứa trong tài liệu.

   PIN mặc định = 1000 + id nhân viên (nhân viên #1 → 1001).
   Đổi ngay sau khi demo xong.
   ══════════════════════════════════════════════════════════════ */

USE CoffeeShopLite;
GO

PRINT N'── A. Phân biệt vai trò làm việc và loại tài khoản ─────────';

IF COL_LENGTH('dbo.Roles','isShiftRole') IS NULL
    ALTER TABLE dbo.Roles ADD isShiftRole BIT NOT NULL DEFAULT 1;
GO

/* 'staff' là LOẠI TÀI KHOẢN, không phải vai trò xếp ca được.
   isShiftRole tách hai khái niệm này ra, tránh lặp lại đúng sai lầm cũ:
   một cột gánh hai ý nghĩa. */
MERGE dbo.Roles AS t
USING (VALUES
    ('admin',   N'Quản trị',  'Admin',   1, 0),
    ('staff',   N'Nhân viên', 'Staff',   2, 0),
    ('barista', N'Pha chế',   'Barista', 3, 1),
    ('cashier', N'Thu ngân',  'Cashier', 4, 1),
    ('runner',  N'Bồi bàn',   'Waiter',  5, 1)
) AS s(code, nameVi, nameEn, sortOrder, isShiftRole)
ON t.code = s.code
WHEN MATCHED THEN UPDATE SET nameVi=s.nameVi, nameEn=s.nameEn, sortOrder=s.sortOrder, isShiftRole=s.isShiftRole
WHEN NOT MATCHED THEN INSERT(code,nameVi,nameEn,sortOrder,isShiftRole)
     VALUES(s.code,s.nameVi,s.nameEn,s.sortOrder,s.isShiftRole);
GO


PRINT N'── B. PIN được băm, không lưu thô ─────────────────────────';

IF COL_LENGTH('dbo.Users','pinHash')  IS NULL ALTER TABLE dbo.Users ADD pinHash  VARCHAR(64) NULL;
IF COL_LENGTH('dbo.Users','pinSalt')  IS NULL ALTER TABLE dbo.Users ADD pinSalt  VARCHAR(32) NULL;
IF COL_LENGTH('dbo.Users','active')   IS NULL ALTER TABLE dbo.Users ADD active   BIT NOT NULL DEFAULT 1;
GO

/* Một nhân viên chỉ được có một tài khoản. Ràng buộc ở tầng CSDL,
   không dựa vào code ứng dụng nhớ kiểm tra. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Users_StaffId' AND object_id=OBJECT_ID('dbo.Users'))
    CREATE UNIQUE INDEX UQ_Users_StaffId ON dbo.Users(staffId) WHERE staffId IS NOT NULL;
GO


PRINT N'── C. Vô hiệu hoá 3 tài khoản vị trí dùng chung ───────────';

/* KHÔNG xoá: dữ liệu cũ (Payments.cashierUsername) đang trỏ tới chúng.
   Chỉ tắt đăng nhập. Tài khoản admin giữ nguyên vì đó là quyền cố định,
   không phụ thuộc ca làm. */
UPDATE dbo.Users SET active = 0 WHERE username IN ('barista','cashier','runner');
UPDATE dbo.Users SET role = 'admin' WHERE username = 'admin';
GO


PRINT N'── D. Kiểm tra ────────────────────────────────────────────';

SELECT 'Nhân viên đang làm'  AS muc, COUNT(*) AS so_luong FROM dbo.Staff WHERE active = 1
UNION ALL SELECT 'Tài khoản cá nhân', COUNT(*) FROM dbo.Users WHERE staffId IS NOT NULL
UNION ALL SELECT 'Tài khoản dùng chung còn bật', COUNT(*) FROM dbo.Users WHERE staffId IS NULL AND active = 1
UNION ALL SELECT 'Ca làm hôm nay', COUNT(*) FROM dbo.Shifts WHERE shiftDate = CONVERT(VARCHAR(10), GETDATE(), 23);

PRINT N'';
PRINT N'-- Ai đang trong ca hôm nay, làm vai trò gì --';
SELECT s.id, s.name, sh.assignedRole AS vai_tro, sh.shiftName AS ca, sh.hours AS gio
FROM   dbo.Staff s
JOIN   dbo.Shifts sh ON sh.staffId = s.id
WHERE  sh.shiftDate = CONVERT(VARCHAR(10), GETDATE(), 23) AND s.active = 1
ORDER  BY sh.assignedRole, s.name;
GO

PRINT N'';
PRINT N'XONG. Khởi động lại Tomcat — LiteService sẽ tạo tài khoản cá nhân';
PRINT N'cho từng nhân viên với PIN mặc định 1000 + id (nhân viên #1 → 1001).';
GO
