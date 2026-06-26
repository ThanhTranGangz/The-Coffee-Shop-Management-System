# Giải Thích Code Frontend

## 1. Frontend trong project được tổ chức thế nào?

Frontend gồm hai phần:

```text
web/*.jsp hoặc web/index.html      khung HTML của từng trang
web/assets/js/*.js                 logic JavaScript của từng trang
web/assets/css/app.css             giao diện chung
```

Các file JSP hiện chủ yếu giữ cấu trúc trang: nav, form, section, nơi đặt `id` để JavaScript render dữ liệu vào. Logic chính nằm trong các file JS riêng.

Ví dụ:

```text
menu.jsp
  -> assets/js/page-menu.js

cashier.jsp
  -> assets/js/page-cashier.js

dashboard.jsp
  -> assets/js/page-dashboard.js
```

Việc tách JS ra khỏi JSP giúp NetBeans ít báo lỗi hơn và code dễ đọc hơn.

## 2. `i18n.js` là file dùng chung toàn hệ thống

File:

```text
web/assets/js/i18n.js
```

File này có nhiều nhiệm vụ:

1. Lưu từ điển tiếng Việt/tiếng Anh.
2. Cung cấp hàm dịch `t(key)`.
3. Cung cấp hàm gọi API `api(path, options)`.
4. Format tiền bằng `money(value)`.
5. Format trạng thái đơn bằng `statusText(status)`.
6. Render thanh điều hướng theo role.
7. Xử lý logout.
8. Hiển thị modal input.
9. Hiển thị toast và phát âm thanh thông báo.

## 3. Cách đổi ngôn ngữ hoạt động

Ngôn ngữ được lưu trong `localStorage`:

```javascript
const LANG_KEY = 'coffeshop_lang';
```

Hàm:

```javascript
lang()
```

trả về `vi` hoặc `en`.

Hàm:

```javascript
t(key)
```

lấy text tương ứng từ `dict`.

Khi bấm nút đổi ngôn ngữ:

```javascript
toggleLang()
  -> setLang(nextLang())
  -> applyI18n()
  -> nếu trang có window.renderPage thì render lại
```

Lý do cần render lại: nhiều text được sinh bằng JavaScript, ví dụ tab, card đơn, status, tiền. Nếu chỉ đổi text tĩnh trong HTML thì các phần render động không đổi.

## 4. Hàm `api(path, options)`

Trong `i18n.js` có:

```javascript
function api(path, options) {
    return fetch('api' + path, Object.assign({ credentials: 'same-origin' }, options || {}));
}
```

Nghĩa là khi frontend gọi:

```javascript
api('/orders')
```

thì request thật là:

```text
/api/orders
```

`credentials: 'same-origin'` giúp browser gửi kèm session cookie. Nhờ vậy backend biết người gọi API là admin, pha chế, thu ngân hay bồi bàn.

## 5. Thanh điều hướng `nav(role)`

Hàm `nav(role)` tạo menu theo vai trò.

Ví dụ:

- Admin thấy dashboard, bàn QR, thực đơn, pha chế, thu ngân, gọi món tại quầy, bồi bàn, đổi bàn, log.
- Pha chế chỉ thấy pha chế và đăng xuất.
- Thu ngân thấy thu ngân, gọi món tại quầy, đổi bàn, đăng xuất.
- Bồi bàn thấy bồi bàn, đổi bàn, đăng xuất.
- Khách chỉ thấy gọi món và tra đơn.

Điểm quan trọng: frontend ẩn chức năng theo role để giao diện gọn. Backend vẫn là nơi chặn quyền thật bằng `SecurityFilter`.

## 6. Logout hoạt động như thế nào?

Hàm:

```javascript
logout()
```

Nếu role là cashier, trước khi logout sẽ:

1. Gọi `/api/cash/status` để lấy tiền mặt hiện có.
2. Mở modal nhập tiền mặt hiện tại.
3. Gửi `/api/cash/count`.
4. Nếu thành công mới gọi `/api/auth/logout`.

Nếu không phải cashier, logout gọi thẳng:

```text
POST /api/auth/logout
```

Sau logout:

- Admin quay về `dashboard.jsp`.
- Nhân viên quay về `staff-login.jsp`.

## 7. `page-staff-login.js`

File:

```text
web/assets/js/page-staff-login.js
```

Nhiệm vụ: đăng nhập nhân viên.

Biến chính:

```javascript
selectedRole = 'barista'
```

Khi bấm chọn vai trò, hàm `chooseRole(role)` đổi `selectedRole` và active button.

Khi submit form:

```javascript
POST /api/auth/login
body: { username: selectedRole, password: pin }
```

Nếu login đúng:

```text
barista -> staff-orders.jsp
cashier -> cashier.jsp
runner  -> runner.jsp
```

Nếu sai, hiện thông báo lỗi.

## 8. `page-menu.js` - giao diện khách gọi món

File:

```text
web/assets/js/page-menu.js
```

Đây là file frontend quan trọng nhất cho khách.

Các biến chính:

```javascript
menuItems
tables
cart
currentItem
currentQty
currentSize
preferredTable
preferredTableCode
lockedTable
```

### 8.1. Khi trang load

`DOMContentLoaded` làm:

1. Đọc query string `tableCode`.
2. Đọc bàn đã lưu trong `sessionStorage`.
3. Gắn event cho ô search.
4. Gắn event cho bottom sheet chọn món.
5. Gọi `loadData()`.

### 8.2. `loadData()`

Hàm này gọi song song:

```javascript
api('/menu')
api('/tables')
```

Sau đó gọi `applyQrTable()` để kiểm tra nếu URL có `tableCode`.

Nếu vào bằng QR hợp lệ:

- `preferredTable` được đặt thành tên bàn.
- `lockedTable = true`.
- select bàn bị disable.
- sessionStorage lưu `selectedTable` và `selectedTableCode`.

### 8.3. Render menu

Các hàm:

```javascript
renderChips()
renderMenu()
filteredItems()
displayName()
priceFor()
```

`filteredItems()` lọc món theo category và search text.

`displayName()` chọn tên Việt hoặc Anh tùy ngôn ngữ.

`priceFor(item, size)` cộng giá gốc với tiền chênh size.

### 8.4. Bottom sheet chọn món

Khi khách bấm món:

```javascript
openSheet(id)
```

Hàm này:

1. Tìm món theo id.
2. Reset số lượng về 1.
3. Chọn size đầu tiên nếu có.
4. Render danh sách size.
5. Mở sheet.

Khi bấm thêm vào giỏ:

```javascript
addSheetItem()
```

Nếu trong giỏ đã có cùng món, cùng size, cùng ghi chú thì cộng số lượng. Nếu chưa có thì push dòng mới vào `cart`.

### 8.5. Gửi đơn

Hàm:

```javascript
submitOrder()
```

Nó gom dữ liệu:

- `tableName`.
- `note`.
- `items`.

Sau đó gọi:

```text
POST /api/orders
```

Nếu thành công, backend trả đơn có `orderNumber`. Frontend hiện link sang trang tra đơn:

```text
order-status.jsp?tableCode=...
```

## 9. `page-order-status.js`

File:

```text
web/assets/js/page-order-status.js
```

Nhiệm vụ: cho khách xem đơn đang xử lý.

Nếu URL có `tableCode` hoặc `table`, trang gọi:

```text
GET /api/orders/table
```

và tự refresh mỗi 5 giây.

Timeline khách thấy gồm:

```text
Pending -> Preparing -> Ready -> Served
```

Nếu đơn đã `Paid` hoặc `Cleared`, frontend vẫn hiển thị như `Served` cho khách. Lý do: khách không cần thấy chi tiết nội bộ sau thanh toán.

## 10. `page-staff-orders.js` - pha chế

File:

```text
web/assets/js/page-staff-orders.js
```

Các trạng thái:

```javascript
const statuses = ['Pending', 'Preparing', 'Ready'];
```

Trang load:

1. Lấy session để biết role.
2. Lấy số cốc.
3. Lấy danh sách đơn.
4. Poll đơn mỗi 5 giây.
5. Poll số cốc mỗi 6 giây.

`loadOrders()` gọi:

```text
GET /api/orders?view=barista
```

`renderTabs()` vẽ tab và số đơn.

`renderBoard()` chỉ render đơn thuộc tab đang chọn.

`nextStatus(status)` định nghĩa:

```text
Pending -> Preparing
Preparing -> Ready
Ready -> không có bước tiếp
```

Khi giữ thẻ đơn `0.5` giây:

```javascript
beginHold(...)
  -> setTimeout(..., 500)
  -> setStatus(id, next)
```

`setStatus()` gọi:

```text
POST /api/orders/status
```

Nếu chuyển sang `Ready`, frontend gọi lại `loadCupStatus()` để cập nhật số cốc.

## 11. `page-cashier.js` - thu ngân

File:

```text
web/assets/js/page-cashier.js
```

Thu ngân có hai tab:

```text
Unpaid, Paid
```

`loadOrders()` gọi:

```text
GET /api/orders?view=cashier
```

`filterOrders()` lọc:

- `Unpaid`: chỉ đơn `Served`.
- `Paid`: đơn `Paid` hoặc `Cleared` trong session thu ngân hiện tại.

Khi giữ đơn `0.5` giây:

```javascript
completeOrder(id)
  -> POST /api/orders/status
  -> status = Paid
```

`loadCashStatus()` gọi `/api/cash/status` để hiển thị tiền mặt và nhận thông báo admin rút tiền.

## 12. `page-runner.js` - bồi bàn

File:

```text
web/assets/js/page-runner.js
```

Trạng thái bồi bàn quan tâm:

```javascript
const runnerStatuses = ['Ready', 'Paid'];
```

Ý nghĩa:

- `Ready`: đơn chờ phục vụ.
- `Paid`: bàn chờ dọn.

`loadWork()` gọi song song:

```text
GET /api/orders?view=runner
GET /api/tables/map
```

Sau đó tách:

```javascript
servingOrders = orders.filter(order => order.status === 'Ready')
cleaningTables = tables.filter(table => table.status === 'Paid')
```

Khi giữ đơn ở tab phục vụ:

```text
POST /api/orders/status
status = Served
```

Khi giữ bàn ở tab chờ dọn:

```text
POST /api/tables/clear
```

Trang này cũng render sơ đồ bàn để bồi bàn thấy vị trí bàn cần xử lý.

## 13. `page-dashboard.js` - admin

File:

```text
web/assets/js/page-dashboard.js
```

Khi load:

1. Gọi `/api/auth/session`.
2. Nếu role là admin thì mở dashboard.
3. Nếu chưa phải admin thì hiện form nhập PIN.

Khi nhập PIN:

```text
POST /api/auth/admin-pin
```

Sau khi mở khóa, `loadStats()` gọi song song:

```text
GET /api/dashboard
GET /api/tables/map
GET /api/cash/status
```

`renderDashboard()` vẽ:

- Tab ngày/tuần/tháng/năm/tất cả/custom.
- Biểu đồ doanh thu.
- Hai món bán chạy.
- Sơ đồ bàn.
- Chi tiết doanh thu ở phần details.

`adminWithdrawCash()` mở modal rút tiền và gọi:

```text
POST /api/cash/withdraw
```

## 14. `page-admin-menu.js`

File:

```text
web/assets/js/page-admin-menu.js
```

Nhiệm vụ: admin quản lý món.

`loadItems()` gọi `/api/menu`. Vì admin có session admin, backend trả cả món đang bán và món ẩn.

`edit(id)` đổ dữ liệu món lên form.

`toggleSizeEditor()` bật/tắt phần size.

`readSizeRows()` đọc size từ form.

`saveItem(event)` gửi:

```text
POST /api/menu
```

`removeItem(id)` gửi:

```text
POST /api/menu/delete
```

## 15. `page-admin-tables.js`

File:

```text
web/assets/js/page-admin-tables.js
```

Nhiệm vụ: admin quản lý bàn và QR.

Các hàm quan trọng:

- `defaultBaseUrl()`: lấy link gốc hiện tại.
- `qrBaseUrl()`: lấy link gốc mà admin nhập.
- `orderUrl(table)`: tạo link order của bàn.
- `qrUrl(table, download)`: tạo link gọi API lấy QR SVG.
- `loadTables()`: gọi `/api/tables/all`.
- `saveTable()`: lưu bàn.
- `toggleTable()`: ẩn/hiện bàn.
- `regenerate()`: đổi code QR.
- `deleteTableHard()`: xóa bàn với xác nhận 2 lớp.
- `copyLink()`: copy link order của bàn.

## 16. `page-counter-order.js`

File:

```text
web/assets/js/page-counter-order.js
```

Nhiệm vụ: thu ngân/admin tạo đơn tại quầy.

Nó dùng logic giống menu khách nhưng tối giản:

- Lấy menu và bàn.
- Chọn bàn.
- Bấm món/size để thêm vào giỏ.
- Nhập ghi chú.
- Gửi `POST /api/orders`.

Đơn sau khi tạo vẫn là `Pending` và đi vào luồng pha chế như bình thường.

## 17. `page-table-transfer.js`

File:

```text
web/assets/js/page-table-transfer.js
```

Nhiệm vụ: đổi bàn.

`loadTables()` gọi:

```text
GET /api/tables/map
```

`renderTransfer()` chia bàn thành:

- `sources`: bàn đang bận và chưa `Paid`.
- `targets`: bàn trống.

Khi submit:

```text
POST /api/tables/transfer
body: { fromTableId, toTableId }
```

Sau khi đổi thành công, trang reload lại sơ đồ bàn.

## 18. `page-system-logs.js`

File:

```text
web/assets/js/page-system-logs.js
```

Nhiệm vụ: admin xem log.

`loadLogs()` gọi:

```text
GET /api/logs
```

`renderLogs()` render tab lọc theo actor:

```text
all, guest, admin, barista, cashier, runner
```

Nếu đang ở tiếng Anh, log dùng `messageEn`. Nếu tiếng Việt, log dùng `messageVi`.

## 19. Vì sao mỗi trang có `window.renderPage`?

`i18n.js` gọi:

```javascript
if (window.renderPage) window.renderPage();
```

khi đổi ngôn ngữ. Vì vậy mỗi trang định nghĩa `window.renderPage` để biết cách vẽ lại UI của chính nó.

Ví dụ:

- Menu render lại tên món và category.
- Cashier render lại tab và status.
- Dashboard render lại nhãn biểu đồ.
- Logs render lại message theo ngôn ngữ.

## 20. Mapping từng JSP với file JavaScript

Để debug frontend nhanh, dùng bảng này:

| Màn hình | File giao diện | File logic | API chính |
| --- | --- | --- | --- |
| Trang chủ | `index.html` | `i18n.js` | `/api/auth/session` |
| Khách gọi món | `menu.jsp` | `page-menu.js` | `/api/menu`, `/api/tables`, `/api/tables/by-code`, `/api/orders` |
| Khách tra đơn | `order-status.jsp` | `page-order-status.js` | `/api/orders/table`, `/api/orders/lookup` |
| Login nhân viên | `staff-login.jsp` | `page-staff-login.js` | `/api/auth/login` |
| Pha chế | `staff-orders.jsp` | `page-staff-orders.js` | `/api/orders`, `/api/orders/status`, `/api/cups/status` |
| Thu ngân | `cashier.jsp` | `page-cashier.js` | `/api/orders`, `/api/orders/status`, `/api/cash/status` |
| Bồi bàn | `runner.jsp` | `page-runner.js` | `/api/orders`, `/api/tables/map`, `/api/tables/clear` |
| Admin dashboard | `dashboard.jsp` | `page-dashboard.js` | `/api/auth/admin-pin`, `/api/dashboard`, `/api/tables/map`, `/api/cash/status` |
| Admin menu | `admin-menu.jsp` | `page-admin-menu.js` | `/api/menu`, `/api/menu/delete` |
| Admin bàn/QR | `admin-tables.jsp` | `page-admin-tables.js` | `/api/tables/all`, `/api/tables`, `/api/tables/qr`, `/api/tables/regenerate` |
| Gọi món tại quầy | `counter-order.jsp` | `page-counter-order.js` | `/api/menu`, `/api/tables`, `/api/orders` |
| Đổi bàn | `table-transfer.jsp` | `page-table-transfer.js` | `/api/tables/map`, `/api/tables/transfer` |
| Log hệ thống | `system-logs.jsp` | `page-system-logs.js` | `/api/logs` |

## 21. Quy ước `id` trong JSP và JavaScript

Các JSP tạo sẵn container có `id`. JavaScript dùng `document.getElementById(...)` để render vào đó.

Ví dụ `menu.jsp`:

```text
menu-list       nơi render danh sách món
chips           nơi render category
cart-list       nơi render giỏ hàng
submit-order    nút gửi đơn
table-welcome   thông báo nhận bàn từ QR
```

Ví dụ `cashier.jsp`:

```text
cashier-tabs    tab chưa thanh toán / đã thanh toán
cashier-orders  danh sách đơn
cash-panel      tiền mặt hiện có
```

Ví dụ `dashboard.jsp`:

```text
admin-pin-gate          overlay nhập PIN
revenue-tabs            tab ngày/tuần/tháng/năm
chart                   vùng biểu đồ
summary                 2 món bán chạy
table-map               sơ đồ bàn
detail-box/details      thông tin chi tiết
```

Nếu UI trắng hoặc không render, nên kiểm tra đầu tiên xem id trong JSP có khớp với id JavaScript đang gọi không.

## 22. Frontend không dùng framework

Project không dùng React/Vue/Angular. Giao diện render bằng:

```javascript
element.innerHTML = `...`
```

Ưu điểm:

- Dễ chạy trong project JSP/Servlet.
- Không cần npm.
- Dễ mở bằng NetBeans.

Nhược điểm:

- Phải tự escape HTML bằng `escapeHtml`.
- Phải tự quản lý state như `cart`, `activeStatus`, `activeRange`.
- Khi đổi ngôn ngữ phải tự gọi `renderPage`.

Vì vậy trong các file JS thường có hàm:

```javascript
escapeHtml()
escapeAttr()
escapeJs()
```

Mục đích là tránh lỗi HTML khi dữ liệu có ký tự đặc biệt.

## 23. Debug frontend theo triệu chứng

| Triệu chứng | Kiểm tra file |
| --- | --- |
| Bấm nút không chạy | Kiểm tra hàm onclick trong JSP/HTML sinh ra bởi JS |
| Không gọi được API | Kiểm tra `i18n.js/api()` và Network tab |
| Text không đổi ngôn ngữ | Kiểm tra key trong `dict` và `window.renderPage` |
| Menu không hiện món | Kiểm tra `page-menu.js/loadData()` và `/api/menu` |
| Đơn không chuyển trạng thái | Kiểm tra `beginHold()`, `setStatus()`, `/api/orders/status` |
| QR không hiện | Kiểm tra `page-admin-tables.js/qrUrl()` và `/api/tables/qr` |
| Sơ đồ bàn sai | Kiểm tra `/api/tables/map` và hàm `renderTableMap()` |
