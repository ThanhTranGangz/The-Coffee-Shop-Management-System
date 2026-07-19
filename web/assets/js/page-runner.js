        const runnerStatuses = ['Ready', 'Paid'];
        const runnerKeys = { Ready: 'serveColumn', Paid: 'cleaningColumn' };
        const PRINTED_INVOICE_KEY = 'runner_printed_invoices';
        let activeRunnerStatus = 'Ready';
        let holdTimer = null;
        let holdingCard = null;
        let knownServingOrders = new Set();
        let knownCleaningTables = new Set();
        let firstLoad = true;
        let runnerOrders = [];
        let runnerTables = [];
        let currentInvoiceOrderId = 0;
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
            syncPrintedInvoiceIdsFromOrders(runnerOrders);
            const servingOrders = currentServingOrders();
            const cleaningTables = currentCleaningTables();
            maybeNotify(servingOrders, cleaningTables, options.silent === true);
            renderCurrentWork();
        }

        function currentServingOrders() {
            return runnerOrders.filter(order => order.status === 'Ready');
        }

        function currentReprintOrders() {
            return runnerOrders.filter(order => order.status === 'Served');
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
            const holder = document.getElementById('runner-work');
            if (activeRunnerStatus !== 'Ready') {
                holder.innerHTML = cleaningTables.length
                    ? cleaningTables.map(cleaningTableHtml).join('')
                    : `<div class="empty-state"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;
                return;
            }
            const reprintOrders = currentReprintOrders();
            if (!servingOrders.length && !reprintOrders.length) {
                holder.innerHTML = `<div class="empty-state"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;
                return;
            }
            let html = servingOrders.map(servingOrderHtml).join('');
            if (reprintOrders.length) {
                html += `
                    <div class="runner-reprint-head">
                        <div class="cat-head">
                            <h2>${t('reprintInvoice')}</h2>
                            <span class="line"></span>
                        </div>
                        <p class="runner-reprint-hint">${t('reprintInvoiceHint')}</p>
                    </div>
                    ${reprintOrders.map(reprintOrderHtml).join('')}
                `;
            }
            holder.innerHTML = html;
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

        function reprintOrderHtml(order) {
            return `
                <article class="card order-card runner-order-card runner-reprint-card">
                    <div class="toolbar order-card-head">
                        <div>
                            <p class="eyebrow">${escapeHtml(order.tableName)}</p>
                            <h3>#${order.orderNumber}</h3>
                        </div>
                        <span class="status served">${t('unpaid')}</span>
                    </div>
                    ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                    <div class="order-lines">
                        ${(order.items || []).map(item => `<p>${escapeHtml(item.itemName)}${item.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(item.itemSize) : ''} x${item.quantity}</p>`).join('')}
                    </div>
                    <div class="links runner-card-actions">
                        <button class="btn print-invoice-btn" type="button"
                            onclick="openInvoice(${order.id || 0})">${t('printInvoice')}</button>
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

        function readPrintedInvoiceIds() {
            try {
                const raw = sessionStorage.getItem(PRINTED_INVOICE_KEY);
                const list = raw ? JSON.parse(raw) : [];
                return Array.isArray(list) ? list.map(Number).filter(id => id > 0) : [];
            } catch (err) {
                return [];
            }
        }

        function orderInvoicePrinted(order) {
            if (!order) return false;
            return order.invoicePrinted === true || order.invoicePrinted === 1 || order.invoicePrinted === '1';
        }

        function syncPrintedInvoiceIdsFromOrders(orders) {
            const ids = new Set(readPrintedInvoiceIds());
            (orders || []).forEach(order => {
                if (orderInvoicePrinted(order) && Number(order.id) > 0) ids.add(Number(order.id));
            });
            sessionStorage.setItem(PRINTED_INVOICE_KEY, JSON.stringify([...ids]));
        }

        function isInvoicePrinted(orderId) {
            const id = Number(orderId);
            if (!id) return false;
            const order = runnerOrders.find(item => Number(item.id) === id);
            if (orderInvoicePrinted(order)) return true;
            return readPrintedInvoiceIds().includes(id);
        }

        function rememberInvoicePrintedLocally(orderId) {
            const id = Number(orderId);
            if (!id) return;
            const ids = new Set(readPrintedInvoiceIds());
            ids.add(id);
            sessionStorage.setItem(PRINTED_INVOICE_KEY, JSON.stringify([...ids]));
            const order = runnerOrders.find(item => Number(item.id) === id);
            if (order) order.invoicePrinted = true;
        }

        async function markInvoicePrinted(orderId) {
            const id = Number(orderId);
            if (!id) return;
            rememberInvoicePrintedLocally(id);
            try {
                const res = await api('/orders/invoice/printed', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id })
                });
                if (res.ok) {
                    const updated = await res.json().catch(() => null);
                    if (updated && orderInvoicePrinted(updated)) {
                        rememberInvoicePrintedLocally(id);
                    }
                }
            } catch (err) {
                // Keep local mark so serve warning still works on this device.
            }
        }

        function confirmServeWithoutInvoice() {
            return new Promise(resolve => {
                const overlay = document.createElement('div');
                overlay.className = 'app-modal-backdrop';
                overlay.innerHTML = `
                    <section class="app-modal-card">
                        <div>
                            <p class="eyebrow">${escapeHtml(t('serveWithoutInvoiceTitle'))}</p>
                            <h2>${escapeHtml(t('serveWithoutInvoiceText'))}</h2>
                        </div>
                        <div class="app-modal-actions">
                            <button class="btn" type="button" data-modal-cancel>${escapeHtml(t('cancel'))}</button>
                            <button class="btn primary" type="button" data-modal-ok>${escapeHtml(t('serveAnyway'))}</button>
                        </div>
                    </section>
                `;
                const cleanup = value => {
                    overlay.remove();
                    resolve(value);
                };
                overlay.querySelector('[data-modal-cancel]').addEventListener('click', () => cleanup(false));
                overlay.querySelector('[data-modal-ok]').addEventListener('click', () => cleanup(true));
                overlay.addEventListener('click', event => {
                    if (event.target === overlay) cleanup(false);
                });
                overlay.addEventListener('keydown', event => {
                    if (event.key === 'Escape') cleanup(false);
                });
                document.body.appendChild(overlay);
                overlay.querySelector('[data-modal-ok]').focus();
            });
        }

        async function requestServeOrder(orderId) {
            if (!orderId) return;
            if (!isInvoicePrinted(orderId)) {
                const confirmed = await confirmServeWithoutInvoice();
                if (!confirmed) return;
            }
            await serveOrder(orderId);
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
                const previous = runnerOrders.find(order => Number(order.id) === Number(orderId)) || {};
                const tableName = updated.tableName || previous.tableName || '';
                const servedOrder = {
                    id: updated.id || orderId,
                    orderNumber: updated.orderNumber || previous.orderNumber,
                    tableName,
                    status: 'Served',
                    note: updated.note || previous.note || '',
                    items: updated.items || previous.items || []
                };
                runnerOrders = [servedOrder, ...runnerOrders.filter(order => {
                    const id = Number(order.id);
                    return id !== Number(orderId) && id !== Number(servedOrder.id);
                })];
                runnerTables = runnerTables.map(table => String(table.name || '') === String(tableName)
                    ? Object.assign({}, table, { status: 'Served', busy: true, orderId, orderNumber: servedOrder.orderNumber || table.orderNumber })
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
            beginHold(event, () => requestServeOrder(id));
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
                currentInvoiceOrderId = Number(order.id || orderId);
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
            currentInvoiceOrderId = 0;
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
            const text = String(value).trim();
            const match = text.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?/);
            const date = match
                ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]), Number(match[4]), Number(match[5]), Number(match[6] || 0))
                : new Date(text);
            if (Number.isNaN(date.getTime())) return String(value);
            return new Intl.DateTimeFormat(lang() === 'en' ? 'en-US' : 'vi-VN', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            }).format(date);
        }

        function printInvoiceSheet() {
            const orderId = currentInvoiceOrderId;
            if (!orderId) {
                window.print();
                return;
            }
            const onAfterPrint = () => {
                window.removeEventListener('afterprint', onAfterPrint);
                markInvoicePrinted(orderId);
            };
            window.addEventListener('afterprint', onAfterPrint);
            window.print();
        }

        window.renderPage = () => loadWork({ silent: true });
        window.openInvoice = openInvoice;
        window.closeInvoice = closeInvoice;
        window.printInvoiceSheet = printInvoiceSheet;
