<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nhà cà phê. — khuyến mãi</title>
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
                <h1 class="font-serif italic font-bold text-2xl text-coffee-dark">Khuyến mãi</h1>
            </div>
            <nav class="flex xl:flex-col gap-2 text-xs font-bold shrink-0">
                <a href="dashboard.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Dashboard</a>
                <a href="admin-menu.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Thực đơn</a>
                <a href="promotions.jsp" class="px-3 py-2 rounded-xl border border-coffee-rust bg-coffee-rust text-white">Khuyến mãi</a>
                <a href="customers.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Khách hàng</a>
                <a href="inventory.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Kho hàng</a>
                <a href="reports.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Báo cáo</a>
            </nav>
        </aside>

        <section class="p-4 sm:p-6 lg:p-8 space-y-6">
            <header class="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-coffee-sand/70 pb-5">
                <div>
                    <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Voucher catalog</p>
                    <h2 class="font-serif italic font-bold text-3xl text-coffee-dark">Quản lý voucher</h2>
                </div>
                <div class="flex items-center gap-2">
                    <button onclick="resetVoucherForm()" class="bg-white border border-coffee-sand text-coffee-dark text-xs font-bold px-4 py-2 rounded-xl hover:border-coffee-rust">Tạo voucher mới</button>
                    <button onclick="loadVouchers()" class="bg-coffee-dark text-white text-xs font-bold px-4 py-2 rounded-xl hover:bg-coffee-rust">Làm mới</button>
                </div>
            </header>

            <div class="grid grid-cols-1 xl:grid-cols-[1fr_380px] gap-6 items-start">
                <section class="bg-white border border-coffee-sand rounded-3xl shadow-sm overflow-hidden">
                    <div class="p-5 border-b border-coffee-sand/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <div>
                            <h3 class="font-serif italic font-bold text-lg text-coffee-dark">Danh sách voucher</h3>
                            <p id="voucher-count-label" class="text-[11px] text-coffee-milk">Đang tải...</p>
                        </div>
                        <input id="voucher-search" oninput="renderVouchers()" type="text" placeholder="Tìm mã hoặc tên..." class="bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 text-xs outline-none focus:border-coffee-rust">
                    </div>
                    <div id="voucher-grid" class="grid grid-cols-1 md:grid-cols-2 2xl:grid-cols-3 gap-4 p-5"></div>
                </section>

                <section class="bg-white border border-coffee-sand rounded-3xl shadow-sm p-5 space-y-4 xl:sticky xl:top-6">
                    <div class="border-b border-coffee-sand/70 pb-3">
                        <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Voucher form</p>
                        <h3 id="voucher-form-title" class="font-serif italic font-bold text-lg text-coffee-dark">Thêm voucher</h3>
                    </div>
                    <form onsubmit="submitVoucher(event)" class="space-y-3 text-xs">
                        <div class="space-y-1">
                            <label class="font-bold text-coffee-dark block">Mã voucher</label>
                            <input id="voucher-code" required type="text" placeholder="Ví dụ: CAFE20" class="uppercase w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust font-mono">
                        </div>
                        <div class="space-y-1">
                            <label class="font-bold text-coffee-dark block">Tên hiển thị</label>
                            <input id="voucher-name" required type="text" placeholder="Voucher giảm 20,000đ" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                        </div>
                        <div class="grid grid-cols-2 gap-2">
                            <div class="space-y-1">
                                <label class="font-bold text-coffee-dark block">Mức giảm</label>
                                <input id="voucher-discount" required min="1000" step="1000" type="number" placeholder="20000" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                            </div>
                            <div class="space-y-1">
                                <label class="font-bold text-coffee-dark block">Giá đổi</label>
                                <input id="voucher-cost" required min="1" step="1" type="number" placeholder="150" class="w-full bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                            </div>
                        </div>
                        <label class="flex items-center justify-between gap-3 bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 cursor-pointer">
                            <span class="font-bold text-coffee-dark">Đang cho khách đổi</span>
                            <input id="voucher-active" type="checkbox" checked class="accent-[#A04423] w-4 h-4">
                        </label>
                        <div class="grid grid-cols-2 gap-2 pt-1">
                            <button type="submit" class="bg-coffee-rust text-white py-2.5 rounded-xl font-bold hover:bg-coffee-rust/95">Lưu voucher</button>
                            <button type="button" onclick="resetVoucherForm()" class="bg-white border border-coffee-sand text-coffee-dark py-2.5 rounded-xl font-bold hover:border-coffee-rust">Huỷ</button>
                        </div>
                    </form>
                </section>
            </div>
        </section>
    </main>

    <script>
        let vouchers = [];

        document.addEventListener('DOMContentLoaded', loadVouchers);

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

        async function loadVouchers() {
            const grid = document.getElementById('voucher-grid');
            grid.innerHTML = '<div class="text-xs text-coffee-milk">Đang tải voucher...</div>';
            try {
                const res = await fetch('api/vouchers', { credentials: 'same-origin' });
                if (!res.ok) throw new Error('Voucher request failed');
                vouchers = await res.json();
                renderVouchers();
            } catch (e) {
                grid.innerHTML = '<div class="text-xs text-red-600">Không tải được danh sách voucher.</div>';
            }
        }

        function renderVouchers() {
            const grid = document.getElementById('voucher-grid');
            const keyword = (document.getElementById('voucher-search').value || '').toLowerCase().trim();
            const list = vouchers.filter(item => {
                const text = [item.code, item.name, item.discountAmount, item.pointCost].join(' ').toLowerCase();
                return !keyword || text.indexOf(keyword) !== -1;
            });
            document.getElementById('voucher-count-label').textContent = list.length + ' voucher trong hệ thống';
            if (!list.length) {
                grid.innerHTML = '<div class="text-xs text-coffee-milk">Không có voucher phù hợp.</div>';
                return;
            }
            grid.innerHTML = list.map(item => `
                <article class="border border-coffee-sand rounded-2xl bg-coffee-light/45 p-4 space-y-3">
                    <div class="flex items-start justify-between gap-3">
                        <div>
                            <span class="inline-block bg-white border border-coffee-sand rounded-lg px-2 py-1 text-[10px] font-mono font-bold text-coffee-rust">${item.code}</span>
                            <h4 class="font-serif italic font-bold text-base text-coffee-dark mt-2">${item.name}</h4>
                        </div>
                        <span class="${item.active ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-zinc-50 text-zinc-500 border-zinc-200'} border text-[9px] uppercase font-bold px-2 py-1 rounded-full">${item.active ? 'Đang bật' : 'Đã tắt'}</span>
                    </div>
                    <div class="grid grid-cols-2 gap-2 text-xs">
                        <div class="bg-white border border-coffee-sand/70 rounded-xl p-3">
                            <p class="text-[10px] text-coffee-milk uppercase font-bold">Mức giảm</p>
                            <p class="font-mono font-bold text-coffee-rust mt-1">${formatVND(item.discountAmount)}</p>
                        </div>
                        <div class="bg-white border border-coffee-sand/70 rounded-xl p-3">
                            <p class="text-[10px] text-coffee-milk uppercase font-bold">Giá đổi</p>
                            <p class="font-mono font-bold text-coffee-dark mt-1">${item.pointCost} hạt</p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                        <button onclick="editVoucher('${item.code}')" class="bg-white border border-coffee-sand text-coffee-dark text-xs font-bold py-2 rounded-xl hover:border-coffee-rust">Sửa</button>
                        <button onclick="deleteVoucher('${item.code}')" class="bg-red-50 border border-red-200 text-red-700 text-xs font-bold py-2 rounded-xl hover:bg-red-600 hover:text-white">Xoá</button>
                    </div>
                </article>
            `).join('');
        }

        function editVoucher(code) {
            const item = vouchers.find(entry => entry.code === code);
            if (!item) return;
            document.getElementById('voucher-form-title').textContent = 'Chỉnh sửa voucher';
            document.getElementById('voucher-code').value = item.code || '';
            document.getElementById('voucher-code').disabled = true;
            document.getElementById('voucher-code').classList.add('opacity-70', 'cursor-not-allowed');
            document.getElementById('voucher-name').value = item.name || '';
            document.getElementById('voucher-discount').value = item.discountAmount || 0;
            document.getElementById('voucher-cost').value = item.pointCost || 0;
            document.getElementById('voucher-active').checked = !!item.active;
        }

        function resetVoucherForm() {
            document.getElementById('voucher-form-title').textContent = 'Thêm voucher';
            document.getElementById('voucher-code').disabled = false;
            document.getElementById('voucher-code').classList.remove('opacity-70', 'cursor-not-allowed');
            document.getElementById('voucher-code').value = '';
            document.getElementById('voucher-name').value = '';
            document.getElementById('voucher-discount').value = '';
            document.getElementById('voucher-cost').value = '';
            document.getElementById('voucher-active').checked = true;
        }

        async function submitVoucher(event) {
            event.preventDefault();
            const payload = {
                code: document.getElementById('voucher-code').value.trim().toUpperCase(),
                name: document.getElementById('voucher-name').value.trim(),
                discountAmount: Number(document.getElementById('voucher-discount').value || 0),
                pointCost: Number(document.getElementById('voucher-cost').value || 0),
                active: document.getElementById('voucher-active').checked
            };
            const res = await fetch('api/vouchers', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                toast('Đã lưu voucher.', 'info');
                resetVoucherForm();
                loadVouchers();
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không lưu được voucher.');
            }
        }

        async function deleteVoucher(code) {
            if (!confirm('Xoá voucher này khỏi hệ thống?')) return;
            const res = await fetch('api/vouchers/delete', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ code })
            });
            if (res.ok) {
                toast('Đã xoá voucher.', 'info');
                resetVoucherForm();
                loadVouchers();
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không xoá được voucher.');
            }
        }
    </script>
</body>
</html>
