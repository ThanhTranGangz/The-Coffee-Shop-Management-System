# Preview Waiter / Bồi Bàn

## 1. Vai trò của bồi bàn

Bồi bàn là người kết nối giữa pha chế, khách và thu ngân. Khi pha chế làm xong món, bồi bàn mang món ra bàn. Sau khi khách thanh toán, bồi bàn dọn bàn để bàn sẵn sàng cho lượt khách tiếp theo.

Trong code, vai trò này có tên kỹ thuật là `runner`. Tên này có nghĩa là người chạy đơn. Trên giao diện và tài liệu, ta gọi là bồi bàn / waiter để dễ hiểu hơn.

## 2. Cách đăng nhập

Trang đăng nhập:

```text
/staff-login.jsp
```

Chọn:

```text
Bồi bàn
```

PIN demo:

```text
3333
```

Sau khi đăng nhập, hệ thống chuyển tới:

```text
/runner.jsp
```

## 3. Bồi bàn xử lý những bước nào?

Bồi bàn xử lý hai giai đoạn:

```text
Ready -> Served
Paid -> Cleared
```

Giai đoạn 1:

- Đơn `Ready` nghĩa là pha chế đã làm xong.
- Bồi bàn mang món ra bàn.
- Sau khi giao món, giữ đơn `0.5` giây để chuyển sang `Served`.

Giai đoạn 2:

- Đơn `Paid` nghĩa là thu ngân đã xác nhận thanh toán.
- Bàn lúc này cần được dọn.
- Bồi bàn giữ thẻ bàn `0.5` giây để chuyển đơn sang `Cleared`.

Khi đơn đã `Cleared`, bàn trở lại trạng thái sẵn sàng.

## 4. Vì sao bồi bàn không thấy giá tiền?

Bồi bàn không cần biết tổng tiền của đơn để phục vụ món. Nếu hiển thị quá nhiều thông tin, giao diện sẽ rối và không đúng vai trò. Vì vậy hệ thống lọc dữ liệu trước khi trả về cho bồi bàn:

- Không hiển thị tổng tiền.
- Không hiển thị thông tin khách không cần thiết.
- Chỉ hiển thị bàn, số đơn, món, size, số lượng và ghi chú.

Đây là nguyên tắc phân quyền dữ liệu: mỗi người chỉ thấy dữ liệu cần cho công việc của mình.

## 5. Các tab của bồi bàn

Bồi bàn có hai tab chính:

- Phục vụ: chứa đơn `Ready`.
- Chờ dọn: chứa bàn có đơn `Paid`.

Khi bấm tab nào, chỉ hiện việc của tab đó. Màn hình vẫn hiển thị số lượng ở từng tab để nhân viên biết còn bao nhiêu việc.

## 6. Sơ đồ bàn

Bên dưới màn hình bồi bàn có sơ đồ bàn. Sơ đồ giúp biết nhanh:

- Bàn nào trống.
- Bàn nào đang có khách.
- Bàn nào chờ phục vụ.
- Bàn nào chờ dọn.

Sơ đồ này tối giản hơn admin. Mục tiêu là hỗ trợ thao tác thực tế, không phải xem báo cáo.

## 7. Dọn bàn kết thúc pipeline như thế nào?

Khi bồi bàn dọn bàn, hệ thống gọi:

```text
POST /api/tables/clear
```

Backend tìm đơn mới nhất của bàn đang ở trạng thái `Paid`, sau đó cập nhật:

```text
Paid -> Cleared
```

Đây là bước cuối cùng của vòng đời đơn hàng. Từ thời điểm này, đơn trở thành lịch sử để admin xem báo cáo.

## 8. API liên quan

```text
GET  /api/orders?view=runner
GET  /api/tables/map
POST /api/orders/status
POST /api/tables/clear
POST /api/tables/transfer
```

## 9. Điểm nên trình bày

Phần bồi bàn thể hiện rõ workflow thực tế:

- Pha chế xong chưa có nghĩa là khách đã nhận món.
- Khách nhận món xong chưa có nghĩa là đã thanh toán.
- Thanh toán xong chưa có nghĩa là bàn đã sẵn sàng.
- Chỉ khi bồi bàn dọn xong thì bàn mới kết thúc pipeline.

## 10. Mổ code luồng bồi bàn

### 10.1. Các file tham gia

| Tầng | File | Vai trò |
| --- | --- | --- |
| JSP | `web/runner.jsp` | Khung màn hình bồi bàn |
| JS | `web/assets/js/page-runner.js` | Load việc phục vụ/dọn bàn, render tab, sơ đồ bàn, giữ để chuyển |
| API | `LiteApiServlet.java` | `/api/orders`, `/api/orders/status`, `/api/tables/map`, `/api/tables/clear` |
| Service | `LiteService.java` | `getOrders("runner")`, `getRunnerTableMap`, `updateOrderStatus`, `clearServedTable` |
| DB | `Orders`, `OrderItems`, `Tables`, `SystemLogs` | Đơn, bàn, log |

### 10.2. Vì sao trong code gọi là runner?

Trong database/session/API, vai trò bồi bàn được lưu là:

```text
runner
```

Tên này xuất hiện trong:

- `Users.role`.
- `SecurityFilter`.
- `LiteApiServlet.canSetStatus`.
- `LiteService.getOrders("runner")`.
- `page-runner.js`.

Trên giao diện, `i18n.js` dịch `runner` thành `Bồi bàn` hoặc `Waiter`.

### 10.3. Load việc của bồi bàn

Trong `page-runner.js`, hàm `loadWork()` gọi song song:

```javascript
Promise.all([
    api('/orders?view=runner'),
    api('/tables/map')
])
```

Backend:

```text
/api/orders?view=runner -> LiteService.getOrders("runner")
/api/tables/map         -> LiteService.getRunnerTableMap() nếu role hiện tại là runner
```

`getOrders("runner")` chỉ lấy:

```sql
WHERE status IN ('Ready','Paid')
```

`getRunnerTableMap()` lọc bớt dữ liệu sơ đồ bàn để bồi bàn không thấy thông tin thừa.

### 10.4. Tách việc phục vụ và dọn bàn

Frontend chia dữ liệu:

```javascript
servingOrders = orders.filter(order => order.status === 'Ready');
cleaningTables = tables.filter(table => table.status === 'Paid');
```

- `Ready`: đơn pha chế xong, bồi bàn cần mang ra.
- `Paid`: khách trả tiền xong, bồi bàn cần dọn bàn.

### 10.5. Phục vụ món

Khi giữ đơn ở tab phục vụ:

```javascript
serveOrder(orderId)
  -> POST /api/orders/status
  -> status = 'Served'
```

Backend `canSetStatus()` chỉ cho runner chuyển:

```text
Ready -> Served
```

Sau khi chuyển, đơn không còn trong tab bồi bàn nữa mà sang thu ngân.

### 10.6. Dọn bàn

Khi giữ thẻ bàn ở tab chờ dọn:

```javascript
clearTable(tableId)
  -> POST /api/tables/clear
```

Backend:

```text
LiteApiServlet case "/tables/clear"
  -> service.clearServedTable(tableId, role, user)
```

`clearServedTable()` tìm đơn `Paid` mới nhất của bàn:

```sql
WHERE t.id=? AND o.status='Paid'
```

Sau đó update:

```sql
UPDATE Orders SET status='Cleared'
```

Đây là lý do chờ dọn không dùng `/api/orders/status`: hành động dọn bàn cần dựa theo `tableId`, không chỉ `orderId`.

### 10.7. Bồi bàn bị ẩn giá như thế nào?

Trong `LiteService.getOrders("runner")`, sau khi lấy đơn sẽ gọi:

```java
sanitizeRunnerOrders(list)
```

Hàm này xóa:

```text
order.total
order.customerPhone
item.price
```

Trong `LiteApiServlet`, nếu trả về một order đơn lẻ cho runner, cũng gọi `sanitizeRunnerOrder(updatedOrder)`.

Đây là phân quyền dữ liệu ở backend, không chỉ ẩn bằng CSS.
