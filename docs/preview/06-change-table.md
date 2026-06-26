# Preview Chức Năng Đổi Bàn

## 1. Đổi bàn dùng trong trường hợp nào?

Đổi bàn dùng khi khách đã ngồi và đã gọi món, nhưng sau đó muốn chuyển sang bàn khác. Ví dụ:

```text
Khách đang ngồi tầng 1 bàn 5
muốn chuyển lên tầng 2 bàn 1
```

Nếu không có chức năng đổi bàn, đơn hàng vẫn gắn với bàn cũ. Khi pha chế xong, bồi bàn có thể mang nhầm món ra bàn cũ. Vì vậy hệ thống cần cập nhật lại bàn của các đơn đang mở.

## 2. Ai được đổi bàn?

Các vai trò được đổi bàn:

- Admin.
- Thu ngân.
- Bồi bàn.

Khách không được đổi bàn trên giao diện. Nếu khách vào bằng QR, bàn bị khóa cứng theo QR. Điều này đúng thực tế hơn, vì việc đổi bàn phải do nhân viên xác nhận.

## 3. Trang truy cập

```text
/table-transfer.jsp
```

Trang này có giao diện chọn bàn cũ và bàn mới. Sau khi thao tác xong có nút quay lại màn hình làm việc trước đó.

## 4. Điều kiện để đổi bàn

Backend kiểm tra các điều kiện sau:

1. Bàn cũ và bàn mới phải khác nhau.
2. Cả hai bàn phải tồn tại.
3. Cả hai bàn phải đang active.
4. Bàn cũ phải có đơn đang mở.
5. Bàn mới không được có khách hoặc đơn đang mở.

Các trạng thái đơn được phép chuyển:

```text
Pending, Preparing, Ready, Served
```

Đơn `Paid` không chuyển nữa vì lúc đó khách đã thanh toán, bàn đang chuyển sang giai đoạn chờ dọn.

## 5. Hệ thống cập nhật dữ liệu như thế nào?

Về bản chất, đổi bàn là cập nhật `tableName` của các đơn đang mở.

Logic đơn giản:

```text
Tìm các đơn của bàn cũ
  -> nếu đơn đang Pending/Preparing/Ready/Served
  -> đổi tableName sang bàn mới
```

Sau đó hệ thống ghi log `TABLE_TRANSFER` để admin biết ai đã đổi bàn, đổi từ đâu sang đâu và vào thời điểm nào.

## 6. Vì sao phải kiểm tra bàn mới có khách hay không?

Nếu bàn mới đang có khách mà vẫn chuyển đơn sang, hệ thống sẽ trộn đơn của hai nhóm khách vào một bàn. Điều này làm sai phục vụ, sai thanh toán và sai báo cáo. Vì vậy bàn mới phải trống trước khi chuyển.

## 7. API liên quan

```text
GET  /api/tables/map
POST /api/tables/transfer
```

## 8. Điểm nên trình bày

Chức năng đổi bàn cho thấy hệ thống không chỉ tạo đơn mà còn xử lý tình huống thực tế trong quán. Quan trọng nhất là đổi bàn không tạo đơn mới, mà cập nhật các đơn đang mở sang bàn mới để workflow tiếp tục bình thường.

## 9. Mổ code chức năng đổi bàn

### 9.1. Các file tham gia

| Tầng | File | Vai trò |
| --- | --- | --- |
| JSP | `web/table-transfer.jsp` | Khung giao diện đổi bàn |
| JS | `web/assets/js/page-table-transfer.js` | Lấy sơ đồ bàn, chọn bàn nguồn/bàn đích, gửi request đổi bàn |
| API | `LiteApiServlet.java` | Case `/tables/transfer` |
| Filter | `SecurityFilter.java` | Chỉ admin/cashier/runner được vào trang và gọi API |
| Service | `LiteService.java` | `transferTable()` |
| DB | `Tables`, `Orders`, `SystemLogs` | Bàn, đơn đang mở, log đổi bàn |

### 9.2. Frontend chọn bàn nguồn/bàn đích

Trong `page-table-transfer.js`, `loadTables()` gọi:

```text
GET /api/tables/map
```

Sau đó `renderTransfer()` chia:

```javascript
sources = tables.filter(table => table.busy && table.status !== 'Paid');
targets = tables.filter(table => !table.busy);
```

Ý nghĩa:

- Bàn nguồn phải đang có khách.
- Bàn nguồn không phải trạng thái `Paid`, vì `Paid` là đang chờ dọn.
- Bàn đích phải trống.

### 9.3. Gửi request đổi bàn

Khi submit form:

```javascript
POST /api/tables/transfer
body: { fromTableId, toTableId }
```

`SecurityFilter.isAllowedApi()` chỉ cho:

```text
admin, cashier, runner
```

### 9.4. Backend xử lý trong `LiteApiServlet`

Case:

```java
case "/tables/transfer":
```

Servlet kiểm tra role:

```java
if (!"runner".equals(transferRole) && !"cashier".equals(transferRole) && !"admin".equals(transferRole))
```

Sau đó gọi:

```java
service.transferTable(fromTableId, toTableId, transferRole, user(req))
```

### 9.5. Service đổi bàn an toàn như thế nào?

`LiteService.transferTable()` dùng transaction:

```java
con.setAutoCommit(false)
```

Nó đọc bàn bằng:

```sql
SELECT ... FROM dbo.Tables WITH (UPDLOCK, ROWLOCK) WHERE id=?
```

`UPDLOCK, ROWLOCK` giúp khóa dòng bàn đang xử lý. Mục tiêu là tránh hai người cùng đổi một bàn trong cùng thời điểm.

Sau khi kiểm tra hợp lệ, service update:

```sql
UPDATE dbo.Orders
SET tableName=?
WHERE tableName=?
AND status IN ('Pending','Preparing','Ready','Served')
```

Sau đó ghi:

```text
SystemLogs.actionType = TABLE_TRANSFER
```

### 9.6. Debug lỗi đổi bàn

- Không vào được trang: kiểm tra `SecurityFilter.transferPages`.
- Không thấy bàn nguồn: kiểm tra `page-table-transfer.js` điều kiện `table.busy && table.status !== 'Paid'`.
- Không thấy bàn đích: kiểm tra bàn đó có đơn đang mở không.
- Backend báo bàn mới đang có khách: kiểm tra `countOpenOrders()` trong `LiteService`.
- Đổi xong nhưng UI chưa đổi: kiểm tra `loadTables()` có chạy lại không.
