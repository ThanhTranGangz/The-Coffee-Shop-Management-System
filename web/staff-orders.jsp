<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=ops-log-1">
    <script defer src="assets/js/i18n.js?v=ops-log-1"></script>
</head>
<body>
    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell work-shell">
        <section class="work-toolbar action-toolbar">
            <button class="stock-chip" id="cup-chip" type="button"></button>
        </section>
        <section class="work-tabs" id="barista-tabs"></section>
        <section class="status-board" id="orders-board"></section>
    </main>

    <script>
        const statuses = ['Pending', 'Preparing', 'Ready'];
        const statusKeys = {
            Pending: 'pendingColumn',
            Preparing: 'preparingColumn',
            Ready: 'readyColumn',
            Served: 'servedColumn'
        };
        let activeStatus = 'Pending';
        let holdTimer = null;
        let holdingCard = null;
        let knownPendingIds = new Set();
        let firstLoad = true;
        let pollTimer = null;
        let sessionRole = '';
        let cupData = { cupsAvailable: 0 };

        document.addEventListener('DOMContentLoaded', async () => {
            rememberWorkPage('staff-orders.jsp');
            await loadSession();
            await loadCupStatus();
            loadOrders();
            pollTimer = setInterval(() => loadOrders({ silent: false }), 5000);
            setInterval(loadCupStatus, 6000);
        });

        async function loadSession() {
            const res = await api('/auth/session');
            const session = res.ok ? await res.json() : {};
            sessionRole = session.role || '';
        }

        async function loadCupStatus() {
            const res = await api('/cups/status');
            if (!res.ok) return;
            cupData = await res.json();
            renderCupChip();
        }

        function renderCupChip() {
            const chip = document.getElementById('cup-chip');
            const editable = sessionRole === 'admin';
            chip.disabled = !editable;
            chip.classList.toggle('editable', editable);
            chip.innerHTML = `<span>${t('cupsAvailable')}</span><b>${Number(cupData.cupsAvailable || 0)}</b>`;
            chip.onclick = editable ? editCupStock : null;
        }

        async function editCupStock() {
            const value = await inputModal({
                title: t('editCupStock'),
                message: t('cupsAvailable'),
                value: String(cupData.cupsAvailable || 0),
                actionLabel: t('save'),
                inputMode: 'numeric'
            });
            if (value === null) return;
            const amount = Number(String(value).replace(/[^\d]/g, ''));
            if (!Number.isFinite(amount) || amount < 0) return;
            const res = await api('/cups/update', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ mode: 'set', amount })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                notifyWork(err.error || t('statusMoveFailed'));
                return;
            }
            cupData = await res.json();
            renderCupChip();
        }

        async function loadOrders(options = {}) {
            const res = await api('/orders?view=barista');
            const orders = await res.json();
            const activeOrders = orders.filter(order => statuses.includes(order.status));
            maybeNotify(activeOrders, options.silent === true);
            renderTabs(activeOrders);
            renderBoard(activeOrders);
        }

        function maybeNotify(orders, silent) {
            const pendingIds = new Set(orders.filter(order => order.status === 'Pending').map(order => Number(order.id)));
            const hasNew = [...pendingIds].some(id => !knownPendingIds.has(id));
            if (!firstLoad && !silent && hasNew) notifyWork(t('newBaristaWork'));
            knownPendingIds = pendingIds;
            firstLoad = false;
        }

        function renderTabs(orders) {
            const tabs = document.getElementById('barista-tabs');
            tabs.dataset.active = String(Math.max(0, statuses.indexOf(activeStatus)));
            tabs.innerHTML = statuses.map(status => {
                const count = orders.filter(order => order.status === status).length;
                const label = t(statusKeys[status]);
                return `<button class="mobile-tab ${activeStatus === status ? 'active' : ''}" title="${label}" onclick="setActiveStatus('${status}')"><span class="tab-label">${label}</span><b>${count}</b></button>`;
            }).join('');
        }

        function renderBoard(orders) {
            const activeOrders = orders.filter(order => order.status === activeStatus);
            const activeLabel = t(statusKeys[activeStatus]);
            document.getElementById('orders-board').innerHTML = `
                <section class="status-col active single-status" id="col-${activeStatus}">
                    <div class="status-col-head">
                        <span>${activeLabel}</span>
                        <b>${activeOrders.length}</b>
                    </div>
                    <div class="status-col-body">
                        ${activeOrders.length ? activeOrders.map(orderHtml).join('') : `<div class="empty-state compact"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`}
                    </div>
                </section>
            `;
        }

        function setActiveStatus(status) {
            activeStatus = status;
            loadOrders({ silent: true });
        }

        function orderHtml(order) {
            const next = nextStatus(order.status);
            return `
                <article class="card order-card hold-card ${next ? '' : 'not-ready'}" data-id="${order.id}" data-next="${next || ''}"
                    onpointerdown="startHold(event, ${order.id}, '${next || ''}')"
                    onpointerup="cancelHold()"
                    onpointercancel="cancelHold()"
                    ontouchstart="startHold(event, ${order.id}, '${next || ''}')"
                    ontouchend="cancelHold()"
                    onmousedown="startHold(event, ${order.id}, '${next || ''}')"
                    onmouseup="cancelHold()"
                    oncontextmenu="return false">
                    <div class="toolbar order-card-head">
                        <div>
                            <p class="eyebrow">${escapeHtml(order.tableName)}</p>
                            <h3>#${order.orderNumber}</h3>
                        </div>
                        <span class="price">${money(order.total)}</span>
                    </div>
                    ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                    <div class="order-lines">
                        ${(order.items || []).map(it => `<p>${escapeHtml(it.itemName)}${it.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(it.itemSize) : ''} x${it.quantity} <span class="price">${money(it.price * it.quantity)}</span></p>`).join('')}
                    </div>
                </article>`;
        }

        function nextStatus(status) {
            if (status === 'Pending') return 'Preparing';
            if (status === 'Preparing') return 'Ready';
            return '';
        }

        async function setStatus(id, status) {
            if (!status) return;
            const res = await api('/orders/status', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({ id, status })
            });
            if (!res.ok) {
                notifyWork(t('statusMoveFailed'));
                return;
            }
            if (status === 'Ready') await loadCupStatus();
            loadOrders({ silent: true });
        }

        function startHold(event, id, next) {
            if (!next) return;
            beginHold(event, () => setStatus(id, next));
        }

        function beginHold(event, action) {
            if (window.PointerEvent && (event.type === 'touchstart' || event.type === 'mousedown')) return;
            if (event.cancelable) event.preventDefault();
            cancelHold();
            holdingCard = event.currentTarget;
            if (holdingCard && event.pointerId !== undefined && holdingCard.setPointerCapture) {
                try { holdingCard.setPointerCapture(event.pointerId); } catch (err) {}
            }
            holdingCard.classList.add('holding');
            holdTimer = setTimeout(async () => {
                const card = holdingCard;
                holdTimer = null;
                if (card) card.classList.add('hold-done');
                await action();
                if (card) card.classList.remove('holding', 'hold-done');
                if (holdingCard === card) holdingCard = null;
            }, 1000);
        }

        function cancelHold() {
            if (holdTimer) clearTimeout(holdTimer);
            holdTimer = null;
            if (holdingCard) holdingCard.classList.remove('holding');
            holdingCard = null;
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        window.renderPage = () => {
            renderCupChip();
            loadOrders({ silent: true });
        };
    </script>
</body>
</html>
