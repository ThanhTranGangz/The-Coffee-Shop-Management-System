<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nhà cà phê. — quản trị thực đơn</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        coffee: {
                            bg: '#FAF8F3',
                            dark: '#2B1B17',
                            rust: '#A04423',
                            sand: '#E5DEC9',
                            light: '#FAF7EE',
                            milk: '#8E7D6F'
                        }
                    }
                }
            }
        }
    </script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Playfair+Display:ital,wght@0,600;0,700;1,600&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/pro-ui.css">
    <script defer src="assets/js/ui-polish.js"></script>
    <style>
        body { font-family: 'Inter', sans-serif; background:#FAF8F3; color:#2B1B17; }
        .font-serif { font-family:'Playfair Display', serif; }
        .font-mono { font-family:'JetBrains Mono', monospace; }
    </style>
</head>
<body class="min-h-screen">
    <main class="min-h-screen grid grid-cols-1 xl:grid-cols-[260px_1fr]">
        <aside class="bg-white border-r border-coffee-sand/70 p-5 xl:sticky xl:top-0 xl:h-screen flex xl:flex-col gap-4 overflow-x-auto xl:overflow-visible">
            <div class="shrink-0 min-w-[190px]">
                <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Admin workspace</p>
                <h1 class="font-serif italic font-bold text-2xl text-coffee-dark">Thực đơn</h1>
            </div>
            <nav class="flex xl:flex-col gap-2 text-xs font-bold shrink-0">
                <a href="dashboard.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Dashboard</a>
                <a href="admin-menu.jsp" class="px-3 py-2 rounded-xl border border-coffee-rust bg-coffee-rust text-white">Thực đơn</a>
                <a href="promotions.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Khuyến mãi</a>
                <a href="inventory.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Kho hàng</a>
                <a href="reports.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Báo cáo</a>
            </nav>
        </aside>

        <section class="p-4 sm:p-6 lg:p-8 space-y-6">
            <header class="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-coffee-sand/70 pb-5">
                <div>
                    <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Menu catalog</p>
                    <h2 class="font-serif italic font-bold text-3xl text-coffee-dark">Quản lý món bán</h2>
                </div>
                <div class="flex items-center gap-2">
                    <button onclick="resetMenuForm()" class="bg-white border border-coffee-sand text-coffee-dark text-xs font-bold px-4 py-2 rounded-xl hover:border-coffee-rust">Tạo món mới</button>
                    <button onclick="loadMenuItems()" class="bg-coffee-dark text-white text-xs font-bold px-4 py-2 rounded-xl hover:bg-coffee-rust">Làm mới</button>
                </div>
            </header>

            <div class="grid grid-cols-1 xl:grid-cols-[1fr_360px] gap-6 items-start">
                <section class="bg-white border border-coffee-sand rounded-3xl shadow-sm overflow-hidden">
                    <div class="p-5 border-b border-coffee-sand/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <div>
                            <h3 class="font-serif italic font-bold text-lg text-coffee-dark">Danh sách món</h3>
                            <p id="menu-count-label" class="text-[11px] text-coffee-milk">Đang tải...</p>
                        </div>
                        <input id="menu-search" oninput="renderMenuItems()" type="text" placeholder="Tìm món..." class="bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 text-xs outline-none focus:border-coffee-rust">
                    </div>
                    <div id="menu-items-grid" class="grid grid-cols-1 md:grid-cols-2 2xl:grid-cols-3 gap-4 p-5"></div>
                </section>

                <section class="bg-white border border-coffee-sand rounded-3xl shadow-sm p-5 space-y-4 xl:sticky xl:top-6">
                    <div class="border-b border-coffee-sand/70 pb-3">
                        <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Menu form</p>
                        <h3 id="menu-form-title" class="font-serif italic font-bold text-lg text-coffee-dark">Thêm món</h3>
                    </div>
                    <form onsubmit="submitMenuItem(event)" class="space-y-3 text-xs">
                        <input type="hidden" id="menu-id">
                        <div class="space-y-1">
                            <label class="font-bold text-coffee-dark block">Tên món</label>
                            <input id="menu-name" required type="text" placeholder="Ví dụ: Latte dừa" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                        </div>
                        <div class="grid grid-cols-2 gap-2">
                            <div class="space-y-1">
                                <label class="font-bold text-coffee-dark block">Nhóm</label>
                                <select id="menu-category" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                                    <option value="Coffee">Coffee</option>
                                    <option value="Tea">Tea</option>
                                    <option value="Specialty">Specialty</option>
                                    <option value="Pastry">Pastry</option>
                                </select>
                            </div>
                            <div class="space-y-1">
                                <label class="font-bold text-coffee-dark block">Giá bán</label>
                                <input id="menu-price" required min="1000" step="1000" type="number" placeholder="35000" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                            </div>
                        </div>
                        <div class="space-y-1">
                            <label class="font-bold text-coffee-dark block">Kích cỡ</label>
                            <input id="menu-sizes" type="text" placeholder="S,M,L" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                        </div>
                        <div class="space-y-1">
                            <label class="font-bold text-coffee-dark block">Ảnh món</label>
                            <input id="menu-image" type="url" placeholder="https://..." class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                        </div>
                        <div class="space-y-1">
                            <label class="font-bold text-coffee-dark block">Mô tả</label>
                            <textarea id="menu-description" rows="3" placeholder="Mô tả ngắn về món..." class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust"></textarea>
                        </div>
                        <div class="grid grid-cols-2 gap-2 pt-1">
                            <button type="submit" class="bg-coffee-rust text-white py-2.5 rounded-xl font-bold hover:bg-coffee-rust/95">Lưu món</button>
                            <button type="button" onclick="resetMenuForm()" class="bg-white border border-coffee-sand text-coffee-dark py-2.5 rounded-xl font-bold hover:border-coffee-rust">Huỷ</button>
                        </div>
                    </form>
                </section>
            </div>
        </section>
    </main>

    <script>
        let menuItems = [];

        document.addEventListener('DOMContentLoaded', loadMenuItems);

        function formatVND(value) {
            return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value || 0);
        }

        function toast(message, type) {
            if (window.appToast) {
                window.appToast(message, type || 'info');
            } else {
                alert(message);
            }
        }

        async function loadMenuItems() {
            const grid = document.getElementById('menu-items-grid');
            grid.innerHTML = '<div class="text-xs text-coffee-milk">Đang tải thực đơn...</div>';
            try {
                const res = await fetch('api/menu', { credentials: 'same-origin' });
                if (!res.ok) throw new Error('Menu request failed');
                menuItems = await res.json();
                renderMenuItems();
            } catch (e) {
                grid.innerHTML = '<div class="text-xs text-red-600">Không tải được thực đơn.</div>';
            }
        }

        function renderMenuItems() {
            const grid = document.getElementById('menu-items-grid');
            const keyword = (document.getElementById('menu-search').value || '').toLowerCase().trim();
            const list = menuItems.filter(item => {
                const text = [item.name, item.category, item.description].join(' ').toLowerCase();
                return !keyword || text.indexOf(keyword) !== -1;
            });
            document.getElementById('menu-count-label').textContent = list.length + ' món đang bán';
            if (!list.length) {
                grid.innerHTML = '<div class="text-xs text-coffee-milk">Không có món phù hợp.</div>';
                return;
            }
            grid.innerHTML = list.map(item => `
                <article class="border border-coffee-sand rounded-2xl overflow-hidden bg-coffee-light/45">
                    <div class="aspect-[4/3] bg-white border-b border-coffee-sand/70">
                        ${item.image ? `<img src="${item.image}" alt="${item.name}" class="w-full h-full object-cover" referrerpolicy="no-referrer">` : `<div class="w-full h-full flex items-center justify-center text-3xl">☕</div>`}
                    </div>
                    <div class="p-4 space-y-3">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <h4 class="font-serif italic font-bold text-base text-coffee-dark">${item.name}</h4>
                                <p class="text-[10px] font-mono text-coffee-milk">${item.category} · ${(item.availableSizes || []).join(', ') || 'M'}</p>
                            </div>
                            <span class="text-xs font-mono font-bold text-coffee-rust">${formatVND(item.price)}</span>
                        </div>
                        <p class="text-[11px] text-coffee-milk leading-5 min-h-[40px]">${item.description || ''}</p>
                        <div class="grid grid-cols-2 gap-2">
                            <button onclick="editMenuItem('${item.id}')" class="bg-white border border-coffee-sand text-coffee-dark text-xs font-bold py-2 rounded-xl hover:border-coffee-rust">Sửa</button>
                            <button onclick="deleteMenuItem('${item.id}')" class="bg-red-50 border border-red-200 text-red-700 text-xs font-bold py-2 rounded-xl hover:bg-red-600 hover:text-white">Xoá</button>
                        </div>
                    </div>
                </article>
            `).join('');
        }

        function editMenuItem(id) {
            const item = menuItems.find(entry => entry.id === id);
            if (!item) return;
            document.getElementById('menu-form-title').textContent = 'Chỉnh sửa món';
            document.getElementById('menu-id').value = item.id;
            document.getElementById('menu-name').value = item.name || '';
            document.getElementById('menu-category').value = item.category || 'Specialty';
            document.getElementById('menu-price').value = item.price || 0;
            document.getElementById('menu-sizes').value = (item.availableSizes || []).join(',');
            document.getElementById('menu-image').value = item.image || '';
            document.getElementById('menu-description').value = item.description || '';
        }

        function resetMenuForm() {
            document.getElementById('menu-form-title').textContent = 'Thêm món';
            document.getElementById('menu-id').value = '';
            document.getElementById('menu-name').value = '';
            document.getElementById('menu-category').value = 'Coffee';
            document.getElementById('menu-price').value = '';
            document.getElementById('menu-sizes').value = 'S,M,L';
            document.getElementById('menu-image').value = '';
            document.getElementById('menu-description').value = '';
        }

        async function submitMenuItem(event) {
            event.preventDefault();
            const id = document.getElementById('menu-id').value.trim();
            const payload = {
                name: document.getElementById('menu-name').value.trim(),
                category: document.getElementById('menu-category').value,
                price: Number(document.getElementById('menu-price').value || 0),
                availableSizes: document.getElementById('menu-sizes').value.split(',').map(s => s.trim()).filter(Boolean),
                image: document.getElementById('menu-image').value.trim(),
                description: document.getElementById('menu-description').value.trim()
            };
            const url = id ? 'api/menu/' + encodeURIComponent(id) : 'api/menu';
            const method = id ? 'PUT' : 'POST';
            const res = await fetch(url, {
                method,
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                toast(id ? 'Đã cập nhật món.' : 'Đã thêm món mới.', 'info');
                resetMenuForm();
                loadMenuItems();
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không lưu được món.');
            }
        }

        async function deleteMenuItem(id) {
            if (!confirm('Xoá món này khỏi thực đơn đang bán?')) return;
            const res = await fetch('api/menu/delete', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id })
            });
            if (res.ok) {
                toast('Đã xoá món khỏi thực đơn.', 'info');
                loadMenuItems();
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không xoá được món.');
            }
        }
    </script>
</body>
</html>
