let profile = null;
let activePanel = 'orders';
let refreshTimer = null;

const REFRESH_MS = 10000;   // cùng nhịp với page-order-status.js (5s) nhưng thưa hơn

document.addEventListener('DOMContentLoaded', () => {
    applyI18n();
    loadAll();
    startAutoRefresh();
});

/**
 * Điểm chỉ được cộng khi thu ngân chuyển đơn sang "Đã thanh toán" — việc đó
 * xảy ra ở máy khác, trang này không thể biết. Nên phải hỏi lại server định kỳ.
 *
 * Chỉ chạy khi tab đang hiển thị: khách khoá màn hình rồi để đó cả buổi thì
 * không có lý do gì bắn request mỗi 10 giây.
 */
function startAutoRefresh() {
    stopAutoRefresh();
    if (document.visibilityState !== 'visible') return;
    refreshTimer = setInterval(silentRefresh, REFRESH_MS);
}

function stopAutoRefresh() {
    if (refreshTimer) clearInterval(refreshTimer);
    refreshTimer = null;
}

document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
        silentRefresh();      // cập nhật ngay khi khách quay lại, không đợi hết 10s
        startAutoRefresh();
    } else {
        stopAutoRefresh();
    }
});

window.addEventListener('pagehide', stopAutoRefresh);

/**
 * Làm mới ngầm. Khác loadAll() ở chỗ KHÔNG chuyển hướng khi lỗi:
 * rớt mạng một nhịp thì giữ nguyên số liệu đang hiển thị, chứ đá khách
 * ra trang đăng nhập giữa chừng là hành vi tệ.
 */
async function silentRefresh() {
    try {
        const res = await api('/customer/me');
        if (!res.ok) return;
        const fresh = await res.json();
        const pointsChanged = !profile || fresh.points !== profile.points;
        profile = fresh;
        renderProfile();

        // Điểm chỉ đổi khi có đơn được thanh toán hoặc dùng điểm,
        // nên chỉ lúc đó mới cần tải lại hai danh sách phía dưới.
        if (!pointsChanged) return;
        const [orderRes, pointRes] = await Promise.all([
            api('/customer/history?limit=50'),
            api('/customer/points?limit=50')
        ]);
        if (orderRes.ok) window.orderHistory = await orderRes.json();
        if (pointRes.ok) window.pointHistory = await pointRes.json();
        renderPanels();
        if (typeof loadNav === 'function') loadNav();
    } catch (err) {
        // Im lặng bỏ qua: đây là làm mới nền, không phải thao tác của khách.
    }
}

// i18n.js gọi lại hàm này mỗi khi đổi ngôn ngữ.
window.renderPage = () => {
    if (profile) renderProfile();
    renderPanels();
};

async function loadAll() {
    const res = await api('/customer/me');
    if (!res.ok) {
        // Chưa đăng nhập: đưa về trang đăng nhập, nhớ đường quay lại.
        window.location.href = withTab('customer-login.jsp?return=customer-account.jsp');
        return;
    }
    profile = await res.json();
    renderProfile();

    const [orderRes, pointRes] = await Promise.all([
        api('/customer/history?limit=50'),
        api('/customer/points?limit=50')
    ]);
    window.orderHistory = orderRes.ok ? await orderRes.json() : [];
    window.pointHistory = pointRes.ok ? await pointRes.json() : [];
    renderPanels();
}

function tierLabel(tier) {
    const map = { Bronze: 'tierBronze', Silver: 'tierSilver', Gold: 'tierGold' };
    return t(map[tier] || 'tierBronze');
}

function renderProfile() {
    if (!profile) return;
    document.getElementById('loyalty-tier').textContent = tierLabel(profile.tier);
    document.getElementById('loyalty-name').textContent = profile.fullName || '—';
    document.getElementById('loyalty-phone').textContent = profile.phone || '';
    document.getElementById('loyalty-points').textContent = Number(profile.points || 0).toLocaleString('vi-VN');
    document.getElementById('loyalty-points-value').textContent = '≈ ' + money(profile.pointsValue);
    document.getElementById('loyalty-spent').textContent = money(profile.totalSpent);
    document.getElementById('loyalty-orders').textContent = Number(profile.orderCount || 0);
    document.getElementById('loyalty-since').textContent = shortDate(profile.createdAt);

    const card = document.getElementById('loyalty-card');
    card.classList.remove('tier-bronze', 'tier-silver', 'tier-gold');
    card.classList.add('tier-' + String(profile.tier || 'Bronze').toLowerCase());

    // Thanh tiến độ lên hạng kế tiếp.
    const rules = profile.rules || {};
    const remaining = Number(profile.spentToNextTier || 0);
    const spent = Number(profile.totalSpent || 0);
    const fill = document.getElementById('loyalty-bar-fill');
    const text = document.getElementById('loyalty-progress-text');
    if (remaining <= 0) {
        fill.style.width = '100%';
        text.textContent = t('tierMaxReached');
    } else {
        const target = spent + remaining;
        const floor = target === rules.goldThreshold ? (rules.silverThreshold || 0) : 0;
        const span = Math.max(1, target - floor);
        const percent = Math.max(4, Math.min(100, Math.round((spent - floor) / span * 100)));
        fill.style.width = percent + '%';
        text.textContent = tf('tierProgress', { amount: money(remaining) });
    }

    const nameInput = document.getElementById('profile-name');
    if (nameInput && !nameInput.value) nameInput.value = profile.fullName || '';
}

function switchPanel(panel) {
    activePanel = panel;
    ['orders', 'points', 'settings'].forEach(name => {
        document.getElementById('tab-' + name).classList.toggle('active', name === panel);
        document.getElementById('panel-' + name).classList.toggle('hidden', name !== panel);
    });
}

function renderPanels() {
    renderOrders();
    renderPoints();
}

function renderOrders() {
    const holder = document.getElementById('panel-orders');
    const orders = window.orderHistory || [];
    if (!orders.length) {
        holder.innerHTML = `<div class="card empty-note">${t('noOrderHistory')}</div>`;
        return;
    }
    holder.innerHTML = orders.map(order => {
        const lines = (order.items || []).map(item => `
            <div class="cust-line">
                <span>${escapeHtml(item.itemName)}${item.itemSize ? ' · ' + escapeHtml(item.itemSize) : ''} × ${item.quantity}</span>
                <span>${money(item.price * item.quantity)}</span>
            </div>`).join('');
        const discountRow = order.discountAmount > 0 ? `
            <div class="cust-line discount">
                <span>${tf('discountByPoints', { points: order.pointsRedeemed })}</span>
                <span>− ${money(order.discountAmount)}</span>
            </div>` : '';
        const earnedTag = order.pointsEarned > 0
            ? `<span class="cust-chip earn">+${order.pointsEarned} ${t('points')}</span>` : '';
        return `
        <article class="card cust-order">
            <div class="cust-order-head">
                <div>
                    <b>#${order.orderNumber}</b>
                    <span class="cust-hint"> · ${escapeHtml(formatTableName(order.tableName) || order.tableName || '')}</span>
                </div>
                <div class="cust-order-meta">
                    <span class="cust-chip">${statusText(order.status)}</span>
                    ${earnedTag}
                </div>
            </div>
            <p class="cust-hint">${shortDateTime(order.createdAt)}</p>
            <div class="cust-lines">${lines}${discountRow}</div>
            <div class="cust-line total">
                <span>${t('total')}</span>
                <b class="price">${money(order.total)}</b>
            </div>
        </article>`;
    }).join('');
}

function renderPoints() {
    const holder = document.getElementById('panel-points');
    const list = window.pointHistory || [];
    if (!list.length) {
        holder.innerHTML = `<div class="card empty-note">${t('noPointHistory')}</div>`;
        return;
    }
    holder.innerHTML = list.map(tx => {
        const positive = Number(tx.points) > 0;
        const label = tx.type === 'EARN' ? t('pointEarned')
            : tx.type === 'REDEEM' ? t('pointRedeemed') : t('pointAdjusted');
        return `
        <article class="card cust-point ${positive ? 'earn' : 'spend'}">
            <div class="cust-order-head">
                <div>
                    <b>${label}</b>
                    ${tx.orderNumber ? `<span class="cust-hint"> · ${t('orderNumber')} #${tx.orderNumber}</span>` : ''}
                </div>
                <b class="cust-point-delta">${positive ? '+' : ''}${tx.points}</b>
            </div>
            <p class="cust-hint">${shortDateTime(tx.createdAt)} · ${t('balanceAfter')}: ${tx.balanceAfter}</p>
        </article>`;
    }).join('');
}

// ── Cài đặt tài khoản ───────────────────────────────────────────────

document.getElementById('profile-form').addEventListener('submit', async event => {
    event.preventDefault();
    const box = document.getElementById('profile-message');
    const res = await api('/customer/profile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ fullName: document.getElementById('profile-name').value.trim() })
    });
    const data = await res.json().catch(() => ({}));
    if (res.ok) {
        profile = data;
        renderProfile();
        showBox(box, t('saved'), false);
    } else {
        showBox(box, data.error || t('saveFailed'), true);
    }
});

document.getElementById('password-form').addEventListener('submit', async event => {
    event.preventDefault();
    const box = document.getElementById('password-message');
    const next = document.getElementById('new-password').value;
    if (next !== document.getElementById('new-password2').value) {
        showBox(box, t('passwordMismatch'), true);
        return;
    }
    const res = await api('/customer/password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            oldPassword: document.getElementById('old-password').value,
            newPassword: next
        })
    });
    const data = await res.json().catch(() => ({}));
    if (res.ok) {
        document.getElementById('password-form').reset();
        showBox(box, t('passwordChanged'), false);
    } else {
        showBox(box, data.error || t('saveFailed'), true);
    }
});

async function customerLogout() {
    await api('/customer/logout', { method: 'POST' });
    window.location.href = withTab('menu.jsp');
}

function showBox(box, text, isError) {
    box.textContent = text;
    box.classList.remove('hidden');
    box.classList.toggle('notice-error', !!isError);
}

// ── Tiện ích ────────────────────────────────────────────────────────

function escapeHtml(value) {
    return String(value == null ? '' : value)
        .replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}

/** SQL Server trả DATETIME2 dạng "2026-07-30 08:15:00.0" — Date không parse được chuỗi này trên Safari. */
function parseServerDate(raw) {
    const text = String(raw || '').trim();
    if (!text) return null;
    const m = text.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?/);
    if (!m) return null;
    return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]), Number(m[6] || 0));
}

function shortDate(raw) {
    const date = parseServerDate(raw);
    if (!date) return '—';
    return date.toLocaleDateString(lang() === 'en' ? 'en-US' : 'vi-VN', { month: 'short', year: 'numeric' });
}

function shortDateTime(raw) {
    const date = parseServerDate(raw);
    if (!date) return '—';
    return date.toLocaleString(lang() === 'en' ? 'en-US' : 'vi-VN', {
        day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
    });
}
