<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nhà cà phê. — quản lý kho nguyên liệu</title>
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        coffee: {
                            bg: '#F6F2E9',       /* Warm Ivory Eggshell */
                            dark: '#2B1B17',     /* Deep Roasted Espresso */
                            rust: '#A04423',     /* Premium Terracotta Red-Brown */
                            sand: '#E5DEC9',     /* Soft Muted Border */
                            light: '#FAF7EE',    /* Soft Off-white Ivory */
                            milk: '#8E7D6F'      /* Elegant Milk Brew Accent */
                        }
                    }
                }
            }
        }
    </script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:ital,wght@0,600;0,700;1,600&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
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
        ::-webkit-scrollbar-thumb:hover {
            background: rgba(160, 68, 35, 0.5);
            border-radius: 99px;
        }
    </style>
    <!-- Role lock & Global Security checker -->
    <script>
        (function() {
            var role = localStorage.getItem('auth_role') || '';
            var user = localStorage.getItem('auth_user') || '';
            // Security guard removed, now handled by SecurityFilter

            document.addEventListener("DOMContentLoaded", function() {
                var navContainer = document.querySelector('nav div.hidden.lg\\:flex');
                if (!navContainer) return;

                var navHtml = 
                    '<a href="index.html" class="hover:text-coffee-rust transition-colors text-coffee-milk">Trang chủ</a>' +
                    '<a href="dashboard.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">📊 Dashboard</a>' +
                    '<a href="reports.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">📈 Doanh số</a>' +
                    '<a href="staff-management.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">🧑‍🤝‍🧑 Nhân sự</a>' +
                    '<a href="inventory.jsp" class="hover:text-coffee-rust transition-colors text-coffee-dark font-bold font-semibold">📦 Kho hàng</a>' +
                    '<div class="relative group">' +
                        '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
                            '<span>Thao tác trực</span>' +
                            '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
                        '</button>' +
                        '<div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
                            '<a href="waitstation.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📟 Wait Station floor</a>' +
                            '<a href="kds.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">🧑‍🍳 Kitchen KDS screen</a>' +
                            '<a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">📋 Danh sách Order</a>' +
                            '<a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🖨️ In mã QR Bàn</a>' +
                            '<a href="menu.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">☕ Giao diện Khách</a>' +
                        '</div>' +
                    '</div>';

                navContainer.innerHTML = navHtml;

                // Render role status info badge
                var rightNavArea = document.querySelector('nav div.flex.items-center.gap-3');
                if (rightNavArea && role) {
                    var badgeHtml = document.createElement('div');
                    badgeHtml.className = 'flex items-center gap-2';
                    badgeHtml.innerHTML = 
                        '<div class="bg-coffee-dark text-coffee-bg border border-coffee-rust/30 px-3.5 py-1.5 rounded-xl text-[10px] uppercase font-bold font-mono tracking-wide flex items-center gap-1.5 shadow-xs">' +
                            '<span class="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping"></span>' +
                            '<span>💼 Quản lý: ' + user + '</span>' +
                        '</div>' +
                        '<button onclick="handleLocalLogout()" class="text-xs font-bold px-2 py-1.5 bg-red-50 hover:bg-red-500 hover:text-white border border-red-200 text-red-600 rounded-xl shadow-xs transition-all cursor-pointer">' +
                            'Đăng xuất ↩' +
                        '</button>';
                    rightNavArea.appendChild(badgeHtml);
                }
            });
        })();

        async function handleLocalLogout() {
            localStorage.removeItem('auth_role');
            localStorage.removeItem('auth_user');
            try { await fetch('/api/auth/logout', { method: 'POST' }); } catch(e) {}
            alert('Đã đăng xuất tài khoản làm việc POS!');
            window.location.href = 'staff.html';
        }
    </script>
</head>
<body class="min-h-screen flex flex-col dot-grid-bg relative selection:bg-coffee-rust/20 selection:text-coffee-rust">

    <!-- TOP NAVIGATION BAR -->
    <nav class="border-b border-coffee-sand/70 bg-coffee-bg/90 backdrop-blur sticky top-0 z-40 px-6 py-4 transition-all">
        <div class="max-w-7xl mx-auto flex items-center justify-between">
            
            <a href="index.html" class="flex items-center gap-2 group">
                <span class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark select-none">
                    nhà cà phê<span class="text-coffee-rust">.</span>
                </span>
            </a>

            <!-- Populated via script -->
            <div class="hidden lg:flex items-center gap-4 text-xs font-medium"></div>

            <div class="flex items-center gap-3">
                <div id="connection-status">
                    <div class="bg-amber-50 text-amber-800 border border-amber-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-medium">
                        <span class="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse"></span>
                        <span>Đang đồng bộ...</span>
                    </div>
                </div>

                <div class="hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>
            </div>
        </div>
    </nav>

    <!-- LIVE POP-UP FLASH BANNERS -->
    <div id="flash-banner-container" class="hidden fixed bottom-6 right-6 z-50 max-w-sm w-full animate-bounce">
        <div id="flash-banner" class="bg-coffee-dark text-white border border-coffee-rust/50 px-4 py-3 rounded-2xl flex items-center gap-2.5 shadow-xl">
            <div class="w-8 h-8 rounded-full bg-coffee-rust flex items-center justify-center shrink-0">
                📦
            </div>
            <div class="flex-1 text-xs">
                <p id="flash-message" class="font-medium text-coffee-bg">Đã cập nhật tình trạng kho hàng!</p>
            </div>
        </div>
    </div>

    <!-- MAIN PORTAL CONTENT CONTAINER -->
    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col justify-start">

        <div class="space-y-6">
            
            <!-- Header section -->
            <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex justify-between items-center">
                <div>
                    <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                        <span>📦</span> Kho Nguyên Liệu & Công Thức
                    </h2>
                    <p class="text-xs text-coffee-milk font-medium">Theo dõi lượng tồn kho thực tế, nhập kho thanh toán nguyên liệu và giám sát công thức pha chế đồ uống.</p>
                </div>
                <div class="bg-[#FAF7EE] border border-coffee-sand px-3.5 py-1.5 rounded-full text-xs font-bold font-mono text-coffee-rust flex items-center gap-1">
                    <span>Trạng thái: </span> <span id="inventory-low-alert-dot" class="w-2.5 h-2.5 bg-emerald-500 rounded-full inline-block"></span>
                    <span id="inventory-alert-text">Ổn định</span>
                </div>
            </div>

            <!-- TAB SELECTOR -->
            <div class="flex border-b border-coffee-sand gap-1">
                <button onclick="switchTab('tab-stock')" id="btn-tab-stock" class="px-5 py-2.5 font-bold text-xs rounded-t-2xl transition-all border-t border-x border-transparent bg-transparent text-coffee-milk hover:text-coffee-rust">
                    📦 Tồn Kho Hiện Tại
                </button>
                <button onclick="switchTab('tab-import')" id="btn-tab-import" class="px-5 py-2.5 font-bold text-xs rounded-t-2xl transition-all border-t border-x border-transparent bg-transparent text-coffee-milk hover:text-coffee-rust flex items-center gap-1.5">
                    💳 Nhập Kho & Thanh Toán
                </button>
                <button onclick="switchTab('tab-recipes')" id="btn-tab-recipes" class="px-5 py-2.5 font-bold text-xs rounded-t-2xl transition-all border-t border-x border-transparent bg-transparent text-coffee-milk hover:text-coffee-rust">
                    📋 Công Thức & Khả Dụng Món
                </button>
                <button onclick="switchTab('tab-logs')" id="btn-tab-logs" class="px-5 py-2.5 font-bold text-xs rounded-t-2xl transition-all border-t border-x border-transparent bg-transparent text-coffee-milk hover:text-coffee-rust">
                    🧾 Nhật Ký Nhập Kho
                </button>
            </div>

            <!-- TAB 1: STOCK STATUS -->
            <div id="tab-stock" class="space-y-4">
                <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-xs space-y-4">
                    <div class="flex justify-between items-center border-b border-coffee-light pb-3">
                        <div>
                            <h3 class="font-serif italic font-bold text-base text-coffee-dark">Trạng thái tồn kho cà phê & phụ liệu</h3>
                            <p class="text-[10px] text-coffee-milk">Các mức định lượng trong kho để kịp thời cảnh báo pha chế</p>
                        </div>
                        <button onclick="syncAllState()" class="text-xs font-mono font-bold text-coffee-rust hover:underline">
                            🔄 Cập nhật tức thời
                        </button>
                    </div>

                    <div id="stock-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        <!-- Loaded dynamically -->
                    </div>
                </div>
            </div>

            <!-- TAB 2: IMPORT & PAY FORM -->
            <div id="tab-import" class="hidden grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
                
                <!-- Left: Form selection fields -->
                <div class="lg:col-span-2 bg-white border border-coffee-sand rounded-3xl p-6 shadow-xs space-y-4">
                    <div class="border-b border-coffee-light pb-2">
                        <h3 class="font-serif italic font-bold text-base text-coffee-dark">Phiếu đề xuất nhập hàng nguyên liệu</h3>
                        <p class="text-[10px] text-coffee-milk">Vui lòng điền định lượng (số lượng) mong muốn nhập thêm cho từng loại nguyên liệu.</p>
                    </div>

                    <div class="space-y-3" id="import-form-lines">
                        <!-- Loaded dynamically -->
                    </div>
                </div>

                <!-- Right: Invoice Checkout visualization panel -->
                <div class="bg-white border border-coffee-rust/35 rounded-3xl p-6 shadow-md space-y-4 relative overflow-hidden">
                    <div class="absolute -top-12 -right-12 w-28 h-28 bg-coffee-rust/10 rounded-full blur-xl"></div>
                    
                    <h3 class="font-serif font-bold text-coffee-dark text-sm border-b border-coffee-sand pb-2 flex items-center gap-1.5">
                        <span>🧾</span> CHI TIẾT THANH TOÁN MUA HÀNG
                    </h3>

                    <div id="checkout-receipt-lines" class="space-y-2 max-h-[220px] overflow-y-auto text-xs pr-1 font-mono text-coffee-milk">
                        <!-- Dynamic receipt -->
                    </div>

                    <div class="border-t border-dashed border-coffee-sand pt-3 space-y-1">
                        <div class="flex justify-between text-xs text-coffee-milk font-mono">
                            <span>Phí giao hàng & thuế:</span>
                            <span class="font-bold">0 ₫ (Miễn phí)</span>
                        </div>
                        <div class="flex justify-between text-sm text-coffee-dark pt-1">
                            <span class="font-bold">Tổng tiền cần chi:</span>
                            <span id="checkout-receipt-total" class="font-mono font-bold text-coffee-rust text-base">0 ₫</span>
                        </div>
                    </div>

                    <div class="space-y-2">
                        <button onclick="submitImportRequest()" id="btn-submit-import" class="w-full bg-coffee-rust hover:bg-coffee-rust/85 text-white text-xs font-bold py-3 px-4 rounded-xl shadow-xs cursor-pointer select-none transition-all duration-150 flex items-center justify-center gap-1.5 focus:outline-none">
                            <span>💳 Thanh toán & Nhập kho quốc gia</span>
                        </button>
                        <p class="text-[9px] text-coffee-milk text-center italic leading-tight">Thanh toán sẽ ngay lập tức được giải ngân từ tài khoản quỹ của quán, đồng thời cộng thẳng số lượng vào tồn kho thực tiễn.</p>
                    </div>
                </div>

            </div>

            <!-- TAB 3: RECIPES & SYSTEM MAPS -->
            <div id="tab-recipes" class="hidden space-y-4">
                <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-xs space-y-4">
                    <div class="border-b border-coffee-light pb-2">
                        <h3 class="font-serif italic font-bold text-base text-coffee-dark">Đồ uống, Bánh ngọt & Định lượng cơ bản</h3>
                        <p class="text-[10px] text-coffee-milk">Nhấp xem cấu trúc nguyên liệu cơ bản cho 1 phần bán chuẩn.</p>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6" id="recipes-grid">
                        <!-- Loaded dynamically -->
                    </div>
                </div>
            </div>

            <!-- TAB 4: HISTORIC TRANSACTIONS LOG -->
            <div id="tab-logs" class="hidden space-y-4">
                <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-xs space-y-4">
                    <div class="flex justify-between items-center border-b border-coffee-light pb-3">
                        <div>
                            <h3 class="font-serif italic font-bold text-base text-coffee-dark">Nhật ký chi phí nhập kho & thanh toán</h3>
                            <p class="text-[10px] text-coffee-milk font-normal">Tổng hợp các đợt phát sinh hoá đơn mua hàng phụ liệu</p>
                        </div>
                        <span class="text-xs bg-coffee-light text-coffee-rust font-bold px-3 py-1 rounded-xl border border-coffee-sand/70 font-mono" id="logs-expenses-total">Tổng chi: 0 ₫</span>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs border-collapse">
                            <thead>
                                <tr class="border-b border-coffee-sand text-coffee-milk uppercase tracking-wider text-[10px] font-mono">
                                    <th class="py-3 px-4">Thời gian thanh toán</th>
                                    <th class="py-3 px-4">Mã giao dịch</th>
                                    <th class="py-3 px-4">Chi tiết nguyên liệu nhập</th>
                                    <th class="py-3 px-4 text-right">Số tiền đã trả</th>
                                </tr>
                            </thead>
                            <tbody id="logs-table-body" class="divide-y divide-coffee-light">
                                <!-- Loaded dynamically -->
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>

    </main>

    <!-- FOOTER PANEL -->
    <footer class="border-t border-coffee-sand/65 bg-white/70 py-6 text-center text-xs text-coffee-milk font-medium">
        <p>© 2026 nhà cà phê. — Hệ thống quản lý đồng bộ thực đơn & nhà kho thời gian thực.</p>
    </footer>

    <script>
        let inventory = [];
        let menu = [];
        let expenses = [];
        let socket;
        let currentTab = 'tab-stock';

        // Recipes dictionary mapping for viewing recipe specs matches server-side definitions
        const recipeSpecs = {
            m1: [ { name: "Hạt cà phê nguyên chất", qty: "20g" } ],
            m2: [ { name: "Hạt cà phê nguyên chất", qty: "20g" }, { name: "Sữa đặc đặc sánh", qty: "30g" } ],
            m3: [ { name: "Hạt cà phê nguyên chất", qty: "20g" }, { name: "Sữa đặc đặc sánh", qty: "20g" }, { name: "Kem béo muối biển", qty: "50ml" } ],
            m4: [ { name: "Hạt cà phê nguyên chất", qty: "15g" }, { name: "Sữa tươi tiệt trùng", qty: "100ml" } ],
            m5: [ { name: "Siro đào thơm mát", qty: "30ml" }, { name: "Sả tươi thơm nồng", qty: "1 nhánh" } ],
            m6: [ { name: "Bột Trà xanh Matcha Uji", qty: "10g" }, { name: "Sữa tươi tiệt trùng", qty: "150ml" } ],
            m7: [ { name: "Lá trà Ô long khô", qty: "15g" }, { name: "Sữa tươi tiệt trùng", qty: "100ml" } ],
            m8: [ { name: "Vỏ bánh sừng bò sấy", qty: "1 cái" } ],
            m9: [ { name: "Bánh Tiramisu cắt sẵn", qty: "1 lát" } ]
        };

        const categoryMap = {
            'Coffee': '☕ CÀ PHÊ',
            'Tea': '🍵 TRÀ DẢO',
            'Specialty': '✨ ĐẶC BIỆT',
            'Pastry': '🍰 BÁNH NGỌT'
        };

        function formatVND(amt) {
            return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amt);
        }

        function flashNotify(msg) {
            const container = document.getElementById('flash-banner-container');
            const message = document.getElementById('flash-message');
            if (container && message) {
                message.innerText = msg;
                container.classList.remove('hidden');
                setTimeout(() => {
                    container.classList.add('hidden');
                }, 3500);
            }
        }

        async function syncAllState() {
            try {
                const [rInv, rMenu, rExp] = await Promise.all([
                    fetch('/api/inventory'),
                    fetch('/api/menu'),
                    fetch('/api/inventory/expenses')
                ]);

                if (rInv.ok) inventory = await rInv.json();
                if (rMenu.ok) menu = await rMenu.json();
                if (rExp.ok) expenses = await rExp.json();

                updateAlertIndicators();
                renderStockStatus();
                renderImportForm();
                renderRecipes();
                renderLogs();
            } catch (err) {
                console.error("Failed to sync inventory state", err);
            }
        }

        function switchTab(tabId) {
            currentTab = tabId;
            const tabs = ['tab-stock', 'tab-import', 'tab-recipes', 'tab-logs'];
            tabs.forEach(t => {
                const el = document.getElementById(t);
                const btn = document.getElementById('btn-' + t);
                if (t === tabId) {
                    el.classList.remove('hidden');
                    btn.className = "px-5 py-2.5 font-bold text-xs rounded-t-2xl border-t border-x border-coffee-sand bg-white text-coffee-rust pointer-events-none";
                } else {
                    el.classList.add('hidden');
                    btn.className = "px-5 py-2.5 font-bold text-xs rounded-t-2xl border-t border-x border-transparent bg-transparent text-coffee-milk hover:text-coffee-rust transition-all";
                }
            });
        }

        function updateAlertIndicators() {
            const hasDepleted = inventory.some(i => i.stock === 0);
            const hasLow = inventory.some(i => i.stock > 0 && i.stock <= i.minStock);

            const alertDot = document.getElementById('inventory-low-alert-dot');
            const alertText = document.getElementById('inventory-alert-text');

            if (alertDot && alertText) {
                if (hasDepleted) {
                    alertDot.className = "w-2.5 h-2.5 bg-red-500 rounded-full inline-block animate-pulse";
                    alertText.innerText = "Hết nguyên liệu 🚫";
                    alertText.className = "text-red-700 font-bold";
                } else if (hasLow) {
                    alertDot.className = "w-2.5 h-2.5 bg-amber-500 rounded-full inline-block animate-pulse";
                    alertText.innerText = "Nguyên liệu sắp hết ⚠️";
                    alertText.className = "text-amber-700 font-bold";
                } else {
                    alertDot.className = "w-2.5 h-2.5 bg-emerald-500 rounded-full inline-block";
                    alertText.innerText = "Ổn định";
                    alertText.className = "text-emerald-700 font-semibold";
                }
            }
        }

        function renderStockStatus() {
            const grid = document.getElementById('stock-grid');
            if (!grid) return;
            grid.innerHTML = '';

            inventory.forEach(ing => {
                const isOutOfStock = ing.stock <= 0;
                const isLowStock = !isOutOfStock && ing.stock <= ing.minStock;
                
                // Calculate stock visual fill percentage (set 100% relative to a safe default e.g. minStock * 5)
                const safeMaxLimit = ing.minStock * 5;
                const progressPct = Math.min(100, Math.round((ing.stock / safeMaxLimit) * 100));

                let badgeHtml = '';
                if (isOutOfStock) {
                    badgeHtml = '<span class="bg-red-100 text-red-800 text-[10px] font-bold px-2 py-0.5 rounded-lg border border-red-200">Hết hàng 🚫</span>';
                } else if (isLowStock) {
                    badgeHtml = '<span class="bg-amber-100 text-amber-800 text-[10px] font-bold px-2 py-0.5 rounded-lg border border-amber-200">Sắp hết hàng ⚠️</span>';
                } else {
                    badgeHtml = '<span class="bg-emerald-50 text-emerald-700 text-[10px] font-bold px-2 py-0.5 rounded-lg border border-emerald-200/50">Đầy đủ 🌿</span>';
                }

                grid.innerHTML += `
                    <div class="bg-coffee-light/60 border ${isOutOfStock ? 'border-red-300 bg-red-50/10' : isLowStock ? 'border-amber-300 bg-amber-50/10' : 'border-coffee-sand/70'} p-4.5 rounded-3xl space-y-3 transition-all hover:bg-white/80 hover:shadow-xs">
                        <div class="flex items-start justify-between">
                            <div>
                                <h4 class="font-bold text-coffee-dark text-xs">${ing.name}</h4>
                                <p class="text-[9.5px] text-coffee-milk font-mono mt-0.5">Mã: ${ing.id.toUpperCase()} • Định mức: ${ing.minStock} ${ing.unit}</p>
                            </div>
                            <div class="shrink-0">
                                ${badgeHtml}
                            </div>
                        </div>

                        <div class="space-y-1.5Packed font-mono">
                            <div class="flex justify-between items-baseline">
                                <span class="text-[9.5px] text-coffee-milk">Tồn hiện có:</span>
                                <span class="font-bold text-sm ${isOutOfStock ? 'text-red-600' : isLowStock ? 'text-amber-600' : 'text-coffee-dark'}">${ing.stock} ${ing.unit}</span>
                            </div>
                            <!-- Visual Progress bar -->
                            <div class="w-full h-2 bg-coffee-sand/40 rounded-full overflow-hidden">
                                <div class="h-full rounded-full transition-all duration-300 ${isOutOfStock ? 'bg-red-500 w-0' : isLowStock ? 'bg-amber-500' : 'bg-coffee-rust'}" style="width: ${progressPct}%"></div>
                            </div>
                        </div>

                        <div class="flex justify-between items-center text-[10px] text-coffee-milk pt-1 border-t border-coffee-sand/20">
                            <span>Đơn giá nhập hộ:</span>
                            <span class="font-mono font-bold text-coffee-dark">${formatVND(ing.importCost)} / ${ing.unit}</span>
                        </div>
                    </div>
                `;
            });
        }

        function renderImportForm() {
            const container = document.getElementById('import-form-lines');
            if (!container) return;
            container.innerHTML = '';

            inventory.forEach((ing, index) => {
                const isOutOfStock = ing.stock <= 0;
                const isLowStock = !isOutOfStock && ing.stock <= ing.minStock;

                container.innerHTML += `
                    <div class="flex items-center gap-4 bg-coffee-light/45 border border-coffee-sand/50 px-4 py-3 rounded-2xl flex-wrap sm:flex-nowrap">
                        <div class="flex-1">
                            <h4 class="font-bold text-xs text-coffee-dark flex items-center gap-1.5">
                                ${ing.name}
                                ${isOutOfStock ? '<span class="text-red-600 text-[10px] font-bold">● Hết</span>' : isLowStock ? '<span class="text-amber-600 text-[10px] font-bold">● Sắp hết</span>' : ''}
                            </h4>
                            <p class="text-[10px] text-coffee-milk font-mono">Tồn thực: ${ing.stock} ${ing.unit} • Đơn giá mua: ${formatVND(ing.importCost)}/${ing.unit}</p>
                        </div>
                        <div class="flex items-center gap-2 shrink-0">
                            <input type="number" min="0" value="0" id="import-qty-${ing.id}" oninput="calculateImportReceipt()" class="w-24 bg-white text-xs font-mono font-semibold border border-coffee-sand rounded-xl px-2.5 py-1.5 text-center focus:border-coffee-rust focus:outline-none" placeholder="Nhập số...">
                            <span class="text-xs text-coffee-milk font-mono font-bold w-12">${ing.unit}</span>
                        </div>
                    </div>
                `;
            });

            calculateImportReceipt();
        }

        function calculateImportReceipt() {
            const receiptLines = document.getElementById('checkout-receipt-lines');
            const totalLabel = document.getElementById('checkout-receipt-total');
            if (!receiptLines) return;

            receiptLines.innerHTML = '';
            let cumulativeTotal = 0;

            inventory.forEach(ing => {
                const input = document.getElementById(`import-qty-${ing.id}`);
                if (input) {
                    const val = parseInt(input.value, 10);
                    if (!isNaN(val) && val > 0) {
                        const cost = ing.importCost * val;
                        cumulativeTotal += cost;

                        receiptLines.innerHTML += `
                            <div class="flex justify-between items-center text-[10px] border-b border-coffee-light pb-1">
                                <div class="text-left">
                                    <p class="font-bold text-coffee-dark">${ing.name}</p>
                                    <p>${val} ${ing.unit} x ${formatVND(ing.importCost)}</p>
                                </div>
                                <span class="font-bold text-coffee-dark text-right">${formatVND(cost)}</span>
                            </div>
                        `;
                    }
                }
            });

            if (receiptLines.innerHTML === '') {
                receiptLines.innerHTML = `
                    <div class="text-center py-8 text-coffee-milk italic text-[11px]">
                        Chưa chọn nguyên liệu để thanh toán nhập hàng.
                    </div>
                `;
            }

            totalLabel.innerText = formatVND(cumulativeTotal);
        }

        async function submitImportRequest() {
            const payloadImports = [];
            inventory.forEach(ing => {
                const input = document.getElementById(`import-qty-${ing.id}`);
                if (input) {
                    const qty = parseInt(input.value, 10);
                    if (!isNaN(qty) && qty > 0) {
                        payloadImports.push({ id: ing.id, quantity: qty });
                    }
                }
            });

            if (payloadImports.length === 0) {
                alert('Vui lòng chỉ định số lượng nguyên liệu cần nhập kho trước khi tiến hành thanh toán!');
                return;
            }

            try {
                const loader = document.getElementById('btn-submit-import');
                loader.disabled = true;
                loader.innerText = '🔄 Đang thanh toán chi quỹ...';

                const response = await fetch('/api/inventory/import', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ imports: payloadImports })
                });

                if (response.ok) {
                    const data = await response.json();
                    flashNotify(`🎉 Thanh toán thành công! Đã chi quỹ: ${formatVND(data.totalCost)}`);
                    await syncAllState();
                    switchTab('tab-stock');
                } else {
                    const err = await response.json();
                    alert(`Giao dịch thất bại: ${err.error}`);
                }
            } catch (error) {
                console.error(error);
                alert('Đã xảy ra lỗi kết nối khi thanh toán mua hàng.');
            } finally {
                const btn = document.getElementById('btn-submit-import');
                if (btn) {
                    btn.disabled = false;
                    btn.innerText = '💳 Thanh toán & Nhập kho';
                }
            }
        }

        function renderRecipes() {
            const grid = document.getElementById('recipes-grid');
            if (!grid) return;
            grid.innerHTML = '';

            menu.forEach(item => {
                const isAvailable = item.inStock !== false;
                const clientRecipe = recipeSpecs[item.id] || [];

                let recipeLinesHtml = '';
                if (clientRecipe.length === 0) {
                    recipeLinesHtml = `<p class="text-[11px] text-coffee-milk italic">Món này thuộc dòng chế biến tự do không khấu hao nguyên liệu cố định.</p>`;
                } else {
                    recipeLinesHtml = `
                        <div class="space-y-1 mt-2">
                            <h5 class="text-[10px] font-bold uppercase text-coffee-milk tracking-wider">Nguyên liệu định lượng định sẵn:</h5>
                            <ul class="space-y-1 text-xs text-coffee-dark font-mono">
                                ${clientRecipe.map(req => `
                                    <li class="flex justify-between border-b border-dashed border-coffee-sand/40 pb-0.5">
                                        <span>• ${req.name}</span>
                                        <span class="font-bold">${req.qty}</span>
                                    </li>
                                `).join('')}
                            </ul>
                        </div>
                    `;
                }

                grid.innerHTML += `
                    <div class="border ${isAvailable ? 'border-coffee-sand/70 bg-coffee-light/35' : 'border-red-200 bg-red-50/5'} p-4.5 rounded-3xl space-y-3">
                        <div class="flex justify-between items-start">
                            <div>
                                <span class="text-[8px] bg-coffee-dark text-coffee-light font-mono font-bold px-1.5 py-0.5 rounded uppercase tracking-wide">
                                    ${categoryMap[item.category] || item.category}
                                </span>
                                <h4 class="font-serif font-bold text-sm text-coffee-dark mt-1">${item.name}</h4>
                                <p class="text-[10px] text-coffee-milk leading-relaxed line-clamp-1">${item.description}</p>
                            </div>
                            <span class="text-[10px] font-bold px-2 py-0.5 rounded-lg border shrink-0 font-sans ${isAvailable ? 'bg-emerald-50 text-emerald-800 border-emerald-200' : 'bg-red-50 text-red-800 border-red-200'}">
                                ${isAvailable ? 'Sẵn sàng bán 🟢' : 'Hết nguyên liệu 🚫'}
                            </span>
                        </div>

                        ${recipeLinesHtml}

                        <div class="flex justify-between items-center text-[10px] text-coffee-milk pt-1.5 border-t border-coffee-sand/20">
                            <span>Giá bán gốc niêm yết:</span>
                            <span class="font-mono font-bold text-coffee-rust">${formatVND(item.price)}</span>
                        </div>
                    </div>
                `;
            });
        }

        function renderLogs() {
            const container = document.getElementById('logs-table-body');
            const totalLabel = document.getElementById('logs-expenses-total');
            if (!container) return;
            container.innerHTML = '';

            let totalExp = 0;
            if (!expenses || expenses.length === 0) {
                container.innerHTML = `
                    <tr>
                        <td colspan="4" class="py-12 text-center text-coffee-milk italic">
                            Chưa ghi nhận giao dịch chi quỹ nhập kho nguyên liệu nào.
                        </td>
                    </tr>
                `;
                totalLabel.innerText = "Tổng chi: 0 ₫";
                return;
            }

            expenses.sort((a,b) => new Date(b.timestamp) - new Date(a.timestamp));

            expenses.forEach(exp => {
                totalExp += exp.amount;
                const formattedDate = new Date(exp.timestamp).toLocaleString('vi-VN');
                container.innerHTML += `
                    <tr class="hover:bg-coffee-light/30 transition-all font-mono">
                        <td class="py-3.5 px-4 text-coffee-dark font-medium">${formattedDate}</td>
                        <td class="py-3.5 px-4 text-coffee-milk text-[11px]">${exp.id}</td>
                        <td class="py-3.5 px-4 text-coffee-dark text-xs">${exp.details || 'Nhập phụ liệu tổng hợp'}</td>
                        <td class="py-3.5 px-4 text-coffee-rust font-bold text-right text-xs">${formatVND(exp.amount)}</td>
                    </tr>
                `;
            });

            totalLabel.innerText = `Tổng chi: ${formatVND(totalExp)}`;
        }

        function setupWebSocket() {
            const sockProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const endpoint = `${sockProtocol}//${window.location.host}/ws`;
            socket = new WebSocket(endpoint);

            socket.onopen = () => {
                const statusNode = document.getElementById('connection-status');
                if (statusNode) {
                    statusNode.innerHTML = `
                        <div class="bg-emerald-50 text-emerald-800 border border-emerald-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold">
                            <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping"></span>
                            <span>Đồng bộ kho thực tế</span>
                        </div>
                    `;
                }
                syncAllState();
            };

            socket.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    if (data.type === 'inventory_updated' || data.type === 'menu_updated' || data.type === 'order_created' || data.type === 'order_updated') {
                        syncAllState();
                        flashNotify('🔄 Hệ thống ghi nhận vệt nghiệp vụ mới, cập nhật tồn kho!');
                    }
                } catch (e) {
                    syncAllState();
                }
            };

            socket.onclose = () => {
                const statusNode = document.getElementById('connection-status');
                if (statusNode) {
                    statusNode.innerHTML = `
                        <div class="bg-red-50 text-red-800 border border-red-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold">
                            <span class="w-1.5 h-1.5 bg-red-500 rounded-full"></span>
                            <span>Mất kết nối</span>
                        </div>
                    `;
                }
                setTimeout(setupWebSocket, 4000);
            };
        }

        // Set Nav Clock
        setInterval(() => {
            const clockNode = document.getElementById('nav-clock');
            if (clockNode) { clockNode.innerText = new Date().toLocaleTimeString('vi-VN'); }
        }, 1000);

        // Initial setup
        switchTab('tab-stock');
        setupWebSocket();
    </script>
</body>
</html>
