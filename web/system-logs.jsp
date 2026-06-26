<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=hold-05-1">
    <script defer src="assets/js/i18n.js?v=ops-log-1"></script>
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
        <section class="dashboard-top">
            <div>
                <p class="eyebrow" data-i18n="overview">Tổng quan</p>
                <h1 data-i18n="systemLogs">Log hệ thống</h1>
            </div>
            <button class="btn primary" type="button" onclick="loadLogs()" data-i18n="refresh">Làm mới</button>
        </section>
        <section class="work-tabs log-tabs" id="log-tabs"></section>
        <section class="log-list" id="log-list"></section>
    </main>
    <script src="assets/js/page-system-logs.js?v=jsp-clean-1"></script>
</body>
</html>
