let activeTab = 'login';

document.addEventListener('DOMContentLoaded', async () => {
    applyI18n();
    bindPasswordToggles();
    bindPasswordMeter();
    // Đã đăng nhập rồi thì không có lý do ở lại trang này.
    try {
        const res = await api('/customer/me');
        if (res.ok) {
            window.location.href = withTab(returnTarget());
            return;
        }
    } catch (err) {}
    document.getElementById('login-phone').focus();
});

/**
 * Sau khi đăng nhập thì quay lại đúng chỗ khách đang đứng.
 * Chỉ chấp nhận vài trang nội bộ đã biết — không nhận URL tuỳ ý từ query
 * string, tránh biến trang đăng nhập thành bàn đạp chuyển hướng ra ngoài.
 */
function returnTarget() {
    const allowed = ['menu.jsp', 'order-status.jsp', 'customer-account.jsp'];
    const raw = new URLSearchParams(window.location.search).get('return') || '';
    const page = raw.split('?')[0].split('/').pop();
    if (!allowed.includes(page)) return 'customer-account.jsp';

    const tableCode = sessionStorage.getItem('selectedTableCode') || '';
    if (page === 'menu.jsp') {
        // menu.jsp bắt buộc phải có mã bàn từ QR, không có thì trang trống trơn.
        // Chưa quét QR thì đưa về trang quét thay vì thả khách vào ngõ cụt.
        return tableCode ? 'menu.jsp?tableCode=' + encodeURIComponent(tableCode) : 'index.html';
    }
    return page;
}

function switchTab(tab) {
    activeTab = tab;
    const isRegister = tab === 'register';
    const loginBtn = document.getElementById('tab-login');
    const registerBtn = document.getElementById('tab-register');

    loginBtn.classList.toggle('active', !isRegister);
    registerBtn.classList.toggle('active', isRegister);
    loginBtn.setAttribute('aria-selected', String(!isRegister));
    registerBtn.setAttribute('aria-selected', String(isRegister));

    // Con trượt nền chạy theo tab đang chọn.
    document.getElementById('switch-thumb').classList.toggle('right', isRegister);

    document.getElementById('login-form').classList.toggle('hidden', isRegister);
    document.getElementById('register-form').classList.toggle('hidden', !isRegister);
    hideMessage();
    document.getElementById(isRegister ? 'reg-name' : 'login-phone').focus();
}

/**
 * Nút con mắt: đổi qua lại giữa type="password" và type="text".
 * Gắn một lần cho mọi nút, kể cả nút nằm trong form đang ẩn.
 */
function bindPasswordToggles() {
    document.querySelectorAll('.cust-eye').forEach(button => {
        button.addEventListener('click', () => {
            const input = document.getElementById(button.dataset.toggle);
            if (!input) return;
            const showing = input.type === 'text';
            input.type = showing ? 'password' : 'text';
            button.classList.toggle('on', !showing);
            button.setAttribute('aria-label', t(showing ? 'showPassword' : 'hidePassword'));
            input.focus();
        });
    });
}

/**
 * Thanh đo độ mạnh mật khẩu — chỉ là gợi ý trực quan cho người dùng.
 * Việc chấp nhận hay từ chối mật khẩu vẫn do PasswordUtils.validate() ở
 * server quyết định; không có gì ở đây được dùng làm căn cứ bảo mật.
 */
function bindPasswordMeter() {
    const input = document.getElementById('reg-password');
    const meter = document.getElementById('pw-meter');
    const hint = document.getElementById('pw-hint');
    if (!input || !meter) return;

    input.addEventListener('input', () => {
        const value = input.value;
        meter.classList.remove('weak', 'medium', 'strong');
        if (!value) {
            hint.textContent = t('passwordHint');
            return;
        }
        let score = 0;
        if (value.length >= 6) score++;
        if (value.length >= 10) score++;
        if (/[a-zA-Z]/.test(value) && /[0-9]/.test(value)) score++;
        if (/[^a-zA-Z0-9]/.test(value)) score++;
        // Mật khẩu toàn một ký tự lặp lại thì luôn là yếu, dài mấy cũng vậy.
        if (new Set(value).size < 2) score = 0;

        const level = score <= 1 ? 'weak' : score === 2 ? 'medium' : 'strong';
        meter.classList.add(level);
        hint.textContent = t(level === 'weak' ? 'pwWeak' : level === 'medium' ? 'pwMedium' : 'pwStrong');
    });
}

function showMessage(text, isError) {
    const box = document.getElementById('message');
    box.textContent = text;
    box.classList.remove('hidden');
    box.classList.toggle('notice-error', !!isError);
}

function hideMessage() {
    document.getElementById('message').classList.add('hidden');
}

function setBusy(form, busy) {
    const button = form.querySelector('button[type="submit"]');
    if (button) button.disabled = busy;
}

document.getElementById('login-form').addEventListener('submit', async event => {
    event.preventDefault();
    const form = event.currentTarget;
    setBusy(form, true);
    hideMessage();
    try {
        const res = await api('/customer/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                phone: document.getElementById('login-phone').value.trim(),
                password: document.getElementById('login-password').value
            })
        });
        if (res.ok) {
            window.location.href = withTab(returnTarget());
        } else {
            const err = await res.json().catch(() => ({}));
            showMessage(err.error || t('loginFailed'), true);
        }
    } catch (err) {
        showMessage(t('networkError'), true);
    } finally {
        setBusy(form, false);
    }
});

document.getElementById('register-form').addEventListener('submit', async event => {
    event.preventDefault();
    const form = event.currentTarget;
    const password = document.getElementById('reg-password').value;
    const confirm = document.getElementById('reg-password2').value;
    // Kiểm tra ở client chỉ để phản hồi nhanh. Server vẫn kiểm lại toàn bộ.
    if (password !== confirm) {
        showMessage(t('passwordMismatch'), true);
        return;
    }
    setBusy(form, true);
    hideMessage();
    try {
        const res = await api('/customer/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                phone: document.getElementById('reg-phone').value.trim(),
                password: password,
                fullName: document.getElementById('reg-name').value.trim()
            })
        });
        if (res.ok) {
            window.location.href = withTab(returnTarget());
        } else {
            const err = await res.json().catch(() => ({}));
            showMessage(err.error || t('registerFailed'), true);
        }
    } catch (err) {
        showMessage(t('networkError'), true);
    } finally {
        setBusy(form, false);
    }
});
