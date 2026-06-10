<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String pageTitle = "Tài khoản thành viên — nhà cà phê";
    String activeNav = "member";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/customer-topbar.jsp" %>

    <main class="wrap wrap-narrow" style="padding-bottom:60px">
        <div class="member-hero">
            <p class="label">Tài khoản thành viên</p>
            <h1 class="serif">Ưu đãi &amp; lịch sử</h1>
            <p class="label" style="margin-top:6px;text-transform:none;letter-spacing:0;font-size:13px">
                Đăng nhập để xem điểm tích lũy, mã giảm giá và đơn hàng trước đây — không cần gọi món.
            </p>
        </div>

        <div id="guestView">
            <div class="card card-pad">
                <h3 class="serif" style="font-size:20px;margin-bottom:14px">Đăng nhập hoặc đăng ký</h3>
                <div class="tabs" style="margin-bottom:16px">
                    <button type="button" id="pageTabLogin" class="active">Đăng nhập</button>
                    <button type="button" id="pageTabRegister">Đăng ký mới</button>
                </div>
                <div id="pagePaneLogin">
                    <input class="field" id="pageLoginPhone" type="tel" placeholder="Số điện thoại" style="margin-bottom:10px">
                    <input class="field" id="pageLoginPass" type="password" placeholder="Mật khẩu">
                </div>
                <div id="pagePaneRegister" style="display:none">
                    <input class="field" id="pageRegName" placeholder="Họ và tên" style="margin-bottom:10px">
                    <input class="field" id="pageRegPhone" type="tel" placeholder="Số điện thoại" style="margin-bottom:10px">
                    <input class="field" id="pageRegPass" type="password" placeholder="Mật khẩu (từ 6 ký tự)">
                </div>
                <div class="form-msg" id="pageAuthMsg"></div>
                <button type="button" class="btn btn-primary btn-big btn-block" id="pageAuthSubmit" style="margin-top:14px">Đăng nhập</button>
            </div>

            <div class="sec"><h2>Quyền lợi thành viên</h2><span class="line"></span></div>
            <div class="card card-pad">
                <ul class="gate-steps">
                    <li><span class="n">1</span>Tích điểm mỗi khi thanh toán tại quán</li>
                    <li><span class="n">2</span>Lên hạng Bronze → Silver → Gold để được giảm tự động</li>
                    <li><span class="n">3</span>Nhận mã ưu đãi riêng theo từng dịp</li>
                </ul>
            </div>
        </div>

        <div id="memberView" style="display:none">
            <div class="card card-pad" id="profileBox"></div>

            <div class="sec"><h2>Ưu đãi của bạn</h2><span class="line"></span></div>
            <div class="card card-pad" id="voucherBox"></div>

            <div class="sec"><h2>Lịch sử đơn hàng</h2><span class="line"></span></div>
            <div class="card card-pad" id="historyBox">
                <div class="skel" style="height:60px"></div>
            </div>

            <div style="margin-top:18px;display:flex;gap:10px;flex-wrap:wrap">
                <a class="btn btn-primary" href="<%=ctx%>/menu.jsp">Gọi món ngay</a>
                <button type="button" class="btn btn-ghost" id="logoutBtn">Đăng xuất</button>
            </div>
        </div>
    </main>

    <script src="<%=ctx%>/assets/js/app.js"></script>
    <script src="<%=ctx%>/assets/js/member.js"></script>
    <script>
    (function () {
        var C = window.CSMS;
        var pageRegister = false;

        function setPageMode(reg) {
            pageRegister = reg;
            document.getElementById('pageTabLogin').classList.toggle('active', !reg);
            document.getElementById('pageTabRegister').classList.toggle('active', reg);
            document.getElementById('pagePaneLogin').style.display = reg ? 'none' : '';
            document.getElementById('pagePaneRegister').style.display = reg ? '' : 'none';
            document.getElementById('pageAuthSubmit').textContent = reg ? 'Tạo tài khoản' : 'Đăng nhập';
            document.getElementById('pageAuthMsg').textContent = '';
        }

        document.getElementById('pageTabLogin').onclick = function () { setPageMode(false); };
        document.getElementById('pageTabRegister').onclick = function () { setPageMode(true); };

        document.getElementById('pageAuthSubmit').onclick = function () {
            var msg = document.getElementById('pageAuthMsg');
            var p = new URLSearchParams();
            if (pageRegister) {
                p.append('fullName', document.getElementById('pageRegName').value.trim());
                p.append('phone', document.getElementById('pageRegPhone').value.trim());
                p.append('password', document.getElementById('pageRegPass').value);
            } else {
                p.append('phone', document.getElementById('pageLoginPhone').value.trim());
                p.append('password', document.getElementById('pageLoginPass').value);
            }
            C.apiPost(pageRegister ? '/api/member/register' : '/api/member/login', p).then(function (data) {
                if (data.ok) {
                    C.toast(pageRegister ? 'Đăng ký thành công!' : 'Chào ' + data.member.fullName + '!');
                    loadAll();
                } else {
                    msg.className = 'form-msg err';
                    msg.textContent = data.message || 'Không thực hiện được.';
                }
            });
        };

        function renderProfile(m) {
            document.getElementById('profileBox').innerHTML =
                '<div class="member-box">'
                + '<div class="avatar">' + C.escapeHtml((m.fullName || '?').charAt(0)) + '</div>'
                + '<div style="flex:1">'
                + '<div style="font-weight:600;font-size:17px">' + C.escapeHtml(m.fullName) + '</div>'
                + '<div class="label" style="margin-top:4px;text-transform:none;letter-spacing:0">'
                + m.phone + ' · <span class="tier-chip">' + C.escapeHtml(m.tierName) + '</span></div>'
                + '<div style="margin-top:8px;font-size:14px"><b>' + m.points + '</b> điểm'
                + (m.tierDiscountPercent > 0 ? ' · giảm <b>' + m.tierDiscountPercent + '%</b> mọi đơn' : '')
                + '</div></div></div>';
        }

        function renderVouchers(vouchers) {
            var box = document.getElementById('voucherBox');
            if (!vouchers || vouchers.length === 0) {
                box.innerHTML = '<p class="label" style="text-transform:none;letter-spacing:0">Chưa có ưu đãi nào.</p>';
                return;
            }
            var html = '';
            vouchers.forEach(function (v) {
                html += '<div class="offer" style="cursor:default;margin-top:8px">'
                    + '<div><div class="code">' + C.escapeHtml(v.code) + '</div>'
                    + '<div class="desc">' + MemberUI.offerDesc(v) + ' · HSD ' + C.escapeHtml(v.expiry || '') + '</div></div>'
                    + (v.memberOnly ? '<span class="tag">Thành viên</span>' : '<span class="tag" style="color:var(--good);border-color:var(--good)">Mọi khách</span>')
                    + '</div>';
            });
            box.innerHTML = html;
        }

        function renderHistory(orders) {
            var box = document.getElementById('historyBox');
            if (!orders || orders.length === 0) {
                box.innerHTML = '<div class="empty-state" style="padding:30px 10px"><div class="big">☕</div>'
                    + '<h3>Chưa có đơn nào</h3><p>Gọi món tại quán để bắt đầu tích điểm.</p></div>';
                return;
            }
            var html = '';
            orders.forEach(function (o) {
                html += '<a class="history-item" href="' + C.BASE + '/order-status.jsp?id=' + o.orderId + '">'
                    + '<div class="hi-main">'
                    + '<div class="hi-title">Đơn #' + o.orderId + (o.tableName ? ' · ' + C.escapeHtml(o.tableName) : '') + '</div>'
                    + '<div class="hi-meta">' + C.escapeHtml(o.date) + ' · ' + MemberUI.statusLabel(o.orderStatus) + '</div>'
                    + '</div><div class="hi-amount">' + C.money(o.finalAmount) + '</div></a>';
            });
            box.innerHTML = html;
        }

        function loadAll() {
            C.apiGet('/api/member/me').then(function (data) {
                if (!data.ok) return;
                if (data.loggedIn) {
                    document.getElementById('guestView').style.display = 'none';
                    document.getElementById('memberView').style.display = '';
                    renderProfile(data.member);
                    renderVouchers(data.vouchers);
                    C.apiGet('/api/member/orders').then(function (od) {
                        if (od.ok) renderHistory(od.orders);
                    });
                } else {
                    document.getElementById('guestView').style.display = '';
                    document.getElementById('memberView').style.display = 'none';
                }
            });
        }

        document.getElementById('logoutBtn').onclick = function () {
            MemberUI.logout().then(loadAll);
        };

        loadAll();
    })();
    </script>
</body>
</html>
