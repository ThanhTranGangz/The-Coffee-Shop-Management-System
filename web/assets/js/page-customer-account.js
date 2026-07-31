let profile = null;
let activePanel = 'orders';
let refreshTimer = null;
let historyRange = '30d'; // today | 7d | 30d | all | custom
let historyFrom = '';
let historyTo = '';

const REFRESH_MS = 10000;

document.addEventListener('DOMContentLoaded', () => {
    applyI18n();
    renderHistoryPresets();
    loadAll();
    startAutoRefresh();
});

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
        silentRefresh();
        startAutoRefresh();
    } else {
        stopAutoRefresh();
    }
});

window.addEventListener('pagehide', stopAutoRefresh);

async function silentRefresh() {
    try {
        const res = await api('/customer/me');
        if (!res.ok) return;
        const fresh = await res.json();
        const pointsChanged = !profile || fresh.points !== profile.points;
        profile = fresh;
        renderProfile();
        if (!pointsChanged) return;
        await loadOrderHistory();
        const pointRes = await api('/customer/points?limit=50');
        if (pointRes.ok) window.pointHistory = await pointRes.json();
        renderPanels();
        if (typeof loadNav === 'function') loadNav();
    } catch (err) {
        // nền — bỏ qua
    }
}

window.renderPage = () => {
    if (profile) renderProfile();
    renderHistoryPresets();
    renderPanels();
};

async function loadAll() {
    const res = await api('/customer/me');
    if (!res.ok) {
        window.location.href = withTab('customer-login.jsp?return=customer-account.jsp');
        return;
    }
    profile = await res.json();
    renderProfile();
    await loadOrderHistory();
    const pointRes = await api('/customer/points?limit=50');
    window.pointHistory = pointRes.ok ? await pointRes.json() : [];
    renderPanels();
}

function historyQuery() {
    const range = resolveHistoryDates();
    const params = new URLSearchParams();
    params.set('limit', '100');
    if (range.from) params.set('from', range.from);
    if (range.to) params.set('to', range.to);
    return '/customer/history?' + params.toString();
}

function resolveHistoryDates() {
    const today = localToday();
    if (historyRange === 'today') return { from: today, to: today };
    if (historyRange === '7d') return { from: addDays(today, -6), to: today };
    if (historyRange === '30d') return { from: addDays(today, -29), to: today };
    if (historyRange === 'custom') return { from: historyFrom || '', to: historyTo || '' };
    return { from: '', to: '' }; // all
}

function localToday() {
    const d = new Date();
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
}

function addDays(yyyyMmDd, delta) {
    const [y, m, d] = yyyyMmDd.split('-').map(Number);
    const dt = new Date(y, m - 1, d);
    dt.setDate(dt.getDate() + delta);
    return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, '0')}-${String(dt.getDate()).padStart(2, '0')}`;
}

async function loadOrderHistory() {
    const res = await api(historyQuery());
    window.orderHistory = res.ok ? await res.json() : [];
}

function renderHistoryPresets() {
    const holder = document.getElementById('history-presets');
    if (!holder) return;
    const presets = [
        ['today', t('rangeToday')],
        ['7d', t('rangeLast7')],
        ['30d', t('rangeLast30')],
        ['all', t('rangeAllTime')],
        ['custom', t('rangeCustom')]
    ];
    holder.innerHTML = presets.map(([key, label]) =>
        `<button type="button" class="history-chip ${historyRange === key ? 'active' : ''}" onclick="setHistoryRange('${key}')">${label}</button>`
    ).join('');
    const custom = document.getElementById('history-custom');
    if (custom) custom.hidden = historyRange !== 'custom';
}

window.setHistoryRange = async function (key) {
    historyRange = key;
    if (key === 'custom') {
        const today = localToday();
        if (!historyFrom) historyFrom = addDays(today, -29);
        if (!historyTo) historyTo = today;
        document.getElementById('history-from').value = historyFrom;
        document.getElementById('history-to').value = historyTo;
    }
    renderHistoryPresets();
    if (key !== 'custom') {
        await loadOrderHistory();
        renderOrders();
    }
};

window.applyCustomHistoryRange = async function () {
    historyFrom = document.getElementById('history-from').value;
    historyTo = document.getElementById('history-to').value;
    if (!historyFrom || !historyTo) {
        notifyWork(t('pickDateRange'));
        return;
    }
    if (historyFrom > historyTo) {
        notifyWork(t('invalidDateRange'));
        return;
    }
    await loadOrderHistory();
    renderOrders();
};

function tierLabel(tier) {
    const map = { Bronze: 'tierBronze', Silver: 'tierSilver', Gold: 'tierGold' };
    return t(map[tier] || 'tierBronze');
}

function currentTierBenefits() {
    const tiers = (profile && profile.rules && profile.rules.tiers) || [];
    const code = profile && profile.tier ? profile.tier : 'Bronze';
    const found = tiers.find(x => x.code === code);
    if (!found) return '';
    const list = lang() === 'en' ? (found.benefitsEn || []) : (found.benefitsVi || []);
    return list[0] || '';
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

    const benefitLine = document.getElementById('loyalty-benefit-line');
    if (benefitLine) {
        const tip = currentTierBenefits();
        benefitLine.textContent = tip
            ? (t('yourTierBenefit') + ': ' + tip)
            : t('tapTierGuide');
    }

    const card = document.getElementById('loyalty-card');
    card.classList.remove('tier-bronze', 'tier-silver', 'tier-gold');
    card.classList.add('tier-' + String(profile.tier || 'Bronze').toLowerCase());

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
        const nextName = profile.nextTier ? tierLabel(profile.nextTier) : '';
        text.textContent = nextName
            ? tf('tierProgressNamed', { amount: money(remaining), tier: nextName })
            : tf('tierProgress', { amount: money(remaining) });
    }

    const nameInput = document.getElementById('profile-name');
    if (nameInput && !nameInput.value) nameInput.value = profile.fullName || '';
}

window.openTierGuide = function () {
    const backdrop = document.getElementById('tier-guide-backdrop');
    const body = document.getElementById('tier-guide-body');
    if (!backdrop || !body || !profile) return;
    const rules = profile.rules || {};
    const tiers = rules.tiers || [];
    const current = profile.tier || 'Bronze';
    const en = lang() === 'en';

    body.innerHTML = `
        <div class="tier-howto card">
            <h3>${t('howPointsWork')}</h3>
            <ul>
                <li>${tf('howEarn', { spend: money(rules.spendPerPoint || 10000) })}</li>
                <li>${tf('howRedeem', { value: money(rules.valuePerPoint || 1000) })}</li>
                <li>${tf('howRedeemCap', { min: rules.minRedeemPoints || 10, max: rules.maxRedeemPercent || 50 })}</li>
                <li>${t('howTierBySpend')}</li>
            </ul>
        </div>
        <div class="tier-guide-list">
            ${tiers.map(tier => {
                const active = tier.code === current;
                const benefits = en ? (tier.benefitsEn || []) : (tier.benefitsVi || []);
                const title = en ? tier.titleEn : tier.titleVi;
                const range = tier.maxSpent == null
                    ? tf('tierFrom', { amount: money(tier.minSpent) })
                    : (tier.minSpent <= 0
                        ? tf('tierUpTo', { amount: money((rules.silverThreshold || 1000000) - 1) })
                        : tf('tierBetween', { from: money(tier.minSpent), to: money(tier.maxSpent) }));
                return `
                <article class="card tier-guide-card ${active ? 'current' : ''} tier-${String(tier.code).toLowerCase()}">
                    <div class="tier-guide-card-head">
                        <div>
                            <p class="eyebrow">${tierLabel(tier.code)}</p>
                            <h3>${escapeHtml(title)}</h3>
                        </div>
                        ${active ? `<span class="cust-chip earn">${t('yourTier')}</span>` : ''}
                    </div>
                    <p class="cust-hint">${range}</p>
                    <ul>${benefits.map(b => `<li>${escapeHtml(b)}</li>`).join('')}</ul>
                </article>`;
            }).join('')}
        </div>
    `;
    backdrop.classList.remove('hidden');
    document.body.classList.add('tier-guide-open');
};

window.closeTierGuide = function () {
    const backdrop = document.getElementById('tier-guide-backdrop');
    if (backdrop) backdrop.classList.add('hidden');
    document.body.classList.remove('tier-guide-open');
};

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
    const holder = document.getElementById('orders-list') || document.getElementById('panel-orders');
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

function escapeHtml(value) {
    return String(value == null ? '' : value)
        .replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}

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
