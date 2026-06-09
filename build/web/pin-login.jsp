<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Staff PIN Login</title>

        <style>
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
            }

            body {
                font-family: Arial, Helvetica, sans-serif;
                min-height: 100vh;
                background: linear-gradient(135deg, #f8ede3, #dfc3a5);
                display: flex;
                justify-content: center;
                align-items: center;
                color: #2d1b12;
            }

            .login-wrapper {
                width: 100%;
                max-width: 900px;
                padding: 30px;
            }

            .login-card {
                display: grid;
                grid-template-columns: 0.9fr 1.1fr;
                background: rgba(255, 255, 255, 0.95);
                border-radius: 24px;
                overflow: hidden;
                box-shadow: 0 20px 45px rgba(80, 45, 20, 0.25);
            }

            .left-panel {
                background: linear-gradient(160deg, #6f4e37, #3d2417);
                color: white;
                padding: 50px 42px;
                display: flex;
                flex-direction: column;
                justify-content: center;
            }

            .logo {
                width: 72px;
                height: 72px;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.18);
                display: flex;
                justify-content: center;
                align-items: center;
                font-size: 36px;
                margin-bottom: 25px;
            }

            .left-panel h1 {
                font-size: 36px;
                margin-bottom: 18px;
            }

            .left-panel p {
                color: #f4dccb;
                font-size: 16px;
                line-height: 1.7;
            }

            .right-panel {
                padding: 55px 48px;
            }

            .right-panel h2 {
                font-size: 32px;
                color: #4a2d1d;
                margin-bottom: 8px;
                text-align: center;
            }

            .subtitle {
                text-align: center;
                color: #7a6253;
                font-size: 15px;
                margin-bottom: 35px;
            }

            .form-group {
                margin-bottom: 18px;
            }

            label {
                display: block;
                margin-bottom: 8px;
                color: #4a2d1d;
                font-weight: bold;
                font-size: 14px;
            }

            .input-box {
                position: relative;
            }

            .input-box span {
                position: absolute;
                left: 15px;
                top: 50%;
                transform: translateY(-50%);
                font-size: 18px;
            }

            input {
                width: 100%;
                padding: 14px 14px 14px 48px;
                border: 1px solid #d7c0ad;
                border-radius: 12px;
                font-size: 15px;
                outline: none;
                background: #fffaf6;
            }

            input:focus {
                border-color: #6f4e37;
                box-shadow: 0 0 0 3px rgba(111, 78, 55, 0.15);
                background: white;
            }

            .pin-input {
                letter-spacing: 10px;
                font-size: 22px;
                font-weight: bold;
                text-align: center;
                padding-left: 48px;
            }

            .login-btn {
                width: 100%;
                padding: 14px;
                margin-top: 10px;
                border: none;
                border-radius: 12px;
                background: #6f4e37;
                color: white;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
            }

            .login-btn:hover {
                background: #4f3424;
            }

            .extra-links {
                display: flex;
                justify-content: space-between;
                margin-top: 22px;
                font-size: 14px;
            }

            .extra-links a {
                color: #6f4e37;
                text-decoration: none;
                font-weight: bold;
            }

            .error {
                margin-top: 18px;
                padding: 12px;
                background: #ffe5e5;
                color: #c62828;
                border-radius: 10px;
                text-align: center;
                font-size: 14px;
                border: 1px solid #ffc4c4;
            }

            .demo-note {
                margin-top: 24px;
                padding: 13px;
                border-radius: 12px;
                background: #f4e7dc;
                color: #6b4b37;
                font-size: 14px;
                text-align: center;
            }

            @media (max-width: 850px) {
                .login-card {
                    grid-template-columns: 1fr;
                }
            }
        </style>
    </head>

    <body>
        <div class="login-wrapper">
            <div class="login-card">

                <div class="left-panel">
                    <div class="logo">🔢</div>
                    <h1>Staff PIN Login</h1>
                    <p>
                        Quick login for shared POS, kiosk, kitchen display,
                        or waiter station devices using a 4-digit staff PIN.
                    </p>
                </div>

                <div class="right-panel">
                    <h2>Enter PIN</h2>
                    <p class="subtitle">Use your staff username and 4-digit PIN.</p>

                    <form action="${pageContext.request.contextPath}/pin-login" method="post">
                        <div class="form-group">
                            <label>Username</label>
                            <div class="input-box">
                                <span>👤</span>
                                <input type="text" name="username" placeholder="Enter username" required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>PIN Code</label>
                            <div class="input-box">
                                <span>🔐</span>
                                <input class="pin-input" type="password" name="pin"
                                       placeholder="1234" maxlength="4"
                                       pattern="[0-9]{4}" required>
                            </div>
                        </div>

                        <button class="login-btn" type="submit">Login with PIN</button>
                    </form>

                    <%
                        String error = (String) request.getAttribute("error");
                        if (error != null) {
                    %>
                        <div class="error"><%= error %></div>
                    <%
                        }
                    %>

                    <div class="extra-links">
                        <a href="${pageContext.request.contextPath}/index.html">← Back to Home</a>
                        <a href="${pageContext.request.contextPath}/login.jsp">Use Password Login</a>
                    </div>

                    <div class="demo-note">
                        Demo PIN account: <b>admin</b> / <b>1234</b>
                    </div>
                </div>

            </div>
        </div>
    </body>
</html>