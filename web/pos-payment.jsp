<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>POS & Payment — nhà cà phê</title>
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
    <style>
        body { font-family: 'Inter', sans-serif; background:#FAF8F3; color:#2B1B17; }
        .font-serif { font-family:'Playfair Display', serif; }
        .font-mono { font-family:'JetBrains Mono', monospace; }
        .scrollbar-thin::-webkit-scrollbar { width: 6px; height: 6px; }
        .scrollbar-thin::-webkit-scrollbar-thumb { background: rgba(160,68,35,.25); border-radius: 999px; }
        .pay-method-active { background:#2B1B17; color:#FAF7EE; border-color:#2B1B17; }
    </style>
    <link rel="stylesheet" href="assets/css/pro-ui.css">
    <script>
        (function() {
            var role = localStorage.getItem('auth_role') || '';
            if (role && role !== 'manager' && role !== 'waiter') {
                window.location.href = 'login.jsp';
            }
        })();
    </script>
</head>
<body class="min-h-screen">
    <main class="min-h-screen grid grid-cols-1 xl:grid-cols-[280px_1fr]">
        <aside class="bg-white border-r border-coffee-sand/70 p-5 xl:sticky xl:top-0 xl:h-screen flex xl:flex-col gap-4 overflow-x-auto xl:overflow-visible">
            <div class="shrink-0 space-y-1 min-w-[190px]">
                <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Cashier workspace</p>
                <h1 class="font-serif italic font-bold text-2xl text-coffee-dark">POS & Payment</h1>
                <p class="text-xs text-coffee-milk leading-5">Thu ngân và chốt ca.</p>
            </div>

            <nav class="flex xl:flex-col gap-2 text-xs font-bold shrink-0">
                <a href="dashboard.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-coffee-light text-coffee-dark">Dashboard</a>
                <a href="waitstation.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Bán hàng</a>
                <a href="staff-orders.jsp" class="px-3 py-2 rounded-xl border border-coffee-sand bg-white text-coffee-milk hover:text-coffee-rust">Đơn hàng</a>
                <a href="pos-payment.jsp" class="px-3 py-2 rounded-xl border border-coffee-rust bg-coffee-rust text-white">Thu ngân POS</a>
            </nav>

            <section class="xl:mt-auto bg-coffee-light border border-coffee-sand rounded-2xl p-4 min-w-[260px] space-y-3">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Ca thu ngân</p>
                        <h2 id="shift-status-label" class="text-sm font-bold text-coffee-dark">Chưa mở ca</h2>
                    </div>
                    <span id="shift-dot" class="w-3 h-3 rounded-full bg-coffee-sand"></span>
                </div>
                <div class="grid grid-cols-2 gap-2">
                    <input id="opening-cash" type="number" min="0" placeholder="Tiền đầu ca" class="px-3 py-2 rounded-xl border border-coffee-sand text-xs bg-white outline-none focus:border-coffee-rust">
                    <button onclick="openShift()" class="bg-coffee-dark text-white rounded-xl text-xs font-bold">Mở ca</button>
                    <input id="closing-cash" type="number" min="0" placeholder="Tiền cuối ca" class="px-3 py-2 rounded-xl border border-coffee-sand text-xs bg-white outline-none focus:border-coffee-rust">
                    <button onclick="closeShift()" class="bg-white border border-coffee-sand text-coffee-dark rounded-xl text-xs font-bold">Đóng ca</button>
                </div>
                <div id="shift-summary" class="text-[11px] text-coffee-milk leading-5"></div>
            </section>
        </aside>

        <section class="p-4 sm:p-6 lg:p-8 space-y-5">
            <header class="flex flex-col lg:flex-row lg:items-end justify-between gap-4">
                <div>
                    <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Payment processing</p>
                    <h2 class="font-serif italic font-bold text-3xl text-coffee-dark">Trạm thu ngân</h2>
                    <p class="text-sm text-coffee-milk mt-1">Chọn đơn và chốt thanh toán.</p>
                </div>
                <div class="grid grid-cols-3 gap-3 min-w-full lg:min-w-[520px]">
                    <div class="bg-white border border-coffee-sand rounded-2xl p-3">
                        <p class="text-[10px] text-coffee-milk font-bold uppercase">Đơn cần thu</p>
                        <p id="stat-open-orders" class="font-serif text-2xl font-bold">0</p>
                    </div>
                    <div class="bg-white border border-coffee-sand rounded-2xl p-3">
                        <p class="text-[10px] text-coffee-milk font-bold uppercase">Chưa thanh toán</p>
                        <p id="stat-open-total" class="font-serif text-2xl font-bold">0 ₫</p>
                    </div>
                    <button onclick="loadPosState()" class="bg-coffee-rust text-white rounded-2xl text-xs font-bold uppercase tracking-wide">Làm mới</button>
                </div>
            </header>

            <div class="grid grid-cols-1 lg:grid-cols-[minmax(320px,420px)_1fr] gap-5">
                <section class="bg-white border border-coffee-sand rounded-3xl overflow-hidden">
                    <div class="p-4 border-b border-coffee-sand flex items-center justify-between gap-3">
                        <div>
                            <h3 class="font-serif italic font-bold text-lg">POS Order List</h3>
                            <p class="text-[11px] text-coffee-milk">Chưa thanh toán</p>
                        </div>
                        <select id="order-filter" onchange="drawOrderList()" class="bg-coffee-light border border-coffee-sand rounded-xl text-xs font-bold px-3 py-2 outline-none">
                            <option value="open">Đang mở</option>
                            <option value="ready">Sẵn sàng</option>
                            <option value="all">Tất cả</option>
                        </select>
                    </div>
                    <div id="order-list" class="max-h-[680px] overflow-y-auto scrollbar-thin p-3 space-y-2"></div>
                </section>

                <section class="grid grid-cols-1 xl:grid-cols-[1fr_360px] gap-5">
                    <div class="bg-white border border-coffee-sand rounded-3xl p-5 space-y-5">
                        <div class="flex items-start justify-between gap-4 border-b border-coffee-sand pb-4">
                            <div>
                                <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Hóa đơn đang chọn</p>
                                <h3 id="selected-title" class="font-serif italic font-bold text-2xl text-coffee-dark">Chưa chọn đơn</h3>
                                <p id="selected-subtitle" class="text-xs text-coffee-milk mt-1">Chọn một đơn ở danh sách bên trái.</p>
                            </div>
                            <div class="text-right">
                                <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Tổng cần thu</p>
                                <p id="selected-total" class="font-mono text-xl font-bold text-coffee-rust">0 ₫</p>
                            </div>
                        </div>

                        <div id="selected-items" class="space-y-2 min-h-[180px]"></div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 border-t border-coffee-sand pt-4">
                            <div class="space-y-2">
                                <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Tách bill</p>
                                <div class="flex gap-2">
                                    <input id="split-parts" type="number" min="1" max="20" value="2" class="w-24 px-3 py-2 rounded-xl border border-coffee-sand bg-coffee-light text-xs font-bold outline-none focus:border-coffee-rust">
                                    <button onclick="splitSelectedBill()" class="px-4 py-2 bg-coffee-dark text-white rounded-xl text-xs font-bold">Tách bill</button>
                                </div>
                                <div id="split-result" class="text-xs text-coffee-milk space-y-1"></div>
                            </div>
                            <div class="space-y-2">
                                <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Ghi chú thu ngân</p>
                                <input id="payment-reference" type="text" placeholder="Mã giao dịch / nội dung chuyển khoản" class="w-full px-3 py-2 rounded-xl border border-coffee-sand bg-coffee-light text-xs outline-none focus:border-coffee-rust">
                                <p class="text-[11px] text-coffee-milk">Mã đối soát thanh toán.</p>
                            </div>
                        </div>
                    </div>

                    <aside class="bg-white border border-coffee-sand rounded-3xl p-5 space-y-4">
                        <div>
                            <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Payment Processing</p>
                            <h3 class="font-serif italic font-bold text-xl">Chốt thanh toán</h3>
                        </div>

                        <div class="grid grid-cols-3 gap-2">
                            <button id="method-cash" onclick="setPaymentMethod('Cash')" class="pay-method-active border border-coffee-sand rounded-xl py-2 text-xs font-bold">Tiền mặt</button>
                            <button id="method-bank" onclick="setPaymentMethod('VietQR')" class="border border-coffee-sand rounded-xl py-2 text-xs font-bold bg-white">VietQR</button>
                            <button id="method-card" onclick="setPaymentMethod('Card')" class="border border-coffee-sand rounded-xl py-2 text-xs font-bold bg-white">Thẻ</button>
                        </div>

                        <label class="block space-y-1">
                            <span class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk">Khách đưa / ngân hàng báo</span>
                            <input id="payment-amount" type="number" min="0" class="w-full px-3 py-3 rounded-xl border border-coffee-sand bg-coffee-light text-sm font-bold outline-none focus:border-coffee-rust">
                        </label>

                        <div class="bg-coffee-light border border-coffee-sand rounded-2xl p-4 text-xs space-y-2">
                            <div class="flex justify-between"><span class="text-coffee-milk">Cần thu</span><strong id="pay-due">0 ₫</strong></div>
                            <div class="flex justify-between"><span class="text-coffee-milk">Tiền thừa</span><strong id="pay-change">0 ₫</strong></div>
                            <div class="flex justify-between"><span class="text-coffee-milk">Phương thức</span><strong id="pay-method-label">Tiền mặt</strong></div>
                        </div>

                        <button onclick="confirmPayment()" class="w-full bg-coffee-rust text-white rounded-2xl py-3 text-xs font-bold uppercase tracking-wide">Xác nhận đã thanh toán</button>
                        <button onclick="simulateBankWebhook()" class="w-full bg-white border border-coffee-sand text-coffee-dark rounded-2xl py-3 text-xs font-bold uppercase tracking-wide">Xác nhận chuyển khoản</button>

                        <div class="border-t border-coffee-sand pt-4">
                            <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk mb-2">Giao dịch gần đây</p>
                            <div id="payment-events" class="space-y-2 max-h-[220px] overflow-y-auto scrollbar-thin"></div>
                        </div>
                    </aside>
                </section>
            </div>
        </section>
    </main>

    <script>
        let orders = [];
        let selectedOrderId = '';
        let selectedMethod = 'Cash';
        let shiftSnapshot = { shift: null, events: [] };

        const statusText = {
            Pending: 'Chờ quầy',
            Preparing: 'Đang pha',
            Ready: 'Sẵn sàng',
            Served: 'Đã thanh toán'
        };

        function formatVND(value) {
            return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(Number(value || 0));
        }

        function activeOrders() {
            return orders.filter(order => order.status !== 'Served');
        }

        async function loadPosState() {
            const [ordersRes, shiftRes] = await Promise.all([
                fetch('api/orders', { credentials: 'same-origin' }),
                fetch('api/pos/shift', { credentials: 'same-origin' })
            ]);
            if (ordersRes.ok) orders = await ordersRes.json();
            if (shiftRes.ok) shiftSnapshot = await shiftRes.json();

            if (!selectedOrderId || !orders.some(order => order.id === selectedOrderId && order.status !== 'Served')) {
                const firstOpen = activeOrders()[0];
                selectedOrderId = firstOpen ? firstOpen.id : '';
            }

            drawOrderList();
            drawSelectedOrder();
            drawShift();
            drawEvents();
        }

        function drawOrderList() {
            const target = document.getElementById('order-list');
            const filter = document.getElementById('order-filter').value;
            let list = orders.slice();
            if (filter === 'open') list = list.filter(order => order.status !== 'Served');
            if (filter === 'ready') list = list.filter(order => order.status === 'Ready');

            const open = activeOrders();
            document.getElementById('stat-open-orders').innerText = open.length;
            document.getElementById('stat-open-total').innerText = formatVND(open.reduce((sum, order) => sum + Number(order.totalAmount || 0), 0));

            if (list.length === 0) {
                target.innerHTML = '<div class="text-center text-xs text-coffee-milk py-12">Không có đơn phù hợp bộ lọc.</div>';
                return;
            }

            target.innerHTML = list.map(order => {
                const active = order.id === selectedOrderId;
                const disabled = order.status === 'Served';
                return `
                    <button onclick="selectOrder('${order.id}')" class="w-full text-left border rounded-2xl p-3 transition-all ${active ? 'bg-coffee-dark text-white border-coffee-dark' : 'bg-white border-coffee-sand hover:border-coffee-rust'} ${disabled ? 'opacity-60' : ''}">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[10px] font-mono font-bold ${active ? 'text-coffee-sand' : 'text-coffee-milk'}">#${order.orderNumber || '--'} • ${order.tableName || 'Mang đi'}</p>
                                <h4 class="font-serif italic font-bold text-lg">${order.tableName || 'Không có bàn'}</h4>
                                <p class="text-[11px] ${active ? 'text-coffee-sand' : 'text-coffee-milk'}">${(order.items || []).length} dòng món • ${statusText[order.status] || order.status}</p>
                            </div>
                            <span class="font-mono text-sm font-bold ${active ? 'text-white' : 'text-coffee-rust'}">${formatVND(order.totalAmount)}</span>
                        </div>
                    </button>
                `;
            }).join('');
        }

        function selectOrder(orderId) {
            selectedOrderId = orderId;
            document.getElementById('split-result').innerHTML = '';
            drawOrderList();
            drawSelectedOrder();
        }

        function selectedOrder() {
            return orders.find(order => order.id === selectedOrderId) || null;
        }

        function drawSelectedOrder() {
            const order = selectedOrder();
            if (!order) {
                document.getElementById('selected-title').innerText = 'Chưa chọn đơn';
                document.getElementById('selected-subtitle').innerText = 'Chọn một đơn ở danh sách bên trái.';
                document.getElementById('selected-total').innerText = formatVND(0);
                document.getElementById('selected-items').innerHTML = '<div class="text-center text-xs text-coffee-milk py-16">Chưa có hóa đơn để xử lý.</div>';
                document.getElementById('payment-amount').value = '';
                updatePaymentMath();
                return;
            }

            document.getElementById('selected-title').innerText = `${order.tableName || 'Không có bàn'} • #${order.orderNumber}`;
            document.getElementById('selected-subtitle').innerText = `${statusText[order.status] || order.status} • ${order.createdAt || ''}`;
            document.getElementById('selected-total').innerText = formatVND(order.totalAmount);
            document.getElementById('payment-amount').value = order.totalAmount || 0;

            document.getElementById('selected-items').innerHTML = (order.items || []).map(item => {
                const custom = item.customization || {};
                return `
                    <div class="border border-coffee-sand rounded-2xl p-3 flex items-start justify-between gap-4">
                        <div>
                            <h4 class="font-bold text-sm">${item.name}</h4>
                            <p class="text-[11px] text-coffee-milk">SL ${item.quantity} • Size ${custom.size || 'M'} • Ngọt ${custom.sugar || '100%'} • Đá ${custom.ice || '100%'}</p>
                            ${item.notes ? `<p class="text-[10px] text-coffee-rust italic mt-1">${item.notes}</p>` : ''}
                        </div>
                        <div class="text-right">
                            <p class="font-mono font-bold text-coffee-rust">${formatVND((item.price || 0) * (item.quantity || 1))}</p>
                            <p class="text-[10px] text-coffee-milk">${statusText[item.status] || item.status}</p>
                        </div>
                    </div>
                `;
            }).join('');
            updatePaymentMath();
        }

        function setPaymentMethod(method) {
            selectedMethod = method;
            ['cash', 'bank', 'card'].forEach(key => {
                document.getElementById('method-' + key).className = 'border border-coffee-sand rounded-xl py-2 text-xs font-bold bg-white';
            });
            const activeId = method === 'VietQR' ? 'method-bank' : method === 'Card' ? 'method-card' : 'method-cash';
            document.getElementById(activeId).className = 'pay-method-active border rounded-xl py-2 text-xs font-bold';
            document.getElementById('pay-method-label').innerText = method === 'VietQR' ? 'Chuyển khoản' : method === 'Card' ? 'Thẻ' : 'Tiền mặt';
            updatePaymentMath();
        }

        function updatePaymentMath() {
            const order = selectedOrder();
            const due = order ? Number(order.totalAmount || 0) : 0;
            const paid = Number(document.getElementById('payment-amount').value || 0);
            document.getElementById('pay-due').innerText = formatVND(due);
            document.getElementById('pay-change').innerText = formatVND(Math.max(0, paid - due));
        }

        async function confirmPayment() {
            const order = selectedOrder();
            if (!order) {
                alert('Vui lòng chọn đơn cần thanh toán.');
                return;
            }
            const amount = Number(document.getElementById('payment-amount').value || 0);
            const reference = document.getElementById('payment-reference').value;
            const res = await fetch('api/payments/confirm', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ orderId: order.id, method: selectedMethod, amount, reference })
            });
            const data = await res.json().catch(() => ({}));
            if (!res.ok) {
                alert(data.error || 'Không thể chốt thanh toán.');
                return;
            }
            alert('Đã thanh toán và trả bàn thành công.');
            await loadPosState();
        }

        async function simulateBankWebhook() {
            const order = selectedOrder();
            if (!order) {
                alert('Vui lòng chọn đơn để xác nhận thanh toán.');
                return;
            }
            const res = await fetch('api/payments/webhook', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Bank-Webhook-Token': 'bank-webhook-token'
                },
                body: JSON.stringify({
                    orderId: order.id,
                    amount: Number(document.getElementById('payment-amount').value || order.totalAmount),
                    reference: document.getElementById('payment-reference').value || `BANK-ORDER-${order.orderNumber}`,
                    bankTrace: 'SIMULATED-SUCCESS'
                })
            });
            const data = await res.json().catch(() => ({}));
            if (!res.ok) {
                alert(data.error || 'Xác nhận chuyển khoản thất bại.');
                return;
            }
            alert('Ngân hàng đã xác nhận chuyển khoản thành công.');
            await loadPosState();
        }

        async function splitSelectedBill() {
            const order = selectedOrder();
            if (!order) {
                alert('Vui lòng chọn đơn cần tách bill.');
                return;
            }
            const parts = Number(document.getElementById('split-parts').value || 2);
            const res = await fetch(`api/orders/${order.id}/split-bill`, {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ parts })
            });
            const data = await res.json().catch(() => ({}));
            if (!res.ok) {
                alert(data.error || 'Không thể tách bill.');
                return;
            }
            document.getElementById('split-result').innerHTML = data.shares.map(share =>
                `<div class="flex justify-between border-b border-coffee-sand/60 py-1"><span>${share.name}</span><strong>${formatVND(share.amount)}</strong></div>`
            ).join('');
        }

        async function openShift() {
            const openingCash = Number(document.getElementById('opening-cash').value || 0);
            const cashierName = localStorage.getItem('auth_user') || 'Thu ngân';
            const res = await fetch('api/pos/shift/open', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ openingCash, cashierName })
            });
            if (!res.ok) {
                const data = await res.json().catch(() => ({}));
                alert(data.error || 'Không mở được ca.');
                return;
            }
            await loadPosState();
        }

        async function closeShift() {
            const closingCash = Number(document.getElementById('closing-cash').value || 0);
            const res = await fetch('api/pos/shift/close', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ closingCash, notes: 'Chốt ca từ POS' })
            });
            const data = await res.json().catch(() => ({}));
            if (!res.ok) {
                alert(data.error || 'Không đóng được ca.');
                return;
            }
            await loadPosState();
        }

        function drawShift() {
            const shift = shiftSnapshot.shift;
            const label = document.getElementById('shift-status-label');
            const dot = document.getElementById('shift-dot');
            const summary = document.getElementById('shift-summary');
            if (!shift) {
                label.innerText = 'Chưa mở ca';
                dot.className = 'w-3 h-3 rounded-full bg-coffee-sand';
                summary.innerHTML = 'Nhập tiền đầu ca rồi bấm <b>Mở ca</b>. Nếu quên, ca sẽ tự mở khi có thanh toán đầu tiên.';
                return;
            }
            const open = shift.status === 'OPEN';
            label.innerText = open ? `Đang mở • ${shift.cashierName}` : `Đã đóng • ${shift.cashierName}`;
            dot.className = open ? 'w-3 h-3 rounded-full bg-emerald-500' : 'w-3 h-3 rounded-full bg-coffee-sand';
            summary.innerHTML = `
                <div class="grid grid-cols-2 gap-x-3 gap-y-1">
                    <span>Doanh thu</span><b class="text-right">${formatVND(shift.totalRevenue)}</b>
                    <span>Tiền mặt</span><b class="text-right">${formatVND(shift.cashTotal)}</b>
                    <span>Chuyển khoản</span><b class="text-right">${formatVND(shift.bankTotal)}</b>
                    <span>Thẻ</span><b class="text-right">${formatVND(shift.cardTotal)}</b>
                </div>
            `;
        }

        function drawEvents() {
            const target = document.getElementById('payment-events');
            const events = shiftSnapshot.events || [];
            if (events.length === 0) {
                target.innerHTML = '<p class="text-xs text-coffee-milk">Chưa có giao dịch.</p>';
                return;
            }
            target.innerHTML = events.slice(0, 8).map(event => `
                <div class="bg-coffee-light border border-coffee-sand rounded-xl p-2">
                    <div class="flex justify-between gap-2">
                        <span class="font-bold">#${event.orderNumber || '--'} • ${event.method}</span>
                        <b class="font-mono text-coffee-rust">${formatVND(event.expectedAmount || event.amount)}</b>
                    </div>
                    <p class="text-[10px] text-coffee-milk">${event.createdAt || ''} • ${event.reference || ''}</p>
                </div>
            `).join('');
        }

        document.getElementById('payment-amount').addEventListener('input', updatePaymentMath);
        loadPosState();
        setInterval(loadPosState, 10000);
    </script>
</body>
</html>
