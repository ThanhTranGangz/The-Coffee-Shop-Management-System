<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sơ đồ phục vụ — nhà cà phê.</title>
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
            background-color: #F6F2E9;
            background-image: radial-gradient(#d3cbb6 1.2px, transparent 1.2px);
            background-size: 24px 24px;
        }
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: rgba(43, 27, 23, 0.05);
            border-radius: 99px;
        }
        ::-webkit-scrollbar-thumb {
            background: rgba(160, 68, 35, 0.3);
            border-radius: 99px;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col dot-grid-bg selection:bg-coffee-rust/10 selection:text-coffee-rust">

    <!-- NAVIGATION BAR -->
    <nav class="border-b border-coffee-sand/70 bg-coffee-bg/95 sticky top-0 z-40 px-6 py-4">
        <div class="max-w-7xl mx-auto flex items-center justify-between">
            <div class="flex items-center gap-2">
                <span class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark select-none">
                    nhà cà phê<span class="text-coffee-rust">.</span>
                </span>
                <span class="bg-coffee-rust text-white text-[10px] uppercase font-bold tracking-widest px-2.5 py-0.5 rounded-full font-mono">WAIT STATION</span>
            </div>

            <div class="flex items-center gap-3">
                <div id="connection-status">
                     <span class="text-xs text-coffee-milk">Đang đồng bộ...</span>
                </div>

                <div class="hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>

                <a href="index.html" class="text-xs font-bold px-3 py-1 bg-white hover:bg-coffee-rust hover:text-white border border-coffee-sand rounded-xl shadow-xs transition-all">
                    Đăng xuất
                </a>
            </div>
        </div>
    </nav>

    <!-- LIVE POP-UP FLASH CHIMES -->
    <div id="flash-banner-container" class="hidden fixed bottom-6 right-6 z-50 max-w-sm w-full animate-bounce">
        <div class="bg-coffee-dark text-white border border-coffee-rust/50 px-4 py-3 rounded-2xl flex items-center gap-2.5 shadow-xl">
            <div class="w-8 h-8 rounded-full bg-coffee-rust flex items-center justify-center shrink-0">🍽️</div>
            <div class="flex-1 text-xs">
                <p id="flash-message" class="font-medium text-coffee-bg"></p>
            </div>
        </div>
    </div>

    <!-- MAIN GRID PORTAL -->
    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col justify-start space-y-6">
        
        <!-- Transfer mode status bar -->
        <div id="transfer-action-banner" class="hidden bg-amber-50 border border-amber-200 text-amber-900 px-5 py-3.5 rounded-2xl text-xs sm:text-sm flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs">
            <div class="flex items-center gap-2">
                <span class="w-2.5 h-2.5 bg-amber-500 rounded-full animate-ping"></span>
                <span>
                    <strong id="transfer-mode-label">Điều chuyển:</strong> Nhấp chọn một bàn trên sơ đồ để dọn tiệc hoặc sát nhập hoá đơn bàn.
                </span>
            </div>
            <button onclick="cancelMoveMerge()" class="text-[11px] font-bold uppercase border border-amber-300 bg-white px-3 py-1.5 rounded-xl hover:bg-amber-100 transition-all cursor-pointer">
                Hủy tác vụ
            </button>
        </div>

        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-4 rounded-[24px] border border-coffee-sand shadow-xs">
            <div>
                <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                    <span>📋</span> Sơ đồ bàn phục vụ (Wait Station)
                </h2>
                <p class="text-xs text-coffee-milk font-medium">Bản đồ ghế ngồi, dọn bàn, điều phối nạp đồ thời gian thực.</p>
            </div>
            
            <div class="flex bg-coffee-light p-1 rounded-xl text-xs border border-coffee-sand overflow-x-auto whitespace-nowrap">
                <button onclick="setZoneFilter('All')" id="tab-zone-all" class="px-3.5 py-1.5 rounded-lg font-bold transition-all bg-coffee-rust text-white shadow-xs">Tất cả khu vực</button>
                <button onclick="setZoneFilter('Ground Floor')" id="tab-zone-ground" class="px-3.5 py-1.5 rounded-lg font-bold transition-all text-coffee-milk hover:text-coffee-dark pb">Tầng Trệt</button>
                <button onclick="setZoneFilter('Terrace')" id="tab-zone-terrace" class="px-3.5 py-1.5 rounded-lg font-bold transition-all text-coffee-milk hover:text-coffee-dark pb">Sân Vườn</button>
                <button onclick="setZoneFilter('Upper Floor')" id="tab-zone-upper" class="px-3.5 py-1.5 rounded-lg font-bold transition-all text-coffee-milk hover:text-coffee-dark pb">Tầng Lửng</button>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            <!-- Floor maps (2 columns) -->
            <div class="lg:col-span-2 space-y-4">
                <div id="wait-tables-container" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 max-h-[640px] overflow-y-auto pr-1">
                    <!-- Populated dynamically -->
                </div>
            </div>

            <!-- Waiter side bill inspection panel (1 column) -->
            <div id="wait-details-card" class="bg-white rounded-[32px] border border-coffee-sand p-6 flex flex-col justify-between h-[520px] shadow-sm relative overflow-hidden">
                
                <div id="wait-placeholder" class="h-full flex flex-col items-center justify-center text-center space-y-4 animate-fade-in">
                    <div class="w-16 h-16 bg-coffee-light rounded-full border border-coffee-sand/70 flex items-center justify-center text-2xl text-coffee-milk shrink-0 shadow-sm">
                        🍽️
                    </div>
                    <div class="space-y-1.5">
                        <h4 class="font-serif italic font-bold text-coffee-dark text-base">Vui lòng chọn bàn</h4>
                        <p class="text-xs text-coffee-milk max-w-xs leading-relaxed">Xem danh sách gọi món hiện hoạt, bổ sung đồ uống trực tiếp, di chuyển đổi bàn hoặc in hóa đơn dọn tiệc.</p>
                    </div>
                </div>

                <div id="wait-active" class="hidden h-full flex flex-col justify-between overflow-hidden">
                    <!-- Dynamic details -->
                </div>
            </div>

        </div>
    </main>

    <!-- SUPPLEMENTARY WAITER ORDER DRAWER -->
    <div id="order-placement-drawer" class="fixed inset-0 bg-coffee-dark/40 z-50 flex justify-end hidden opacity-0 transition-all duration-300">
        <div class="w-full max-w-lg bg-coffee-bg h-full flex flex-col shadow-2xl p-6 transition-all transform translate-x-full">
            <div class="flex items-center justify-between border-b border-coffee-sand pb-4">
                <div>
                    <h3 class="text-lg font-serif italic font-bold text-coffee-dark" id="drawer-title">Thêm món nước vào bàn</h3>
                    <p class="text-xs text-coffee-milk">Bổ sung phao trà sữa hoặc bánh ngọt cho khách hàng</p>
                </div>
                <button onclick="closeOrderDrawer()" class="p-2 hover:bg-coffee-sand/30 rounded-xl text-coffee-dark transition-colors">✕</button>
            </div>

            <div class="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 overflow-hidden">
                <div class="flex flex-col h-full overflow-hidden border-r border-coffee-sand/50 pr-2">
                    <div class="space-y-2 mb-2">
                        <div class="flex flex-wrap gap-1" id="drawer-categories-holder"></div>
                        <input type="text" id="drawer-search-input" oninput="drawDrawerMenuList()" placeholder="Tìm món phin..." class="w-full text-xs px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                    </div>
                    <div id="drawer-menu-container" class="flex-1 overflow-y-auto space-y-2.5"></div>
                </div>

                <div class="flex flex-col h-full overflow-hidden">
                    <h4 class="text-[11px] uppercase font-bold tracking-wider text-coffee-rust border-b border-coffee-sand pb-2 mb-2">Món đã chọn của bàn</h4>
                    <div id="drawer-cart-container" class="flex-1 overflow-y-auto space-y-3 pr-1"></div>

                    <div class="border-t border-coffee-sand pt-4 mt-2 space-y-3">
                        <div>
                            <label class="text-[9px] font-bold uppercase text-coffee-milk block mb-1">Ghi chú bếp pha chế</label>
                            <textarea id="drawer-order-notes" placeholder="e.g. Không đường nhiều đá..." class="w-full text-xs px-3 py-2 bg-white border border-coffee-sand rounded-xl h-14 focus:outline-none focus:border-coffee-rust"></textarea>
                        </div>

                        <div class="bg-coffee-light rounded-xl p-3 flex justify-between items-center text-xs border border-coffee-sand/70">
                            <span class="font-bold text-coffee-dark">Thành tiền nháp:</span>
                            <span class="font-mono font-bold text-sm text-coffee-rust" id="drawer-cart-total">0 ₫</span>
                        </div>

                        <button id="submit-ticket-btn" onclick="submitTicket()" class="w-full bg-coffee-rust text-white font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all flex justify-center items-center gap-1.5 shadow-sm">
                            Xác nhận gọi món 📋
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- OPERATIONS SYSTEM SCRIPT -->
    <script>
        let menu = [];
        let tables = [];
        let orders = [];

        let selectedZone = 'All';
        let selectedTableId = null;

        let cartItems = [];
        let drawerCategory = 'All';

        let transferState = {
            mode: null,
            sourceTableId: null
        };

        setInterval(() => {
            const clock = document.getElementById('nav-clock');
            if(clock) clock.innerText = new Date().toLocaleTimeString('vi-VN');
        }, 1000);

        function playAlertTone() {
            try {
                const AudioCtx = window.AudioContext || window.webkitAudioContext;
                if (!AudioCtx) return;
                const context = new AudioCtx();
                const o = context.createOscillator();
                const g = context.createGain();
                o.connect(g);
                g.connect(context.destination);
                o.frequency.setValueAtTime(587.33, context.currentTime); // D5
                g.gain.setValueAtTime(0.08, context.currentTime);
                g.gain.exponentialRampToValueAtTime(0.001, context.currentTime + 0.25);
                o.start();
                o.stop(context.currentTime + 0.25);
            } catch(e){}
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

                drawWaiterTables();
                drawWaiterDetails();
            } catch (err) {
                console.error(err);
            }
        }

        function setZoneFilter(z) {
            selectedZone = z;
            const filters = ['All', 'Ground Floor', 'Terrace', 'Upper Floor'];
            filters.forEach(item => {
                const id = 'tab-zone-' + (item === 'All' ? 'all' : item.replace(' Floor', '').toLowerCase());
                const target = document.getElementById(id);
                if (!target) return;
                if (item === z) {
                    target.className = "px-3.5 py-1.5 rounded-lg font-bold transition-all bg-coffee-rust text-white shadow-xs cursor-pointer";
                } else {
                    target.className = "px-3.5 py-1.5 rounded-lg font-bold transition-all text-coffee-milk hover:text-coffee-dark cursor-pointer";
                }
            });
            drawWaiterTables();
        }

        function formatVND(val) {
            return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
        }

        function drawWaiterTables() {
            const target = document.getElementById('wait-tables-container');
            if(!target) return;
            target.innerHTML = '';

            const list = tables.filter(t => selectedZone === 'All' || t.zone === selectedZone);

            list.forEach(table => {
                const isSel = selectedTableId === table.id;
                const isSrc = transferState.sourceTableId === table.id;

                let colorStyles = 'border-coffee-sand bg-white text-coffee-dark hover:border-coffee-rust/50';
                let statusLabel = 'Trống';
                let statusBadge = 'bg-coffee-light text-coffee-milk border border-coffee-sand/50';

                if (table.status === 'serving') {
                    colorStyles = 'border-coffee-sand bg-orange-50/20 text-coffee-dark hover:border-amber-500';
                    statusBadge = 'bg-amber-100 text-amber-800 border-amber-200';
                    statusLabel = 'Phục vụ';
                } else if (table.status === 'ready_to_serve') {
                    colorStyles = 'border-emerald-600 bg-emerald-50/20 text-coffee-dark shadow-xs outline outline-2 outline-emerald-500/20 animate-pulse';
                    statusBadge = 'bg-emerald-105 text-emerald-800 border-emerald-300';
                    statusLabel = 'Trực trà';
                }

                if (isSel) {
                    colorStyles += ' ring-2 ring-coffee-rust border-transparent shadow-md transform -translate-y-0.5';
                }
                if (isSrc) {
                    colorStyles += ' border-amber-400 bg-amber-50 ring-2 ring-amber-400';
                }

                target.innerHTML += `
                    <div onclick="selectWaiterTable('${table.id}')" class="border rounded-2xl p-4 flex flex-col justify-between h-40 transition-all duration-150 cursor-pointer ${colorStyles}">
                        <div>
                            <span class="text-[9px] uppercase font-bold tracking-wider opacity-60 font-mono">${table.zone === 'Ground Floor' ? 'Tầng trệt' : table.zone === 'Terrace' ? 'Garden' : 'Lầu'}</span>
                            <h4 class="font-serif font-bold italic text-base leading-tight mt-0.5 text-coffee-dark">${table.name}</h4>
                        </div>
                        
                        <div class="flex items-center justify-between text-xs mt-3">
                            <span class="text-[11px] text-coffee-milk font-mono">
                                Ghế: ${table.capacity}
                            </span>
                            <span class="text-[9px] px-2 py-0.5 rounded-full font-bold uppercase tracking-wider font-mono ${statusBadge}">
                                ${statusLabel}
                            </span>
                        </div>
                    </div>
                `;
            });
        }

        async function selectWaiterTable(tableId) {
            if (transferState.mode && transferState.sourceTableId) {
                if (tableId === transferState.sourceTableId) {
                    alert('Không đổi dời hoá đơn sang chính cùng vị trí bàn!');
                    return;
                }

                const src = tables.find(t=>t.id===transferState.sourceTableId);
                const dest = tables.find(t=>t.id === tableId);

                if (transferState.mode === 'move') {
                    if (dest.status !== 'empty') {
                        alert('Bàn đích chuyển tới bắt buộc phải còn trống dọn tiệc!');
                        return;
                    }
                    await postMoveTable(src.id, dest.id);
                } else if (transferState.mode === 'merge') {
                    await postMergeTables(src.id, dest.id);
                }

                cancelMoveMerge();
                selectedTableId = dest.id;
                fetchStateCore();
                return;
            }

            selectedTableId = tableId;
            drawWaiterTables();
            drawWaiterDetails();
        }

        function drawWaiterDetails() {
            const ple = document.getElementById('wait-placeholder');
            const act = document.getElementById('wait-active');

            if (!selectedTableId) {
                ple.classList.remove('hidden');
                act.classList.add('hidden');
                return;
            }

            ple.classList.add('hidden');
            act.classList.remove('hidden');

            const table = tables.find(t => t.id === selectedTableId);
            const orderObj = orders.find(o => o.tableId === selectedTableId && o.status !== 'Served');

            let listHtml = '';
            if (orderObj && orderObj.items.length > 0) {
                orderObj.items.forEach(it => {
                    let badgeClass = 'bg-coffee-light border border-coffee-sand/30';
                    if (it.status === 'Preparing') badgeClass = 'bg-amber-100 text-amber-850 border-amber-250';
                    else if (it.status === 'Ready') badgeClass = 'bg-emerald-100 text-emerald-800 border-emerald-300 animate-pulse';
                    else if (it.status === 'Served') badgeClass = 'bg-coffee-rust/10 text-coffee-rust border-coffee-rust/10';

                    listHtml += `
                        <div class="flex justify-between items-center bg-coffee-light border border-coffee-sand/75 rounded-xl px-3 py-2 text-xs">
                            <div class="space-y-0.5">
                                <p class="font-bold text-coffee-dark">${it.name} <span class="font-mono text-coffee-rust">x${it.quantity}</span></p>
                                <p class="text-[9.5px] text-coffee-milk">Sz: ${it.customization ? it.customization.size : 'M'}</p>
                            </div>
                            <span class="text-[9px] font-mono uppercase font-bold px-1.5 py-0.5 rounded-full ${badgeClass}">
                                ${it.status === 'Pending' ? 'Đợi' : it.status === 'Preparing' ? 'Pha' : it.status === 'Ready' ? 'Dọn' : 'Xong'}
                            </span>
                        </div>
                    `;
                });
            } else {
                listHtml = `<div class="text-center py-6 text-xs text-coffee-milk italic bg-coffee-light rounded-2xl border border-coffee-sand/50">Không có đồ uống đang dọn dẹp.</div>`;
            }

            act.innerHTML = `
                <div class="h-full flex flex-col justify-between overflow-hidden">
                    <div class="overflow-y-auto space-y-4 pr-1">
                        
                        <div class="flex justify-between items-center border-b border-coffee-sand/60 pb-3">
                            <div>
                                <span class="text-[9px] uppercase font-bold tracking-wider text-coffee-milk font-mono">${table.zone === 'Ground Floor' ? 'Tầng trệt' : table.zone === 'Terrace' ? 'Garden Khu B' : 'Tầng Lầu'}</span>
                                <h3 class="font-serif italic font-bold text-lg text-coffee-dark leading-tight">${table.name}</h3>
                            </div>
                            <span class="text-[11px] font-bold font-mono bg-coffee-light border border-coffee-sand text-coffee-dark px-2.5 py-1 rounded-lg">Ghế: ${table.capacity}</span>
                        </div>

                        ${orderObj ? `
                            <div class="bg-coffee-light border border-coffee-sand/80 rounded-2xl p-3 text-[11px] font-medium space-y-1 text-coffee-dark">
                                <div class="flex justify-between font-mono">
                                    <span class="text-coffee-milk">ID HÓA ĐƠN</span>
                                    <span class="font-bold text-coffee-dark">#${orderObj.orderNumber}</span>
                                </div>
                                <div class="flex justify-between font-mono">
                                    <span class="text-coffee-milk">TRẠNG THÁI</span>
                                    <span class="font-bold text-coffee-rust uppercase">${orderObj.status}</span>
                                </div>
                            </div>
                        ` : ''}

                        <div class="space-y-1.5">
                            <h5 class="text-[10px] uppercase font-bold tracking-widest text-coffee-milk font-mono">DANH SÁCH MÓN ĐÃ GỌI</h5>
                            <div class="space-y-1.5 max-h-[165px] overflow-y-auto">
                                ${listHtml}
                            </div>
                        </div>
                    </div>

                    <div class="border-t border-coffee-sand/60 pt-4 space-y-3 shrink-0">
                        <div class="grid grid-cols-2 gap-2">
                            <button onclick="triggerTransfer('move')" class="bg-white border border-coffee-sand hover:bg-coffee-rust/5 text-coffee-dark hover:border-coffee-rust text-xs py-2 rounded-xl flex items-center justify-center gap-1.5 font-bold transition-all cursor-pointer">🚚 Đổi bàn</button>
                            <button onclick="triggerTransfer('merge')" class="bg-white border border-coffee-sand hover:bg-coffee-rust/5 text-coffee-dark hover:border-coffee-rust text-xs py-2 rounded-xl flex items-center justify-center gap-1.5 font-bold transition-all cursor-pointer">🔗 Ghép bàn</button>
                        </div>

                        ${orderObj ? `
                            <div class="bg-coffee-light border border-coffee-sand p-3 rounded-2xl flex justify-between items-center text-xs">
                                <span class="font-bold text-coffee-milk">Tổng chi hóa đơn:</span>
                                <span class="font-mono font-bold text-sm text-coffee-rust">${formatVND(orderObj.totalAmount)}</span>
                            </div>

                            <div class="grid grid-cols-2 gap-2">
                                <button onclick="openStaffOrderDrawer()" class="bg-[#FDFBF7] border border-coffee-sand/80 text-coffee-dark hover:border-coffee-rust text-[11px] h-10 rounded-xl font-bold transition-all cursor-pointer">＋ Mở rộng món</button>
                                <button onclick="checkoutWaiterTable('${table.id}')" class="bg-coffee-rust text-white hover:bg-coffee-rust/95 text-[11.5px] h-10 rounded-xl font-bold transition-all cursor-pointer flex items-center justify-center gap-1">💸 Xuất Hoá Đơn</button>
                            </div>
                        ` : `
                            <button onclick="openStaffOrderDrawer()" class="w-full bg-coffee-rust text-white hover:bg-coffee-rust/95 py-3 rounded-xl font-bold text-xs uppercase tracking-wider transition-all cursor-pointer">＋ Ghi nhận bàn mới</button>
                        `}
                    </div>
                </div>
            `;
        }

        function triggerTransfer(mode) {
            if (!selectedTableId) return;
            transferState.mode = mode;
            transferState.sourceTableId = selectedTableId;
            document.getElementById('transfer-mode-label').innerText = mode === 'move' ? 'Điều dời sơ đồ bàn:' : 'Gộp nhóm liên kết:';
            document.getElementById('transfer-action-banner').classList.remove('hidden');
            drawWaiterTables();
        }

        function cancelMoveMerge() {
            transferState.mode = null;
            transferState.sourceTableId = null;
            document.getElementById('transfer-action-banner').classList.add('hidden');
            drawWaiterTables();
        }

        async function postMoveTable(src, dst) {
            try {
                const response = await fetch('/api/tables/move', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ sourceTableId: src, targetTableId: dst })
                });
                if (response.ok) {
                    flashNotify('🚚 Di chuyển đơn đồ uống sang bàn mới thành công!');
                } else {
                    const error = await response.json();
                    alert(error.error || 'Trụ sở dọn tiệc từ chối.');
                }
            } catch (err) {
                console.error(err);
            }
        }

        async function postMergeTables(src, dst) {
            try {
                const response = await fetch('/api/tables/merge', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ sourceTableId: src, targetTableId: dst })
                });
                if (response.ok) {
                    flashNotify('🔗 Sát nhập hai hóa đơn thành công!');
                } else {
                    const error = await response.json();
                    alert(error.error || 'Trụ sở gộp tiệc từ chối.');
                }
            } catch (err) {
                console.error(err);
            }
        }

        async function checkoutWaiterTable(tableId) {
            const table = tables.find(t=>t.id===tableId);
            if (!confirm(`Xác nhận khách thanh toán xong và dọn dẹp ${table.name}?`)) return;

            try {
                const response = await fetch(`/api/tables/${tableId}/checkout`, { method: 'POST' });
                if (response.ok) {
                    selectedTableId = null;
                    flashNotify('💸 Thanh toán & trả dọn dẹp bàn trống thành công!');
                    fetchStateCore();
                } else {
                    alert('Hóa đơn checkout bị từ chối.');
                }
            } catch (err) {
                console.error(err);
            }
        }

        // SUPPLEMENTARY ADD MON DRAWER
        function openStaffOrderDrawer() {
            cartItems = [];
            const table = tables.find(t=>t.id === selectedTableId);
            if (!table) return;

            document.getElementById('drawer-title').innerText = `Gọi món bàn nước — ${table.name}`;
            document.getElementById('drawer-order-notes').value = '';

            const holder = document.getElementById('drawer-categories-holder');
            holder.innerHTML = '';
            const list = ['All', 'Coffee', 'Tea', 'Specialty', 'Pastry'];
            list.forEach(item => {
                const isSel = drawerCategory === item;
                const txt = item === 'All' ? 'Tất cả' : item==='Coffee' ? 'Cà phê' : item==='Tea' ? 'Trà đào' : item==='Specialty' ? 'Đậm vị' : 'Bánh';
                holder.innerHTML += `<button onclick="setDrawerCategory('${item}')" class="text-[10px] font-bold px-2 py-1 rounded border transition-all ${isSel ? 'bg-coffee-rust text-white border-transparent':'bg-white border-coffee-sand text-coffee-milk'}">${txt}</button>`;
            });

            const drawer = document.getElementById('order-placement-drawer');
            drawer.classList.remove('hidden');
            setTimeout(() => {
                drawer.classList.remove('opacity-0');
                drawer.firstElementChild.classList.remove('translate-x-full');
            }, 50);

            drawDrawerMenuList();
            drawDrawerCart();
        }

        function setDrawerCategory(cat) {
            drawerCategory = cat;
            openStaffOrderDrawer();
        }

        function closeOrderDrawer() {
            const el = document.getElementById('order-placement-drawer');
            el.classList.add('opacity-0');
            el.firstElementChild.classList.add('translate-x-full');
            setTimeout(() => { el.classList.add('hidden'); }, 300);
        }

        function drawDrawerMenuList() {
            const container = document.getElementById('drawer-menu-container');
            if(!container) return;
            container.innerHTML = '';

            const key = document.getElementById('drawer-search-input').value.toLowerCase();
            const list = menu.filter(m => {
                const matchCat = drawerCategory==='All' || m.category === drawerCategory;
                const matchKey = m.name.toLowerCase().includes(key) || m.description.toLowerCase().includes(key);
                return matchCat && matchKey;
            });

            list.forEach(it => {
                container.innerHTML += `
                    <div onclick="addDrawerItem('${it.id}')" class="bg-white border border-coffee-sand hover:border-coffee-rust rounded-xl p-2.5 flex justify-between items-center cursor-pointer transition-all text-xs">
                        <div class="space-y-0.5">
                            <h5 class="font-bold text-coffee-dark">${it.name}</h5>
                            <span class="font-mono text-coffee-rust font-bold">${formatVND(it.price)}</span>
                        </div>
                        <div class="w-5 h-5 rounded-full bg-coffee-light text-coffee-rust flex items-center justify-center font-bold">＋</div>
                    </div>
                `;
            });
        }

        function addDrawerItem(id) {
            const matched = menu.find(m => m.id === id);
            const standardSize = matched.availableSizes[0] || 'M';

            cartItems.push({
                menuItem: matched,
                quantity: 1,
                customization: {
                    size: standardSize,
                    sugar: matched.category !== 'Pastry' ? '100%' : undefined,
                    ice: matched.category !== 'Pastry' ? '100%' : undefined
                },
                notes: ''
            });

            drawDrawerCart();
        }

        function drawDrawerCart() {
            const container = document.getElementById('drawer-cart-container');
            if(!container) return;
            container.innerHTML = '';

            if (cartItems.length === 0) {
                container.innerHTML = `<div class="text-center text-xs text-coffee-milk py-8 italic">Chưa có món nào được chỉ định.</div>`;
                document.getElementById('drawer-cart-total').innerText = '0 ₫';
                return;
            }

            let sum = 0;
            cartItems.forEach((c, index) => {
                let p = c.menuItem.price;
                if(c.customization.size === 'L') p += 6000;
                else if (c.customization.size==='S') p = Math.max(10000, p - 4000);

                const sub = p * c.quantity;
                sum += sub;

                container.innerHTML += `
                    <div class="bg-coffee-light border rounded-xl p-2.5 text-xs flex justify-between items-center">
                        <div class="space-y-0.5">
                            <h6 class="font-bold text-coffee-dark leading-tight">${c.menuItem.name} <span class="font-mono font-bold text-coffee-rust">x${c.quantity}</span></h6>
                            <p class="text-[10px] text-coffee-milk">Size ${c.customization.size}</p>
                        </div>
                        <button onclick="removeDrawerItem(${index})" class="text-coffee-milk text-sm shrink-0">🗑️</button>
                    </div>
                `;
            });

            document.getElementById('drawer-cart-total').innerText = formatVND(sum);
        }

        function removeDrawerItem(idx) {
            cartItems.splice(idx, 1);
            drawDrawerCart();
        }

        async function submitTicket() {
            if (cartItems.length === 0) {
                alert('Vui lòng bổ sung ít nhất một món.');
                return;
            }

            const itemsPayload = cartItems.map(c => ({
                menuItemId: c.menuItem.id,
                name: c.menuItem.name,
                price: c.menuItem.price,
                quantity: c.quantity,
                customization: {
                    size: c.customization.size,
                    sugar: c.customization.sugar,
                    ice: c.customization.ice
                },
                notes: c.notes
            }));

            const notes = document.getElementById('drawer-order-notes').value;

            try {
                const response = await fetch('/api/orders', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        tableId: selectedTableId,
                        items: itemsPayload,
                        notes: notes
                    })
                });

                if (response.ok) {
                    closeOrderDrawer();
                    flashNotify('🚀 Tạo bổ sung hoá đơn bàn thành công!');
                    fetchStateCore();
                } else {
                    alert('Hệ thống từ chối nạp bill.');
                }
            } catch(e) {
                console.error(e);
            }
        }

        function flashNotify(msg) {
            const wrapper = document.getElementById('flash-banner-container');
            const text = document.getElementById('flash-message');
            text.innerText = msg;
            wrapper.classList.remove('hidden');
            wrapper.classList.add('block');
            setTimeout(() => { wrapper.classList.add('hidden'); }, 3000);
        }

        function setupWebSocket() {
            const loc = window.location;
            const sockProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:';
            const endpoint = sockProtocol + '//' + loc.host + '/ws';
            const socket = new WebSocket(endpoint);

            socket.onopen = () => {
                document.getElementById('connection-status').innerHTML =
                    '<div class="bg-emerald-50 text-emerald-800 px-3 py-1 rounded-full text-xs">Đồng bộ bàn</div>';
                fetchTables();
            };

            socket.onmessage = () => {
                fetchTables();
                playAlertTone();
                flashNotify('🔄 Bàn phục vụ vừa được cập nhật từ QR!');
            };

            socket.onclose = () => {
                document.getElementById('connection-status').innerHTML =
                    '<div class="bg-red-50 text-red-800 px-3 py-1 rounded-full text-xs">Mất kết nối</div>';
                setTimeout(setupWebSocket, 4000);
            };
        }

        window.addEventListener('DOMContentLoaded', () => {
            setupWebSocket();
            fetchTables();
            setInterval(fetchTables, 10000); // fallback polling
        });

    </script>
</body>
</html>
