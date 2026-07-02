        let items = [];
        const imageByCategory = {
            'Cà phê': 'assets/img/menu/coffee.jpg',
            'Trà': 'assets/img/menu/tea.jpg',
            'Đặc biệt': 'assets/img/menu/matcha.jpg',
            'Bánh ngọt': 'assets/img/menu/pastry.jpg'
        };

        document.addEventListener('DOMContentLoaded', () => {
            document.getElementById('form-overlay').addEventListener('click', closeEditSheet);
            loadItems();
        });

        function isMobile() {
            return window.matchMedia('(max-width: 760px)').matches;
        }

        function openEditSheet() {
            if (!isMobile()) return;
            document.getElementById('form-overlay').classList.add('show');
            document.getElementById('edit-panel').classList.add('show');
        }

        function closeEditSheet() {
            document.getElementById('form-overlay').classList.remove('show');
            document.getElementById('edit-panel').classList.remove('show');
        }

        async function loadItems() {
            const res = await api('/menu');
            items = await res.json();
            renderPage();
        }

        window.renderPage = function() {
            document.getElementById('items').innerHTML = items.map(item => {
                const name = lang() === 'en' ? item.nameEn : item.nameVi;
                return `
                    <article class="card dish" style="cursor:default">
                        <div class="dish-img">${imageHtml(item, name)}</div>
                        <div class="dish-body">
                            <p class="eyebrow">${categoryText(item.category)}</p>
                            <div class="dish-name">${escapeHtml(name)}</div>
                            ${item.sizes && item.sizes.length ? `<div class="dish-sizes">${item.sizes.map(size => escapeHtml(size.sizeName)).join(' · ')}</div>` : ''}
                            <div class="dish-foot"><span class="price">${money(item.price)}</span>${item.active ? '<span class="status ready">' + t('active') + '</span>' : ''}</div>
                            <div class="links" style="margin-top:12px"><button class="btn" onclick="edit(${item.id})">${t('edit')}</button><button class="btn danger" onclick="removeItem(${item.id})">${t('delete')}</button></div>
                        </div>
                    </article>`;
            }).join('');
        }

        function imageHtml(item, name) {
            if (item.imagePath) {
                return `<img src="${escapeHtml(item.imagePath)}" alt="${escapeHtml(name)}" loading="lazy">`;
            }
            return `<span class="initial">${escapeHtml(String(name || '?').charAt(0))}</span>`;
        }

        function edit(id) {
            const item = items.find(x => x.id === id);
            ['id','nameVi','nameEn','category','price','imagePath'].forEach(key => document.getElementById(key).value = item[key] || '');
            document.getElementById('active').checked = item.active;
            document.getElementById('hasSizes').checked = Array.isArray(item.sizes) && item.sizes.length > 0;
            renderSizeRows(item.sizes || []);
            hideMessage();
            openEditSheet();
        }

        function resetForm() {
            document.querySelector('form').reset();
            document.getElementById('id').value = '';
            document.getElementById('category').value = 'Cà phê';
            document.getElementById('imagePath').value = imageByCategory['Cà phê'];
            document.getElementById('active').checked = true;
            document.getElementById('hasSizes').checked = false;
            renderSizeRows([]);
            hideMessage();
        }

        function toggleSizeEditor() {
            if (document.getElementById('hasSizes').checked && !document.querySelectorAll('.size-row').length) {
                renderSizeRows([{ sizeName: 'S', extraPrice: 0 }, { sizeName: 'M', extraPrice: 5000 }, { sizeName: 'L', extraPrice: 10000 }]);
            } else {
                renderSizeRows(readSizeRows());
            }
        }

        function renderSizeRows(sizes) {
            const hasSizes = document.getElementById('hasSizes').checked;
            const editor = document.getElementById('size-editor');
            editor.classList.toggle('hidden', !hasSizes);
            const rows = normalizeSizeRowsForForm(sizes);
            document.getElementById('size-rows').innerHTML = hasSizes ? rows.map((size, index) => `
                <div class="size-row">
                    <input value="${escapeAttr(size.sizeName)}" ${index === 0 ? 'readonly' : ''} aria-label="${t('sizeName')}">
                    <input type="number" min="0" max="100000" step="1000" value="${Number(size.extraPrice || 0)}" ${index === 0 ? 'readonly' : ''} aria-label="${t('extraPrice')}">
                    ${index === 0 ? '<span class="status ready">S</span>' : `<button class="btn danger" type="button" onclick="removeSizeRow(${index})">${t('delete')}</button>`}
                </div>
            `).join('') : '';
        }

        function normalizeSizeRowsForForm(sizes) {
            const rows = Array.isArray(sizes) && sizes.length ? sizes : [{ sizeName: 'S', extraPrice: 0 }];
            const cleaned = rows.map(size => ({ sizeName: String(size.sizeName || 'S').toUpperCase(), extraPrice: Number(size.extraPrice || 0) }));
            if (!cleaned.some(size => size.sizeName === 'S')) cleaned.unshift({ sizeName: 'S', extraPrice: 0 });
            cleaned.sort((a, b) => a.sizeName === 'S' ? -1 : (b.sizeName === 'S' ? 1 : 0));
            cleaned[0] = { sizeName: 'S', extraPrice: 0 };
            return cleaned;
        }

        function readSizeRows() {
            return Array.from(document.querySelectorAll('.size-row')).map(row => {
                const inputs = row.querySelectorAll('input');
                return { sizeName: inputs[0].value.trim().toUpperCase(), extraPrice: Number(inputs[1].value || 0) };
            });
        }

        function addSizeRow() {
            const rows = readSizeRows();
            rows.push({ sizeName: '', extraPrice: 0 });
            renderSizeRows(rows);
            const last = document.querySelector('.size-row:last-child input');
            if (last) last.focus();
        }

        function removeSizeRow(index) {
            const rows = readSizeRows();
            rows.splice(index, 1);
            renderSizeRows(rows);
        }

        function syncDefaultImage() {
            const image = document.getElementById('imagePath');
            if (!image.value || Object.values(imageByCategory).includes(image.value)) {
                image.value = imageByCategory[document.getElementById('category').value] || imageByCategory['Cà phê'];
            }
        }

        async function saveItem(event) {
            event.preventDefault();
            const res = await api('/menu', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({
                id: Number(document.getElementById('id').value || 0),
                nameVi: document.getElementById('nameVi').value.trim(),
                nameEn: document.getElementById('nameEn').value.trim(),
                category: document.getElementById('category').value,
                price: Number(document.getElementById('price').value || 0),
                imagePath: document.getElementById('imagePath').value.trim(),
                active: document.getElementById('active').checked,
                hasSizes: document.getElementById('hasSizes').checked,
                sizes: readSizeRows()
            })});
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                showMessage(err.error || t('orderError'));
                return;
            }
            resetForm();
            closeEditSheet();
            loadItems();
        }

        async function downloadImportTemplate() {
            const res = await api('/menu/import-template');
            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                alert(err.error || t('orderError'));
                return;
            }
            const blob = await res.blob();
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'mau-import-thuc-don.xlsx';
            document.body.appendChild(a);
            a.click();
            a.remove();
            URL.revokeObjectURL(url);
        }

        async function importExcelFile(event) {
            const input = event.target;
            const file = input.files && input.files[0];
            input.value = '';
            if (!file) {
                alert(t('importNoFile'));
                return;
            }
            const formData = new FormData();
            formData.append('file', file);
            const res = await api('/menu/import', { method: 'POST', body: formData });
            const result = await res.json().catch(() => ({}));
            if (!res.ok) {
                alert(result.error || t('orderError'));
                return;
            }
            let msg = `${t('importDone')}: ${result.importedCount}`;
            if (result.skippedCount) {
                msg += `\n${t('importSkipped')}: ${result.skippedCount}`;
                msg += '\n' + result.skipped.map(s => `- #${s.row} ${s.nameVi || ''}: ${s.reason}`).join('\n');
            }
            alert(msg);
            loadItems();
        }

        async function removeItem(id) {
            if (!confirm(t('deleteItemConfirm'))) return;
            await api('/menu/delete', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ id }) });
            loadItems();
        }

        function showMessage(text) {
            const box = document.getElementById('message');
            box.textContent = text;
            box.classList.remove('hidden');
        }

        function hideMessage() {
            document.getElementById('message').classList.add('hidden');
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
        }

        function escapeAttr(value) {
            return escapeHtml(value).replace(/`/g, '&#96;');
        }
