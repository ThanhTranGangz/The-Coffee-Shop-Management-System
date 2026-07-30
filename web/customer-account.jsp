<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <meta name="page-title-key" content="customerAccountTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
</head>
<body>
    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell work-shell" style="max-width:900px">

        <!-- Thẻ thành viên -->
        <section class="loyalty-card" id="loyalty-card">
            <div class="loyalty-head">
                <div>
                    <p class="eyebrow" id="loyalty-tier">—</p>
                    <h2 id="loyalty-name">—</h2>
                    <p class="loyalty-phone" id="loyalty-phone">—</p>
                </div>
                <div class="loyalty-points">
                    <span class="loyalty-points-num" id="loyalty-points">0</span>
                    <span class="loyalty-points-label" data-i18n="points">điểm</span>
                    <span class="loyalty-points-value" id="loyalty-points-value">≈ 0 đ</span>
                </div>
            </div>
            <div class="loyalty-progress">
                <div class="loyalty-bar"><span id="loyalty-bar-fill"></span></div>
                <p class="cust-hint" id="loyalty-progress-text">—</p>
            </div>
            <div class="loyalty-facts">
                <div><b id="loyalty-spent">0 đ</b><span data-i18n="totalSpent">Tổng chi tiêu</span></div>
                <div><b id="loyalty-orders">0</b><span data-i18n="orderCountLabel">Số đơn</span></div>
                <div><b id="loyalty-since">—</b><span data-i18n="memberSince">Thành viên từ</span></div>
            </div>
        </section>

        <!-- Tabs -->
        <div class="cust-tabs" style="margin:18px 0 14px" role="tablist">
            <button class="cust-tab active" type="button" id="tab-orders" onclick="switchPanel('orders')"
                    data-i18n="orderHistory">Lịch sử đơn</button>
            <button class="cust-tab" type="button" id="tab-points" onclick="switchPanel('points')"
                    data-i18n="pointHistory">Sổ điểm</button>
            <button class="cust-tab" type="button" id="tab-settings" onclick="switchPanel('settings')"
                    data-i18n="accountSettings">Tài khoản</button>
        </div>

        <section id="panel-orders" class="list"></section>

        <section id="panel-points" class="list hidden"></section>

        <section id="panel-settings" class="hidden">
            <div class="card" style="margin-bottom:14px">
                <p class="eyebrow" data-i18n="profileInfo">Thông tin cá nhân</p>
                <form id="profile-form" class="auth-form">
                    <div>
                        <label for="profile-name" data-i18n="fullName">Họ và tên</label>
                        <input id="profile-name" type="text" required>
                    </div>
                    <button class="btn primary" type="submit" data-i18n="save">Lưu</button>
                </form>
                <div id="profile-message" class="notice hidden" style="margin-top:12px"></div>
            </div>

            <div class="card">
                <p class="eyebrow" data-i18n="changePassword">Đổi mật khẩu</p>
                <form id="password-form" class="auth-form">
                    <div>
                        <label for="old-password" data-i18n="currentPassword">Mật khẩu hiện tại</label>
                        <input id="old-password" type="password" autocomplete="current-password" required>
                    </div>
                    <div>
                        <label for="new-password" data-i18n="newPassword">Mật khẩu mới</label>
                        <input id="new-password" type="password" autocomplete="new-password" required>
                    </div>
                    <div>
                        <label for="new-password2" data-i18n="passwordConfirm">Nhập lại mật khẩu</label>
                        <input id="new-password2" type="password" autocomplete="new-password" required>
                    </div>
                    <button class="btn primary" type="submit" data-i18n="changePassword">Đổi mật khẩu</button>
                </form>
                <div id="password-message" class="notice hidden" style="margin-top:12px"></div>
            </div>

            <button class="btn danger block" type="button" onclick="customerLogout()"
                    style="margin-top:16px" data-i18n="logout">Đăng xuất</button>
        </section>
    </main>

    <script src="assets/js/page-customer-account.js?v=loyalty-2"></script>
</body>
</html>
