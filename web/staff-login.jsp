<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=hold-05-1">
    <script defer src="assets/js/i18n.js?v=ops-log-1"></script>
</head>
<body class="auth-page staff-auth">
    <main class="auth-shell">
        <section class="auth-card staff-pin-card">
            <div class="auth-top">
                <a class="brand auth-brand" href="index.html">coffeshop</a>
                <div class="auth-tools">
                    <button id="lang-toggle" class="link lang-toggle auth-lang" type="button" onclick="toggleLang()">EN</button>
                </div>
            </div>

            <form id="login-form" class="auth-form staff-pin-form">
                <div>
                    <label data-i18n="roleChoose">Vị trí</label>
                    <div class="role-picker" id="role-picker">
                        <button class="role-option active" type="button" data-role="barista" onclick="chooseRole('barista')" data-i18n="roleBarista">Pha chế</button>
                        <button class="role-option" type="button" data-role="cashier" onclick="chooseRole('cashier')" data-i18n="roleCashier">Thu ngân</button>
                        <button class="role-option" type="button" data-role="runner" onclick="chooseRole('runner')" data-i18n="roleRunner">Bồi bàn</button>
                    </div>
                </div>

                <div>
                    <label for="pin" data-i18n="pin">Mã PIN</label>
                    <input id="pin" type="password" inputmode="numeric" pattern="[0-9]*" autocomplete="current-password" required autofocus>
                </div>

                <button class="btn primary big block auth-submit" type="submit" data-i18n="login">Đăng nhập</button>
                <div id="message" class="notice hidden"></div>
            </form>
        </section>
    </main>
    <script src="assets/js/page-staff-login.js?v=jsp-clean-1"></script>
</body>
</html>
