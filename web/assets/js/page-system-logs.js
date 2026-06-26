        const actors = ['all', 'guest', 'admin', 'barista', 'cashier', 'runner'];
        let activeActor = 'all';
        let logs = [];

        document.addEventListener('DOMContentLoaded', () => {
            rememberWorkPage('dashboard.jsp');
            loadLogs();
        });

        async function loadLogs() {
            const res = await api('/logs');
            logs = res.ok ? await res.json() : [];
            renderLogs();
        }

        function renderLogs() {
            const visibleLogs = activeActor === 'all' ? logs : logs.filter(log => log.actorRole === activeActor);
            const tabs = document.getElementById('log-tabs');
            tabs.dataset.active = String(Math.max(0, actors.indexOf(activeActor)));
            tabs.style.setProperty('--log-tab-count', actors.length);
            tabs.innerHTML = actors.map(actor => {
                const label = actorLabel(actor);
                const count = actor === 'all' ? logs.length : logs.filter(log => log.actorRole === actor).length;
                return `<button class="mobile-tab ${activeActor === actor ? 'active' : ''}" type="button" onclick="setActor('${actor}')"><span class="tab-label">${label}</span><b>${count}</b></button>`;
            }).join('');

            document.getElementById('log-list').innerHTML = visibleLogs.length
                ? visibleLogs.map(logHtml).join('')
                : `<div class="empty-state"><div class="big">0</div><h3>${t('noLogs')}</h3></div>`;
        }

        function setActor(actor) {
            activeActor = actor;
            loadLogs();
        }

        function logHtml(log) {
            const message = lang() === 'en' ? log.messageEn : log.messageVi;
            return `
                <article class="card log-card">
                    <div>
                        <span class="status ${escapeHtml(log.actorRole)}">${actorLabel(log.actorRole)}</span>
                        <h3>${escapeHtml(message)}</h3>
                    </div>
                    <p>${escapeHtml(formatLogTime(log.createdAt))}</p>
                </article>
            `;
        }

        function actorLabel(actor) {
            const map = {
                all: 'actorAll',
                guest: 'actorGuest',
                admin: 'actorAdmin',
                barista: 'actorBarista',
                cashier: 'actorCashier',
                runner: 'actorRunner'
            };
            return t(map[actor] || actor);
        }

        function formatLogTime(value) {
            const date = new Date(String(value || '').replace(' ', 'T') + 'Z');
            if (Number.isNaN(date.getTime())) return String(value || '');
            return date.toLocaleString(lang() === 'en' ? 'en-US' : 'vi-VN');
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        window.renderPage = renderLogs;
