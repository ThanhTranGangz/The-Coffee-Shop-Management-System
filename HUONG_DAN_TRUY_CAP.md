# Hướng Dẫn Truy Cập Coffeeshop Lite

## Vị trí project và database

- Thư mục source project:
  `/Users/mtsmvp/Downloads/The-Coffee-Shop-Management-System-Lite`

- File cấu hình kết nối database:
  `ConnectDB.properties`

- Tên database SQL Server:
  `CoffeeShopLite`

- File dữ liệu SQL Server trên máy hiện tại:
  `/var/opt/mssql/data/CoffeeShopLite.mdf`

- File log database:
  `/var/opt/mssql/data/CoffeeShopLite_log.ldf`

- App đang deploy trên Tomcat:
  `/opt/homebrew/opt/tomcat@10/libexec/webapps/The-Coffee-Shop-Management-System-Lite`

## Link gốc khi chạy local

```text
http://localhost:8080/The-Coffee-Shop-Management-System-Lite/
```

Nếu mở bằng điện thoại cùng Wi-Fi, đổi `localhost` thành IP của máy đang chạy Tomcat.
Ví dụ:

```text
http://192.168.1.10:8080/The-Coffee-Shop-Management-System-Lite/
```

## Khách gọi món

Khách quét QR trên bàn để vào menu đúng bàn:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-Lite/menu.jsp?tableCode=MA_BAN
```

Trong thực tế không cần tự nhập `tableCode`. Admin vào mục `Bàn & QR` để tải QR riêng của từng bàn. Khi khách quét QR, hệ thống tự nhận bàn và khách không đổi bàn được trong giao diện gọi món.

Nếu cần mở menu thủ công:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-Lite/menu.jsp
```

Trang tra đơn của khách:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-Lite/order-status.jsp
```

## Admin

Admin không có trang login riêng.

Mở trực tiếp dashboard:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-Lite/dashboard.jsp
```

Hệ thống sẽ hiện màn hình che phủ yêu cầu nhập PIN quản trị.

```text
PIN admin: 8888
```

Sau khi mở khoá, admin dùng được các chức năng:

- Dashboard doanh thu.
- Bàn & QR.
- Quản lý thực đơn.
- Xem giao diện pha chế, thu ngân, bồi bàn.
- Gọi món tại quầy.
- Đổi bàn.
- Log hệ thống.

## Nhân viên

Trang đăng nhập nhân viên:

```text
http://localhost:8080/The-Coffee-Shop-Management-System-Lite/staff-login.jsp
```

Chọn đúng vị trí rồi nhập PIN:

| Vai trò | PIN | Trang sau đăng nhập |
| --- | --- | --- |
| Pha chế | `1111` | `staff-orders.jsp` |
| Thu ngân | `2222` | `cashier.jsp` |
| Bồi bàn | `3333` | `runner.jsp` |

Giao diện không hiển thị sẵn PIN. PIN chỉ ghi trong tài liệu này để phục vụ demo.

## Ghi chú khi chạy lại

Nếu Tomcat hoặc SQL Server chưa chạy, mở Terminal và chạy:

```bash
brew services start tomcat@10
brew services start mssql-server
```

Nếu muốn build lại bằng NetBeans, mở đúng thư mục project:

```text
/Users/mtsmvp/Downloads/The-Coffee-Shop-Management-System-Lite
```
