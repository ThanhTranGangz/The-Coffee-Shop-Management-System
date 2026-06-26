# Preview QR Code Theo Bàn

## 1. QR trong hệ thống dùng để làm gì?

QR giúp hệ thống biết khách đang ngồi bàn nào. Mỗi bàn có một QR riêng. Khách quét QR của bàn nào thì website tự mở menu của bàn đó.

Nếu không có QR riêng, khách sẽ phải tự chọn bàn. Khi quán đông, khách chọn nhầm bàn là lỗi rất dễ xảy ra. QR theo bàn giải quyết vấn đề đó.

## 2. QR dẫn tới link nào?

Mỗi QR chứa một link dạng:

```text
/menu.jsp?tableCode=CODE_CUA_BAN
```

Ví dụ:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-main/menu.jsp?tableCode=TBL-ABC123
```

Khi demo bằng điện thoại cùng Wi-Fi, cần thay `localhost` bằng IP của máy chạy Tomcat:

```text
http://192.168.1.10:8080/The-Coffee-Shop-Management-System-main/menu.jsp?tableCode=TBL-ABC123
```

## 3. Admin quản lý QR ở đâu?

Trang:

```text
/admin-tables.jsp
```

Admin có thể:

- Xem danh sách bàn.
- Xem mã code của bàn.
- Copy link order của bàn.
- Tải QR dạng SVG.
- Tạo lại QR.
- Ẩn hoặc hiện bàn.
- Xóa bàn nếu bàn không có đơn đang mở.

## 4. QR được tạo như thế nào?

Backend có endpoint:

```text
GET /api/tables/qr?code=CODE&base=BASE_URL&size=420&download=1
```

`LiteApiServlet` dùng thư viện ZXing để tạo QR. QR được xuất dạng SVG. SVG có ưu điểm là nhẹ, rõ nét và in ra không bị vỡ hình.

## 5. Khi khách quét QR thì chuyện gì xảy ra?

Luồng xử lý:

```text
Khách quét QR
  -> mở menu.jsp?tableCode=...
  -> page-menu.js đọc tableCode
  -> gọi GET /api/tables/by-code
  -> LiteService tìm bàn theo code
  -> trả thông tin bàn
  -> giao diện khóa bàn đó
```

Sau khi bàn đã khóa, đơn khách tạo sẽ gắn với đúng `tableName` của bàn đó.

## 6. Vì sao cần regenerate QR?

Admin có thể tạo lại mã QR trong các trường hợp:

- QR cũ bị in sai.
- QR cũ bị người khác dùng nhầm.
- Muốn vô hiệu hóa link cũ.
- Thay tem QR mới cho bàn.

Khi regenerate, hệ thống tạo `code` mới cho bàn. QR cũ không còn nên dùng nữa vì nó không còn đại diện chính xác cho bàn hiện tại.

## 7. Vì sao QR không cần dịch vụ ngoài?

QR chỉ là hình chứa một đường link. Hệ thống tự sinh QR bằng backend Java, không cần gọi API ngoài. Điều này phù hợp yêu cầu chạy local:

- Không cần internet.
- Không phụ thuộc bên thứ ba.
- Dễ demo trong mạng nội bộ.
- Dễ in QR cho từng bàn.

## 8. Điểm nên trình bày

QR theo bàn là điểm bắt đầu của toàn bộ workflow. Nếu nhận diện bàn đúng, các bước sau mới đúng:

```text
Pha chế biết đơn của bàn nào
Bồi bàn biết mang món ra đâu
Thu ngân biết bàn nào cần thanh toán
Admin xem sơ đồ bàn chính xác
```

Vì vậy QR không chỉ là tiện ích giao diện, mà là cơ chế nhận diện bàn của hệ thống.

## 9. Mổ code QR ở cấp hệ thống

### 9.1. QR dùng thư viện/plugin nào?

QR không dùng plugin NetBeans và cũng không gọi API ngoài. QR dùng thư viện Java:

```text
ZXing Core
```

File jar nằm tại:

```text
lib/zxing-core-3.5.3.jar
```

Trong jar này có các class được dùng:

```text
com.google.zxing.qrcode.QRCodeWriter
com.google.zxing.common.BitMatrix
com.google.zxing.BarcodeFormat
com.google.zxing.EncodeHintType
```

Project khai báo jar ở:

```text
nbproject/project.properties
```

Dòng quan trọng:

```text
file.reference.zxing-core-3.5.3.jar=lib/zxing-core-3.5.3.jar
```

Jar được đưa vào classpath:

```text
javac.classpath=... ${file.reference.zxing-core-3.5.3.jar}
```

Khi build WAR, NetBeans copy jar vào `WEB-INF/lib` theo khai báo trong:

```text
nbproject/project.xml
```

### 9.2. Backend import ZXing ở đâu?

File:

```text
src/java/servlet/LiteApiServlet.java
```

Các import:

```java
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
```

Nếu NetBeans báo đỏ các dòng này, nguyên nhân thường là thiếu `lib/zxing-core-3.5.3.jar` hoặc classpath chưa nhận jar.

### 9.3. Mã QR của bàn nằm ở đâu trong database?

Bảng:

```text
Tables
```

Cột:

```text
code VARCHAR(40)
```

Mỗi bàn có một code riêng, ví dụ:

```text
TB-A1B2C3D4
```

Code được sinh trong `LiteService.uniqueTableCode()`:

```java
String code = "TB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase(Locale.ROOT);
```

Sau đó kiểm tra trong database để tránh trùng:

```sql
SELECT COUNT(*) FROM dbo.Tables WHERE code=?
```

Nếu chưa có code, `ensureTableCodes()` sẽ tự gán code cho bàn.

### 9.4. Admin tải QR từ frontend như thế nào?

File:

```text
web/assets/js/page-admin-tables.js
```

Hàm tạo link order:

```javascript
function orderUrl(table) {
    return `${qrBaseUrl()}/menu.jsp?tableCode=${encodeURIComponent(table.code)}`;
}
```

Hàm tạo link QR:

```javascript
function qrUrl(table, download) {
    return `api/tables/qr?code=${encodeURIComponent(table.code)}&base=${encodeURIComponent(qrBaseUrl())}&size=420${download ? '&download=1' : ''}`;
}
```

Khi admin bấm tải QR, browser gọi:

```text
GET /api/tables/qr?code=TB-...&base=http://...&size=420&download=1
```

### 9.5. API QR đi qua backend như thế nào?

Trong `LiteApiServlet.doGet()` có đoạn đặc biệt:

```java
if ("/tables/qr".equals(path)) {
    writeTableQr(req, resp);
    return;
}
```

Nó được đặt trước `json(resp)` vì QR trả về `image/svg+xml`, không phải JSON.

Hàm xử lý:

```java
private void writeTableQr(HttpServletRequest req, HttpServletResponse resp)
```

Luồng trong hàm:

1. Lấy `code` từ query string.
2. Gọi `service.getTableByCode(code)` để kiểm tra bàn có tồn tại và active không.
3. Lấy `base` từ query string. Nếu không có thì dùng `publicBase(req)`.
4. Ghép link:

```java
String url = base + "/menu.jsp?tableCode=" + URLEncoder.encode(code, StandardCharsets.UTF_8);
```

5. Lấy size, giới hạn từ 180 đến 960.
6. Gọi `qrSvg(url, size)`.
7. Set content type:

```text
image/svg+xml
```

8. Nếu `download=1`, set header tải file.

### 9.6. `qrSvg()` tạo hình QR như thế nào?

Hàm:

```java
private String qrSvg(String text, int size)
```

Bước 1: tạo cấu hình cho QR:

```java
EnumMap<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
hints.put(EncodeHintType.MARGIN, 2);
```

Bước 2: ZXing encode text thành ma trận:

```java
BitMatrix matrix = new QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size, hints);
```

`BitMatrix` có thể hiểu là bảng ô vuông đen/trắng. Ô nào `true` thì là ô đen trong QR.

Bước 3: code tự chuyển từng ô đen thành SVG path:

```java
if (matrix.get(x, y)) {
    sb.append('M').append(x).append(' ').append(y).append("h1v1h-1z");
}
```

Nghĩa là mỗi ô đen được vẽ thành một hình vuông 1x1 trong SVG.

Điểm quan trọng: ZXing chỉ tạo ma trận QR. Phần chuyển sang SVG là code tự viết trong project, không dùng thư viện render ảnh riêng.

### 9.7. Khách quét QR xong frontend xử lý thế nào?

QR mở:

```text
menu.jsp?tableCode=TB-...
```

File xử lý:

```text
web/assets/js/page-menu.js
```

Hàm:

```javascript
applyQrTable()
```

Nếu code hợp lệ:

```javascript
preferredTable = table.name;
qrTableName = table.name;
lockedTable = true;
sessionStorage.setItem('selectedTable', table.name);
sessionStorage.setItem('selectedTableCode', preferredTableCode);
```

Sau đó order gửi lên sẽ dùng:

```javascript
tableName: selectedTable()
```

Tức là đơn được gắn vào đúng bàn.

### 9.8. Debug QR nếu bị lỗi

| Lỗi | Kiểm tra |
| --- | --- |
| NetBeans báo đỏ `QRCodeWriter` | Kiểm tra `lib/zxing-core-3.5.3.jar` và `nbproject/project.properties` |
| API QR trả 404 | Kiểm tra `web.xml` mapping `/api/*` và `LiteApiServlet.doGet()` |
| QR tải được nhưng quét không vào điện thoại | Kiểm tra `base-url` trong `admin-tables.jsp`, không dùng `localhost` khi quét bằng điện thoại |
| Quét QR vào menu nhưng không nhận bàn | Kiểm tra `Tables.code`, `/api/tables/by-code`, `page-menu.js/applyQrTable()` |
| QR cũ không dùng được | Có thể admin đã bấm `regenerate`, code cũ không còn đúng |
| SVG lỗi XML | Kiểm tra `LiteApiServlet.qrSvg()` chỉ có một thuộc tính `xmlns` và response content type là `image/svg+xml` |

### 9.9. Tóm tắt QR bằng một câu để trình bày

QR trong hệ thống là một link có chứa `tableCode`; code này được lưu trong bảng `Tables`, được backend Java sinh thành hình SVG bằng thư viện ZXing, và khi khách quét thì frontend dùng `tableCode` để khóa đúng bàn trước khi gửi đơn.
