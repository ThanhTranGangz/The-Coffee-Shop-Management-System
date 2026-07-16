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

function render() {
    const tbody = document.getElementById('items-tbody');
    if (!tbody) return;
    
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
    document.getElementById('id').readOnly = true; // Không cho đổi ID khi sửa
    document.getElementById('name').value = ing.name;
    document.getElementById('unit').value = ing.unit;
    document.getElementById('stock').value = ing.stock;
    document.getElementById('minStock').value = ing.minStock;
    document.getElementById('importCost').value = ing.importCost;
    
    document.getElementById('form-title').textContent = t('editMaterial') + ' ' + ing.name;
    document.getElementById('message').className = 'notice hidden';
    openEditSheet();
}

async function saveItem(event) {
    event.preventDefault();
    const payload = {
        id: document.getElementById('id').value.trim(),
        name: document.getElementById('name').value.trim(),
        unit: document.getElementById('unit').value.trim(),
        stock: parseInt(document.getElementById('stock').value) || 0,
        minStock: parseInt(document.getElementById('minStock').value) || 0,
        importCost: parseInt(document.getElementById('importCost').value) || 0
    };
    
    if (!payload.id || !payload.name) return;
    
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
            const idx = items.findIndex(i => i.id === payload.id);
            if (idx >= 0) items[idx] = saved;
            else items.push(saved);
            
            // Nếu có đổi ID (trong lý thuyết form readonly nhưng nếu API có hỗ trợ),
            // nhưng hiện tại form đã set ID là readonly khi edit, nên ko cần lo đổi ID.
            
            render();
            closeEditSheet();
        } else {
            const err = await res.json().catch(()=>({}));
            msg.textContent = err.error || t('systemError');
            msg.className = 'notice error';
        }
    } catch (err) {
        msg.textContent = t('networkError');
        msg.className = 'notice error';
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
            alert('Lỗi: ' + (await res.text()));
        }
    } catch (err) {
        alert('Lỗi mạng');
    }
}

function openEditSheet() {
    document.body.classList.add('editing');
    // Scroll mượt tới vùng form
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
    // Không làm gì, reset fields đã được handle trong newItem
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
