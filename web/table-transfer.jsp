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
            <button class="btn" type="button" onclick="goBackToWork()" data-i18n="backToPrevious">Quay lại</button>
        </section>
        <section class="card transfer-panel" id="transfer-root"></section>
        <section class="card table-map-card" id="transfer-map"></section>
    </main>

    <script>
        let tables = [];

        document.addEventListener('DOMContentLoaded', loadTables);

        async function loadTables() {
            const res = await api('/tables/map');
            tables = res.ok ? await res.json() : [];
            renderPage();
        }

        window.renderPage = function() {
            renderTransfer();
            renderTableMap();
        }

        function renderTransfer() {
            const sources = tables.filter(table => table.busy && table.status !== 'Paid');
            const targets = tables.filter(table => !table.busy);
            document.getElementById('transfer-root').innerHTML = `
                <div class="toolbar compact-toolbar">
                    <div>
                        <p class="eyebrow">${t('operations')}</p>
                        <h2>${t('transferTable')}</h2>
                    </div>
                    <span class="status ready">${sources.length}</span>
                </div>
                ${sources.length && targets.length ? `
                    <form class="table-transfer-grid" onsubmit="transferTable(event)">
                        <div>
                            <label>${t('fromTable')}</label>
                            <select id="from-table">${sources.map(table => `<option value="${table.id}">${escapeHtml(tableDisplayName(table.name))} · ${statusText(table.status)}</option>`).join('')}</select>
                        </div>
                        <div>
                            <label>${t('toTable')}</label>
                            <select id="to-table">${targets.map(table => `<option value="${table.id}">${escapeHtml(tableDisplayName(table.name))}</option>`).join('')}</select>
                        </div>
                        <button class="btn primary big block" type="submit">${t('save')}</button>
                    </form>
                ` : `<div class="empty-state"><div class="big">0</div><h3>${t('noTransferTable')}</h3></div>`}
            `;
        }

        function renderTableMap() {
            const groups = {};
            tables.forEach(table => {
                const floor = table.floorNo || 1;
                if (!groups[floor]) groups[floor] = [];
                groups[floor].push(table);
            });
            document.getElementById('transfer-map').innerHTML = `
                <div class="toolbar compact-toolbar">
                    <div>
                        <p class="eyebrow">${t('tableMap')}</p>
                        <h2>${t('serving')}: ${tables.filter(table => table.busy).length}</h2>
                    </div>
                    <span>${tables.length}</span>
                </div>
                <div class="table-map-grid">
                    ${Object.keys(groups).sort().map(floor => `
                        <section class="floor-map">
                            <div class="floor-title">${t('floor')} ${floor}</div>
                            <div class="table-grid-map">
                                ${groups[floor].map(tableTile).join('')}
                            </div>
                        </section>
                    `).join('')}
                </div>
            `;
        }

        function tableTile(table) {
            const status = String(table.status || '');
            const label = status === 'Paid' ? t('needsCleaning') : (status === 'Served' ? t('unpaid') : (status === 'Ready' ? t('serveColumn') : (table.busy ? statusText(status) : t('available'))));
            return `
                <div class="table-tile ${table.busy ? 'busy' : 'free'} ${status === 'Paid' ? 'cleaning' : ''}">
                    <b>${escapeHtml(tableNameShort(table.name))}</b>
                    <span>${escapeHtml(label)}</span>
                </div>
            `;
        }

        async function transferTable(event) {
            event.preventDefault();
            const fromTableId = Number(document.getElementById('from-table').value || 0);
            const toTableId = Number(document.getElementById('to-table').value || 0);
            const res = await api('/tables/transfer', {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({ fromTableId, toTableId })
            });
            if (!res.ok) {
                notifyWork(t('statusMoveFailed'));
                return;
            }
            notifyWork(t('transferDone'));
            loadTables();
        }

        function tableDisplayName(name) {
            const match = String(name || '').match(/Tầng\s*(\d+)\s*-\s*Bàn\s*(\d+)/i);
            return match ? `${t('floor')} ${match[1]} · ${t('table')} ${match[2]}` : name;
        }

        function tableNameShort(name) {
            const match = String(name || '').match(/Bàn\s*(\d+)/i);
            return match ? 'B' + match[1] : name;
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }
    </script>
</body>
</html>
