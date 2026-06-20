<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String pageTitle = "Theo dõi đơn — nhà cà phê";
    String activeNav = "menu";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/customer-topbar.jsp" %>

    <main class="wrap wrap-narrow" style="padding-bottom:50px" id="mainArea">
        <div class="card card-pad" style="margin-top:18px">
            <div class="skel" style="height:120px"></div>
        </div>
    </main>

    <script src="<%=ctx%>/assets/js/app.js"></script>
    <script>
    (function () {
        var C = window.CSMS;
        var orderId = new URLSearchParams(location.search).get('id');
        var main = document.getElementById('mainArea');
        var timer = null;

        if (!orderId) {
            main.innerHTML = '<div class="empty-state"><div class="big">☕</div><h3>Thiếu mã đơn</h3>'
                + '<p><a href="menu.jsp">Quay lại menu</a></p></div>';
            return;
        }

        var STEPS = [
            { key: 'PENDING',   title: 'Quán đã nhận đơn',   desc: 'Đơn đã chuyển tới quầy pha chế' },
            { key: 'PREPARING', title: 'Đang pha chế',       desc: 'Barista đang chuẩn bị món của bạn' },
            { key: 'READY',     title: 'Sẵn sàng phục vụ',   desc: 'Món sẽ được mang tới bàn ngay' },
            { key: 'COMPLETED', title: 'Hoàn tất',           desc: 'Chúc bạn ngon miệng!' }
        ];

        function stepIndex(status) {
            for (var i = 0; i < STEPS.length; i++) {
                if (STEPS[i].key === status) return i;
            }
            return 0;
        }

        function render(data) {
            var o = data.order;

            var html = '';

            if (o.orderStatus === 'CANCELLED') {
                html += '<div class="empty-state"><div class="big">✕</div><h3>Đơn #' + o.orderId + ' đã hủy</h3>'
                    + '<p>Liên hệ nhân viên nếu bạn cần hỗ trợ.</p>'
                    + '<a class="btn btn-primary" style="margin-top:14px" href="menu.jsp">Đặt đơn mới</a></div>';
                main.innerHTML = html;
                clearInterval(timer);
                return;
            }

            // header đơn
            html += '<div style="margin:18px 0 14px">'
                + '<p class="label">Đơn hàng #' + o.orderId + (o.time ? ' · ' + o.time : '')
                + (o.tableName ? ' · ' + C.escapeHtml(o.tableName) : '') + '</p>'
                + '<h1 style="font-size:26px">'
                + (o.orderStatus === 'COMPLETED' ? 'Chúc ngon miệng ☕' : 'Quán đang chuẩn bị...')
                + '</h1></div>';

            // khối thanh toán
            if (data.vietqr) {
                html += '<div class="card card-pad" style="margin-bottom:14px;text-align:center">'
                    + '<p class="label" style="margin-bottom:10px">Chuyển khoản ' + C.money(o.finalAmount) + '</p>'
                    + '<img src="' + C.escapeHtml(data.vietqr.image) + '" alt="VietQR" style="width:230px;max-width:100%;border:1px solid var(--line);border-radius:12px;background:#fff">'
                    + '<div style="font-size:12.5px;color:var(--ink-soft);margin-top:10px;line-height:1.8">'
                    + C.escapeHtml(data.vietqr.bankName) + ' · ' + C.escapeHtml(data.vietqr.accountNo) + '<br>'
                    + C.escapeHtml(data.vietqr.accountName) + '<br>'
                    + 'Nội dung: <b>' + C.escapeHtml(data.vietqr.memo) + '</b></div>'
                    + '<div class="notice" style="text-align:left;margin-bottom:0">'
                    + '<span>!</span><span>Sau khi chuyển khoản, thu ngân sẽ xác nhận trong giây lát. Trạng thái: <b>'
                    + (C.PAY_STATUS[o.paymentStatus] || o.paymentStatus) + '</b></span></div>'
                    + '</div>';
            } else if (o.paymentMethod === 'CASH' && o.paymentStatus !== 'PAID') {
                html += '<div class="card card-pad" style="margin-bottom:14px">'
                    + '<div class="bill-row" style="padding:0"><span>Thanh toán tại quầy</span><b>' + C.money(o.finalAmount) + '</b></div>'
                    + '<p class="label" style="margin-top:6px">Vui lòng ghé quầy thu ngân khi thanh toán — đọc số đơn #' + o.orderId + '</p>'
                    + '</div>';
            } else if (o.paymentStatus === 'PAID') {
                html += '<div class="card card-pad" style="margin-bottom:14px">'
                    + '<div class="bill-row" style="padding:0"><span>Đã thanh toán ✓</span><b>' + C.money(o.finalAmount) + '</b></div>'
                    + (data.pointsEarned ? '<p class="label" style="margin-top:6px;color:var(--good)">+' + data.pointsEarned + ' điểm đã vào tài khoản thành viên</p>' : '')
                    + '</div>';
            }

            // timeline
            var idx = stepIndex(o.orderStatus);
            html += '<div class="card card-pad"><div class="timeline">';
            STEPS.forEach(function (s, i) {
                var cls = i < idx ? 'done' : (i === idx ? (o.orderStatus === 'COMPLETED' ? 'done' : 'now') : 'todo');
                html += '<div class="t-step ' + cls + '">'
                    + '<div class="t-dotcol"><div class="t-dot"></div>' + (i < STEPS.length - 1 ? '<div class="t-line"></div>' : '') + '</div>'
                    + '<div class="t-body"><div class="t-title">' + s.title + '</div>'
                    + '<div class="t-desc">' + s.desc + '</div></div></div>';
            });
            html += '</div></div>';

            // món trong đơn
            html += '<div class="sec"><h2>Món trong đơn</h2><span class="line"></span></div>'
                + '<div class="card card-pad">';
            o.items.forEach(function (it) {
                html += '<div class="oc-item"><span class="qty">' + it.quantity + '×</span>'
                    + '<span style="flex:1">' + C.escapeHtml(it.name)
                    + (it.note ? '<span class="note">“' + C.escapeHtml(it.note) + '”</span>' : '')
                    + '</span><span>' + C.money(it.subtotal) + '</span></div>';
            });
            if (o.discountAmount > 0) {
                html += '<div class="bill-row discount" style="margin-top:6px"><span>Giảm giá</span><span>−' + C.money(o.discountAmount) + '</span></div>';
            }
            html += '<div class="bill-row total"><span>Tổng</span><b>' + C.money(o.finalAmount) + '</b></div></div>';

            html += '<a class="btn btn-block" style="margin-top:18px" href="menu.jsp">+ Gọi thêm món</a>';

            main.innerHTML = html;

            if (o.orderStatus === 'COMPLETED' && o.paymentStatus === 'PAID') {
                clearInterval(timer);
            }
        }

        function poll() {
            C.apiGet('/api/orders/status?id=' + encodeURIComponent(orderId))
                .then(function (data) {
                    if (!data.ok) {
                        main.innerHTML = '<div class="empty-state"><div class="big">☕</div><h3>'
                            + C.escapeHtml(data.message || 'Không xem được đơn này') + '</h3>'
                            + '<p><a href="menu.jsp">Quay lại menu</a></p></div>';
                        clearInterval(timer);
                        return;
                    }
                    render(data);
                })
                .catch(function () { /* giữ nội dung cũ khi mất mạng tạm thời */ });
        }

        poll();
        timer = setInterval(poll, 5000);
    })();
    </script>
</body>
</html>
