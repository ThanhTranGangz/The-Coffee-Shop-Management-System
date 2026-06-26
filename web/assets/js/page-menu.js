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

        document.addEventListener('DOMContentLoaded', async () => {
            const params = new URLSearchParams(location.search);
            preferredTableCode = params.get('tableCode') || '';
            preferredTable = params.get('table') || sessionStorage.getItem('selectedTable') || '';
            if (!preferredTableCode) preferredTableCode = sessionStorage.getItem('selectedTableCode') || '';
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
                if (currentQty < 20) {
                    currentQty++;
                    syncSheet();
                }
            });
            document.getElementById('sheet-add').addEventListener('click', addSheetItem);
            await loadData();
        });

        async function loadData() {
            try {
                const [menuRes, tableRes] = await Promise.all([api('/menu'), api('/tables')]);
                menuItems = await menuRes.json();
                tables = await tableRes.json();
                await applyQrTable();
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
            if (!preferredTableCode) return;
            let table = tables.find(tb => tb.code === preferredTableCode);
            if (!table) {
                const res = await api('/tables/by-code?code=' + encodeURIComponent(preferredTableCode));
                if (res.ok) table = await res.json();
            }
            if (table && table.name) {
                preferredTable = table.name;
                qrTableName = table.name;
                lockedTable = true;
                document.body.classList.add('qr-locked');
                sessionStorage.setItem('selectedTable', table.name);
                sessionStorage.setItem('selectedTableCode', preferredTableCode);
            } else {
                qrTableName = '';
                lockedTable = false;
                sessionStorage.removeItem('selectedTableCode');
                document.getElementById('table-welcome').classList.remove('hidden');
                document.getElementById('table-welcome-text').textContent = t('qrMissingTable');
            }
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
            renderChips();
            renderMenu();
            renderCart();
        }

        function renderWelcome() {
            if (!qrTableName) return;
            const text = lang() === 'en'
                ? `You are seated at ${qrTableName}. Have a lovely day ^^!`
                : `Bạn đang ngồi ${qrTableName}. Chúc bạn một ngày vui vẻ ^^!`;
            document.getElementById('table-welcome-text').textContent = text;
            document.getElementById('table-welcome').classList.remove('hidden');
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
                const name = displayName(item);
                const sized = hasSizes(item);
                html += `
                    <article class="card dish" onclick="openSheet(${item.id})">
                        <div class="dish-img">${imageHtml(item, name)}</div>
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

        function syncSheet() {
            document.getElementById('sheet-qty').textContent = currentQty;
            document.getElementById('sheet-minus').disabled = currentQty <= 1;
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
            const existing = cart.find(item => item.menuItemId === currentItem.id && item.size === currentSize && item.note === note);
            if (existing) existing.quantity += currentQty;
            else cart.push({ menuItemId: currentItem.id, size: currentSize, quantity: currentQty, note });
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
                                    <button type="button" onclick="changeQty(${index}, 1)">+</button>
                                </div>
                            </div>
                        </div>`;
                }).join('');
            }
            document.getElementById('cart-total').textContent = money(total);
            document.getElementById('cart-count').textContent = count;
            document.getElementById('cart-bar-total').textContent = money(total);
            document.getElementById('cart-bar').classList.toggle('show', cart.length > 0);
            document.getElementById('submit-order').disabled = cart.length === 0;
        }

        function changeQty(index, delta) {
            if (!cart[index]) return;
            cart[index].quantity += delta;
            if (cart[index].quantity <= 0) cart.splice(index, 1);
            renderCart();
        }

        function removeLine(index) {
            cart.splice(index, 1);
            renderCart();
        }

        async function submitOrder() {
            const msg = document.getElementById('message');
            msg.classList.remove('hidden');
            if (!cart.length) {
                msg.textContent = t('emptyCart');
                return;
            }
            const itemNotes = cart.map(line => {
                const menu = menuItems.find(item => item.id === line.menuItemId);
                return line.note && menu ? `${displayName(menu)}${line.size ? ' ' + t('size') + ' ' + sizeLabel(menu, line.size) : ''}: ${line.note}` : '';
            }).filter(Boolean).join('; ');
            const orderNote = [document.getElementById('note').value.trim(), itemNotes].filter(Boolean).join(' | ');
            const res = await api('/orders', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    tableName: selectedTable(),
                    customerPhone: '',
                    note: orderNote,
                    items: cart.map(line => ({ menuItemId: line.menuItemId, size: line.size, quantity: line.quantity }))
                })
            });
            if (res.ok) {
                const order = await res.json();
                const statusUrl = preferredTableCode
                    ? `order-status.jsp?tableCode=${encodeURIComponent(preferredTableCode)}`
                    : `order-status.jsp?table=${encodeURIComponent(selectedTable())}`;
                msg.innerHTML = `<strong>${t('orderSent')}</strong><br>${t('orderNumber')}: ${order.orderNumber}<br><a class="btn primary" style="margin-top:10px" href="${statusUrl}">${t('viewStatus')}</a>`;
                cart = [];
                renderCart();
            } else {
                const err = await res.json().catch(() => ({}));
                msg.textContent = err.error || t('orderError');
            }
        }
