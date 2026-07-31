/**
 * Đăng nhập nhân viên — chọn tên rồi nhập PIN cá nhân.
 *
 * Thiết kế cũ: chọn "vị trí" (pha chế / thu ngân / bồi bàn) rồi nhập PIN dùng
 * chung. Ai biết PIN cũng vào được bất kỳ vị trí nào, và nhật ký chỉ ghi tên
 * tài khoản vị trí nên không quy được trách nhiệm cho ai.
 *
 * Thiết kế mới: mỗi người một PIN riêng. VAI TRÒ KHÔNG DO NGƯỜI DÙNG CHỌN —
 * server tra bảng phân ca ĐANG DIỄN RA để quyết định. Ngoài giờ ca thì không
 * vào được, trừ khi quản lý nhập PIN mở khoá.
 *
 * Màn này chạy trên máy ở quầy: màn cảm ứng, người dùng đang vội, thường đứng.
 * Vì vậy ưu tiên nút to, trạng thái ca nhìn là hiểu, và bàn phím số trên màn
 * hình thay cho bàn phím ảo của hệ điều hành.
 */

let roster = [];
let chosen = null;
// Phân biệt "gọi API hỏng" với "thật sự không có ai".
// Trước đây cả hai đều hiện cùng một câu, nên một câu SQL lỗi cú pháp trông
// y hệt như quán chưa có nhân viên nào — rất khó lần ra nguyên nhân.
let rosterFailed = false;
let rosterLoading = true;
let searchTerm = '';
// Từ số này trở lên mới bày ô tìm tên: ít hơn thì mắt quét nhanh hơn gõ.
const SEARCH_THRESHOLD = 8;

document.addEventListener('DOMContentLoaded', () => {
    buildPinPad();
    applyI18n();
    startClock();
    bindSearch();
    loadRoster();
});

// i18n.js gọi lại khi đổi ngôn ngữ.
window.renderPage = () => {
    renderRoster();
    tickClock();
    if (chosen) renderChosen();
};

async function loadRoster() {
    renderRoster();
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
    rosterLoading = false;
    renderRoster();
}

/* ── Đồng hồ ────────────────────────────────────────────────────────────
   Ca làm được tính theo giờ, nên giờ hiện tại là thông tin của màn này chứ
   không phải đồ trang trí: ai bị chặn vì "chưa tới ca" sẽ tự đối chiếu được. */
function startClock() {
    tickClock();
    setInterval(tickClock, 15000);
}

function tickClock() {
    const box = document.getElementById('staff-clock');
    if (!box) return;
    box.textContent = new Date().toLocaleTimeString(localeTag(), { hour: '2-digit', minute: '2-digit' });
}

function localeTag() { return lang() === 'en' ? 'en-US' : 'vi-VN'; }

function bindSearch() {
    const box = document.getElementById('staff-search');
    if (!box) return;
    box.addEventListener('input', () => {
        searchTerm = foldAccents(box.value);
        renderRoster();
    });
}

/**
 * Bỏ dấu để gõ "hung" vẫn ra "Hùng". Không ai đứng ở quầy mà chịu khó bật
 * bộ gõ tiếng Việt chỉ để tìm tên mình. Chữ đ phải xử lý riêng vì nó là một
 * chữ cái, không phải d có dấu.
 */
function foldAccents(value) {
    return String(value || '')
        .normalize('NFD')
        .replace(new RegExp('[\\u0300-\\u036f]', 'g'), '')
        .replace(/đ/g, 'd')
        .replace(/Đ/g, 'D')
        .trim()
        .toLowerCase();
}

/* ── Bước 1: chọn người ────────────────────────────────────────────────── */

function renderRoster() {
    const holder = document.getElementById('staff-roster');
    if (!holder) return;
    document.getElementById('roster-date').textContent = tf('rosterToday', { date: todayLabel() });

    const empty = document.getElementById('roster-empty');
    const search = document.getElementById('staff-search');

    // Đang tải: khung xám thay cho khoảng trắng. Màn trắng trơn khiến người ta
    // tưởng hỏng và bấm tải lại giữa chừng.
    if (rosterLoading) {
        holder.innerHTML = '<span class="staff-skeleton"></span>'.repeat(3);
        empty.classList.add('hidden');
        search.classList.add('hidden');
        return;
    }

    search.classList.toggle('hidden', roster.length < SEARCH_THRESHOLD);

    if (!roster.length) {
        holder.innerHTML = '';
        empty.textContent = rosterFailed ? t('rosterLoadFailed') : t('rosterEmpty');
        empty.classList.toggle('notice', rosterFailed);
        empty.classList.toggle('notice-error', rosterFailed);
        empty.classList.remove('hidden');
        return;
    }

    const matched = roster.filter(person =>
        !searchTerm || foldAccents(person.name).includes(searchTerm));

    if (!matched.length) {
        holder.innerHTML = '';
        empty.textContent = t('noMatch');
        empty.classList.remove('notice', 'notice-error');
        empty.classList.remove('hidden');
        return;
    }
    empty.classList.add('hidden');

    // Hai nhóm rõ ràng thay vì một danh sách dài mờ dần. Người đang trong ca
    // là người sắp bấm vào; những người còn lại chỉ cần thấy để biết mình
    // chưa tới lượt, không phải để bấm nhầm rồi đọc thông báo từ chối.
    const onDuty = matched.filter(person => person.onDuty);
    const offDuty = matched.filter(person => !person.onDuty);

    let html = '';
    if (onDuty.length) {
        html += groupLabel(t('onDutyNow'), onDuty.length, 'on');
        html += onDuty.map(tileHtml).join('');
    }
    if (offDuty.length) {
        html += groupLabel(t('offDutyGroup'), offDuty.length, 'off');
        html += offDuty.map(tileHtml).join('');
    }
    holder.innerHTML = html;
}

function groupLabel(text, count, kind) {
    return `<p class="staff-group ${kind}"><span>${escapeText(text)}</span><b>${count}</b></p>`;
}

function tileHtml(person) {
    const status = statusOf(person);
    return `
        <button class="staff-tile ${person.onDuty ? 'on-duty-row' : 'off-duty'}" type="button"
                onclick="pickStaff(${person.id})">
            <span class="staff-avatar">${escapeText(initialOf(person.name))}</span>
            <span class="staff-tile-body">
                <b>${escapeText(person.name)}</b>
                <span class="cust-hint">${escapeText(status.detail)}</span>
            </span>
            <span class="staff-chip ${status.tone}">${escapeText(status.chip)}</span>
        </button>`;
}

/**
 * Trạng thái của một người, gói lại một chỗ để thẻ trong danh sách và thẻ đã
 * chọn ở bước PIN không bao giờ nói hai câu khác nhau về cùng một người.
 *
 *   chip   — nhãn ngắn, đọc lướt là hiểu bấm vào có vào được không
 *   detail — dòng phụ nói rõ vai trò / mấy giờ tới ca
 *   tone   — màu: xanh = vào được, hổ phách = phải chờ, xám = không vào được
 */
function statusOf(person) {
    // Nhãn và dòng phụ không được nói lại cùng một ý: một dòng ngắn đọc lướt
    // được vẫn hơn hai dòng đầy đủ nhưng phải xuống hàng.
    const nextDay = person.nextShiftDate ? tf('nextShiftOn', { date: dayLabel(person.nextShiftDate) }) : '';
    if (person.onDuty) {
        return {
            tone: 'on',
            chip: t('onDutyNow'),
            detail: roleScheduleText(person.todayRole)
                + (person.todayHours ? ' · ' + person.todayHours : '')
        };
    }
    if (person.hasAccount === false) {
        return { tone: 'off', chip: t('noAccountYet'), detail: t('noAccountShort') };
    }
    if (person.upcomingShift) {
        return {
            tone: 'wait',
            chip: t('notYet'),
            detail: shiftText(person.upcomingShift, person.upcomingHours)
        };
    }
    if (person.shiftEnded) {
        return { tone: 'off', chip: t('shiftEnded'), detail: nextDay || t('shiftEndedHint') };
    }
    return { tone: 'off', chip: t('noShiftChip'), detail: nextDay };
}

/** "Ca Tối · 18:00 - 23:00" — tên ca dịch theo ngôn ngữ, kèm khung giờ khi có. */
function shiftText(name, hours) {
    const label = shiftNameText(name);
    return hours ? label + ' · ' + hours : label;
}

/** "2026-08-03" → "03/08". Ngày ISO thô đọc chậm hơn hẳn ngày quen mắt. */
function dayLabel(isoDate) {
    const parts = String(isoDate || '').split('-');
    if (parts.length !== 3) return isoDate;
    return lang() === 'en' ? parts[1] + '/' + parts[2] : parts[2] + '/' + parts[1];
}

/* ── Bước 2: nhập PIN ──────────────────────────────────────────────────── */

function pickStaff(id) {
    chosen = roster.find(p => p.id === id) || null;
    if (!chosen) return;
    document.getElementById('step-who').classList.add('hidden');
    document.getElementById('step-pin').classList.remove('hidden');
    document.getElementById('override-box').classList.add('hidden');
    document.getElementById('pin').value = '';
    document.getElementById('admin-pin').value = '';
    padTarget = 'pin';
    hideMessage();
    renderChosen();
    document.getElementById('pin').focus();
}

function renderChosen() {
    if (!chosen) return;
    const status = statusOf(chosen);
    document.getElementById('chosen-initial').textContent = initialOf(chosen.name);
    document.getElementById('chosen-name').textContent = chosen.name || '';
    document.getElementById('chosen-shift').textContent = status.detail || status.chip;
    const chip = document.getElementById('chosen-chip');
    chip.textContent = status.chip;
    chip.className = 'staff-chip ' + status.tone;

    // Chưa có tài khoản thì nhập PIN cũng không vào được — nói trước cho rõ.
    const submit = document.querySelector('#pin-form button[type="submit"]');
    const noAccount = chosen.hasAccount === false;
    if (submit) submit.disabled = noAccount;
    document.getElementById('pin').disabled = noAccount;
    document.getElementById('pin-pad').classList.toggle('disabled', noAccount);
    if (noAccount) showMessage(t('noAccountHelp'), true); else hideMessage();
}

function backToRoster() {
    chosen = null;
    document.getElementById('step-pin').classList.add('hidden');
    document.getElementById('step-who').classList.remove('hidden');
    hideMessage();
}

/**
 * Bàn phím số trên màn hình.
 *
 * Ô nhập vẫn là input thật nên bàn phím cứng, trình quản lý mật khẩu và
 * autofill đều hoạt động như cũ — bàn phím này chỉ thêm một cách bấm, không
 * thay thế cách nào.
 */
function buildPinPad() {
    const pad = document.getElementById('pin-pad');
    if (!pad) return;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'clear', '0', 'back'];
    pad.innerHTML = keys.map(key => {
        if (key === 'back') return '<button class="pin-key wide" type="button" data-key="back" data-i18n-aria="delete">⌫</button>';
        if (key === 'clear') return '<button class="pin-key wide" type="button" data-key="clear">C</button>';
        return `<button class="pin-key" type="button" data-key="${key}">${key}</button>`;
    }).join('');

    ['pin', 'admin-pin'].forEach(id => {
        const input = document.getElementById(id);
        if (input) input.addEventListener('focus', () => { padTarget = id; });
    });

    pad.addEventListener('click', event => {
        const key = event.target.closest('.pin-key');
        if (!key || pad.classList.contains('disabled')) return;
        const input = activePinInput();
        const action = key.dataset.key;
        if (action === 'back') input.value = input.value.slice(0, -1);
        else if (action === 'clear') input.value = '';
        else if (input.value.length < Number(input.maxLength || 8)) input.value += action;
        input.focus();
    });
}

/**
 * Bàn phím gõ vào ô đang được chọn — PIN cá nhân, hoặc PIN quản lý khi ô đó
 * mở ra và được đưa con trỏ vào. Bám theo focus thay vì tự suy đoán, để bấm
 * vào ô nào là gõ đúng ô đó.
 */
let padTarget = 'pin';

function activePinInput() {
    return document.getElementById(padTarget) || document.getElementById('pin');
}

document.getElementById('pin-form').addEventListener('submit', async event => {
    event.preventDefault();
    if (!chosen) return;
    const button = event.currentTarget.querySelector('button[type="submit"]');
    button.disabled = true;
    button.classList.add('is-busy');
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
            // PIN đúng nhưng đang ngoài giờ ca: mở ô PIN quản lý.
            const box = document.getElementById('override-box');
            box.classList.remove('hidden');
            showMessage(err.error || t('offShiftBlocked'), true);
            document.getElementById('admin-pin').focus();
            // Ô vừa hiện nằm dưới bàn phím số nên rất dễ ở ngoài màn hình.
            box.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        } else {
            showMessage(err.error || t('loginFailed'), true);
            // PIN sai thì xoá hẳn: bấm lại từ đầu trên màn cảm ứng nhanh hơn là
            // xoá từng chữ số của lần gõ hỏng.
            const pin = document.getElementById('pin');
            pin.value = '';
            pin.focus();
            shake();
        }
    } catch (err) {
        showMessage(t('networkError'), true);
    } finally {
        button.disabled = chosen ? chosen.hasAccount === false : false;
        button.classList.remove('is-busy');
    }
});

/** Lắc nhẹ thẻ khi sai PIN — phản hồi thấy được ngay cả khi mắt đang ở bàn phím. */
function shake() {
    const card = document.querySelector('.staff-pin-card');
    if (!card) return;
    card.classList.remove('shake');
    void card.offsetWidth;
    card.classList.add('shake');
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

function initialOf(name) {
    const parts = String(name || '').trim().split(/\s+/);
    if (!parts.length || !parts[0]) return '?';
    return parts[parts.length - 1].charAt(0).toUpperCase();
}

function todayLabel() {
    const now = new Date();
    return now.toLocaleDateString(localeTag(), { weekday: 'long', day: '2-digit', month: '2-digit' });
}

function escapeText(value) {
    return String(value == null ? '' : value)
        .replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}
