<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nhà cà phê. — hệ thống quản lý chuẩn jsp</title>
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
        /* Grid background matching screenshot */
        .dot-grid-bg {
            background-color: #F6F2E9;
            background-image: radial-gradient(#d3cbb6 1.2px, transparent 1.2px);
            background-size: 24px 24px;
        }
        /* Custom scrollbar */
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
    <!-- Dynamic role-based navigation and security guard -->
    <script>
        (function() {
            var role = localStorage.getItem('auth_role') || '';
            var user = localStorage.getItem('auth_user') || '';
            var path = window.location.pathname;
            var page = path.substring(path.lastIndexOf('/') + 1) || 'index.html';

            var customerPages = ['menu.jsp', 'order-status.jsp', 'member.jsp'];
            var waiterPages = ['waitstation.jsp', 'staff-orders.jsp', 'table-qr.jsp', 'order-summary.jsp'];
            var baristaPages = ['kds.jsp'];
            var managerPages = ['dashboard.jsp', 'reports.jsp', 'staff-management.jsp', 'inventory.jsp'];

            // Security guard removed, now handled by SecurityFilter

            document.addEventListener("DOMContentLoaded", function() {
                var navContainer = document.querySelector('nav div.hidden.lg\\:flex');
                if (!navContainer) return;

                var navHtml = '';
                if (customerPages.indexOf(page) !== -1 || page === 'index.html' || page === 'login.jsp' || page === 'pin-login.jsp') {
                    if (!role) {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                            '<a href="menu.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'menu.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">Khách gọi món</a>' +
                            '<a href="order-status.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'order-status.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Kiểm tra đơn nước 🔍</a>' +
                            '<a href="member.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'member.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Khách Thành Viên 🎟️</a>';
                    } else if (role === 'waiter') {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors">Trang chủ</a>' +
                            '<a href="waitstation.jsp" class="hover:text-coffee-rust transition-colors font-semibold">Wait Station 📟</a>' +
                            '<a href="staff-orders.jsp" class="hover:text-coffee-rust transition-colors">Danh sách Order 📋</a>' +
                            '<a href="table-qr.jsp" class="hover:text-coffee-rust transition-colors">In mã QR Bàn 🖨️</a>';
                    } else if (role === 'barista') {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors">Trang chủ</a>' +
                            '<a href="kds.jsp" class="hover:text-coffee-rust transition-colors font-semibold">Kitchen KDS 🧑‍🍳</a>';
                    } else if (role === 'manager') {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors">Trang chủ</a>' +
                            '<a href="dashboard.jsp" class="hover:text-coffee-rust transition-colors">📊 Dashboard</a>' +
                            '<a href="reports.jsp" class="hover:text-coffee-rust transition-colors">📈 Doanh số</a>' +
                            '<a href="staff-management.jsp" class="hover:text-coffee-rust transition-colors">🧑‍🤝‍🧑 Nhân sự</a>' +
                            '<a href="inventory.jsp" class="hover:text-coffee-rust transition-colors">📦 Kho hàng</a>' +
                           '<div class="relative group">' +
                               '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
                                   '<span>Thao tác trực</span>' +
                                   '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
                               '</button>' +
                               '<div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
                                '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📦 Kho nguyên liệu</a>' +
                                
                                    '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📦 Kho nguyên liệu</a>' +
                                    '<a href="waitstation.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📟 Wait Station floor</a>' +
                                   '<a href="kds.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">🧑‍🍳 Kitchen KDS screen</a>' +
                                   '<a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">📋 Danh sách Order</a>' +
                                   '<a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🖨️ In mã QR Bàn</a>' +
                                   '<a href="menu.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">☕ Giao diện Khách</a>' +
                               '</div>' +
                           '</div>';
                    }
                } else if (role === 'waiter' || waiterPages.indexOf(page) !== -1) {
                    navHtml = 
                        '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                        '<a href="waitstation.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'waitstation.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">Wait Station 📟</a>' +
                        '<a href="staff-orders.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'staff-orders.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Danh sách Order 📋</a>' +
                        '<a href="table-qr.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'table-qr.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">In mã QR Bàn 🖨️</a>';
                } else if (role === 'barista' || baristaPages.indexOf(page) !== -1) {
                    navHtml = 
                        '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                        '<a href="kds.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'kds.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">Kitchen KDS 🧑‍🍳</a>';
                } else if (role === 'manager' || managerPages.indexOf(page) !== -1) {
                    navHtml = 
                        '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                        '<a href="dashboard.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'dashboard.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">📊 Dashboard</a>' +
                        '<a href="reports.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'reports.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">📈 Doanh số</a>' +
                        '<a href="staff-management.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'staff-management.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">🧑‍🤝‍🧑 Nhân sự</a>' +
                        '<a href="inventory.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'inventory.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">📦 Kho hàng</a>' +
                        '<div class="relative group">' +
                            '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
                                '<span>Thao tác trực</span>' +
                                '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
                            '</button>' +
                            '<div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
                                '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📦 Kho nguyên liệu</a>' +
                                
                                    '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📦 Kho nguyên liệu</a>' +
                                    '<a href="waitstation.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📟 Wait Station floor</a>' +
                                '<a href="kds.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">🧑‍🍳 Kitchen KDS screen</a>' +
                                '<a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">📋 Danh sách Order</a>' +
                                '<a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🖨️ In mã QR Bàn</a>' +
                                '<a href="menu.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">☕ Giao diện Khách</a>' +
                            '</div>' +
                        '</div>';
                }
                navContainer.innerHTML = navHtml;

                // Render badge and logout button (only for staff pages or logged in)
                var rightNavArea = document.querySelector('nav div.flex.items-center.gap-3 div.flex.items-center.gap-1\\.5') || document.querySelector('nav div.flex.items-center.gap-3');
                if (rightNavArea && role) {
                    var roleBadge = '';
                    if (role === 'manager') roleBadge = '💼 Quản lý';
                    else if (role === 'waiter') roleBadge = '📟 Phục vụ';
                    else if (role === 'barista') roleBadge = '🧑‍🍳 Pha chế';

                    var badgeHtml = 
                        '<div class="flex items-center gap-2">' +
                            '<div class="bg-coffee-dark text-coffee-bg border border-coffee-rust/30 px-3.5 py-1.5 rounded-xl text-[10px] uppercase font-bold font-mono tracking-wide flex items-center gap-1.5 shadow-xs">' +
                                '<span class="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping"></span>' +
                                '<span>' + roleBadge + ': ' + user + '</span>' +
                            '</div>' +
                            '<button onclick="handleLocalLogout()" class="text-xs font-bold px-2 py-1.5 bg-red-50 hover:bg-red-500 hover:text-white border border-red-200 text-red-600 rounded-xl shadow-xs transition-all cursor-pointer">' +
                                'Đăng xuất ↩' +
                            '</button>' +
                        '</div>';

                    var backBtnChild = rightNavArea.querySelector('a[href="index.html"]');
                    if (backBtnChild) {
                        backBtnChild.parentElement.innerHTML = badgeHtml;
                    } else {
                        var existingLogoutBtn = rightNavArea.querySelector('button[onclick="handleLocalLogout()"]');
                        if (!existingLogoutBtn) {
                            var badgeDiv = document.createElement('div');
                            badgeDiv.className = 'flex items-center gap-1.5 ml-2';
                            badgeDiv.innerHTML = badgeHtml;
                            rightNavArea.appendChild(badgeDiv);
                        }
                    }
                }
            });
        })();

        async function handleLocalLogout() {
            localStorage.removeItem('auth_role');
            localStorage.removeItem('auth_user');
            try { await fetch('/api/auth/logout', { method: 'POST' }); } catch(e) {}
            alert('Đã đăng xuất tài khoản làm việc POS! Chuyển hướng về cổng portal.');
            window.location.href = 'staff.html';
        }
    </script>
</head>
<body class="min-h-screen flex flex-col dot-grid-bg relative selection:bg-coffee-rust/20 selection:text-coffee-rust">

    <!-- TOP NAVIGATION BAR -->
    <nav class="border-b border-coffee-sand/70 bg-coffee-bg/90 backdrop-blur sticky top-0 z-40 px-6 py-4 transition-all">
        <div class="max-w-7xl mx-auto flex items-center justify-between">
            
            <!-- Logo Brand -->
            <a href="index.html" class="flex items-center gap-2 group">
                <span class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark select-none">
                    nhà cà phê<span class="text-coffee-rust">.</span>
                </span>
            </a>

            <!-- Dropdown Menu / Quick Links Header mapping all pages -->
            <div class="hidden lg:flex items-center gap-4 text-xs font-medium">
                <a href="index.html" class="hover:text-coffee-rust transition-colors text-coffee-milk">Trang chủ</a>
                <a href="menu.jsp" class="hover:text-coffee-rust transition-colors text-coffee-dark font-bold">Khách gọi món</a>
                <a href="order-status.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Kiểm tra đơn nước 🔍</a>
                <a href="member.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Khách Thành Viên 🎟️</a>
            </div>

            <!-- Status Indicator and Navigation -->
            <div class="flex items-center gap-3">
                
                <!-- Live Sync Node Indicator -->
                <div id="connection-status">
                    <div class="bg-amber-50 text-amber-800 border border-amber-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-medium">
                        <span class="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse"></span>
                        <span>Đang kết nối...</span>
                    </div>
                </div>

                <!-- Clock -->
                <div class="hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>

                <!-- Active View info badge -->
                <div class="flex items-center gap-1.5">
                    <a href="javascript:history.back()" class="text-xs font-bold px-3 py-1.5 bg-white hover:bg-coffee-rust hover:text-white border border-coffee-sand rounded-xl shadow-xs transition-all pointer">
                        Quay lại ↩
                    </a>
                </div>

            </div>
        </div>
    </nav>

    <!-- LIVE POP-UP FLASH BANNERS -->
    <div id="flash-banner-container" class="hidden fixed bottom-6 right-6 z-50 max-w-sm w-full animate-bounce">
        <div id="flash-banner" class="bg-coffee-dark text-white border border-coffee-rust/50 px-4 py-3 rounded-2xl flex items-center gap-2.5 shadow-xl">
            <div class="w-8 h-8 rounded-full bg-coffee-rust flex items-center justify-center shrink-0">
                ☕
            </div>
            <div class="flex-1 text-xs">
                <p id="flash-message" class="font-medium text-coffee-bg">Đã cập nhật trạng thái đồng bộ!</p>
            </div>
        </div>
    </div>

    <!-- MAIN PORTAL CONTENT CONTAINER -->
    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col justify-start">

<div class="space-y-6">
    <div id="ordering-warning-banner" class="hidden"></div>
    <!-- Header visual banner -->
    <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="space-y-1">
            <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                <span>☕</span> Chọn đồ uống & Gọi món tại bàn
            </h2>
            <p class="text-xs text-coffee-milk font-medium">Thực đơn nhà làm — gọi món để pha chế trực tiếp phục vụ tại bàn của bạn.</p>
        </div>

        <!-- Stable Table Seating Selector (Controlled & Protected) -->
        <div id="table-seating-container" class="flex items-center gap-3 bg-coffee-light border border-coffee-sand px-3 py-2 rounded-2xl">
            <!-- Rendered dynamically depending on role to prevent guest tampering -->
        </div>
    </div>

    <!-- Main Workspace layout -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        
        <!-- Menu list: Left column -->
        <div class="lg:col-span-2 space-y-4">
            <!-- Search + Filters -->
            <div class="flex flex-col sm:flex-row items-center gap-3 bg-white border border-coffee-sand p-3.5 rounded-2xl shadow-xs">
                <!-- Category sliders -->
                <div class="flex flex-wrap gap-1.5 w-full sm:w-auto overflow-x-auto" id="cust-categories">
                    <button onclick="setCustMenuCategory('All')" id="custcat-all" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-rust text-white rounded-lg">Tất cả</button>
                    <button onclick="setCustMenuCategory('Coffee')" id="custcat-coffee" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Cà phê</button>
                    <button onclick="setCustMenuCategory('Tea')" id="custcat-tea" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Trà phin</button>
                    <button onclick="setCustMenuCategory('Specialty')" id="custcat-specialty" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Đặc sản</button>
                    <button onclick="setCustMenuCategory('Pastry')" id="custcat-pastry" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Bánh ngọt</button>
                </div>
                <!-- Search inputs -->
                <div class="relative w-full sm:flex-1">
                    <input type="text" id="cust-search" oninput="drawCustMenuList()" placeholder="Tìm món nước nhanh..." class="w-full text-xs px-3 py-2 pl-8 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white">
                    <svg class="w-3.5 h-3.5 text-coffee-milk absolute left-2.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
            </div>

            <!-- Beverage cards grid -->
            <div id="cust-menu-container" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <!-- Loaded from API -->
            </div>
        </div>

        <!-- Basket & History trackers: Right column -->
        <div class="space-y-6">
            
            <!-- Basket Card -->
            <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4">
                <div class="flex items-center justify-between border-b border-coffee-sand/60 pb-3">
                    <div>
                        <h3 class="font-serif italic font-bold text-base text-coffee-dark">Giỏ hàng của bạn</h3>
                        <p class="text-[10px] text-coffee-milk">Các đồ uống đặt tại bàn hiện tại</p>
                    </div>
                    <span id="cart-item-count" class="text-[10px] font-mono font-bold bg-coffee-rust text-white px-2.5 py-0.5 rounded-full">
                        0 món
                    </span>
                </div>

                <!-- Product row container -->
                <div id="guest-cart-container" class="space-y-3 max-h-[300px] overflow-y-auto pr-1">
                    <!-- Populated dynamically -->
                </div>

                <!-- Notes & Action -->
                <div class="border-t border-coffee-sand/60 pt-4 space-y-3">
                    <div>
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block mb-1">Ghi chú pha chế riêng</label>
                        <textarea id="guest-order-notes" placeholder="Ví dụ: Lấy nhiều ly đá, cho đường ít..." class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl h-14 focus:outline-none focus:border-coffee-rust focus:bg-white"></textarea>
                    </div>

                    <!-- Member voucher container -->
                    <div id="cart-membership-section" class="bg-coffee-light/60 border border-coffee-sand/70 p-3.5 rounded-2xl text-xs">
                        <!-- Loaded dynamically -->
                    </div>

                    <div class="bg-[#FAF7EE] border border-coffee-sand/80 px-4 py-3 rounded-2xl flex items-center justify-between">
                        <span class="text-xs font-bold text-coffee-milk">Thành tiền:</span>
                        <span id="guest-cart-total" class="font-mono font-bold text-sm text-coffee-rust">0 ₫</span>
                    </div>

                    <button onclick="submitGuestTicket()" class="w-full bg-coffee-rust text-white font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all cursor-pointer flex justify-center items-center gap-1.5 shadow-sm">
                        Gửi gọi món tới bếp 🚀
                    </button>
                    
                    <a href="order-status.jsp" class="block w-full text-center text-xs font-bold font-mono text-coffee-rust hover:underline">
                        🔍 Xem chi tiết Trạng thái đơn bàn của bạn →
                    </a>
                </div>
            </div>

            <!-- Active Pending tickets tracker right in view! -->
            <div id="guest-history-card" class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4 hidden">
                <div class="border-b border-coffee-sand pb-2">
                    <h4 class="font-serif italic font-bold text-sm text-coffee-dark">Trạng thái pha chế tại <span id="history-table-label" class="text-coffee-rust">Bàn --</span></h4>
                    <p class="text-[9.5px] text-coffee-milk">Đơn nước của bạn đang được pha chế trực tiếp...</p>
                </div>
                <div id="guest-history-container" class="space-y-3">
                    <!-- Dynamic state queue -->
                </div>
            </div>

        </div>

    </div>
</div>

<!-- WAITER TABLE SWAP VERIFICATION MODAL -->
<div id="waiter-confirmation-modal" class="fixed inset-0 bg-coffee-dark/50 z-50 hidden items-center justify-center p-4">
    <div class="bg-[#FAF7EE] border border-coffee-sand rounded-3xl p-6 max-w-sm w-full shadow-2xl relative">
        <button onclick="closeWaiterConfirmationModal()" class="absolute top-4 right-4 text-coffee-milk hover:text-coffee-dark text-xl transition-colors cursor-pointer">
            ✕
        </button>
        
        <div class="space-y-4">
            <div class="text-center pb-2 border-b border-coffee-sand/80">
                <span class="text-2xl">🔑</span>
                <h3 class="text-lg font-serif italic font-bold text-coffee-dark">Phục vụ Xác nhận Đổi Bàn</h3>
                <p class="text-[11px] text-coffee-milk">Nhân viên cần nhập mã PIN để xác minh thẩm quyền chuyển bàn</p>
            </div>
            
            <!-- Staff Selector -->
            <div class="space-y-1">
                <label class="text-[10px] font-bold uppercase text-coffee-rust block">Nhân viên xác nhận:</label>
                <select id="modal-waiter-select" class="w-full text-xs font-bold px-3 py-2 bg-white border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust outline-none cursor-pointer">
                    <!-- Populated dynamically -->
                </select>
            </div>

            <!-- Target Table Selector -->
            <div class="space-y-1">
                <label class="text-[10px] font-bold uppercase text-coffee-rust block">Chọn bàn muốn chuyển đến:</label>
                <select id="modal-target-table-select" class="w-full text-xs font-bold px-3 py-2 bg-white border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust outline-none cursor-pointer">
                    <!-- Populated dynamically -->
                </select>
            </div>

            <!-- PIN Code Input Field -->
            <div class="space-y-1.5 text-center">
                <label class="text-[10px] font-bold uppercase text-coffee-rust block">Mã PIN Nhân viên (4 số):</label>
                <input type="password" id="modal-waiter-pin" readonly maxlength="4" placeholder="••••" class="w-32 mx-auto text-center text-lg font-mono font-bold tracking-[0.5em] px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust outline-none font-medium">
            </div>

            <!-- Custom Pinpad -->
            <div class="grid grid-cols-3 gap-2 max-w-[240px] mx-auto pt-1">
                <button onclick="tapModalPin('1')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">1</button>
                <button onclick="tapModalPin('2')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">2</button>
                <button onclick="tapModalPin('3')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">3</button>
                <button onclick="tapModalPin('4')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">4</button>
                <button onclick="tapModalPin('5')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">5</button>
                <button onclick="tapModalPin('6')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">6</button>
                <button onclick="tapModalPin('7')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">7</button>
                <button onclick="tapModalPin('8')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">8</button>
                <button onclick="tapModalPin('9')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">9</button>
                <button onclick="clearModalPin()" class="bg-red-50 hover:bg-red-100 text-red-600 font-bold py-2 rounded-xl border border-red-100 text-[10px] active:scale-95 transition-all cursor-pointer flex items-center justify-center">Xóa</button>
                <button onclick="tapModalPin('0')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">0</button>
                <button onclick="popModalPin()" class="bg-coffee-light hover:bg-coffee-sand/40 text-coffee-milk font-bold py-2 rounded-xl border border-coffee-sand/60 text-[10px] active:scale-95 transition-all cursor-pointer flex items-center justify-center">⌫</button>
            </div>

            <!-- Action button -->
            <button onclick="confirmWaiterTableSwap()" class="w-full bg-coffee-rust hover:bg-coffee-rust/95 text-white font-bold py-2.5 px-4 rounded-xl text-xs uppercase tracking-wider active:scale-[0.98] transition-all cursor-pointer text-center shadow-xs">
                Xác nhận Đổi Bàn ⚡
            </button>
        </div>
    </div>
</div>

<!-- ITEM CONFIGURATION POPUP MODAL (GUEST CUSTOMIZER) -->
<div id="customization-modal" class="fixed inset-0 bg-coffee-dark/50 z-50 hidden items-center justify-center p-4">
    <div class="bg-[#FAF7EE] border border-coffee-sand rounded-3xl p-6 max-w-sm w-full shadow-2xl relative">
        <button onclick="closeCustomizationModal()" class="absolute top-4 right-4 text-coffee-milk hover:text-coffee-dark text-xl transition-colors cursor-pointer">
            ✕
        </button>
        
        <div id="modal-product-header" class="space-y-1 pr-6 pb-4 border-b border-coffee-sand/80">
            <!-- Populated dynamically -->
        </div>

        <!-- Custom parameters -->
        <div class="py-4 space-y-4">
            <!-- Size selector -->
            <div class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide">Kích cỡ đồ uống (Size)</label>
                <div id="modal-size-container" class="grid grid-cols-3 gap-2">
                    <!-- Buttons -->
                </div>
            </div>

            <!-- Sugar selector -->
            <div id="modal-sugar-wrapper" class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide">Định lượng ngọt (Đường)</label>
                <div class="grid grid-cols-5 gap-1.5" id="modal-sugar-container">
                    <!-- Buttons -->
                </div>
            </div>

            <!-- Ice selector -->
            <div id="modal-ice-wrapper" class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide">Độ mát lạnh (Đá)</label>
                <div class="grid grid-cols-4 gap-1.5" id="modal-ice-container">
                    <!-- Buttons -->
                </div>
            </div>

            <!-- Modifier remarks -->
            <div class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide">Yêu cầu thêm</label>
                <input type="text" id="modal-notes-input" placeholder="Ví dụ: Để đá riêng, ít ngọt..." class="w-full text-xs px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
            </div>
        </div>

        <div class="flex items-center gap-3 pt-3 border-t border-coffee-sand/80">
            <!-- Quantity tools -->
            <div class="flex items-center gap-2">
                <button onclick="changeModalQty(-1)" class="w-8 h-8 rounded-full border border-coffee-sand bg-white flex items-center justify-center font-bold text-coffee-dark hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">-</button>
                <span id="modal-qty-label" class="font-mono text-sm font-bold w-4 text-center">1</span>
                <button onclick="changeModalQty(1)" class="w-8 h-8 rounded-full border border-coffee-sand bg-white flex items-center justify-center font-bold text-coffee-dark hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">+</button>
            </div>
            
            <button id="modal-action-btn" onclick="confirmProductCustomization()" class="flex-1 bg-coffee-rust text-white font-bold py-2.5 px-4 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-colors cursor-pointer text-center">
                Thêm vào giỏ 🛒
            </button>
        </div>
    </div>
</div>

<!-- CLIENT REAL-TIME INTEGRATIONS -->
<script>
    let menu = [];
    let tables = [];
    let orders = [];

    let customerCategory = 'All';
    const urlParams = new URLSearchParams(window.location.search);
    const urlTableId = urlParams.get('tableId');
    const authRole = localStorage.getItem('auth_role') || '';
    const isStaffUser = (authRole === 'waiter' || authRole === 'manager');

    let userSittingTableId = 't1';
    if (urlTableId) {
        userSittingTableId = urlTableId;
        localStorage.setItem('user_sitting_table_id', urlTableId);
    } else {
        if (isStaffUser) {
            userSittingTableId = localStorage.getItem('user_sitting_table_id') || 't1';
        } else {
            userSittingTableId = 't1';
            localStorage.setItem('user_sitting_table_id', 't1');
        }
    }
    let custCartItems = [];

    let modalActiveProduct = null;
    let modalSize = 'M';
    let modalSugar = '100%';
    let modalIce = '100%';
    let modalQty = 1;

    let socket = null;

    const categoryMap = {
        'Coffee': 'Cà phê',
        'Tea': 'Trà phin',
        'Specialty': 'Đặc sản sữa',
        'Pastry': 'Bánh ngọt'
    };

    function formatVND(amt) {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amt);
    }

    let shopClosedGlobal = false;

    async function checkOrderingRestriction() {
        try {
            const res = await fetch('/api/shop/status');
            if (res.ok) {
                const data = await res.json();
                shopClosedGlobal = data.closed;
            }
        } catch (e) {
            console.error('Failed to fetch shop status:', e);
        }

        const currentHour = new Date().getHours();
        const hourRestricted = (currentHour >= 22 || currentHour < 6);
        const restricted = shopClosedGlobal || hourRestricted;

        const warningBanner = document.getElementById('ordering-warning-banner');
        const submitBtn = document.querySelector('button[onclick="submitGuestTicket()"]');

        if (restricted) {
            let reasonStr = "";
            if (shopClosedGlobal) {
                reasonStr = "Quầy đang tạm đóng cửa nhận đơn theo chỉ định của Quản lý";
            } else {
                reasonStr = "Hệ thống tạm ngưng nhận các đơn nước sau 22:00 hằng ngày";
            }

            if (warningBanner) {
                warningBanner.innerHTML = `
                    <div class="bg-red-50 border border-red-250 text-red-800 p-4 rounded-3xl text-xs flex items-center gap-3 animate-pulse my-2">
                        <span class="text-xl">🛑</span>
                        <div>
                            <p class="font-bold uppercase tracking-wider text-red-900">Thông báo ngừng nhận đơn nước</p>
                            <p class="text-[11px] text-red-700 font-medium">${reasonStr}. Quý khách và Hội viên chỉ có thể tham khảo chi tiết Menu và kiểm tra trạng thái thanh toán.</p>
                        </div>
                    </div>
                `;
                warningBanner.classList.remove('hidden');
            }

            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.className = "w-full bg-coffee-sand text-coffee-milk font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider cursor-not-allowed flex justify-center items-center gap-1.5 shadow-none";
                submitBtn.innerText = "🛑 ĐÃ TẠM NGƯNG NHẬN ĐƠN";
            }
        } else {
            if (warningBanner) {
                warningBanner.classList.add('hidden');
            }
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.className = "w-full bg-coffee-rust text-white font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all cursor-pointer flex justify-center items-center gap-1.5 shadow-sm";
                submitBtn.innerText = "Gửi gọi món tới bếp 🚀";
            }
        }
    }

    async function fetchStateCore() {
        try {
            await checkOrderingRestriction();
            const [rMenu, rTables, rOrders] = await Promise.all([
                fetch('/api/menu'),
                fetch('/api/tables'),
                fetch('/api/orders')
            ]);

            if (rMenu.ok) menu = await rMenu.json();
            if (rTables.ok) tables = await rTables.json();
            if (rOrders.ok) orders = await rOrders.json();

            drawCustomerDropdown();
            drawCustMenuList();
            drawCustCartList();
            drawGuestHistory();
        } catch (err) {
            console.error('Core fetch error', err);
        }
    }

    function setupWebSocket() {
        const sockProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const endpoint = `${sockProtocol}//${window.location.host}/ws`;
        socket = new WebSocket(endpoint);

        socket.onopen = () => {
            setWsIndicator('connected');
            fetchStateCore();
        };

        socket.onmessage = () => {
            fetchStateCore();
            flashNotify('🔄 Đơn nước bàn bạn vừa được đồng bộ cập nhật!');
        };

        socket.onclose = () => {
            setWsIndicator('disconnected');
            setTimeout(setupWebSocket, 4000);
        };
    }

    function setWsIndicator(stat) {
        const indicator = document.getElementById('connection-status');
        if (!indicator) return;
        if (stat === 'connected') {
            indicator.innerHTML = `
                <div class="bg-emerald-50 text-emerald-800 border border-emerald-250/60 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold">
                    <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping"></span>
                    <span>Đồng bộ thực đơn thực tế</span>
                </div>
            `;
        } else {
            indicator.innerHTML = `
                <div class="bg-red-50 text-red-800 border border-red-250/60 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold">
                    <span class="w-1.5 h-1.5 bg-red-500 rounded-full"></span>
                    <span>Ngoại tuyến (đang kết nối)</span>
                </div>
            `;
        }
    }

    function changeSittingTable(newId) {
        userSittingTableId = newId;
        localStorage.setItem('user_sitting_table_id', newId);
        fetchStateCore();
    }

    function drawCustomerDropdown() {
        const container = document.getElementById('table-seating-container');
        if (!container) return;

        const role = localStorage.getItem('auth_role') || '';
        const isStaff = (role === 'waiter' || role === 'manager');

        // Find the current sitting table object
        const activeTableObj = tables.find(t => t.id === userSittingTableId);
        const activeTableName = activeTableObj ? activeTableObj.name : 'Bàn --';

        if (isStaff) {
            // Staff mode: interactive selector dropdown
            let selectHtml = `
                <div class="flex items-center gap-2 flex-wrap">
                    <label class="text-xs font-bold text-coffee-rust shrink-0">BÀN ĐANG SỬ DỤNG:</label>
                    <select id="user-sitting-table" onchange="changeSittingTable(this.value)" class="bg-white text-xs font-bold text-coffee-dark border border-coffee-sand/80 px-2.5 py-1 rounded-xl outline-none focus:border-coffee-rust cursor-pointer">
            `;
            tables.forEach(t => {
                const isSelected = (t.id === userSittingTableId) ? 'selected' : '';
                selectHtml += `<option value="${t.id}" ${isSelected}>${t.name} (${t.zone === 'Ground Floor' ? 'Tầng trệt' : t.zone === 'Terrace' ? 'Sân vườn' : 'Khu lửng'})</option>`;
            });
            selectHtml += `</select>`;
            selectHtml += `
                    <span class="text-[9px] bg-amber-50 text-amber-700 border border-amber-200/50 px-2 py-0.5 rounded-lg font-bold font-mono">STAFF MODE</span>
                </div>
            `;
            container.innerHTML = selectHtml;
        } else {
            // Guest mode: lock active table badge and offer Waiter PIN or scan QR action
            let customerHtml = `
                <div class="flex items-center gap-3 flex-wrap">
                    <label class="text-xs font-bold text-coffee-rust shrink-0">BÀN GỌI MÓN:</label>
                    <div class="bg-coffee-dark text-[#FAF7EE] text-xs font-bold px-3.5 py-1.5 rounded-xl flex items-center gap-1.5 shadow-xs select-none">
                        <span>${activeTableName}</span>
                        <span class="text-[11px] opacity-90">🔒</span>
                    </div>
                    <button onclick="openWaiterConfirmationModal()" class="text-xs font-bold text-coffee-rust bg-white hover:bg-coffee-light border border-coffee-sand/80 hover:border-coffee-rust px-2.5 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1 active:scale-95 shadow-2xs">
                        <span>🔑 Thay đổi</span>
                    </button>
                    <span class="text-[9.5px] text-coffee-milk font-medium hidden md:inline">
                        Để đổi bàn: vui lòng báo Phục vụ nhập PIN hoặc Quét lại QR bàn mới
                    </span>
                </div>
            `;
            container.innerHTML = customerHtml;
        }
    }

    let modalPinStr = '';

    function openWaiterConfirmationModal() {
        modalPinStr = '';
        const pinInput = document.getElementById('modal-waiter-pin');
        if (pinInput) pinInput.value = '';

        // Load roster
        let roster = JSON.parse(localStorage.getItem('staff_roster')) || [];
        if (roster.length === 0) {
            roster = [
                { id: 1, name: 'Quản lý Hệ Thống', role: 'manager', pin: '8888', shift: 'Toàn thời gian', active: true, username: 'admin', password: '123456' },
                { id: 2, name: 'Nhân viên Phục vụ (waiter1)', role: 'waiter', pin: '1234', shift: 'Ca sáng (06:00 - 12:00)', active: true, username: 'waiter1', password: '123456' },
                { id: 3, name: 'Nhân viên Pha chế (barista1)', role: 'barista', pin: '3333', shift: 'Ca chiều (12:00 - 18:00)', active: true, username: 'barista1', password: '123456' }
            ];
            localStorage.setItem('staff_roster', JSON.stringify(roster));
        }

        // Filter valid table swappers (waiter & manager)
        const eligibleStaff = roster.filter(s => s.role === 'waiter' || s.role === 'manager');

        // Populate waiter list
        const wSelect = document.getElementById('modal-waiter-select');
        if (wSelect) {
            wSelect.innerHTML = '';
            eligibleStaff.forEach(s => {
                const opt = document.createElement('option');
                opt.value = s.username;
                opt.text = `${s.name} (${s.role === 'manager' ? 'Quản lý' : 'Phục vụ'})`;
                wSelect.appendChild(opt);
            });
        }

        // Populate target tables
        const tSelect = document.getElementById('modal-target-table-select');
        if (tSelect) {
            tSelect.innerHTML = '';
            tables.forEach(t => {
                const opt = document.createElement('option');
                opt.value = t.id;
                opt.text = `${t.name} (${t.zone === 'Ground Floor' ? 'Tầng trệt' : t.zone === 'Terrace' ? 'Sân vườn' : 'Khu lửng'})`;
                if (t.id === userSittingTableId) {
                    opt.text += ' [Đang ngồi tại đây]';
                    opt.selected = true;
                }
                tSelect.appendChild(opt);
            });
        }

        const modal = document.getElementById('waiter-confirmation-modal');
        if (modal) {
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        }
    }

    function closeWaiterConfirmationModal() {
        const modal = document.getElementById('waiter-confirmation-modal');
        if (modal) {
            modal.classList.remove('flex');
            modal.classList.add('hidden');
        }
    }

    function tapModalPin(num) {
        if (modalPinStr.length < 4) {
            modalPinStr += num;
            const pinInput = document.getElementById('modal-waiter-pin');
            if (pinInput) pinInput.value = modalPinStr;
        }
    }

    function popModalPin() {
        if (modalPinStr.length > 0) {
            modalPinStr = modalPinStr.slice(0, -1);
            const pinInput = document.getElementById('modal-waiter-pin');
            if (pinInput) pinInput.value = modalPinStr;
        }
    }

    function clearModalPin() {
        modalPinStr = '';
        const pinInput = document.getElementById('modal-waiter-pin');
        if (pinInput) pinInput.value = '';
    }

    function confirmWaiterTableSwap() {
        const typedUser = document.getElementById('modal-waiter-select').value;
        const enteredPin = modalPinStr;
        const targetTableId = document.getElementById('modal-target-table-select').value;

        let roster = JSON.parse(localStorage.getItem('staff_roster')) || [];
        const match = roster.find(s => s.username === typedUser && s.pin === enteredPin);

        if (!match) {
            alert('Mã PIN xác thực không chính xác! Vui lòng thử lại.');
            clearModalPin();
            return;
        }

        if (targetTableId === userSittingTableId) {
            alert('Bàn đích trùng khớp với bàn hiện tại của khách!');
            return;
        }

        // Apply transfer and save state
        changeSittingTable(targetTableId);
        closeWaiterConfirmationModal();
        flashNotify(`🔄 Đã chuyển khách sang ${tables.find(t => t.id === targetTableId).name} (được duyệt bởi ${match.name})`);
    }

    function setCustMenuCategory(cat) {
        customerCategory = cat;
        ['All', 'Coffee', 'Tea', 'Specialty', 'Pastry'].forEach(p => {
            const btn = document.getElementById(`custcat-${p === 'All' ? 'all' : p.toLowerCase()}`);
            if (!btn) return;
            if (p === cat) {
                btn.className = "text-[11px] font-bold px-3 py-1.5 bg-coffee-rust text-white rounded-lg shadow-xs";
            } else {
                btn.className = "text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all";
            }
        });
        drawCustMenuList();
    }

    function drawCustMenuList() {
        const container = document.getElementById('cust-menu-container');
        if (!container) return;
        container.innerHTML = '';

        const keyword = document.getElementById('cust-search').value.toLowerCase();
        const list = menu.filter(m => {
            const matchesCat = customerCategory === 'All' || m.category === customerCategory;
            const matchesKey = m.name.toLowerCase().includes(keyword) || m.description.toLowerCase().includes(keyword);
            return matchesCat && matchesKey;
        });

        if (list.length === 0) {
            container.innerHTML = `
                <div class="col-span-2 text-center py-12 text-xs text-coffee-milk italic bg-white rounded-3xl border border-coffee-sand/50">
                    Không tìm thấy thức uống nào tương ứng.
                </div>
            `;
            return;
        }

        list.forEach(item => {
            const vietNameVal = categoryMap[item.category] || item.category;
            const outOfStock = item.inStock === false;
            container.innerHTML += `
                <div onclick="${outOfStock ? "flashNotify('⚠️ Thức uống này hiện đã tạm hết nguyên liệu pha chế!')" : `triggerCustomerSettings('${item.id}')`}" 
                     class="${outOfStock ? 'opacity-60 relative cursor-not-allowed bg-coffee-light/20' : 'bg-white hover:bg-coffee-light/40 cursor-pointer'} border border-coffee-sand/70 hover:border-coffee-rust/50 transition-all rounded-3xl p-4 flex flex-col justify-between group shadow-xs">
                    
                    ${outOfStock ? `
                    <div class="absolute top-4 right-4 z-10 bg-red-50 text-red-750 border border-red-200 text-[10px] font-bold px-2 py-0.5 rounded-full select-none shadow-xs font-mono">
                        Tạm hết hàng 🚫
                    </div>
                    ` : ''}

                    <div class="space-y-3">
                        ${item.image ? `
                        <div class="w-full aspect-[4/3] rounded-2xl overflow-hidden bg-coffee-light border border-coffee-sand/30 relative">
                            <img src="${item.image}" alt="${item.name}" referrerpolicy="no-referrer" class="w-full h-full object-cover ${outOfStock ? '' : 'group-hover:scale-105'} transition-transform duration-300">
                        </div>
                        ` : ''}
                        <div class="space-y-1.5">
                            <div class="flex items-center justify-between gap-2">
                                <span class="text-[8px] tracking-wider uppercase font-mono font-bold bg-coffee-light text-coffee-rust border border-coffee-sand/40 px-2 py-0.5 rounded-md">
                                    ${vietNameVal}
                                </span>
                                <span class="font-mono font-bold text-coffee-rust text-[13px] ${outOfStock ? 'line-through opacity-70' : ''}">
                                    ${formatVND(item.price)}
                                </span>
                            </div>
                            <h4 class="font-serif font-bold text-coffee-dark text-sm ${outOfStock ? 'opacity-70' : 'group-hover:text-coffee-rust'} transition-colors leading-tight">
                                ${item.name}
                            </h4>
                            <p class="text-[11px] text-coffee-milk/80 line-clamp-2 leading-relaxed">
                                ${item.description}
                            </p>
                        </div>
                    </div>
                    <div class="flex items-center justify-between pt-3 mt-3 border-t border-coffee-sand/25">
                        <span class="text-[9px] text-coffee-milk font-mono font-medium">
                            Sizes: ${item.availableSizes.join(', ')}
                        </span>
                        <div class="w-6 h-6 rounded-full bg-coffee-light text-coffee-rust flex items-center justify-center text-[10px] ${outOfStock ? '' : 'group-hover:bg-coffee-rust group-hover:text-white'} transition-all duration-200">
                            ${outOfStock ? '✕' : '＋'}
                        </div>
                    </div>
                </div>
            `;
        });
    }

    function triggerCustomerSettings(menuItemId) {
        const product = menu.find(m => m.id === menuItemId);
        if (!product) return;

        modalActiveProduct = product;
        modalSize = product.availableSizes[0] || 'M';
        modalSugar = '100%';
        modalIce = '100%';
        modalQty = 1;

        const hdr = document.getElementById('modal-product-header');
        hdr.innerHTML = `
            <span class="text-[9px] font-mono font-bold text-coffee-rust bg-coffee-light px-2 py-0.5 rounded border border-coffee-sand/50 inline-block">
                ${categoryMap[product.category] || product.category}
            </span>
            <h3 class="text-base font-serif font-bold text-coffee-dark mt-1">${product.name}</h3>
            <p class="text-xs text-coffee-milk">${product.description}</p>
            <p class="text-xs text-coffee-rust font-mono font-bold pt-1.5" id="modal-product-price-label">Đơn giá gốc: ${formatVND(product.price)}</p>
        `;

        const sizeBox = document.getElementById('modal-size-container');
        sizeBox.innerHTML = '';
        product.availableSizes.forEach(sz => {
            const isSel = modalSize === sz;
            sizeBox.innerHTML += `
                <button onclick="setModalAttr('size', '${sz}')" class="py-1.5 border text-xs font-bold rounded-xl transition-all cursor-pointer ${isSel ? 'bg-coffee-rust border-transparent text-white shadow-xs' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    Cỡ ${sz}
                </button>
            `;
        });

        const sugarBox = document.getElementById('modal-sugar-wrapper');
        const iceBox = document.getElementById('modal-ice-wrapper');
        if (product.category === 'Pastry') {
            sugarBox.classList.add('hidden');
            iceBox.classList.add('hidden');
        } else {
            sugarBox.classList.remove('hidden');
            iceBox.classList.remove('hidden');
            drawModalSugarButtons();
            drawModalIceButtons();
        }

        document.getElementById('modal-notes-input').value = '';
        document.getElementById('modal-qty-label').innerText = '1';

        document.getElementById('customization-modal').className = 'fixed inset-0 bg-coffee-dark/50 z-50 flex items-center justify-center p-4';
        updateModalPriceDisplay();
    }

    function updateModalPriceDisplay() {
        if (!modalActiveProduct) return;
        let singlePrice = modalActiveProduct.price;
        if (modalSize === 'L') singlePrice += 6000;
        else if (modalSize === 'S') singlePrice = Math.max(10000, singlePrice - 4000);

        const totalValue = singlePrice * modalQty;
        
        const priceLabel = document.getElementById('modal-product-price-label');
        if (priceLabel) {
            priceLabel.innerHTML = `Đơn giá: <span class="text-coffee-rust font-bold">${formatVND(singlePrice)}</span>${modalSize !== 'M' ? ` <span class="text-[10px] text-coffee-milk font-normal">(Cỡ ${modalSize})</span>` : ''}`;
        }
        
        const actionBtn = document.getElementById('modal-action-btn');
        if (actionBtn) {
            actionBtn.innerText = `Thêm vào giỏ - ${formatVND(totalValue)} 🛒`;
        }
    }

    function setModalAttr(attr, val) {
        if (attr === 'size') {
            modalSize = val;
            const pills = modalActiveProduct.availableSizes;
            const sizeBox = document.getElementById('modal-size-container');
            Array.from(sizeBox.children).forEach((btn, idx) => {
                const sz = pills[idx];
                if (sz === modalSize) {
                    btn.className = "py-1.5 border text-xs font-bold rounded-xl bg-coffee-rust border-transparent text-white shadow-xs";
                } else {
                    btn.className = "py-1.5 border text-xs font-bold rounded-xl bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust transition-all";
                }
            });
            updateModalPriceDisplay();
        }
        else if (attr === 'sugar') {
            modalSugar = val;
            drawModalSugarButtons();
        }
        else if (attr === 'ice') {
            modalIce = val;
            drawModalIceButtons();
        }
    }

    function drawModalSugarButtons() {
        const container = document.getElementById('modal-sugar-container');
        container.innerHTML = '';
        ['100%', '70%', '50%', '30%', '0%'].forEach(opt => {
            const isSel = modalSugar === opt;
            const optViStr = opt === '0%' ? 'Ít ngọt' : opt;
            container.innerHTML += `
                <button onclick="setModalAttr('sugar', '${opt}')" class="py-1 text-[10px] font-bold rounded-lg cursor-pointer ${isSel ? 'bg-coffee-rust border-transparent text-white' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    ${optViStr}
                </button>
            `;
        });
    }

    function drawModalIceButtons() {
        const container = document.getElementById('modal-ice-container');
        container.innerHTML = '';
        ['100%', '50%', '30%', 'Ấm'].forEach(opt => {
            const isSel = modalIce === opt;
            container.innerHTML += `
                <button onclick="setModalAttr('ice', '${opt}')" class="py-1 text-[10px] font-bold rounded-lg cursor-pointer ${isSel ? 'bg-coffee-rust border-transparent text-white' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    ${opt}
                </button>
            `;
        });
    }

    function changeModalQty(delta) {
        const n = modalQty + delta;
        if (n > 0) {
            modalQty = n;
            document.getElementById('modal-qty-label').innerText = n;
            updateModalPriceDisplay();
        }
    }

    function closeCustomizationModal() {
        document.getElementById('customization-modal').className = 'fixed inset-0 bg-coffee-dark/50 z-50 hidden items-center justify-center p-4';
    }

    function confirmProductCustomization() {
        if (!modalActiveProduct) return;

        custCartItems.push({
            menuItem: modalActiveProduct,
            quantity: modalQty,
            customization: {
                size: modalSize,
                sugar: modalSugar,
                ice: modalIce
            },
            notes: document.getElementById('modal-notes-input').value
        });

        closeCustomizationModal();
        drawCustCartList();
        flashNotify('💖 Thức uống đã được thêm vào giỏ hàng!');
    }

    let selectedVoucherCode = '';
    let selectedVoucherDiscount = 0;

    async function drawCartMembershipSection() {
        const section = document.getElementById('cart-membership-section');
        if (!section) return;

        const phone = localStorage.getItem('member_phone');
        if (!phone) {
            section.innerHTML = `
                <div class="flex items-center justify-between">
                    <span class="text-coffee-milk font-medium text-[11px]">🎟️ Bạn là thành viên?</span>
                    <a href="member.jsp" class="text-coffee-rust font-bold hover:underline hover:text-coffee-rust/80 text-[11px]">Đăng nhập áp Voucher &rarr;</a>
                </div>
            `;
            selectedVoucherCode = '';
            selectedVoucherDiscount = 0;
            updateCartTotalDisplay();
            return;
        }

        try {
            const res = await fetch(`/api/members/profile?phone=${phone}`);
            if (res.ok) {
                const member = await res.json();
                let html = `
                    <div class="space-y-1.5">
                        <div class="flex justify-between items-center text-[11px]">
                            <span class="text-coffee-dark font-medium flex items-center gap-1">
                                <span class="text-xs">🎟️</span> Hội viên: <strong class="text-coffee-rust">${member.name}</strong>
                            </span>
                            <span class="text-coffee-milk font-mono font-medium">${member.points} hạt 🫘</span>
                        </div>
                `;

                if (!member.vouchers || member.vouchers.length === 0) {
                    html += `
                        <p class="text-[10px] text-coffee-milk italic mt-1">Hội viên chưa có sẵn mã voucher. <a href="member.jsp" class="text-coffee-rust font-bold hover:underline">Vào đổi voucher &rarr;</a></p>
                    `;
                    selectedVoucherCode = '';
                    selectedVoucherDiscount = 0;
                } else {
                    html += `
                        <div class="space-y-1">
                            <label class="text-[9px] font-bold uppercase tracking-wider text-coffee-milk block">Chọn 1 Voucher giảm giá:</label>
                            <select id="guest-cart-voucher-select" onchange="selectVoucherForCart(this.value)" class="w-full bg-white text-xs border border-coffee-sand rounded-lg px-2 py-1 outline-none font-medium cursor-pointer">
                                <option value="">-- Không áp dụng voucher --</option>
                    `;
                    member.vouchers.forEach(vCode => {
                        const vName = vCode === 'CAFE15' ? 'Giảm 15,000đ' : vCode === 'CAFE30' ? 'Giảm 30,000đ' : vCode === 'CAFE50' ? 'Giảm 50,000đ' : 'Giảm 100,000đ';
                        const isSelected = selectedVoucherCode === vCode ? 'selected' : '';
                        html += `<option value="${vCode}" ${isSelected}>Voucher ${vCode} (${vName})</option>`;
                    });
                    html += `
                            </select>
                        </div>
                    `;
                }

                html += `</div>`;
                section.innerHTML = html;
                updateCartTotalDisplay();
            } else {
                localStorage.removeItem('member_phone');
                localStorage.removeItem('member_name');
                drawCartMembershipSection();
            }
        } catch (error) {
            console.error(error);
        }
    }

    function selectVoucherForCart(val) {
        selectedVoucherCode = val;
        if (val === 'CAFE15') selectedVoucherDiscount = 15000;
        else if (val === 'CAFE30') selectedVoucherDiscount = 30000;
        else if (val === 'CAFE50') selectedVoucherDiscount = 50000;
        else if (val === 'CAFE100') selectedVoucherDiscount = 100000;
        else selectedVoucherDiscount = 0;

        updateCartTotalDisplay();
    }

    function updateCartTotalDisplay() {
        let totalVal = 0;
        custCartItems.forEach(c => {
            let singlePrice = c.menuItem.price;
            if (c.customization.size === 'L') singlePrice += 6000;
            else if (c.customization.size === 'S') singlePrice = Math.max(10000, singlePrice - 4000);
            totalVal += singlePrice * c.quantity;
        });

        const payTotal = Math.max(0, totalVal - selectedVoucherDiscount);
        const displayTotal = document.getElementById('guest-cart-total');
        if (displayTotal) {
            if (selectedVoucherDiscount > 0 && totalVal > 0) {
                displayTotal.innerHTML = `
                    <span class="line-through text-coffee-milk text-xs mr-1 font-mono">${formatVND(totalVal)}</span>
                    <span class="font-mono text-coffee-rust">${formatVND(payTotal)}</span>
                `;
            } else {
                displayTotal.innerText = formatVND(totalVal);
            }
        }
    }

    function drawCustCartList() {
        const container = document.getElementById('guest-cart-container');
        const total = document.getElementById('guest-cart-total');
        const sizeBadge = document.getElementById('cart-item-count');

        if (!container) return;
        container.innerHTML = '';

        sizeBadge.innerText = `${custCartItems.length} món`;

        if (custCartItems.length === 0) {
            container.innerHTML = `
                <div class="py-10 text-center text-coffee-milk/60 text-xs">
                    <span class="text-3xl mb-1 text-coffee-sand block">🛒</span>
                    Giỏ hàng rỗng. Hãy chọn đồ uống ngon của bạn!
                </div>
            `;
            total.innerText = '0 ₫';
            selectedVoucherCode = '';
            selectedVoucherDiscount = 0;
            drawCartMembershipSection();
            return;
        }

        let totalValue = 0;
        custCartItems.forEach((c, idx) => {
            let singlePrice = c.menuItem.price;
            if (c.customization.size === 'L') singlePrice += 6000;
            else if (c.customization.size === 'S') singlePrice = Math.max(10000, singlePrice - 4000);

            const itemsVal = singlePrice * c.quantity;
            totalValue += itemsVal;

            const customDetail = c.menuItem.category !== 'Pastry' 
                ? `Size ${c.customization.size} \u2022 Ngọt:${c.customization.sugar} \u2022 Đá:${c.customization.ice}`
                : `Cỡ ${c.customization.size}`;

            container.innerHTML += `
                <div class="bg-coffee-light border border-coffee-sand/60 rounded-2xl p-3 text-xs space-y-1.5 flex flex-col justify-between">
                    <div class="flex justify-between items-start gap-2">
                        <div class="space-y-0.5">
                            <h5 class="font-bold text-coffee-dark">${c.menuItem.name}</h5>
                            <p class="text-[10px] text-coffee-milk font-medium">${customDetail}</p>
                            ${c.notes ? `<p class="text-[9px] text-coffee-rust italic">"${c.notes}"</p>` : ''}
                        </div>
                        <button onclick="removeCustCartItem(${idx})" class="text-coffee-milk hover:text-coffee-rust text-xs shrink-0 p-1 cursor-pointer">
                            🗑️
                        </button>
                    </div>
                    <div class="flex items-center justify-between border-t border-coffee-sand/30 pt-2 mt-1">
                        <span class="font-mono font-bold text-coffee-rust text-xs">${formatVND(itemsVal)}</span>
                        <div class="flex items-center gap-2">
                            <button onclick="updateCustItemQty(${idx}, -1)" class="w-5 h-5 bg-white border border-coffee-sand text-xs flex items-center justify-center rounded font-bold hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">-</button>
                            <span class="font-mono text-xs font-bold">${c.quantity}</span>
                            <button onclick="updateCustItemQty(${idx}, 1)" class="w-5 h-5 bg-white border border-coffee-sand text-xs flex items-center justify-center rounded font-bold hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">+</button>
                        </div>
                    </div>
                </div>
            `;
        });

        drawCartMembershipSection();
    }

    function updateCustItemQty(idx, d) {
        const n = custCartItems[idx].quantity + d;
        if (n > 0) {
            custCartItems[idx].quantity = n;
            drawCustCartList();
        }
    }

    function removeCustCartItem(idx) {
        custCartItems.splice(idx, 1);
        drawCustCartList();
    }

    async function submitGuestTicket() {
        const currentHour = new Date().getHours();
        const hourRestricted = (currentHour >= 22 || currentHour < 6);
        if (shopClosedGlobal || hourRestricted) {
            alert('⚠️ Hệ thống đang tạm ngưng nhận các đơn đặt hàng (quán đóng cửa sau 22h tối hoặc ngưng nhận đơn theo thông báo của quản lý). Qúy khách xin vui lòng quay lại sau!');
            return;
        }

        if (custCartItems.length === 0) {
            alert('Vui lòng chọn ít nhất một thức uống vào giỏ hàng của bạn!');
            return;
        }

        const itemsPayload = custCartItems.map(c => ({
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

        const globalCommStr = document.getElementById('guest-order-notes').value;
        const loggedInPhone = localStorage.getItem('member_phone') || null;

        try {
            const response = await fetch('/api/orders', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    tableId: userSittingTableId,
                    items: itemsPayload,
                    notes: globalCommStr,
                    memberPhone: loggedInPhone,
                    appliedVoucherCode: selectedVoucherCode || null
                })
            });

            if (response.ok) {
                const ticket = await response.json();
                custCartItems = [];
                selectedVoucherCode = '';
                selectedVoucherDiscount = 0;
                document.getElementById('guest-order-notes').value = '';
                drawCustCartList();
                flashNotify(`🎉 Báo gọi món thành công! Đã gửi đơn bàn sô #${ticket.orderNumber}`);
                
                // Track history directly
                drawGuestHistory();
            } else {
                const error = await response.json();
                alert(error.error || 'Xảy ra lỗi khi gửi yêu cầu gọi nước.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    function drawGuestHistory() {
        const label = document.getElementById('history-table-label');
        const box = document.getElementById('guest-history-container');
        const wrapper = document.getElementById('guest-history-card');

        if (!box) return;

        const sitTable = tables.find(t => t.id === userSittingTableId);
        label.innerText = sitTable ? sitTable.name : 'Chưa rõ';

        const rawList = orders.filter(o => o.tableId === userSittingTableId && o.status !== 'Served');

        if (rawList.length === 0) {
            wrapper.classList.add('hidden');
            return;
        }

        wrapper.classList.remove('hidden');
        box.innerHTML = '';

        rawList.forEach(o => {
            let statusBadgeClass = 'bg-coffee-light border-coffee-sand text-coffee-dark';
            if (o.status === 'Preparing') statusBadgeClass = 'bg-amber-100 border-amber-200 text-amber-800';
            else if (o.status === 'Ready') statusBadgeClass = 'bg-emerald-100 border-emerald-250 text-emerald-800 animate-pulse';

            let trackingItemsRows = '';
            o.items.forEach(it => {
                let stLabel = 'Đợi duyệt';
                let stClass = 'text-coffee-milk text-[10px]';

                if (it.status === 'Preparing') {
                    stLabel = 'Đang pha chế 🧑‍🍳';
                    stClass = 'font-bold text-amber-800 text-[10px]';
                } else if (it.status === 'Ready') {
                    stLabel = 'Sẵn sàng ⚡';
                    stClass = 'font-bold text-emerald-800 text-[10px]';
                } else if (it.status === 'Served') {
                    stLabel = 'Đã đưa phục vụ✓';
                    stClass = 'text-coffee-milk line-through text-[10px]';
                }

                trackingItemsRows += `
                    <div class="flex justify-between items-center text-[11px] py-1 border-b border-coffee-sand/15 font-medium">
                        <span>${it.name} <span class="font-mono text-coffee-milk">x${it.quantity}</span></span>
                        <span class="${stClass}">${stLabel}</span>
                    </div>
                `;
            });

            box.innerHTML += `
                <div class="bg-coffee-light border border-coffee-sand/60 p-3 rounded-2xl text-xs space-y-2">
                    <div class="flex justify-between items-center bg-white px-2 py-1 rounded-xl">
                        <span class="font-bold text-coffee-rust">Mã đơn #${o.orderNumber}</span>
                        <span class="text-[9px] uppercase font-mono font-bold px-2 py-0.5 rounded border ${statusBadgeClass}">
                            ${o.status === 'Pending' ? 'Đầu quầy' : o.status === 'Preparing' ? 'Pha chế' : 'Hoàn thành'}
                        </span>
                    </div>
                    <div class="space-y-0.5">
                        ${trackingItemsRows}
                    </div>
                </div>
            `;
        });
    }

    // Begin
    setupWebSocket();
</script>

    </main>

    <!-- ==================== FOOTER SYSTEM INFORMATION ==================== -->
    <footer class="mt-auto py-6 border-t border-coffee-sand/70 bg-white/70 backdrop-blur-xs text-xs text-coffee-milk">
        <div class="max-w-7xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
            <p class="font-serif italic font-bold text-sm text-coffee-dark">
                nhà cà phê © 2026
            </p>
            <div class="flex gap-4 font-mono text-[10px] tracking-wider">
                <span>VER: 3.0.1</span>
            </div>
        </div>
    </footer>

    <!-- GLOBAL TIMEOUT AND TIMEKEEPING -->
    <script>
        // Update nav clock live
        if (document.getElementById('nav-clock')) {
            setInterval(() => {
                document.getElementById('nav-clock').innerText = new Date().toLocaleTimeString('vi-VN');
            }, 1000);
        }

        // Global toast notifier helper
        function flashNotify(msg) {
            const holder = document.getElementById('flash-banner-container');
            const target = document.getElementById('flash-message');
            if (holder && target) {
                target.innerText = msg;
                holder.classList.remove('hidden');
                setTimeout(() => {
                    holder.classList.add('hidden');
                }, 4000);
            }
        }
    </script>
</body>
</html>
