<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
        <meta name="page-title-key" content="loginTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
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

            <!-- BƯỚC 1: bạn là ai.
                 Không còn chọn "vị trí" nữa: vai trò do ca làm hôm nay quyết định,
                 nhân viên không tự khai được mình là thu ngân hay pha chế. -->
            <section id="step-who">
                <p class="eyebrow" data-i18n="pickYourself">Chọn tên của bạn</p>
                <p class="cust-hint" id="roster-date"></p>
                <div class="staff-roster" id="staff-roster"></div>
                <p class="cust-hint hidden" id="roster-empty"></p>
            </section>

            <!-- BƯỚC 2: PIN cá nhân -->
            <section id="step-pin" class="hidden">
                <button class="link back-link" type="button" onclick="backToRoster()">
                    ← <span data-i18n="backToPrevious">Quay lại</span>
                </button>

                <div class="staff-chosen">
                    <span class="staff-avatar" id="chosen-initial"></span>
                    <div>
                        <b id="chosen-name"></b>
                        <span class="cust-hint" id="chosen-shift"></span>
                    </div>
                </div>

                <form id="pin-form" class="auth-form staff-pin-form">
                    <div>
                        <label for="pin" data-i18n="personalPin">Mã PIN cá nhân</label>
                        <input id="pin" type="password" inputmode="numeric" pattern="[0-9]*"
                               autocomplete="one-time-code" maxlength="8" required>
                    </div>

                    <!-- Chỉ hiện khi PIN đúng nhưng hôm nay người này không có ca -->
                    <div id="override-box" class="hidden">
                        <label for="admin-pin" data-i18n="managerPin">PIN quản lý</label>
                        <input id="admin-pin" type="password" inputmode="numeric" pattern="[0-9]*" maxlength="8">
                        <p class="cust-hint" data-i18n="overrideHint">
                            Người này không có ca hôm nay. Quản lý nhập PIN để mở khoá.
                        </p>
                    </div>

                    <button class="btn primary big block auth-submit" type="submit" data-i18n="login">Đăng nhập</button>
                    <div id="message" class="notice hidden"></div>
                </form>
            </section>
        </section>
    </main>
    <script src="assets/js/page-staff-login.js?v=loyalty-3"></script>
</body>
</html>
