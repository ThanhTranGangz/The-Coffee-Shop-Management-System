<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String pageTitle = "Đăng nhập PIN — nhà cà phê";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
    <style>
        .pin-field { text-align: center; letter-spacing: .35em; font-size: 22px; }
    </style>
</head>
<body class="textured">
    <div class="login-shell">
        <div class="card login-card">
            <div style="text-align:center;margin-bottom:22px">
                <a class="logo" href="<%=ctx%>/index.html" style="font-size:30px">nhà cà phê<b>.</b></a>
                <p class="label" style="margin-top:8px">Đăng nhập nhanh bằng PIN</p>
            </div>

            <form action="<%=ctx%>/pin-login" method="post">
                <label class="label label-dark" style="display:block;margin-bottom:6px">Tên đăng nhập</label>
                <input class="field" type="text" name="username" placeholder="username" required style="margin-bottom:14px" autocomplete="username">

                <label class="label label-dark" style="display:block;margin-bottom:6px">Mã PIN (4 số)</label>
                <input class="field pin-field" type="password" name="pin"
                       inputmode="numeric" maxlength="4" pattern="[0-9]{4}" placeholder="••••" required autocomplete="off">

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
                <a href="login.jsp">Đăng nhập mật khẩu</a>
            </div>
        </div>
    </div>
</body>
</html>
