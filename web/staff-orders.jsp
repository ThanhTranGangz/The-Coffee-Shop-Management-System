<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    model.Staff staff = (model.Staff) session.getAttribute("staff");
    if (staff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String ctx = request.getContextPath();
    String pageTitle = "Bảng đơn — nhà cà phê";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/staff-topbar.jsp" %>

    <main class="wrap staff-shell">
        <div class="card staff-hero no-print">
            <p class="label">Pha chế &amp; thu ngân</p>
            <h1 class="serif">Bảng đơn hôm nay</h1>
            <p>Kéo đơn qua các cột: chờ pha → đang pha → sẵn sàng / hoàn tất.</p>
        </div>
        <div class="board" id="board">
            <div class="card card-pad"><div class="skel" style="height:90px"></div></div>
            <div class="card card-pad"><div class="skel" style="height:90px"></div></div>
            <div class="card card-pad"><div class="skel" style="height:90px"></div></div>
        </div>
    </main>

    <script src="<%=ctx%>/assets/js/app.js"></script>
    <script>
    (function () {
        var C = window.CSMS;
        var timer = null;

        var COLS = [
            { title: 'Chờ pha chế',   match: function (o) { return o.orderStatus === 'PENDING'; } },
            { title: 'Đang pha chế',  match: function (o) { return o.orderStatus === 'PREPARING'; } },
            { title: 'Sẵn sàng / Hoàn tất', match: function (o) { return o.orderStatus === 'READY' || o.orderStatus === 'COMPLETED'; } }
        ];

        function payBadge(o) {
            if (o.paymentStatus === 'PAID') return '<span class="badge paid">Đã thu ' + (o.paymentMethod === 'VIETQR' ? 'CK' : 'tiền') + '</span>';
            if (o.paymentStatus === 'PENDING') return '<span class="badge pending">Chờ xác nhận CK</span>';
            return '<span class="badge unpaid">Chưa thu tiền</span>';
        }

        function actions(o) {
            var html = '';
            if (o.orderStatus === 'PENDING') {
                html += '<button class="btn btn-primary btn-sm" data-act="advance" data-id="' + o.orderId + '">Bắt đầu pha</button>';
                html += '<button class="btn btn-ghost btn-sm" data-act="cancel" data-id="' + o.orderId + '">Hủy</button>';
            } else if (o.orderStatus === 'PREPARING') {
                html += '<button class="btn btn-primary btn-sm" data-act="advance" data-id="' + o.orderId + '">Pha xong</button>';
            } else if (o.orderStatus === 'READY') {
                html += '<button class="btn btn-primary btn-sm" data-act="advance" data-id="' + o.orderId + '">Đã phục vụ</button>';
            }
            if (o.paymentStatus !== 'PAID') {
                html += '<button class="btn btn-sm" data-act="markPaid" data-id="' + o.orderId + '">✓ Đã thu tiền</button>';
            }
            return html;
        }

        function orderCard(o) {
            var items = '';
            o.items.forEach(function (it) {
                items += '<div class="oc-item"><span class="qty">' + it.quantity + '×</span>'
                    + '<span style="flex:1">' + C.escapeHtml(it.name)
                    + (it.note ? '<span class="note">“' + C.escapeHtml(it.note) + '”</span>' : '')
                    + '</span></div>';
            });
            return '<div class="card order-card">'
                + '<div class="oc-head"><span class="no">#' + o.orderId + '</span>'
                + '<span class="table-badge"><span class="dot"></span>' + C.escapeHtml(o.tableName || 'Mang đi') + '</span>'
                + '<span class="time">' + (o.time || '') + '</span>'
                + '<span class="spacer"></span>' + payBadge(o)
                + '</div>'
                + '<div class="oc-items">' + items
                + (o.memberName ? '<div class="label" style="margin-top:6px">Thành viên: ' + C.escapeHtml(o.memberName) + '</div>' : '')
                + '</div>'
                + '<div class="oc-foot"><span class="sum">' + C.money(o.finalAmount) + '</span>' + actions(o) + '</div>'
                + '</div>';
        }

        function render(orders) {
            var html = '';
            COLS.forEach(function (col) {
                var list = orders.filter(col.match);
                html += '<div><div class="board-col-head"><span class="label label-dark">' + col.title
                    + '</span><span class="cnt">' + list.length + '</span></div>';
                if (list.length === 0) {
                    html += '<div class="card card-pad" style="text-align:center;color:var(--muted);font-size:12.5px">Trống</div>';
                } else {
                    list.forEach(function (o) { html += orderCard(o); });
                }
                html += '</div>';
            });
            var board = document.getElementById('board');
            board.innerHTML = html;

            board.querySelectorAll('[data-act]').forEach(function (b) {
                b.onclick = function () {
                    if (b.dataset.act === 'cancel' && !confirm('Hủy đơn #' + b.dataset.id + '? Nguyên liệu sẽ được hoàn kho.')) {
                        return;
                    }
                    var p = new URLSearchParams();
                    p.append('action', b.dataset.act);
                    p.append('orderId', b.dataset.id);
                    C.apiPost('/api/staff/orders', p).then(function (data) {
                        if (!data.ok) {
                            C.toast(data.message || 'Không thực hiện được.');
                        } else if (data.pointsAwarded > 0) {
                            C.toast('Đã thu tiền · cộng ' + data.pointsAwarded + ' điểm cho thành viên');
                        }
                        poll();
                    });
                };
            });
        }

        function poll() {
            C.apiGet('/api/staff/orders').then(function (data) {
                if (data.ok) render(data.orders);
            }).catch(function () { /* giữ bảng cũ khi mất mạng */ });
        }

        poll();
        timer = setInterval(poll, 5000);
    })();
    </script>
</body>
</html>
