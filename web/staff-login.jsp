<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
        <meta name="page-title-key" content="loginTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=staff-login-2">
    <script defer src="assets/js/i18n.js?v=staff-login-2"></script>
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
                <div class="staff-head">
                    <div>
                        <p class="eyebrow" data-i18n="pickYourself">Chọn tên của bạn</p>
                        <p class="cust-hint" id="roster-date"></p>
                    </div>
                    <!-- Đồng hồ: người bị chặn vì ngoài ca cần thấy ngay bây giờ
                         là mấy giờ để tự hiểu vì sao, khỏi phải đoán. -->
                    <span class="staff-clock" id="staff-clock"></span>
                </div>

                <!-- Ô tìm tên chỉ hiện khi danh sách dài; quán ít người mà bày ra
                     thì chỉ tổ thêm một thứ để nhìn. -->
                <input id="staff-search" class="staff-search hidden" type="search" autocomplete="off"
                       data-i18n-placeholder="searchStaff" placeholder="Tìm tên…"
                       data-i18n-aria="searchStaff" aria-label="Tìm tên">

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
                    <div class="staff-chosen-body">
                        <b id="chosen-name"></b>
                        <span class="cust-hint" id="chosen-shift"></span>
                    </div>
                    <!-- Nhãn trạng thái lặp lại ở đây để người đang ngoài ca biết
                         trước khi gõ hết PIN rồi mới bị từ chối. -->
                    <span class="staff-chip" id="chosen-chip"></span>
                </div>

                <form id="pin-form" class="auth-form staff-pin-form">
                    <div>
                        <label for="pin" data-i18n="personalPin">Mã PIN cá nhân</label>
                        <input id="pin" class="pin-display" type="password" inputmode="numeric" pattern="[0-9]*"
                               autocomplete="one-time-code" maxlength="8" required>
                        <!-- Bàn phím số trên màn hình: máy ở quầy là màn cảm ứng,
                             bấm phím to hơn nhiều so với gõ bàn phím ảo của hệ điều hành.
                             Ô nhập vẫn gõ được bằng bàn phím cứng như cũ. -->
                        <div class="pin-pad" id="pin-pad"></div>
                    </div>

                    <!-- Chỉ hiện khi PIN đúng nhưng người này đang ngoài giờ ca -->
                    <div id="override-box" class="hidden">
                        <label for="admin-pin" data-i18n="managerPin">PIN quản lý</label>
                        <input id="admin-pin" type="password" inputmode="numeric" pattern="[0-9]*" maxlength="8">
                        <p class="cust-hint" data-i18n="overrideHint">
                            Người này đang ngoài giờ ca. Quản lý nhập PIN để mở khoá.
                        </p>
                    </div>

                    <div id="message" class="notice hidden" role="status" aria-live="polite"></div>
                    <button class="btn primary big block auth-submit" type="submit" data-i18n="login">Đăng nhập</button>
                </form>
            </section>
        </section>
    </main>
    <script src="assets/js/page-staff-login.js?v=staff-login-2"></script>
</body>
</html>
