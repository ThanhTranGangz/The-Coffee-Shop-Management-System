<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.List,dal.TableDAO"%>
<%
    model.Staff staff = (model.Staff) session.getAttribute("staff");
    if (staff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String ctx = request.getContextPath();
    @SuppressWarnings("unchecked")
    List<TableDAO.TableWithToken> tables = (List<TableDAO.TableWithToken>) request.getAttribute("tables");
    if (tables == null) {
        response.sendRedirect(ctx + "/staff/table-qr");
        return;
    }

    int port = request.getServerPort();
    boolean defaultPort = ("http".equals(request.getScheme()) && port == 80)
            || ("https".equals(request.getScheme()) && port == 443);
    String baseUrl = request.getScheme() + "://" + request.getServerName()
            + (defaultPort ? "" : ":" + port) + ctx;
    String pageTitle = "Mã QR bàn — nhà cà phê";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <div class="no-print"><%@ include file="/includes/staff-topbar.jsp" %></div>

    <main class="wrap staff-shell">
        <div class="no-print" style="display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap;margin:16px 0">
            <div>
                <h1 class="serif" style="font-size:24px">Mã QR đặt món tại bàn</h1>
                <p class="label" style="text-transform:none;letter-spacing:0;margin-top:4px">In và dán tại từng bàn</p>
            </div>
            <button class="btn btn-primary btn-sm" type="button" onclick="window.print()">In tất cả</button>
        </div>
        <div class="notice no-print">
            <span>!</span>
            <span>Khách quét mã bằng camera điện thoại sẽ vào thẳng menu của đúng bàn.
                  Lưu ý: để điện thoại truy cập được, hãy mở trang này qua địa chỉ IP của máy chủ
                  trong mạng wifi của quán (ví dụ <b>http://192.168.1.10:8080<%=ctx%></b>) rồi mới in —
                  mã QR được tạo theo địa chỉ đang mở: <b><%= baseUrl %></b></span>
        </div>

        <div class="qr-grid">
            <% for (TableDAO.TableWithToken t : tables) {
                String url = baseUrl + "/table?token=" + t.getQrToken();
                String qrImg = "https://api.qrserver.com/v1/create-qr-code/?size=320x320&margin=2&data="
                        + java.net.URLEncoder.encode(url, "UTF-8");
            %>
            <div class="card qr-card">
                <div class="label">nhà cà phê — quét để gọi món</div>
                <div class="tname"><%= t.getTableName() %></div>
                <img src="<%= qrImg %>" alt="QR <%= t.getTableName() %>" loading="lazy">
                <div class="url"><%= url %></div>
                <a class="btn btn-ghost btn-sm no-print" style="margin-top:10px" href="<%= url %>">Mở thử liên kết</a>
            </div>
            <% } %>
        </div>
    </main>
</body>
</html>
