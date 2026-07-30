/**
 * Đăng nhập nhân viên — chọn tên rồi nhập PIN cá nhân.
 *
 * Thiết kế cũ: chọn "vị trí" (pha chế / thu ngân / bồi bàn) rồi nhập PIN dùng
 * chung. Ai biết PIN cũng vào được bất kỳ vị trí nào, và nhật ký chỉ ghi tên
 * tài khoản vị trí nên không quy được trách nhiệm cho ai.
 *
 * Thiết kế mới: mỗi người một PIN riêng. VAI TRÒ KHÔNG DO NGƯỜI DÙNG CHỌN —
 * server tra bảng phân ca của hôm nay để quyết định. Không có ca thì không
 * vào được, trừ khi quản lý nhập PIN mở khoá.
 */

let roster = [];
let chosen = null;
// Phân biệt "gọi API hỏng" với "thật sự không có ai".
// Trước đây cả hai đều hiện cùng một câu, nên một câu SQL lỗi cú pháp trông
// y hệt như quán chưa có nhân viên nào — rất khó lần ra nguyên nhân.
let rosterFailed = false;

document.addEventListener('DOMContentLoaded', () => {
    applyI18n();
    loadRoster();
});

// i18n.js gọi lại khi đổi ngôn ngữ.
window.renderPage = () => {
    renderRoster();
    if (chosen) renderChosen();
};

async function loadRoster() {
    try {
        const res = await api('/staff/roster');
        rosterFailed = !res.ok;
        roster = res.ok ? await res.json() : [];
        if (!res.ok) console.error('[staff-login] /staff/roster trả về HTTP ' + res.status);
    } catch (err) {
        rosterFailed = true;
        roster = [];
        console.error('[staff-login] không gọi được /staff/roster:', err);
    }
    renderRoster();
}

function renderRoster() {
    const holder = document.getElementById('staff-roster');
    if (!holder) return;
    document.getElementById('roster-date').textContent = tf('rosterToday', { date: todayLabel() });

    const empty = document.getElementById('roster-empty');
    if (!roster.length) {
        holder.innerHTML = '';
        empty.textContent = rosterFailed ? t('rosterLoadFailed') : t('rosterEmpty');
        empty.classList.toggle('notice', rosterFailed);
        empty.classList.toggle('notice-error', rosterFailed);
        empty.classList.remove('hidden');
        return;
    }
    empty.classList.add('hidden');

    // Người có ca hôm nay xếp lên trước — đó là những người sắp bấm vào.
    const sorted = roster.slice().sort((a, b) => (b.onDuty ? 1 : 0) - (a.onDuty ? 1 : 0));
    holder.innerHTML = sorted.map(person => `
        <button class="staff-tile ${person.onDuty ? '' : 'off-duty'}" type="button"
                onclick="pickStaff(${person.id})">
            <span class="staff-avatar">${escapeText(initialOf(person.name))}</span>
            <span class="staff-tile-body">
                <b>${escapeText(person.name)}</b>
                <span class="cust-hint">${subtitleFor(person)}</span>
            </span>
        </button>`).join('');
}

/**
 * Dòng phụ dưới tên. Ba trạng thái phải phân biệt được ngay từ danh sách,
 * đừng để người dùng bấm vào rồi mới biết mình không vào được:
 *   • có ca hôm nay  → vai trò + tên ca
 *   • chưa có tài khoản → nói thẳng, vì gõ PIN bao nhiêu lần cũng vô ích
 *   • không có ca hôm nay → kèm ngày ca gần nhất để biết mình nhớ nhầm ngày
 */
function subtitleFor(person) {
    if (person.onDuty) {
        return escapeText(roleScheduleText(person.todayRole))
            + (person.todayShift ? ' · ' + escapeText(person.todayShift) : '');
    }
    if (person.hasAccount === false) return t('noAccountYet');
    if (person.nextShiftDate) return tf('nextShiftOn', { date: escapeText(person.nextShiftDate) });
    return t('noShiftToday');
}

function pickStaff(id) {
    chosen = roster.find(p => p.id === id) || null;
    if (!chosen) return;
    document.getElementById('step-who').classList.add('hidden');
    document.getElementById('step-pin').classList.remove('hidden');
    document.getElementById('override-box').classList.add('hidden');
    document.getElementById('pin').value = '';
    document.getElementById('admin-pin').value = '';
    hideMessage();
    renderChosen();
    document.getElementById('pin').focus();
}

function renderChosen() {
    if (!chosen) return;
    document.getElementById('chosen-initial').textContent = initialOf(chosen.name);
    document.getElementById('chosen-name').textContent = chosen.name || '';
    document.getElementById('chosen-shift').textContent = chosen.onDuty
        ? roleScheduleText(chosen.todayRole) + (chosen.todayHours ? ' · ' + chosen.todayHours : '')
        : (chosen.hasAccount === false ? t('noAccountYet')
            : chosen.nextShiftDate ? tf('nextShiftOn', { date: chosen.nextShiftDate }) : t('noShiftToday'));

    // Chưa có tài khoản thì nhập PIN cũng không vào được — nói trước cho rõ.
    const submit = document.querySelector('#pin-form button[type="submit"]');
    const noAccount = chosen.hasAccount === false;
    if (submit) submit.disabled = noAccount;
    document.getElementById('pin').disabled = noAccount;
    if (noAccount) showMessage(t('noAccountHelp'), true); else hideMessage();
}

function backToRoster() {
    chosen = null;
    document.getElementById('step-pin').classList.add('hidden');
    document.getElementById('step-who').classList.remove('hidden');
    hideMessage();
}

document.getElementById('pin-form').addEventListener('submit', async event => {
    event.preventDefault();
    if (!chosen) return;
    const button = event.currentTarget.querySelector('button[type="submit"]');
    button.disabled = true;
    hideMessage();

    const overrideVisible = !document.getElementById('override-box').classList.contains('hidden');
    const payload = {
        staffId: chosen.id,
        pin: document.getElementById('pin').value
    };
    // Chỉ gửi PIN quản lý khi ô đó thực sự đang hiện.
    if (overrideVisible) payload.adminPin = document.getElementById('admin-pin').value;

    try {
        const res = await api('/auth/staff-login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            const session = await res.json();
            const targetByRole = {
                barista: 'staff-orders.jsp',
                cashier: 'cashier.jsp',
                runner: 'runner.jsp',
                admin: 'dashboard.jsp'
            };
            window.location.href = withTab(targetByRole[session.role] || 'staff-login.jsp');
            return;
        }

        const err = await res.json().catch(() => ({}));
        if (res.status === 409) {
            // PIN đúng nhưng hôm nay không có ca: mở ô PIN quản lý.
            document.getElementById('override-box').classList.remove('hidden');
            showMessage(err.error || t('offShiftBlocked'), true);
            document.getElementById('admin-pin').focus();
        } else {
            showMessage(err.error || t('loginFailed'), true);
            document.getElementById('pin').select();
        }
    } catch (err) {
        showMessage(t('networkError'), true);
    } finally {
        button.disabled = false;
    }
});

function showMessage(text, isError) {
    const box = document.getElementById('message');
    box.textContent = text;
    box.classList.remove('hidden');
    box.classList.toggle('notice-error', !!isError);
}

function hideMessage() {
    document.getElementById('message').classList.add('hidden');
}

function initialOf(name) {
    const parts = String(name || '').trim().split(/\s+/);
    if (!parts.length || !parts[0]) return '?';
    return parts[parts.length - 1].charAt(0).toUpperCase();
}

function todayLabel() {
    const now = new Date();
    return now.toLocaleDateString(lang() === 'en' ? 'en-US' : 'vi-VN',
        { weekday: 'long', day: '2-digit', month: '2-digit' });
}

function escapeText(value) {
    return String(value == null ? '' : value)
        .replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}
