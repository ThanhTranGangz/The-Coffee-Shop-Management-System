        let activeFilter = 'Unpaid';
        let holdTimer = null;
        let holdingCard = null;
        let knownPayableIds = new Set();
        let shownWithdrawalIds = new Set();
        let firstLoad = true;

        document.addEventListener('DOMContentLoaded', () => {
            rememberWorkPage('cashier.jsp');
            loadCashStatus({ initial: true });
            loadOrders();
            setInterval(() => loadCashStatus({ initial: false }), 5000);
            setInterval(() => loadOrders({ silent: false }), 5000);
        });

        async function loadCashStatus(options = {}) {
            const res = await api('/cash/status');
            if (!res.ok) return;
            const cash = await res.json();
            renderCashPanel(cash);
            const pending = Array.isArray(cash.pendingWithdrawals) ? cash.pendingWithdrawals : [];
            const fresh = pending.filter(event => !shownWithdrawalIds.has(Number(event.id)));
            fresh.forEach(event => {
                shownWithdrawalIds.add(Number(event.id));
                const message = `${t('adminWithdrawNotice')}: ${money(Math.abs(Number(event.amount || 0)))}`;
                notifyWork(message);
                alert(message);
            });
            if (pending.length) {
                await api('/cash/ack-withdrawals', { method: 'POST' });
            }
        }

        function renderCashPanel(cash) {
            const withdrawals = Array.isArray(cash.recentWithdrawals) ? cash.recentWithdrawals.slice(0, 1) : [];
            document.getElementById('cash-panel').innerHTML = `
                <div class="stock-chip cash-mini">
                    <span>${t('cashOnHand')}</span>
                    <b>${money(cash.balance)}</b>
                </div>
                ${withdrawals.length ? `<span class="cash-mini-note">${t('adminWithdrawEvent')}: ${money(Math.abs(Number(withdrawals[0].amount || 0)))}</span>` : ''}
            `;
        }

        async function loadOrders(options = {}) {
            const orderRes = await api('/orders?view=cashier');
            const orders = await orderRes.json();
            maybeNotify(orders, options.silent === true);
            renderTabs(orders);
            const visibleOrders = filterOrders(orders);
            document.getElementById('cashier-orders').innerHTML = visibleOrders.length
                ? visibleOrders.map(orderHtml).join('')
                : `<div class="empty-state" style="grid-column:1/-1"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;
        }

        function maybeNotify(orders, silent) {
            const payableIds = new Set(orders.filter(isPayableOrder).map(order => Number(order.id)));
            const hasNew = [...payableIds].some(id => !knownPayableIds.has(id));
            if (!firstLoad && !silent && hasNew) notifyWork(t('newCashierWork'));
            knownPayableIds = payableIds;
            firstLoad = false;
        }

        function renderTabs(orders) {
            const unpaidCount = orders.filter(order => order.status === 'Served').length;
            const paidCount = orders.filter(order => order.status === 'Paid' || order.status === 'Cleared').length;
            const tabs = [
                ['Unpaid', t('unpaid'), unpaidCount],
                ['Paid', t('paid'), paidCount]
            ];
            const holder = document.getElementById('cashier-tabs');
            holder.dataset.active = String(Math.max(0, tabs.findIndex(tab => tab[0] === activeFilter)));
            holder.innerHTML = tabs.map(tab => `<button class="mobile-tab ${activeFilter === tab[0] ? 'active' : ''}" title="${tab[1]}" onclick="setFilter('${tab[0]}')"><span class="tab-label">${tab[1]}</span><b>${tab[2]}</b></button>`).join('');
        }

        function setFilter(filter) {
            activeFilter = filter;
            loadOrders({ silent: true });
        }

        function filterOrders(orders) {
            if (activeFilter === 'Paid') return orders.filter(order => order.status === 'Paid' || order.status === 'Cleared');
            return orders.filter(order => order.status === 'Served');
        }

        function orderHtml(order) {
            const blocking = Number(order.blockingOrders || 0);
            const payable = isPayableOrder(order);
            return `
                <article class="card order-card hold-card ${payable ? '' : 'not-ready'}"
                    data-cashier-card="1"
                    onpointerdown="startHold(event, ${order.id}, ${payable})"
                    onpointerup="cancelHold()"
                    onpointercancel="cancelHold()"
                    ontouchstart="startHold(event, ${order.id}, ${payable})"
                    ontouchend="cancelHold()"
                    onmousedown="startHold(event, ${order.id}, ${payable})"
                    onmouseup="cancelHold()"
                    oncontextmenu="return false">
                    <div class="toolbar" style="margin-bottom:10px">
                        <div>
                            <p class="eyebrow">${escapeHtml(order.tableName)}</p>
                            <h3>#${order.orderNumber}</h3>
                        </div>
                        <span class="status ${statusClass(order.status)}">${paymentStatusText(order.status)}</span>
                    </div>
                    ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                    ${blocking > 0 ? `<div class="notice mini-notice">${t('paymentBlockedUntilServed')} <b>${blocking}</b> ${t('pendingTableItems').toLowerCase()}</div>` : ''}
                    <div class="order-lines">
                        ${(order.items || []).map(it => `<p><span>${escapeHtml(it.itemName)}${it.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(it.itemSize) : ''} x${it.quantity}</span><span class="price">${money(it.price * it.quantity)}</span></p>`).join('')}
                    </div>
                    <div class="cart-total">
                        <span data-i18n="total">${t('total')}</span>
                        <b class="price">${money(order.total)}</b>
                    </div>
                </article>`;
        }

        function isPayableOrder(order) {
            return order && order.status === 'Served' && Number(order.blockingOrders || 0) === 0;
        }

        function statusClass(status) {
            return ({ Pending:'pending', Preparing:'preparing', Ready:'ready', Served:'served', Paid:'paid', Cleared:'served' })[status] || '';
        }

        function paymentStatusText(status) {
            if (status === 'Served') return t('unpaid');
            if (status === 'Paid') return t('paid');
            if (status === 'Cleared') return t('cleared');
            return statusText(status);
        }

        async function completeOrder(id) {
            const res = await api('/orders/status', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({ id, status: 'Paid' })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                notifyWork(err.error || t('statusMoveFailed'));
                return;
            }
            loadOrders({ silent: true });
        }

        function startHold(event, id, payable) {
            if (!payable) return;
            beginHold(event, () => completeOrder(id));
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

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        window.renderPage = () => loadOrders({ silent: true });
