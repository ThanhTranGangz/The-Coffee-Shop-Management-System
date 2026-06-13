<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KDS Monitor — nhà cà phê.</title>
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        coffee: {
                            bg: '#F6F2E9',
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
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:ital,wght@0,600;0,700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #F6F2E9;
            color: #2B1B17;
        }
        .font-serif {
            font-family: 'Playfair Display', serif;
        }
        .font-mono {
            font-family: 'JetBrains Mono', monospace;
        }
        .dot-grid-bg {
            background-color: #F8F5EE;
            background-image: radial-gradient(#d3cbb6 1.2px, transparent 1.2px);
            background-size: 24px 24px;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col dot-grid-bg">

    <!-- NAVIGATION BAR -->
    <nav class="border-b border-coffee-sand bg-coffee-bg/95 sticky top-0 z-40 px-6 py-4">
        <div class="max-w-7xl mx-auto flex items-center justify-between">
            <div class="flex items-center gap-3">
                <span class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark">
                    nhà cà phê<span class="text-coffee-rust">.</span>
                </span>
                <span class="bg-coffee-rust text-white text-[10px] uppercase font-bold tracking-widest px-2.5 py-0.5 rounded-full font-mono">KDS MONITOR</span>
            </div>

            <div class="flex items-center gap-4">
                <div id="connection-status">
                     <span class="text-xs text-coffee-milk">Đang đồng bộ...</span>
                </div>

                <div class="hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>

                <a href="index.html" class="text-xs font-bold px-3 py-1 bg-white hover:bg-coffee-rust hover:text-white border border-coffee-sand rounded-xl shadow-xs transition-all cursor-pointer">
                    Đăng xuất KDS
                </a>
            </div>
        </div>
    </nav>

    <!-- BANNER TOAST -->
    <div id="flash-banner-container" class="hidden fixed bottom-6 right-6 z-50 max-w-sm w-full">
        <div class="bg-coffee-dark text-white border border-coffee-rust/50 px-4 py-3 rounded-2xl flex items-center gap-2.5 shadow-xl">
            <div class="w-8 h-8 rounded-full bg-coffee-rust flex items-center justify-center shrink-0">🍳</div>
            <div class="flex-1 text-xs">
                <p id="flash-message" class="font-medium text-coffee-bg"></p>
            </div>
        </div>
    </div>

    <!-- MAIN PORTAL WRAPPER -->
    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col justify-start space-y-6">
        
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-4.5 rounded-3xl border border-coffee-sand shadow-xs">
            <div>
                <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                    <span>🍳</span> Màn hình pha chế (Kitchen Display Monitor KDS)
                </h2>
                <p class="text-xs text-coffee-milk font-semibold">Theo dõi đơn đặt nước từ khách quét mã QR. Nhấp từng dòng nước để chuyển đổi tiến trình chế biến.</p>
            </div>
        </div>

        <!-- Empty queue placeholder message -->
        <div id="kds-empty-msg" class="hidden bg-white rounded-3xl border border-coffee-sand p-16 text-center text-coffee-milk space-y-2 max-w-lg mx-auto shadow-sm">
            <span class="text-4xl text-coffee-rust select-none">😴</span>
            <p class="font-serif italic font-bold text-coffee-dark text-base">Hiện không có nước cần pha chế!</p>
            <p class="text-xs">Tất cả các sản phẩm hạt phin hoặc trà sữa đều đã bàn giao phục vụ.</p>
        </div>

        <!-- Dynamic active orders grid queue -->
        <div id="kds-tickets-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <!-- Dynamic KDS cards -->
        </div>

    </main>

    <script id="kds-core-script">
        let menu = [];
        let tables = [];
        let orders = [];

        // Time ticker
        setInterval(() => {
            const clock = document.getElementById('nav-clock');
            if(clock) clock.innerText = new Date().toLocaleTimeString('vi-VN');
        }, 1000);

        function playAlertTone() {
            try {
                const AudioCtx = window.AudioContext || window.webkitAudioContext;
                if (!AudioCtx) return;
                const context = new AudioCtx();
                
                const synthTone = (freq, delay, length) => {
                    setTimeout(() => {
                        const osc = context.createOscillator();
                        const envelope = context.createGain();
                        osc.connect(envelope);
                        envelope.connect(context.destination);
                        osc.type = 'sine';
                        osc.frequency.setValueAtTime(freq, context.currentTime);
                        envelope.gain.setValueAtTime(0.12, context.currentTime);
                        envelope.gain.exponentialRampToValueAtTime(0.001, context.currentTime + length);
                        osc.start();
                        osc.stop(context.currentTime + length);
                    }, delay);
                };

                synthTone(523.25, 0, 0.25);   // C5
                synthTone(659.25, 100, 0.25); // E5
                synthTone(783.99, 200, 0.45); // G5
            } catch (err) {}
        }

        async function fetchStateCore() {
            try {
                const [rMenu, rTables, rOrders] = await Promise.all([
                    fetch('/api/menu'),
                    fetch('/api/tables'),
                    fetch('/api/orders')
                ]);

                if (rMenu.ok) menu = await rMenu.json();
                if (rTables.ok) tables = await rTables.json();
                if (rOrders.ok) orders = await rOrders.json();

                drawKDS();
            } catch (err) {
                console.error(err);
            }
        }

        function drawKDS() {
            const grid = document.getElementById('kds-tickets-grid');
            const emptyLabel = document.getElementById('kds-empty-msg');

            if (!grid) return;
            grid.innerHTML = '';

            const tickets = orders.filter(o => o.status !== 'Served');

            if (tickets.length === 0) {
                emptyLabel.classList.remove('hidden');
                grid.classList.add('hidden');
                return;
            }

            emptyLabel.classList.add('hidden');
            grid.classList.remove('hidden');

            tickets.forEach(o => {
                let cardBadge = 'bg-coffee-light border-coffee-sand text-coffee-milk';
                if (o.status === 'Preparing') cardBadge = 'bg-amber-100 border-amber-200 text-amber-800';
                else if (o.status === 'Ready') cardBadge = 'bg-emerald-100 border-emerald-250 text-emerald-805 animate-pulse';

                const ageMin = Math.floor((new Date() - new Date(o.createdAt)) / 60000);
                const ageText = ageMin <= 0 ? 'Vừa mới' : `${ageMin} phút trước`;

                const completeCount = o.items.filter(it => it.status === 'Ready' || it.status === 'Served').length;
                const ratio = Math.round((completeCount / o.items.length) * 100);

                let itemsRows = '';
                o.items.forEach(it => {
                    let rowClass = 'text-coffee-dark';
                    let stBadge = 'bg-coffee-light text-coffee-milk border-coffee-sand';
                    let label = 'Chờ xử lý';
                    let nStatus = 'Preparing';

                    if (it.status === 'Preparing') {
                        rowClass = 'text-amber-950 font-semibold';
                        stBadge = 'bg-amber-100 text-amber-800 border-amber-250';
                        label = 'Pha chế';
                        nStatus = 'Ready';
                    } else if (it.status === 'Ready') {
                        rowClass = 'text-emerald-900 line-through opacity-80';
                        stBadge = 'bg-emerald-100 text-emerald-800 border-emerald-250';
                        label = 'Giao đồ ☕';
                        nStatus = 'Served';
                    } else if (it.status === 'Served') {
                        rowClass = 'opacity-40 line-through';
                        stBadge = 'bg-coffee-rust/10 text-coffee-rust border-transparent';
                        label = 'Xong';
                        nStatus = 'Served';
                    }

                    const updateAction = it.status !== 'Served' ? `onclick="toggleBaristaItem('${o.id}', '${it.id}', '${nStatus}')"` : '';

                    itemsRows += `
                        <div ${updateAction} class="flex items-start justify-between p-2 rounded-xl transition-all border border-transparent hover:border-coffee-sand/40 ${it.status !== 'Served' ? 'hover:bg-coffee-light/50 cursor-pointer' : ''}">
                            <div class="space-y-0.5 pr-2">
                                <p class="text-xs ${rowClass}">
                                    ${it.name} <span class="font-mono text-xs opacity-85 font-bold">x${it.quantity}</span>
                                </p>
                                <p class="text-[9.5px] text-coffee-milk font-semibold">Size ${it.customization ? it.customization.size : 'M'} \u2022 Đ:${it.customization ? it.customization.sugar : '100%'} \u2022 Đá:${it.customization ? it.customization.ice : '100%'}</p>
                                ${it.notes ? `<p class="text-[9px] bg-amber-50 text-amber-800 rounded px-1.5 py-0.5 font-bold block italic mt-1 inline-block">"${it.notes}"</p>` : ''}
                            </div>
                            <span class="text-[9px] font-mono font-bold uppercase tracking-wider px-2 py-0.5 rounded-full border shrink-0 ${stBadge}">
                                ${label}
                            </span>
                        </div>
                    `;
                });

                grid.innerHTML += `
                    <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs flex flex-col justify-between hover:shadow-sm transition-all h-auto gap-4">
                        <div class="space-y-3.5">
                            <div class="flex justify-between items-start border-b border-coffee-light pb-2">
                                <div>
                                    <span class="text-[10px] font-mono font-bold text-coffee-milk uppercase bg-coffee-light px-2 py-0.5 rounded border border-coffee-sand/40">ĐƠN #${o.orderNumber}</span>
                                    <h4 class="font-serif font-bold italic text-base mt-1 text-coffee-dark">${o.tableName}</h4>
                                </div>
                                <div class="text-right space-y-0.5">
                                    <span class="text-[9px] font-mono uppercase tracking-wider font-bold px-2 py-0.5 rounded-full border ${cardBadge}">
                                        ${o.status === 'Pending' ? 'ĐỢI DUYỆT' : o.status === 'Preparing' ? 'ĐANG LÀM' : 'ĐỒ XONG'}
                                    </span>
                                    <p class="text-[10px] text-coffee-milk font-mono">${ageText}</p>
                                </div>
                            </div>

                            <div class="space-y-1">
                                <div class="flex justify-between items-center text-[10px] text-coffee-milk font-mono font-bold">
                                    <span>Tỷ lệ hoàn tất:</span>
                                    <span>${ratio}%</span>
                                </div>
                                <div class="w-full bg-coffee-light h-1.5 rounded-full overflow-hidden border border-coffee-sand/30">
                                    <div class="bg-coffee-rust h-full rounded-full transition-all duration-300" style="width: ${ratio}%"></div>
                                </div>
                            </div>

                            <div class="space-y-1 shadow-2xs divide-y divide-coffee-sand/20">
                                ${itemsRows}
                            </div>

                            ${o.notes ? `
                                <div class="bg-amber-50/50 border border-amber-100 rounded-xl p-2.5 text-[10px] text-amber-900 leading-normal font-medium">
                                    Ghi chú phụ: "${o.notes}"
                                </div>
                            ` : ''}
                        </div>

                        <div class="pt-3 border-t border-coffee-sand/40 mt-1">
                            <button onclick="postTicketComplete('${o.id}')" class="w-full bg-coffee-light hover:bg-coffee-rust text-coffee-rust hover:text-white border border-coffee-sand hover:border-transparent transition-all py-2 rounded-xl text-xs font-bold font-mono tracking-wider cursor-pointer">
                                HOÀN TẤT LÊN ĐỒ 🏁
                            </button>
                        </div>
                    </div>
                `;
            });
        }

        async function toggleBaristaItem(orderId, itemId, nextStatus) {
            try {
                await fetch(`/api/orders/${orderId}/items/${itemId}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ status: nextStatus })
                });
                fetchStateCore();
            } catch (err) {
                console.error(err);
            }
        }

        async function postTicketComplete(orderId) {
            try {
                await fetch(`/api/orders/${orderId}/status`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ status: 'Served' })
                });
                fetchStateCore();
            } catch (err) {
                console.error(err);
            }
        }

        function flashNotify(msg) {
            const wrapper = document.getElementById('flash-banner-container');
            const text = document.getElementById('flash-message');
            text.innerText = msg;
            wrapper.classList.remove('hidden');
            wrapper.classList.add('block');
            setTimeout(() => {
                wrapper.classList.add('hidden');
            }, 3000);
        }

        function setupWebSocketChannel() {
            const loc = window.location;
            const sockProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:';
            const endpoint = `${sockProtocol}//${loc.host}/ws`;
            
            const socket = new WebSocket(endpoint);

            socket.onopen = () => {
                const el = document.getElementById('connection-status');
                el.innerHTML = `
                    <div class="bg-emerald-50 text-emerald-800 border border-emerald-250 px-3 py-1 rounded-full text-[11px] flex items-center gap-1.5 font-bold">
                        <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping"></span>
                        <span>Đồng bộ thực tế</span>
                    </div>
                `;
                fetchStateCore();
            };

            socket.onmessage = () => {
                fetchStateCore();
                playAlertTone();
                flashNotify('🔄 Đơn pha chế mới dán thành công thời gian thực!');
            };

            socket.onclose = () => {
                const el = document.getElementById('connection-status');
                el.innerHTML = `
                    <div class="bg-red-50 text-red-800 border border-red-200 px-3 py-1 rounded-full text-[11px] flex items-center gap-1.5 font-bold">
                        <span class="w-1.5 h-1.5 bg-red-500 rounded-full"></span>
                        <span>Hệ thống mất mạng</span>
                    </div>
                `;
                setTimeout(setupWebSocketChannel, 4500);
            };
        }

        window.addEventListener('DOMContentLoaded', setupWebSocketChannel);
    </script>
</body>
</html>
