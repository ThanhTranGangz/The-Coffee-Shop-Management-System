<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    if (ctx == null) ctx = request.getContextPath();
    if (activeNav == null) activeNav = "";
    model.Tables table = (model.Tables) session.getAttribute("table");
    model.Member member = (model.Member) session.getAttribute("member");
%>
<header class="topbar">
    <div class="wrap topbar-in">
        <a class="logo" href="<%= ctx %>/index.html" title="Trang chủ">nhà cà phê<b>.</b></a>

        <nav class="topnav" aria-label="Điều hướng khách">
            <a class="topnav-link icon-only<%= "home".equals(activeNav) ? " active" : "" %>"
               href="<%= ctx %>/index.html" title="Trang chủ">⌂</a>
            <a class="topnav-link<%= "menu".equals(activeNav) ? " active" : "" %>"
               href="<%= ctx %>/menu.jsp">Menu</a>
            <a class="topnav-link<%= "member".equals(activeNav) ? " active" : "" %>"
               href="<%= ctx %>/member.jsp">Thành viên</a>
        </nav>

        <div class="spacer"></div>

        <% if (table != null) { %>
        <span class="table-badge"><span class="dot"></span><%= table.getTableName() %></span>
        <% } %>

        <a class="btn btn-ghost btn-sm nav-mobile-only" href="<%= ctx %>/member.jsp">Thành viên</a>
        <a class="btn btn-ghost btn-sm" href="<%= ctx %>/login.jsp" title="Khu vực nhân viên">Nhân viên</a>
    </div>
</header>
