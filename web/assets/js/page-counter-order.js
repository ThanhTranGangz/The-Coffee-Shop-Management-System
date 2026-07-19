        let counterMenu = [];
        let counterTables = [];
        let counterCart = [];
        let counterTable = '';
        let counterNote = '';
        let counterMessage = '';
        let counterSubmitting = false;
        let counterConfirming = false;
        const MAX_QTY = 20;

        document.addEventListener('DOMContentLoaded', loadCounterData);

        async function loadCounterData() {
            const [menuRes, tableRes] = await Promise.all([api('/menu'), api('/tables')]);
            counterMenu = menuRes.ok ? await menuRes.json() : [];
            counterTables = tableRes.ok ? await tableRes.json() : [];
            if (!counterTable && counterTables[0]) counterTable = counterTables[0].name;
            renderCounterOrder();
        }

        function renderCounterOrder() {
            const tableOptions = counterTables.map(table => `<option value="${escapeAttr(table.name)}" ${counterTable === table.name ? 'selected' : ''}>${escapeHtml(formatTableName(table.name))}</option>`).join('');
            document.getElementById('counter-root').innerHTML = `
                <div class="toolbar compact-toolbar">
                    <div>
                        <p class="eyebrow">${t('cashier')}</p>
                        <h2>${t('orderForTable')}</h2>
                    </div>
                    <select class="counter-table-select" onchange="setCounterTable(this.value)">${tableOptions}</select>
                </div>
                <div class="counter-order-layout">
                    <div class="counter-menu-grid">
                        ${counterMenu.map(counterItemHtml).join('')}
                    </div>
                    <aside class="counter-cart">
                        <h3>${t('cart')}</h3>
                        <div class="list">${counterCartHtml()}</div>
                        <div class="cart-total"><span>${t('total')}</span><b class="price">${money(counterTotal())}</b></div>
                        <div style="margin-top:12px">
                            <label>${t('orderNote')}</label>
                            <textarea rows="3" oninput="counterNote=this.value" placeholder="${escapeAttr(t('notePlaceholder'))}">${escapeHtml(counterNote)}</textarea>
                        </div>
                        <button class="btn primary big block" type="button" onclick="submitCounterOrder()" ${counterCart.length && !counterSubmitting && !counterConfirming ? '' : 'disabled'}>${t('checkout')}</button>
                        ${counterMessage ? `<div class="notice" style="margin-top:10px">${escapeHtml(counterMessage)}</div>` : ''}
                    </aside>
                </div>
            `;
        }

        function setCounterTable(value) {
            counterTable = value;
        }

        function counterItemHtml(item) {
            const sizes = sizeOptions(item);
            const actions = sizes.length ? sizes : [{ code: '', label: '+' }];
            return `
                <article class="counter-menu-item">
                    <div>
                        <b>${escapeHtml(displayName(item))}</b>
                        <span>${escapeHtml(categoryText(item.category))}</span>
                    </div>
                    <div class="counter-size-actions">
                        ${actions.map(size => `<button class="btn" type="button" onclick="addCounterItem(${item.id}, '${escapeJs(size.code)}')">${escapeHtml(size.label)}</button>`).join('')}
                    </div>
                </article>
            `;
        }

        function counterCartHtml() {
            if (!counterCart.length) return `<div class="empty-state compact"><div class="big">+</div><h3>${t('emptyCart')}</h3></div>`;
            return counterCart.map((line, index) => {
                const item = counterMenu.find(menu => menu.id === line.menuItemId);
                if (!item) return '';
                return `
                    <div class="cart-item">
                        <div style="min-width:0">
                            <div class="ci-name">${escapeHtml(displayName(item))}</div>
                            ${line.size ? `<div class="ci-size">${t('size')} ${escapeHtml(sizeLabel(item, line.size))}</div>` : ''}
                        </div>
                        <div class="ci-right">
                            <span class="price">${money(priceFor(item, line.size) * line.quantity)}</span>
                            <div class="stepper">
                                <button type="button" onclick="changeCounterQty(${index}, -1)">−</button>
                                <span class="num">${line.quantity}</span>
                                <button type="button" onclick="changeCounterQty(${index}, 1)" ${remainingCounterQty(line.menuItemId, index) <= 0 || line.quantity >= MAX_QTY ? 'disabled' : ''}>+</button>
                            </div>
                        </div>
                    </div>
                `;
            }).join('');
        }

        function addCounterItem(id, size) {
            const item = counterMenu.find(menu => menu.id === id);
            if (!item) return;
            const normalizedSize = sizeOptions(item).length ? size : '';
            const remaining = remainingCounterQty(id);
            if (remaining <= 0) {
                counterMessage = availableCounterQty(item) <= 0
                    ? t('stockSoldOut')
                    : t('stockNotEnough').replace('{count}', String(availableCounterQty(item)));
                renderCounterOrder();
                return;
            }
            const existing = counterCart.find(line => line.menuItemId === id && line.size === normalizedSize);
            if (existing) existing.quantity = Math.min(MAX_QTY, existing.quantity + 1);
            else counterCart.push({ menuItemId: id, size: normalizedSize, quantity: 1 });
            counterMessage = '';
            renderCounterOrder();
        }

        function changeCounterQty(index, delta) {
            if (!counterCart[index]) return;
            if (delta > 0) {
                const line = counterCart[index];
                if (line.quantity >= MAX_QTY) return;
                if (remainingCounterQty(line.menuItemId, index) <= 0) {
                    const item = counterMenu.find(menu => menu.id === line.menuItemId);
                    counterMessage = t('stockNotEnough').replace('{count}', String(availableCounterQty(item)));
                    renderCounterOrder();
                    return;
                }
            }
            counterCart[index].quantity = Math.min(MAX_QTY, counterCart[index].quantity + delta);
            if (counterCart[index].quantity <= 0) counterCart.splice(index, 1);
            counterMessage = '';
            renderCounterOrder();
        }

        function availableCounterQty(item) {
            const value = Number(item && item.availableQty);
            if (!Number.isFinite(value)) return MAX_QTY;
            return Math.max(0, Math.min(MAX_QTY, Math.floor(value)));
        }

        function remainingCounterQty(menuItemId, excludeIndex = -1) {
            const item = counterMenu.find(menu => menu.id === menuItemId);
            const inCart = counterCart.reduce((sum, line, index) => (
                index !== excludeIndex && line.menuItemId === menuItemId
                    ? sum + Number(line.quantity || 0)
                    : sum
            ), 0);
            return Math.max(0, availableCounterQty(item) - inCart);
        }

        function counterTotal() {
            return counterCart.reduce((sum, line) => {
                const item = counterMenu.find(menu => menu.id === line.menuItemId);
                return item ? sum + priceFor(item, line.size) * line.quantity : sum;
            }, 0);
        }

        async function submitCounterOrder() {
            if (!counterTable || !counterCart.length || counterSubmitting || counterConfirming) return;
            counterConfirming = true;
            renderCounterOrder();
            let confirmed = false;
            try {
                confirmed = await confirmCounterOrderHold();
            } finally {
                counterConfirming = false;
                renderCounterOrder();
            }
            if (!confirmed || !counterCart.length || counterSubmitting) return;

            counterSubmitting = true;
            renderCounterOrder();
            try {
                const res = await api('/orders', {
                    method:'POST',
                    headers:{'Content-Type':'application/json'},
                    body: JSON.stringify({
                        tableName: counterTable,
                        customerPhone: '',
                        note: counterNote.trim(),
                        items: counterCart.map(line => ({ menuItemId: line.menuItemId, size: line.size, quantity: Math.min(MAX_QTY, line.quantity) }))
                    })
                });
                if (res.ok) {
                    const order = await res.json();
                    counterCart = [];
                    counterNote = '';
                    counterMessage = `${t('orderCreated')} #${order.orderNumber}`;
                    notifyWork(counterMessage);
                    await loadCounterData();
                } else {
                    const err = await res.json().catch(() => ({}));
                    counterMessage = err.error || t('orderError');
                    await loadCounterData();
                }
            } finally {
                counterSubmitting = false;
                renderCounterOrder();
            }
        }

        function counterSummary() {
            return counterCart.reduce((summary, line) => {
                const item = counterMenu.find(menu => menu.id === line.menuItemId);
                summary.count += Number(line.quantity || 0);
                summary.total += item ? priceFor(item, line.size) * Number(line.quantity || 0) : 0;
                return summary;
            }, { count: 0, total: 0 });
        }

        function confirmCounterOrderHold() {
            return new Promise(resolve => {
                const summary = counterSummary();
                const overlay = document.createElement('div');
                overlay.className = 'order-confirm-backdrop';
                overlay.innerHTML = `
                    <section class="order-confirm-card" role="dialog" aria-modal="true">
                        <div>
                            <p class="eyebrow">${escapeHtml(counterTable)}</p>
                            <h2>${t('confirmOrderTitle')}</h2>
                            <p>${t('confirmOrderText')}</p>
                        </div>
                        <div class="order-confirm-summary">
                            <span>${t('orderConfirmItems')}<b>${summary.count}</b></span>
                            <span>${t('orderConfirmTotal')}<b>${money(summary.total)}</b></span>
                        </div>
                        <button class="hold-confirm-button" type="button">
                            <span>${t('holdToOrder')}</span>
                            <small>${t('releaseToCancel')}</small>
                        </button>
                        <button class="btn block" type="button" data-confirm-cancel>${t('cancel')}</button>
                    </section>
                `;
                document.body.appendChild(overlay);

                const holdButton = overlay.querySelector('.hold-confirm-button');
                let timer = null;
                let done = false;
                const cleanup = value => {
                    if (done) return;
                    done = true;
                    if (timer) clearTimeout(timer);
                    overlay.remove();
                    resolve(value);
                };
                const cancelHold = () => {
                    if (timer) clearTimeout(timer);
                    timer = null;
                    holdButton.classList.remove('holding');
                };
                const startHold = event => {
                    if (event.cancelable) event.preventDefault();
                    cancelHold();
                    if (event.pointerId !== undefined && holdButton.setPointerCapture) {
                        try { holdButton.setPointerCapture(event.pointerId); } catch (err) {}
                    }
                    holdButton.classList.add('holding');
                    timer = setTimeout(() => cleanup(true), 1000);
                };

                holdButton.addEventListener('pointerdown', startHold);
                holdButton.addEventListener('pointerup', cancelHold);
                holdButton.addEventListener('pointercancel', cancelHold);
                holdButton.addEventListener('pointerleave', cancelHold);
                overlay.querySelector('[data-confirm-cancel]').addEventListener('click', () => cleanup(false));
                overlay.addEventListener('click', event => {
                    if (event.target === overlay) cleanup(false);
                });
            });
        }

        function displayName(item) {
            return lang() === 'en' ? item.nameEn : item.nameVi;
        }

        function priceFor(item, size) {
            const opt = sizeOptions(item).find(row => row.code === size);
            return (item.price || 0) + (opt ? opt.add : 0);
        }

        function sizeOptions(item) {
            return Array.isArray(item.sizes)
                ? item.sizes.map(size => ({
                    code: String(size.sizeName || '').toUpperCase(),
                    label: String(size.sizeName || '').toUpperCase(),
                    add: Number(size.extraPrice || 0)
                })).filter(size => size.code)
                : [];
        }

        function sizeLabel(item, size) {
            const opt = sizeOptions(item).find(row => row.code === size);
            return opt ? opt.label : size;
        }

        function fold(value) {
            return String(value || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        function escapeAttr(value) {
            return escapeHtml(value).replace(/`/g, '&#96;');
        }

        function escapeJs(value) {
            return String(value || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
        }

        window.renderPage = renderCounterOrder;
