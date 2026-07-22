        let tables = [];

        document.addEventListener('DOMContentLoaded', () => {
            const baseInput = document.getElementById('base-url');
            baseInput.value = localStorage.getItem('coffeshop_qr_base') || defaultBaseUrl();
            baseInput.addEventListener('input', () => {
                localStorage.setItem('coffeshop_qr_base', baseInput.value.trim());
                renderPage();
            });
            loadTables();
        });

        function defaultBaseUrl() {
            return location.origin + location.pathname.replace(/\/[^/]*$/, '');
        }

        function qrBaseUrl() {
            return (document.getElementById('base-url').value || defaultBaseUrl()).replace(/\/+$/, '');
        }

        function orderUrl(table) {
            return `${qrBaseUrl()}/menu.jsp?tableCode=${encodeURIComponent(table.code)}`;
        }

        function qrUrl(table, download) {
            return `api/tables/qr?code=${encodeURIComponent(table.code)}&base=${encodeURIComponent(qrBaseUrl())}&size=420${download ? '&download=1' : ''}`;
        }

        async function loadTables() {
            const res = await api('/tables/all');
            tables = await res.json();
            if (!document.getElementById('id').value && !document.getElementById('tableNo').value) {
                const next = nextTableLocation();
                document.getElementById('floorNo').value = next.floorNo;
                document.getElementById('tableNo').value = next.tableNo;
                syncTableName();
            }
            renderPage();
        }

        window.renderPage = function() {
            const list = document.getElementById('table-list');
            const visibleTables = tables.filter(table => true);
            list.innerHTML = visibleTables.map(table => `
                <article class="card qr-card ${table.active ? '' : 'inactive'}">
                    <div class="qr-preview">
                        ${table.active
                            ? `<img src="${qrUrl(table, false)}" alt="QR ${escapeHtml(table.name)}">`
                            : `<div class="qr-disabled">${t('inactiveTable')}</div>`}
                    </div>
                    <div class="qr-info">
                        <div class="toolbar">
                            <div>
                                <p class="eyebrow">${t('table')}</p>
                                <h2>${escapeHtml(formatTableName(table.name))}</h2>
                            </div>
                            <span class="status ${table.active ? 'ready' : 'served'}">${table.active ? t('activeTable') : t('inactiveTable')}</span>
                        </div>
                        <p class="qr-code">${escapeHtml(table.code)}</p>
                        <input class="qr-link-input" data-table-id="${table.id}" value="${escapeAttr(orderUrl(table))}" readonly onclick="this.select()">
                        <div class="qr-actions">
                            ${table.active ? `
                                <a class="btn primary" href="${qrUrl(table, true)}">${t('downloadQr')}</a>
                                <button class="btn" type="button" onclick="copyLink(${table.id})">${t('copyLink')}</button>
                            ` : ''}
                            <button class="btn" type="button" onclick="editTable(${table.id})">${t('edit')}</button>
                            <button class="btn" type="button" onclick="regenerate(${table.id})">${t('regenerateQr')}</button>
                            <button class="btn ${table.active ? 'danger' : 'primary'}" type="button" onclick="toggleTable(${table.id}, ${table.active ? 'false' : 'true'})">${table.active ? t('hideTable') : t('showTable')}</button>
                            <button class="btn danger" type="button" onclick="deleteTableHard(${table.id})">${t('deleteTableHard')}</button>
                        </div>
                    </div>
                </article>
            `).join('');
        }

        function editTable(id) {
            const table = tables.find(x => x.id === id);
            if (!table) return;
            document.getElementById('id').value = table.id;
            document.getElementById('name').value = table.name;
            document.getElementById('floorNo').value = table.floorNo || 1;
            document.getElementById('tableNo').value = table.tableNo || '';
            document.getElementById('active').checked = !!table.active;
            document.querySelector('aside.card').scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        function resetTableForm() {
            document.querySelector('form').reset();
            document.getElementById('id').value = '';
            document.getElementById('active').checked = true;
            const next = nextTableLocation();
            document.getElementById('floorNo').value = next.floorNo;
            document.getElementById('tableNo').value = next.tableNo;
            syncTableName();
            document.getElementById('name').focus();
        }

        function nextTableLocation() {
            const floorNo = 1;
            const used = tables.filter(table => Number(table.floorNo) === floorNo).map(table => Number(table.tableNo || 0));
            let tableNo = 1;
            while (used.includes(tableNo)) tableNo++;
            return { floorNo, tableNo };
        }

        function syncTableName() {
            const floorNo = Number(document.getElementById('floorNo').value || 1);
            const tableNo = Number(document.getElementById('tableNo').value || 0);
            if (tableNo > 0) document.getElementById('name').value = tf('tableNamePattern', { floor: floorNo, no: tableNo });
        }

        async function saveTable(event) {
            event.preventDefault();
            const res = await api('/tables', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: Number(document.getElementById('id').value || 0),
                    name: document.getElementById('name').value.trim(),
                    floorNo: Number(document.getElementById('floorNo').value || 0),
                    tableNo: Number(document.getElementById('tableNo').value || 0),
                    active: document.getElementById('active').checked
                })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                showMessage(err.error || t('orderError'));
                return;
            }
            showMessage(t('tableSaved'));
            resetTableForm();
            await loadTables();
        }

        async function toggleTable(id, active) {
            const table = tables.find(x => x.id === id);
            if (!table) return;
            if (!active && !confirm(t('deleteTableConfirm'))) return;
            await api('/tables', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: table.id, name: table.name, floorNo: table.floorNo, tableNo: table.tableNo, active })
            });
            await loadTables();
        }

        async function regenerate(id) {
            if (!confirm(t('regenerateQrConfirm'))) return;
            await api('/tables/regenerate', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id }) });
            await loadTables();
        }

        async function deleteTableHard(id) {
            const table = tables.find(x => x.id === id);
            if (!table) return;
            if (!confirm(t('deleteTableConfirm1'))) return;
            const typed = prompt(`${t('deleteTableConfirm2')} ${table.name}`);
            if (typed !== table.name) {
                showMessage(t('confirmTextMismatch'));
                return;
            }
            const res = await api('/tables/delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                showMessage(err.error || t('orderError'));
                return;
            }
            showMessage(t('tableDeleted'));
            resetTableForm();
            await loadTables();
        }

        async function copyLink(id) {
            const table = tables.find(x => x.id === id);
            if (!table) return;
            const value = orderUrl(table);
            try {
                await navigator.clipboard.writeText(value);
            } catch (err) {
                const input = document.querySelector(`.qr-link-input[data-table-id="${id}"]`);
                if (input) {
                    input.select();
                    document.execCommand('copy');
                }
            }
            showMessage(t('copyDone'));
        }

        function showMessage(text) {
            const box = document.getElementById('message');
            box.textContent = text;
            box.classList.remove('hidden');
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        function escapeAttr(value) {
            return escapeHtml(value).replace(/`/g, '&#96;');
        }
