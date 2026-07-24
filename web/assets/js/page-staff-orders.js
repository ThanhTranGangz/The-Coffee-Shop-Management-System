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

        function isCookByItemActive() {
            // Item-level prep is only available while the order is already Preparing.
            return activeStatus === 'Preparing' && viewMode === 'item';
        }

        function renderViewToggle() {
            const container = document.getElementById('view-toggle-group');
            if (!container) return;
            // Toggle appears only on the Preparing tab: Pending is "start cooking" only.
            if (activeStatus !== 'Preparing') {
                container.innerHTML = '';
                return;
            }
            container.innerHTML = `
                <button class="view-toggle-btn ${viewMode === 'order' ? 'active' : ''}" id="btn-view-order" onclick="switchViewMode('order')">${t('cookByOrder')}</button>
                <button class="view-toggle-btn ${viewMode === 'item' ? 'active' : ''}" id="btn-view-item" onclick="switchViewMode('item')">${t('cookByItem')}</button>
            `;
        }

        function switchViewMode(mode) {
            if (activeStatus !== 'Preparing') return;
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
            const itemInteractive = isCookByItemActive();
            const countLabel = activeOrders.length;
            const bodyHtml = activeOrders.length
                ? activeOrders.map(order => orderHtml(order, itemInteractive)).join('')
                : `<div class="empty-state compact"><div class="big">0</div><h3>${t('noOrder')}</h3></div>`;

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

        function setActiveStatus(status) {
            activeStatus = status;
            renderViewToggle();
            loadOrders({ silent: true });
        }

        function orderHtml(order, itemInteractive = false) {
            const next = nextStatus(order.status);
            
            let cardAttributes = '';
            let cardClasses = `card order-card ${next ? '' : 'not-ready'}`;
            let inlineStyle = itemInteractive ? 'style="height: auto; min-height: 246px;"' : '';
            
            if (!itemInteractive && next) {
                cardClasses += ' hold-card';
                cardAttributes = `
                    onpointerdown="startHold(event, ${order.id}, '${next}')"
                    onpointerup="cancelHold()"
                    onpointercancel="cancelHold()"
                    ontouchstart="startHold(event, ${order.id}, '${next}')"
                    ontouchend="cancelHold()"
                    onmousedown="startHold(event, ${order.id}, '${next}')"
                    onmouseup="cancelHold()"
                    oncontextmenu="return false"
                `;
            }
            
            let itemsHtml = '';
            if (itemInteractive) {
                itemsHtml = (order.items || []).map(it => {
                    const prep = it.preparedQty || 0;
                    const isCompleted = prep >= it.quantity;
                    const canHoldItem = next && !isCompleted;
                    
                    const progressText = `${prep}/${it.quantity}`;
                    const statusBadge = isCompleted 
                        ? `<span class="status ready" style="padding: 2px 8px; font-size: 10px; font-weight: bold;">✓ ${t('readyColumn')}</span>`
                        : prep > 0 
                            ? `<span class="status preparing" style="padding: 2px 8px; font-size: 10px; font-weight: bold;">${progressText}</span>`
                            : `<span class="status pending" style="padding: 2px 8px; font-size: 10px; font-weight: bold;">0/${it.quantity}</span>`;
                    
                    return `
                        <div class="${canHoldItem ? 'hold-card' : ''}" 
                            style="display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; margin-bottom: 6px; border-radius: var(--radius-sm); border: 1px solid var(--line); background: var(--surface-2); position: relative; overflow: hidden; user-select: none;"
                            ${canHoldItem ? `
                                onpointerdown="startHoldItem(event, ${order.id}, ${it.menuItemId}, '${it.itemSize || ''}')"
                                onpointerup="cancelHold()"
                                onpointercancel="cancelHold()"
                                ontouchstart="startHoldItem(event, ${order.id}, ${it.menuItemId}, '${it.itemSize || ''}')"
                                ontouchend="cancelHold()"
                                onmousedown="startHoldItem(event, ${order.id}, ${it.menuItemId}, '${it.itemSize || ''}')"
                                onmouseup="cancelHold()"
                                oncontextmenu="return false; event.stopPropagation();"
                            ` : ''}>
                            <div style="display: flex; flex-direction: column; gap: 2px;">
                                <span style="font-weight: 800; color: var(--ink);">${escapeHtml(it.itemName)}</span>
                                ${it.itemSize ? `<span class="eyebrow" style="margin-bottom: 0; font-size: 9px;">${t('size') + ' ' + escapeHtml(it.itemSize)}</span>` : ''}
                            </div>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span class="price" style="font-size: 13px;">x${it.quantity}</span>
                                ${statusBadge}
                            </div>
                        </div>
                    `;
                }).join('');
            } else {
                itemsHtml = (order.items || []).map(it => {
                    const prep = it.preparedQty || 0;
                    const isCompleted = prep >= it.quantity;
                    const progressText = prep > 0 ? ` <span class="price" style="font-size: 11px; margin-left: 4px;">(${prep}/${it.quantity})</span>` : '';
                    const strikeStyle = isCompleted ? 'text-decoration: line-through; opacity: 0.6;' : '';
                    
                    return `
                        <p style="margin: 0; padding: 6px 0; border-bottom: 1px dashed var(--line); display: flex; justify-content: space-between; align-items: baseline; ${strikeStyle}">
                            <span>
                                <b>${escapeHtml(it.itemName)}</b>
                                ${it.itemSize ? `<span class="eyebrow" style="margin-left: 6px; font-size: 10px; margin-bottom: 0;">${escapeHtml(it.itemSize)}</span>` : ''}
                                ${progressText}
                            </span>
                            <span class="price">x${it.quantity}</span>
                        </p>
                    `;
                }).join('');
            }
            
            return `
                <article class="${cardClasses}" data-id="${order.id}" data-next="${next || ''}" ${cardAttributes} ${inlineStyle}>
                    <div class="toolbar order-card-head" style="margin-bottom: 8px;">
                        <div>
                            <p class="eyebrow" style="margin-bottom: 2px;">${escapeHtml(formatTableName(order.tableName))}</p>
                            <h3 style="margin: 0;">#${order.orderNumber}</h3>
                        </div>
                        <span class="price" style="font-size: 15px; font-weight: 900;">${money(order.total)}</span>
                    </div>
                    ${order.note ? `<div class="order-note" style="margin-top: 2px; margin-bottom: 8px;"><b>${t('orderNote')}:</b> <span>${escapeHtml(order.note)}</span></div>` : ''}
                    <div class="order-lines" style="flex: 1; overflow-y: auto; display: block; margin: 4px 0;">
                        ${itemsHtml}
                    </div>
                </article>
            `;
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

        function startHoldItem(event, orderId, menuItemId, itemSize) {
            if (!isCookByItemActive()) return;
            beginHold(event, async () => {
                const res = await api('/orders/item-prepare', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ orderId, menuItemId, itemSize })
                });
                if (!res.ok) {
                    const err = await res.json().catch(() => ({}));
                    notifyWork(err.error || t('statusMoveFailed'));
                } else {
                    await loadCupStatus();
                    loadOrders({ silent: true });
                }
            });
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
