        let activeFilter = 'Unpaid';
        let holdTimer = null;
        let holdingCard = null;
        let knownPayableIds = new Set();
        let shownWithdrawalIds = new Set();
        let firstLoad = true;
        let currentOrders = [];
        let splitOrderId = 0;

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
            currentOrders = Array.isArray(orders) ? orders : [];
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
            const payable = isPayableOrder(order);
            return `
                <article class="card order-card hold-card ${payable ? '' : 'not-ready'}"
                    data-cashier-card="1"
                    onpointerdown="startHold(event, ${order.id}, ${payable}, ${order.total || 0})"
                    onpointerup="cancelHold()"
                    onpointercancel="cancelHold()"
                    ontouchstart="startHold(event, ${order.id}, ${payable}, ${order.total || 0})"
                    ontouchend="cancelHold()"
                    onmousedown="startHold(event, ${order.id}, ${payable}, ${order.total || 0})"
                    onmouseup="cancelHold()"
                    oncontextmenu="return false">
                    <div class="toolbar" style="margin-bottom:10px">
                        <div>
                            <p class="eyebrow">${escapeHtml(formatTableName(order.tableName))}</p>
                            <h3>#${order.orderNumber}</h3>
                        </div>
                        <span class="status ${statusClass(order.status)}">${paymentStatusText(order.status)}</span>
                    </div>
                    ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                    <div class="order-lines">
                        ${(order.items || []).map(it => `<p><span>${escapeHtml(it.itemName)}${it.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(it.itemSize) : ''} x${it.quantity}</span><span class="price">${money(it.price * it.quantity)}</span></p>`).join('')}
                    </div>
                    <div class="cart-total">
                        <span data-i18n="total">${t('total')}</span>
                        <b class="price">${money(order.total)}</b>
                    </div>
                    ${order.status === 'Served' && splittableUnits(order) >= 2 ? `<div class="links" style="margin-top:10px">
                        <button class="btn split-btn" type="button"
                            onpointerdown="event.stopPropagation()" onmousedown="event.stopPropagation()" ontouchstart="event.stopPropagation()"
                            onclick="event.stopPropagation(); openSplit(${order.id})">${t('splitBill')}</button>
                    </div>` : ''}
                </article>`;
        }

        function splittableUnits(order) {
            return (order.items || []).reduce((sum, it) => sum + Number(it.quantity || 0), 0);
        }

        function isPayableOrder(order) {
            return order && order.status === 'Served';
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

        async function completeOrder(id, amount) {
            // Hỏi hình thức thanh toán TRƯỚC khi ghi nhận. Trước đây chỉ đổi
            // status thành 'Paid' — không lưu trả bằng gì, khách đưa bao nhiêu,
            // ai thu, nên không đối soát ca được.
            const detail = await paymentModal(Number(amount) || 0);
            if (!detail) return;

            const res = await api('/orders/status', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({
                    id,
                    status: 'Paid',
                    paymentMethod: detail.method,
                    receivedAmount: detail.received
                })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                notifyWork(err.error || t('statusMoveFailed'));
                return;
            }
            if (detail.change > 0) notifyWork(t('changeAmount') + ': ' + money(detail.change));
            loadOrders({ silent: true });
        }

        /**
         * Hộp thoại thu tiền. Trả về {method, received, change} hoặc null nếu huỷ.
         * Số tiền thối tính ở đây chỉ để thu ngân đọc; server vẫn tự tính lại
         * và tự kẹp received >= amount trước khi ghi vào bảng Payments.
         */
        function paymentModal(amount) {
            return new Promise(resolve => {
                let method = 'CASH';
                const overlay = document.createElement('div');
                overlay.className = 'app-modal-backdrop';
                overlay.innerHTML = `
                    <section class="app-modal-card pay-modal">
                        <div>
                            <p class="eyebrow">${t('confirmPayment')}</p>
                            <h2 class="price">${money(amount)}</h2>
                        </div>
                        <div>
                            <label>${t('paymentMethod')}</label>
                            <div class="role-picker pay-methods">
                                <button class="role-option active" type="button" data-method="CASH">${t('payCash')}</button>
                                <button class="role-option" type="button" data-method="TRANSFER">${t('payTransfer')}</button>
                            </div>
                        </div>
                        <div data-cash-only>
                            <label for="pay-received">${t('receivedAmount')}</label>
                            <input id="pay-received" class="app-modal-input" inputmode="numeric" value="${amount}">
                            <p class="cust-hint" data-change>${t('changeAmount')}: ${money(0)}</p>
                        </div>
                        <div class="app-modal-actions">
                            <button class="btn" type="button" data-cancel>${t('cancel')}</button>
                            <button class="btn primary" type="button" data-ok>${t('confirmPayment')}</button>
                        </div>
                    </section>`;
                document.body.appendChild(overlay);

                const input = overlay.querySelector('#pay-received');
                const changeLine = overlay.querySelector('[data-change]');
                const cashBlock = overlay.querySelector('[data-cash-only]');

                function received() {
                    return Math.max(0, Math.floor(Number(String(input.value).replace(/[^0-9]/g, '')) || 0));
                }
                function refresh() {
                    const change = Math.max(0, received() - amount);
                    changeLine.textContent = t('changeAmount') + ': ' + money(change);
                    changeLine.classList.toggle('pay-short', received() < amount);
                }
                input.addEventListener('input', refresh);

                overlay.querySelectorAll('[data-method]').forEach(button => {
                    button.addEventListener('click', () => {
                        method = button.dataset.method;
                        overlay.querySelectorAll('[data-method]').forEach(b => b.classList.toggle('active', b === button));
                        // Chuyển khoản thì không có chuyện đưa tiền và thối lại.
                        cashBlock.classList.toggle('hidden', method !== 'CASH');
                    });
                });

                function close(value) { overlay.remove(); resolve(value); }
                overlay.querySelector('[data-cancel]').addEventListener('click', () => close(null));
                overlay.querySelector('[data-ok]').addEventListener('click', () => {
                    if (method === 'TRANSFER') return close({ method, received: amount, change: 0 });
                    if (received() < amount) { refresh(); input.focus(); return; }
                    close({ method, received: received(), change: received() - amount });
                });
                overlay.addEventListener('keydown', e => { if (e.key === 'Escape') close(null); });
                setTimeout(() => { input.focus(); input.select(); refresh(); }, 30);
            });
        }

        function startHold(event, id, payable, amount) {
            if (!payable) return;
            beginHold(event, () => completeOrder(id, amount));
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

        function openSplit(id) {
            const order = currentOrders.find(o => Number(o.id) === Number(id));
            if (!order) return;
            splitOrderId = Number(id);
            hideSplitMessage();
            document.getElementById('split-rows').innerHTML = (order.items || []).map(it => `
                <div class="size-row split-row" data-item-id="${it.id}" data-max="${Number(it.quantity || 0)}">
                    <span>${escapeHtml(it.itemName)}${it.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(it.itemSize) : ''} <b class="price">${money(it.price)}</b></span>
                    <input type="number" min="0" max="${Number(it.quantity || 0)}" value="0" inputmode="numeric" aria-label="${t('splitToNewBill')}">
                    <span class="status served">/ ${Number(it.quantity || 0)}</span>
                </div>
            `).join('');
            document.getElementById('split-overlay').classList.add('show');
            document.getElementById('split-sheet').classList.add('show');
            document.getElementById('split-sheet').setAttribute('aria-hidden', 'false');
        }

        function closeSplit() {
            splitOrderId = 0;
            document.getElementById('split-overlay').classList.remove('show');
            document.getElementById('split-sheet').classList.remove('show');
            document.getElementById('split-sheet').setAttribute('aria-hidden', 'true');
        }

        async function confirmSplit() {
            if (!splitOrderId) return;
            const items = [];
            document.querySelectorAll('#split-rows .split-row').forEach(row => {
                const input = row.querySelector('input');
                const max = Number(row.dataset.max || 0);
                let qty = Math.floor(Number(input.value || 0));
                if (qty < 0) qty = 0;
                if (qty > max) qty = max;
                if (qty > 0) items.push({ id: Number(row.dataset.itemId), quantity: qty });
            });
            if (!items.length) {
                showSplitMessage(t('splitNothing'));
                return;
            }
            const res = await api('/orders/split', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: splitOrderId, items })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                showSplitMessage(err.error || t('splitFailed'));
                return;
            }
            closeSplit();
            notifyWork(t('splitDone'));
            loadOrders({ silent: true });
        }

        function showSplitMessage(text) {
            const box = document.getElementById('split-message');
            box.textContent = text;
            box.classList.remove('hidden');
        }

        function hideSplitMessage() {
            document.getElementById('split-message').classList.add('hidden');
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        window.renderPage = () => loadOrders({ silent: true });
