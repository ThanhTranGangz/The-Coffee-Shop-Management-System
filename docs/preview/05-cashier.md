# Preview Cashier / Thu Ngân

## 1. Vai trò của thu ngân

Thu ngân chịu trách nhiệm xác nhận thanh toán, theo dõi tiền mặt và tạo đơn tại quầy cho khách không quét QR. Thu ngân không quản lý menu, không sửa bàn và không xem toàn bộ báo cáo như admin.

## 2. Cách đăng nhập

Trang:

```text
/staff-login.jsp
```

Chọn:

```text
Thu ngân
```

PIN demo:

```text
2222
```

Sau khi đăng nhập, hệ thống chuyển tới:

```text
/cashier.jsp
```

## 3. Thu ngân nhìn thấy đơn nào?

Thu ngân chủ yếu xử lý đơn ở trạng thái:

```text
Served
```

`Served` nghĩa là bồi bàn đã phục vụ món cho khách, khách đã nhận món và đơn đang chờ thanh toán.

Thu ngân giữ đơn `0.5` giây để chuyển:

```text
Served -> Paid
```

Sau khi chuyển sang `Paid`, đơn được lưu trong danh sách đã thanh toán của session hiện tại.

## 4. Vì sao danh sách đã thanh toán chỉ theo session?

Trong thực tế, thu ngân thường quan tâm các đơn đã thanh toán trong ca đang làm. Nếu hiển thị toàn bộ đơn cũ, màn hình sẽ rất rối.

Vì vậy hệ thống lưu các đơn đã thanh toán trong session đăng nhập hiện tại. Khi thu ngân logout và đăng nhập lại, danh sách này được reset.

Điều này giúp:

- Màn hình gọn.
- Dễ kiểm tra các đơn vừa xử lý.
- Không lẫn dữ liệu ca cũ.

Admin vẫn có thể xem dữ liệu lịch sử qua dashboard và log.

## 5. Tiền mặt hoạt động như thế nào?

Thu ngân có ô nhỏ hiển thị tiền mặt hiện có. Tuy nhiên, tiền mặt không tự tăng sau mỗi đơn `Paid`. Lý do là trong quán thật có nhiều phương thức thanh toán: tiền mặt, chuyển khoản, thẻ, ví điện tử. Bản demo không tích hợp thanh toán thật, nên tiền mặt được xử lý bằng thao tác chốt ca.

Khi thu ngân logout:

1. Hệ thống mở popup nhập số tiền mặt hiện tại.
2. Thu ngân bắt buộc nhập số tiền.
3. Backend ghi sự kiện `CASHIER_COUNT`.
4. Hệ thống cập nhật số dư tiền mặt.
5. Session đăng nhập kết thúc.

## 6. Admin rút tiền và thu ngân nhận thông báo

Admin có quyền rút tiền mặt. Khi admin rút:

- Sự kiện được ghi vào `CashEvents`.
- Số dư tiền mặt giảm.
- Thu ngân đang online sẽ thấy popup.
- Nếu thu ngân không online, lần đăng nhập sau sẽ thấy thông báo/lịch sử rút tiền.

Điều này mô phỏng việc quản lý lấy tiền khỏi két trong ca.

## 7. Gọi món tại quầy

Thu ngân có chức năng:

```text
/counter-order.jsp
```

Chức năng này dùng khi khách không quét QR, ví dụ khách gọi trực tiếp tại quầy. Thu ngân chọn bàn, chọn món, size, số lượng và ghi chú. Khi xác nhận, hệ thống tạo đơn `Pending` giống như khách gọi món từ QR.

## 8. Đổi bàn

Thu ngân cũng có thể vào:

```text
/table-transfer.jsp
```

Chức năng này dùng khi khách đã gọi món nhưng muốn chuyển bàn. Thu ngân có thể hỗ trợ đổi bàn mà không cần admin.

## 9. API liên quan

```text
GET  /api/orders?view=cashier
POST /api/orders/status
GET  /api/cash/status
POST /api/cash/count
POST /api/cash/ack-withdrawals
POST /api/orders
POST /api/tables/transfer
```

## 10. Điểm nên trình bày

Thu ngân là nơi chuyển đơn từ đã phục vụ sang đã thanh toán. Đây là điểm bắt đầu để doanh thu được tính. Trước khi `Paid`, đơn chưa được tính là doanh thu chính thức.

## 11. Mổ code luồng thu ngân

### 11.1. Các file tham gia

| Tầng | File | Vai trò |
| --- | --- | --- |
| JSP | `web/cashier.jsp` | Khung màn hình thu ngân |
| JS | `web/assets/js/page-cashier.js` | Load đơn chưa thanh toán, render tab, giữ để thanh toán, tiền mặt |
| JS chung | `web/assets/js/i18n.js` | Logout và popup chốt tiền mặt |
| API | `LiteApiServlet.java` | `/api/orders`, `/api/orders/status`, `/api/cash/status`, `/api/cash/count`, `/api/cash/ack-withdrawals` |
| Service | `LiteService.java` | `getOrders("cashier")`, `updateOrderStatus`, `getCashStatus`, `recordCashierCount` |
| DB | `Orders`, `OrderItems`, `CashEvents`, `SystemLogs` | Đơn, chi tiết đơn, tiền mặt, log |

### 11.2. Load đơn thu ngân

`page-cashier.js` gọi:

```text
GET /api/orders?view=cashier
```

`LiteService.getOrders("cashier", cashierSessionPaidIds)` xử lý:

- Nếu session chưa có đơn đã thanh toán thì chỉ lấy `status='Served'`.
- Nếu session có `paidOrderIds` thì lấy thêm các đơn đó.

Đoạn logic:

```text
WHERE status='Served'
hoặc
WHERE status='Served' OR id IN (paidOrderIds)
```

Vì vậy tab đã thanh toán của thu ngân chỉ hiện đơn trong ca/session hiện tại.

### 11.3. Tại sao phải có `paidOrderIds` trong session?

Khi thu ngân chuyển đơn sang `Paid`, đơn không còn `Served` nữa. Nếu query chỉ lấy `Served`, đơn vừa thanh toán sẽ biến mất ngay. Hệ thống muốn thu ngân vẫn xem lại đơn vừa xử lý trong ca, nên `LiteApiServlet` gọi:

```java
rememberPaidOrder(req, orderId)
```

Danh sách này được lưu trong session:

```java
session.setAttribute("paidOrderIds", new ArrayList<Integer>());
```

Khi logout, session bị invalidate nên danh sách reset.

### 11.4. Thanh toán đơn

Frontend:

```javascript
completeOrder(id)
  -> POST /api/orders/status
  -> status = 'Paid'
```

Backend:

```text
LiteApiServlet case "/orders/status"
  -> canSetStatus("cashier", "Served", "Paid")
  -> LiteService.updateOrderStatus()
  -> rememberPaidOrder()
```

Nếu đơn chưa ở `Served`, cashier không chuyển được sang `Paid`.

### 11.5. Tiền mặt và logout

Nút logout gọi hàm `logout()` trong `i18n.js`, không nằm riêng trong `page-cashier.js`.

Nếu session role là cashier:

```javascript
GET /api/cash/status
inputModal(...)
POST /api/cash/count
POST /api/auth/logout
```

Backend `/cash/count`:

```text
LiteApiServlet case "/cash/count"
  -> kiểm tra role phải là cashier
  -> LiteService.recordCashierCount()
```

`recordCashierCount()` insert:

```text
CashEvents.eventType = CASHIER_COUNT
SystemLogs.actionType = CASH_COUNT
```

### 11.6. Admin rút tiền và thu ngân thấy popup

`page-cashier.js` có `loadCashStatus()` chạy định kỳ. Nó gọi:

```text
GET /api/cash/status
```

Nếu response có `pendingWithdrawals`, frontend:

- Hiển thị toast.
- Hiện alert.
- Gọi `/api/cash/ack-withdrawals` để đánh dấu đã xem.

Trong database, cột `CashEvents.seenByCashier` quyết định sự kiện rút tiền đã được thu ngân nhìn thấy chưa.
