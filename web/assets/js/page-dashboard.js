        let dashboardData = null;
        let tableMapData = [];
        let cashData = null;
        let activeRange = 'day';
        let customStart = '';
        let customEnd = '';
        let statsLoadToken = 0;
        const rangeKeys = ['day', 'week', 'month', 'year', 'all', 'custom'];

        document.addEventListener('DOMContentLoaded', async () => {
            rememberWorkPage('dashboard.jsp');
            document.getElementById('admin-pin-form').addEventListener('submit', unlockAdminDashboard);
            await initDashboard();
        });

        async function initDashboard() {
            const res = await api('/auth/session');
            const session = res.ok ? await res.json() : {};
            if (session.role === 'admin') {
                unlockUi();
                await loadStats();
            } else {
                document.getElementById('admin-pin-gate').classList.remove('hidden');
                setTimeout(() => document.getElementById('admin-pin-input').focus(), 40);
            }
        }

        async function unlockAdminDashboard(event) {
            event.preventDefault();
            const message = document.getElementById('admin-pin-message');
            message.classList.add('hidden');
            const res = await api('/auth/admin-pin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ pin: document.getElementById('admin-pin-input').value })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                message.textContent = err.error || t('adminPinInvalid');
                message.classList.remove('hidden');
                document.getElementById('admin-pin-input').select();
                return;
            }
            unlockUi();
            await loadNav();
            await loadStats();
        }

        function unlockUi() {
            const gate = document.getElementById('admin-pin-gate');
            if (gate) gate.classList.add('hidden');
        }

        async function loadStats() {
            const token = ++statsLoadToken;
            const dashboardPath = activeRange === 'custom' && customStart && customEnd
                ? `/dashboard?start=${encodeURIComponent(customStart)}&end=${encodeURIComponent(customEnd)}`
                : '/dashboard';
            loadTableMap(token);
            loadCashStatus(token);
            try {
                const dashboardRes = await api(dashboardPath);
                if (token !== statsLoadToken) return;
                if (!dashboardRes.ok) return;
                dashboardData = await dashboardRes.json();
                if (!customStart) customStart = dashboardData.today || todayInputValue();
                if (!customEnd) customEnd = dashboardData.today || todayInputValue();
                renderDashboard();
            } catch (err) {
                notifyWork(t('networkError'));
            }
        }

        async function loadTableMap(token = statsLoadToken) {
            try {
                const tableRes = await api('/tables/map');
                if (token !== statsLoadToken) return;
                tableMapData = tableRes.ok ? await tableRes.json() : [];
                renderTableMap(tableMapData, 'table-map');
            } catch (err) {
                if (token === statsLoadToken) renderTableMap([], 'table-map');
            }
        }

        async function loadCashStatus(token = statsLoadToken) {
            try {
                const cashRes = await api('/cash/status');
                if (token !== statsLoadToken) return;
                cashData = cashRes.ok ? await cashRes.json() : null;
                renderCashPanel();
            } catch (err) {
                cashData = null;
            }
        }

        function renderDashboard() {
            if (!dashboardData) return;
            const s = dashboardData;
            const seriesMap = s.revenueSeries || {};
            const currentSeries = Array.isArray(seriesMap[activeRange]) ? seriesMap[activeRange] : [];
            const chartTotal = currentSeries.reduce((sum, point) => sum + num(point.revenue), 0);
            const topProducts = Array.isArray(s.topProducts) ? s.topProducts : [];
            const productsByRange = s.topProductsByRange || {};
            const rangeProducts = Array.isArray(productsByRange[activeRange]) ? productsByRange[activeRange] : [];
            const rangeDetails = s.rangeDetails || {};
            const activeDetails = rangeDetails[activeRange] || {};

            document.getElementById('revenue-tabs').innerHTML = rangeKeys.map(key => `
                <button class="range-tab ${activeRange === key ? 'active' : ''}" type="button" onclick="setRevenueRange('${key}')">${t('range' + cap(key))}</button>
            `).join('');
            renderCustomControls();
            renderCashPanel();
            document.getElementById('chart-total').textContent = money(chartTotal);
            document.getElementById('chart').innerHTML = lineChart(currentSeries);

            document.getElementById('summary').innerHTML = `
                <div class="range-best">
                    <p class="eyebrow">${t('rangeBestSeller')}</p>
                    ${rangeProducts.length ? `
                        <div class="best-list">
                            ${rangeProducts.slice(0, 2).map((item, index) => `
                                <div class="best-card">
                                    <b>${index + 1}</b>
                                    <span>${escapeHtml(item.itemName)}</span>
                                    <strong>${num(item.quantity)} ${t('items')}</strong>
                                </div>
                            `).join('')}
                        </div>
                    ` : `<div class="notice">${t('noSalesData')}</div>`}
                </div>
            `;

            document.getElementById('details').innerHTML = `
                <section class="detail-grid">
                    <article>
                        <p class="eyebrow">${t('operationDetail')}</p>
                        <div class="mini-list">
                            <span>${t('selectedRange')} <b>${t('range' + cap(activeRange))}</b></span>
                            <span>${t('revenue')} <b>${money(activeDetails.revenue)}</b></span>
                            <span>${t('soldProducts')} <b>${num(activeDetails.soldProducts)}</b></span>
                            <span>${t('paidOrders')} <b>${num(activeDetails.paidOrders)}</b></span>
                        </div>
                    </article>
                    <article>
                        <p class="eyebrow">${t('topProducts')}</p>
                        <div class="rank-list">
                            ${rangeProducts.length ? rangeProducts.map((item, index) => `
                                <div class="rank-row">
                                    <b>${index + 1}</b>
                                    <span>${escapeHtml(item.itemName)}</span>
                                    <strong>${num(item.quantity)} ${t('items')}</strong>
                                    <em>${money(item.revenue)}</em>
                                </div>
                            `).join('') : `<div class="notice">${t('noSalesData')}</div>`}
                        </div>
                    </article>
                </section>
            `;
        }

        function renderCashPanel() {
            if (!cashData) return;
            document.getElementById('cash-panel').innerHTML = `
                <div class="stock-chip cash-mini">
                    <span>${t('cashOnHand')}</span>
                    <b>${money(cashData.balance)}</b>
                </div>
                <button class="btn primary" type="button" onclick="adminWithdrawCash()">${t('withdrawCash')}</button>
            `;
        }

        async function adminWithdrawCash() {
            const value = await inputModal({
                title: t('withdrawAmount'),
                message: `${t('cashOnHand')}: ${money(cashData ? cashData.balance : 0)}`,
                value: '',
                actionLabel: t('withdrawCash'),
                inputMode: 'numeric'
            });
            if (value === null) return;
            const amount = parseMoneyInput(value);
            if (!Number.isFinite(amount) || amount <= 0) {
                alert(t('cashCountInvalid'));
                return;
            }
            const res = await api('/cash/withdraw', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ amount })
            });
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                alert(err.error || t('cashCountInvalid'));
                return;
            }
            cashData = await res.json();
            renderCashPanel();
            notifyWork(t('cashWithdrawn'));
            loadStats();
        }

        function setRevenueRange(range) {
            activeRange = range;
            if (range === 'custom') {
                if (!customStart) customStart = dashboardData && dashboardData.today ? dashboardData.today : todayInputValue();
                if (!customEnd) customEnd = customStart;
                loadStats();
                return;
            }
            renderDashboard();
        }

        function renderCustomControls() {
            const holder = document.getElementById('custom-range-controls');
            holder.classList.toggle('hidden', activeRange !== 'custom');
            if (activeRange !== 'custom') {
                holder.innerHTML = '';
                return;
            }
            holder.innerHTML = `
                <label>${t('fromDate')}<input type="date" value="${escapeAttr(customStart)}" onchange="customStart=this.value"></label>
                <label>${t('toDate')}<input type="date" value="${escapeAttr(customEnd)}" onchange="customEnd=this.value"></label>
                <button class="btn primary" type="button" onclick="loadStats()">${t('apply')}</button>
            `;
        }

        function todayInputValue() {
            return new Date().toISOString().slice(0, 10);
        }

        function renderTableMap(tables, targetId) {
            const groups = {};
            (tables || []).forEach(table => {
                const floor = table.floorNo || 1;
                if (!groups[floor]) groups[floor] = [];
                groups[floor].push(table);
            });
            document.getElementById(targetId).innerHTML = `
                <div class="toolbar compact-toolbar">
                    <div>
                        <p class="eyebrow">${t('tableMap')}</p>
                        <h2>${t('serving')}: ${(tables || []).filter(tb => tb.busy).length}</h2>
                    </div>
                    <span>${(tables || []).length}</span>
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
            const busy = Boolean(table.busy);
            const label = status === 'Paid' ? t('needsCleaning') : (status === 'Served' ? t('unpaid') : (busy ? statusText(status) : t('available')));
            return `
                <div class="table-tile ${busy ? 'busy' : 'free'} ${status === 'Paid' ? 'cleaning' : ''}">
                    <b>${escapeHtml(tableNameShort(table.name))}</b>
                    <span>${escapeHtml(label)}</span>
                    ${table.orderNumber ? `<em>#${table.orderNumber}</em>` : ''}
                </div>
            `;
        }

        function tableNameShort(name) {
            const match = String(name || '').match(/Bàn\s*(\d+)/i);
            return match ? 'B' + match[1] : name;
        }

        function num(value) {
            return Number(value || 0);
        }

        function cap(value) {
            return value.charAt(0).toUpperCase() + value.slice(1);
        }

        function lineChart(series) {
            const points = series.length ? series.map(point => ({
                label: String(point.label || point.date || ''),
                revenue: num(point.revenue)
            })) : [{ label: '', revenue: 0 }, { label: '', revenue: 0 }];
            const width = 340;
            const height = 128;
            const pad = 12;
            const max = Math.max(...points.map(point => point.revenue), 1);
            const total = points.reduce((sum, point) => sum + point.revenue, 0);
            const step = points.length > 1 ? (width - pad * 2) / (points.length - 1) : 0;
            const coords = points.map((point, index) => {
                const x = pad + index * step;
                const y = height - pad - (point.revenue / max) * (height - pad * 2);
                return { x, y, ...point };
            });
            const line = coords.map((point, index) => `${index ? 'L' : 'M'}${point.x.toFixed(1)} ${point.y.toFixed(1)}`).join(' ');
            const area = `${line} L${width - pad} ${height - pad} L${pad} ${height - pad} Z`;
            const last = coords[coords.length - 1];
            return `
                <div class="stock-chart">
                    <svg viewBox="0 0 ${width} ${height}" role="img" aria-label="${t('revenueTrend')}">
                        <path class="chart-grid" d="M${pad} ${height - pad}H${width - pad} M${pad} ${height * .62}H${width - pad} M${pad} ${height * .32}H${width - pad}"></path>
                        <path class="chart-area" d="${area}"></path>
                        <path class="chart-line" d="${line}"></path>
                        ${coords.map(point => `<circle class="chart-dot" cx="${point.x.toFixed(1)}" cy="${point.y.toFixed(1)}" r="2.8"></circle>`).join('')}
                        <circle class="chart-last" cx="${last.x.toFixed(1)}" cy="${last.y.toFixed(1)}" r="5"></circle>
                    </svg>
                    <div class="chart-labels">
                        <span>${escapeHtml(shortLabel(points[0].label))}</span>
                        <b>${money(total)}</b>
                        <span>${escapeHtml(shortLabel(points[points.length - 1].label))}</span>
                    </div>
                </div>
            `;
        }

        function shortLabel(value) {
            const text = String(value || '');
            if (activeRange === 'day') return text;
            if (activeRange === 'year' || activeRange === 'all') return text.replace('-', '/');
            const parts = text.split('-');
            if (parts.length >= 3) return parts[2] + '/' + parts[1];
            return text;
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        function escapeAttr(value) {
            return escapeHtml(value).replace(/`/g, '&#96;');
        }

        window.renderPage = () => {
            renderDashboard();
            renderCashPanel();
            renderTableMap(tableMapData, 'table-map');
        };
