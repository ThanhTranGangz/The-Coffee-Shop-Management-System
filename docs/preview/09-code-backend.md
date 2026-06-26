# Giải Thích Code Backend

## 1. Nên đọc backend theo thứ tự nào?

Nếu mở project để giải thích code, nên đọc theo thứ tự này:

```text
web/WEB-INF/web.xml
  -> src/java/context/DBContext.java
  -> src/java/servlet/SecurityFilter.java
  -> src/java/servlet/LiteApiServlet.java
  -> src/java/service/LiteService.java
  -> src/java/utils/JsonUtils.java
```

Lý do: `web.xml` cho biết request `/api/*` đi vào servlet nào. `DBContext` cho biết database kết nối ở đâu. `SecurityFilter` cho biết ai được vào trang/API nào. `LiteApiServlet` là lớp nhận request. `LiteService` là nơi xử lý nghiệp vụ thật. `JsonUtils` giúp parse và trả JSON.

## 2. `web/WEB-INF/web.xml`

File này là cấu hình web app.

Phần quan trọng nhất:

```xml
<servlet>
    <servlet-name>LiteApiServlet</servlet-name>
    <servlet-class>servlet.LiteApiServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>LiteApiServlet</servlet-name>
    <url-pattern>/api/*</url-pattern>
</servlet-mapping>
```

Ý nghĩa:

- Bất kỳ request nào bắt đầu bằng `/api/` sẽ chạy vào `LiteApiServlet`.
- Ví dụ `/api/orders`, `/api/menu`, `/api/tables/map` đều vào cùng một servlet.
- Servlet sẽ đọc phần phía sau `/api` để biết phải xử lý chức năng nào.

File này cũng đặt:

```xml
<request-character-encoding>UTF-8</request-character-encoding>
<response-character-encoding>UTF-8</response-character-encoding>
```

Mục đích là để tiếng Việt không bị lỗi font khi gửi request/response.

Phần JSP:

```xml
<el-ignored>true</el-ignored>
```

Nghĩa là JSP không tự xử lý Expression Language `${...}`. Cái này quan trọng vì frontend JavaScript có template string cũng dùng `${...}`. Nếu JSP hiểu nhầm đó là EL, NetBeans hoặc Tomcat có thể báo lỗi đỏ.

## 3. `DBContext.java`

File:

```text
src/java/context/DBContext.java
```

Đây là lớp chịu trách nhiệm mở kết nối tới SQL Server.

Các thông tin kết nối:

```java
SERVER = "localhost"
PORT = "1433"
DATABASE = "CoffeeShopLite"
USER = "sa"
PASSWORD = "123"
```

Hàm chính:

```java
public Connection getConnection()
```

Luồng chạy:

1. Gọi `ensureDatabase()`.
2. Load SQL Server JDBC driver.
3. Tạo JDBC URL tới database `CoffeeShopLite`.
4. Trả về `Connection`.

`ensureDatabase()` kết nối vào database `master` trước, sau đó chạy:

```sql
IF DB_ID(N'CoffeeShopLite') IS NULL CREATE DATABASE CoffeeShopLite
```

Nói đơn giản: nếu database chưa tồn tại thì app tự tạo database. Sau lần đầu tạo xong, biến `databaseReady` được đặt thành `true` để không tạo lại nhiều lần.

Điểm nên trình bày: app không chỉ kết nối database, mà còn tự đảm bảo database chính tồn tại trước khi chạy.

## 4. `SecurityFilter.java`

File:

```text
src/java/servlet/SecurityFilter.java
```

Filter này chạy trước servlet và trước JSP. Nó giống như cửa bảo vệ của hệ thống.

Annotation:

```java
@WebFilter("/*")
```

Nghĩa là mọi request đều đi qua filter này.

### 4.1. Các nhóm trang

Code chia trang thành nhiều nhóm:

```java
adminPages   = admin-menu.jsp, admin-tables.jsp, system-logs.jsp
baristaPages = staff-orders.jsp
cashierPages = cashier.jsp, counter-order.jsp
runnerPages  = runner.jsp
transferPages = table-transfer.jsp
publicPages  = index.html, staff-login.jsp, dashboard.jsp, menu.jsp, order-status.jsp
```

Ý nghĩa:

- Trang public ai cũng mở được.
- Trang admin cần role `admin`.
- Trang pha chế cần role `barista` hoặc `admin`.
- Trang thu ngân cần role `cashier` hoặc `admin`.
- Trang bồi bàn cần role `runner` hoặc `admin`.
- Trang đổi bàn cho phép admin, cashier, runner.

### 4.2. Luồng xử lý trong `doFilter`

Hàm chính:

```java
public void doFilter(...)
```

Nó làm theo thứ tự:

1. Lấy path hiện tại.
2. Nếu là file trong `/assets/` hoặc trang public thì cho qua.
3. Nếu là API `/api/...` thì kiểm tra API public hoặc API được phép theo role.
4. Nếu là trang JSP nội bộ thì kiểm tra role.
5. Nếu không đủ quyền thì redirect hoặc trả JSON lỗi.

Ví dụ:

- Khách mở `menu.jsp`: cho qua.
- Khách gọi `POST /api/orders`: cho qua vì khách được đặt đơn.
- Khách mở `cashier.jsp`: bị chuyển về `staff-login.jsp`.
- Pha chế gọi `/api/cash/status`: bị chặn vì không phải API của pha chế.
- Admin mở `admin-menu.jsp`: cho qua.

### 4.3. `isPublicApi`

Hàm này định nghĩa API nào không cần đăng nhập.

Các API public gồm:

- Login/logout/session.
- Lấy menu.
- Lấy bàn.
- Lấy bàn theo QR code.
- Lấy QR.
- Khách xem đơn của bàn.
- Khách tạo đơn.

Điểm quan trọng: khách không có tài khoản nhưng vẫn phải đặt được món, nên `POST /api/orders` là public.

### 4.4. `isAllowedApi`

Hàm này kiểm tra API theo role:

- `admin`: được gọi toàn bộ API.
- `barista`: được xem đơn, đổi trạng thái đơn, xem số cốc.
- `cashier`: được xem đơn, thanh toán, đổi bàn, tiền mặt.
- `runner`: được xem đơn, phục vụ, dọn bàn, đổi bàn.

Đây là lớp bảo vệ phía server. Dù frontend có bị sửa bằng DevTools, backend vẫn không cho gọi API sai quyền.

## 5. `LiteApiServlet.java`

File:

```text
src/java/servlet/LiteApiServlet.java
```

Đây là API controller chính. Nó nhận request HTTP rồi gọi sang `LiteService`.

Ở đầu file có:

```java
private final LiteService service = LiteService.getInstance();
```

Nghĩa là servlet dùng một instance chung của service. `LiteService` được viết theo kiểu singleton.

## 6. `doGet` trong `LiteApiServlet`

`doGet` dùng cho các request lấy dữ liệu.

Ví dụ:

```text
GET /api/menu
GET /api/tables
GET /api/orders
GET /api/dashboard
GET /api/logs
```

Code lấy path bằng:

```java
String path = req.getPathInfo() == null ? "/" : req.getPathInfo();
```

Nếu URL là:

```text
/api/orders
```

thì `pathInfo` là:

```text
/orders
```

Sau đó servlet dùng `switch (path)` để chọn nhánh xử lý.

### 6.1. API menu

```java
case "/menu":
    boolean admin = "admin".equals(role(req));
    resp.getWriter().write(JsonUtils.toJson(service.getMenu(admin)));
```

Nếu là admin, service trả cả món active và inactive. Nếu không phải admin, chỉ trả món đang bán.

### 6.2. API bàn

```java
/tables
/tables/all
/tables/map
/tables/by-code
```

- `/tables`: bàn active cho khách order.
- `/tables/all`: tất cả bàn cho admin quản lý.
- `/tables/map`: sơ đồ bàn.
- `/tables/by-code`: tìm bàn từ mã QR.

Với `/tables/map`, nếu role là `runner`, service trả bản đã lọc bớt dữ liệu để bồi bàn không thấy thông tin không cần thiết.

### 6.3. API đơn hàng

```java
/orders
/orders/lookup
/orders/table
```

- `/orders`: nhân viên lấy danh sách đơn theo role.
- `/orders/lookup`: tìm một đơn bằng mã đơn.
- `/orders/table`: khách xem các đơn đang mở của đúng bàn.

`/orders` có logic đặc biệt:

```java
service.getOrders(orderViewRole(req), cashierPaidIds(req, false))
```

`orderViewRole(req)` quyết định lấy đơn theo vai trò nào. Nếu admin gọi `?view=barista`, admin có thể xem màn hình pha chế. Nếu không phải admin, role lấy từ session.

`cashierPaidIds` dùng để giữ danh sách đơn đã thanh toán trong session của thu ngân.

### 6.4. API dashboard, cash, cups, logs

```java
/dashboard
/cash/status
/cups/status
/logs
```

- Dashboard trả doanh thu, top sản phẩm, series biểu đồ.
- Cash status trả tiền mặt hiện có và lịch sử rút tiền.
- Cups status trả số cốc còn lại.
- Logs trả nhật ký hệ thống.

## 7. `doPost` trong `LiteApiServlet`

`doPost` dùng cho các request làm thay đổi dữ liệu.

Đầu tiên servlet đọc body:

```java
Map<String, Object> body = JsonUtils.parseObject(readBody(req));
```

Frontend gửi JSON, backend parse thành `Map`.

### 7.1. Login nhân viên

```java
case "/auth/login":
```

Luồng:

1. Nếu username là `admin` thì từ chối, vì admin phải vào `dashboard.jsp`.
2. Gọi `service.login(username, password)`.
3. Nếu đúng, lưu session:

```java
session.setAttribute("role", user.get("role"));
session.setAttribute("user", user.get("fullName"));
```

4. Nếu là cashier, tạo `paidOrderIds` rỗng để lưu đơn đã thanh toán trong ca hiện tại.
5. Ghi log login.

### 7.2. Mở khóa admin

```java
case "/auth/admin-pin":
```

Nếu PIN là `8888`, session được đặt:

```java
role = admin
user = Quản trị coffeshop
```

Đây là lý do admin không cần trang login riêng.

### 7.3. Tạo đơn

```java
case "/orders":
    service.createOrder(body)
```

API này được dùng bởi cả khách QR và thu ngân gọi món tại quầy. Dữ liệu gửi lên gồm bàn, ghi chú và danh sách món.

### 7.4. Chuyển trạng thái đơn

```java
case "/orders/status":
```

Luồng:

1. Đọc `id` đơn và `status` mới.
2. Lấy đơn hiện tại bằng `service.getOrderById`.
3. Gọi `canSetStatus(...)` để kiểm tra chuyển trạng thái có hợp lệ không.
4. Nếu hợp lệ, gọi `service.updateOrderStatus(...)`.
5. Nếu thu ngân chuyển sang `Paid`, ghi id đơn vào session `paidOrderIds`.
6. Nếu bồi bàn gọi API, dữ liệu trả về được lọc bớt bằng `sanitizeRunnerOrder`.

Điểm quan trọng: trạng thái không chỉ được kiểm tra ở frontend. Backend cũng kiểm tra lại nên không thể chuyển sai luồng bằng cách gọi API thủ công.

### 7.5. Menu, bàn, tiền mặt, cốc, đổi bàn

Các case còn lại gọi sang service tương ứng:

```text
/menu              lưu món
/menu/delete       ẩn món
/tables            lưu bàn
/tables/delete     xóa bàn
/cash/count        thu ngân chốt tiền mặt
/cash/withdraw     admin rút tiền
/cups/update       admin sửa số cốc
/tables/regenerate đổi QR code
/tables/clear      bồi bàn dọn bàn
/tables/transfer   đổi bàn
```

## 8. `canSetStatus`

Hàm này là lõi kiểm soát workflow đơn hàng.

Các bước hợp lệ:

```java
Pending -> Preparing       barista
Preparing -> Ready         barista
Ready -> Served            runner
Served -> Paid             cashier
```

Admin cũng được phép thực hiện các bước này khi kiểm tra hệ thống.

Không có dòng nào cho phép:

```text
Paid -> Served
Ready -> Pending
Pending -> Ready
Served -> Cleared
```

Riêng `Paid -> Cleared` không đi qua `/orders/status`, mà đi qua `/tables/clear` để gắn với hành động dọn bàn.

## 9. `writeTableQr`

Hàm này xử lý:

```text
GET /api/tables/qr
```

Luồng:

1. Lấy `code` từ query string.
2. Tìm bàn bằng `service.getTableByCode(code)`.
3. Tạo link menu:

```text
base + "/menu.jsp?tableCode=" + code
```

4. Gọi `qrSvg(url, size)`.
5. Trả về SVG.

Nếu có `download=1`, response thêm header để browser tải file SVG xuống.

## 10. `LiteService.java`

File:

```text
src/java/service/LiteService.java
```

Đây là file quan trọng nhất. Nó chứa gần như toàn bộ nghiệp vụ: tạo database schema, seed dữ liệu, CRUD menu, CRUD bàn, tạo đơn, chuyển trạng thái, tính doanh thu, tiền mặt, log.

## 11. Singleton trong `LiteService`

Đầu file:

```java
private static final LiteService INSTANCE = new LiteService();
public static LiteService getInstance() { return INSTANCE; }
```

Ý nghĩa: toàn bộ servlet dùng chung một service. Khi service được tạo, constructor gọi `init()`.

## 12. `init()` và `seed()`

`init()` làm hai việc:

1. Tạo bảng nếu chưa có.
2. Gọi `seed(con)` để thêm dữ liệu demo.

Các bảng được tạo:

```text
Users, Tables, MenuItems, MenuItemSizes, Orders, OrderItems,
CashEvents, StoreState, SystemLogs
```

`seed()` thêm:

- User admin, barista, cashier, runner.
- Bàn chuẩn 2 tầng, mỗi tầng 6 bàn.
- Code QR cho bàn.
- Menu mẫu.
- Lịch sử bán hàng 1 năm để dashboard có dữ liệu.
- Một vài đơn đang mở để demo.
- State `cupsAvailable`.

Điểm cần hiểu: app có khả năng tự dựng dữ liệu demo khi chạy lần đầu, nên không cần nhập tay từ đầu.

## 13. Nhóm hàm menu

Các hàm chính:

```java
getMenu(includeInactive)
saveMenuItem(data)
deleteMenuItem(id)
getMenuItem(id)
validateMenuItem(...)
normalizeSizeRows(...)
```

`getMenu(false)` dùng cho khách và nhân viên, chỉ lấy món active.

`getMenu(true)` dùng cho admin, lấy cả món ẩn để admin có thể sửa.

`saveMenuItem` làm theo logic:

1. Đọc dữ liệu từ `Map`.
2. Chuẩn hóa category.
3. Đọc giá, ảnh, active, size.
4. Validate dữ liệu.
5. Nếu id > 0 thì update.
6. Nếu id = 0 thì insert.
7. Lưu lại size.
8. Trả món vừa lưu.

`normalizeSizeRows` đảm bảo:

- Nếu có size thì luôn có size `S`.
- Size `S` luôn chênh `0`.
- Tên size không quá dài.
- Tiền chênh hợp lệ.
- Không quá 8 size.

## 14. Nhóm hàm bàn và QR

Các hàm chính:

```java
getTables()
getAllTables()
getTableMap()
getRunnerTableMap()
getTableByCode(code)
saveTable(data)
regenerateTableCode(id)
deleteTable(id)
```

`getTableMap()` dùng `OUTER APPLY` để lấy đơn đang mở mới nhất của từng bàn. Sau đó gắn thêm field:

```java
busy = table.get("orderId") != null
```

Tức là nếu bàn có đơn chưa kết thúc thì bàn được coi là đang bận.

`getRunnerTableMap()` lấy sơ đồ bàn nhưng lọc bớt dữ liệu cho bồi bàn.

`saveTable()` kiểm tra:

- Tên bàn hợp lệ.
- Tầng hợp lệ.
- Số bàn hợp lệ.
- Không trùng vị trí tầng/số bàn.

`deleteTable()` không cho xóa nếu bàn đang có đơn:

```text
Pending, Preparing, Ready, Served, Paid
```

## 15. Nhóm hàm order

Các hàm chính:

```java
createOrder(data)
getOrders(role, cashierSessionPaidIds)
getOrderByNumber(orderNumber)
getOrderById(id)
getOrderItems(orderId)
updateOrderStatus(id, status, actorRole, actorName)
```

### 15.1. `createOrder`

Luồng:

1. Đọc `tableName`, `customerPhone`, `note`, `items`.
2. Nếu không có item thì báo lỗi.
3. Mở transaction bằng `con.setAutoCommit(false)`.
4. Insert vào `Orders` trước, total tạm thời là 0.
5. Lặp từng item:
   - Lấy menu bằng `getMenuItem`.
   - Chuẩn hóa size.
   - Tính giá theo size.
   - Insert vào `OrderItems`.
6. Tính tổng tiền.
7. Set `orderNumber = 1000 + orderId`.
8. Update lại `Orders`.
9. Ghi log `ORDER_CREATE`.
10. Commit.

Vì dùng transaction, nếu đang tạo đơn mà lỗi ở giữa, database sẽ không bị lưu nửa vời.

### 15.2. `getOrders`

Hàm này lọc đơn theo role:

```text
barista -> Pending, Preparing, Ready
cashier -> Served + các đơn Paid trong session hiện tại
runner  -> Ready, Paid
admin   -> không lọc hoặc xem theo view
```

Nếu role là `runner`, hàm gọi `sanitizeRunnerOrders` để xóa giá tiền và thông tin không cần thiết.

### 15.3. `updateOrderStatus`

Hàm này cập nhật trạng thái đơn.

Nó dùng:

```sql
WITH (UPDLOCK, ROWLOCK)
```

khi đọc đơn. Ý nghĩa đơn giản: khóa dòng đơn đang xử lý để tránh hai thiết bị cùng lúc chuyển trạng thái gây lỗi.

Nếu chuyển:

```text
Preparing -> Ready
```

thì hàm tính số cốc cần trừ bằng `cupCountForOrder`. Nếu không đủ cốc, hàm báo lỗi và không cập nhật trạng thái.

Sau khi update trạng thái, hàm ghi log `ORDER_STATUS`.

## 16. Tính số cốc trong `cupCountForOrder`

Hàm này join `OrderItems` với `MenuItems`:

```sql
SELECT oi.quantity, mi.category
FROM OrderItems oi
JOIN MenuItems mi ON mi.id = oi.menuItemId
WHERE oi.orderId = ?
```

Nếu category là đồ uống, cộng `quantity` vào số cốc. Nếu là bánh, không cộng.

Ví dụ:

```text
Latte x2 + Croissant x1
```

Số cốc cần trừ là `2`.

## 17. Nhóm hàm đổi bàn và dọn bàn

### `transferTable`

Hàm này đổi bàn bằng cách cập nhật `tableName` của các đơn đang mở.

Nó kiểm tra:

- Bàn mới khác bàn cũ.
- Bàn tồn tại.
- Bàn không bị ẩn.
- Bàn cũ có đơn.
- Bàn mới đang trống.

Sau đó update:

```sql
UPDATE Orders
SET tableName = bàn mới
WHERE tableName = bàn cũ
AND status IN ('Pending','Preparing','Ready','Served')
```

### `clearServedTable`

Hàm này xử lý bước cuối:

```text
Paid -> Cleared
```

Nó tìm đơn `Paid` mới nhất của bàn, update sang `Cleared`, ghi log và trả về trạng thái bàn đã sẵn sàng.

## 18. Nhóm hàm tiền mặt

Các hàm:

```java
getCashStatus(role)
recordCashierCount(countedCash, actorName)
withdrawCash(amount, actorName)
acknowledgeCashierWithdrawals()
```

`recordCashierCount` dùng khi thu ngân logout và nhập tiền mặt hiện tại.

`withdrawCash` dùng khi admin rút tiền. Sự kiện được ghi vào `CashEvents`, đồng thời ghi log vào `SystemLogs`.

`acknowledgeCashierWithdrawals` đánh dấu thông báo rút tiền là đã được thu ngân xem.

## 19. Nhóm hàm dashboard

Hàm chính:

```java
getDashboard(start, end)
```

Nó gom nhiều dữ liệu:

- Số đơn theo trạng thái.
- Doanh thu tổng.
- Doanh thu hôm nay/tháng/năm.
- Sản phẩm bán chạy.
- Series doanh thu theo ngày/tuần/tháng/năm/tất cả/custom.
- Chi tiết theo khoảng đang chọn.

Các hàm phụ:

```java
revenueByHour
revenueByDay
revenueByMonth
topProductsBetween
rangeDetailBetween
```

Dashboard chỉ tính doanh thu từ đơn:

```text
Paid, Cleared
```

Vì đây là các đơn đã thanh toán hoặc đã hoàn tất.

## 20. `JsonUtils.java`

File:

```text
src/java/utils/JsonUtils.java
```

Project không dùng thư viện JSON lớn như Gson/Jackson. Thay vào đó có class nhỏ để:

- Convert Java `Map`, `List`, `String`, `Number`, `Boolean` thành JSON.
- Parse JSON body từ frontend thành `Map<String, Object>`.

`toJson(obj)` dùng khi servlet trả response.

`parseObject(json)` dùng khi servlet nhận POST body.

Điểm cần nói rõ: đây là parser đơn giản, đủ cho dữ liệu demo của project. Nếu làm production thật, nên dùng thư viện JSON chuẩn.

## 21. Thư viện backend nằm ở đâu và được nạp thế nào?

Project không dùng Maven. Thư viện được đặt thủ công trong:

```text
lib/
```

Danh sách chính:

| File jar | Công dụng | Code sử dụng |
| --- | --- | --- |
| `sqljdbc42.jar` | Driver JDBC để kết nối Microsoft SQL Server | `DBContext.java` |
| `zxing-core-3.5.3.jar` | Sinh QR code | `LiteApiServlet.java` |
| `jakarta.servlet.jsp.jstl-2.0.0.jar` | Hỗ trợ JSTL/JSP nếu cần | Build web app |
| `jakarta.servlet.jsp.jstl-api-2.0.0.jar` | API JSTL | Build web app |
| `jaxb-api-2.1.jar` | Thư viện tương thích JAXB | Build classpath |

NetBeans đọc thư viện từ:

```text
nbproject/project.properties
```

Các dòng quan trọng:

```text
file.reference.sqljdbc42.jar=lib/sqljdbc42.jar
file.reference.zxing-core-3.5.3.jar=lib/zxing-core-3.5.3.jar
javac.classpath=...
```

Khi đóng gói WAR, các jar được copy vào:

```text
build/web/WEB-INF/lib
dist/The-Coffee-Shop-Management-System-main.war/WEB-INF/lib
```

Cấu hình copy nằm trong:

```text
nbproject/project.xml
```

Nếu chuyển project sang máy khác mà NetBeans báo đỏ import `com.google.zxing...` hoặc `com.microsoft.sqlserver...`, nguyên nhân thường là thư mục `lib` thiếu jar hoặc `project.properties` không trỏ đúng jar.

## 22. QR code nhìn từ backend

Chức năng QR là ví dụ rõ nhất về cách backend dùng thư viện ngoài.

Các điểm cần nhớ:

```text
Thư viện: lib/zxing-core-3.5.3.jar
Import: LiteApiServlet.java
Endpoint: GET /api/tables/qr
Hàm xử lý: writeTableQr()
Hàm render: qrSvg()
Database: Tables.code
Frontend gọi: page-admin-tables.js/qrUrl()
```

`QRCodeWriter` không tự trả file ảnh PNG/JPG. Nó trả `BitMatrix`. Code trong `qrSvg()` tự duyệt từng ô của `BitMatrix` để dựng SVG. Vì vậy nếu cần đổi màu QR, nền QR hoặc kích thước SVG thì sửa trong `qrSvg()`, không sửa trong database.

## 23. SQL Server nhìn từ backend

Kết nối SQL Server không nằm trong từng DAO mà tập trung ở:

```text
DBContext.java
```

`LiteService` mỗi lần cần dữ liệu sẽ gọi:

```java
try (Connection con = db.getConnection()) { ... }
```

Điểm quan trọng:

- `try-with-resources` tự đóng connection.
- Các thao tác nhiều bước dùng transaction bằng `con.setAutoCommit(false)`.
- Các thao tác dễ tranh chấp dùng `WITH (UPDLOCK, ROWLOCK)`.

Ví dụ:

- Chuyển trạng thái đơn khóa dòng `Orders`.
- Đổi bàn khóa dòng `Tables`.
- Trừ cốc khóa dòng `StoreState`.

Nếu không khóa, hai thiết bị có thể cùng bấm một đơn/bàn làm dữ liệu bị lệch.
