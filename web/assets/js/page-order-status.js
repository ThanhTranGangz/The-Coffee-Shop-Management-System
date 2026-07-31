        const progress = ['Pending', 'Preparing', 'Ready', 'Served'];
        let tableCode = '';
        let tableName = '';
        let refreshTimer = null;
        let pastExpanded = false;

        document.addEventListener('DOMContentLoaded', () => {
            const params = new URLSearchParams(location.search);
            const orderNumber = params.get('orderNumber');
            const urlTableCode = params.get('tableCode') || '';
            const urlTableName = params.get('table') || '';
            if (urlTableCode) {
                tableCode = urlTableCode;
                tableName = '';
                if (urlTableCode !== sessionStorage.getItem('selectedTableCode')) {
                    sessionStorage.removeItem('selectedTable');
                }
            } else {
                tableCode = sessionStorage.getItem('selectedTableCode') || '';
                tableName = urlTableName || sessionStorage.getItem('selectedTable') || '';
                if (urlTableName) sessionStorage.removeItem('selectedTableCode');
            }
            if (tableCode || tableName) {
                loadTableOrders();
                refreshTimer = setInterval(loadTableOrders, 5000);
            } else if (orderNumber) {
                document.getElementById('manual-card').classList.remove('hidden');
                document.getElementById('order-number').value = orderNumber;
                lookup();
            } else {
                document.getElementById('manual-card').classList.remove('hidden');
            }
        });

        async function loadTableOrders() {
            const box = document.getElementById('table-orders');
            if (tableCode) await resolveTableName();
            const query = tableCode
                ? 'tableCode=' + encodeURIComponent(tableCode)
                : 'table=' + encodeURIComponent(tableName);
            const res = await api('/orders/table?' + query);
            if (!res.ok) {
                box.innerHTML = `<div class="notice">${t('notFound')}</div>`;
                return;
            }
            const payload = await res.json();
            // Hỗ trợ cả response mới {active,past} và mảng cũ.
            const active = Array.isArray(payload) ? payload : (payload.active || []);
            const past = Array.isArray(payload) ? [] : (payload.past || []);
            if (!Array.isArray(payload) && payload.tableName) {
                syncTrackedTableName(payload.tableName);
            } else {
                syncTrackedTable(active.concat(past));
            }
            if (tableCode && !tableName) await resolveTableName();
            const displayName = formatTableName(tableName) || t('table');
            box.innerHTML = `
                <section class="card table-order-head">
                    <p class="eyebrow">${t('trackCurrentSession')}</p>
                    <h2>${escapeHtml(displayName)}</h2>
                    <span class="status ready">${active.length} ${t('orders')}</span>
                </section>
                <section class="table-order-list">
                    ${active.length
                        ? active.map(orderCard).join('')
                        : `<div class="empty-state"><div class="big">0</div><h3>${t('noSessionOrders')}</h3><p class="cust-hint">${t('noSessionOrdersHint')}</p></div>`}
                </section>
                ${past.length ? `
                <section class="past-orders-panel ${pastExpanded ? 'open' : ''}">
                    <button class="past-orders-toggle" type="button" onclick="togglePastOrders()">
                        <span>${t('pastOrdersToday')}</span>
                        <b>${past.length}</b>
                        <em>${pastExpanded ? '▴' : '▾'}</em>
                    </button>
                    <div class="past-orders-body" ${pastExpanded ? '' : 'hidden'}>
                        ${past.map(o => orderCard(o, true)).join('')}
                    </div>
                </section>` : ''}
            `;
        }

        window.togglePastOrders = function () {
            pastExpanded = !pastExpanded;
            loadTableOrders();
        };

        function syncTrackedTableName(nextTable) {
            if (!nextTable) return;
            const moved = tableName && tableName !== nextTable;
            tableName = nextTable;
            sessionStorage.setItem('selectedTable', tableName);
            if (moved) {
                tableCode = '';
                sessionStorage.removeItem('selectedTableCode');
                history.replaceState(null, '', `order-status.jsp?table=${encodeURIComponent(tableName)}`);
            }
        }

        function syncTrackedTable(orders) {
            if (!Array.isArray(orders) || !orders.length || !orders[0].tableName) return;
            syncTrackedTableName(orders[0].tableName);
        }

        async function resolveTableName() {
            const res = await api('/tables/by-code?code=' + encodeURIComponent(tableCode));
            if (!res.ok) return;
            const table = await res.json();
            tableName = table.name || tableName;
            tableCode = table.code || tableCode;
            if (tableName) sessionStorage.setItem('selectedTable', tableName);
            if (tableCode) sessionStorage.setItem('selectedTableCode', tableCode);
        }

        async function lookup() {
            const number = document.getElementById('order-number').value.trim();
            const res = await api('/orders/lookup?orderNumber=' + encodeURIComponent(number));
            const box = document.getElementById('result');
            if (!res.ok) {
                box.innerHTML = `<div class="notice">${t('notFound')}</div>`;
                return;
            }
            const order = await res.json();
            box.innerHTML = orderCard(order);
        }

        function orderCard(order, isPast) {
            const terminal = order.status === 'Cleared' || order.status === 'Cancelled' || order.status === 'Refunded';
            const visibleStatus = (order.status === 'Paid' || order.status === 'Cleared') ? 'Served' : order.status;
            const activeIndex = terminal
                ? progress.length - 1
                : Math.max(0, progress.indexOf(visibleStatus));
            return `
                <article class="card order-track-card ${isPast ? 'past-order' : ''}">
                <div class="toolbar">
                    <div>
                        <p class="eyebrow">${escapeHtml(formatTableName(order.tableName))}</p>
                        <h2>#${order.orderNumber}</h2>
                    </div>
                    <span class="status ${statusClass(order.status)}">${statusText(order.status === 'Cleared' ? 'Cleared' : visibleStatus)}</span>
                </div>
                ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                ${!isPast ? `<div class="timeline">
                    ${progress.map((status, index) => `
                        <div class="t-step ${index < activeIndex ? 'done' : (index === activeIndex ? 'now' : 'todo')}">
                            <div class="t-dotcol"><span class="t-dot"></span>${index < progress.length - 1 ? '<span class="t-line"></span>' : ''}</div>
                            <div class="t-body">
                                <div class="t-title">${statusText(status)}</div>
                                <div class="t-desc">${index <= activeIndex ? t('orderNumber') + ' #' + order.orderNumber : ''}</div>
                            </div>
                        </div>
                    `).join('')}
                </div>` : ''}
                <p class="eyebrow" style="margin-top:8px">${t('orderItems')}</p>
                <div class="list">
                    ${(order.items || []).map(it => `<div class="item">${escapeHtml(it.itemName)}${it.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(it.itemSize) : ''} x${it.quantity}<span class="price" style="float:right">${money(it.price * it.quantity)}</span></div>`).join('')}
                </div>
                <div class="cart-total"><span>${t('total')}</span><b class="price">${money(order.total)}</b></div>
                ${order.status === 'Pending' ? `<div class="links" style="margin-top:10px"><button class="btn danger" type="button" onclick="cancelGuestOrder(${order.id})">${t('cancelOrder')}</button></div>` : ''}
                ${order.status === 'Cancelled' ? `<div class="notice" style="margin-top:10px">${t('cancelled')}${order.cancelReason ? ': ' + escapeHtml(order.cancelReason) : ''}</div>` : ''}
                </article>
            `;
        }

        async function cancelGuestOrder(id) {
            const result = await cancelOrderPrompt(id);
            if (!result) return;
            if (tableCode || tableName) loadTableOrders();
            else lookup();
        }

        function statusClass(status) {
            return ({ Pending:'pending', Preparing:'preparing', Ready:'ready', Served:'served', Paid:'paid', Cleared:'served', Cancelled:'pending', Refunded:'pending' })[status] || '';
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }
