# Vấn đáp phần WAITER (runner): Query Database & Validate

Chỉ tập trung vào luồng bồi bàn. Mọi trích dẫn đều từ code thật, có số dòng để mở ra đối chiếu.

## Bản đồ: waiter chạm vào những gì

Whitelist riêng cho waiter có đúng **7 endpoint** (`SecurityFilter.java:98`):

| Endpoint | Service gọi xuống | Khi nào chạy |
|---|---|---|
| `GET /orders` (view=runner) | `getOrders("runner")` | **Tự động mỗi 5 giây** |
| `GET /tables/map` | `getRunnerTableMap()` | **Tự động mỗi 5 giây** |
| `POST /orders/status` | `updateOrderStatus()` | Nhấn giữ card 0.5s để phục vụ |
| `POST /tables/clear` | `clearServedTable()` | Nhấn giữ card để dọn bàn |
| `POST /tables/transfer` | `transferTable()` | Trang đổi bàn |
| `GET /orders/invoice` | `getOrderInvoice()` | Bấm in hóa đơn |
| `POST /orders/invoice/printed` | `markInvoicePrinted()` | Sau khi in xong |

⚠️ **Cẩn thận nếu bị hỏi vặn "vậy waiter tạo đơn được không?"** — đừng nói "chỉ 7 endpoint" rồi dừng. `doFilter` cho qua nếu `isPublicApi(...) || isAllowedApi(...)`, mà `isPublicApi()` (`SecurityFilter.java:78`) mở thêm cho **mọi** caller, kể cả waiter: 4 endpoint `/api/auth/*`, 6 endpoint GET công khai (`/api/menu`, `/api/tables`, `/api/tables/by-code`, `/api/tables/qr`, `/api/orders/lookup`, `/api/orders/table`), và **`POST /api/orders`** — tức là waiter **tạo đơn được**.

**Câu trả lời đủ:** "Whitelist riêng cho runner có 7 endpoint. Ngoài ra runner còn dùng chung các endpoint công khai trong `isPublicApi()`, gồm cả `POST /api/orders` nên waiter vẫn gọi món hộ khách được."

**Câu mở đầu nên nói:** "Phần waiter đặc biệt ở chỗ nó **polling mỗi 5 giây** (`page-runner.js:25`), nên mọi vấn đề hiệu năng về query đều bị nhân lên. Còn về validate thì waiter là role bị giới hạn chặt nhất — chỉ được chuyển đúng một bước trạng thái."

---

# PHẦN A — QUERY

## A1. "Waiter lấy dữ liệu như thế nào?"

Mỗi 5 giây, `loadWork()` gọi song song 2 API (`page-runner.js:29`):

```js
const [orderRes, tableRes] = await Promise.all([
    api('/orders?view=runner'),
    api('/tables/map')
]);
```

**Query 1** — `getOrders("runner")`, `LiteService.java:1446`:

```java
String sql = "SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt, invoicePrinted FROM dbo.Orders ";
...
} else if ("runner".equals(role)) {
    sql += "WHERE status IN ('Ready','Served','Paid') ";
}
sql += "ORDER BY id DESC";
```

Waiter chỉ thấy 3 trạng thái: `Ready` (cần bưng ra), `Served` (để in lại hóa đơn), `Paid` (bàn cần dọn).

**Query 2** — `getRunnerTableMap()` gọi `getTableMap()`, `LiteService.java:987`:

```sql
SELECT t.id, t.name, t.code, t.active, t.floorNo, t.tableNo,
       activeOrder.id orderId, activeOrder.orderNumber, activeOrder.status
FROM dbo.Tables t
OUTER APPLY (SELECT TOP 1 id, orderNumber, status FROM dbo.Orders
             WHERE tableName = t.name AND status IN ('Pending','Preparing','Ready','Served','Paid')
             ORDER BY id DESC) activeOrder
WHERE t.active = 1
ORDER BY ISNULL(t.floorNo, 1), ISNULL(t.tableNo, 999), t.name
```

**Đây là query nên khoe.** Giải thích: `OUTER APPLY` cho phép truy vấn con tham chiếu `t.name` của hàng ngoài rồi lấy `TOP 1` mới nhất. `LEFT JOIN` thường **không** làm được kiểu "lấy 1 dòng mới nhất cho mỗi bàn" gọn như vậy — sẽ phải dùng subquery lồng hoặc window function. `ISNULL` trong `ORDER BY` để bàn chưa gán tầng không trôi lên đầu.

## A2. ⚠️⚠️ "Mỗi lần waiter poll thì chạy bao nhiêu query?" — N+1

**Đây là điểm yếu lớn nhất của phần waiter. Phải chuẩn bị kỹ.**

`getOrders()` sau khi lấy danh sách đơn thì lặp để lấy món, `LiteService.java:1460`:

```java
List<Map<String, Object>> list = rows(rs);
for (Map<String, Object> order : list) {
    order.put("items", getOrderItems(readInt(order.get("id"), 0)));   // ← query trong vòng lặp
}
```

Và `getOrderItems()` (`LiteService.java:2159`) **mở connection mới mỗi lần**:

```java
private List<Map<String, Object>> getOrderItems(int orderId) throws Exception {
    try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
            "SELECT id, menuItemId, itemName, itemSize, quantity, price, ISNULL(preparedQty,0) preparedQty "
          + "FROM dbo.OrderItems WHERE orderId=? ORDER BY id")) {
```

**Con số để nói với thầy cô:** quán có 15 đơn đang ở `Ready`/`Served`/`Paid` thì một lần poll của waiter = **1 + 15 = 16 query và 16 connection**. Cộng thêm `/tables/map` là 17. Poll 5 giây/lần = **204 query mỗi phút cho một máy waiter**. Hai waiter cùng ca là hơn 400.

**Cách sửa — lấy hết item trong một query rồi group ngoài Java:**

```java
private Map<Integer, List<Map<String, Object>>> getOrderItemsBatch(Connection con, List<Integer> orderIds) throws Exception {
    Map<Integer, List<Map<String, Object>>> grouped = new LinkedHashMap<>();
    if (orderIds == null || orderIds.isEmpty()) return grouped;
    String sql = "SELECT orderId, id, menuItemId, itemName, itemSize, quantity, price, "
               + "ISNULL(preparedQty,0) preparedQty FROM dbo.OrderItems "
               + "WHERE orderId IN (" + placeholders(orderIds.size()) + ") ORDER BY orderId, id";
    try (PreparedStatement ps = con.prepareStatement(sql)) {
        for (int i = 0; i < orderIds.size(); i++) ps.setInt(i + 1, orderIds.get(i));
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> item = row(rs);
                int oid = readInt(item.remove("orderId"), 0);
                grouped.computeIfAbsent(oid, k -> new ArrayList<>()).add(item);
            }
        }
    }
    return grouped;
}
```

**Nói kèm 2 ý ăn điểm:**

1. Hàm `placeholders(int)` **project đã có sẵn** (`LiteService.java:2633`) và sinh ra `?,?,?` — nên vẫn là PreparedStatement, không nối giá trị vào SQL.
2. Kỹ thuật này project **đã dùng đúng ở chỗ khác**: trong `createOrder`, em nạp sẵn `getIngredientStockMap(con)` và `getReservedMenuQuantityMap(con)` thành `Map` **trước** vòng lặp thay vì query từng món. "Cùng một bài học nhưng em áp dụng chưa đồng đều."

Kết quả: **16 query → 2 query, 16 connection → 1 connection**.

## A3. ⚠️ "Query của phần waiter có bug nào không?" — bug `floorNo`

**Bug thật, đã sửa. Nếu tự nêu ra sẽ rất được đánh giá cao.**

`getRunnerTableMap()` (`LiteService.java:1001`) lấy đủ dữ liệu từ `getTableMap()` rồi **lọc bớt field** trước khi trả cho waiter:

```java
public List<Map<String, Object>> getRunnerTableMap() throws Exception {
    List<Map<String, Object>> full = getTableMap();     // bản này CÓ floorNo
    List<Map<String, Object>> sanitized = new java.util.ArrayList<>();
    for (Map<String, Object> table : full) {
        Map<String, Object> row = new java.util.LinkedHashMap<>();
        row.put("id",     table.get("id"));
        row.put("name",   table.get("name"));
        row.put("status", table.get("status"));
        row.put("busy",   table.get("busy"));
        // floorNo và tableNo bị bỏ quên
        sanitized.add(row);
    }
```

Hậu quả bên client (`page-runner.js`):

```js
const floor = table.floorNo || 1;   // undefined || 1  →  1 cho MỌI bàn
```

→ toàn bộ 12 bàn của 2 tầng dồn hết vào nhóm "Tầng 1", hiển thị B1–B6 lặp lại hai lần. Trang cashier/admin không bị vì chúng gọi thẳng `getTableMap()`.

**Bài học nên nói:** "Đây là cái giá của việc sanitize bằng cách **liệt kê field muốn giữ** (whitelist). Ưu điểm là an toàn — thêm cột nhạy cảm vào DB thì nó không tự lọt ra ngoài. Nhược điểm là thêm cột hợp lệ thì phải nhớ khai báo, quên là mất dữ liệu âm thầm. So sánh với `sanitizeRunnerOrder` ở servlet dùng cách ngược lại — **xoá field không muốn** (blacklist) — thì không bị lỗi này, nhưng lại rủi ro hơn về bảo mật."

**Sửa:** thêm 2 dòng `row.put("floorNo", ...)` và `row.put("tableNo", ...)`.

## A4. "Waiter đổi trạng thái đơn — query chạy thế nào?"

`updateOrderStatus()` (`LiteService.java:1505`) — transaction có lock:

```java
con.setAutoCommit(false);
// đọc trạng thái hiện tại, giữ lock
"SELECT status,total,orderNumber,tableName FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=?"
// (nhánh trừ kho + trừ cốc chỉ chạy khi Preparing→Ready, tức là của barista)
"UPDATE dbo.Orders SET status=? WHERE id=?"
insertSystemLog(con, actorRole, actorName, "ORDER_STATUS", ...);
con.commit();
```

**Giải thích lock hint:** `UPDLOCK` giữ update-lock ngay từ lúc đọc, `ROWLOCK` giới hạn ở mức dòng để không khoá cả bảng. Không có nó thì hai người đọc cùng giá trị rồi cùng ghi đè — gọi là **lost update**.

**Nhấn thêm:** việc đổi trạng thái và ghi log nằm trong **cùng** transaction, nên không thể có chuyện đổi được trạng thái mà mất log, hoặc ngược lại.

## A5. ⭐ "Chỗ nào em xử lý đồng thời tốt nhất?" — `clearServedTable`

**Đây là câu để ghi điểm. `clearServedTable()` (`LiteService.java:1131`) là hàm chỉ runner và admin gọi được, và làm rất bài bản:**

```java
con.setAutoCommit(false);

// 1. Đọc bàn CÓ LOCK
Map<String, Object> table = tableRowForUpdate(con, tableId);
//    → "SELECT id, name, active FROM dbo.Tables WITH (UPDLOCK, ROWLOCK) WHERE id=?"
if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");

// 2. Chặn dọn nhầm bàn còn khách
int notClearedYet = countOpenOrders(con, tableName, "('Pending','Preparing','Ready','Served')");
if (notClearedYet > 0) throw new IllegalArgumentException("Bàn vẫn còn đơn đang phục vụ, chưa thể dọn.");

// 3. Lấy danh sách đơn đã thanh toán, CÓ LOCK
"SELECT id, orderNumber FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE tableName=? AND status='Paid' ORDER BY id"
if (orderIds.isEmpty()) throw new IllegalArgumentException("Bàn này không có đơn chờ dọn.");

// 4. UPDATE CÓ ĐIỀU KIỆN + kiểm tra số dòng bị ảnh hưởng  ← điểm quan trọng nhất
try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status='Cleared' WHERE tableName=? AND status='Paid'")) {
    clearedCount = ps.executeUpdate();
    if (clearedCount == 0) {
        throw new IllegalArgumentException("Bàn này vừa được cập nhật bởi thiết bị khác.");
    }
}
con.commit();
```

**Thuật ngữ phải gọi đúng tên: bước 4 là _optimistic locking_.** Điều kiện `AND status='Paid'` nằm ngay trong câu `UPDATE`, nên nếu người khác đã dọn bàn đó trong tích tắc vừa rồi thì `executeUpdate()` trả về `0` và mình báo lỗi thay vì ghi đè mù quáng. Đây là cách chống race condition mà **không** cần khoá lâu.

**Nếu thầy cô hỏi "khác gì pessimistic locking?":** pessimistic (`UPDLOCK`) là khoá trước rồi mới làm — an toàn nhưng giữ khoá lâu, giảm thông lượng. Optimistic là cứ làm, đến lúc ghi mới kiểm tra xem dữ liệu có bị đổi không — nhanh hơn, hợp với trường hợp ít khi đụng độ. Hàm này dùng **cả hai**, mỗi cái đúng chỗ.

## A6. ⚠️ "Chỗ này em kiểm tra rồi mới update — chắc chưa?" — TOCTOU ở `/orders/status`

**Trớ trêu là `clearServedTable` làm đúng, nhưng `/orders/status` — đường mà waiter dùng để phục vụ món — lại có lỗi này.**

`LiteApiServlet.java:294`:

```java
Map<String, Object> order = service.getOrderById(orderId);          // đọc status — NGOÀI transaction
if (!canSetStatus(currentRole, str(order.get("status")), status)) { ... }
Map<String, Object> updatedOrder = service.updateOrderStatus(...);  // transaction mở Ở ĐÂY, muộn hơn
```

Kiểm tra điều kiện xảy ra **ngoài** transaction, việc ghi xảy ra trong **một transaction khác** mở sau đó. Khoảng giữa hai lời gọi là kẽ hở — gọi là **TOCTOU** (Time Of Check To Time Of Use).

**Kịch bản cụ thể:** hai waiter cùng nhấn giữ một card. Cả hai đọc `Ready`, cả hai qua `canSetStatus`, cả hai `UPDATE status='Served'`. `UPDLOCK` chỉ tuần tự hoá hai câu UPDATE chứ **không kiểm tra lại điều kiện** → sinh 2 dòng log `ORDER_STATUS` cho một lần chuyển.

**Cách sửa — áp dụng đúng kỹ thuật mà `clearServedTable` đã dùng:**

```java
try (PreparedStatement ps = con.prepareStatement(
        "UPDATE dbo.Orders SET status=? WHERE id=? AND status=?")) {
    ps.setString(1, status);
    ps.setInt(2, id);
    ps.setString(3, expectedCurrentStatus);   // truyền từ servlet xuống
    if (ps.executeUpdate() == 0) {
        throw new IllegalArgumentException("Đơn vừa được cập nhật bởi người khác, vui lòng tải lại.");
    }
}
```

**Câu nói mạnh nhất:** "Em đã dùng đúng pattern này ở `clearServedTable`, chỉ là chưa áp dụng đồng đều cho `updateOrderStatus`."

## A7. ⚠️ "Có chỗ nào nối chuỗi vào SQL trong phần waiter không?"

**Có — `countOpenOrders()` (`LiteService.java:1117`), và nó nằm ngay trong cả `clearServedTable` lẫn `transferTable`:**

```java
private int countOpenOrders(Connection con, String tableName, String statuses) throws Exception {
    try (PreparedStatement ps = con.prepareStatement(
            "SELECT COUNT(*) FROM dbo.Orders WHERE tableName=? AND status IN " + statuses)) {
```

`tableName` được tham số hoá đúng bằng `?`, nhưng `statuses` **nối thẳng vào chuỗi SQL**.

**Cách trả lời cân bằng:** "Hiện không exploit được, vì `statuses` chỉ được gọi với 2 chuỗi hằng viết cứng trong code — `\"('Pending','Preparing','Ready','Served')\"` và bản có thêm `'Paid'`. Không có đường nào để input người dùng chạm tới tham số đó. Nhưng đây là mã dễ hỏng: chỉ cần sau này ai đó cho phép truyền trạng thái từ ngoài vào là thành lỗ hổng ngay."

**Sửa cho sạch:**

```java
private int countOpenOrders(Connection con, String tableName, List<String> statuses) throws Exception {
    String sql = "SELECT COUNT(*) FROM dbo.Orders WHERE tableName=? AND status IN ("
               + placeholders(statuses.size()) + ")";
    try (PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setString(1, tableName);
        for (int i = 0; i < statuses.size(); i++) ps.setString(i + 2, statuses.get(i));
        ...
    }
}
```

## A8. ⚠️ "Transaction của waiter có rollback không?"

**Trả lời thật:** `clearServedTable`, `transferTable` và `updateOrderStatus` — cả ba nghiệp vụ chính của waiter — đều **không** có `catch { rollback(); }`. Riêng `LiteService` có 10 transaction nhưng chỉ 4 chỗ rollback tường minh (689, 1431, 1593, 2260) — không chỗ nào thuộc ba hàm trên. Các DAO thì làm đúng: `RecipeDAO` và `InventoryDAO` đều có rollback.

**Cách nói:** "Về mặt kỹ thuật thì `try (Connection con = ...)` sẽ `close()`, mà đóng một connection đang `autoCommit=false` chưa commit thì JDBC rollback — nên dữ liệu không sai. Nhưng em đang dựa vào hành vi ngầm của driver thay vì viết rõ ràng, đọc code không thấy được ý định."

**Sửa:**

```java
try (Connection con = db.getConnection()) {
    con.setAutoCommit(false);
    try {
        // ... công việc ...
        con.commit();
        return result;
    } catch (Exception e) {
        con.rollback();      // ← thêm
        throw e;
    }
}
```

## A9. ⚠️ "Bảng của em có index không?"

**0 `CREATE INDEX` trong `database_lite.sql`.** Chỉ có index ngầm từ `PRIMARY KEY` và `UNIQUE`.

**Nói cho sát phần waiter — 3 query waiter chạy nhiều nhất đều filter trên cột không index:**

```sql
WHERE status IN ('Ready','Served','Paid')     -- getOrders, mỗi 5 giây
WHERE tableName = t.name AND status IN (...)  -- getTableMap OUTER APPLY, mỗi 5 giây
WHERE orderId = ?                             -- getOrderItems, N lần mỗi vòng poll
```

**Index nên thêm:**

```sql
CREATE NONCLUSTERED INDEX IX_OrderItems_Order ON dbo.OrderItems(orderId);
CREATE NONCLUSTERED INDEX IX_Orders_Status    ON dbo.Orders(status);
CREATE NONCLUSTERED INDEX IX_Orders_Table     ON dbo.Orders(tableName, status);
```

**Câu ăn điểm:** "`IX_OrderItems_Order` quan trọng nhất vì `orderId` là khoá ngoại, mà SQL Server **không** tự tạo index cho khoá ngoại — chỉ tự tạo cho `PRIMARY KEY` và `UNIQUE`. Nhiều người tưởng có FK là có index."

**Cách demo:** trong SSMS bật `SET STATISTICS IO ON`, chạy `SELECT * FROM dbo.OrderItems WHERE orderId = 5` trước và sau khi tạo index, so `logical reads` — trước là table scan, sau là index seek.

## A10. "Nếu 5 waiter mở cùng lúc thì sao?"

Trả lời có số, theo thứ tự nút cổ chai:

1. **Connection** — `DBContext.getConnection()` gọi `DriverManager.getConnection()` mới mỗi lần, không có pool. Mà `encrypt=true` nên mỗi lần còn tốn thêm bắt tay TLS.
2. **N+1** ở `getOrders` nhân với số máy.
3. **Polling** — 5 waiter × 12 request/phút × 16 query = gần 1000 query/phút, phần lớn trả về **dữ liệu không đổi**.

**Hướng cải thiện nên nêu:** "Đúng ra nên chuyển từ polling sang WebSocket hoặc Server-Sent Events, để server chỉ đẩy khi có thay đổi thật. Hiện tại client hỏi liên tục dù không có gì mới."

---

# PHẦN B — VALIDATE

## B1. "Waiter bị chặn ở những tầng nào?"

**Trả lời theo 4 tầng — đây là câu trả lời có cấu trúc, dễ ghi điểm:**

| Tầng | Chặn gì | Ở đâu |
|---|---|---|
| Client (JS) | Chống bấm trùng, hỏi xác nhận khi chưa in hóa đơn | `page-runner.js` |
| Filter | Whitelist 7 endpoint riêng cho waiter (+ các endpoint công khai) | `SecurityFilter.java:78, 98` |
| Servlet | Kiểm role + kiểm thứ tự trạng thái | `LiteApiServlet.java:915` |
| Service | Validate nghiệp vụ + transaction + lock | `LiteService.java` |

**Câu chốt:** "Ba tầng sau là bảo mật thật. Tầng client chỉ để trải nghiệm — vì người dùng có thể gọi API bằng Postman hoặc sửa JS trong DevTools."

## B2. ⭐ "Sao waiter không tự thanh toán đơn được?" — `canSetStatus`

**Câu này gần như chắc chắn bị hỏi. `LiteApiServlet.java:915`:**

```java
private boolean canSetStatus(String role, String currentStatus, String nextStatus) {
    boolean baristaStep = ("Pending".equals(currentStatus)   && "Preparing".equals(nextStatus))
                       || ("Preparing".equals(currentStatus) && "Ready".equals(nextStatus));
    boolean cashierStep =  "Served".equals(currentStatus)     && "Paid".equals(nextStatus);
    boolean runnerStep  =  "Ready".equals(currentStatus)      && "Served".equals(nextStatus);
    if ("admin".equals(role))   return baristaStep || cashierStep || runnerStep;
    if ("barista".equals(role)) return baristaStep;
    if ("cashier".equals(role)) return cashierStep;
    if ("runner".equals(role))  return runnerStep;
    return false;
}
```

Waiter chỉ có **đúng một** bước hợp lệ: `Ready → Served`.

```
Pending ──barista──> Preparing ──barista──> Ready ──runner──> Served ──cashier──> Paid
```

**Nêu 4 hệ quả cụ thể (nói được là rất chắc bài):**

1. Waiter nhấn giữ 2 lần trên một card → lần thứ hai `currentStatus` đã là `Served` → `runnerStep = false` → **403**. Đây là lớp chống double-serve ở server.
2. Waiter không nhảy được `Ready → Paid` để tự thanh toán.
3. Không đi lùi được — không có cặp `Served → Ready` nào trong hàm, **kể cả admin**.
4. Chưa đăng nhập thì `role(req)` trả `""` (chuỗi rỗng, không phải `null`) → rơi xuống `return false`.

**Điểm thiết kế đáng khen:** hàm này gộp **cả hai** câu hỏi "ai được làm" và "từ trạng thái nào sang trạng thái nào" vào một chỗ. Nếu tách rời thì dễ sót trường hợp.

## B3. "Validate ở tầng service của waiter gồm những gì?"

**`clearServedTable` — dọn bàn, có 4 lớp validate xếp thứ tự hợp lý:**

```java
if (table == null)         throw new IllegalArgumentException("Không tìm thấy bàn.");
if (notClearedYet > 0)     throw new IllegalArgumentException("Bàn vẫn còn đơn đang phục vụ, chưa thể dọn.");
if (orderIds.isEmpty())    throw new IllegalArgumentException("Bàn này không có đơn chờ dọn.");
if (clearedCount == 0)     throw new IllegalArgumentException("Bàn này vừa được cập nhật bởi thiết bị khác.");
```

**Thứ tự này quan trọng — giải thích được là ăn điểm:** kiểm tra tồn tại trước, rồi nghiệp vụ, rồi tranh chấp đồng thời cuối cùng. Cái cuối chỉ phát hiện được **sau khi** đã thử ghi.

**`transferTable` — đổi bàn, 5 lớp:**

```java
if (fromTableId == toTableId)              throw ... ("Bàn mới phải khác bàn hiện tại.");
if (from == null || to == null)            throw ... ("Không tìm thấy bàn.");
if (!active(from) || !active(to))          throw ... ("Bàn đã ẩn không thể đổi.");
if (sourceOrders == 0)                     throw ... ("Bàn hiện tại không có đơn cần chuyển.");
if (targetOrders > 0)                      throw ... ("Bàn mới đang có khách.");
```

Chú ý `targetOrders` đếm với danh sách trạng thái **có thêm `'Paid'`**, còn `sourceOrders` thì không — vì bàn đích còn đơn chưa dọn cũng không được nhận khách mới.

## B4. ⭐ "Waiter có thấy giá tiền không?" — validate dữ liệu trả về

**Câu trả lời tốt, vì làm ở server chứ không ẩn bằng CSS.** Hai chỗ:

`LiteApiServlet.java:928` — cho một đơn:

```java
private void sanitizeRunnerOrder(Map<String, Object> order) {
    if (order == null) return;
    order.remove("total");
    order.remove("customerPhone");
    Object items = order.get("items");
    if (!(items instanceof Iterable<?>)) return;
    for (Object raw : (Iterable<?>) items) {
        if (raw instanceof Map<?, ?>) ((Map<String, Object>) raw).remove("price");
    }
}
```

`LiteService.java:1480` — `sanitizeRunnerOrders` làm tương tự cho cả danh sách, gọi ở cuối `getOrders()` khi `role = "runner"`.

**Nhấn mạnh:** xoá **trước khi** serialize JSON, nên waiter mở DevTools cũng không thấy. Nếu chỉ `display:none` bên CSS thì dữ liệu vẫn nằm trong response — vô nghĩa về bảo mật.

## B5. "In hóa đơn — em validate gì?"

**Hai tầng, và tầng service dùng optimistic locking.**

Servlet (`LiteApiServlet.java:338`) chặn role và trạng thái:

```java
if (!"runner".equals(printRole) && !"admin".equals(printRole)) {
    error(resp, SC_FORBIDDEN, "Chỉ bồi bàn được ghi nhận in hóa đơn.");
    break;
}
if ("runner".equals(printRole)) {
    status = str(existingInvoice.get("status"));
    if (!"Ready".equals(status) && !"Served".equals(status)) {
        error(resp, SC_FORBIDDEN, "Chỉ in được hóa đơn đơn đang phục vụ.");
        break;
    }
}
```

Service (`LiteService.java:2145`) không tin tầng trên, kiểm tra lại **ngay trong câu UPDATE**:

```java
"UPDATE dbo.Orders SET invoicePrinted=1 WHERE id=? AND status IN ('Ready','Served')"
int updated = ps.executeUpdate();
if (updated == 0) {
    Map<String, Object> order = getOrderById(id);
    if (order == null) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
    throw new IllegalArgumentException("Chỉ đánh dấu đã in cho đơn Ready hoặc Served.");
}
```

**Chi tiết tinh tế nên chỉ ra:** khi `updated == 0`, code **query lại** để phân biệt hai nguyên nhân — đơn không tồn tại, hay đơn tồn tại nhưng sai trạng thái. Hai thông báo lỗi khác nhau. Đây là kiểu validate cho ra thông báo hữu ích thay vì báo chung chung.

## B6. "Client có validate gì không?"

Có 3 cơ chế trong `page-runner.js`, nên nói rõ là **để trải nghiệm, không phải bảo mật**:

**1. Chống double-submit bằng `Set`:**

```js
const servingInProgress = new Set();
const clearingInProgress = new Set();

async function serveOrder(orderId) {
    if (!orderId || servingInProgress.has(Number(orderId))) return;
    servingInProgress.add(Number(orderId));
    try { /* gọi API */ }
    finally { servingInProgress.delete(Number(orderId)); }   // finally: luôn dọn kể cả khi lỗi
}
```

**2. Nhấn giữ 0.5 giây thay vì bấm một phát** — chống chạm nhầm trên điện thoại:

```js
holdTimer = setTimeout(async () => { ... await action(); }, 500);
```

**3. Cảnh báo khi chưa in hóa đơn** — `confirmServeWithoutInvoice()` mở modal, trả về `Promise`, chỉ chạy tiếp khi người dùng bấm "Vẫn phục vụ".

**Câu chốt:** "Ba cái này người dùng bỏ qua được hết bằng DevTools. Nên server vẫn kiểm tra lại toàn bộ — `canSetStatus` chặn double-serve, và service chặn sai trạng thái."

## B7. ⚠️ "Validate của waiter có lỗ nào không?" — nên chủ động nêu

**Lỗ 1 — servlet gộp mọi lỗi thành 400.** Cuối `doPost` (`LiteApiServlet.java:653`):

```java
} catch (Exception e) {
    error(resp, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
}
```

Bắt `Exception` chung nên lỗi nhập liệu và lỗi hệ thống đều ra 400. Waiter dọn bàn lúc DB mất kết nối sẽ nhận **400** thay vì 500, và `e.getMessage()` của `NullPointerException` thường là `null` → người dùng thấy thông báo trống.

**Sửa:**

```java
} catch (IllegalArgumentException badInput) {
    error(resp, HttpServletResponse.SC_BAD_REQUEST, badInput.getMessage());
} catch (Exception systemError) {
    error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi hệ thống, vui lòng thử lại.");
}
```

**Nói kèm:** "Project **đã** làm đúng cách này ở `/inventory/save` (`LiteApiServlet.java:538`) và `/inventory/delete` (dòng 581) — có tách `catch (IllegalArgumentException)` riêng. Chỉ là chưa áp dụng cho các endpoint còn lại."

**Lỗ 2 — client bỏ mất thông báo lỗi của server.** `serveOrder()` trong `page-runner.js`:

```js
if (!res.ok) { notifyWork(t('statusMoveFailed')); return; }   // vứt bỏ body response
```

Server trả `{"error": "Chỉ được chuyển trạng thái theo đúng thứ tự."}` nhưng waiter chỉ thấy thông báo chung chung. Trong khi `clearTable()` **ngay bên dưới** lại làm đúng:

```js
const data = await res.json();
if (data && data.error) message = data.error;
```

**Lỗ 3 — biến bị dùng chung giữa các case.** Ở `LiteApiServlet.java:351`, case `/orders/invoice/printed` gán:

```java
status = str(existingInvoice.get("status"));
```

`status` không được khai báo trong case này — nó là biến khai báo ở case `/orders/status` (dòng 296). Vì các case trong `switch` **không bọc `{ }`** nên biến leak ra toàn khối. Code vẫn chạy đúng, nhưng khó đọc và dễ gây lỗi khi sửa. Đó cũng là lý do các case khác phải đặt tên khác đi: `clearRole`, `transferRole`, `printRole`, `splitRole`.

**Sửa:** bọc mỗi case trong `{ }` — case `/orders/invoice/printed` đã làm đúng (`case "...": {`), chỉ cần làm nốt cho `/orders/status`.

---

# PHẦN C — BẢNG TỔNG: NÊN CHỦ ĐỘNG NHẬN

Thầy cô đánh giá cao sinh viên **biết code mình yếu ở đâu**. Học thuộc bảng này, chủ động nêu 2–3 cái trước khi bị hỏi.

| # | Điểm yếu (phần waiter) | Câu nói gọn |
|---|---|---|
| 1 | N+1 ở `getOrders` | "15 đơn thành 16 query, mà waiter poll 5 giây một lần" |
| 2 | Bug `floorNo` ở `getRunnerTableMap` | "Sanitize kiểu whitelist nên quên field là mất dữ liệu âm thầm" |
| 3 | 0 index trên `status`, `orderId`, `tableName` | "SQL Server không tự tạo index cho khoá ngoại" |
| 4 | TOCTOU ở `/orders/status` | "Em làm đúng ở `clearServedTable` nhưng chưa áp dụng đồng đều" |
| 5 | Không rollback tường minh | "Em dựa vào hành vi ngầm của JDBC" |
| 6 | `catch (Exception)` gộp lỗi thành 400 | "Lỗi hệ thống phải là 500" |
| 7 | `countOpenOrders` nối chuỗi `statuses` | "Chưa exploit được nhưng là mã dễ hỏng" |
| 8 | Không có connection pool | "Mỗi query mở TCP + bắt tay TLS mới" |

# PHẦN D — BẢNG TỔNG: ĐIỂM MẠNH NÊN KHOE

Đừng chỉ nhận lỗi. Chuẩn bị sẵn 5 cái này:

| # | Điểm mạnh | Nói ở đâu |
|---|---|---|
| 1 | `clearServedTable` dùng **cả** pessimistic (`UPDLOCK`) **và** optimistic locking | A5 |
| 2 | `OUTER APPLY` lấy đơn mới nhất của mỗi bàn trong 1 query | A1 |
| 3 | `canSetStatus` ép luồng trạng thái một chiều, gộp cả role lẫn thứ tự | B2 |
| 4 | Sanitize ở **server** trước khi serialize, không ẩn bằng CSS | B4 |
| 5 | `markInvoicePrinted` query lại để cho **2 thông báo lỗi khác nhau** | B5 |

# PHẦN E — SỬA NGAY TẠI CHỖ

Nếu thầy cô bảo "em sửa cho tôi xem", 4 bản sửa nhỏ nhất mà tác động rõ nhất:

**E1. Thêm index — chạy thẳng trên SSMS, không cần build lại:**

```sql
CREATE NONCLUSTERED INDEX IX_OrderItems_Order ON dbo.OrderItems(orderId);
CREATE NONCLUSTERED INDEX IX_Orders_Status    ON dbo.Orders(status);
```

**E2. Thêm rollback — 4 dòng, trong `clearServedTable`:**

```java
} catch (Exception e) {
    con.rollback();
    throw e;
}
```

**E3. Tách catch trong servlet — 3 dòng, cuối `doPost`** (xem B7 lỗ 1).

**E4. Sửa client đọc message lỗi — 2 dòng, trong `serveOrder()`:**

```js
if (!res.ok) {
    let message = t('statusMoveFailed');
    try { const data = await res.json(); if (data && data.error) message = data.error; } catch (err) {}
    notifyWork(message);
    return;
}
```

---

# PHẦN F — CÂU HỎI BẪY

**"Dùng `PreparedStatement` là chống được SQL injection hoàn toàn chưa?"**

→ Chưa. `PreparedStatement` chỉ tham số hoá được **giá trị**, không tham số hoá được **tên bảng, tên cột, hay từ khoá SQL**. Đúng như `countOpenOrders` — không thể viết `status IN ?`. Với những chỗ đó phải whitelist trong code, không nhận từ input.

**"Waiter poll 5 giây, sao không để 1 giây cho nhanh?"**

→ Mỗi lần poll đang tốn 16 query. Giảm xuống 1 giây là nhân 5 tải. Hướng đúng không phải chỉnh con số mà là đổi cơ chế — WebSocket/SSE để server đẩy khi có thay đổi. Nếu bắt buộc giữ polling thì nên sửa N+1 trước, và thêm cơ chế trả `304 Not Modified` khi dữ liệu không đổi.

**"Nếu waiter đang nhấn giữ card mà đúng lúc poll chạy thì sao?"**

→ Đây là bug thật, nên thừa nhận. Mỗi vòng `loadWork()` dẫn tới `renderWork()`, và hàm này gán `holder.innerHTML = html` (`page-runner.js:106`) thay toàn bộ DOM, nên card đang giữ bị detach → sự kiện `onpointerup` của nó không bắn nữa → `cancelHold()` không được gọi → nhưng `setTimeout` 500ms vẫn sống và **vẫn serve món dù waiter đã nhả tay**. Cách sửa: tạm dừng polling khi đang giữ card, hoặc render theo diff thay vì thay cả `innerHTML`.

**"Transaction của em ở isolation level nào?"**

→ Mặc định SQL Server là `READ COMMITTED`. Em không đổi level mà dùng lock hint `UPDLOCK` ở từng câu đọc cần bảo vệ — nhắm đúng chỗ hơn là nâng cả transaction lên `SERIALIZABLE`, vì `SERIALIZABLE` dễ gây deadlock và giảm thông lượng.

**"Sao waiter query bằng `tableName` mà không phải `tableId`?"**

→ Câu hỏi hay và là điểm yếu thiết kế thật. `Orders.tableName` là `NVARCHAR(60)`, **không** có khoá ngoại tới `Tables`. Nên đổi tên bàn là mất liên kết với các đơn cũ, và join phải so chuỗi thay vì số. Đúng ra nên là `tableId INT REFERENCES dbo.Tables(id)`.

---

# PHỤ LỤC — TRA CỨU NHANH

| Nội dung | File | Dòng |
|---|---|---|
| Polling 5 giây | `web/assets/js/page-runner.js` | 25 |
| Gọi 2 API song song (trong `loadWork`) | `web/assets/js/page-runner.js` | 29 |
| Whitelist endpoint cho runner | `src/java/servlet/SecurityFilter.java` | 98 |
| Endpoint `/orders/status` | `src/java/servlet/LiteApiServlet.java` | 294 |
| `/orders/invoice/printed` | `src/java/servlet/LiteApiServlet.java` | 338 |
| `/tables/clear` | `src/java/servlet/LiteApiServlet.java` | 634 |
| `catch (Exception)` → 400 | `src/java/servlet/LiteApiServlet.java` | 653 |
| `canSetStatus()` | `src/java/servlet/LiteApiServlet.java` | 915 |
| `sanitizeRunnerOrder()` | `src/java/servlet/LiteApiServlet.java` | 928 |
| `getTableMap()` — `OUTER APPLY` | `src/java/service/LiteService.java` | 986 |
| `getRunnerTableMap()` — bug `floorNo` | `src/java/service/LiteService.java` | 1001 |
| `transferTable()` | `src/java/service/LiteService.java` | 1071 |
| `tableRowForUpdate()` — `UPDLOCK` | `src/java/service/LiteService.java` | 1108 |
| `countOpenOrders()` — nối chuỗi | `src/java/service/LiteService.java` | 1117 |
| `clearServedTable()` — optimistic locking | `src/java/service/LiteService.java` | 1131 |
| `getOrders()` — N+1 | `src/java/service/LiteService.java` | 1445, 1460 |
| `sanitizeRunnerOrders()` | `src/java/service/LiteService.java` | 1480 |
| `updateOrderStatus()` — transaction | `src/java/service/LiteService.java` | 1505 |
| `getOrderById()` | `src/java/service/LiteService.java` | 2126 |
| `markInvoicePrinted()` | `src/java/service/LiteService.java` | 2145 |
| `getOrderItems()` — N+1 | `src/java/service/LiteService.java` | 2159 |
| `placeholders()` | `src/java/service/LiteService.java` | 2633 |
