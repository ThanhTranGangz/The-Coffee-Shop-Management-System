# Vấn đáp NGHIỆP VỤ — Hệ thống quản lý quán cà phê

Khác với câu hỏi về code, câu hỏi nghiệp vụ kiểm tra bạn **hiểu bài toán thực tế** hay chỉ code theo yêu cầu. Dưới đây là những gì thầy cô hay hỏi, kèm câu trả lời dẫn chiếu code thật.

---

# PHẦN A — CÂU MỞ ĐẦU

## A1. ⭐ "Hệ thống của em làm gì?" — chuẩn bị 60 giây

**Trả lời mẫu:**

"Đây là hệ thống quản lý quán cà phê tại chỗ, phục vụ **5 loại người dùng**: khách hàng, pha chế, bồi bàn, thu ngân và quản lý.

Khách quét mã QR dán trên bàn để tự gọi món, không cần gọi nhân viên. Đơn hàng đi qua **một luồng trạng thái một chiều**: khách đặt → pha chế nhận và pha → bồi bàn bưng ra → thu ngân thu tiền → bồi bàn dọn bàn. Mỗi vai trò chỉ nhìn thấy và chỉ thao tác được đúng phần việc của mình.

Hệ thống tự động **trừ kho nguyên liệu theo công thức** khi pha chế xong món, và tự tắt món khỏi thực đơn khi hết nguyên liệu. Ngoài ra có quản lý ca làm, đối soát tiền mặt và nhật ký thao tác."

**Ba con số nên nhớ:** 5 vai trò, 6 trạng thái đơn, 13 bảng dữ liệu.

## A2. "Vì sao chọn đề tài này?"

Trả lời theo hướng bài toán có **nhiều vai trò cộng tác đồng thời trên cùng dữ liệu** — đây là điểm khó thật sự, không phải chỉ CRUD.

Ví dụ cụ thể: cùng một đơn hàng, pha chế thấy nó ở màn hình của mình, bồi bàn thấy ở màn hình khác, thu ngân thấy ở màn hình thứ ba — nhưng mỗi người chỉ được làm đúng một việc, và không ai được làm chồng lên người khác.

---

# PHẦN B — LUỒNG NGHIỆP VỤ CHÍNH

## B1. ⭐ "Mô tả quy trình từ lúc khách vào quán đến lúc rời đi"

**Đây là câu quan trọng nhất. Học thuộc 7 bước:**

```
1. Khách ngồi xuống, quét QR trên bàn        → menu.jsp?tableCode=...
2. Chọn món, gửi đơn                          → status = Pending
3. Pha chế nhận đơn                           → Pending → Preparing
4. Pha chế pha xong, trừ kho + trừ cốc        → Preparing → Ready
5. Bồi bàn in hóa đơn, bưng món ra            → Ready → Served
6. Khách đưa hóa đơn, thu ngân thu tiền       → Served → Paid
7. Khách rời đi, bồi bàn dọn bàn              → Paid → Cleared
```

**Điểm nhấn khi trình bày:** đây là luồng **một chiều, không đi lùi được**. Mỗi mũi tên do đúng một vai trò thực hiện, và server kiểm tra chặt bằng `canSetStatus()`.

## B2. "Vì sao lại là quét QR mà không phải gọi nhân viên?"

Ba lý do nghiệp vụ:

1. **Giảm sai sót** — khách tự chọn nên không có chuyện nhân viên nghe nhầm món hay nhầm bàn
2. **Giảm nhân sự giờ cao điểm** — không cần người đứng ghi order
3. **Bàn được xác định tự động** — mã QR gắn cứng với bàn nên đơn luôn đúng bàn

Code chặn khách đặt món khi chưa quét QR:

```java
if (table == null || !hasVerifiedGuestTable(req)) {
    throw new IllegalArgumentException("Vui lòng quét QR trên bàn để gọi món.");
}
```

## B3. "Khách bấm gửi đơn hai lần thì sao?"

Hệ thống có **cửa sổ chống trùng 5 giây**:

```java
private static final long DUPLICATE_ORDER_WINDOW_MS = 5000;
...
if (signature.equals(previousSignature) && previousOrderId > 0
        && now - previousAt <= DUPLICATE_ORDER_WINDOW_MS) {
    Map<String, Object> existing = service.getOrderById(previousOrderId);
    existing.put("duplicate", true);
    return existing;      // trả lại đơn cũ, KHÔNG tạo đơn mới
}
```

`signature` là chuỗi ghép từ tên bàn + ghi chú + danh sách món. Nếu trong 5 giây khách gửi lại **đúng nội dung đó**, hệ thống trả lại đơn cũ thay vì tạo đơn thứ hai.

**Vì sao 5 giây:** đủ để chặn double-click hoặc mạng chậm gửi lại, nhưng không chặn khách thật sự muốn gọi thêm một phần y hệt.

---

# PHẦN C — CÂU HỎI THEO TỪNG VAI TRÒ

## C1. "Pha chế làm được những gì?"

Ba việc:

1. **Nhận đơn**: `Pending → Preparing` — báo cho cả hệ thống biết đơn đang được xử lý
2. **Đánh dấu từng món đã pha** — với đơn nhiều món, pha xong món nào tick món đó
3. **Hoàn thành đơn**: `Preparing → Ready` — lúc này mới trừ kho

**Chi tiết đáng nói về việc 2** (`prepareOrderItem`, dòng 2169): nó chỉ chạy khi đơn đã ở `Preparing`:

```java
if (!"Preparing".equals(currentStatus)) {
    throw new IllegalStateException("Chỉ pha được món khi đơn đang pha. Hãy nhận đơn từ Chờ xử lý trước.");
}
```

Cột `OrderItems.preparedQty` lưu số phần đã pha trong tổng `quantity`. Đơn gọi 3 ly, pha xong 2 thì `preparedQty = 2`.

⭐ **Chi tiết đáng khoe:** khi pha chế tick nốt **phần cuối cùng** của đơn, `prepareOrderItem()` **tự động** trừ cốc, trừ kho và đẩy đơn sang `Ready` luôn — không cần bấm nút "Hoàn thành đơn" riêng. Việc 1 và việc 3 gộp làm một ở bước cuối.

## C2. ⭐ "Bồi bàn làm được những gì?"

Bốn việc, và đây là vai trò bị giới hạn chặt nhất:

| Việc | Thao tác | Kết quả |
|---|---|---|
| Bưng món ra | Nhấn giữ card 0.5s | `Ready → Served` |
| In hóa đơn | Bấm nút "In hóa đơn" | `invoicePrinted = 1` |
| Dọn bàn | Nhấn giữ card 0.5s | Mọi đơn `Paid` của bàn → `Cleared` |
| Đổi bàn | Trang "Đổi bàn" | Chuyển đơn sang bàn khác |

**Ba giới hạn cần nêu:**

- Chỉ được chuyển **đúng một bước** trạng thái: `Ready → Served`
- **Không thấy giá tiền** — server xóa `total`, `price`, `customerPhone` trước khi gửi
- Thao tác quan trọng phải **nhấn giữ 0.5 giây**, chống chạm nhầm trên điện thoại

## C3. "Thu ngân làm được những gì?"

1. **Thu tiền**: `Served → Paid`
2. **Tách hóa đơn** — khách đi nhóm muốn trả riêng
3. **Chốt tiền mặt cuối ca** — đối soát số tiền thực đếm với số hệ thống ghi nhận
4. **Xác nhận thông báo rút tiền** từ quản lý
5. **Đổi bàn** — `SecurityFilter` cho cả `cashier` lẫn `runner` gọi `/api/tables/transfer`, nên đây không phải việc riêng của bồi bàn

## C4. "Quản lý làm được những gì?"

Quản lý đăng nhập bằng **mã PIN** riêng (`8888`), không qua form đăng nhập thường. Làm được:

- Quản lý thực đơn (thêm/sửa/ẩn món, import từ Excel)
- Quản lý bàn và sinh mã QR
- Quản lý kho nguyên liệu và công thức
- Quản lý nhân viên, xếp ca làm
- Rút tiền mặt khỏi két
- Cập nhật số cốc
- Xem dashboard doanh thu và nhật ký hệ thống

---

# PHẦN D — NGHIỆP VỤ ĐẶC BIỆT

## D1. ⭐⭐ "Hệ thống trừ kho nguyên liệu như thế nào?"

**Đây là nghiệp vụ hay nhất, nên chuẩn bị kỹ.**

Mỗi món có **công thức** — bảng `RecipeItems` ghi món này cần nguyên liệu gì, bao nhiêu cho một phần. Ví dụ cà phê sữa = 20g hạt cà phê + 30g sữa đặc.

Khi pha chế chuyển đơn `Preparing → Ready`, hệ thống join qua công thức để tính tổng lượng cần trừ:

```sql
SELECT ri.ingredientId, SUM(ri.quantity * oi.quantity) usedQuantity
FROM dbo.OrderItems oi
JOIN dbo.RecipeItems ri ON ri.menuItemId = CONVERT(VARCHAR(50), oi.menuItemId)
WHERE oi.orderId = ?
GROUP BY ri.ingredientId
```

Phép nhân `ri.quantity * oi.quantity` = **định lượng một phần × số phần khách gọi**. Khách gọi 3 ly cà phê sữa thì trừ 60g cà phê và 90g sữa. `GROUP BY` để nếu đơn có nhiều món cùng dùng sữa thì cộng dồn rồi trừ một lần.

## D2. ⭐ "Vì sao trừ kho lúc `Preparing → Ready` mà không phải lúc khách đặt?"

**Câu hỏi hay, thể hiện hiểu nghiệp vụ:**

Vì lúc khách đặt, món **chưa được pha** — nguyên liệu vẫn còn nguyên trong kho. Nếu trừ ngay lúc đặt mà sau đó đơn bị hủy thì phải cộng trả lại, dễ sai sót.

Trừ đúng lúc pha xong là **khớp với thực tế vật lý**.

**Nhưng phát sinh vấn đề:** các đơn `Pending`/`Preparing` chưa trừ kho nhưng đã "hứa" phần nguyên liệu đó. Nếu chỉ nhìn `Inventory.stock` thì hệ thống sẽ cho khách đặt vượt quá khả năng.

Giải pháp: khi khách đặt, hệ thống nạp **cả hai** bảng để tính:

```java
Map<String, Integer> stockMap    = getIngredientStockMap(con);        // kho thực tế
Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);  // đã giữ bởi đơn chưa pha
```

Rồi báo: `"Chỉ còn N suất, không đủ số lượng đã chọn."`

**Thuật ngữ nên dùng:** tách bạch giữa **"giữ chỗ" (reserve)** và **"trừ thật" (deduct)**.

## D3. "Món hết nguyên liệu thì sao?"

Hệ thống **tự tắt món khỏi thực đơn** — `MenuItems.active` về `0`, qua hai hàm `deactivateUnavailableMenuItems()` và `refreshMenuAvailability()`.

Khách mở thực đơn sẽ không thấy món đó nữa.

⚠️ **Cơ chế chỉ có một chiều — tắt.** Cả `deactivateUnavailableMenuItems()` lẫn `refreshMenuAvailability()` chỉ chạy `UPDATE dbo.MenuItems SET active=0`. **Không có nhánh bật lại.** Admin nhập thêm nguyên liệu xong phải tự vào trang quản lý thực đơn bật món bằng tay. Đây là điểm em có thể mở rộng.

Thông báo trả về cả số món bị tắt: `"Admin lưu nguyên liệu i1 - Hạt cà phê nguyên chất (tắt 3 món hết hàng)"`.

## D4. ⭐ "Số cốc để làm gì?"

Đây là **ràng buộc vật lý** ít người nghĩ tới — quán có hữu hạn cốc, rửa xong mới dùng lại được.

`StoreState` lưu `cupsAvailable`. Chỉ **món thuộc nhóm đồ uống** mới tính cốc — `cupCountForOrder()` lọc bằng `isDrinkCategory()`, nên croissant, tiramisu, cheesecake không trừ cốc nào.

Khi pha chế chuyển đơn sang `Ready`:

```java
int requiredCups = cupCountForOrder(con, id);
int cups = stateValueForUpdate(con, "cupsAvailable", 0);
if (requiredCups > cups) {
    throw new IllegalArgumentException("Đơn này cần " + requiredCups + " cốc, hiện chỉ còn " + cups + " cốc.");
}
setStateValue(con, "cupsAvailable", cups - requiredCups);
```

Admin cập nhật số cốc qua `/cups/update`, có **hai chế độ**:

```java
int next = "adjust".equalsIgnoreCase(mode) ? current + amount : amount;
```

- `adjust` — cộng thêm (rửa xong 20 cốc thì `+20`)
- mặc định — đặt lại giá trị tuyệt đối (kiểm kê thấy còn đúng 85 cốc)

## D5. ⭐ "Tách hóa đơn dùng khi nào?"

Khách đi nhóm 4 người ngồi chung bàn, gọi chung một đơn, nhưng muốn **trả riêng**.

Thu ngân chọn những món thuộc về một người, hệ thống tạo **đơn mới** chứa các món đó, và trừ bớt khỏi đơn gốc.

**Ba ràng buộc nghiệp vụ:**

```java
// 1. Chỉ tách được đơn đang chờ thanh toán
"SELECT orderNumber, tableName FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=? AND status='Served'"
if (!rs.next()) throw new IllegalArgumentException("Chỉ tách được hóa đơn đang chờ thanh toán.");

// 2. Phải để lại ít nhất 1 món trên đơn gốc
throw new IllegalArgumentException("Phải để lại ít nhất 1 món trên hóa đơn gốc.");

// 3. Số lượng tách không vượt quá số lượng có
throw new IllegalArgumentException("Số lượng tách vượt quá số lượng của món.");
```

Tổng tiền của **cả hai** hóa đơn (gốc và mới) được tính lại bằng `updateOrderTotal()`.

⚠️ **Chỗ này phải nói cẩn thận.** Cả đơn gốc và đơn mới đều được gán `splitLocked = 1`, nhưng cờ này **chỉ được ghi, chưa bao giờ được đọc** — không có `WHERE splitLocked=0` hay `if` nào kiểm tra nó, và `getOrderById` cũng không trả cột này về client. Ràng buộc duy nhất đang hoạt động là `status='Served'`, mà đơn gốc sau khi tách **vẫn ở `Served`** nên **vẫn tách tiếp được**.

Nếu thầy cô hỏi "em chặn tách nhiều lần ở đâu", đừng chỉ vào `splitLocked` — hãy trả lời thật: "Em có cột `splitLocked` để đánh dấu nhưng chưa dùng nó để chặn. Hiện chỉ có ràng buộc `status='Served'` và phải để lại ít nhất 1 món. Sửa thì thêm `AND splitLocked=0` vào câu SELECT khóa đơn nguồn."

## D6. "Đổi bàn dùng khi nào?"

Khách đang ngồi bàn 3, muốn chuyển sang bàn 8 rộng hơn — nhưng đã gọi món rồi.

`transferTable()` chuyển **tất cả đơn đang hoạt động** từ bàn cũ sang bàn mới:

```sql
UPDATE dbo.Orders SET tableName = ?
WHERE tableName = ? AND status IN ('Pending','Preparing','Ready','Served')
```

**Năm điều kiện kiểm tra:**

| Điều kiện | Thông báo |
|---|---|
| Bàn nguồn ≠ bàn đích | "Bàn mới phải khác bàn hiện tại." |
| Cả hai bàn tồn tại | "Không tìm thấy bàn." |
| Cả hai bàn chưa bị ẩn | "Bàn đã ẩn không thể đổi." |
| Bàn nguồn **có** đơn để chuyển | "Bàn hiện tại không có đơn cần chuyển." |
| Bàn đích **trống** | "Bàn mới đang có khách." |

**Chi tiết tinh tế:** khi đếm bàn đích, danh sách trạng thái **có thêm `'Paid'`** — bàn còn đơn đã trả tiền nhưng chưa dọn thì cũng không nhận khách mới được.

## D7. "Đối soát tiền mặt thế nào?"

Bảng `CashEvents` là **sổ cái tiền mặt** — chỉ ghi thêm, không sửa.

**Cuối ca, thu ngân đếm tiền thật trong két rồi nhập vào:**

```java
int current = currentCashBalance(con);      // số hệ thống ghi nhận
int diff = countedCash - current;           // chênh lệch
insertCashEvent(con, "CASHIER_COUNT", diff, countedCash, ...);
```

`diff` chính là số **thừa/thiếu**. Hệ thống không tự sửa mà ghi lại chênh lệch để truy vết.

**Quản lý rút tiền khỏi két:**

```java
if (amount > current) throw new IllegalArgumentException("Số tiền rút lớn hơn tiền mặt hiện có.");
insertCashEvent(con, "ADMIN_WITHDRAW", -amount, balance, "Admin withdraw", "admin", actorName, false);
```

Tham số cuối `false` là `seenByCashier` — thu ngân sẽ thấy **thông báo** rằng quản lý vừa rút tiền, để không hoang mang khi đếm thấy thiếu. Bấm xác nhận thì cờ về `true`.

**Cột `balanceAfter`** lưu số dư ngay sau mỗi sự kiện, nên tra số dư tại bất kỳ thời điểm nào mà không cần cộng dồn lại từ đầu.

## D8. "Xếp ca làm thế nào?"

Mỗi ca cần đủ **3 vị trí**: Barista, Cashier, Waiter — lưu ở `Shifts.assignedRole`.

Ba ca trong ngày: Ca Sáng (06:00–12:00), Ca Chiều (12:00–18:00), Ca Tối (18:00–23:00).

**Ràng buộc ở mức database:**

```sql
CREATE UNIQUE INDEX UX_Shifts_StaffDateName ON dbo.Shifts(staffId, shiftDate, shiftName)
```

Một nhân viên **không thể** bị xếp hai lần vào cùng ca cùng ngày.

Có chức năng `carryOver` — sao chép lịch tuần này sang tuần sau, đỡ phải xếp lại từ đầu.

---

# PHẦN E — CÂU HỎI "VÌ SAO THIẾT KẾ THẾ"

## E1. "Vì sao 6 trạng thái mà không phải ít hơn?"

Mỗi trạng thái đánh dấu **một lần bàn giao trách nhiệm** giữa hai vai trò:

| Trạng thái | Ai đang giữ việc | Vì sao cần |
|---|---|---|
| `Pending` | chưa ai | Phân biệt đơn mới với đơn đã có người nhận |
| `Preparing` | pha chế | Tránh hai pha chế cùng làm một đơn |
| `Ready` | bồi bàn | Món xong rồi, ai đó phải bưng ra |
| `Served` | thu ngân | Đã bưng, chờ khách trả tiền |
| `Paid` | bồi bàn | Đã trả tiền, bàn cần dọn |
| `Cleared` | xong | Bàn trống, sẵn sàng đón khách mới |

Gộp bớt sẽ mất thông tin. Ví dụ bỏ `Ready` thì không biết món đã pha xong hay chưa — bồi bàn phải chạy vào bếp hỏi.

## E2. "Vì sao bồi bàn không thấy giá tiền?"

Ba lý do:

1. **Phân tách trách nhiệm** — thu tiền là việc của thu ngân, bồi bàn không cần biết
2. **Giảm rủi ro gian lận** — bồi bàn không biết giá thì khó thỏa thuận riêng với khách
3. **Bảo mật thông tin khách** — `customerPhone` cũng bị xóa

Và quan trọng: **xóa ở server**, không phải ẩn bằng CSS:

```java
private void sanitizeRunnerOrder(Map<String, Object> order) {
    order.remove("total");
    order.remove("customerPhone");
    for (...) ((Map<String, Object>) raw).remove("price");
}
```

Ẩn bằng CSS thì mở DevTools là thấy — vô nghĩa về bảo mật.

## E3. "Vì sao bồi bàn phải nhấn giữ chứ không bấm?"

Vì các thao tác này **không hoàn tác được**. Bồi bàn cầm điện thoại chạy quanh quán, bấm nhầm rất dễ. Nhấn giữ 0.5 giây buộc phải có chủ đích.

Cộng thêm cảnh báo khi chưa in hóa đơn mà đã bấm phục vụ.

## E4. "Vì sao màn hình tự cập nhật?"

Vì **nhiều người làm việc đồng thời trên cùng dữ liệu**. Pha chế xong món thì bồi bàn phải biết ngay, không thể bắt họ bấm F5 liên tục.

Hiện dùng **polling 5 giây** — client hỏi server mỗi 5 giây.

**Thừa nhận luôn hạn chế:** cách này tốn tài nguyên vì phần lớn lần hỏi không có gì mới. Hướng cải thiện đúng là WebSocket hoặc Server-Sent Events để server chủ động đẩy khi có thay đổi.

## E5. "Vì sao đăng nhập theo vai trò mà không theo từng người?"

Trả lời trung thực: đây là **hạn chế của thiết kế hiện tại**. Hệ thống có 4 tài khoản cố định (`admin`, `barista`, `cashier`, `runner`), và bảng `Staff` (nhân viên để xếp ca) **hoàn toàn tách rời** với `Users` — không có cột nào nối hai bảng.

Hệ quả: không biết ca làm nào ứng với tài khoản nào. Muốn truy vết ai làm gì phải dựa vào `SystemLogs.actorName`.

Hướng sửa: thêm `Staff.userId` trỏ tới `Users.username`, và cho mỗi nhân viên một tài khoản riêng.

---

# PHẦN F — CÂU HỎI TÌNH HUỐNG

**"Hai bồi bàn cùng bấm phục vụ một món thì sao?"**

→ Người thứ hai bị chặn. `canSetStatus("runner", "Served", "Served")` trả `false` vì bước hợp lệ duy nhất của bồi bàn là `Ready → Served`, mà đơn đã ở `Served` rồi → **403**.

**"Bồi bàn dọn nhầm bàn còn khách thì sao?"**

→ Bị chặn ở service: `"Bàn vẫn còn đơn đang phục vụ, chưa thể dọn."` Hệ thống đếm đơn ở `Pending`/`Preparing`/`Ready`/`Served`, còn dòng nào là từ chối.

**"Hai pha chế cùng hoàn thành đơn, số cốc có bị trừ hai lần không?"**

→ Không. Câu đọc số cốc dùng `SELECT ... WITH (UPDLOCK, ROWLOCK)` nên hai giao dịch bị tuần tự hóa. Không có lock thì cả hai đọc cùng giá trị rồi cùng trừ — gọi là **lost update**.

**"Khách gọi món hết nguyên liệu thì sao?"**

→ Hai lớp chặn. Lớp một: món đã bị tự tắt khỏi thực đơn nên khách không thấy. Lớp hai: nếu vừa hết trong lúc khách đang chọn, lúc gửi đơn hệ thống tính lại và báo `"Chỉ còn N suất, không đủ số lượng đã chọn."`

**"Admin đổi tên bàn thì các đơn cũ thế nào?"**

→ **Mất liên kết.** Đây là điểm yếu thật nên chủ động nhận: `Orders.tableName` lưu **tên bàn dạng chuỗi**, không có khóa ngoại tới `Tables`. Đổi tên bàn thì đơn cũ vẫn giữ tên cũ. Đúng ra nên là `tableId INT REFERENCES dbo.Tables(id)`.

**"Mất điện giữa lúc đang cập nhật thì sao?"**

→ Các nghiệp vụ ghi nhiều bảng đều nằm trong **transaction**. Ví dụ chuyển `Preparing → Ready` gồm: trừ cốc, trừ kho, đổi trạng thái, ghi log — hoặc thành công tất cả, hoặc không gì cả. Không có trạng thái nửa vời.

**"Khách quét QR bàn 3 rồi đi sang bàn 8 quét tiếp thì sao?"**

→ Hệ thống phát hiện quét bàn khác và **xóa tiến trình cũ** — `resetGuestProgress()` xóa cả bàn đã khóa lẫn danh sách đơn của phiên — rồi khóa theo bàn mới. Phiên đó **mất hẳn** liên kết tới đơn ở bàn cũ.

Cơ chế "ưu tiên bàn đang có đơn" chỉ áp dụng ở **nhánh khác**: khi khách gửi đơn mà **không kèm `tableCode`** (bấm đặt lại từ tab cũ). Hai nhánh này loại trừ nhau trong `createGuestOrder()`.

---

# PHẦN G — ĐIỂM YẾU NGHIỆP VỤ NÊN CHỦ ĐỘNG NHẬN

| # | Hạn chế | Câu nói gọn |
|---|---|---|
| 1 | Đăng nhập theo vai trò, không theo người | "Không truy vết được ai làm ca nào" |
| 2 | Không có đặt bàn trước | "Chỉ phục vụ khách đến trực tiếp" |
| 3 | Chỉ tiền mặt | "Chưa có thanh toán chuyển khoản hay ví điện tử" |
| 4 | Không hủy đơn được | "Đơn đã tạo chỉ đi tới, không có trạng thái Cancelled" |
| 5 | Không có chương trình khuyến mãi | "Chưa có giảm giá, tích điểm, khách thân thiết" |
| 6 | Polling 5 giây | "Tốn tài nguyên, nên chuyển sang WebSocket" |
| 7 | Đổi tên bàn làm mất liên kết đơn cũ | "Nối bằng tên chuỗi thay vì khóa ngoại" |
| 8 | Cờ `splitLocked` ghi mà không dùng | "Em có cột đánh dấu nhưng chưa kiểm tra nó — đơn gốc vẫn tách tiếp được" |
| 9 | Món hết nguyên liệu không tự bật lại | "Hệ thống chỉ tự tắt, bật lại phải làm thủ công" |

**Cách nói cho có lợi:** "Đây là những nghiệp vụ em đã xác định phạm vi từ đầu là chưa làm, không phải bỏ sót. Nếu mở rộng thì em ưu tiên theo thứ tự: hủy đơn, thanh toán điện tử, rồi tài khoản theo từng nhân viên."

---

# PHẦN H — ĐIỂM MẠNH NGHIỆP VỤ NÊN KHOE

| # | Điểm mạnh |
|---|---|
| 1 | **Trừ kho tự động theo công thức** — không phải nhập tay, và tính đúng theo số lượng |
| 2 | **Tách "giữ chỗ" và "trừ thật"** — đơn chưa pha vẫn được tính vào khả năng phục vụ |
| 3 | **Tự tắt món hết nguyên liệu** — khách không đặt được món quán không làm được |
| 4 | **Quản lý số cốc** — ràng buộc vật lý ít ai nghĩ tới |
| 5 | **Chống đặt trùng 5 giây** — chặn double-click mà không chặn khách gọi thêm |
| 6 | **Tách hóa đơn** — giải quyết bài toán thật của khách đi nhóm |
| 7 | **Đối soát tiền mặt có ghi chênh lệch** — không tự sửa số liệu, giữ dấu vết |
| 8 | **Ẩn giá với bồi bàn ở tầng server** — phân tách trách nhiệm thật, không phải ẩn giao diện |
| 9 | **Nhật ký song ngữ đầy đủ** — mọi thao tác đều truy vết được ai, lúc nào |
