# Preview Barista / Pha Chế

## 1. Vai trò của pha chế

Pha chế chịu trách nhiệm xử lý các đơn đã được khách hoặc thu ngân gửi vào hệ thống. Pha chế không cần quan tâm tiền, đổi bàn hay quản lý menu. Màn hình pha chế chỉ tập trung vào một việc: nhận đơn và đưa đơn tới trạng thái sẵn sàng phục vụ.

## 2. Cách đăng nhập

Pha chế vào trang:

```text
/staff-login.jsp
```

Chọn vai trò:

```text
Pha chế
```

Nhập PIN demo:

```text
1111
```

Sau khi đăng nhập đúng, hệ thống chuyển tới:

```text
/staff-orders.jsp
```

## 3. Các trạng thái pha chế xử lý

Pha chế chỉ xử lý ba trạng thái đầu của đơn:

```text
Pending -> Preparing -> Ready
```

Ý nghĩa:

- `Pending`: đơn mới, chưa ai nhận pha.
- `Preparing`: pha chế đã nhận và đang làm.
- `Ready`: món đã xong, chờ bồi bàn mang ra cho khách.

Pha chế không được chuyển đơn sang `Served` hoặc `Paid`, vì đó là nhiệm vụ của bồi bàn và thu ngân.

## 4. Giao diện được thiết kế ra sao?

Màn hình pha chế có các tab:

- Chờ xử lý.
- Đang pha.
- Sẵn sàng.

Mỗi tab hiển thị số lượng đơn trong trạng thái đó. Khi bấm vào tab nào, chỉ hiện đơn thuộc tab đó. Cách này giúp màn hình mobile không bị rối và nhân viên không phải kéo quá nhiều.

Mỗi đơn hiển thị:

- Số đơn.
- Bàn.
- Danh sách món.
- Size.
- Số lượng.
- Ghi chú.

## 5. Cách chuyển trạng thái

Pha chế giữ thẻ đơn trong `0.5` giây để chuyển sang bước tiếp theo.

Luồng hợp lệ:

```text
Pending -> Preparing
Preparing -> Ready
```

Luồng không hợp lệ:

```text
Ready -> Preparing
Pending -> Ready
Preparing -> Served
```

Frontend không hiển thị nút chuyển sai, backend cũng kiểm tra lại bằng `canSetStatus()` trong `LiteApiServlet`. Nhờ đó hệ thống không chỉ dựa vào giao diện mà còn có kiểm tra phía server.

## 6. Quản lý số cốc

Pha chế có ô hiển thị số cốc còn lại. Số cốc được lưu trong bảng `StoreState` với key:

```text
cupsAvailable
```

Khi đơn chuyển từ `Preparing` sang `Ready`, hệ thống tính số cốc cần trừ theo số lượng đồ uống, không tính bánh.

Ví dụ:

```text
Cà phê sữa x2
Matcha latte x1
Bánh croissant x1
```

Số cốc cần trừ là `3`, vì bánh không dùng cốc.

Nếu số cốc còn lại không đủ, backend không cho chuyển đơn sang `Ready` và trả lỗi. Điều này mô phỏng tình huống thực tế: nếu hết cốc, pha chế không thể hoàn tất đơn nước.

## 7. Thông báo đơn mới

Trang pha chế tự động tải lại danh sách đơn theo chu kỳ. Khi có đơn mới ở trạng thái `Pending`, hệ thống hiện thông báo và phát âm thanh. Điều này giúp nhân viên không cần refresh thủ công.

## 8. API liên quan

```text
GET  /api/orders?view=barista
POST /api/orders/status
GET  /api/cups/status
POST /api/cups/update    chỉ admin được cập nhật số cốc
```

## 9. Điểm nên trình bày

Khi giải thích phần pha chế, nên nhấn mạnh:

- Pha chế chỉ thấy đúng việc của mình.
- Trạng thái đơn đi một chiều.
- Giữ `0.5` giây giúp tránh bấm nhầm trên điện thoại.
- Số cốc được trừ theo số lượng đồ uống, không trừ theo số đơn.

## 10. Mổ code luồng pha chế

### 10.1. Các file tham gia

| Tầng | File | Vai trò |
| --- | --- | --- |
| JSP | `web/staff-orders.jsp` | Khung màn hình pha chế |
| JS | `web/assets/js/page-staff-orders.js` | Load đơn, render tab, giữ đơn để chuyển trạng thái, hiển thị số cốc |
| JS chung | `web/assets/js/i18n.js` | API helper, toast, âm báo |
| API | `LiteApiServlet.java` | `/api/orders`, `/api/orders/status`, `/api/cups/status`, `/api/cups/update` |
| Service | `LiteService.java` | `getOrders("barista")`, `updateOrderStatus`, `cupCountForOrder`, `getCupStatus` |
| DB | `Orders`, `OrderItems`, `MenuItems`, `StoreState`, `SystemLogs` | Đơn, món, loại món, số cốc, log |

### 10.2. Load đơn pha chế

Trong `page-staff-orders.js`:

```javascript
loadOrders()
  -> api('/orders?view=barista')
```

Ở backend:

```text
LiteApiServlet.doGet case "/orders"
  -> service.getOrders(orderViewRole(req), ...)
```

`LiteService.getOrders("barista")` thêm điều kiện SQL:

```sql
WHERE status IN ('Pending','Preparing','Ready')
```

Vì vậy pha chế không lấy đơn `Served`, `Paid`, `Cleared`.

### 10.3. Tab Pending/Preparing/Ready hoạt động thế nào?

Frontend có:

```javascript
const statuses = ['Pending', 'Preparing', 'Ready'];
let activeStatus = 'Pending';
```

`renderTabs()` đếm số đơn theo từng status. `renderBoard()` chỉ lấy:

```javascript
orders.filter(order => order.status === activeStatus)
```

Do đó khi bấm tab nào thì chỉ hiện đơn tab đó, không phải render cả 3 cột dài.

### 10.4. Giữ đơn 0.5 giây nằm ở đâu?

Trong `page-staff-orders.js`:

```javascript
holdTimer = setTimeout(async () => {
    await action();
}, 500);
```

CSS hiệu ứng nằm ở:

```text
web/assets/css/app.css
```

Class chính:

```text
.hold-card.holding:after
animation: hold-fill .5s linear forwards;
```

Vì vậy cả logic và hiệu ứng đều là 0.5 giây.

### 10.5. Backend kiểm soát chuyển trạng thái

Frontend gọi:

```text
POST /api/orders/status
body: { id, status }
```

`LiteApiServlet` lấy status hiện tại của đơn:

```java
Map<String, Object> order = service.getOrderById(orderId);
```

Sau đó gọi:

```java
canSetStatus(currentRole, currentStatus, status)
```

Với role `barista`, chỉ hợp lệ:

```text
Pending -> Preparing
Preparing -> Ready
```

Nếu cố chuyển sai, backend trả lỗi `FORBIDDEN`.

### 10.6. Trừ cốc hoạt động thế nào?

Khi status hiện tại là `Preparing` và status mới là `Ready`, `LiteService.updateOrderStatus()` chạy:

```java
int requiredCups = cupCountForOrder(con, id);
int cups = stateValueForUpdate(con, "cupsAvailable", 0);
```

`cupCountForOrder()` join:

```sql
OrderItems oi
JOIN MenuItems mi ON mi.id = oi.menuItemId
```

Nếu `mi.category` là đồ uống thì cộng `oi.quantity`.

Số cốc được lưu trong:

```text
StoreState.stateKey = 'cupsAvailable'
```

Nếu thiếu cốc, service ném lỗi và không update `Orders.status`.

### 10.7. Debug lỗi pha chế

- Không thấy đơn: kiểm tra `GET /api/orders?view=barista` và `LiteService.getOrders("barista")`.
- Không chuyển trạng thái: kiểm tra `canSetStatus()` trong `LiteApiServlet`.
- Không trừ cốc: kiểm tra `cupCountForOrder()` và category trong `MenuItems`.
- Số cốc âm/sai: kiểm tra `StoreState` và `updateCupStock()`.
