<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=order-confirm-1">
    <script defer src="assets/js/i18n.js?v=tab-session-2"></script>
</head>
<body>
    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell work-shell">
        <section class="work-toolbar action-toolbar">
            <a class="btn primary" href="counter-order.jsp" data-i18n="counterOrder">Gọi món tại quầy</a>
            <a class="btn" href="table-transfer.jsp" data-i18n="transferTable">Đổi bàn</a>
        </section>
        <section class="cash-strip" id="cash-panel"></section>
        <section class="work-tabs two-tabs" id="cashier-tabs"></section>
        <section class="order-list" id="cashier-orders"></section>
    </main>

    <div class="overlay" id="split-overlay" onclick="closeSplit()"></div>
    <aside class="sheet" id="split-sheet" aria-hidden="true">
        <div class="sheet-in">
            <div class="sheet-grip"></div>
            <h3 data-i18n="splitTitle">Tách hóa đơn</h3>
            <p class="muted" data-i18n="splitHint">Chọn số lượng mỗi món để tách sang hóa đơn mới.</p>
            <div id="split-rows"></div>
            <div id="split-message" class="notice hidden"></div>
            <div class="links" style="margin-top:14px">
                <button class="btn" type="button" onclick="closeSplit()" data-i18n="cancel">Huỷ</button>
                <button class="btn primary" type="button" onclick="confirmSplit()" data-i18n="splitConfirm">Xác nhận tách</button>
            </div>
        </div>
    </aside>

    <script src="assets/js/page-cashier.js?v=split-bill-1"></script>
</body>
</html>
