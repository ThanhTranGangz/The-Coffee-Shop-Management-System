<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Staff Login</title>

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
                max-width: 980px;
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
                line-height: 1.2;
                margin-bottom: 18px;
            }

            .left-panel p {
                color: #f4dccb;
                font-size: 16px;
                line-height: 1.7;
            }

            .tag {
                margin-top: 28px;
                display: inline-block;
                width: fit-content;
                padding: 10px 16px;
                border-radius: 20px;
                background: rgba(255, 255, 255, 0.16);
                color: #fff3e8;
                font-size: 14px;
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
                transition: 0.2s;
            }

            input:focus {
                border-color: #6f4e37;
                box-shadow: 0 0 0 3px rgba(111, 78, 55, 0.15);
                background: white;
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
                transition: 0.25s;
            }

            .login-btn:hover {
                background: #4f3424;
                transform: translateY(-2px);
                box-shadow: 0 10px 20px rgba(111, 78, 55, 0.25);
            }

            .extra-links {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-top: 22px;
                font-size: 14px;
            }

            .extra-links a {
                color: #6f4e37;
                text-decoration: none;
                font-weight: bold;
            }

            .extra-links a:hover {
                text-decoration: underline;
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
                line-height: 1.5;
            }

            @media (max-width: 850px) {
                .login-card {
                    grid-template-columns: 1fr;
                }

                .left-panel {
                    padding: 35px 30px;
                }

                .left-panel h1 {
                    font-size: 30px;
                }

                .right-panel {
                    padding: 38px 28px;
                }
            }
        </style>
    </head>

    <body>
        <div class="login-wrapper">
            <div class="login-card">

                <div class="left-panel">
                    <div class="logo">☕</div>

                    <h1>Staff Login</h1>

                    <p>
                        Sign in to access the Coffee Shop Management System.
                        This module supports staff authentication, role-based security,
                        admin reports, and CRM management.
                    </p>

                    <div class="tag">
                        Admin, Security & CRM
                    </div>
                </div>

                <div class="right-panel">
                    <h2>Welcome Back</h2>
                    <p class="subtitle">Please enter your staff account to continue.</p>

                    <form action="login" method="post">
                        <div class="form-group">
                            <label>Username</label>
                            <div class="input-box">
                                <span>👤</span>
                                <input type="text" name="username" placeholder="Enter username" required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Password</label>
                            <div class="input-box">
                                <span>🔒</span>
                                <input type="password" name="password" placeholder="Enter password" required>
                            </div>
                        </div>

                        <button class="login-btn" type="submit">Login</button>
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
                        <a href="pin-login.jsp">Use PIN Login</a>
                    </div>

                    <div class="demo-note">
                        Demo account: <b>admin</b> / <b>123456</b>
                    </div>
                </div>

            </div>
        </div>
    </body>
</html>