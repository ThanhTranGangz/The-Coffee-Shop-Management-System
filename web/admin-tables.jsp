<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=order-confirm-1">
    <script defer src="assets/js/i18n.js?v=tab-session-2"></script>
</head>
<body>
    <nav class="nav"><div class="nav-inner"><a class="brand" href="index.html">coffeshop</a><div class="links" id="nav-links"></div><button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button></div></nav>
    <main class="shell work-shell">
        <div class="work-toolbar">
            <button class="btn primary" onclick="resetTableForm()" data-i18n="addTable">Thêm bàn</button>
        </div>

        <section class="card qr-base-card">
            <label for="base-url" data-i18n="qrBaseUrl">Link gốc QR</label>
            <input id="base-url" autocomplete="off">
            <p class="muted" data-i18n="qrBaseHelp">Dùng địa chỉ mà điện thoại khách có thể truy cập, ví dụ IP cùng mạng.</p>
        </section>

        <div class="grid side admin-table-layout">
            <section class="table-admin-grid" id="table-list"></section>
            <aside class="card">
                <h2 id="form-title" data-i18n="tableInfo">Thông tin bàn</h2>
                <form class="grid" onsubmit="saveTable(event)">
                    <input id="id" type="hidden">
                    <div class="form-row">
                        <div><label data-i18n="floorNumber">Tầng</label><input id="floorNo" type="number" min="1" max="10" value="1" required oninput="syncTableName()"></div>
                        <div><label data-i18n="tableNumber">Số bàn</label><input id="tableNo" type="number" min="1" max="99" required oninput="syncTableName()"></div>
                    </div>
                    <div><label data-i18n="tableName">Tên bàn</label><input id="name" required></div>
                    <label><input id="active" type="checkbox" checked style="width:auto"> <span data-i18n="activeTable">Đang dùng</span></label>
                    <button class="btn primary" type="submit" data-i18n="save">Lưu</button>
                    <div id="message" class="notice hidden"></div>
                </form>
            </aside>
        </div>
    </main>
    <script src="assets/js/page-admin-tables.js?v=order-confirm-1"></script>
</body>
</html>
