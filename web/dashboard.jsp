<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
        <meta name="page-title-key" content="dashboardTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
</head>
<body>
    <div class="pin-intro admin-pin-gate" id="admin-pin-gate">
        <form class="pin-intro-card admin-pin-card" id="admin-pin-form">
            <p class="eyebrow" data-i18n="adminPinTitle">Mã PIN quản trị</p>
            <p data-i18n="adminPinText">Nhập mã PIN để mở dashboard.</p>
            <input id="admin-pin-input" type="password" inputmode="numeric" pattern="[0-9]*" autocomplete="current-password" required autofocus>
            <button class="btn primary big block" type="submit" data-i18n="unlock">Mở khoá</button>
            <div id="admin-pin-message" class="notice hidden"></div>
        </form>
    </div>

    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell work-shell dashboard-shell">
        <section class="dashboard-top">
            <div>
                <p class="eyebrow" data-i18n="overview">Tổng quan</p>
                <h1 data-i18n="salesDashboard">Kinh doanh</h1>
            </div>
            <button class="btn primary" onclick="loadStats()" data-i18n="refresh">Làm mới</button>
        </section>
        <section class="cash-strip admin-cash-strip" id="cash-panel"></section>
        <section id="low-stock-panel" class="hidden"></section>

        <section class="revenue-dashboard-grid">
            <article class="card revenue-chart-card">
                <div class="toolbar">
                    <div>
                        <p class="eyebrow" data-i18n="revenueTrend">Biến động doanh thu</p>
                        <h2 id="chart-total">0 ₫</h2>
                    </div>
                    <div class="revenue-tabs" id="revenue-tabs"></div>
                </div>
                <div class="custom-range-controls hidden" id="custom-range-controls"></div>
                <div id="chart"></div>
            </article>

            <article class="card dashboard-summary" id="summary"></article>
        </section>
        <section class="card table-map-card" id="table-map"></section>

        <details class="card dashboard-details" id="detail-box">
            <summary data-i18n="details">Chi tiết</summary>
            <div id="details"></div>
        </details>
    </main>
    <script src="assets/js/page-dashboard.js?v=stock-limit-1"></script>
</body>
</html>
