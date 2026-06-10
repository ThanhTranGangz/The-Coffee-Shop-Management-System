<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Staff"%>
<%@page import="util.AuthUtil"%>
<%@page import="util.Permission"%>
<%
    Staff staff = (Staff) session.getAttribute("staff");
    if (staff == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String ctx = request.getContextPath();
    String pageTitle = "Bảng điều khiển — nhà cà phê";
    boolean denied = "1".equals(request.getParameter("denied"));
    boolean canViewOrders = AuthUtil.hasAnyPermission(request, Permission.VIEW_STAFF_ORDERS, Permission.VIEW_KITCHEN_ORDER);
    boolean canManageQr = AuthUtil.hasPermission(request, Permission.MANAGE_TABLE_QR);
    boolean canManageStaff = AuthUtil.hasPermission(request, Permission.MANAGE_STAFF);
    boolean canViewReport = "MANAGER".equalsIgnoreCase(staff.getRoleName())
            || AuthUtil.hasPermission(request, Permission.VIEW_REPORT);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/staff-topbar.jsp" %>

    <main class="wrap staff-shell">
        <div class="card staff-hero">
            <p class="label">Xin chào, <%= staff.getFullName() %></p>
            <h1 class="serif">Bảng điều khiển</h1>
            <p>Vai trò: <b><%= staff.getRoleName() %></b> — chọn module bên dưới để bắt đầu.</p>
            <% if (denied) { %>
            <p style="margin-top:12px;color:#b45309;font-size:14px">Bạn không có quyền truy cập module vừa chọn.</p>
            <% } %>
        </div>

        <div class="module-grid">
            <% if (canViewOrders) { %>
            <div class="card module-card">
                <h3 class="serif">Bảng đơn pha chế</h3>
                <p>Theo dõi đơn từ khách QR: chờ pha → đang pha → sẵn sàng. Xác nhận thanh toán và tích điểm thành viên.</p>
                <div class="module-actions">
                    <a class="btn btn-primary" href="staff-orders.jsp">Mở bảng đơn</a>
                </div>
            </div>
            <% } %>

            <% if (canManageQr) { %>
            <div class="card module-card">
                <h3 class="serif">Mã QR bàn</h3>
                <p>In hoặc xem mã QR riêng cho từng bàn. Khách quét sẽ vào menu đúng bàn của họ.</p>
                <div class="module-actions">
                    <a class="btn btn-primary" href="<%=ctx%>/staff/table-qr">Quản lý QR</a>
                </div>
            </div>
            <% } %>

            <div class="card module-card">
                <h3 class="serif">Menu khách hàng</h3>
                <p>Xem giao diện khách đang dùng tại quán — hữu ích khi hỗ trợ hoặc kiểm tra món.</p>
                <div class="module-actions">
                    <a class="btn" href="menu.jsp">Xem menu</a>
                    <a class="btn btn-ghost" href="index.html">Trang chủ khách</a>
                </div>
            </div>

            <% if (canManageStaff) { %>
            <div class="card module-card">
                <h3 class="serif">Quản lý nhân viên</h3>
                <p>Tạo tài khoản, gán vai trò, kích hoạt hoặc vô hiệu hóa nhân viên trong hệ thống.</p>
                <div class="module-actions">
                    <a class="btn btn-primary" href="<%=ctx%>/staff-management">Mở quản lý</a>
                </div>
            </div>
            <% } %>

            <div class="card module-card">
                <h3 class="serif">Báo cáo &amp; CRM</h3>
                <p>Báo cáo cuối ngày, voucher và quản lý thành viên — đang phát triển thêm.</p>
                <div class="module-actions">
                    <% if (canViewReport) { %>
                    <a class="btn btn-primary" href="<%=ctx%>/staff/reports">Mở báo cáo</a>
                    <% } else { %>
                    <span class="label" style="text-transform:none;letter-spacing:0">Bạn chưa có quyền xem</span>
                    <% } %>
                </div>
            </div>
        </div>

        <p class="label" style="text-align:center;margin-top:28px">nhà cà phê © 2026</p>
    </main>
</body>
</html>
