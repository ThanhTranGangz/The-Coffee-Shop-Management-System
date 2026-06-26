# Preview Admin

## 1. Admin là ai trong hệ thống?

Admin là người quản lý toàn bộ quán. Admin không phải là nhân viên vận hành theo ca như pha chế, thu ngân hay bồi bàn. Admin có quyền xem báo cáo, chỉnh thực đơn, quản lý bàn, quản lý QR, xem log và kiểm tra các màn hình làm việc của nhân viên.

Admin không đăng nhập ở trang `staff-login.jsp`. Thay vào đó, admin mở trực tiếp:

```text
/dashboard.jsp
```

Màn hình dashboard sẽ có lớp khóa yêu cầu nhập mã PIN:

```text
PIN admin: 8888
```

Sau khi nhập đúng PIN, backend lưu session với role là `admin`. Từ đó admin mới được gọi các API quản lý.

## 2. Vì sao admin dùng PIN riêng?

Vì trong bản demo này, admin không cần hệ thống tài khoản phức tạp. Mục tiêu là mở nhanh dashboard để trình bày, nhưng vẫn có lớp bảo vệ cơ bản để người không có quyền không xem được dữ liệu quản lý.

Về mặt kỹ thuật:

```text
dashboard.jsp
  -> nhập PIN
  -> POST /api/auth/admin-pin
  -> nếu PIN đúng, session.role = admin
```

## 3. Các chức năng chính của admin

Admin có các nhóm chức năng sau:

- Dashboard doanh thu.
- Sơ đồ bàn.
- Quản lý thực đơn.
- Quản lý bàn và QR.
- Gọi món tại quầy.
- Đổi bàn.
- Xem log hệ thống.
- Quản lý tiền mặt.
- Kiểm tra giao diện pha chế, thu ngân, bồi bàn.

## 4. Dashboard doanh thu

Dashboard là màn hình tổng quan của admin. Nó trả lời các câu hỏi:

- Quán đang thu được bao nhiêu tiền?
- Doanh thu thay đổi theo thời gian như thế nào?
- Hai sản phẩm bán chạy nhất trong khoảng đang xem là gì?
- Bàn nào đang có khách?
- Bàn nào đang chờ phục vụ, chờ thanh toán hoặc chờ dọn?

Các mốc thời gian có thể xem:

```text
Ngày, tuần, tháng, năm, tất cả, khoảng ngày tự chọn
```

Doanh thu chỉ tính các đơn đã thanh toán hoặc đã hoàn tất:

```text
Paid, Cleared
```

Lý do: nếu tính cả đơn chưa thanh toán thì báo cáo sẽ sai. Một đơn đang pha hoặc đang phục vụ chưa chắc đã thu tiền xong.

## 5. Sơ đồ bàn

Sơ đồ bàn giúp admin nhìn nhanh tình trạng quán. Hệ thống hiện chia bàn theo tầng, ví dụ 2 tầng, mỗi tầng 6 bàn.

Một bàn được coi là đang phục vụ nếu có đơn chưa kết thúc:

```text
Pending, Preparing, Ready, Served, Paid
```

Khi bồi bàn dọn xong và đơn chuyển sang `Cleared`, bàn trở lại trạng thái sẵn sàng.

## 6. Quản lý thực đơn

Trang:

```text
/admin-menu.jsp
```

Admin có thể thêm, sửa hoặc ẩn món. Mỗi món có:

- Tên tiếng Việt.
- Tên tiếng Anh.
- Nhóm món.
- Giá gốc.
- Ảnh hiển thị.
- Trạng thái đang bán hoặc ẩn.
- Danh sách size nếu món có size.

Các rule khi thêm/sửa món:

- Tên tiếng Việt và tiếng Anh phải từ 2 đến 80 ký tự.
- Giá từ 10.000đ đến 200.000đ.
- Giá phải chia hết cho 1.000đ.
- Không được trùng tên món.
- Ảnh phải nằm trong `assets/img/menu`.
- Nếu món có size, size `S` là giá gốc.
- Tiền chênh size phải hợp lệ, không âm và chia hết cho 1.000đ.

Những rule này giúp dữ liệu sạch. Nếu không có rule, admin có thể nhập sai giá, sai ảnh hoặc tạo món trùng tên, làm menu và báo cáo bị rối.

## 7. Quản lý bàn và QR

Trang:

```text
/admin-tables.jsp
```

Admin có thể:

- Thêm bàn.
- Sửa tầng và số bàn.
- Ẩn hoặc hiện bàn.
- Xóa bàn nếu bàn không có đơn đang mở.
- Tải QR riêng của từng bàn.
- Tạo lại mã QR nếu cần.

Mỗi bàn có một mã `code`. QR của bàn chứa link:

```text
/menu.jsp?tableCode=CODE_CUA_BAN
```

Khi khách quét QR, hệ thống biết khách đang ngồi bàn nào mà không cần khách tự chọn.

## 8. Quản lý tiền mặt

Admin có một ô nhỏ hiển thị số tiền mặt hiện có. Admin có thể rút tiền mặt. Khi rút:

1. Hệ thống kiểm tra số tiền rút có hợp lệ không.
2. Ghi sự kiện vào `CashEvents`.
3. Cập nhật số dư tiền mặt.
4. Ghi log vào `SystemLogs`.
5. Thu ngân sẽ nhận thông báo nếu đang online hoặc nhìn thấy ở lần đăng nhập sau.

Điểm cần nói rõ: tiền mặt trong hệ thống demo không tự tăng sau mỗi đơn thanh toán. Thu ngân chốt tiền khi kết thúc ca, còn admin có quyền rút tiền.

## 9. Log hệ thống

Trang:

```text
/system-logs.jsp
```

Log lưu lại các hành động quan trọng:

- Khách gọi món.
- Pha chế nhận đơn hoặc hoàn tất pha chế.
- Bồi bàn phục vụ hoặc dọn bàn.
- Thu ngân xác nhận thanh toán.
- Admin sửa menu, sửa bàn, rút tiền.
- Đổi bàn.

Admin có thể lọc theo actor để giải thích ai đã làm gì và làm lúc nào. Đây là phần quan trọng khi debug vì log cho biết lỗi xảy ra ở bước nào trong workflow.

## 10. Mổ code admin theo từng file

### 10.1. Dashboard admin

Các file tham gia:

| Tầng | File | Vai trò |
| --- | --- | --- |
| JSP | `web/dashboard.jsp` | Khung HTML của dashboard và form nhập PIN |
| JavaScript | `web/assets/js/page-dashboard.js` | Mở khóa admin, gọi API dashboard, render biểu đồ, sơ đồ bàn, tiền mặt |
| API | `src/java/servlet/LiteApiServlet.java` | Xử lý `/api/auth/admin-pin`, `/api/dashboard`, `/api/tables/map`, `/api/cash/status`, `/api/cash/withdraw` |
| Service | `src/java/service/LiteService.java` | Tính doanh thu, lấy sơ đồ bàn, xử lý rút tiền |
| Database | `Orders`, `OrderItems`, `Tables`, `CashEvents`, `SystemLogs` | Dữ liệu doanh thu, bàn, tiền mặt, log |

Luồng mở dashboard:

```text
dashboard.jsp load
  -> page-dashboard.js gọi GET /api/auth/session
  -> nếu role=session là admin thì gọi loadStats()
  -> nếu chưa có admin thì hiện overlay nhập PIN
```

Luồng nhập PIN:

```text
unlockAdminDashboard()
  -> POST /api/auth/admin-pin { pin }
  -> LiteApiServlet case "/auth/admin-pin"
  -> nếu pin == 8888 thì session.role = admin
  -> service.addSystemLog("admin", ..., "ADMIN_UNLOCK", ...)
  -> frontend gọi loadNav() và loadStats()
```

### 10.2. Dashboard lấy dữ liệu như thế nào?

Trong `page-dashboard.js`, hàm `loadStats()` gọi song song:

```javascript
Promise.all([
    api('/dashboard'),
    api('/tables/map'),
    api('/cash/status')
])
```

Đi qua backend:

```text
/api/dashboard   -> LiteApiServlet.doGet case "/dashboard"   -> LiteService.getDashboard()
/api/tables/map  -> LiteApiServlet.doGet case "/tables/map"  -> LiteService.getTableMap()
/api/cash/status -> LiteApiServlet.doGet case "/cash/status" -> LiteService.getCashStatus()
```

`LiteService.getDashboard()` đọc từ:

- `Orders`: tính số đơn, trạng thái và doanh thu.
- `OrderItems`: tính sản phẩm bán chạy và số sản phẩm đã bán.
- `MenuItems`: đếm số món đang bán.

Doanh thu chỉ tính:

```sql
WHERE status IN ('Paid','Cleared')
```

Vì `Paid` là đã thanh toán, còn `Cleared` là đã thanh toán và đã dọn xong.

### 10.3. Biểu đồ doanh thu nằm ở đâu?

Frontend:

```text
page-dashboard.js
```

Các hàm chính:

- `setRevenueRange(range)`: đổi ngày/tuần/tháng/năm/tất cả/thủ công.
- `renderCustomControls()`: hiện input chọn ngày bắt đầu/kết thúc.
- `lineChart(series)`: dựng biểu đồ bằng HTML/CSS, không dùng plugin chart ngoài.

Backend:

```text
LiteService.getRevenueSeriesMap()
```

Các hàm phụ:

- `revenueByHour`: doanh thu theo giờ trong ngày.
- `revenueByDay`: doanh thu theo ngày.
- `revenueByMonth`: doanh thu theo tháng.
- `revenueCustom`: tự chọn khoảng, ngắn thì theo giờ/ngày, dài thì theo tháng.

Điểm cần nói rõ: biểu đồ không dùng Chart.js hay plugin ngoài. Nó là HTML/CSS tự render từ dữ liệu JSON.

### 10.4. Admin quản lý menu đi qua file nào?

Luồng:

```text
admin-menu.jsp
  -> page-admin-menu.js
  -> POST /api/menu hoặc POST /api/menu/delete
  -> LiteApiServlet.doPost
  -> LiteService.saveMenuItem() hoặc deleteMenuItem()
  -> MenuItems, MenuItemSizes
```

`page-admin-menu.js` xử lý form, size, ảnh, active. `LiteService.saveMenuItem()` mới là nơi validate thật:

- Không trùng tên.
- Giá hợp lệ.
- Ảnh phải nằm trong `assets/img/menu`.
- Size S là giá gốc.
- Tiền chênh size hợp lệ.

Nếu muốn debug lỗi thêm/sửa món, đọc theo thứ tự:

```text
page-admin-menu.js -> LiteApiServlet case "/menu" -> LiteService.saveMenuItem()
```

### 10.5. Admin quản lý bàn và QR đi qua file nào?

Luồng:

```text
admin-tables.jsp
  -> page-admin-tables.js
  -> GET /api/tables/all
  -> POST /api/tables
  -> POST /api/tables/regenerate
  -> GET /api/tables/qr
  -> LiteService.saveTable(), regenerateTableCode(), getTableByCode()
  -> Tables
```

Mã QR không lưu hình ảnh trong database. Database chỉ lưu `Tables.code`. Khi cần tải QR, backend lấy `code`, ghép thành link menu, rồi sinh SVG ngay tại thời điểm request.

### 10.6. Admin rút tiền đi qua file nào?

Luồng:

```text
page-dashboard.js/adminWithdrawCash()
  -> POST /api/cash/withdraw
  -> LiteApiServlet case "/cash/withdraw"
  -> LiteService.withdrawCash()
  -> INSERT CashEvents eventType='ADMIN_WITHDRAW'
  -> INSERT SystemLogs actionType='CASH_WITHDRAW'
```

Nếu thu ngân đang online, `page-cashier.js` poll `/api/cash/status` và thấy withdrawal chưa đọc. Sau đó thu ngân nhận popup và gọi `/api/cash/ack-withdrawals`.
