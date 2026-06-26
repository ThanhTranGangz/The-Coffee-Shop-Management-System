# Preview Guest / Khách Vãng Lai

## 1. Khách sử dụng hệ thống như thế nào?

Khách không cần tài khoản. Khi ngồi vào bàn, khách quét QR đặt trên bàn. QR sẽ mở menu của đúng bàn đó.

Link có dạng:

```text
/menu.jsp?tableCode=CODE_CUA_BAN
```

Ví dụ:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-main/menu.jsp?tableCode=TBL-ABC123
```

Trong thực tế, khi dùng điện thoại cùng mạng Wi-Fi, `localhost` phải được thay bằng địa chỉ IP của máy đang chạy Tomcat.

## 2. Vì sao khách không cần đăng nhập?

Đây là mô hình khách vãng lai tại quán. Khách chỉ cần gọi món, không cần quản lý tài khoản. Việc bắt khách đăng nhập sẽ làm trải nghiệm chậm và không phù hợp với quán cà phê nhỏ.

Hệ thống nhận diện khách qua bàn, không qua tài khoản. Bàn được nhận diện bằng QR.

## 3. Khi khách quét QR thì hệ thống làm gì?

Luồng xử lý:

```text
Khách quét QR
  -> mở menu.jsp?tableCode=...
  -> JavaScript đọc tableCode
  -> gọi GET /api/tables/by-code
  -> backend tìm bàn trong database
  -> nếu hợp lệ, giao diện khóa bàn đó
```

Khi bàn đã được khóa theo QR, khách không đổi bàn trên giao diện được nữa. Điều này tránh trường hợp khách ngồi bàn 2 nhưng chọn nhầm bàn 5.

## 4. Khách nhìn thấy gì?

Giao diện khách tập trung vào những thứ cần để gọi món:

- Danh sách món.
- Tìm kiếm món.
- Nhóm món.
- Ảnh món.
- Giá.
- Size nếu món có size.
- Số lượng.
- Ghi chú.
- Giỏ hàng.
- Nút xác nhận gọi món.

Trên mobile, giỏ hàng có thanh tóm tắt phía dưới để khách dễ mở lại trước khi gửi đơn.

## 5. Khách gọi món như thế nào?

Khách chọn món, chọn size, số lượng và ghi chú. Khi bấm xác nhận, frontend gửi API:

```text
POST /api/orders
```

Backend tạo:

- Một bản ghi trong `Orders`.
- Nhiều bản ghi trong `OrderItems`.

Đơn mới có trạng thái:

```text
Pending
```

Nghĩa là đơn vừa được gửi và đang chờ pha chế nhận.

## 6. Ghi chú đơn dùng để làm gì?

Ghi chú giúp khách nói rõ yêu cầu:

- Ít đá.
- Ít đường.
- Không kem.
- Mang bánh ra trước.
- Gộp ghi chú từng món và ghi chú chung.

Ghi chú này đi theo đơn trong toàn bộ workflow để pha chế, bồi bàn và thu ngân đều nhìn thấy khi cần.

## 7. Khách xem trạng thái đơn

Sau khi gọi món, khách có thể xem các đơn đang xử lý của đúng bàn.

Trang:

```text
/order-status.jsp?tableCode=CODE_CUA_BAN
```

API:

```text
GET /api/orders/table?tableCode=CODE_CUA_BAN
```

Trang này chỉ trả về đơn của bàn đó. Khách không nhập mã đơn để xem đơn của toàn bộ quán, vì như vậy sẽ không đúng bảo mật và không đúng trải nghiệm thực tế.

## 8. Khách không được làm gì?

Khách không được:

- Vào dashboard admin.
- Vào màn hình pha chế, thu ngân, bồi bàn.
- Xem đơn của bàn khác.
- Đổi bàn trên giao diện khi đã vào bằng QR.
- Xem doanh thu, log, tiền mặt.

Những giới hạn này giúp hệ thống rõ vai trò và tránh lộ dữ liệu nội bộ.

## 9. Mổ code luồng khách từ QR tới đơn hàng

### 9.1. Các file tham gia

| Tầng | File | Vai trò |
| --- | --- | --- |
| HTML/JSP | `web/menu.jsp` | Khung giao diện khách gọi món |
| JavaScript | `web/assets/js/page-menu.js` | Đọc QR code, tải menu/bàn, render món, giỏ hàng, gửi đơn |
| JavaScript chung | `web/assets/js/i18n.js` | Hàm `api()`, `money()`, `t()`, thanh nav khách |
| API | `LiteApiServlet.java` | Xử lý `/api/menu`, `/api/tables`, `/api/tables/by-code`, `/api/orders` |
| Service | `LiteService.java` | `getMenu`, `getTables`, `getTableByCode`, `createOrder` |
| Database | `Tables`, `MenuItems`, `MenuItemSizes`, `Orders`, `OrderItems`, `SystemLogs` | Lưu bàn, menu, đơn và log |

### 9.2. Khi khách mở link QR

Link QR có dạng:

```text
menu.jsp?tableCode=TB-XXXXXXX
```

Trong `page-menu.js`, đoạn đầu `DOMContentLoaded` đọc:

```javascript
const params = new URLSearchParams(location.search);
preferredTableCode = params.get('tableCode') || '';
```

Sau đó gọi `loadData()`.

`loadData()` gọi:

```javascript
const [menuRes, tableRes] = await Promise.all([api('/menu'), api('/tables')]);
```

Nghĩa là frontend lấy menu và danh sách bàn cùng lúc để load nhanh hơn.

### 9.3. `applyQrTable()` khóa bàn như thế nào?

Trong `page-menu.js`, hàm `applyQrTable()` làm:

1. Kiểm tra có `preferredTableCode` không.
2. Tìm bàn trong danh sách `tables`.
3. Nếu chưa thấy thì gọi:

```text
GET /api/tables/by-code?code=...
```

4. Nếu backend trả bàn hợp lệ:

```javascript
preferredTable = table.name;
qrTableName = table.name;
lockedTable = true;
document.body.classList.add('qr-locked');
sessionStorage.setItem('selectedTable', table.name);
sessionStorage.setItem('selectedTableCode', preferredTableCode);
```

`lockedTable = true` làm select bàn bị disable. Vì vậy khách vào bằng QR sẽ không đổi bàn được.

### 9.4. Menu lấy dữ liệu từ đâu?

Frontend gọi:

```text
GET /api/menu
```

`SecurityFilter.isPublicApi()` cho phép API này vì khách cần xem menu.

`LiteApiServlet.doGet` case `/menu` gọi:

```java
service.getMenu(admin)
```

Vì khách không phải admin, `admin = false`, nên `LiteService.getMenu(false)` chỉ query món:

```sql
WHERE active=1
```

Mỗi món còn được gắn thêm size bằng:

```java
item.put("sizes", getMenuSizes(...))
```

### 9.5. Khách chọn size và giá được tính ở đâu?

Frontend tính giá hiển thị trong `page-menu.js`:

```javascript
priceFor(item, size)
```

Hàm này lấy giá gốc `item.price`, rồi cộng `extraPrice` của size.

Nhưng giá chính thức vẫn được backend tính lại trong `LiteService.createOrder()` bằng:

```java
normalizeSize(menu, size)
priceForSize(menu, size)
```

Điều này quan trọng: dù người dùng sửa giá trên trình duyệt bằng DevTools, backend vẫn không tin giá frontend gửi lên. Frontend chỉ gửi `menuItemId`, `size`, `quantity`; backend tự lấy giá từ database.

### 9.6. Khi khách bấm xác nhận gọi món

`submitOrder()` trong `page-menu.js` gom dữ liệu:

```javascript
body: JSON.stringify({
    tableName: selectedTable(),
    customerPhone: '',
    note: orderNote,
    items: cart.map(line => ({
        menuItemId: line.menuItemId,
        size: line.size,
        quantity: line.quantity
    }))
})
```

Sau đó gọi:

```text
POST /api/orders
```

Backend:

```text
LiteApiServlet.doPost case "/orders"
  -> LiteService.createOrder(body)
```

`createOrder()` insert:

- `Orders`: tạo đơn tổng.
- `OrderItems`: tạo từng món trong đơn.
- `SystemLogs`: ghi khách đã gọi đơn.

Đơn mới mặc định có status `Pending`, vì trong bảng `Orders` cột `status` default là `Pending`.

### 9.7. Debug nếu khách không gọi món được

Kiểm tra theo thứ tự:

1. `menu.jsp` có load `page-menu.js` không.
2. Console browser có lỗi JavaScript không.
3. Network tab xem `POST /api/orders` trả status gì.
4. Nếu 401/403, kiểm tra `SecurityFilter.isPublicApi()` có cho `POST /api/orders` không.
5. Nếu 400, kiểm tra lỗi từ `LiteService.createOrder()`.
6. Nếu lỗi database, kiểm tra `DBContext.java`, SQL Server và bảng `Orders`, `OrderItems`.
