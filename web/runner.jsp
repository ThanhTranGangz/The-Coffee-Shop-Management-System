<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=invoice-print-fix-1">
    <script defer src="assets/js/i18n.js?v=invoice-confirm-1"></script>
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
            <a class="btn primary" href="table-transfer.jsp" data-i18n="transferTable">Đổi bàn</a>
        </section>
        <section class="work-tabs two-tabs" id="runner-tabs"></section>
        <section class="runner-work-grid" id="runner-work"></section>
        <section class="card table-map-card" id="runner-table-map"></section>
    </main>

    <div class="invoice-backdrop" id="invoice-backdrop" hidden>
        <div class="invoice-modal" role="dialog" aria-modal="true" aria-labelledby="invoice-title">
            <div class="invoice-modal-head">
                <div>
                    <p class="eyebrow" data-i18n="invoiceTitle">Hóa đơn</p>
                    <h2 id="invoice-title">coffeshop</h2>
                </div>
                <button class="btn" type="button" onclick="closeInvoice()" data-i18n="closeInvoice">Đóng</button>
            </div>
            <p class="invoice-hint" data-i18n="invoiceHint">Đưa hóa đơn này kèm món cho khách. Khi thanh toán, khách đưa hóa đơn cho thu ngân.</p>
            <div class="invoice-sheet" id="invoice-sheet"></div>
            <div class="invoice-actions no-print">
                <button class="btn" type="button" onclick="closeInvoice()" data-i18n="closeInvoice">Đóng</button>
                <button class="btn primary" type="button" onclick="printInvoiceSheet()" data-i18n="printNow">In hóa đơn</button>
            </div>
        </div>
    </div>

    <script src="assets/js/page-runner.js?v=invoice-confirm-1"></script>
</body>
</html>
