<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
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
            <a class="btn primary" href="table-transfer.jsp" data-i18n="transferTable">Đổi bàn</a>
        </section>
        <section class="work-tabs two-tabs" id="runner-tabs"></section>
        <section class="runner-work-grid" id="runner-work"></section>
        <section class="card table-map-card" id="runner-table-map"></section>
    </main>

    <script>
        const runnerStatuses = ['Ready', 'Paid'];
        const runnerKeys = { Ready: 'serveColumn', Paid: 'cleaningColumn' };
        let activeRunnerStatus = 'Ready';
        let holdTimer = null;
        let holdingCard = null;
        let knownServingOrders = new Set();
        let knownCleaningTables = new Set();
        let firstLoad = true;

        document.addEventListener('DOMContentLoaded', () => {
            rememberWorkPage('runner.jsp');
            loadWork();
            setInterval(() => loadWork({ silent: false }), 5000);
        });

        async function loadWork(options = {}) {
            const [orderRes, tableRes] = await Promise.all([api('/orders?view=runner'), api('/tables/map')]);
            const orders = orderRes.ok ? await orderRes.json() : [];
            const tables = tableRes.ok ? await tableRes.json() : [];
            const servingOrders = orders.filter(order => order.status === 'Ready');
            const cleaningTables = tables.filter(table => table.status === 'Paid');
            maybeNotify(servingOrders, cleaningTables, options.silent === true);
            renderTabs(servingOrders, cleaningTables);
            renderWork(servingOrders, cleaningTables, tables);
            renderTableMap(tables);
        }

        function maybeNotify(servingOrders, cleaningTables, silent) {
            const servingIds = new Set(servingOrders.map(order => Number(order.id)));
            const tableIds = new Set(cleaningTables.map(table => Number(table.id)));
            const hasNewServing = [...servingIds].some(id => !knownServingOrders.has(id));
            const hasNewCleaning = [...tableIds].some(id => !knownCleaningTables.has(id));
            if (!firstLoad && !silent && (hasNewServing || hasNewCleaning)) notifyWork(t('newWaiterWork'));
            knownServingOrders = servingIds;
            knownCleaningTables = tableIds;
            firstLoad = false;
        }

        function renderTabs(servingOrders, cleaningTables) {
            const counts = { Ready: servingOrders.length, Paid: cleaningTables.length };
            const holder = document.getElementById('runner-tabs');
            holder.dataset.active = String(Math.max(0, runnerStatuses.indexOf(activeRunnerStatus)));
            holder.innerHTML = runnerStatuses.map(status => {
                const label = t(runnerKeys[status]);
                return `<button class="mobile-tab ${activeRunnerStatus === status ? 'active' : ''}" title="${label}" onclick="setActiveRunnerStatus('${status}')"><span class="tab-label">${label}</span><b>${counts[status] || 0}</b></button>`;
            }).join('');
        }

        function renderWork(servingOrders, cleaningTables, tables) {
            const list = activeRunnerStatus === 'Ready' ? servingOrders : cleaningTables;
            document.getElementById('runner-work').innerHTML = list.length
                ? list.map(activeRunnerStatus === 'Ready' ? servingOrderHtml : cleaningTableHtml).join('')
                : `<div class="empty-state"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;
        }

        function setActiveRunnerStatus(status) {
            activeRunnerStatus = status;
            loadWork({ silent: true });
        }

        function servingOrderHtml(order) {
            return `
                <article class="card order-card runner-order-card hold-card"
                    onpointerdown="startOrderHold(event, ${order.id || 0})"
                    onpointerup="cancelHold()"
                    onpointercancel="cancelHold()"
                    ontouchstart="startOrderHold(event, ${order.id || 0})"
                    ontouchend="cancelHold()"
                    onmousedown="startOrderHold(event, ${order.id || 0})"
                    onmouseup="cancelHold()"
                    oncontextmenu="return false">
                    <div class="toolbar order-card-head">
                        <div>
                            <p class="eyebrow">${escapeHtml(order.tableName)}</p>
                            <h3>#${order.orderNumber}</h3>
                        </div>
                        <span class="status ready">${t('serveColumn')}</span>
                    </div>
                    ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                    <div class="order-lines">
                        ${(order.items || []).map(item => `<p>${escapeHtml(item.itemName)}${item.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(item.itemSize) : ''} x${item.quantity}</p>`).join('')}
                    </div>
                </article>`;
        }

        function cleaningTableHtml(table) {
            return `
                <article class="card table-clean-card hold-card" data-table-id="${table.id || 0}"
                    onpointerdown="startTableHold(event, ${table.id || 0})"
                    onpointerup="cancelHold()"
                    onpointercancel="cancelHold()"
                    ontouchstart="startTableHold(event, ${table.id || 0})"
                    ontouchend="cancelHold()"
                    onmousedown="startTableHold(event, ${table.id || 0})"
                    onmouseup="cancelHold()"
                    oncontextmenu="return false">
                    <p class="eyebrow">${t('floor')} ${num(table.floorNo)}</p>
                    <h2>${escapeHtml(tableDisplayName(table.name))}</h2>
                    <span class="status paid">${t('needsCleaning')}</span>
                </article>`;
        }

        function renderTableMap(tables) {
            const groups = {};
            (tables || []).forEach(table => {
                const floor = table.floorNo || 1;
                if (!groups[floor]) groups[floor] = [];
                groups[floor].push(table);
            });
            document.getElementById('runner-table-map').innerHTML = `
                <div class="toolbar compact-toolbar">
                    <div>
                        <p class="eyebrow">${t('tableMap')}</p>
                        <h2>${t('serving')}: ${(tables || []).filter(tb => tb.busy).length}</h2>
                    </div>
                    <span>${(tables || []).length}</span>
                </div>
                <div class="table-map-grid">
                    ${Object.keys(groups).sort().map(floor => `
                        <section class="floor-map">
                            <div class="floor-title">${t('floor')} ${floor}</div>
                            <div class="table-grid-map">
                                ${groups[floor].map(tableTile).join('')}
                            </div>
                        </section>
                    `).join('')}
                </div>
            `;
        }

        function tableTile(table) {
            const status = String(table.status || '');
            const busy = Boolean(table.busy);
            const label = status === 'Paid' ? t('needsCleaning') : (status === 'Served' ? t('unpaid') : (status === 'Ready' ? t('serveColumn') : (busy ? statusText(status) : t('available'))));
            return `
                <div class="table-tile ${busy ? 'busy' : 'free'} ${status === 'Paid' ? 'cleaning' : ''}">
                    <b>${escapeHtml(tableNameShort(table.name))}</b>
                    <span>${escapeHtml(label)}</span>
                </div>
            `;
        }

        async function serveOrder(orderId) {
            if (!orderId) return;
            const res = await api('/orders/status', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({ id: orderId, status: 'Served' })
            });
            if (!res.ok) {
                notifyWork(t('statusMoveFailed'));
                return;
            }
            loadWork({ silent: true });
        }

        async function clearTable(tableId) {
            if (!tableId) return;
            const res = await api('/tables/clear', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({ tableId })
            });
            if (!res.ok) {
                let message = t('statusMoveFailed');
                try {
                    const data = await res.json();
                    if (data && data.error) message = data.error;
                } catch (err) {}
                notifyWork(message);
                return;
            }
            const card = document.querySelector(`.table-clean-card[data-table-id="${tableId}"]`);
            if (card) card.remove();
            notifyWork(t('tableReady'));
            loadWork({ silent: true });
        }

        function startOrderHold(event, id) {
            if (!id) return;
            beginHold(event, () => serveOrder(id));
        }

        function startTableHold(event, id) {
            if (!id) return;
            beginHold(event, () => clearTable(id));
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

        function tableDisplayName(name) {
            const match = String(name || '').match(/Tầng\s*(\d+)\s*-\s*Bàn\s*(\d+)/i);
            return match ? `${t('floor')} ${match[1]} · ${t('table')} ${match[2]}` : name;
        }

        function tableNameShort(name) {
            const match = String(name || '').match(/Bàn\s*(\d+)/i);
            return match ? 'B' + match[1] : name;
        }

        function num(value) {
            return Number(value || 0);
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        window.renderPage = () => loadWork({ silent: true });
    </script>
</body>
</html>
