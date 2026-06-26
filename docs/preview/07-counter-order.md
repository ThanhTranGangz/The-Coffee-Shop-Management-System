# Preview Gọi Món Tại Quầy

## 1. Gọi món tại quầy là gì?

Không phải khách nào cũng quét QR. Có khách sẽ gọi trực tiếp với thu ngân ở quầy. Vì vậy hệ thống có chức năng gọi món tại quầy để thu ngân tạo đơn thay cho khách.

Trang:

```text
/counter-order.jsp
```

## 2. Ai được dùng?

Các vai trò được dùng:

- Thu ngân.
- Admin.

Bồi bàn và pha chế không cần chức năng này. Khách cũng không dùng chức năng này vì khách đã có giao diện `menu.jsp`.

## 3. Quy trình thao tác

Thu ngân thực hiện:

1. Chọn bàn.
2. Chọn món.
3. Chọn size nếu món có size.
4. Chọn số lượng.
5. Nhập ghi chú nếu cần.
6. Xác nhận gửi đơn.

Sau đó hệ thống gọi:

```text
POST /api/orders
```

Đơn được tạo với trạng thái:

```text
Pending
```

Từ đây đơn đi vào workflow giống hệt đơn của khách quét QR.

## 4. Vì sao không gộp vào màn hình thu ngân?

Màn hình thu ngân chính chỉ nên tập trung vào thanh toán. Nếu nhét thêm toàn bộ menu gọi món vào đó, giao diện sẽ dài, khó dùng trên điện thoại và dễ bấm nhầm.

Tách riêng giúp mỗi màn hình có một nhiệm vụ rõ:

```text
cashier.jsp         thanh toán
counter-order.jsp   tạo đơn tại quầy
table-transfer.jsp  đổi bàn
```

Đây là nguyên tắc thiết kế giao diện làm việc: mỗi màn hình nên phục vụ một nhóm thao tác chính.

## 5. Ghi chú trong gọi món tại quầy

Ghi chú đơn tại quầy cũng được lưu giống ghi chú từ khách QR. Ghi chú sẽ xuất hiện trong các bước sau:

- Pha chế.
- Bồi bàn.
- Thu ngân.

Nhờ đó yêu cầu của khách không bị mất khi đơn đi qua nhiều bộ phận.

## 6. Dữ liệu được lưu ở đâu?

Khi gọi món tại quầy, hệ thống vẫn ghi vào:

- `Orders`.
- `OrderItems`.
- `SystemLogs`.

Không cần tạo bảng riêng cho đơn tại quầy vì về bản chất đó vẫn là một đơn hàng của quán. Cách này giúp báo cáo doanh thu thống nhất.

## 7. Điểm nên trình bày

Gọi món tại quầy là luồng phụ nhưng rất thực tế. Nó chứng minh hệ thống không phụ thuộc hoàn toàn vào QR. Nếu khách không dùng điện thoại, thu ngân vẫn tạo đơn được và đơn vẫn đi qua pha chế, bồi bàn, thanh toán như bình thường.

## 8. Mổ code chức năng gọi món tại quầy

### 8.1. Các file tham gia

| Tầng | File | Vai trò |
| --- | --- | --- |
| JSP | `web/counter-order.jsp` | Khung màn hình gọi món tại quầy |
| JS | `web/assets/js/page-counter-order.js` | Load menu/bàn, tạo giỏ hàng, gửi đơn |
| API | `LiteApiServlet.java` | `/api/menu`, `/api/tables`, `/api/orders` |
| Filter | `SecurityFilter.java` | Chỉ admin/cashier được vào `counter-order.jsp` |
| Service | `LiteService.java` | `getMenu`, `getTables`, `createOrder` |
| DB | `MenuItems`, `MenuItemSizes`, `Tables`, `Orders`, `OrderItems`, `SystemLogs` | Menu, bàn, đơn, log |

### 8.2. Vì sao dùng chung API với khách QR?

Thu ngân gọi món tại quầy vẫn tạo một đơn bình thường của quán. Vì vậy frontend cũng gọi:

```text
POST /api/orders
```

giống khách ở `menu.jsp`.

Điểm khác nhau chỉ nằm ở người thao tác:

- Khách QR thao tác trên `page-menu.js`.
- Thu ngân thao tác trên `page-counter-order.js`.

Backend không cần tạo bảng riêng vì dữ liệu nghiệp vụ giống nhau.

### 8.3. Load dữ liệu

Trong `page-counter-order.js`:

```javascript
loadCounterData()
  -> Promise.all([api('/menu'), api('/tables')])
```

`counterMenu` lưu danh sách món. `counterTables` lưu danh sách bàn. Nếu chưa chọn bàn, hệ thống chọn bàn đầu tiên.

### 8.4. Thêm món vào giỏ

Khi bấm nút món/size:

```javascript
addCounterItem(id, size)
```

Hàm tìm món theo id, chuẩn hóa size rồi thêm vào `counterCart`. Nếu món đó đã có trong giỏ với cùng size thì tăng quantity.

### 8.5. Gửi đơn tại quầy

Khi submit:

```javascript
submitCounterOrder()
```

Frontend gửi:

```json
{
  "tableName": "Tầng 1 - Bàn 1",
  "customerPhone": "",
  "note": "ghi chú",
  "items": [
    { "menuItemId": 1, "size": "M", "quantity": 1 }
  ]
}
```

Backend gọi:

```java
LiteService.createOrder(body)
```

Đơn mới có trạng thái `Pending`, xuất hiện ở màn hình pha chế.

### 8.6. Debug gọi món tại quầy

- Không vào được trang: kiểm tra role cashier/admin trong `SecurityFilter`.
- Không thấy menu: kiểm tra `/api/menu`.
- Không thấy bàn: kiểm tra `/api/tables`.
- Tạo đơn lỗi: kiểm tra `LiteService.createOrder()`.
- Giá sai: kiểm tra `priceFor()` frontend và `priceForSize()` backend; backend mới là giá chính thức.
