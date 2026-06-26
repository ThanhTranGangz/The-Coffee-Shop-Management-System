<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=ops-log-1">
    <script defer src="assets/js/i18n.js?v=ops-log-1"></script>
</head>
<body>
    <nav class="nav">
        <div class="nav-inner">
            <a class="brand" href="index.html">coffeshop</a>
            <div class="links" id="nav-links"></div>
            <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
        </div>
    </nav>

    <main class="shell work-shell">
        <section class="work-toolbar action-toolbar">
            <button class="btn" type="button" onclick="goBackToWork('cashier.jsp')" data-i18n="backToPrevious">Quay lại</button>
        </section>
        <section class="card counter-order-panel" id="counter-root"></section>
    </main>

    <script>
        let counterMenu = [];
        let counterTables = [];
        let counterCart = [];
        let counterTable = '';
        let counterNote = '';
        let counterMessage = '';

        document.addEventListener('DOMContentLoaded', loadCounterData);

        async function loadCounterData() {
            const [menuRes, tableRes] = await Promise.all([api('/menu'), api('/tables')]);
            counterMenu = menuRes.ok ? await menuRes.json() : [];
            counterTables = tableRes.ok ? await tableRes.json() : [];
            if (!counterTable && counterTables[0]) counterTable = counterTables[0].name;
            renderCounterOrder();
        }

        function renderCounterOrder() {
            const tableOptions = counterTables.map(table => `<option value="${escapeAttr(table.name)}" ${counterTable === table.name ? 'selected' : ''}>${escapeHtml(table.name)}</option>`).join('');
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
                        <button class="btn primary big block" type="button" onclick="submitCounterOrder()" ${counterCart.length ? '' : 'disabled'}>${t('checkout')}</button>
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
                                <button type="button" onclick="changeCounterQty(${index}, 1)">+</button>
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
            const existing = counterCart.find(line => line.menuItemId === id && line.size === normalizedSize);
            if (existing) existing.quantity++;
            else counterCart.push({ menuItemId: id, size: normalizedSize, quantity: 1 });
            counterMessage = '';
            renderCounterOrder();
        }

        function changeCounterQty(index, delta) {
            if (!counterCart[index]) return;
            counterCart[index].quantity += delta;
            if (counterCart[index].quantity <= 0) counterCart.splice(index, 1);
            renderCounterOrder();
        }

        function counterTotal() {
            return counterCart.reduce((sum, line) => {
                const item = counterMenu.find(menu => menu.id === line.menuItemId);
                return item ? sum + priceFor(item, line.size) * line.quantity : sum;
            }, 0);
        }

        async function submitCounterOrder() {
            if (!counterTable || !counterCart.length) return;
            const res = await api('/orders', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({
                    tableName: counterTable,
                    customerPhone: '',
                    note: counterNote.trim(),
                    items: counterCart.map(line => ({ menuItemId: line.menuItemId, size: line.size, quantity: line.quantity }))
                })
            });
            if (res.ok) {
                const order = await res.json();
                counterCart = [];
                counterNote = '';
                counterMessage = `${t('orderCreated')} #${order.orderNumber}`;
                notifyWork(counterMessage);
            } else {
                counterMessage = t('orderError');
            }
            renderCounterOrder();
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
    </script>
</body>
</html>
