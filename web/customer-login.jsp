<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <meta name="page-title-key" content="customerLoginTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
</head>
<body class="auth-page cust-auth-page">
    <main class="cust-auth-shell">
        <div class="cust-auth-layout">

            <!-- Cột giới thiệu: ẩn trên điện thoại để form luôn nằm trên màn hình đầu -->
            <aside class="cust-auth-aside">
                <a class="brand cust-aside-brand" href="index.html">coffeshop</a>
                <h1 class="cust-aside-title" data-i18n="loyaltyHeroTitle">Mỗi ly cà phê đều được cộng điểm</h1>
                <p class="cust-aside-text" data-i18n="loyaltyHeroText">
                    Tạo tài khoản để tích điểm, đổi điểm lấy giảm giá và xem lại toàn bộ đơn đã gọi.
                </p>

                <ul class="cust-benefits">
                    <li>
                        <span class="cust-benefit-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 3l2.6 5.6 6.1.8-4.5 4.2 1.2 6-5.4-3-5.4 3 1.2-6L3.3 9.4l6.1-.8z"/>
                            </svg>
                        </span>
                        <div>
                            <b data-i18n="benefitEarnTitle">Tích điểm tự động</b>
                            <span data-i18n="benefitEarnText">Cứ 10.000đ thanh toán là 1 điểm.</span>
                        </div>
                    </li>
                    <li>
                        <span class="cust-benefit-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20.6 13.4 12 22l-9-9V3h10z"/>
                                <circle cx="7.5" cy="7.5" r="1.4"/>
                            </svg>
                        </span>
                        <div>
                            <b data-i18n="benefitRedeemTitle">Đổi điểm lấy giảm giá</b>
                            <span data-i18n="benefitRedeemText">1 điểm bằng 1.000đ, dùng ngay khi gọi món.</span>
                        </div>
                    </li>
                    <li>
                        <span class="cust-benefit-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M3 12a9 9 0 1 0 2.6-6.4"/>
                                <path d="M3 4v5h5"/>
                                <path d="M12 7.5V12l3 1.8"/>
                            </svg>
                        </span>
                        <div>
                            <b data-i18n="benefitHistoryTitle">Lịch sử đơn hàng</b>
                            <span data-i18n="benefitHistoryText">Xem lại mọi đơn đã gọi trên mọi thiết bị.</span>
                        </div>
                    </li>
                </ul>

                <div class="cust-tier-strip">
                    <span class="cust-tier-pill bronze" data-i18n="tierBronze">Hạng Đồng</span>
                    <span class="cust-tier-pill silver" data-i18n="tierSilver">Hạng Bạc</span>
                    <span class="cust-tier-pill gold" data-i18n="tierGold">Hạng Vàng</span>
                </div>
            </aside>

            <!-- Cột biểu mẫu -->
            <section class="auth-card cust-auth-card">
                <div class="auth-top cust-auth-top">
                    <a class="brand auth-brand cust-card-brand" href="index.html">coffeshop</a>
                    <button id="lang-toggle" class="link lang-toggle auth-lang" type="button" onclick="toggleLang()">EN</button>
                </div>

                <div class="cust-switch" role="tablist">
                    <span class="cust-switch-thumb" id="switch-thumb" aria-hidden="true"></span>
                    <button class="cust-switch-btn active" type="button" id="tab-login" role="tab"
                            aria-selected="true" onclick="switchTab('login')"
                            data-i18n="customerLogin">Đăng nhập</button>
                    <button class="cust-switch-btn" type="button" id="tab-register" role="tab"
                            aria-selected="false" onclick="switchTab('register')"
                            data-i18n="customerRegister">Đăng ký</button>
                </div>

                <!-- ĐĂNG NHẬP -->
                <form id="login-form" class="auth-form cust-form">
                    <header class="cust-form-head">
                        <h2 data-i18n="welcomeBack">Chào bạn quay lại</h2>
                        <p data-i18n="loginSubtitle">Đăng nhập bằng số điện thoại đã đăng ký.</p>
                    </header>

                    <div class="cust-field">
                        <label for="login-phone" data-i18n="phoneNumber">Số điện thoại</label>
                        <div class="cust-input">
                            <span class="cust-input-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="6" y="2.5" width="12" height="19" rx="2.6"/>
                                    <path d="M11 18.5h2"/>
                                </svg>
                            </span>
                            <input id="login-phone" type="tel" inputmode="numeric" autocomplete="username"
                                   placeholder="0901234567" required autofocus>
                        </div>
                    </div>

                    <div class="cust-field">
                        <label for="login-password" data-i18n="password">Mật khẩu</label>
                        <div class="cust-input">
                            <span class="cust-input-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="4" y="10.5" width="16" height="10.5" rx="2.4"/>
                                    <path d="M8 10.5V7.4a4 4 0 0 1 8 0v3.1"/>
                                </svg>
                            </span>
                            <input id="login-password" type="password" autocomplete="current-password" required>
                            <button class="cust-eye" type="button" data-toggle="login-password"
                                    data-i18n-aria="showPassword" aria-label="Hiện mật khẩu"></button>
                        </div>
                    </div>

                    <button class="btn primary big block cust-submit" type="submit"
                            data-i18n="customerLogin">Đăng nhập</button>
                </form>

                <!-- ĐĂNG KÝ -->
                <form id="register-form" class="auth-form cust-form hidden">
                    <header class="cust-form-head">
                        <h2 data-i18n="createAccount">Tạo tài khoản</h2>
                        <p data-i18n="registerSubtitle">Chỉ cần số điện thoại, mất khoảng 30 giây.</p>
                    </header>

                    <div class="cust-field">
                        <label for="reg-name" data-i18n="fullName">Họ và tên</label>
                        <div class="cust-input">
                            <span class="cust-input-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="8" r="3.6"/>
                                    <path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>
                                </svg>
                            </span>
                            <input id="reg-name" type="text" autocomplete="name"
                                   data-i18n-placeholder="fullNamePlaceholder" placeholder="Nguyễn Văn A" required>
                        </div>
                    </div>

                    <div class="cust-field">
                        <label for="reg-phone" data-i18n="phoneNumber">Số điện thoại</label>
                        <div class="cust-input">
                            <span class="cust-input-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="6" y="2.5" width="12" height="19" rx="2.6"/>
                                    <path d="M11 18.5h2"/>
                                </svg>
                            </span>
                            <input id="reg-phone" type="tel" inputmode="numeric" autocomplete="username"
                                   placeholder="0901234567" required>
                        </div>
                    </div>

                    <div class="cust-field">
                        <label for="reg-password" data-i18n="password">Mật khẩu</label>
                        <div class="cust-input">
                            <span class="cust-input-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="4" y="10.5" width="16" height="10.5" rx="2.4"/>
                                    <path d="M8 10.5V7.4a4 4 0 0 1 8 0v3.1"/>
                                </svg>
                            </span>
                            <input id="reg-password" type="password" autocomplete="new-password" required>
                            <button class="cust-eye" type="button" data-toggle="reg-password"
                                    data-i18n-aria="showPassword" aria-label="Hiện mật khẩu"></button>
                        </div>
                        <div class="cust-meter" id="pw-meter" aria-hidden="true">
                            <span></span><span></span><span></span>
                        </div>
                        <p class="cust-hint" id="pw-hint" data-i18n="passwordHint">Tối thiểu 6 ký tự.</p>
                    </div>

                    <div class="cust-field">
                        <label for="reg-password2" data-i18n="passwordConfirm">Nhập lại mật khẩu</label>
                        <div class="cust-input">
                            <span class="cust-input-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M4.5 12.5 9.5 17.5 19.5 7.5"/>
                                </svg>
                            </span>
                            <input id="reg-password2" type="password" autocomplete="new-password" required>
                            <button class="cust-eye" type="button" data-toggle="reg-password2"
                                    data-i18n-aria="showPassword" aria-label="Hiện mật khẩu"></button>
                        </div>
                    </div>

                    <button class="btn primary big block cust-submit" type="submit"
                            data-i18n="customerRegister">Đăng ký</button>
                </form>

                <div id="message" class="notice hidden cust-message"></div>

                <div class="cust-divider"><span data-i18n="orLabel">hoặc</span></div>

                <a class="btn block cust-guest" href="menu.jsp" data-i18n="continueAsGuest">
                    Tiếp tục gọi món không cần tài khoản
                </a>
            </section>
        </div>
    </main>
    <script src="assets/js/page-customer-login.js?v=loyalty-2"></script>
</body>
</html>
