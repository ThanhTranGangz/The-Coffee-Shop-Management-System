<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
        <meta name="page-title-key" content="transferTableTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
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
            <button class="btn" type="button" onclick="goBackToWork()" data-i18n="backToPrevious">Quay lại</button>
        </section>
        <section class="card transfer-panel" id="transfer-root"></section>
        <section class="card table-map-card" id="transfer-map"></section>
    </main>
    <script src="assets/js/page-table-transfer.js?v=runner-floor-fix-1"></script>
</body>
</html>
