<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String pageTitle = "Đăng nhập nhân viên — nhà cà phê";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">
    <div class="login-shell">
        <div class="card login-card">
            <div style="text-align:center;margin-bottom:22px">
                <a class="logo" href="<%=ctx%>/index.html" style="font-size:30px">nhà cà phê<b>.</b></a>
                <p class="label" style="margin-top:8px">Khu vực nhân viên</p>
            </div>

            <form action="login" method="post">
                <label class="label label-dark" style="display:block;margin-bottom:6px">Tên đăng nhập</label>
                <input class="field" type="text" name="username" placeholder="username" required style="margin-bottom:14px" autocomplete="username">

                <label class="label label-dark" style="display:block;margin-bottom:6px">Mật khẩu</label>
                <input class="field" type="password" name="password" placeholder="••••••" required autocomplete="current-password">

                <button class="btn btn-primary btn-big btn-block" type="submit" style="margin-top:18px">Đăng nhập</button>
            </form>

            <%
                String error = (String) request.getAttribute("error");
                if (error != null) {
            %>
            <div class="err-box"><%= error %></div>
            <%
                }
            %>

            <div style="display:flex;justify-content:space-between;margin-top:18px;font-size:12.5px;flex-wrap:wrap;gap:8px">
                <a href="<%=ctx%>/index.html">← Trang chủ</a>
                <a href="pin-login.jsp">Đăng nhập bằng PIN</a>
            </div>
        </div>
    </div>
</body>
</html>
