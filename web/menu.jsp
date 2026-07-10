<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=vi-serif-1">
    <script defer src="assets/js/i18n.js?v=scroll-top-1"></script>
</head>
<body>
    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell">
        <section class="table-welcome hidden" id="table-welcome">
            <p class="eyebrow" data-i18n="qrWelcomeTitle">Đã nhận bàn</p>
            <h2 id="table-welcome-text"></h2>
        </section>

        <section class="mobile-quick-panel table-picker-panel">
            <label data-i18n="table">Bàn</label>
            <select id="table-select-desktop" onchange="syncTable('desktop')"></select>
            <select id="table-select-mobile" class="hidden" onchange="syncTable('mobile')"></select>
        </section>

        <div class="order-layout">
            <section>
                <div class="search-row">
                    <div class="search-box">
                        <span class="search-mark">⌕</span>
                        <input id="search-input" type="search" data-i18n-placeholder="searchMenu" placeholder="Tìm món, ví dụ: cà phê sữa..." autocomplete="off">
                    </div>
                </div>
                <section class="favorites-section" id="favorites-section" hidden>
                    <div class="cat-head favorites-head">
                        <h2 data-i18n="favoriteItems">Các món được yêu thích nhất</h2>
                        <span class="line"></span>
                    </div>
                    <div class="menu-grid favorites-grid" id="favorites-list"></div>
                </section>
                <div class="chips" id="chips"></div>
                <section class="menu-grid" id="menu-list"></section>
            </section>

            <aside class="card cart-panel" id="cart-panel">
                <h2 data-i18n="cart">Giỏ hàng</h2>
                <div id="cart-list" class="list"></div>
                <div class="cart-total">
                    <span data-i18n="total">Tổng tiền</span>
                    <b class="price" id="cart-total">0 ₫</b>
                </div>
                <div style="margin-top:12px">
                    <label data-i18n="cartNote">Ghi chú cho quán</label>
                    <textarea id="note" rows="3" data-i18n-placeholder="notePlaceholder" placeholder="Ít đá, ít đường, giao trước món nóng..."></textarea>
                </div>
                <button class="btn primary big block" id="submit-order" onclick="submitOrder()" data-i18n="checkout" style="margin-top:16px">Xác nhận gọi món</button>
                <div id="message" class="notice hidden" style="margin-top:12px"></div>
            </aside>
        </div>
    </main>

    <button class="scroll-top-btn" id="scroll-top-btn" type="button" onclick="scrollToTop()" aria-label="Lên đầu trang" title="Lên đầu trang" hidden>
        <span aria-hidden="true">↑</span>
    </button>

    <div class="cart-bar" id="cart-bar">
        <div class="cart-bar-in" onclick="document.getElementById('cart-panel').scrollIntoView({behavior:'smooth', block:'start'})">
            <span class="cart-count" id="cart-count">0</span>
            <span class="cart-bar-label" data-i18n="cartSummary">Xem giỏ hàng</span>
            <span class="cart-bar-total" id="cart-bar-total">0 ₫</span>
        </div>
    </div>

    <div class="overlay" id="sheet-overlay"></div>
    <div class="sheet" id="item-sheet">
        <div class="sheet-in">
            <div class="sheet-grip"></div>
            <p class="eyebrow" id="sheet-category"></p>
            <h3 id="sheet-name">Tên món</h3>
            <p class="price" id="sheet-price">0 ₫</p>
            <div class="size-group hidden" id="sheet-size-group">
                <label data-i18n="size">Size</label>
                <div class="size-options" id="sheet-sizes"></div>
            </div>
            <div style="display:flex;align-items:center;justify-content:space-between;margin:16px 0">
                <span class="eyebrow" data-i18n="quantity" style="margin:0">Số lượng</span>
                <div class="stepper">
                    <button type="button" id="sheet-minus">−</button>
                    <span class="num" id="sheet-qty">1</span>
                    <button type="button" id="sheet-plus">+</button>
                </div>
            </div>
            <label for="sheet-note" data-i18n="note">Ghi chú</label>
            <textarea id="sheet-note" rows="3" data-i18n-placeholder="notePlaceholder" placeholder="Ít đá, ít đường, giao trước món nóng..."></textarea>
            <button class="btn primary big block" id="sheet-add" type="button" style="margin-top:16px">
                <span data-i18n="addToCart">Thêm vào giỏ</span> — <span id="sheet-total">0 ₫</span>
            </button>
        </div>
    </div>
    <script src="assets/js/page-menu.js?v=scroll-top-1"></script>
</body>
</html>
