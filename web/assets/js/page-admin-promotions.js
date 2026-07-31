(function () {
    let promos = [];

    document.addEventListener('DOMContentLoaded', async () => {
        const session = await api('/auth/session').then(r => r.ok ? r.json() : {});
        if (session.role) {
            const links = document.getElementById('nav-links');
            if (links) links.innerHTML = nav(session.role);
        }
        applyI18n();
        await Promise.all([loadPromos(), loadTaxConfig()]);
    });

    async function loadPromos() {
        const res = await api('/promotions');
        promos = res.ok ? await res.json() : [];
        renderList();
    }

    function renderList() {
        const box = document.getElementById('promo-list');
        if (!promos.length) {
            box.innerHTML = `<div class="empty-state"><h3>${t('noSalesData')}</h3></div>`;
            return;
        }
        box.innerHTML = promos.map(p => `
            <article class="card">
                <div class="toolbar">
                    <div>
                        <p class="eyebrow">${escapeHtml(p.code)}</p>
                        <h3>${escapeHtml(lang() === 'en' ? p.nameEn : p.nameVi)}</h3>
                    </div>
                    <span class="status ${p.active ? 'ready' : 'pending'}">${p.active ? t('active') : 'OFF'}</span>
                </div>
                <p>${p.discountType === 'PERCENT' ? (p.discountValue + '%') : money(p.discountValue)} · ${p.usedCount || 0}/${p.maxUses || '∞'}</p>
                <div class="links">
                    <button class="btn" type="button" onclick="editPromo(${p.id})">${t('edit')}</button>
                    <button class="btn danger" type="button" onclick="deactivatePromo(${p.id})">${t('delete')}</button>
                </div>
            </article>
        `).join('');
    }

    window.newPromo = function () {
        resetForm();
        openEditSheet();
    };

    window.editPromo = function (id) {
        const p = promos.find(x => Number(x.id) === Number(id));
        if (!p) return;
        document.getElementById('id').value = p.id;
        document.getElementById('code').value = p.code || '';
        document.getElementById('nameVi').value = p.nameVi || '';
        document.getElementById('nameEn').value = p.nameEn || '';
        document.getElementById('discountType').value = p.discountType || 'PERCENT';
        document.getElementById('discountValue').value = p.discountValue || 0;
        document.getElementById('minSubtotal').value = p.minSubtotal || 0;
        document.getElementById('maxDiscount').value = p.maxDiscount || 0;
        document.getElementById('startAt').value = formatTs(p.startAt);
        document.getElementById('endAt').value = formatTs(p.endAt);
        document.getElementById('maxUses').value = p.maxUses || 0;
        document.getElementById('active').checked = !!p.active;
        openEditSheet();
    };

    window.resetForm = function () {
        ['id','code','nameVi','nameEn','startAt','endAt'].forEach(id => document.getElementById(id).value = '');
        document.getElementById('discountType').value = 'PERCENT';
        document.getElementById('discountValue').value = 10;
        document.getElementById('minSubtotal').value = 0;
        document.getElementById('maxDiscount').value = 0;
        document.getElementById('maxUses').value = 0;
        document.getElementById('active').checked = true;
        const msg = document.getElementById('message');
        msg.classList.add('hidden');
        msg.textContent = '';
    };

    window.savePromo = async function (event) {
        event.preventDefault();
        const body = {
            id: Number(document.getElementById('id').value || 0),
            code: document.getElementById('code').value.trim(),
            nameVi: document.getElementById('nameVi').value.trim(),
            nameEn: document.getElementById('nameEn').value.trim(),
            discountType: document.getElementById('discountType').value,
            discountValue: Number(document.getElementById('discountValue').value || 0),
            minSubtotal: Number(document.getElementById('minSubtotal').value || 0),
            maxDiscount: Number(document.getElementById('maxDiscount').value || 0),
            startAt: document.getElementById('startAt').value.trim(),
            endAt: document.getElementById('endAt').value.trim(),
            maxUses: Number(document.getElementById('maxUses').value || 0),
            active: document.getElementById('active').checked
        };
        const res = await api('/promotions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
        const msg = document.getElementById('message');
        if (!res.ok) {
            const err = await res.json().catch(() => ({}));
            msg.textContent = err.error || t('orderError');
            msg.classList.remove('hidden');
            return;
        }
        closeEditSheet();
        await loadPromos();
    };

    window.deactivatePromo = async function (id) {
        if (!confirm(t('deleteItemConfirm'))) return;
        await api('/promotions/delete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id })
        });
        await loadPromos();
    };

    async function loadTaxConfig() {
        const res = await api('/store/tax-config');
        if (!res.ok) return;
        const cfg = await res.json();
        document.getElementById('vatPercent').value = cfg.vatPercent || 0;
        document.getElementById('serviceChargePercent').value = cfg.serviceChargePercent || 0;
        document.getElementById('tipEnabled').checked = !!cfg.tipEnabled;
    }

    window.saveTaxConfig = async function (event) {
        event.preventDefault();
        await api('/store/tax-config', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                vatPercent: Number(document.getElementById('vatPercent').value || 0),
                serviceChargePercent: Number(document.getElementById('serviceChargePercent').value || 0),
                tipEnabled: document.getElementById('tipEnabled').checked
            })
        });
        notifyWork(t('save'));
    };

    function openEditSheet() {
        document.getElementById('edit-panel').classList.add('open');
        document.getElementById('form-overlay').classList.add('open');
    }
    window.closeEditSheet = function () {
        document.getElementById('edit-panel').classList.remove('open');
        document.getElementById('form-overlay').classList.remove('open');
    };

    function formatTs(value) {
        if (!value) return '';
        return String(value).replace('T', ' ').substring(0, 19);
    }
    function escapeHtml(value) {
        return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
    }
})();
