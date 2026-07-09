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
            <button class="stock-chip" id="cup-chip" type="button"></button>
        </section>
        <section class="work-tabs" id="barista-tabs"></section>
        <section class="status-board" id="orders-board"></section>
    </main>
    <script src="assets/js/page-staff-orders.js?v=order-confirm-1"></script>
</body>
</html>
