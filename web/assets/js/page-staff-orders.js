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
        let viewMode = localStorage.getItem('barista_view_mode') || 'order';

        document.addEventListener('DOMContentLoaded', async () => {
            rememberWorkPage('staff-orders.jsp');
            await loadSession();
            await loadCupStatus();
            renderViewToggle();
            loadOrders();
            pollTimer = setInterval(() => loadOrders({ silent: false }), 5000);
            setInterval(loadCupStatus, 6000);
        });

        function renderViewToggle() {
            const container = document.getElementById('view-toggle-group');
            if (!container) return;
            container.innerHTML = `
                <button class="view-toggle-btn ${viewMode === 'order' ? 'active' : ''}" id="btn-view-order" onclick="switchViewMode('order')">${t('cookByOrder')}</button>
                <button class="view-toggle-btn ${viewMode === 'item' ? 'active' : ''}" id="btn-view-item" onclick="switchViewMode('item')">${t('cookByItem')}</button>
            `;
        }

        function switchViewMode(mode) {
            if (viewMode === mode) return;
            viewMode = mode;
            localStorage.setItem('barista_view_mode', mode);
            renderViewToggle();
            loadOrders({ silent: true });
        }

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
            
            let countLabel = activeOrders.length;
            let bodyHtml = '';
            
            if (viewMode === 'item') {
                const groupedItems = groupOrdersByItem(activeOrders);
                const totalCups = groupedItems.reduce((sum, item) => sum + item.totalQuantity, 0);
                countLabel = `${groupedItems.length} (${totalCups} ${t('items')})`;
                bodyHtml = groupedItems.length 
                    ? groupedItems.map(itemGroupHtml).join('') 
                    : `<div class="empty-state compact"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;
            } else {
                bodyHtml = activeOrders.length 
                    ? activeOrders.map(orderHtml).join('') 
                    : `<div class="empty-state compact"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;
            }
            
            document.getElementById('orders-board').innerHTML = `
                <section class="status-col active single-status" id="col-${activeStatus}">
                    <div class="status-col-head">
                        <span>${activeLabel}</span>
                        <b>${countLabel}</b>
                    </div>
                    <div class="status-col-body">
                        ${bodyHtml}
                    </div>
                </section>
            `;
        }

        function groupOrdersByItem(orders) {
            const grouped = {};
            orders.forEach(order => {
                const items = order.items || [];
                items.forEach(it => {
                    const key = `${it.menuItemId}_${it.itemSize || ''}`;
                    if (!grouped[key]) {
                        grouped[key] = {
                            menuItemId: it.menuItemId,
                            itemName: it.itemName,
                            itemSize: it.itemSize || '',
                            totalQuantity: 0,
                            orders: [],
                            notes: []
                        };
                    }
                    grouped[key].totalQuantity += it.quantity;
                    if (!grouped[key].orders.some(o => o.id === order.id)) {
                        grouped[key].orders.push({
                            id: order.id,
                            orderNumber: order.orderNumber,
                            quantity: it.quantity,
                            tableName: order.tableName
                        });
                    }
                    if (order.note) {
                        grouped[key].notes.push({
                            orderNumber: order.orderNumber,
                            note: order.note
                        });
                    }
                });
            });
            return Object.values(grouped);
        }

        function itemGroupHtml(item) {
            const next = nextStatus(activeStatus);
            const notesHtml = item.notes.map(n => `<span>#${n.orderNumber}: ${escapeHtml(n.note)}</span>`).join('; ');
            
            return `
                <article class="card order-card ${next ? '' : 'not-ready'}" data-next="${next || ''}">
                    <div class="toolbar order-card-head">
                        <div>
                            <p class="eyebrow">${item.itemSize ? t('size') + ' ' + escapeHtml(item.itemSize) : ''}</p>
                            <h3>${escapeHtml(item.itemName)}</h3>
                        </div>
                        <span class="price">x${item.totalQuantity}</span>
                    </div>
                    <div class="order-note" style="margin-top: 8px;">
                        <b>${t('orders')}:</b>
                        <div class="order-chips-list" style="display: inline-flex; gap: 6px; flex-wrap: wrap; margin-left: 6px;">
                            ${item.orders.map(o => `
                                <span class="order-chip-link" onclick="event.stopPropagation(); setStatusGroupItem(${o.id}, ${o.orderNumber}, '${next}')" title="${escapeHtml(o.tableName)}">
                                    #${o.orderNumber} (x${o.quantity})
                                </span>
                            `).join('')}
                        </div>
                    </div>
                    ${notesHtml ? `<div class="order-note" style="margin-top: 8px; border-top: 1px dashed var(--line); padding-top: 6px;"><b>${t('note')}:</b> ${notesHtml}</div>` : ''}
                </article>`;
        }

        async function setStatusGroupItem(id, orderNumber, status) {
            if (!status) return;
            const nextLabel = t(statusKeys[status]);
            const msg = t('confirmMoveOrderStatus')
                .replace('{order}', orderNumber)
                .replace('{status}', nextLabel);
            if (confirm(msg)) {
                await setStatus(id, status);
            }
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

        window.renderPage = () => {
            renderCupChip();
            renderViewToggle();
            loadOrders({ silent: true });
        };
