# Vấn đáp NGHIỆP VỤ — Vai trò BỒI BÀN (runner/waiter)

Tài liệu tập trung vào **bài toán thực tế** của bồi bàn, không phải code. Mọi chi tiết đã đối chiếu với source.

---

# PHẦN A — TỔNG QUAN

## A1. ⭐ "Bồi bàn trong hệ thống của em làm gì?"

**Trả lời mẫu — 30 giây:**

"Bồi bàn là **cầu nối giữa quầy pha chế và khách**. Anh ta không nhận order (khách tự quét QR), không thu tiền (thu ngân làm), mà chỉ lo hai đầu của quy trình phục vụ:

- **Đầu vào:** món pha xong thì in hóa đơn, bưng ra bàn cho khách
- **Đầu ra:** khách trả tiền xong thì dọn bàn để đón khách mới

Ngoài ra có thể đổi bàn cho khách và in lại hóa đơn khi khách làm mất."

**Vị trí trong luồng — nhớ hai mũi tên:**

```
Pending ──barista──► Preparing ──barista──► Ready ──BỒI BÀN──► Served ──thu ngân──► Paid ──BỒI BÀN──► Cleared
                                                    ↑ bưng món ra                          ↑ dọn bàn
```

Bồi bàn chạm vào **hai** chặng, ở hai đầu đối diện của quy trình thanh toán.

## A2. "Vì sao cần vai trò bồi bàn riêng?"

Ba lý do nghiệp vụ:

1. **Pha chế không rời quầy được** — đang pha dở mà bưng món ra thì hỏng cả dây chuyền
2. **Thu ngân phải ở quầy thu tiền** — không thể bỏ két đi dọn bàn
3. **Bồi bàn là người duy nhất di chuyển trong quán** — nên gộp luôn việc dọn bàn và đổi bàn

Đây cũng là lý do màn hình bồi bàn được thiết kế cho **điện thoại**: anh ta cầm máy đi lại, không ngồi trước màn hình như hai vai trò kia.

---

# PHẦN B — MÀN HÌNH BỒI BÀN

## B1. "Bồi bàn nhìn thấy gì?"

**Bốn khu**, từ trên xuống:

| Khu | Nội dung |
|---|---|
| **Thanh nút "Đổi bàn"** | Link sang `table-transfer.jsp` — đây là lối vào chức năng đổi bàn |
| **Hai tab** | "Phục vụ" (**số đơn** cần bưng — một đơn 5 ly vẫn đếm là 1) và "Chờ dọn" (số bàn cần dọn) |
| **Khu làm việc** | Danh sách card theo tab đang chọn |
| **Sơ đồ bàn** | Toàn bộ bàn của quán, chia theo tầng, tô màu theo trạng thái |

Tab "Phục vụ" còn có thêm khu **"In lại hóa đơn"** ở dưới — chứa các đơn đã bưng ra rồi, giữ lại phòng khi khách xin in lại.

## B2. "Bồi bàn thấy được những trạng thái nào?"

Chỉ **ba trong sáu** trạng thái:

| Trạng thái | Ý nghĩa với bồi bàn | Hiện ở đâu |
|---|---|---|
| `Ready` | Món pha xong, **cần bưng ra ngay** | Tab "Phục vụ" |
| `Served` | Đã bưng rồi, giữ để in lại hóa đơn | Khu "In lại hóa đơn" |
| `Paid` | Khách đã trả tiền, **bàn cần dọn** | Tab "Chờ dọn" |

Ba trạng thái còn lại bị lọc ngay từ câu SQL: `Pending`, `Preparing` là việc của pha chế; `Cleared` là đã xong.

**Ý nghĩa nghiệp vụ:** bồi bàn chỉ thấy **việc phải làm**, không bị nhiễu bởi đơn đang pha hay đơn đã kết thúc.

## B3. "Màn hình tự cập nhật thế nào?"

Polling **5 giây một lần**. Khi có việc mới xuất hiện, hệ thống phát **chuông + toast** "Có việc mới cho bồi bàn".

Cơ chế nhận biết "mới": lưu tập ID đã thấy ở vòng trước, so với tập hiện tại, có ID nào chưa từng thấy thì mới kêu. Nhờ vậy không kêu lại cho những việc bồi bàn đã biết.

Cờ `silent` chỉ tắt **thông báo việc mới**, không tắt âm thanh — `notifyWork()` luôn gọi `playDing()`. Cụ thể:

| Thao tác | Có kêu không |
|---|---|
| Phục vụ món xong | im hoàn toàn |
| Đổi tab | im hoàn toàn |
| Dọn bàn xong | **có** — toast "Bàn đã sẵn sàng" kèm ding |
| Việc mới từ bên ngoài | **có** — toast "Có việc mới cho bồi bàn" kèm ding |

Cần phân biệt hai loại ding: **xác nhận thao tác của mình** và **báo việc mới**. Chỉ loại thứ hai mới bị `silent` chặn.

---

# PHẦN C — BỐN NGHIỆP VỤ CHI TIẾT

## C1. ⭐⭐ "Quy trình bưng món ra bàn"

**Đây là nghiệp vụ chính, nên chuẩn bị kỹ nhất.**

```
1. Pha chế xong → đơn chuyển Ready → chuông kêu ở máy bồi bàn
2. Bấm "IN HÓA ĐƠN" trên card → hiện **hộp xem trước hóa đơn** kèm câu hướng dẫn
3. Bấm "In hóa đơn" **lần nữa** trong hộp thoại → trình duyệt mở hộp in → ra giấy
4. Bồi bàn bưng món + kèm hóa đơn ra bàn khách
5. Nhấn giữ card 0.5 giây → đơn chuyển Served
```

**Vì sao phải in hóa đơn trước khi bưng ra** — đây là chỗ ăn điểm. Hóa đơn đóng vai trò **"vé thanh toán"**. Câu hướng dẫn hiện ngay trên màn hình:

> "Đưa hóa đơn này kèm món cho khách. Khi thanh toán, khách đưa hóa đơn cho thu ngân."

Quán không có POS ở bàn, nên khách phải cầm hóa đơn ra quầy. Không có hóa đơn thì thu ngân không biết thu tiền đơn nào.

**Hệ thống nhắc nếu quên in.** Nhấn giữ card mà đơn chưa in hóa đơn, một hộp thoại hiện lên:

> **Chưa in hóa đơn**
> Đơn này chưa in hóa đơn. Vẫn xác nhận đã phục vụ?
> [Huỷ] [Vẫn phục vụ]

Đây là **cảnh báo, không phải chặn** — vì có trường hợp máy in hỏng, khách quen trả sau, hoặc bồi bàn đã in từ trước ở máy khác.

## C2. "Hóa đơn có những gì?"

| Mục | Nội dung |
|---|---|
| Tên quán | coffeshop |
| Bàn | Tầng 1 - Bàn 3 |
| Số đơn | #1421 |
| Giờ | thời điểm khách đặt |
| Ghi chú | nếu khách có yêu cầu riêng |
| Danh sách món | tên, size, số lượng, **thành tiền từng dòng** |
| Tổng cộng | tổng tiền |

⚠️ **Chỗ này phải nói cẩn thận.** Nếu bạn tuyên bố "bồi bàn hoàn toàn không thấy giá tiền", thầy cô mở hóa đơn ra là bắt được ngay.

**Sự thật:** endpoint `/orders/invoice` **không** gọi `sanitizeRunnerOrder`, và `getOrderInvoice()` chỉ xóa `customerPhone`:

```java
public Map<String, Object> getOrderInvoice(int id) throws Exception {
    Map<String, Object> order = getOrderById(id);
    if (order == null) return null;
    order.remove("customerPhone");     // chỉ xóa SĐT, GIỮ giá tiền
    return order;
}
```

**Cách trả lời đúng:**

> "Bồi bàn không thấy giá **trên danh sách công việc** — server xóa `total` và `price` khỏi response của `/orders?view=runner`. Nhưng **hóa đơn thì phải có giá**, vì đó là tờ giấy đưa cho khách. Nên `/orders/invoice` là endpoint riêng, không bị lọc giá.
>
> Nói cách khác, em ẩn giá ở chỗ bồi bàn **không cần biết** (lướt danh sách công việc), và giữ giá ở chỗ **nghiệp vụ bắt buộc** (tờ hóa đơn)."

Đây là câu trả lời tốt vì nó cho thấy bạn hiểu **vì sao** ẩn, chứ không ẩn máy móc.

## C3. ⭐ "Quy trình dọn bàn"

```
1. Thu ngân thu tiền xong → đơn chuyển Paid → chuông kêu ở máy bồi bàn
2. Card bàn xuất hiện ở tab "Chờ dọn"
3. Khách rời đi, bồi bàn dọn bàn thật
4. Nhấn giữ card 0.5 giây → mọi đơn Paid của bàn chuyển Cleared
5. Toast "Bàn đã sẵn sàng", ô bàn trên sơ đồ đổi thành "Sẵn sàng"
```

**Ba điểm nghiệp vụ đáng nói:**

**a. Dọn theo BÀN, không theo đơn.** Một bàn có thể có nhiều đơn (khách gọi thêm nhiều lần, hoặc tách hóa đơn). Bồi bàn dọn bàn một lần là xong tất cả:

```sql
UPDATE dbo.Orders SET status='Cleared' WHERE tableName=? AND status='Paid'
```

Điều này khớp với thực tế — bồi bàn lau bàn, dọn ly chén, chứ không "dọn từng hóa đơn".

**b. Không dọn được bàn còn khách.** Hệ thống đếm đơn ở `Pending`/`Preparing`/`Ready`/`Served`, còn dòng nào là từ chối:

> "Bàn vẫn còn đơn đang phục vụ, chưa thể dọn."

Tình huống thật: khách ngồi bàn 5 đã trả tiền phần 1, nhưng vừa gọi thêm ly nữa. Bồi bàn không được dọn.

**c. Hai bồi bàn cùng dọn một bàn.** Người thứ hai nhận:

> "Bàn này vừa được cập nhật bởi thiết bị khác."

## C4. "Quy trình đổi bàn"

Khách đang ngồi bàn 3, muốn chuyển sang bàn 8 rộng hơn — nhưng đã gọi món rồi.

Bồi bàn vào trang "Đổi bàn", chọn bàn nguồn và bàn đích. **Tất cả đơn đang hoạt động** được chuyển sang bàn mới.

**Năm điều kiện:**

| Điều kiện | Thông báo khi vi phạm |
|---|---|
| Hai bàn phải khác nhau | "Bàn mới phải khác bàn hiện tại." |
| Cả hai bàn tồn tại | "Không tìm thấy bàn." |
| Cả hai bàn chưa bị ẩn | "Bàn đã ẩn không thể đổi." |
| Bàn nguồn **có** đơn | "Bàn hiện tại không có đơn cần chuyển." |
| Bàn đích **trống** | "Bàn mới đang có khách." |

**Chi tiết tinh tế nên nêu:** khi kiểm tra bàn đích, danh sách trạng thái **có thêm `'Paid'`** — bàn còn đơn đã trả tiền nhưng chưa dọn thì cũng không nhận khách mới. Còn bàn nguồn thì không xét `Paid`.

Lý do: bàn đích chưa dọn nghĩa là còn ly chén trên đó, không thể chuyển khách sang.

⚠️ **Lưu ý:** đổi bàn **không phải việc riêng của bồi bàn** — `SecurityFilter` cho cả `cashier` gọi `/api/tables/transfer`.

## C5. "In lại hóa đơn dùng khi nào?"

Khách làm mất hóa đơn, hoặc hóa đơn bị ướt/rách, hoặc khách muốn thêm một bản.

Các đơn `Served` (đã bưng ra, chưa thanh toán) được giữ trong khu riêng ở cuối tab "Phục vụ", viền **đứt nét** để phân biệt với việc cần làm:

> "Đơn đã phục vụ nhưng có thể in lại hóa đơn cho khách."

**Vì sao chỉ giữ đơn `Served`:** đơn `Paid` đã thanh toán xong rồi, in lại không còn ý nghĩa. Điều kiện ở server:

```java
if (!"Ready".equals(status) && !"Served".equals(status)) {
    error(resp, SC_FORBIDDEN, "Chỉ in được hóa đơn đơn đang phục vụ.");
}
```

---

# PHẦN D — VÌ SAO THIẾT KẾ THẾ

## D1. ⭐ "Vì sao bồi bàn phải nhấn giữ 0.5 giây thay vì bấm nút?"

Ba lý do:

1. **Thao tác không hoàn tác được** — đã chuyển `Served` thì không lùi lại `Ready`, đã dọn bàn thì không "chưa dọn" lại
2. **Dùng trên điện thoại, vừa đi vừa bấm** — chạm nhầm rất dễ
3. **Card to, chiếm nửa màn hình** — nếu bấm một cái là xong thì đụng đâu cũng trúng

Nhấn giữ 0.5 giây buộc phải có chủ đích. Có dải màu chạy đầy card làm phản hồi thị giác, nhả tay giữa chừng thì hủy.

**Đừng nói nhấn giữ là đặc quyền của bồi bàn** — dễ bị vặn. Hệ thống dùng nó cho **mọi thao tác không hoàn tác được trên thiết bị cầm tay**, với hai thời lượng:

| Nơi dùng | Thời lượng |
|---|---|
| Card bồi bàn (phục vụ, dọn bàn) | 0.5 giây |
| Card pha chế (`page-staff-orders.js`) | 0.5 giây |
| Nút khách xác nhận đặt món (`page-menu.js`) | **1 giây** |

Khách phải giữ lâu hơn vì đặt món là hành động tạo dữ liệu mới, và khách không quen giao diện.

## D2. "Vì sao bồi bàn chỉ chuyển được đúng một bước trạng thái?"

`canSetStatus` cho bồi bàn **duy nhất** bước `Ready → Served`. Ý nghĩa nghiệp vụ:

- Không được **nhảy cóc**: bồi bàn không tự thanh toán đơn (`Ready → Paid`) — đó là việc của thu ngân, và liên quan tới tiền
- Không được **đi lùi**: đã bưng ra rồi thì không "chưa bưng" lại được
- Không được **làm hộ pha chế**: không đánh dấu món đã pha xong

Đây là **phân tách trách nhiệm** — mỗi người chỉ làm được đúng phần việc của mình, kể cả khi cố tình.

## D3. "Vì sao ẩn giá trên danh sách công việc?"

Ba lý do:

1. **Bồi bàn không cần biết** — việc của anh ta là bưng đúng món ra đúng bàn
2. **Giảm rủi ro** — không biết giá thì khó thỏa thuận riêng với khách
3. **Bảo vệ thông tin khách** — `customerPhone` cũng bị xóa

Và làm ở **server**, không phải ẩn bằng CSS:

```java
private void sanitizeRunnerOrder(Map<String, Object> order) {
    order.remove("total");
    order.remove("customerPhone");
    for (...) ((Map<String, Object>) raw).remove("price");
}
```

Ẩn bằng CSS thì mở DevTools là thấy — vô nghĩa về bảo mật.

## D4. "Vì sao có sơ đồ bàn ở cuối màn hình?"

Hai tab phía trên chỉ cho thấy **việc phải làm**. Sơ đồ bàn cho thấy **toàn cảnh quán**:

- Bàn nào đang trống để hướng dẫn khách mới vào
- Bàn nào đang phục vụ
- Tổng số bàn đang có khách (tiêu đề "Đang phục vụ: 6")

Ô bàn tô màu theo trạng thái: `Paid` → "Chờ dọn", `Served` → "Chưa thanh toán", `Ready` → "Phục vụ", còn lại → "Sẵn sàng".

---

# PHẦN E — CÂU HỎI TÌNH HUỐNG

**"Hai bồi bàn cùng bấm phục vụ một món?"**

→ Người thứ hai bị chặn. Bước hợp lệ duy nhất là `Ready → Served`, mà đơn đã ở `Served` rồi nên `canSetStatus` trả `false` → **403**.

**"Bồi bàn bưng nhầm món ra bàn khác?"**

→ Hệ thống **không phát hiện được**. Đây là hạn chế thật — phần mềm chỉ ghi nhận trạng thái, không biết món thực tế đi đâu. Card có hiện rõ tên bàn ở đầu để giảm nhầm lẫn, nhưng đó là biện pháp giao diện chứ không phải ràng buộc.

**"Khách đòi hủy món sau khi bồi bàn đã bưng ra?"**

→ Hệ thống **chưa hỗ trợ**. Không có trạng thái `Cancelled`, không có API xóa đơn. Nên chủ động nhận là phạm vi chưa làm.

**"Bồi bàn dọn bàn nhưng khách vẫn ngồi đó?"**

→ Nếu khách đã trả tiền hết (mọi đơn ở `Paid`) thì hệ thống **cho dọn** — nó không biết khách còn ngồi hay không. Ngược lại nếu còn đơn chưa thanh toán thì bị chặn.

**"Bồi bàn đang nhấn giữ card thì đúng lúc màn hình tự cập nhật?"**

→ Đây là **bug thật**, nên thừa nhận. `renderWork()` thay toàn bộ `innerHTML` nên card đang giữ bị hủy, sự kiện `pointerup` không bắn nữa, `cancelHold()` không được gọi — nhưng `setTimeout` vẫn sống và **vẫn serve món dù bồi bàn đã nhả tay**. Cách sửa: tạm dừng polling khi đang giữ card.

**"Máy in hỏng thì sao?"**

→ Vẫn phục vụ được — hệ thống chỉ **cảnh báo** chứ không chặn. Bồi bàn bấm "Vẫn phục vụ". Nhưng khách sẽ không có hóa đơn cầm ra quầy, thu ngân phải tra đơn theo số bàn.

**"Bồi bàn bấm in rồi bấm Hủy trong hộp thoại in thì sao?"**

→ ⚠️ Hệ thống **vẫn đánh dấu là đã in**. Code lắng nghe sự kiện `afterprint`, mà sự kiện này bắn cả khi người dùng hủy:

```js
const onAfterPrint = () => {
    window.removeEventListener('afterprint', onAfterPrint);
    markInvoicePrinted(orderId);
};
window.addEventListener('afterprint', onAfterPrint);
window.print();
```

Trình duyệt không cho biết người dùng thực sự in hay hủy. Đây là hạn chế kỹ thuật của web, nên nói thẳng nếu bị hỏi.

---

# PHẦN F — ĐIỂM YẾU NÊN CHỦ ĐỘNG NHẬN

| # | Hạn chế | Câu nói gọn |
|---|---|---|
| 1 | Không phát hiện bưng nhầm bàn | "Phần mềm chỉ ghi trạng thái, không biết món đi đâu thật" |
| 2 | Không hủy được đơn đã bưng | "Chưa có trạng thái Cancelled" |
| 3 | `afterprint` bắn cả khi hủy in | "Trình duyệt không phân biệt được, là hạn chế của web" |
| 4 | Polling làm mất thao tác nhấn giữ | "Card bị thay giữa lúc đang giữ — cần tạm dừng polling" |
| 5 | Không biết bàn còn khách ngồi hay không | "Chỉ dựa vào trạng thái đơn, không có cảm biến" |
| 6 | Không có phân công bàn cho từng bồi bàn | "Mọi bồi bàn thấy chung một danh sách, dễ giẫm chân nhau" |
| 7 | Việc mới rơi vào lần refresh im lặng thì **mất chuông vĩnh viễn** | "`maybeNotify` cập nhật mốc ghi nhớ kể cả khi `silent`, nên vòng sau nó không còn là mới" |

**Điểm 6 là câu trả lời tốt nếu bị hỏi "quán đông nhiều bồi bàn thì sao":** hiện tại ai nhanh tay thì làm, hệ thống chỉ chống được việc hai người cùng bấm chứ chưa chia việc. Mở rộng thì thêm cột phân công khu vực cho từng người.

# PHẦN G — ĐIỂM MẠNH NÊN KHOE

| # | Điểm mạnh |
|---|---|
| 1 | **Nhấn giữ 0.5s** — chống chạm nhầm, phù hợp thao tác trên điện thoại khi đang di chuyển |
| 2 | **Chỉ hiện việc phải làm** — lọc còn 3/6 trạng thái, không nhiễu |
| 3 | **Chuông chỉ kêu cho việc mới từ bên ngoài** — không kêu lại việc đã biết, không kêu cho thao tác của chính mình |
| 4 | **Ẩn giá ở danh sách nhưng giữ trên hóa đơn** — ẩn đúng chỗ theo nhu cầu nghiệp vụ |
| 5 | **Dọn theo bàn, không theo đơn** — khớp với thao tác thực tế |
| 6 | **Cảnh báo chưa in hóa đơn** — nhắc chứ không chặn, để xử lý được trường hợp ngoại lệ |
| 7 | **Chống hai người cùng thao tác** — `UPDLOCK` khi đọc, kiểm tra số dòng bị ảnh hưởng khi ghi |
| 8 | **Mọi thao tác đều vào nhật ký** — `ORDER_STATUS`, `TABLE_CLEAR`, `TABLE_TRANSFER` ghi rõ ai làm, lúc nào |
