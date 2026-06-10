<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Staff"%>
<%
    if (ctx == null) ctx = request.getContextPath();
    Staff staffUser = (Staff) session.getAttribute("staff");
    String staffName = staffUser != null ? staffUser.getFullName() : "";
%>
<header class="topbar">
    <div class="wrap topbar-in">
        <a class="logo" href="<%= ctx %>/dashboard.jsp">nhà cà phê<b>.</b></a>
        <span class="label">Khu vực nhân viên</span>
        <div class="spacer"></div>
        <% if (!staffName.isEmpty()) { %>
        <span class="table-badge"><span class="dot"></span><%= staffName %></span>
        <% } %>
        <a class="btn btn-ghost btn-sm" href="<%= ctx %>/staff-orders.jsp">Bảng đơn</a>
        <a class="btn btn-ghost btn-sm" href="<%= ctx %>/staff/table-qr">QR bàn</a>
        <a class="btn btn-ghost btn-sm" href="<%= ctx %>/index.html" title="Về trang khách">⌂ Khách</a>
        <a class="btn btn-ghost btn-sm" href="<%= ctx %>/logout">Thoát</a>
    </div>
</header>
