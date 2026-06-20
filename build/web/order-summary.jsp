<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String pageTitle = "Giỏ hàng — nhà cà phê";
    String activeNav = "menu";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/customer-topbar.jsp" %>

    <main class="wrap wrap-narrow" style="padding-bottom:130px;margin-top:4px">
        <h1 style="font-size:26px;margin:18px 0 4px">Đơn của bạn</h1>
        <p class="label">Order summary</p>

        <% if (table == null) { %>
        <div class="notice">
            <span>!</span>
            <span>Chưa xác định bàn — vui lòng quét mã QR dán tại bàn trước khi gửi đơn cho quán.</span>
        </div>
        <% } %>

        <!-- danh sách món -->
        <div class="sec"><h2>Món đã chọn</h2><span class="line"></span></div>
        <div class="card card-pad" id="cartBox"></div>
        <div style="margin-top:10px">
            <a class="link-btn" href="<%=ctx%>/menu.jsp">+ Thêm món khác</a>
        </div>

        <div id="orderArea">
            <!-- thành viên -->
            <div class="sec"><h2>Thành viên</h2><span class="line"></span></div>
            <div class="card card-pad" id="memberBox"></div>

            <!-- ưu đãi -->
            <div class="sec"><h2>Ưu đãi</h2><span class="line"></span></div>
            <div class="card card-pad">
                <div class="voucher-row">
                    <input class="field" id="voucherInput" placeholder="NHẬP MÃ ƯU ĐÃI" autocomplete="off">
                    <button class="btn" id="voucherApply">Áp dụng</button>
                </div>
                <div class="voucher-msg" id="voucherMsg"></div>
                <div id="offerList"></div>
            </div>

            <!-- tạm tính -->
            <div class="sec"><h2>Tạm tính</h2><span class="line"></span></div>
            <div class="card card-pad" id="billBox"></div>

            <!-- thanh toán -->
            <div class="sec"><h2>Thanh toán</h2><span class="line"></span></div>
            <label class="pay-opt active" data-method="CASH">
                <input type="radio" name="pay" value="CASH" checked>
                <span>
                    <span class="t">Tại quầy thu ngân</span><br>
                    <span class="d">Gọi món trước, thanh toán tiền mặt hoặc quẹt tại quầy</span>
                </span>
            </label>
            <label class="pay-opt" data-method="VIETQR">
                <input type="radio" name="pay" value="VIETQR">
                <span>
                    <span class="t">Chuyển khoản VietQR</span><br>
                    <span class="d">Quét mã QR ngân hàng, quán xác nhận khi nhận được tiền</span>
                </span>
            </label>

            <button class="btn btn-primary btn-big btn-block" id="confirmBtn" style="margin-top:18px">
                Xác nhận &amp; gửi đơn cho quán
            </button>
            <p class="label" style="text-align:center;margin-top:10px">
                Đơn sẽ được chuyển tới quầy pha chế ngay sau khi xác nhận
            </p>
        </div>
    </main>

    <!-- modal sửa ghi chú -->
    <div class="modal" id="noteModal">
        <div class="modal-in">
            <h3>Ghi chú cho món</h3>
            <p id="noteDishName" class="label label-dark" style="margin-bottom:8px"></p>
            <textarea class="field" id="noteInput" maxlength="200"
                      placeholder="Ví dụ: ít đường, ít đá, không kem..."></textarea>
            <div style="display:flex;gap:8px;margin-top:14px">
                <button class="btn btn-ghost" style="flex:1" id="noteCancel">Đóng</button>
                <button class="btn btn-primary" style="flex:1" id="noteSave">Lưu ghi chú</button>
            </div>
        </div>
    </div>

    <%@ include file="/includes/auth-modal.jsp" %>

    <script src="<%=ctx%>/assets/js/app.js"></script>
    <script src="<%=ctx%>/assets/js/member.js"></script>
    <script>
    (function () {
        var C = window.CSMS;
        var voucherCode = '';
        var lastQuote = null;
        var member = null;
        var noteIndex = -1;
        var registerMode = false;

        /* ================= giỏ hàng ================= */

        function renderCart() {
            var items = C.Cart.items();
            var box = document.getElementById('cartBox');
            var area = document.getElementById('orderArea');

            if (items.length === 0) {
                box.innerHTML = '<div class="empty-state"><div class="big">🛒</div><h3>Giỏ hàng trống</h3>'
                    + '<p>Quay lại menu để chọn vài món ngon nhé.</p>'
                    + '<a class="btn btn-primary" style="margin-top:14px" href="menu.jsp">Xem menu</a></div>';
                area.style.display = 'none';
                return;
            }
            area.style.display = '';

            var unavailable = {};
            if (lastQuote) {
                lastQuote.lines.forEach(function (l) {
                    if (!l.available) unavailable[l.productId] = true;
                });
            }

            var html = '';
            items.forEach(function (it, i) {
                var dead = unavailable[it.productId];
                html += '<div class="cart-item">'
                    + '<div style="flex:1;min-width:0">'
                    + '<div class="ci-name">' + C.escapeHtml(it.name) + '</div>'
                    + (dead ? '<div class="ci-soldout">Món vừa hết — chạm để bỏ khỏi giỏ</div>' : '')
                    + '<div class="ci-note">'
                    + (it.note ? '“' + C.escapeHtml(it.note) + '” · ' : '')
                    + '<button data-note="' + i + '">' + (it.note ? 'Sửa ghi chú' : '+ Ghi chú (ít đường, ít đá...)') + '</button>'
                    + '</div></div>'
                    + '<div class="ci-right">'
                    + '<span class="ci-price">' + C.money(it.price * it.qty) + '</span>'
                    + (dead
                        ? '<button class="btn btn-ghost btn-sm" data-remove="' + i + '">Bỏ món</button>'
                        : '<div class="stepper small">'
                            + '<button data-minus="' + i + '">−</button>'
                            + '<span class="num">' + it.qty + '</span>'
                            + '<button data-plus="' + i + '">+</button>'
                          + '</div>')
                    + '</div></div>';
            });
            box.innerHTML = html;

            box.querySelectorAll('[data-minus]').forEach(function (b) {
                b.onclick = function () { C.Cart.setQty(+b.dataset.minus, C.Cart.items()[+b.dataset.minus].qty - 1); };
            });
            box.querySelectorAll('[data-plus]').forEach(function (b) {
                b.onclick = function () { C.Cart.setQty(+b.dataset.plus, C.Cart.items()[+b.dataset.plus].qty + 1); };
            });
            box.querySelectorAll('[data-remove]').forEach(function (b) {
                b.onclick = function () { C.Cart.remove(+b.dataset.remove); C.toast('Đã bỏ món khỏi giỏ'); };
            });
            box.querySelectorAll('[data-note]').forEach(function (b) {
                b.onclick = function () { openNote(+b.dataset.note); };
            });
        }

        /* ================= ghi chú ================= */

        var noteModal = document.getElementById('noteModal');

        function openNote(i) {
            var it = C.Cart.items()[i];
            if (!it) return;
            noteIndex = i;
            document.getElementById('noteDishName').textContent = it.qty + ' × ' + it.name;
            document.getElementById('noteInput').value = it.note || '';
            noteModal.classList.add('show');
            document.getElementById('noteInput').focus();
        }

        document.getElementById('noteCancel').onclick = function () { noteModal.classList.remove('show'); };
        document.getElementById('noteSave').onclick = function () {
            C.Cart.setNote(noteIndex, document.getElementById('noteInput').value);
            noteModal.classList.remove('show');
        };

        /* ================= tạm tính ================= */

        var quoteTimer = null;

        function requestQuote() {
            clearTimeout(quoteTimer);
            quoteTimer = setTimeout(doQuote, 220);
        }

        function doQuote() {
            if (C.Cart.count() === 0) { renderCart(); return; }
            C.apiPost('/api/orders/quote', C.Cart.toParams({ voucherCode: voucherCode }))
                .then(function (data) {
                    if (!data.ok) return;
                    lastQuote = data.quote;
                    renderBill();
                    renderCart();
                    renderVoucherMsg();
                });
        }

        function renderBill() {
            var q = lastQuote;
            var box = document.getElementById('billBox');
            if (!q) { box.innerHTML = ''; return; }
            var html = '<div class="bill-row"><span>Tạm tính (' + q.lines.length + ' món)</span><span>' + C.money(q.subtotal) + '</span></div>';
            if (q.memberDiscount > 0) {
                html += '<div class="bill-row discount"><span>Ưu đãi hạng ' + C.escapeHtml(member ? member.tierName : '')
                    + ' (−' + q.memberDiscountPercent + '%)</span><span>−' + C.money(q.memberDiscount) + '</span></div>';
            }
            if (q.voucherValid && q.voucherDiscount > 0) {
                html += '<div class="bill-row discount"><span>Mã ' + C.escapeHtml(q.voucherCode) + '</span><span>−' + C.money(q.voucherDiscount) + '</span></div>';
            }
            html += '<div class="bill-row total"><span>Tổng thanh toán</span><b>' + C.money(q.total) + '</b></div>';
            if (member && q.pointsEarn > 0) {
                html += '<div class="bill-row" style="padding-top:2px"><span>Điểm tích lũy sau thanh toán</span><span>+' + q.pointsEarn + ' điểm</span></div>';
            }
            box.innerHTML = html;
        }

        /* ================= voucher ================= */

        function renderVoucherMsg() {
            var el = document.getElementById('voucherMsg');
            if (!lastQuote || !lastQuote.voucherCode) { el.textContent = ''; el.className = 'voucher-msg'; return; }
            el.textContent = lastQuote.voucherMessage || '';
            el.className = 'voucher-msg ' + (lastQuote.voucherValid ? 'ok' : 'err');
            highlightOffer();
        }

        document.getElementById('voucherApply').onclick = function () {
            voucherCode = document.getElementById('voucherInput').value.trim().toUpperCase();
            doQuote();
        };

        function offerDesc(v) {
            return v.discountPercent != null ? 'Giảm ' + v.discountPercent + '%' : 'Giảm ' + C.money(v.discountAmount);
        }

        function renderOffers(vouchers) {
            var box = document.getElementById('offerList');
            if (!vouchers || vouchers.length === 0) { box.innerHTML = ''; return; }
            var html = '<div class="label" style="margin-top:14px">Ưu đãi dành cho bạn — chạm để áp dụng</div>';
            vouchers.forEach(function (v) {
                html += '<div class="offer" data-code="' + C.escapeHtml(v.code) + '">'
                    + '<div><div class="code">' + C.escapeHtml(v.code) + '</div>'
                    + '<div class="desc">' + offerDesc(v) + ' · HSD ' + C.escapeHtml(v.expiry || '') + '</div></div>'
                    + (v.memberOnly ? '<span class="tag">Thành viên</span>' : '<span class="tag" style="color:var(--good);border-color:var(--good)">Mọi khách</span>')
                    + '</div>';
            });
            box.innerHTML = html;
            box.querySelectorAll('.offer').forEach(function (el) {
                el.onclick = function () {
                    var code = el.dataset.code === voucherCode ? '' : el.dataset.code;
                    voucherCode = code;
                    document.getElementById('voucherInput').value = code;
                    doQuote();
                };
            });
            highlightOffer();
        }

        function highlightOffer() {
            document.querySelectorAll('.offer').forEach(function (el) {
                el.classList.toggle('active',
                    !!voucherCode && el.dataset.code === voucherCode && lastQuote && lastQuote.voucherValid);
            });
        }

        /* ================= thành viên ================= */

        function renderMember() {
            var box = document.getElementById('memberBox');
            if (member) {
                box.innerHTML = '<div class="member-box">'
                    + '<div class="avatar">' + C.escapeHtml((member.fullName || '?').charAt(0)) + '</div>'
                    + '<div style="flex:1;min-width:0">'
                    + '<div style="font-weight:600">' + C.escapeHtml(member.fullName) + '</div>'
                    + '<div class="label" style="margin-top:3px">' + member.points + ' điểm · '
                    + '<span class="tier-chip">' + C.escapeHtml(member.tierName) + '</span>'
                    + (member.tierDiscountPercent > 0 ? ' · luôn giảm ' + member.tierDiscountPercent + '%' : '')
                    + '</div></div>'
                    + '<button class="link-btn" id="logoutBtn">Đăng xuất</button></div>';
                document.getElementById('logoutBtn').onclick = function () {
                    C.apiPost('/api/member/logout').then(function () {
                        member = null;
                        voucherCode = '';
                        document.getElementById('voucherInput').value = '';
                        loadMember();
                        doQuote();
                    });
                };
            } else {
                box.innerHTML = '<div class="member-box">'
                    + '<div class="avatar" style="background:var(--surface-2);color:var(--muted)">?</div>'
                    + '<div style="flex:1"><div style="font-weight:600">Bạn là thành viên?</div>'
                    + '<div class="label" style="margin-top:3px">Đăng nhập để tích điểm &amp; nhận ưu đãi</div></div>'
                    + '<div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end">'
                    + '<button class="btn btn-sm" id="loginOpenBtn">Đăng nhập</button>'
                    + '<a class="link-btn" href="' + C.BASE + '/member.jsp">Tài khoản &amp; ưu đãi →</a>'
                    + '</div></div>';
                document.getElementById('loginOpenBtn').onclick = openAuth;
            }
        }

        function loadMember() {
            C.apiGet('/api/member/me').then(function (data) {
                if (!data.ok) return;
                member = data.loggedIn ? data.member : null;
                renderMember();
                renderOffers(data.vouchers);
                renderBill();
            });
        }

        /* ----- modal auth ----- */
        var authModal = document.getElementById('authModal');

        function openAuth() {
            authModal.classList.add('show');
            MemberUI.setAuthMode(false);
        }

        document.getElementById('tabLogin').onclick = function () { registerMode = false; MemberUI.setAuthMode(false); };
        document.getElementById('tabRegister').onclick = function () { registerMode = true; MemberUI.setAuthMode(true); };
        document.getElementById('authCancel').onclick = function () { authModal.classList.remove('show'); };

        document.getElementById('authSubmit').onclick = function () {
            MemberUI.submitAuth(registerMode).then(function (data) {
                if (data && data.ok) {
                    member = data.member;
                    loadMember();
                    doQuote();
                }
            });
        };

        /* ================= thanh toán ================= */

        document.querySelectorAll('.pay-opt').forEach(function (el) {
            el.addEventListener('click', function () {
                document.querySelectorAll('.pay-opt').forEach(function (o) { o.classList.remove('active'); });
                el.classList.add('active');
                el.querySelector('input').checked = true;
            });
        });

        document.getElementById('confirmBtn').onclick = function () {
            var btn = this;
            if (C.Cart.count() === 0) { C.toast('Giỏ hàng đang trống.'); return; }
            var method = document.querySelector('input[name=pay]:checked').value;

            btn.disabled = true;
            btn.textContent = 'Đang gửi đơn...';

            C.apiPost('/api/orders/create', C.Cart.toParams({
                voucherCode: voucherCode,
                paymentMethod: method
            })).then(function (data) {
                if (data.ok) {
                    C.Cart.clear();
                    location.href = 'order-status.jsp?id=' + data.orderId;
                    return;
                }
                C.toast(data.message || 'Không gửi được đơn.');
                if (data.error === 'UNAVAILABLE' || data.error === 'OUT_OF_STOCK') {
                    doQuote(); // đánh dấu lại món vừa hết
                }
                btn.disabled = false;
                btn.innerHTML = 'Xác nhận &amp; gửi đơn cho quán';
            }).catch(function () {
                C.toast('Lỗi kết nối, thử lại nhé.');
                btn.disabled = false;
                btn.innerHTML = 'Xác nhận &amp; gửi đơn cho quán';
            });
        };

        /* ================= khởi động ================= */

        document.addEventListener('cart:change', function () {
            renderCart();
            requestQuote();
        });

        renderCart();
        loadMember();
        doQuote();
    })();
    </script>
</body>
</html>
