<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String pageTitle = "Menu — nhà cà phê";
    String activeNav = "menu";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/customer-topbar.jsp" %>

    <main class="wrap">
        <% if (table == null) { %>
        <div class="notice">
            <span>!</span>
            <span>Bạn chưa quét mã QR tại bàn. Hãy quét mã QR dán trên bàn của bạn để hệ thống biết
                  bàn cần phục vụ — bạn vẫn có thể xem menu và thêm món trước.</span>
        </div>
        <% } %>

        <div class="search-row">
            <div class="search-box">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
                <input class="field" id="searchInput" type="search" placeholder="Tìm món, ví dụ: cà phê sữa..." autocomplete="off">
            </div>
        </div>

        <div class="chips" id="chips"></div>

        <div class="menu-grid" id="menuGrid">
            <div class="skel" style="aspect-ratio:4/5"></div>
            <div class="skel" style="aspect-ratio:4/5"></div>
            <div class="skel" style="aspect-ratio:4/5"></div>
            <div class="skel" style="aspect-ratio:4/5"></div>
        </div>
    </main>

    <!-- thanh giỏ hàng -->
    <div class="cart-bar" id="cartBar">
        <div class="cart-bar-in" onclick="location.href='<%=ctx%>/order-summary.jsp'">
            <span class="cart-count">0</span>
            <span class="cart-bar-label">Xem giỏ hàng</span>
            <span class="cart-bar-total">0&#273;</span>
        </div>
    </div>

    <!-- sheet thêm món -->
    <div class="overlay" id="sheetOverlay"></div>
    <div class="sheet" id="dishSheet">
        <div class="sheet-in">
            <div class="sheet-grip"></div>
            <h3 id="shName">Tên món</h3>
            <div class="price" id="shPrice">0&#273;</div>

            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
                <span class="label label-dark">Số lượng</span>
                <div class="stepper">
                    <button type="button" id="shMinus">−</button>
                    <span class="num" id="shQty">1</span>
                    <button type="button" id="shPlus">+</button>
                </div>
            </div>

            <label class="label label-dark" for="shNote" style="display:block;margin-bottom:6px">Ghi chú cho quán</label>
            <textarea class="field" id="shNote" maxlength="200"
                      placeholder="Ví dụ: ít đường, ít đá, không kem, làm nóng..."></textarea>

            <button class="btn btn-primary btn-big btn-block" id="shAdd" style="margin-top:16px">
                Thêm vào giỏ — <span id="shTotal">0&#273;</span>
            </button>
        </div>
    </div>

    <script src="<%=ctx%>/assets/js/app.js"></script>
    <script>
    (function () {
        var C = window.CSMS;
        var state = { products: [], categories: [], filter: 0, search: '' };
        var current = null, currentQty = 1;

        /* bỏ dấu tiếng Việt để tìm kiếm dễ hơn */
        function fold(s) {
            return (s || '').toLowerCase().normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '').replace(/\u0111/g, 'd');
        }

        function load() {
            C.apiGet('/api/products').then(function (data) {
                if (!data.ok) return;
                state.products = data.products;
                state.categories = data.categories;
                renderChips();
                renderGrid();
            }).catch(function () {
                document.getElementById('menuGrid').innerHTML =
                    '<div class="empty-state" style="grid-column:1/-1"><div class="big">☕</div>' +
                    '<h3>Không tải được menu</h3><p>Vui lòng kiểm tra kết nối rồi thử lại.</p></div>';
            });
        }

        function renderChips() {
            var html = '<button class="chip' + (state.filter === 0 ? ' active' : '') + '" data-cat="0">Tất cả</button>';
            state.categories.forEach(function (c) {
                html += '<button class="chip' + (state.filter === c.categoryId ? ' active' : '') + '" data-cat="'
                    + c.categoryId + '">' + C.escapeHtml(c.categoryName) + '</button>';
            });
            var box = document.getElementById('chips');
            box.innerHTML = html;
            box.querySelectorAll('.chip').forEach(function (b) {
                b.onclick = function () {
                    state.filter = parseInt(b.dataset.cat, 10);
                    renderChips();
                    renderGrid();
                };
            });
        }

        function dishCard(p, idx) {
            var img = p.image
                ? '<img src="' + C.escapeHtml(p.image) + '" alt="" loading="lazy">'
                : '<span class="initial">' + C.escapeHtml((p.name || '?').charAt(0)) + '</span>';
            return '<article class="dish' + (p.available ? '' : ' soldout') + '" data-idx="' + idx + '">'
                + (p.available ? '' : '<span class="soldout-tag">Hết món</span>')
                + '<div class="dish-img">' + img + '</div>'
                + '<div class="dish-body">'
                + '<div class="dish-name">' + C.escapeHtml(p.name) + '</div>'
                + '<div class="dish-foot"><span class="dish-price">' + C.money(p.price) + '</span>'
                + (p.available ? '<button class="dish-add" aria-label="Thêm">+</button>' : '')
                + '</div></div></article>';
        }

        function renderGrid() {
            var q = fold(state.search);
            var list = state.products.filter(function (p) {
                if (state.filter !== 0 && p.categoryId !== state.filter) return false;
                if (q && fold(p.name).indexOf(q) === -1) return false;
                return true;
            });

            var grid = document.getElementById('menuGrid');
            if (list.length === 0) {
                grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1"><div class="big">🔍</div>'
                    + '<h3>Không thấy món nào</h3><p>Thử từ khóa khác xem sao.</p></div>';
                return;
            }

            var html = '', lastCat = null;
            var grouped = state.filter === 0 && !q;
            list.forEach(function (p) {
                if (grouped && p.categoryName !== lastCat) {
                    lastCat = p.categoryName;
                    html += '<div class="cat-head"><h2>' + C.escapeHtml(p.categoryName) + '</h2><span class="line"></span></div>';
                }
                html += dishCard(p, state.products.indexOf(p));
            });
            grid.innerHTML = html;

            grid.querySelectorAll('.dish:not(.soldout)').forEach(function (el) {
                el.onclick = function () { openSheet(state.products[parseInt(el.dataset.idx, 10)]); };
            });
        }

        /* ---------- sheet ---------- */
        var sheet = document.getElementById('dishSheet');
        var overlay = document.getElementById('sheetOverlay');

        function openSheet(p) {
            current = p;
            currentQty = 1;
            document.getElementById('shName').textContent = p.name;
            document.getElementById('shPrice').textContent = C.money(p.price);
            document.getElementById('shNote').value = '';
            syncSheet();
            sheet.classList.add('show');
            overlay.classList.add('show');
        }

        function closeSheet() {
            sheet.classList.remove('show');
            overlay.classList.remove('show');
        }

        function syncSheet() {
            document.getElementById('shQty').textContent = currentQty;
            document.getElementById('shMinus').disabled = currentQty <= 1;
            document.getElementById('shTotal').textContent = C.money(current ? current.price * currentQty : 0);
        }

        overlay.onclick = closeSheet;
        document.getElementById('shMinus').onclick = function () { if (currentQty > 1) { currentQty--; syncSheet(); } };
        document.getElementById('shPlus').onclick = function () { if (currentQty < 20) { currentQty++; syncSheet(); } };
        document.getElementById('shAdd').onclick = function () {
            if (!current) return;
            C.Cart.add(current.productId, current.name, current.price, currentQty, document.getElementById('shNote').value);
            closeSheet();
            C.toast('Đã thêm ' + currentQty + ' × ' + current.name);
        };

        /* ---------- search ---------- */
        var deb = null;
        document.getElementById('searchInput').addEventListener('input', function (e) {
            clearTimeout(deb);
            deb = setTimeout(function () {
                state.search = e.target.value.trim();
                renderGrid();
            }, 160);
        });

        if (new URLSearchParams(location.search).get('qr') === 'invalid') {
            C.toast('Mã QR không hợp lệ — vui lòng quét lại mã tại bàn.');
            history.replaceState(null, '', location.pathname);
        }

        load();
    })();
    </script>
</body>
</html>
