<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=order-confirm-1">
    <script defer src="assets/js/i18n.js?v=tab-session-1"></script>
</head>
<body>
    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell work-shell" style="max-width:820px">
        <section class="card hidden" id="manual-card">
            <label for="order-number" data-i18n="enterOrderNumber">Nhập mã đơn của bạn</label>
            <div class="form-row">
                <input id="order-number" placeholder="1001">
                <button class="btn primary" onclick="lookup()" data-i18n="checkOrder">Kiểm tra đơn</button>
            </div>
            <div id="result" style="margin-top:18px"></div>
        </section>
        <section id="table-orders"></section>
    </main>
    <script src="assets/js/page-order-status.js?v=order-confirm-1"></script>
</body>
</html>
