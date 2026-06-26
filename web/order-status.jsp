<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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

    <main class="shell work-shell" style="max-width:820px">
        <section class="card hidden" id="manual-card">
            <label for="order-number" data-i18n="enterOrderNumber">Nhập mã đơn của bạn</label>
            <div class="form-row">
                <input id="order-number" placeholder="1001">
                <button class="btn primary" onclick="lookup()" data-i18n="checkOrder">Kiểm tra đơn</button>
            </div>
            <div id="result" style="margin-top:18px"></div>
        </section>
        <section id="table-orders"></section>
    </main>

    <script>
        const progress = ['Pending', 'Preparing', 'Ready', 'Served'];
        let tableCode = '';
        let tableName = '';
        let refreshTimer = null;

        document.addEventListener('DOMContentLoaded', () => {
            const params = new URLSearchParams(location.search);
            const orderNumber = params.get('orderNumber');
            tableCode = params.get('tableCode') || sessionStorage.getItem('selectedTableCode') || '';
            tableName = params.get('table') || sessionStorage.getItem('selectedTable') || '';
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
            const query = tableCode
                ? 'tableCode=' + encodeURIComponent(tableCode)
                : 'table=' + encodeURIComponent(tableName);
            const res = await api('/orders/table?' + query);
            if (!res.ok) {
                box.innerHTML = `<div class="notice">${t('notFound')}</div>`;
                return;
            }
            const orders = await res.json();
            if (tableCode && !tableName) await resolveTableName();
            box.innerHTML = `
                <section class="card table-order-head">
                    <p class="eyebrow">${t('trackCurrentTable')}</p>
                    <h2>${escapeHtml(tableName || t('table'))}</h2>
                    <span class="status ready">${orders.length} ${t('orders')}</span>
                </section>
                <section class="table-order-list">
                    ${orders.length ? orders.map(orderCard).join('') : `<div class="empty-state"><div class="big">0</div><h3>${t('noTableOrders')}</h3></div>`}
                </section>
            `;
        }

        async function resolveTableName() {
            const res = await api('/tables/by-code?code=' + encodeURIComponent(tableCode));
            if (!res.ok) return;
            const table = await res.json();
            tableName = table.name || tableName;
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

        function orderCard(order) {
            const visibleStatus = (order.status === 'Paid' || order.status === 'Cleared') ? 'Served' : order.status;
            const activeIndex = Math.max(0, progress.indexOf(visibleStatus));
            return `
                <article class="card order-track-card">
                <div class="toolbar">
                    <div>
                        <p class="eyebrow">${escapeHtml(order.tableName)}</p>
                        <h2>#${order.orderNumber}</h2>
                    </div>
                    <span class="status ${statusClass(visibleStatus)}">${statusText(visibleStatus)}</span>
                </div>
                ${order.note ? `<div class="order-note"><b>${t('orderNote')}</b><span>${escapeHtml(order.note)}</span></div>` : ''}
                <div class="timeline">
                    ${progress.map((status, index) => `
                        <div class="t-step ${index < activeIndex ? 'done' : (index === activeIndex ? 'now' : 'todo')}">
                            <div class="t-dotcol"><span class="t-dot"></span>${index < progress.length - 1 ? '<span class="t-line"></span>' : ''}</div>
                            <div class="t-body">
                                <div class="t-title">${statusText(status)}</div>
                                <div class="t-desc">${index <= activeIndex ? t('orderNumber') + ' #' + order.orderNumber : ''}</div>
                            </div>
                        </div>
                    `).join('')}
                </div>
                <p class="eyebrow" style="margin-top:8px" data-i18n="orderItems">${t('orderItems')}</p>
                <div class="list">
                    ${(order.items || []).map(it => `<div class="item">${escapeHtml(it.itemName)}${it.itemSize ? ' · ' + t('size') + ' ' + escapeHtml(it.itemSize) : ''} x${it.quantity}<span class="price" style="float:right">${money(it.price * it.quantity)}</span></div>`).join('')}
                </div>
                <div class="cart-total"><span data-i18n="total">${t('total')}</span><b class="price">${money(order.total)}</b></div>
                </article>
            `;
        }

        function statusClass(status) {
            return ({ Pending:'pending', Preparing:'preparing', Ready:'ready', Served:'served', Paid:'paid', Cleared:'served' })[status] || '';
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }
    </script>
</body>
</html>
