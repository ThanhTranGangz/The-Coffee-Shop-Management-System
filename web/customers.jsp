<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nhà cà phê. — khách hàng</title>
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
                <h1 class="font-serif italic font-bold text-2xl text-coffee-dark">Khách hàng</h1>
            </div>
            <nav class="flex xl:flex-col gap-2 text-xs font-bold shrink-0">
                <a href="dashboard.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Dashboard</a>
                <a href="admin-menu.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Thực đơn</a>
                <a href="promotions.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Khuyến mãi</a>
                <a href="customers.jsp" class="px-3 py-2 rounded-xl border border-coffee-rust bg-coffee-rust text-white">Khách hàng</a>
                <a href="inventory.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Kho hàng</a>
                <a href="reports.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Báo cáo</a>
            </nav>
        </aside>

        <section class="p-4 sm:p-6 lg:p-8 space-y-6">
            <header class="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-coffee-sand/70 pb-5">
                <div>
                    <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Member CRM</p>
                    <h2 class="font-serif italic font-bold text-3xl text-coffee-dark">Quản lý khách hàng</h2>
                </div>
                <div class="flex items-center gap-2">
                    <button onclick="loadCustomers()" class="bg-coffee-dark text-white text-xs font-bold px-4 py-2 rounded-xl hover:bg-coffee-rust">Làm mới</button>
                </div>
            </header>

            <div class="grid grid-cols-1 xl:grid-cols-[1fr_390px] gap-6 items-start">
                <section class="bg-white border border-coffee-sand rounded-3xl shadow-sm overflow-hidden">
                    <div class="p-5 border-b border-coffee-sand/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <div>
                            <h3 class="font-serif italic font-bold text-lg text-coffee-dark">Danh sách khách hàng</h3>
                            <p id="customer-count-label" class="text-[11px] text-coffee-milk">Đang tải...</p>
                        </div>
                        <input id="customer-search" oninput="renderCustomers()" type="text" placeholder="Tìm tên hoặc số điện thoại..." class="bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 text-xs outline-none focus:border-coffee-rust">
                    </div>
                    <div id="customers-grid" class="grid grid-cols-1 md:grid-cols-2 2xl:grid-cols-3 gap-4 p-5"></div>
                </section>

                <section class="bg-white border border-coffee-sand rounded-3xl shadow-sm p-5 space-y-4 xl:sticky xl:top-6">
                    <div class="border-b border-coffee-sand/70 pb-3">
                        <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Customer detail</p>
                        <h3 id="customer-panel-title" class="font-serif italic font-bold text-lg text-coffee-dark">Thông tin khách</h3>
                    </div>

                    <div id="customer-empty-state" class="bg-coffee-light/55 border border-dashed border-coffee-sand rounded-2xl p-4 text-xs text-coffee-milk">
                        Chọn một khách hàng để xem thông tin và thao tác.
                    </div>

                    <div id="customer-detail-panel" class="hidden space-y-4">
                        <div class="bg-coffee-light/55 border border-coffee-sand rounded-2xl p-4 space-y-3">
                            <div class="flex items-start justify-between gap-3">
                                <div>
                                    <p id="detail-name" class="font-serif italic font-bold text-xl text-coffee-dark"></p>
                                    <p id="detail-phone" class="text-xs font-mono text-coffee-milk mt-1"></p>
                                </div>
                                <span id="detail-rank" class="bg-white border border-coffee-sand text-coffee-rust text-[10px] font-bold uppercase px-2 py-1 rounded-full"></span>
                            </div>
                            <div class="grid grid-cols-2 gap-2 text-xs">
                                <div class="bg-white border border-coffee-sand/70 rounded-xl p-3">
                                    <p class="text-[10px] text-coffee-milk uppercase font-bold">Điểm</p>
                                    <p id="detail-points" class="font-mono font-bold text-coffee-rust mt-1"></p>
                                </div>
                                <div class="bg-white border border-coffee-sand/70 rounded-xl p-3">
                                    <p class="text-[10px] text-coffee-milk uppercase font-bold">Sở thích</p>
                                    <p id="detail-pref" class="font-bold text-coffee-dark mt-1 truncate"></p>
                                </div>
                            </div>
                            <div class="text-xs space-y-1">
                                <p class="text-coffee-milk">Email: <span id="detail-email" class="text-coffee-dark font-medium"></span></p>
                                <p class="text-coffee-milk">Ưu đãi mặc định: <span id="detail-discount" class="text-coffee-dark font-medium"></span></p>
                            </div>
                            <div>
                                <p class="text-[10px] text-coffee-milk uppercase font-bold mb-2">Voucher đang có</p>
                                <div id="detail-vouchers" class="flex flex-wrap gap-2"></div>
                            </div>
                        </div>

                        <form onsubmit="submitAddPoints(event)" class="bg-white border border-coffee-sand rounded-2xl p-4 space-y-3 text-xs">
                            <h4 class="font-bold text-coffee-dark">Cộng điểm</h4>
                            <div class="grid grid-cols-[1fr_auto] gap-2">
                                <input id="points-input" required min="1" step="1" type="number" placeholder="Ví dụ: 50" class="bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust">
                                <button type="submit" class="bg-coffee-rust text-white px-4 py-2 rounded-xl font-bold hover:bg-coffee-rust/95">Cộng</button>
                            </div>
                        </form>

                        <form onsubmit="submitGiftVoucher(event)" class="bg-white border border-coffee-sand rounded-2xl p-4 space-y-3 text-xs">
                            <h4 class="font-bold text-coffee-dark">Tặng voucher</h4>
                            <div class="grid grid-cols-[1fr_auto] gap-2">
                                <select id="gift-voucher-select" required class="bg-coffee-light border border-coffee-sand rounded-xl px-3 py-2 outline-none focus:border-coffee-rust"></select>
                                <button type="submit" class="bg-coffee-dark text-white px-4 py-2 rounded-xl font-bold hover:bg-coffee-rust">Tặng</button>
                            </div>
                        </form>

                        <button onclick="deleteSelectedCustomer()" class="w-full bg-red-50 border border-red-200 text-red-700 text-xs font-bold py-2.5 rounded-xl hover:bg-red-600 hover:text-white transition-colors">
                            Xoá khách
                        </button>
                    </div>
                </section>
            </div>
        </section>
    </main>

    <script>
        let customers = [];
        let vouchers = [];
        let selectedPhone = '';

        document.addEventListener('DOMContentLoaded', loadCustomers);

        function toast(message, type) {
            if (window.appToast) {
                window.appToast(message, type || 'info');
            } else {
                alert(message);
            }
        }

        function esc(value) {
            return String(value || '').replace(/[&<>"']/g, function(ch) {
                return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
            });
        }

        function rankLabel(rank) {
            if (rank === 'Platinum') return 'Kim Cương';
            if (rank === 'Gold') return 'Vàng';
            return 'Bạc';
        }

        function voucherName(code) {
            const found = vouchers.find(item => String(item.code || '').toUpperCase() === String(code || '').toUpperCase());
            return found ? found.name : code;
        }

        async function loadCustomers() {
            const grid = document.getElementById('customers-grid');
            grid.innerHTML = '<div class="text-xs text-coffee-milk">Đang tải khách hàng...</div>';
            try {
                const [memberRes, voucherRes] = await Promise.all([
                    fetch('api/members', { credentials: 'same-origin' }),
                    fetch('api/vouchers', { credentials: 'same-origin' })
                ]);
                if (!memberRes.ok) throw new Error('Members request failed');
                customers = await memberRes.json();
                vouchers = voucherRes.ok ? await voucherRes.json() : [];
                renderVoucherSelect();
                renderCustomers();
                if (selectedPhone && !customers.some(member => member.phone === selectedPhone)) {
                    selectedPhone = '';
                    renderSelectedCustomer();
                } else if (selectedPhone) {
                    renderSelectedCustomer();
                }
            } catch (error) {
                grid.innerHTML = '<div class="text-xs text-red-600">Không tải được danh sách khách hàng.</div>';
            }
        }

        function renderCustomers() {
            const grid = document.getElementById('customers-grid');
            const keyword = (document.getElementById('customer-search').value || '').toLowerCase().trim();
            const list = customers.filter(member => {
                const text = [member.name, member.phone, member.rank, member.email, member.pref].join(' ').toLowerCase();
                return !keyword || text.indexOf(keyword) !== -1;
            });
            document.getElementById('customer-count-label').textContent = list.length + ' khách hàng';
            if (!list.length) {
                grid.innerHTML = '<div class="text-xs text-coffee-milk">Không có khách hàng phù hợp.</div>';
                return;
            }
            grid.innerHTML = list.map(member => {
                const selectedClass = selectedPhone === member.phone ? 'border-coffee-rust bg-coffee-light' : 'border-coffee-sand bg-coffee-light/45';
                const voucherCount = (member.vouchers || []).length;
                return `
                    <article class="${selectedClass} border rounded-2xl p-4 space-y-3">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <h4 class="font-serif italic font-bold text-base text-coffee-dark">${esc(member.name)}</h4>
                                <p class="text-[10px] font-mono text-coffee-milk mt-1">${esc(member.phone)}</p>
                            </div>
                            <span class="bg-white border border-coffee-sand text-coffee-rust text-[9px] uppercase font-bold px-2 py-1 rounded-full">${rankLabel(member.rank)}</span>
                        </div>
                        <div class="grid grid-cols-2 gap-2 text-xs">
                            <div class="bg-white border border-coffee-sand/70 rounded-xl p-3">
                                <p class="text-[10px] text-coffee-milk uppercase font-bold">Điểm</p>
                                <p class="font-mono font-bold text-coffee-rust mt-1">${Number(member.points || 0)}</p>
                            </div>
                            <div class="bg-white border border-coffee-sand/70 rounded-xl p-3">
                                <p class="text-[10px] text-coffee-milk uppercase font-bold">Voucher</p>
                                <p class="font-mono font-bold text-coffee-dark mt-1">${voucherCount}</p>
                            </div>
                        </div>
                        <div class="grid grid-cols-2 gap-2">
                            <button onclick='selectCustomer(${JSON.stringify(member.phone || '')})' class="bg-white border border-coffee-sand text-coffee-dark text-xs font-bold py-2 rounded-xl hover:border-coffee-rust">Xem</button>
                            <button onclick='deleteCustomer(${JSON.stringify(member.phone || '')})' class="bg-red-50 border border-red-200 text-red-700 text-xs font-bold py-2 rounded-xl hover:bg-red-600 hover:text-white">Xoá</button>
                        </div>
                    </article>
                `;
            }).join('');
        }

        function renderVoucherSelect() {
            const select = document.getElementById('gift-voucher-select');
            const active = vouchers.filter(voucher => voucher.active !== false);
            if (!active.length) {
                select.innerHTML = '<option value="">Chưa có voucher đang bật</option>';
                select.disabled = true;
                return;
            }
            select.disabled = false;
            select.innerHTML = active.map(voucher => `<option value="${esc(voucher.code)}">${esc(voucher.code)} - ${esc(voucher.name)}</option>`).join('');
        }

        function selectCustomer(phone) {
            selectedPhone = phone;
            renderCustomers();
            renderSelectedCustomer();
        }

        function selectedCustomer() {
            return customers.find(member => member.phone === selectedPhone) || null;
        }

        function renderSelectedCustomer() {
            const member = selectedCustomer();
            document.getElementById('customer-empty-state').classList.toggle('hidden', !!member);
            document.getElementById('customer-detail-panel').classList.toggle('hidden', !member);
            if (!member) {
                document.getElementById('customer-panel-title').textContent = 'Thông tin khách';
                return;
            }

            document.getElementById('customer-panel-title').textContent = 'Thông tin khách';
            document.getElementById('detail-name').textContent = member.name || 'Khách hàng';
            document.getElementById('detail-phone').textContent = member.phone || '';
            document.getElementById('detail-rank').textContent = rankLabel(member.rank);
            document.getElementById('detail-points').textContent = Number(member.points || 0) + ' điểm';
            document.getElementById('detail-pref').textContent = member.pref || '-';
            document.getElementById('detail-email').textContent = member.email || '-';
            document.getElementById('detail-discount').textContent = member.discount || '-';

            const box = document.getElementById('detail-vouchers');
            const owned = member.vouchers || [];
            if (!owned.length) {
                box.innerHTML = '<span class="text-xs text-coffee-milk">Chưa có voucher.</span>';
            } else {
                box.innerHTML = owned.map(code => `
                    <span title="${esc(voucherName(code))}" class="bg-white border border-coffee-sand text-coffee-rust text-[10px] font-mono font-bold px-2 py-1 rounded-lg">${esc(code)}</span>
                `).join('');
            }
        }

        function replaceCustomer(updated) {
            const idx = customers.findIndex(member => member.phone === updated.phone);
            if (idx >= 0) {
                customers[idx] = updated;
            } else {
                customers.push(updated);
            }
            selectedPhone = updated.phone;
            renderCustomers();
            renderSelectedCustomer();
        }

        async function submitAddPoints(event) {
            event.preventDefault();
            const member = selectedCustomer();
            if (!member) return;
            const points = Number(document.getElementById('points-input').value || 0);
            const res = await fetch('api/members/points', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ phone: member.phone, points })
            });
            if (res.ok) {
                const updated = await res.json();
                document.getElementById('points-input').value = '';
                replaceCustomer(updated);
                toast('Đã cộng điểm cho khách hàng.', 'info');
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không cộng được điểm.');
            }
        }

        async function submitGiftVoucher(event) {
            event.preventDefault();
            const member = selectedCustomer();
            const code = document.getElementById('gift-voucher-select').value;
            if (!member || !code) return;
            const res = await fetch('api/members/voucher', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ phone: member.phone, code })
            });
            if (res.ok) {
                const updated = await res.json();
                replaceCustomer(updated);
                toast('Đã tặng voucher cho khách hàng.', 'info');
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không tặng được voucher.');
            }
        }

        function deleteSelectedCustomer() {
            const member = selectedCustomer();
            if (member) {
                deleteCustomer(member.phone);
            }
        }

        async function deleteCustomer(phone) {
            const member = customers.find(entry => entry.phone === phone);
            const label = member ? member.name + ' (' + member.phone + ')' : phone;
            if (!confirm('Xoá khách hàng ' + label + '?')) return;
            const res = await fetch('api/members/delete', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ phone })
            });
            if (res.ok) {
                customers = customers.filter(entry => entry.phone !== phone);
                if (selectedPhone === phone) selectedPhone = '';
                renderCustomers();
                renderSelectedCustomer();
                toast('Đã xoá khách hàng.', 'info');
            } else {
                const error = await res.json().catch(() => ({}));
                alert(error.error || 'Không xoá được khách hàng.');
            }
        }
    </script>
</body>
</html>
