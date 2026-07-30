# Mô tả Cơ sở dữ liệu — CoffeeShopLite

**13 bảng**, **6 khóa ngoại**. SQL Server. Toàn bộ tiền tệ lưu bằng `INT` (đơn vị VNĐ, không có phần lẻ).

> ⚠️ **Nguồn sự thật là `LiteService.init()`**, không phải `database_lite.sql`. File `.sql` đó đã lỗi thời: chỉ có 11/13 bảng (thiếu `Inventory`, `RecipeItems`), 4/6 khóa ngoại, thiếu `Users.role` (nhưng `MERGE` bên dưới lại chèn `role` nên tự gây lỗi), thiếu `Shifts.staffName`, `Orders.splitLocked`, `Orders.invoicePrinted`, `OrderItems.preparedQty`. Dùng `setup_database.sql` thay thế.

## Sơ đồ quan hệ

```
                    ┌─────────────┐
                    │  MenuItems  │  (thực đơn)
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           │ 1:N           │ 1:N           │ 1:N
    ┌──────▼───────┐ ┌─────▼──────┐ ┌──────▼───────┐
    │MenuItemSizes │ │ OrderItems │ │ RecipeItems  │
    └──────────────┘ └─────▲──────┘ └──────┬───────┘
                           │ 1:N           │ N:1
                    ┌──────┴──────┐  ┌─────▼──────┐
                    │   Orders    │  │ Inventory  │
                    └──────┬──────┘  └────────────┘
                           ┊ (không FK — nối bằng chuỗi tên bàn)
                    ┌──────┴──────┐        ┌────────┐  1:N  ┌────────┐
                    │   Tables    │        │ Staff  ├──────►│ Shifts │
                    └─────────────┘        └────────┘       └────────┘

    Độc lập:  Users · CashEvents · StoreState · SystemLogs
```

## Phân nhóm

| Nhóm | Bảng |
|---|---|
| Bán hàng | `Orders`, `OrderItems`, `Tables` |
| Thực đơn | `MenuItems`, `MenuItemSizes` |
| Kho & công thức | `Inventory`, `RecipeItems` |
| Nhân sự | `Users`, `Staff`, `Shifts` |
| Vận hành | `CashEvents`, `StoreState`, `SystemLogs` |

---

# NHÓM BÁN HÀNG

## 1. `Tables` — Danh sách bàn

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã bàn, tự tăng |
| `name` | NVARCHAR(60) | NOT NULL | Tên đầy đủ, dạng `Tầng 1 - Bàn 3`. **Đây là khóa mà `Orders` tham chiếu tới** |
| `code` | VARCHAR(40) | NULL | Mã ngẫu nhiên nhúng trong QR dán trên bàn. Khách quét → `menu.jsp?tableCode=...` |
| `floorNo` | INT | NULL | Số tầng, dùng để nhóm trên sơ đồ |
| `tableNo` | INT | NULL | Số bàn trong tầng, dùng để sắp thứ tự |
| `active` | BIT | NOT NULL, DEFAULT 1 | **Bàn còn dùng được không** — cờ ẩn/hiện do admin điều khiển. Không liên quan tới việc bàn có khách |

**Lưu ý quan trọng:** bảng này **không có cột trạng thái**. Bàn trống hay đang có khách được **suy ra từ `Orders`**, không lưu sẵn — tránh hai nguồn sự thật lệch nhau.

`floorNo`, `tableNo` được thêm sau bằng `ALTER TABLE` nên cho phép `NULL`. Query sắp xếp dùng `ISNULL(floorNo, 1)` và `ISNULL(tableNo, 999)` để bàn chưa gán không trôi lên đầu.

## 2. `Orders` — Hóa đơn

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã đơn nội bộ. **Mọi API đều dùng số này** |
| `orderNumber` | INT | NULL, UNIQUE | **Số hiệu hiển thị cho khách**, công thức `1000 + id`. Đơn `id=421` → `#1421` |
| `tableName` | NVARCHAR(60) | NOT NULL | Tên bàn. ⚠️ Nối bằng **chuỗi**, không có FK tới `Tables` |
| `customerPhone` | VARCHAR(20) | NULL | SĐT khách. Bị xóa khỏi response gửi cho waiter |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'Pending' | Trạng thái đơn — xem bảng dưới |
| `total` | INT | NOT NULL, DEFAULT 0 | Tổng tiền — tính lúc tạo đơn, và **tính lại khi tách hóa đơn** (`recalcOrderTotal`) |
| `note` | NVARCHAR(255) | NULL | Ghi chú của khách |
| `createdAt` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Thời điểm tạo, giờ UTC |
| `splitLocked` | BIT | NOT NULL, DEFAULT 0 | Đơn đã bị tách thì khóa, không cho tách tiếp |
| `invoicePrinted` | BIT | NOT NULL, DEFAULT 0 | Waiter đã in hóa đơn chưa. Chưa in mà bấm phục vụ thì hệ thống hỏi lại |

**Sáu giá trị của `status`** — đây là trục xương sống của cả hệ thống:

```
Pending ──barista──► Preparing ──barista──► Ready ──waiter──► Served ──thu ngân──► Paid ┄┄waiter┄┄► Cleared
 khách                đang pha              chờ bưng          đã bưng             đã trả tiền       đã dọn bàn
 vừa đặt              └──────────── canSetStatus() ép 4 bước này ────────────┘      └─ /tables/clear ─┘
```

Luồng **một chiều**, mỗi chặng một vai trò, không có đường đi lùi.

⚠️ **Bước cuối đi đường khác.** `canSetStatus()` (`LiteApiServlet.java:915`) chỉ mã hóa **4 bước đầu** — hoàn toàn không nhắc tới `Cleared`. Bước `Paid → Cleared` không qua `/orders/status` mà qua endpoint **`/tables/clear`** → `clearServedTable()`, và nó cập nhật **theo tên bàn** cho mọi đơn `Paid` của bàn đó cùng lúc:

```sql
UPDATE dbo.Orders SET status='Cleared' WHERE tableName=? AND status='Paid'
```

Ngoài ra `clearOrphanActiveOrders()` cũng ghi `Cleared` hàng loạt lúc khởi động ứng dụng.

⚠️ Cột `status` **không có `CHECK` constraint** — về mặt DB vẫn ghi được giá trị lạ.

**Vì sao `orderNumber` cho phép `NULL`:** `id` là `IDENTITY` nên chỉ biết sau khi `INSERT`. Code phải `INSERT` trước, lấy `id`, rồi mới `UPDATE orderNumber = 1000 + id`. Khoảng giữa hai bước đó nó là `NULL`.

## 3. `OrderItems` — Chi tiết món trong đơn

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã dòng |
| `orderId` | INT | NOT NULL, **FK → Orders** | Thuộc đơn nào |
| `menuItemId` | INT | NOT NULL, **FK → MenuItems** | Món nào trong thực đơn |
| `itemName` | NVARCHAR(120) | NOT NULL | ⚠️ Tên món **chép lại** tại thời điểm bán |
| `itemSize` | VARCHAR(20) | NULL | Size khách chọn: `S`, `M`, `L` |
| `quantity` | INT | NOT NULL | Số lượng |
| `price` | INT | NOT NULL | ⚠️ Giá **chép lại** tại thời điểm bán (đã gồm phụ phí size) |
| `preparedQty` | INT | NOT NULL, DEFAULT 0 | Barista đã pha xong bao nhiêu phần trong `quantity` |

**Vì sao lưu trùng `itemName` và `price` dù đã có `menuItemId`:**

Đây **không phải** lỗi thiết kế mà là **denormalization có chủ đích**. Nếu quán tăng giá cà phê từ 30k lên 35k, hóa đơn tháng trước phải giữ giá 30k. Chỉ lưu `menuItemId` rồi join lấy giá hiện tại thì mọi hóa đơn cũ tự đổi giá — sai hoàn toàn về kế toán.

Thuật ngữ: **chụp ảnh dữ liệu tại thời điểm giao dịch**.

---

# NHÓM THỰC ĐƠN

## 4. `MenuItems` — Món trong thực đơn

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã món |
| `nameVi` | NVARCHAR(120) | NOT NULL | Tên tiếng Việt |
| `nameEn` | NVARCHAR(120) | NOT NULL | Tên tiếng Anh — hệ thống song ngữ |
| `category` | NVARCHAR(60) | NOT NULL | Nhóm: `Cà phê`, `Trà`, `Đặc biệt`, `Bánh ngọt` |
| `price` | INT | NOT NULL | Giá gốc (size S). Validate: 10.000–200.000đ, chia hết cho 1.000 |
| `active` | BIT | NOT NULL, DEFAULT 1 | Còn bán không. **Tự động về 0 khi hết nguyên liệu** |
| `imagePath` | VARCHAR(255) | NULL | Đường dẫn ảnh, dạng `assets/img/menu/latte.jpg` |

`active` được `refreshMenuAvailability()` và `deactivateUnavailableMenuItems()` tự cập nhật — món hết nguyên liệu thì biến khỏi thực đơn của khách.

## 5. `MenuItemSizes` — Size của món

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã dòng |
| `menuItemId` | INT | NOT NULL, **FK → MenuItems** | Thuộc món nào |
| `sizeName` | NVARCHAR(20) | NOT NULL | `S`, `M`, `L`. Validate `[A-Z0-9+\- ]+`: chữ/số/`+`/`-`/**dấu cách**, tối đa 12 ký tự, **tự viết hoa** trước khi lưu |
| `extraPrice` | INT | NOT NULL, DEFAULT 0 | **Tiền cộng thêm** so với giá gốc. Size S bắt buộc bằng 0 |
| `sortOrder` | INT | NOT NULL, DEFAULT 0 | Thứ tự hiển thị |

Giá cuối = `MenuItems.price + MenuItemSizes.extraPrice`. Mỗi món tối đa 8 size.

Món đồ uống được tự tạo sẵn 3 size: S (+0), M (+5.000), L (+10.000).

---

# NHÓM KHO & CÔNG THỨC

## 6. `Inventory` — Kho nguyên liệu

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | VARCHAR(50) | PK | ⚠️ Khóa **chuỗi** do người dùng đặt: `i1`, `CF_01`. Validate: 2–50 ký tự, chỉ chữ/số/`_`/`-` |
| `name` | NVARCHAR(120) | NOT NULL | Tên nguyên liệu: `Hạt cà phê nguyên chất` |
| `unit` | NVARCHAR(20) | NOT NULL | Đơn vị: `g`, `ml`, `cái`, `lát`, `nhánh` |
| `stock` | INT | NOT NULL, DEFAULT 0 | Tồn kho hiện tại |
| `minStock` | INT | NOT NULL, DEFAULT 0 | Ngưỡng cảnh báo sắp hết |
| `importCost` | INT | NOT NULL, DEFAULT 0 | Giá nhập trên một đơn vị |

Đây là bảng duy nhất dùng khóa chính do người dùng tự đặt, nên phải validate định dạng kỹ.

## 7. `RecipeItems` — Công thức pha chế

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | VARCHAR(50) | PK | Mã dòng công thức |
| `menuItemId` | INT | NOT NULL, **FK → MenuItems** | Món nào |
| `ingredientId` | VARCHAR(50) | NOT NULL, **FK → Inventory** | Dùng nguyên liệu nào |
| `quantity` | INT | NOT NULL | **Định lượng cho MỘT phần** |

**Đây là bảng trung gian của quan hệ nhiều–nhiều duy nhất trong hệ thống:**

```
MenuItems ──1:N──► RecipeItems ◄──N:1── Inventory
```

Một món cần nhiều nguyên liệu, một nguyên liệu dùng cho nhiều món. Nhưng nó **có thuộc tính riêng** là `quantity`, nên đúng thuật ngữ phải gọi là **thực thể kết hợp** (associative entity), không phải bảng nối thuần túy.

Ví dụ cà phê sữa = 2 dòng: `(cà phê sữa, hạt cà phê, 18)` và `(cà phê sữa, sữa đặc, 30)`.

**Khi barista chuyển đơn `Preparing → Ready`**, hệ thống join qua bảng này để trừ kho:

```sql
SELECT ri.ingredientId, SUM(ri.quantity * oi.quantity) usedQuantity
FROM dbo.OrderItems oi
JOIN dbo.RecipeItems ri ON ri.menuItemId = CONVERT(VARCHAR(50), oi.menuItemId)
WHERE oi.orderId = ?
GROUP BY ri.ingredientId
```

`ri.quantity * oi.quantity` = định lượng một phần × số phần khách gọi.

**Vì sao có `CONVERT(VARCHAR(50), ...)`:** cột `RecipeItems.menuItemId` từng là `VARCHAR(50)` rồi được migrate sang `INT`. Bản `CREATE TABLE` dự phòng trong `RecipeDAO.java:182` **vẫn khai báo `VARCHAR(50)`** — chưa cập nhật. Khi cả hai vế đã là `INT`, phép `CONVERT` này khiến SQL Server **không dùng được index** trên cột đó (non-sargable). Bỏ đi được.

---

# NHÓM NHÂN SỰ

## 8. `Users` — Tài khoản đăng nhập

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `username` | VARCHAR(50) | PK | Tên đăng nhập |
| `password` | VARCHAR(100) | NOT NULL | ⚠️ Mật khẩu **lưu dạng thô**, chưa hash |
| `role` | VARCHAR(20) | NOT NULL | `admin` / `barista` / `cashier` / `runner` |
| `fullName` | NVARCHAR(120) | NOT NULL | Tên hiển thị, dùng để ghi log |

Chỉ có **4 tài khoản cố định** — hệ thống đăng nhập theo **vai trò**, không theo từng người.

⚠️ Hai điểm yếu cần biết: mật khẩu chưa hash (`admin/8888`, `barista/1111`...), và `login()` so sánh mật khẩu **trong câu SQL** (`WHERE username=? AND password=?`) thay vì lấy hash ra so ở tầng Java.

## 9. `Staff` — Nhân viên

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK | Mã nhân viên, **không IDENTITY** — nhập tay |
| `name` | NVARCHAR(120) | NOT NULL | Họ tên |
| `active` | BIT | NOT NULL, DEFAULT 1 | Còn làm việc không |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'Active' | Trạng thái nhân sự |

⚠️ **`Staff` và `Users` hoàn toàn tách rời** — không có cột nào nối hai bảng. Nghĩa là không biết ca làm nào ứng với tài khoản nào. Muốn truy vết ai làm gì phải dựa vào `SystemLogs.actorName`.

Bảng này từng có **8 cột** nay đã bị `LiteService.init()` `DROP COLUMN` khi tách bạch hai khái niệm: `shift`, `username`, `password`, `role`, `pin`, `overtime`, `phone`, `email`. Đây là lý do các script cũ (`update_db.sql`, `test_data.sql`) chèn vào những cột đó sẽ báo `Invalid column name`.

## 10. `Shifts` — Ca làm

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | VARCHAR(50) | PK | Mã ca, sinh dạng `s<timestamp>-<hash>` |
| `staffId` | INT | NOT NULL, **FK → Staff** | Nhân viên nào |
| `staffName` | NVARCHAR(120) | NOT NULL | ⚠️ **Cột chết** — khai báo NOT NULL nhưng KHÔNG code path nào ghi vào. Tên hiển thị luôn lấy qua `JOIN dbo.Staff` |
| `shiftDate` | VARCHAR(20) | NOT NULL | ⚠️ Ngày lưu dạng **chuỗi** `2026-07-17`, không phải `DATE` |
| `shiftName` | NVARCHAR(50) | NOT NULL | `Ca Sáng` / `Ca Chiều` / `Ca Tối` |
| `hours` | VARCHAR(50) | NOT NULL | Khung giờ: `06:00 - 12:00` |
| `status` | NVARCHAR(30) | NOT NULL | `Đã xếp lịch` / `Đã làm` / `Vắng` / `Hoàn thành` |
| `notes` | NVARCHAR(255) | NULL | Ghi chú |
| `assignedRole` | VARCHAR(30) | NULL | Vị trí trong ca: `Barista` / `Cashier` / `Waiter` |

**Có UNIQUE INDEX** `UX_Shifts_StaffDateName (staffId, shiftDate, shiftName)` — chặn xếp trùng một người vào cùng ca cùng ngày. Đây là ràng buộc gây lỗi khi chạy `test_data.sql` cũ.

⚠️ `shiftDate` là `VARCHAR` nên không dùng được hàm ngày tháng của SQL Server, và so sánh khoảng ngày phải dựa vào việc chuỗi `yyyy-MM-dd` tình cờ sắp xếp đúng thứ tự.

---

# NHÓM VẬN HÀNH

## 11. `CashEvents` — Nhật ký tiền mặt

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã sự kiện |
| `eventType` | VARCHAR(30) | NOT NULL | Loại: chốt ca, rút tiền... |
| `amount` | INT | NOT NULL | Số tiền của sự kiện |
| `balanceAfter` | INT | NOT NULL | **Số dư sau sự kiện** — lưu sẵn để không phải cộng dồn lại |
| `note` | NVARCHAR(255) | NULL | Ghi chú |
| `actorRole` | VARCHAR(20) | NULL | Vai trò người thực hiện |
| `actorName` | NVARCHAR(120) | NULL | Tên người thực hiện |
| `seenByCashier` | BIT | NOT NULL, DEFAULT 1 | Thu ngân đã xem thông báo rút tiền chưa |
| `createdAt` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Thời điểm |

Đây là **sổ cái** — chỉ thêm, không sửa. `balanceAfter` giúp tra số dư tại bất kỳ thời điểm nào mà không cần tính lại từ đầu.

## 12. `StoreState` — Trạng thái cửa hàng (key-value)

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `stateKey` | VARCHAR(50) | PK | Tên biến |
| `intValue` | INT | NOT NULL | Giá trị |
| `updatedAt` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Lần sửa cuối |

Hiện chỉ có **một** dòng: `cupsAvailable = 120` — số cốc còn trong quán.

Barista chuyển đơn sang `Ready` sẽ trừ số cốc. Đọc bằng `SELECT ... WITH (UPDLOCK, ROWLOCK)` để hai barista không cùng trừ một lượng (lost update).

Kiểu bảng key-value cho phép thêm cấu hình mới mà không cần `ALTER TABLE`.

## 13. `SystemLogs` — Nhật ký hệ thống

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| `id` | INT | PK, IDENTITY | Mã log |
| `actorRole` | VARCHAR(20) | NOT NULL | Vai trò người thao tác |
| `actorName` | NVARCHAR(120) | NULL | Tên người thao tác |
| `actionType` | VARCHAR(40) | NOT NULL | `LOGIN`, `ORDER_STATUS`, `TABLE_CLEAR`, `TABLE_TRANSFER`, `MENU_SAVE`, `INVENTORY_DELETE`... |
| `messageVi` | NVARCHAR(400) | NOT NULL | Nội dung tiếng Việt |
| `messageEn` | NVARCHAR(400) | NOT NULL | Nội dung tiếng Anh |
| `refId` | INT | NULL | ⚠️ ID đối tượng liên quan (thường là `Orders.id`) — **cố ý KHÔNG có FK** |
| `createdAt` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Thời điểm |

**Vì sao `refId` không có FK:** log phải sống lâu hơn dữ liệu nó tham chiếu. Nếu có FK thì xóa một đơn sẽ kéo theo mất log của đơn đó — mất luôn dấu vết kiểm toán. Ngoài ra `refId` đôi khi để `NULL` (log đăng nhập, log đổi bàn).

Ghi log được thực hiện **trong cùng transaction** với thao tác nghiệp vụ, nên không thể có chuyện đổi trạng thái thành công mà mất log.

---

# TỔNG HỢP QUAN HỆ

| # | Bảng con | Cột | → Bảng cha | Loại |
|---|---|---|---|---|
| 1 | `MenuItemSizes` | `menuItemId` | `MenuItems.id` | 1:N |
| 2 | `OrderItems` | `orderId` | `Orders.id` | 1:N |
| 3 | `OrderItems` | `menuItemId` | `MenuItems.id` | 1:N |
| 4 | `RecipeItems` | `menuItemId` | `MenuItems.id` | N:N (nửa 1) |
| 5 | `RecipeItems` | `ingredientId` | `Inventory.id` | N:N (nửa 2) |
| 6 | `Shifts` | `staffId` | `Staff.id` | 1:N |

## Bốn quan hệ ngầm — không có FK

| Quan hệ | Vì sao không có FK |
|---|---|
| `Orders.tableName` → `Tables.name` | ⚠️ Nối bằng **chuỗi tên bàn**. Đổi tên bàn là mất liên kết với đơn cũ. Đúng ra nên là `tableId INT REFERENCES Tables(id)` |
| `SystemLogs.refId` → `Orders.id` | ✅ Cố ý — log phải sống lâu hơn dữ liệu |
| `Users` ↔ `Staff` | ⚠️ Không có cột nối. Không biết ca làm nào ứng với tài khoản nào |
| `CashEvents`, `StoreState` | ✅ Bảng độc lập, không cần liên kết |

---

# ĐIỂM YẾU CẦN BIẾT

| # | Vấn đề | Ảnh hưởng |
|---|---|---|
| 1 | **0 `CHECK` constraint** | `Orders.status` ghi được giá trị lạ; `quantity` có thể âm ở mức DB |
| 2 | **Ít index** | `Orders.status`, `Orders.tableName`, `OrderItems.orderId` là 3 cột query nhiều nhất. SQL Server **không tự tạo index cho khóa ngoại** |
| 3 | **`Orders.tableName` không có FK** | Nối bằng chuỗi 60 ký tự thay vì số nguyên |
| 4 | **Mật khẩu lưu thô** | Phải hash + salt |
| 5 | **`Shifts.shiftDate` là `VARCHAR`** | Không dùng được hàm ngày tháng |
| 6 | **`Users` và `Staff` tách rời** | Không truy vết được ai làm ca nào |
| 7 | **`Shifts.staffName` là cột chết** | `NOT NULL` không DEFAULT nhưng `ShiftDAO.save()` và seed đều không ghi vào → `INSERT` sẽ fail trên schema mới. Mọi câu đọc đều `JOIN dbo.Staff` lấy tên |

## `CHECK` constraint nên thêm

```sql
ALTER TABLE dbo.Orders ADD CONSTRAINT CK_Orders_Status
    CHECK (status IN ('Pending','Preparing','Ready','Served','Paid','Cleared'));
ALTER TABLE dbo.OrderItems ADD CONSTRAINT CK_OrderItems_Quantity CHECK (quantity > 0);
ALTER TABLE dbo.OrderItems ADD CONSTRAINT CK_OrderItems_Price    CHECK (price >= 0);
ALTER TABLE dbo.Orders     ADD CONSTRAINT CK_Orders_Total        CHECK (total >= 0);
ALTER TABLE dbo.Inventory  ADD CONSTRAINT CK_Inventory_Stock     CHECK (stock >= 0);
```

# ĐIỂM MẠNH NÊN KHOE

| # | Điểm mạnh |
|---|---|
| 1 | **Denormalization có chủ đích** ở `OrderItems` — giữ giá tại thời điểm bán |
| 2 | **Quan hệ N:N với thuộc tính** — `RecipeItems.quantity` cho phép tính trừ kho tự động |
| 3 | **Trạng thái bàn không lưu sẵn** — suy ra từ đơn, tránh hai nguồn sự thật |
| 4 | **`SystemLogs` cố ý không FK** — bảo toàn dấu vết kiểm toán |
| 5 | **`CashEvents.balanceAfter`** — tra số dư mọi thời điểm không cần cộng dồn |
| 6 | **`StoreState` key-value** — thêm cấu hình không cần `ALTER TABLE` |
| 7 | **UNIQUE index trên `Shifts`** — chặn xếp trùng ca ở mức DB |
