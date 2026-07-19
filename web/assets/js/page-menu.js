        let menuItems = [];
        let tables = [];
        let cart = [];
        let currentItem = null;
        let currentQty = 1;
        let currentSize = '';
        let activeCategory = 'all';
        let searchText = '';
        let preferredTable = '';
        let preferredTableCode = '';
        let qrTableName = '';
        let lockedTable = false;
        let isSubmitting = false;
        let isConfirmingOrder = false;
        const MAX_QTY = 20;

        document.addEventListener('DOMContentLoaded', async () => {
            const params = new URLSearchParams(location.search);
            const urlTableCode = params.get('tableCode') || '';
            const urlTableName = params.get('table') || '';
            if (urlTableCode && urlTableCode !== sessionStorage.getItem('selectedTableCode')) {
                sessionStorage.removeItem('selectedTable');
            }
            if (urlTableName && !urlTableCode) {
                sessionStorage.removeItem('selectedTableCode');
            }
            preferredTableCode = urlTableCode || sessionStorage.getItem('selectedTableCode') || '';
            preferredTable = urlTableCode ? '' : (urlTableName || sessionStorage.getItem('selectedTable') || '');
            document.getElementById('search-input').addEventListener('input', event => {
                searchText = event.target.value.trim();
                renderPage();
            });
            document.getElementById('sheet-overlay').addEventListener('click', closeSheet);
            document.getElementById('sheet-minus').addEventListener('click', () => {
                if (currentQty > 1) {
                    currentQty--;
                    syncSheet();
                }
            });
            document.getElementById('sheet-plus').addEventListener('click', () => {
                const maxQty = maxSelectableQty(currentItem);
                if (currentQty < maxQty) {
                    currentQty++;
                    syncSheet();
                } else {
                    notifyStockLimit(currentItem, maxQty);
                }
            });
            document.getElementById('sheet-add').addEventListener('click', addSheetItem);
            window.addEventListener('scroll', updateScrollTop, { passive: true });
            window.addEventListener('resize', updateScrollTop);
            updateScrollTop();
            await loadData();
        });

        function updateScrollTop() {
            const btn = document.getElementById('scroll-top-btn');
            if (!btn) return;
            const label = t('scrollToTop');
            btn.setAttribute('aria-label', label);
            btn.setAttribute('title', label);
            const show = window.scrollY > 320;
            btn.hidden = !show;
            btn.classList.toggle('show', show);
            document.body.classList.toggle('has-cart-bar', document.getElementById('cart-bar')?.classList.contains('show'));
        }

        function scrollToTop() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
        window.scrollToTop = scrollToTop;

        async function loadData() {
            try {
                const [menuRes, tableRes] = await Promise.all([api('/menu'), api('/tables')]);
                menuItems = await menuRes.json();
                tables = await tableRes.json();
                const qrReady = await applyQrTable();
                if (!qrReady) {
                    renderQrRequired(preferredTableCode ? t('qrMissingTable') : t('qrRequired'));
                    return;
                }
                const tableOptions = tables.map(tb => `<option>${escapeHtml(tb.name)}</option>`).join('');
                document.getElementById('table-select-desktop').innerHTML = tableOptions;
                document.getElementById('table-select-mobile').innerHTML = tableOptions;
                const selected = tables.some(tb => tb.name === preferredTable) ? preferredTable : (tables[0] ? tables[0].name : '');
                document.getElementById('table-select-desktop').value = selected;
                document.getElementById('table-select-mobile').value = selected;
                document.getElementById('table-select-desktop').disabled = lockedTable;
                document.getElementById('table-select-mobile').disabled = lockedTable;
                if (selected) sessionStorage.setItem('selectedTable', selected);
                if (typeof loadNav === 'function') loadNav();
                renderPage();
            } catch (err) {
                document.getElementById('menu-list').innerHTML = `<div class="empty-state" style="grid-column:1/-1"><div class="big">!</div><h3>${t('orderError')}</h3></div>`;
            }
        }

        async function applyQrTable() {
            if (!preferredTableCode) return false;
            const requestedCode = preferredTableCode.trim();
            let table = tables.find(tb => String(tb.code || '').toUpperCase() === requestedCode.toUpperCase());
            if (!table) {
                const res = await api('/tables/by-code?code=' + encodeURIComponent(requestedCode));
                if (res.ok) table = await res.json();
            }
            if (table && table.name) {
                preferredTable = table.name;
                preferredTableCode = table.code || requestedCode;
                qrTableName = table.name;
                lockedTable = true;
                document.body.classList.add('qr-locked');
                sessionStorage.setItem('selectedTable', table.name);
                sessionStorage.setItem('selectedTableCode', preferredTableCode);
                return true;
            } else {
                qrTableName = '';
                lockedTable = false;
                sessionStorage.removeItem('selectedTableCode');
                return false;
            }
        }

        function renderQrRequired(message) {
            cart = [];
            lockedTable = false;
            qrTableName = '';
            document.body.classList.add('qr-required');
            const welcome = document.getElementById('table-welcome');
            const text = document.getElementById('table-welcome-text');
            welcome.classList.remove('hidden');
            text.textContent = message;
            document.getElementById('chips').innerHTML = '';
            document.getElementById('menu-list').innerHTML = '';
            const favorites = document.getElementById('favorites-section');
            if (favorites) favorites.hidden = true;
            const submit = document.getElementById('submit-order');
            if (submit) submit.disabled = true;
            if (typeof loadNav === 'function') loadNav();
            updateScrollTop();
        }

        function syncTable(source) {
            if (lockedTable) return;
            const desktop = document.getElementById('table-select-desktop');
            const mobile = document.getElementById('table-select-mobile');
            if (source === 'desktop') mobile.value = desktop.value;
            else desktop.value = mobile.value;
            sessionStorage.setItem('selectedTable', desktop.value);
            sessionStorage.removeItem('selectedTableCode');
            preferredTableCode = '';
        }

        function selectedTable() {
            if (lockedTable && qrTableName) return qrTableName;
            const mobile = document.getElementById('table-select-mobile');
            const desktop = document.getElementById('table-select-desktop');
            return window.matchMedia('(max-width: 760px)').matches ? mobile.value : desktop.value;
        }

        function displayName(item) {
            return lang() === 'en' ? item.nameEn : item.nameVi;
        }

        function hasSizes(item) {
            return Array.isArray(item.sizes) && item.sizes.length > 0;
        }

        function sizeLabel(item, size) {
            const option = item ? sizeOptions(item).find(row => row.code === size) : null;
            return option ? option.label : size;
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

        function priceFor(item, size) {
            const opt = sizeOptions(item).find(row => row.code === size);
            return (item.price || 0) + (opt ? opt.add : 0);
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        function fold(value) {
            return String(value || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');
        }

        function categories() {
            return [...new Set(menuItems.map(item => item.category || '').filter(Boolean))];
        }

        function filteredItems() {
            const q = fold(searchText);
            return menuItems.filter(item => {
                if (activeCategory !== 'all' && item.category !== activeCategory) return false;
                if (!q) return true;
                return fold(displayName(item)).includes(q) || fold(categoryText(item.category)).includes(q);
            });
        }

        window.renderPage = function() {
            renderWelcome();
            renderFavorites();
            renderChips();
            renderMenu();
            renderCart();
            updateScrollTop();
        }

        function renderWelcome() {
            if (!qrTableName) return;
            const text = lang() === 'en'
                ? `You are seated at ${qrTableName}. Have a lovely day ^^!`
                : `Bạn đang ngồi ${qrTableName}. Chúc bạn một ngày vui vẻ ^^!`;
            document.getElementById('table-welcome-text').textContent = text;
            document.getElementById('table-welcome').classList.remove('hidden');
        }

        function favoriteItems() {
            const seen = new Set();
            return menuItems.filter(item => {
                if (!item.bestSeller || seen.has(item.id)) return false;
                seen.add(item.id);
                return true;
            });
        }

        function renderFavorites() {
            const section = document.getElementById('favorites-section');
            const list = document.getElementById('favorites-list');
            if (!section || !list) return;
            const showFavorites = activeCategory === 'all' && !searchText;
            const items = showFavorites ? favoriteItems() : [];
            if (!items.length) {
                section.hidden = true;
                list.innerHTML = '';
                return;
            }
            section.hidden = false;
            list.innerHTML = items.map(item => dishCardHtml(item)).join('');
        }

        function renderChips() {
            const chips = [`<button class="chip ${activeCategory === 'all' ? 'active' : ''}" onclick="setCategory('all')">${t('all')}</button>`]
                .concat(categories().map(cat => `<button class="chip ${activeCategory === cat ? 'active' : ''}" onclick="setCategory('${escapeHtml(cat)}')">${escapeHtml(categoryText(cat))}</button>`));
            document.getElementById('chips').innerHTML = chips.join('');
        }

        function setCategory(category) {
            activeCategory = category;
            renderPage();
        }

        function dishCardHtml(item) {
            const name = displayName(item);
            const sized = hasSizes(item);
            return `
                <article class="card dish" onclick="openSheet(${item.id})">
                    <div class="dish-img">
                        ${item.bestSeller ? `<span class="dish-badge best-seller">${t('bestSeller')}</span>` : ''}
                        ${imageHtml(item, name)}
                    </div>
                    <div class="dish-body">
                        <p class="eyebrow">${escapeHtml(categoryText(item.category))}</p>
                        <div class="dish-name">${escapeHtml(name)}</div>
                        ${sized ? `<div class="dish-sizes">${sizeOptions(item).map(size => escapeHtml(size.label)).join(' · ')}</div>` : ''}
                        <div class="dish-foot">
                            <span class="price">${money(item.price)}</span>
                            <button class="dish-add" type="button" onclick="event.stopPropagation(); openSheet(${item.id})">+</button>
                        </div>
                    </div>
                </article>`;
        }

        function renderMenu() {
            const items = filteredItems();
            const grid = document.getElementById('menu-list');
            if (!items.length) {
                grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1"><div class="big">⌕</div><h3>${t('noMenu')}</h3></div>`;
                return;
            }
            let html = '';
            let lastCategory = '';
            items.forEach(item => {
                if (activeCategory === 'all' && !searchText && item.category !== lastCategory) {
                    lastCategory = item.category;
                    html += `<div class="cat-head"><h2>${escapeHtml(categoryText(item.category))}</h2><span class="line"></span></div>`;
                }
                html += dishCardHtml(item);
            });
            grid.innerHTML = html;
        }

        function imageHtml(item, name) {
            if (item.imagePath) {
                return `<img src="${escapeHtml(item.imagePath)}" alt="${escapeHtml(name)}" loading="lazy">`;
            }
            return `<span class="initial">${escapeHtml(String(name || '?').charAt(0))}</span>`;
        }

        function openSheet(id) {
            currentItem = menuItems.find(item => item.id === id);
            if (!currentItem) return;
            const remaining = remainingQtyForItem(currentItem.id);
            if (remaining <= 0) {
                alert(t('stockSoldOut'));
                return;
            }
            currentQty = 1;
            const sizes = sizeOptions(currentItem);
            currentSize = sizes.length ? sizes[0].code : '';
            document.getElementById('sheet-category').textContent = categoryText(currentItem.category);
            document.getElementById('sheet-name').textContent = displayName(currentItem);
            document.getElementById('sheet-note').value = '';
            renderSizeOptions();
            syncSheet();
            document.getElementById('sheet-overlay').classList.add('show');
            document.getElementById('item-sheet').classList.add('show');
        }

        function closeSheet() {
            document.getElementById('sheet-overlay').classList.remove('show');
            document.getElementById('item-sheet').classList.remove('show');
        }

        function availableQty(item) {
            const value = Number(item && item.availableQty);
            if (!Number.isFinite(value)) return MAX_QTY;
            return Math.max(0, Math.min(MAX_QTY, Math.floor(value)));
        }

        function remainingQtyForItem(menuItemId, excludeIndex = -1) {
            const item = menuItems.find(menu => menu.id === menuItemId);
            const inCart = cart.reduce((sum, line, index) => (
                index !== excludeIndex && line.menuItemId === menuItemId
                    ? sum + Number(line.quantity || 0)
                    : sum
            ), 0);
            return Math.max(0, availableQty(item) - inCart);
        }

        function maxSelectableQty(item) {
            if (!item) return 1;
            return Math.max(0, remainingQtyForItem(item.id));
        }

        function notifyStockLimit(item, available) {
            if (!available) {
                alert(t('stockSoldOut'));
                return;
            }
            alert(t('stockNotEnough').replace('{count}', String(available)));
        }

        function syncSheet() {
            const maxQty = maxSelectableQty(currentItem);
            if (currentQty > maxQty) currentQty = Math.max(1, maxQty);
            document.getElementById('sheet-qty').textContent = currentQty;
            document.getElementById('sheet-minus').disabled = currentQty <= 1;
            document.getElementById('sheet-plus').disabled = currentQty >= maxQty;
            const unit = currentItem ? priceFor(currentItem, currentSize) : 0;
            document.getElementById('sheet-price').textContent = money(unit);
            document.getElementById('sheet-total').textContent = money(unit * currentQty);
        }

        function renderSizeOptions() {
            const group = document.getElementById('sheet-size-group');
            const holder = document.getElementById('sheet-sizes');
            const options = currentItem ? sizeOptions(currentItem) : [];
            group.classList.toggle('hidden', options.length === 0);
            holder.innerHTML = options.map(opt => `
                <button class="size-option ${currentSize === opt.code ? 'active' : ''}" type="button" onclick="setSize('${opt.code}')">
                    <b>${escapeHtml(opt.label)}</b>
                    <span>${opt.add ? '+' + money(opt.add) : money(currentItem.price)}</span>
                </button>
            `).join('');
        }

        function setSize(size) {
            currentSize = size;
            renderSizeOptions();
            syncSheet();
        }

        function addSheetItem() {
            if (!currentItem) return;
            const note = document.getElementById('sheet-note').value.trim();
            const remaining = remainingQtyForItem(currentItem.id);
            if (remaining <= 0) {
                notifyStockLimit(currentItem, availableQty(currentItem));
                closeSheet();
                renderCart();
                return;
            }
            const existingVariantQty = totalQtyForVariant(currentItem.id, currentSize);
            const quantityToAdd = Math.min(currentQty, remaining, Math.max(0, MAX_QTY - existingVariantQty));
            if (quantityToAdd <= 0) {
                notifyStockLimit(currentItem, availableQty(currentItem));
                closeSheet();
                renderCart();
                return;
            }
            if (quantityToAdd < currentQty) {
                notifyStockLimit(currentItem, availableQty(currentItem));
            }
            const existing = cart.find(item => item.menuItemId === currentItem.id && item.size === currentSize && item.note === note);
            if (existing) existing.quantity += quantityToAdd;
            else cart.push({ menuItemId: currentItem.id, size: currentSize, quantity: quantityToAdd, note });
            closeSheet();
            renderCart();
        }

        function renderCart() {
            const list = document.getElementById('cart-list');
            let total = 0;
            let count = 0;
            if (!cart.length) {
                list.innerHTML = `<div class="empty-state"><div class="big">+</div><h3>${t('emptyCart')}</h3></div>`;
            } else {
                list.innerHTML = cart.map((line, index) => {
                    const menu = menuItems.find(item => item.id === line.menuItemId);
                    if (!menu) return '';
                    const unit = priceFor(menu, line.size);
                    total += unit * line.quantity;
                    count += line.quantity;
                    return `
                        <div class="cart-item">
                            <div style="min-width:0">
                                <div class="ci-name">${escapeHtml(displayName(menu))}</div>
                                ${line.size ? `<div class="ci-size">${t('size')} ${escapeHtml(sizeLabel(menu, line.size))}</div>` : ''}
                                ${line.note ? `<div class="ci-note">${escapeHtml(line.note)}</div>` : ''}
                                <button class="btn danger" type="button" onclick="removeLine(${index})" style="margin-top:8px">${t('remove')}</button>
                            </div>
                            <div class="ci-right">
                                <span class="price">${money(unit * line.quantity)}</span>
                                <div class="stepper">
                                    <button type="button" onclick="changeQty(${index}, -1)">−</button>
                                    <span class="num">${line.quantity}</span>
                                    <button type="button" onclick="changeQty(${index}, 1)" ${remainingQtyForItem(line.menuItemId, index) <= 0 || totalQtyForVariant(line.menuItemId, line.size) >= MAX_QTY ? 'disabled' : ''}>+</button>
                                </div>
                            </div>
                        </div>`;
                }).join('');
            }
            document.getElementById('cart-total').textContent = money(total);
            document.getElementById('cart-count').textContent = count;
            document.getElementById('cart-bar-total').textContent = money(total);
            document.getElementById('cart-bar').classList.toggle('show', cart.length > 0);
            document.getElementById('submit-order').disabled = cart.length === 0 || isSubmitting || isConfirmingOrder;
            updateScrollTop();
        }

        function changeQty(index, delta) {
            if (!cart[index]) return;
            if (delta > 0) {
                const line = cart[index];
                if (totalQtyForVariant(line.menuItemId, line.size) >= MAX_QTY) return;
                if (remainingQtyForItem(line.menuItemId, index) <= 0) {
                    const menu = menuItems.find(item => item.id === line.menuItemId);
                    notifyStockLimit(menu, availableQty(menu));
                    return;
                }
            }
            const nextQty = cart[index].quantity + delta;
            cart[index].quantity = Math.min(MAX_QTY, nextQty);
            if (cart[index].quantity <= 0) cart.splice(index, 1);
            renderCart();
        }

        function totalQtyForVariant(menuItemId, size) {
            return cart.reduce((sum, line) => (
                line.menuItemId === menuItemId && line.size === size
                    ? sum + Number(line.quantity || 0)
                    : sum
            ), 0);
        }

        function removeLine(index) {
            cart.splice(index, 1);
            renderCart();
        }

        async function submitOrder() {
            if (isSubmitting || isConfirmingOrder) return;
            const msg = document.getElementById('message');
            msg.classList.remove('hidden');
            if (!cart.length) {
                msg.textContent = t('emptyCart');
                return;
            }
            isConfirmingOrder = true;
            renderCart();
            let confirmed = false;
            try {
                confirmed = await confirmOrderHold();
            } finally {
                isConfirmingOrder = false;
                renderCart();
            }
            if (!confirmed) return;
            if (isSubmitting || !cart.length) return;
            isSubmitting = true;
            renderCart();
            const itemNotes = cart.map(line => {
                const menu = menuItems.find(item => item.id === line.menuItemId);
                return line.note && menu ? `${displayName(menu)}${line.size ? ' ' + t('size') + ' ' + sizeLabel(menu, line.size) : ''}: ${line.note}` : '';
            }).filter(Boolean).join('; ');
            const orderNote = [document.getElementById('note').value.trim(), itemNotes].filter(Boolean).join(' | ');
            try {
                const res = await api('/orders', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        tableName: selectedTable(),
                        tableCode: preferredTableCode,
                        customerPhone: '',
                        note: orderNote,
                        items: cart.map(line => ({ menuItemId: line.menuItemId, size: line.size, quantity: Math.min(MAX_QTY, line.quantity) }))
                    })
                });
                if (res.ok) {
                    const order = await res.json();
                    if (order.tableName) {
                        preferredTable = order.tableName;
                        qrTableName = lockedTable ? order.tableName : qrTableName;
                        sessionStorage.setItem('selectedTable', order.tableName);
                    }
                    const statusUrl = preferredTableCode
                        ? `order-status.jsp?tableCode=${encodeURIComponent(preferredTableCode)}`
                        : `order-status.jsp?table=${encodeURIComponent(order.tableName || selectedTable())}`;
                    msg.innerHTML = `<strong>${t('orderSent')}</strong><br>${t('orderNumber')}: ${order.orderNumber}<br><a class="btn primary" style="margin-top:10px" href="${withTab(statusUrl)}">${t('viewStatus')}</a>`;
                    cart = [];
                    await loadData();
                } else {
                    const err = await res.json().catch(() => ({}));
                    msg.textContent = err.error || t('orderError');
                    await loadData();
                }
            } finally {
                isSubmitting = false;
                renderCart();
            }
        }

        function cartSummary() {
            return cart.reduce((summary, line) => {
                const menu = menuItems.find(item => item.id === line.menuItemId);
                const unit = menu ? priceFor(menu, line.size) : 0;
                summary.count += Number(line.quantity || 0);
                summary.total += unit * Number(line.quantity || 0);
                return summary;
            }, { count: 0, total: 0 });
        }

        function confirmOrderHold() {
            return new Promise(resolve => {
                const summary = cartSummary();
                const overlay = document.createElement('div');
                overlay.className = 'order-confirm-backdrop';
                overlay.innerHTML = `
                    <section class="order-confirm-card" role="dialog" aria-modal="true">
                        <div>
                            <p class="eyebrow">${escapeHtml(selectedTable())}</p>
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
