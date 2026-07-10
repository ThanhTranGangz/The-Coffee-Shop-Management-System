        const runnerStatuses = ['Ready', 'Paid'];
        const runnerKeys = { Ready: 'serveColumn', Paid: 'cleaningColumn' };
        let activeRunnerStatus = 'Ready';
        let holdTimer = null;
        let holdingCard = null;
        let knownServingOrders = new Set();
        let knownCleaningTables = new Set();
        let firstLoad = true;
        let runnerOrders = [];
        let runnerTables = [];
        const servingInProgress = new Set();
        const clearingInProgress = new Set();

        document.addEventListener('DOMContentLoaded', () => {
            rememberWorkPage('runner.jsp');
            const backdrop = document.getElementById('invoice-backdrop');
            if (backdrop) {
                backdrop.addEventListener('click', event => {
                    if (event.target.id === 'invoice-backdrop') closeInvoice();
                });
            }
            loadWork();
            setInterval(() => loadWork({ silent: false }), 5000);
        });

        async function loadWork(options = {}) {
            const [orderRes, tableRes] = await Promise.all([api('/orders?view=runner'), api('/tables/map')]);
            runnerOrders = orderRes.ok ? await orderRes.json() : [];
            runnerTables = tableRes.ok ? await tableRes.json() : [];
            const servingOrders = currentServingOrders();
            const cleaningTables = currentCleaningTables();
            maybeNotify(servingOrders, cleaningTables, options.silent === true);
            renderCurrentWork();
        }

        function currentServingOrders() {
            return runnerOrders.filter(order => order.status === 'Ready');
        }

        function currentCleaningTables() {
            return runnerTables.filter(table => table.status === 'Paid');
        }

        function renderCurrentWork() {
            const servingOrders = currentServingOrders();
            const cleaningTables = currentCleaningTables();
            renderTabs(servingOrders, cleaningTables);
            renderWork(servingOrders, cleaningTables, runnerTables);
            renderTableMap(runnerTables);
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
                    <div class="links runner-card-actions">
                        <button class="btn print-invoice-btn" type="button"
                            onpointerdown="event.stopPropagation()" onmousedown="event.stopPropagation()" ontouchstart="event.stopPropagation()"
                            onclick="event.stopPropagation(); openInvoice(${order.id || 0})">${t('printInvoice')}</button>
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
            if (!orderId || servingInProgress.has(Number(orderId))) return;
            servingInProgress.add(Number(orderId));
            try {
                const res = await api('/orders/status', {
                    method:'POST',
                    headers:{'Content-Type':'application/json'},
                    body: JSON.stringify({ id: orderId, status: 'Served' })
                });
                if (!res.ok) {
                    notifyWork(t('statusMoveFailed'));
                    return;
                }
                const updated = await res.json().catch(() => ({}));
                const tableName = updated.tableName || (runnerOrders.find(order => Number(order.id) === Number(orderId)) || {}).tableName || '';
                runnerOrders = runnerOrders.filter(order => Number(order.id) !== Number(orderId));
                runnerTables = runnerTables.map(table => String(table.name || '') === String(tableName)
                    ? Object.assign({}, table, { status: 'Served', busy: true, orderId, orderNumber: updated.orderNumber || table.orderNumber })
                    : table);
                renderCurrentWork();
                loadWork({ silent: true });
            } finally {
                servingInProgress.delete(Number(orderId));
            }
        }

        async function clearTable(tableId) {
            if (!tableId || clearingInProgress.has(Number(tableId))) return;
            clearingInProgress.add(Number(tableId));
            try {
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
                runnerTables = runnerTables.map(table => Number(table.id) === Number(tableId)
                    ? Object.assign({}, table, { status: null, busy: false, orderId: null, orderNumber: null })
                    : table);
                renderCurrentWork();
                notifyWork(t('tableReady'));
                loadWork({ silent: true });
            } finally {
                clearingInProgress.delete(Number(tableId));
            }
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
            }, 500);
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

        async function openInvoice(orderId) {
            if (!orderId) return;
            cancelHold();
            try {
                const res = await api('/orders/invoice?id=' + encodeURIComponent(orderId));
                if (!res.ok) {
                    notifyWork(t('invoiceLoadFailed'));
                    return;
                }
                const order = await res.json();
                renderInvoice(order);
                const backdrop = document.getElementById('invoice-backdrop');
                backdrop.hidden = false;
                document.body.classList.add('invoice-open');
            } catch (err) {
                notifyWork(t('invoiceLoadFailed'));
            }
        }

        function closeInvoice() {
            const backdrop = document.getElementById('invoice-backdrop');
            if (!backdrop) return;
            backdrop.hidden = true;
            document.body.classList.remove('invoice-open');
            document.getElementById('invoice-sheet').innerHTML = '';
        }

        function renderInvoice(order) {
            const items = order.items || [];
            document.getElementById('invoice-sheet').innerHTML = `
                <div class="invoice-print-area">
                    <div class="invoice-brand">coffeshop</div>
                    <div class="invoice-meta">
                        <div>
                            <p class="eyebrow">${t('table')}</p>
                            <strong>${escapeHtml(order.tableName)}</strong>
                        </div>
                        <div>
                            <p class="eyebrow">${t('orderNumber')}</p>
                            <strong>#${escapeHtml(order.orderNumber)}</strong>
                        </div>
                        <div>
                            <p class="eyebrow">${t('invoiceDate')}</p>
                            <strong>${escapeHtml(formatInvoiceTime(order.createdAt))}</strong>
                        </div>
                    </div>
                    ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                    <div class="order-lines invoice-lines">
                        ${items.map(item => `
                            <p>
                                <span>${escapeHtml(item.itemName)}${item.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(item.itemSize) : ''} x${item.quantity}</span>
                                <span class="price">${money(Number(item.price || 0) * Number(item.quantity || 0))}</span>
                            </p>
                        `).join('')}
                    </div>
                    <div class="cart-total invoice-total">
                        <span>${t('total')}</span>
                        <b class="price">${money(order.total)}</b>
                    </div>
                    <p class="invoice-pay-hint">${t('invoicePayHint')}</p>
                </div>
            `;
        }

        function formatInvoiceTime(value) {
            if (!value) return '—';
            const date = new Date(value);
            if (Number.isNaN(date.getTime())) return String(value);
            return date.toLocaleString(lang() === 'en' ? 'en-US' : 'vi-VN');
        }

        function printInvoiceSheet() {
            window.print();
        }

        window.renderPage = () => loadWork({ silent: true });
        window.openInvoice = openInvoice;
        window.closeInvoice = closeInvoice;
        window.printInvoiceSheet = printInvoiceSheet;
