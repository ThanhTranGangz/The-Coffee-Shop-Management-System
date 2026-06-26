# Tài Liệu Preview Tổng Quan Hệ Thống Coffeshop

## 1. Hệ thống này dùng để làm gì?

Đây là hệ thống quản lý quán cà phê phiên bản rút gọn nhưng vẫn có đầy đủ luồng vận hành chính của một quán thật. Mục tiêu của hệ thống là xử lý một vòng đời đơn hàng từ lúc khách ngồi vào bàn, quét QR để gọi món, cho tới khi món được pha chế, phục vụ, thanh toán và bàn được dọn xong.

Hệ thống được thiết kế để dễ demo, dễ giải thích và dễ debug trong NetBeans. Vì vậy các chức năng quá phức tạp như tài khoản thành viên, voucher nâng cao hoặc tích hợp ngân hàng thật đã được lược bỏ. Phần còn lại tập trung vào quy trình cốt lõi:

```text
Khách gọi món -> Pha chế xử lý -> Bồi bàn phục vụ -> Thu ngân thanh toán -> Bồi bàn dọn bàn -> Admin xem báo cáo
```

## 2. Các file preview chi tiết

| File | Nội dung |
| --- | --- |
| `01-admin.md` | Admin quản lý dashboard, menu, bàn, QR, log, tiền mặt |
| `02-guest.md` | Khách quét QR, gọi món và xem đơn của đúng bàn |
| `03-barista.md` | Pha chế nhận đơn, chuyển trạng thái và quản lý số cốc |
| `04-waiter.md` | Bồi bàn phục vụ món, dọn bàn và xem sơ đồ bàn |
| `05-cashier.md` | Thu ngân thanh toán, chốt tiền mặt và gọi món tại quầy |
| `06-change-table.md` | Quy trình đổi bàn cho khách |
| `07-counter-order.md` | Chức năng gọi món tại quầy cho khách không quét QR |
| `08-qrcode.md` | Cách QR riêng của từng bàn hoạt động |
| `09-code-backend.md` | Giải thích code backend: DB, Filter, Servlet, Service |
| `10-code-frontend.md` | Giải thích code frontend: JSP và JavaScript từng màn hình |
| `11-code-workflows.md` | Giải thích code theo từng luồng chạy thực tế |

## 2.1. Cách đọc tài liệu ở mức code hệ thống

Từ bản này, mỗi file preview không chỉ mô tả chức năng mà còn chỉ rõ:

- File JSP nào là màn hình.
- File JavaScript nào điều khiển màn hình đó.
- API nào được gọi.
- API đó đi vào case nào trong `LiteApiServlet`.
- Hàm nào trong `LiteService` xử lý nghiệp vụ.
- Dữ liệu được đọc/ghi ở bảng nào trong SQL Server.
- Thư viện/jar nào được dùng nếu chức năng cần thư viện ngoài.
- Nếu lỗi thì nên debug ở file nào trước.

Ví dụ với QR:

```text
admin-tables.jsp
  -> page-admin-tables.js tạo link api/tables/qr
  -> SecurityFilter cho phép GET /api/tables/qr
  -> LiteApiServlet.writeTableQr()
  -> thư viện ZXing trong lib/zxing-core-3.5.3.jar
  -> QRCodeWriter tạo BitMatrix
  -> qrSvg() chuyển BitMatrix thành SVG
  -> Tables.code là mã nhận diện bàn
  -> menu.jsp?tableCode=... dùng code đó để khóa bàn cho khách
```

Đây là cách đọc xuyên suốt toàn bộ hệ thống: đi từ giao diện, qua JavaScript, qua API, qua service, xuống database rồi quay lại giao diện.

## 2.2. Bản đồ thư viện và cấu hình build

Các thư viện ngoài nằm trong thư mục:

```text
lib/
```

Các jar quan trọng:

| Jar | Dùng để làm gì | Nơi được dùng |
| --- | --- | --- |
| `sqljdbc42.jar` | JDBC driver để Java kết nối SQL Server | `DBContext.java` |
| `zxing-core-3.5.3.jar` | Sinh QR code | `LiteApiServlet.java` |
| `jakarta.servlet.jsp.jstl-*.jar` | Hỗ trợ JSP/JSTL nếu cần | Build web app |
| `jaxb-api-2.1.jar` | Thư viện phụ trợ tương thích Java cũ | Build classpath |

NetBeans biết các jar này qua:

```text
nbproject/project.properties
```

Trong đó có:

```text
file.reference.sqljdbc42.jar=lib/sqljdbc42.jar
file.reference.zxing-core-3.5.3.jar=lib/zxing-core-3.5.3.jar
javac.classpath=...
```

Khi build WAR, NetBeans/Ant copy các jar vào:

```text
WEB-INF/lib
```

Khai báo copy nằm trong:

```text
nbproject/project.xml
```

Vì vậy nếu máy khác pull project về mà báo thiếu thư viện, cần kiểm tra thư mục `lib` và hai file cấu hình `nbproject/project.properties`, `nbproject/project.xml`.

## 3. Công nghệ sử dụng

Hệ thống dùng mô hình Java Web truyền thống, phù hợp để mở và chạy bằng NetBeans.

| Thành phần | Công nghệ | Vai trò |
| --- | --- | --- |
| Giao diện | JSP, HTML, CSS, JavaScript thuần | Hiển thị màn hình khách, nhân viên và admin |
| Backend | Java Servlet | Nhận request từ frontend, xử lý API |
| Database | Microsoft SQL Server | Lưu bàn, món, đơn hàng, log, tiền mặt |
| Kết nối database | JDBC | Java kết nối và truy vấn SQL Server |
| Server chạy web | Apache Tomcat 10 | Deploy và chạy project JSP/Servlet |
| Build project | Ant / NetBeans | Biên dịch Java và đóng gói WAR |
| QR code | ZXing | Sinh QR SVG cho từng bàn |
| Đa ngôn ngữ | JavaScript `i18n.js` | Chuyển giao diện tiếng Việt / tiếng Anh |

Các file quan trọng:

```text
src/java/servlet/LiteApiServlet.java      API chính của hệ thống
src/java/servlet/SecurityFilter.java      Kiểm soát quyền truy cập
src/java/service/LiteService.java         Logic nghiệp vụ và truy vấn database
src/java/context/DBContext.java           Cấu hình kết nối SQL Server
web/assets/js/i18n.js                     Ngôn ngữ Việt / Anh
web/assets/css/app.css                    Giao diện toàn hệ thống
```

## 4. Cách hệ thống chạy từ frontend đến database

Khi người dùng thao tác trên web, luồng xử lý cơ bản là:

```text
Trình duyệt
  -> mở file JSP
  -> JavaScript gọi API bằng fetch()
  -> LiteApiServlet nhận request
  -> LiteService xử lý logic
  -> JDBC truy vấn SQL Server
  -> trả JSON về frontend
  -> giao diện cập nhật lại
```

Ví dụ khách bấm xác nhận gọi món:

```text
menu.jsp
  -> page-menu.js
  -> POST /api/orders
  -> LiteApiServlet
  -> LiteService.createOrder()
  -> ghi Orders và OrderItems vào SQL Server
  -> trả mã đơn về giao diện
```

Điểm quan trọng để giải thích với người khác: JSP chỉ là phần hiển thị. Logic chính không nằm rải rác trong JSP mà được gom vào JavaScript phía giao diện và Java Servlet/Service phía backend.

## 5. Các vai trò trong hệ thống

| Vai trò | Cách vào | Mã PIN demo | Nhiệm vụ |
| --- | --- | --- | --- |
| Khách / Guest | Quét QR hoặc mở `menu.jsp` | Không cần | Xem menu, gọi món, xem đơn của bàn |
| Admin | Mở `dashboard.jsp` | `8888` | Quản lý toàn hệ thống |
| Pha chế / Barista | `staff-login.jsp` | `1111` | Xử lý đơn từ mới đến sẵn sàng |
| Thu ngân / Cashier | `staff-login.jsp` | `2222` | Thanh toán, gọi món tại quầy, tiền mặt |
| Bồi bàn / Waiter | `staff-login.jsp` | `3333` | Phục vụ món, dọn bàn, đổi bàn |

Trong code, vai trò bồi bàn còn có tên kỹ thuật là `runner`. Đây chỉ là tên nội bộ trong code, còn giao diện và tài liệu dùng tên dễ hiểu là bồi bàn / waiter.

## 6. Vòng đời đơn hàng

Đơn hàng đi theo một chiều cố định:

```text
Pending -> Preparing -> Ready -> Served -> Paid -> Cleared
```

Giải thích từng trạng thái:

| Trạng thái | Ý nghĩa | Ai xử lý |
| --- | --- | --- |
| `Pending` | Đơn mới được tạo, đang chờ pha chế nhận | Pha chế |
| `Preparing` | Pha chế đã nhận và đang làm | Pha chế |
| `Ready` | Món đã xong, chờ bồi bàn mang ra | Bồi bàn |
| `Served` | Bồi bàn đã phục vụ cho khách, chờ thanh toán | Thu ngân |
| `Paid` | Thu ngân đã xác nhận thanh toán, bàn chờ dọn | Bồi bàn |
| `Cleared` | Bàn đã được dọn, đơn hoàn tất và lưu lịch sử | Hệ thống / Admin xem báo cáo |

Các màn hình nhân viên chuyển trạng thái bằng thao tác giữ thẻ đơn trong `0.5` giây. Cách này giảm bấm nhầm trên điện thoại nhưng vẫn đủ nhanh để thao tác khi quán đông.

## 7. Vì sao phải tách từng vai trò?

Nếu mọi người đều nhìn thấy mọi chức năng, hệ thống sẽ dễ nhầm và khó dùng. Ví dụ:

- Khách không nên thấy đơn của bàn khác.
- Pha chế không cần thấy doanh thu.
- Bồi bàn không cần thấy giá tiền.
- Thu ngân không nên sửa menu.
- Admin cần nhìn toàn cảnh nhưng không nhất thiết thao tác như khách.

Vì vậy hệ thống dùng `SecurityFilter` để kiểm soát quyền. Nếu người dùng vào sai trang, hệ thống sẽ chuyển về trang đăng nhập hoặc trang dashboard phù hợp.

## 8. Database lưu những gì?

Database chính là `CoffeeShopLite`.

Các bảng quan trọng:

| Bảng | Dùng để lưu |
| --- | --- |
| `Users` | Tài khoản/PIN của nhân viên |
| `Tables` | Bàn, tầng, số bàn, mã QR, trạng thái ẩn/hiện |
| `MenuItems` | Món, tên Việt/Anh, nhóm món, giá, ảnh |
| `MenuItemSizes` | Size của món, ví dụ S/M/L và tiền chênh |
| `Orders` | Đơn hàng, bàn, tổng tiền, ghi chú, trạng thái |
| `OrderItems` | Chi tiết món trong đơn |
| `CashEvents` | Lịch sử chốt tiền, rút tiền, số dư tiền mặt |
| `StoreState` | Trạng thái chung của quán, ví dụ số cốc còn lại |
| `SystemLogs` | Nhật ký thao tác của khách, nhân viên, admin |

## 9. Luồng demo nên trình bày

Khi demo với giảng viên hoặc người khác, có thể đi theo thứ tự này:

1. Admin mở `dashboard.jsp`, nhập PIN `8888`.
2. Admin vào `Bàn & QR`, tải QR của một bàn.
3. Khách quét QR hoặc mở link `menu.jsp?tableCode=...`.
4. Khách chọn món, size, số lượng, ghi chú và gửi đơn.
5. Pha chế đăng nhập PIN `1111`, thấy đơn ở `Pending`.
6. Pha chế giữ đơn để chuyển sang `Preparing`, sau đó giữ tiếp để chuyển sang `Ready`.
7. Bồi bàn đăng nhập PIN `3333`, thấy đơn sẵn sàng phục vụ.
8. Bồi bàn giữ đơn để chuyển sang `Served`.
9. Thu ngân đăng nhập PIN `2222`, thấy đơn chưa thanh toán.
10. Thu ngân giữ đơn để chuyển sang `Paid`.
11. Bồi bàn thấy bàn chờ dọn, giữ bàn để chuyển sang `Cleared`.
12. Admin quay lại dashboard để xem doanh thu, sơ đồ bàn và log hệ thống.

Đây là vòng khép kín của một đơn hàng thật trong quán.
