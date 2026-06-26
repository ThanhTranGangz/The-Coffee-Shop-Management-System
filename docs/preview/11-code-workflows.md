# Giải Thích Code Theo Luồng Chạy Thực Tế

## 1. Luồng tổng quát của một request

Mọi thao tác trong hệ thống đều đi theo mô hình:

```text
JSP/HTML
  -> JavaScript
  -> fetch API
  -> SecurityFilter
  -> LiteApiServlet
  -> LiteService
  -> SQL Server
  -> JSON response
  -> JavaScript render lại giao diện
```

Ví dụ đơn giản: pha chế giữ đơn để chuyển trạng thái.

```text
staff-orders.jsp
  -> page-staff-orders.js
  -> POST /api/orders/status
  -> SecurityFilter kiểm tra role barista
  -> LiteApiServlet kiểm tra chuyển trạng thái hợp lệ
  -> LiteService.updateOrderStatus()
  -> UPDATE Orders SET status = ...
  -> ghi SystemLogs
  -> trả JSON đơn mới
  -> frontend load lại danh sách đơn
```

## 2. Luồng khách quét QR và gọi món

### Bước 1: Admin tạo QR

Trong `page-admin-tables.js`, mỗi bàn có link:

```javascript
orderUrl(table)
```

Link có dạng:

```text
menu.jsp?tableCode=CODE_CUA_BAN
```

Khi admin tải QR, frontend gọi:

```text
GET /api/tables/qr?code=...&base=...&download=1
```

`LiteApiServlet.writeTableQr()` tạo SVG QR bằng ZXing.

### Bước 2: Khách quét QR

Khách mở:

```text
menu.jsp?tableCode=...
```

Trong `page-menu.js`, `DOMContentLoaded` đọc:

```javascript
preferredTableCode = params.get('tableCode')
```

Sau đó `loadData()` gọi:

```text
GET /api/menu
GET /api/tables
```

và gọi tiếp:

```javascript
applyQrTable()
```

Nếu code hợp lệ, `applyQrTable()`:

- Gán tên bàn vào `preferredTable`.
- Đặt `lockedTable = true`.
- Disable select bàn.
- Lưu bàn vào `sessionStorage`.

### Bước 3: Khách chọn món

Khi bấm món:

```javascript
openSheet(id)
```

Khi chọn size/số lượng và bấm thêm:

```javascript
addSheetItem()
```

Món được đưa vào mảng `cart`.

### Bước 4: Khách gửi đơn

Khi bấm xác nhận:

```javascript
submitOrder()
```

Frontend gửi:

```text
POST /api/orders
```

Body gồm:

```json
{
  "tableName": "Tầng 1 - Bàn 2",
  "customerPhone": "",
  "note": "Ít đá",
  "items": [
    { "menuItemId": 1, "size": "M", "quantity": 2 }
  ]
}
```

`LiteApiServlet` gọi:

```java
service.createOrder(body)
```

`LiteService.createOrder()`:

1. Insert `Orders`.
2. Insert từng dòng `OrderItems`.
3. Tính tổng tiền.
4. Tạo `orderNumber`.
5. Ghi log `ORDER_CREATE`.
6. Trả đơn về frontend.

Sau đó frontend hiện link xem trạng thái đơn.

## 3. Luồng xem trạng thái đơn của khách

Trang:

```text
order-status.jsp
```

Nếu có `tableCode`, `page-order-status.js` gọi:

```text
GET /api/orders/table?tableCode=...
```

`LiteApiServlet` gọi:

```java
service.getOpenOrdersByTable(tableCode, table)
```

Service:

1. Nếu có `tableCode`, tìm bàn bằng `getTableByCode`.
2. Lấy các đơn của bàn đó với status:

```text
Pending, Preparing, Ready, Served, Paid
```

3. Gắn `items` vào từng đơn.
4. Trả JSON.

Frontend vẽ timeline:

```text
Pending -> Preparing -> Ready -> Served
```

Nếu đơn đã `Paid` hoặc `Cleared`, frontend vẫn hiển thị như đã phục vụ, vì khách không cần xem chi tiết nội bộ thanh toán/dọn bàn.

## 4. Luồng pha chế

Trang:

```text
staff-orders.jsp
```

File JS:

```text
page-staff-orders.js
```

### Bước 1: Lấy đơn pha chế

Frontend gọi:

```text
GET /api/orders?view=barista
```

`LiteApiServlet.orderViewRole(req)` quyết định view là `barista`.

`LiteService.getOrders("barista")` chỉ lấy:

```text
Pending, Preparing, Ready
```

### Bước 2: Hiển thị theo tab

`renderTabs()` tạo 3 tab:

```text
Pending, Preparing, Ready
```

`renderBoard()` chỉ vẽ đơn thuộc tab đang chọn.

### Bước 3: Giữ đơn để chuyển trạng thái

Khi người dùng giữ thẻ đơn:

```javascript
beginHold(event, action)
```

Sau `500ms`, action được chạy:

```javascript
setStatus(id, next)
```

Frontend gửi:

```text
POST /api/orders/status
```

Backend kiểm tra:

```java
canSetStatus("barista", currentStatus, nextStatus)
```

Chỉ cho:

```text
Pending -> Preparing
Preparing -> Ready
```

### Bước 4: Trừ số cốc

Nếu chuyển:

```text
Preparing -> Ready
```

`LiteService.updateOrderStatus()` gọi:

```java
cupCountForOrder(con, id)
```

Hàm này đếm số lượng món thuộc category đồ uống. Nếu còn đủ cốc, trừ `cupsAvailable`. Nếu không đủ, ném lỗi và trạng thái không đổi.

## 5. Luồng bồi bàn phục vụ

Trang:

```text
runner.jsp
```

File JS:

```text
page-runner.js
```

Frontend gọi song song:

```text
GET /api/orders?view=runner
GET /api/tables/map
```

`LiteService.getOrders("runner")` lấy:

```text
Ready, Paid
```

Sau đó frontend chia thành:

```javascript
servingOrders = orders.filter(order => order.status === 'Ready')
cleaningTables = tables.filter(table => table.status === 'Paid')
```

### Phục vụ món

Bồi bàn giữ đơn ở tab phục vụ:

```text
POST /api/orders/status
status = Served
```

Backend chỉ cho role `runner` chuyển:

```text
Ready -> Served
```

Sau bước này đơn chuyển sang màn hình thu ngân.

### Dọn bàn

Sau khi thu ngân thanh toán, bàn có đơn `Paid`. Bồi bàn giữ thẻ bàn:

```text
POST /api/tables/clear
```

`LiteService.clearServedTable()` tìm đơn `Paid` mới nhất của bàn, rồi update:

```text
Paid -> Cleared
```

Đây là bước kết thúc pipeline. Bàn trở lại trạng thái sẵn sàng.

## 6. Luồng thu ngân thanh toán

Trang:

```text
cashier.jsp
```

File JS:

```text
page-cashier.js
```

Frontend gọi:

```text
GET /api/orders?view=cashier
```

`LiteService.getOrders("cashier")` lấy:

- Đơn `Served`.
- Các đơn `Paid` nằm trong session hiện tại của thu ngân.

Khi thu ngân giữ đơn:

```javascript
completeOrder(id)
```

Frontend gửi:

```text
POST /api/orders/status
status = Paid
```

Backend chỉ cho:

```text
Served -> Paid
```

Sau khi thành công, `LiteApiServlet` gọi:

```java
rememberPaidOrder(req, orderId)
```

để đơn đó hiện trong tab đã thanh toán của session hiện tại.

## 7. Luồng thu ngân logout và chốt tiền

Logout nằm trong `i18n.js`.

Khi role là cashier:

1. Gọi `/api/cash/status`.
2. Mở modal nhập tiền mặt hiện tại.
3. Gửi:

```text
POST /api/cash/count
```

4. Nếu thành công mới gọi:

```text
POST /api/auth/logout
```

Backend xử lý `/cash/count` bằng:

```java
service.recordCashierCount(...)
```

Hàm này ghi:

- `CashEvents` với type `CASHIER_COUNT`.
- `SystemLogs` với type `CASH_COUNT`.

Điểm cần nói rõ: việc đơn hàng `Paid` không tự tăng tiền mặt. Tiền mặt trong bản demo được xác nhận khi thu ngân chốt ca.

## 8. Luồng admin rút tiền

Trong `page-dashboard.js`, admin bấm rút tiền:

```javascript
adminWithdrawCash()
```

Frontend mở modal nhập số tiền, sau đó gọi:

```text
POST /api/cash/withdraw
```

Backend:

1. Kiểm tra role phải là admin.
2. Gọi `service.withdrawCash(amount, user)`.
3. Kiểm tra số tiền rút không vượt số dư.
4. Insert `CashEvents` type `ADMIN_WITHDRAW`.
5. Ghi log `CASH_WITHDRAW`.

Thu ngân ở `page-cashier.js` poll `/api/cash/status`. Nếu có withdrawal chưa seen, thu ngân nhận popup và hệ thống gọi `/api/cash/ack-withdrawals`.

## 9. Luồng gọi món tại quầy

Trang:

```text
counter-order.jsp
```

File:

```text
page-counter-order.js
```

Khác với `menu.jsp`, trang này dành cho thu ngân/admin. Nhưng khi submit, nó vẫn gọi cùng API:

```text
POST /api/orders
```

Vì vậy đơn tại quầy và đơn khách QR dùng chung database, chung dashboard và chung workflow.

Sau khi tạo, đơn có status:

```text
Pending
```

và xuất hiện ở màn hình pha chế.

## 10. Luồng đổi bàn

Trang:

```text
table-transfer.jsp
```

File:

```text
page-table-transfer.js
```

Frontend gọi:

```text
GET /api/tables/map
```

Rồi chia:

```javascript
sources = tables.filter(table => table.busy && table.status !== 'Paid')
targets = tables.filter(table => !table.busy)
```

Nghĩa là:

- Bàn nguồn phải có khách và chưa vào giai đoạn chờ dọn.
- Bàn đích phải trống.

Khi submit:

```text
POST /api/tables/transfer
```

Backend:

1. Kiểm tra role admin/cashier/runner.
2. Gọi `service.transferTable`.
3. Khóa hai bàn cần xử lý bằng query `WITH (UPDLOCK, ROWLOCK)`.
4. Kiểm tra bàn nguồn có đơn.
5. Kiểm tra bàn đích trống.
6. Update `tableName` của các đơn đang mở.
7. Ghi log `TABLE_TRANSFER`.

## 11. Luồng admin quản lý menu

Trang:

```text
admin-menu.jsp
```

Frontend:

```text
page-admin-menu.js
```

Khi lưu món:

```text
POST /api/menu
```

Backend:

```java
service.saveMenuItem(body)
```

Service validate:

- Tên.
- Category.
- Giá.
- Ảnh.
- Size.
- Trùng tên.

Sau đó insert/update `MenuItems` và `MenuItemSizes`.

Khi xóa món:

```text
POST /api/menu/delete
```

Service không xóa cứng, mà update:

```text
active = 0
```

Cách này giữ được dữ liệu lịch sử đơn hàng cũ.

## 12. Luồng admin quản lý bàn và QR

Trang:

```text
admin-tables.jsp
```

Frontend:

```text
page-admin-tables.js
```

Khi thêm/sửa bàn:

```text
POST /api/tables
```

`LiteService.saveTable()`:

- Chuẩn hóa tên bàn.
- Kiểm tra tầng.
- Kiểm tra số bàn.
- Kiểm tra trùng vị trí.
- Nếu thêm mới thì sinh QR code bằng `uniqueTableCode`.

Khi regenerate QR:

```text
POST /api/tables/regenerate
```

Service update code mới. QR cũ trở nên không nên dùng nữa.

Khi xóa bàn:

```text
POST /api/tables/delete
```

Service chỉ cho xóa nếu bàn không có đơn đang mở.

## 13. Luồng dashboard doanh thu

Admin mở dashboard, frontend gọi:

```text
GET /api/dashboard
GET /api/tables/map
GET /api/cash/status
```

`LiteService.getDashboard()` trả:

- Counts theo trạng thái đơn.
- Revenue tổng.
- Revenue series.
- Top products.
- Range details.

Các series:

```text
day    -> revenueByHour
week   -> revenueByDay 7 ngày
month  -> revenueByDay 30 ngày
year   -> revenueByMonth 12 tháng
all    -> revenueByMonth từ tháng đầu có dữ liệu
custom -> tự chọn; ngắn thì theo giờ/ngày, dài thì theo tháng
```

Frontend `page-dashboard.js` lấy series theo `activeRange`, tính tổng chart và render biểu đồ.

## 14. Luồng log hệ thống

Mỗi hành động quan trọng đều gọi:

```java
insertSystemLog(...)
```

hoặc:

```java
service.addSystemLog(...)
```

Log lưu:

- `actorRole`.
- `actorName`.
- `actionType`.
- `messageVi`.
- `messageEn`.
- `refId`.
- `createdAt`.

Trang `system-logs.jsp` gọi:

```text
GET /api/logs
```

và lọc phía frontend theo actor.

Điểm nên trình bày: log giúp debug workflow. Nếu đơn bị kẹt, admin có thể xem ai đã thao tác bước cuối cùng.

## 15. Vì sao code dùng cả frontend check và backend check?

Frontend check giúp giao diện dễ dùng:

- Ẩn nút không đúng role.
- Chỉ render trạng thái hợp lệ.
- Chỉ cho chọn bàn phù hợp.

Backend check giúp bảo mật và tránh dữ liệu sai:

- `SecurityFilter` chặn API sai role.
- `canSetStatus` chặn chuyển trạng thái sai.
- `LiteService` validate menu, bàn, tiền, size.
- SQL transaction tránh lưu dữ liệu nửa vời.

Khi trình bày, có thể nói: frontend giúp trải nghiệm tốt, backend mới là nơi đảm bảo luật hệ thống.

## 16. Workflow QR chi tiết kiểu trace file

Đây là ví dụ đầy đủ nhất để giải thích hệ thống theo cấp file.

```text
1. Admin mở admin-tables.jsp
2. admin-tables.jsp load page-admin-tables.js
3. page-admin-tables.js gọi GET /api/tables/all
4. LiteApiServlet.doGet case "/tables/all"
5. LiteService.getAllTables()
6. SQL đọc bảng Tables
7. Frontend render QR card cho từng bàn
8. page-admin-tables.js/qrUrl() tạo link api/tables/qr
9. Browser gọi GET /api/tables/qr?code=...&base=...
10. SecurityFilter cho qua vì /api/tables/qr là public GET API
11. LiteApiServlet.doGet thấy path "/tables/qr"
12. LiteApiServlet.writeTableQr()
13. writeTableQr() gọi LiteService.getTableByCode(code)
14. SQL đọc Tables WHERE code=? AND active=1
15. writeTableQr() ghép menu.jsp?tableCode=...
16. qrSvg() dùng QRCodeWriter trong zxing-core-3.5.3.jar
17. QRCodeWriter tạo BitMatrix
18. qrSvg() chuyển BitMatrix thành SVG
19. Browser hiển thị hoặc tải SVG
20. Khách quét SVG bằng camera điện thoại
21. Điện thoại mở menu.jsp?tableCode=...
22. page-menu.js đọc tableCode
23. page-menu.js/applyQrTable() gọi /api/tables/by-code nếu cần
24. LiteService.getTableByCode() trả thông tin bàn
25. page-menu.js khóa select bàn
26. Khách gửi order thì tableName là đúng bàn đó
```

Điểm trình bày: QR không phải chỉ là hình ảnh. Nó là mắt xích nối `Tables.code` trong database với `menu.jsp?tableCode=...` trên điện thoại khách.

## 17. Workflow order chi tiết kiểu trace file

```text
1. Khách bấm xác nhận trong menu.jsp
2. page-menu.js/submitOrder()
3. Tạo JSON gồm tableName, note, items
4. POST /api/orders
5. SecurityFilter cho qua vì POST /api/orders là public API
6. LiteApiServlet.doPost case "/orders"
7. JsonUtils.parseObject() parse body
8. LiteService.createOrder(body)
9. INSERT Orders, lấy orderId
10. Lặp từng item
11. getMenuItem(menuId) đọc MenuItems và MenuItemSizes
12. normalizeSize() kiểm tra size hợp lệ
13. priceForSize() tính giá chính thức
14. INSERT OrderItems
15. UPDATE Orders SET orderNumber=1000+id,total=...
16. INSERT SystemLogs ORDER_CREATE
17. commit transaction
18. getOrderById(orderId) lấy lại đơn
19. JsonUtils.toJson() trả JSON
20. page-menu.js hiện mã đơn và link tra đơn
```

Nếu đơn không tạo được, trace này giúp biết lỗi nằm ở frontend gửi thiếu item, API bị chặn, service validate lỗi hay database lỗi.

## 18. Workflow trạng thái đơn chi tiết kiểu trace file

```text
1. Nhân viên giữ card 0.5s
2. page-*.js/beginHold() chạy setTimeout 500ms
3. Gọi action tương ứng: setStatus/completeOrder/serveOrder
4. POST /api/orders/status
5. SecurityFilter kiểm tra role có được gọi /api/orders/status không
6. LiteApiServlet đọc id và status mới
7. service.getOrderById(id) lấy trạng thái hiện tại
8. canSetStatus(role, currentStatus, nextStatus)
9. Nếu hợp lệ: service.updateOrderStatus()
10. updateOrderStatus() khóa dòng Orders bằng UPDLOCK, ROWLOCK
11. Nếu Preparing -> Ready thì trừ cốc
12. UPDATE Orders SET status=?
13. INSERT SystemLogs ORDER_STATUS
14. commit
15. Frontend load lại danh sách đơn
```

Mapping actor:

```text
barista: Pending -> Preparing -> Ready
runner: Ready -> Served
cashier: Served -> Paid
runner clear table: Paid -> Cleared qua /api/tables/clear
```

## 19. Workflow database khởi tạo

Khi app lần đầu gọi database:

```text
DBContext.getConnection()
  -> ensureDatabase()
  -> nếu CoffeeShopLite chưa tồn tại thì CREATE DATABASE
  -> trả connection tới CoffeeShopLite
```

Khi `LiteService` được tạo:

```text
LiteService.INSTANCE
  -> constructor
  -> init()
  -> CREATE TABLE nếu thiếu
  -> seed()
```

`seed()` tạo:

- User demo.
- 12 bàn chuẩn.
- Code QR cho bàn.
- Menu mẫu.
- Lịch sử doanh thu demo.
- Số cốc ban đầu.

Vì vậy nếu xóa database rồi chạy lại app, hệ thống có thể tự dựng lại cấu trúc cơ bản.

## 20. Cách trình bày khi giảng viên hỏi “chức năng này nằm ở đâu?”

Câu trả lời nên theo mẫu:

```text
Chức năng này bắt đầu ở file JSP ..., logic frontend ở file JS ...,
frontend gọi API ..., API được route vào LiteApiServlet case ...,
nghiệp vụ nằm ở LiteService hàm ...,
dữ liệu lưu ở bảng ...,
nếu cần thư viện ngoài thì jar nằm ở lib/... và khai báo trong nbproject/project.properties.
```

Ví dụ QR:

```text
QR bắt đầu từ admin-tables.jsp, logic ở page-admin-tables.js,
frontend gọi GET /api/tables/qr, servlet xử lý bằng writeTableQr(),
QR được sinh bằng thư viện ZXing trong lib/zxing-core-3.5.3.jar,
mã bàn nằm ở Tables.code, khách quét xong vào menu.jsp?tableCode=...
```

Ví dụ thanh toán:

```text
Thu ngân thao tác ở cashier.jsp, logic ở page-cashier.js,
frontend gọi POST /api/orders/status với status Paid,
LiteApiServlet kiểm tra canSetStatus(),
LiteService.updateOrderStatus() cập nhật Orders.status,
log ghi vào SystemLogs, đơn Paid được lưu vào session paidOrderIds để thu ngân xem lại trong ca.
```
