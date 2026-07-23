let items = [];
let editingId = null;

async function loadData() {
    try {
        const res = await api('/inventory');
        if (res.ok) {
            items = await res.json();
            render();
        }
    } catch (err) {
        console.error('Failed to load inventory', err);
    }
}

function lowStockItems() {
    return items.filter(ing => Number(ing.stock) <= Number(ing.minStock));
}

function renderLowStockAlert() {
    const box = document.getElementById('low-stock-alert');
    if (!box) return;
    const low = lowStockItems();
    if (!low.length) {
        box.classList.add('hidden');
        box.innerHTML = '';
        return;
    }
    box.classList.remove('hidden');
    box.innerHTML = `
        <h3>${escapeHtml(t('lowStockWarning'))}</h3>
        <p>${escapeHtml(t('lowStockBanner').replace('{count}', String(low.length)))}</p>
        <ul>
            ${low.map(ing => `<li>${escapeHtml(
                t('lowStockItemLine')
                    .replace('{name}', ing.name || ing.id)
                    .replace('{stock}', String(ing.stock))
                    .replace('{min}', String(ing.minStock))
                    .replace('{unit}', ing.unit || '')
            )}</li>`).join('')}
        </ul>
    `;
}

function render() {
    const tbody = document.getElementById('items-tbody');
    if (!tbody) return;
    renderLowStockAlert();

    tbody.innerHTML = '';
    if (items.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:2rem" class="muted">${t('inventoryEmpty')}</td></tr>`;
        return;
    }

    items.forEach(ing => {
        const isLow = ing.stock <= ing.minStock;
        const stockClass = isLow ? 'stock-low' : 'stock-ok';

        const tr = document.createElement('tr');
        tr.style.borderBottom = '1px solid var(--border)';
        tr.innerHTML = `
            <td style="padding:12px"><b>${escapeHtml(ing.id)}</b></td>
            <td style="padding:12px">${escapeHtml(ing.name)}</td>
            <td style="padding:12px; text-align:right" class="${stockClass}">${money(ing.stock).replace(' đ','').replace('VND ','')}</td>
            <td style="padding:12px; text-align:right" class="muted">${money(ing.minStock).replace(' đ','').replace('VND ','')}</td>
            <td style="padding:12px">${escapeHtml(ing.unit)}</td>
            <td style="padding:12px; text-align:right">${money(ing.importCost)}</td>
            <td style="padding:12px; text-align:right">
                <button class="btn" style="padding:4px 8px; font-size:0.85rem; margin-right:4px" onclick="edit('${escapeJs(ing.id)}')">${t('edit')}</button>
                <button class="btn danger" style="padding:4px 8px; font-size:0.85rem" onclick="deleteItem('${escapeJs(ing.id)}')">${t('delete')}</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function newItem() {
    editingId = null;
    document.getElementById('originalId').value = '';
    document.getElementById('id').value = '';
    document.getElementById('id').readOnly = false;
    document.getElementById('name').value = '';
    document.getElementById('unit').value = 'g';
    document.getElementById('stock').value = 0;
    document.getElementById('minStock').value = 0;
    document.getElementById('importCost').value = 0;

    document.getElementById('form-title').textContent = t('addNewMaterial');
    document.getElementById('message').className = 'notice hidden';
    openEditSheet();
}

function edit(id) {
    const ing = items.find(i => i.id === id);
    if (!ing) return;

    editingId = id;
    document.getElementById('originalId').value = id;
    document.getElementById('id').value = ing.id;
    document.getElementById('id').readOnly = true;
    document.getElementById('name').value = ing.name;
    document.getElementById('unit').value = ing.unit;
    document.getElementById('stock').value = ing.stock;
    document.getElementById('minStock').value = ing.minStock;
    document.getElementById('importCost').value = ing.importCost;

    document.getElementById('form-title').textContent = t('editMaterial') + ' ' + ing.name;
    document.getElementById('message').className = 'notice hidden';
    openEditSheet();
}

function parseNonNegativeField(id, labelKey) {
    const raw = document.getElementById(id).value.trim();
    if (raw === '') {
        return { error: t('inventoryFieldRequired').replace('{field}', t(labelKey)) };
    }
    if (!/^\d+$/.test(raw)) {
        return { error: t('inventoryFieldNonNegative').replace('{field}', t(labelKey)) };
    }
    return { value: parseInt(raw, 10) };
}

function showFormError(message) {
    const msg = document.getElementById('message');
    msg.textContent = message;
    msg.className = 'notice error';
}

async function readApiError(res, fallback) {
    try {
        const err = await res.json();
        if (err && err.error) return err.error;
        if (err && err.message) return err.message;
    } catch (_) { /* ignore non-JSON bodies */ }
    return fallback || t('systemError');
}

async function saveItem(event) {
    event.preventDefault();
    const originalId = document.getElementById('originalId').value.trim();
    const isCreate = !originalId;
    const payload = {
        originalId: originalId,
        id: document.getElementById('id').value.trim(),
        name: document.getElementById('name').value.trim(),
        unit: document.getElementById('unit').value.trim()
    };

    if (!payload.id || !payload.name || !payload.unit) {
        showFormError(t('inventoryMissingRequired'));
        return;
    }
    if (payload.id.length < 2 || payload.id.length > 50) {
        showFormError(t('inventoryIdLength'));
        return;
    }
    if (!/^[A-Za-z0-9_-]+$/.test(payload.id)) {
        showFormError(t('inventoryIdFormat'));
        return;
    }
    if (payload.name.length < 2 || payload.name.length > 120) {
        showFormError(t('inventoryNameLength'));
        return;
    }
    if (payload.unit.length > 20) {
        showFormError(t('inventoryUnitLength'));
        return;
    }

    if (isCreate) {
        const duplicated = items.some(i => String(i.id).toLowerCase() === payload.id.toLowerCase());
        if (duplicated) {
            showFormError(t('inventoryDuplicateId'));
            return;
        }
    }

    const stock = parseNonNegativeField('stock', 'currentStock');
    if (stock.error) { showFormError(stock.error); return; }
    const minStock = parseNonNegativeField('minStock', 'minStockLevel');
    if (minStock.error) { showFormError(minStock.error); return; }
    const importCost = parseNonNegativeField('importCost', 'importPriceVND');
    if (importCost.error) { showFormError(importCost.error); return; }

    payload.stock = stock.value;
    payload.minStock = minStock.value;
    payload.importCost = importCost.value;

    const msg = document.getElementById('message');
    msg.className = 'notice hidden';

    try {
        const res = await api('/inventory/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            const saved = await res.json();
            const matchId = originalId || payload.id;
            const idx = items.findIndex(i => String(i.id).toLowerCase() === String(matchId).toLowerCase());
            if (idx >= 0) items[idx] = saved;
            else items.push(saved);
            render();
            closeEditSheet();
            if (Number(saved.disabledMenuCount) > 0) {
                notifyWork(t('menuDisabledByStock').replace('{count}', String(saved.disabledMenuCount)));
            } else if (Number(saved.stock) <= Number(saved.minStock)) {
                notifyWork(t('lowStockWarning') + ': ' + (saved.name || saved.id));
            }
        } else {
            showFormError(await readApiError(res, t('systemError')));
        }
    } catch (err) {
        showFormError(t('networkError'));
    }
}

async function deleteItem(id) {
    if (!confirm(t('deleteMaterialConfirm').replace('{id}', id))) return;
    try {
        const res = await api('/inventory/delete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id })
        });
        if (res.ok) {
            items = items.filter(i => i.id !== id);
            render();
        } else {
            alert(t('errorPrefix') + ' ' + (await readApiError(res, t('systemError'))));
        }
    } catch (err) {
        alert(t('networkError'));
    }
}

function openEditSheet() {
    document.body.classList.add('editing');
    if (window.innerWidth < 1024) {
        setTimeout(() => {
            const panel = document.getElementById('edit-panel');
            if (panel) panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }, 100);
    }
}

function closeEditSheet() {
    document.body.classList.remove('editing');
}

function resetForm() {
}

function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/[&<>"']/g, function(m) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m];
    });
}

function escapeJs(str) {
    if (!str) return '';
    return String(str).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '\\"');
}

document.addEventListener('DOMContentLoaded', () => {
    loadData();
    document.getElementById('form-overlay').addEventListener('click', closeEditSheet);
});

window.renderPage = function() {
    render();
    if (editingId) {
        const ing = items.find(i => i.id === editingId);
        if (ing) {
            document.getElementById('form-title').textContent = t('editMaterial') + ' ' + ing.name;
        }
    } else {
        const titleEl = document.getElementById('form-title');
        if (titleEl && titleEl.textContent !== t('materialInfo')) {
            titleEl.textContent = t('addNewMaterial');
        } else if (titleEl) {
            titleEl.textContent = t('materialInfo');
        }
    }
};
