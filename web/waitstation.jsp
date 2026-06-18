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

            if (waiterPages.indexOf(page) !== -1 && role !== 'waiter' && role !== 'manager') {
                try { alert('Cảnh báo bảo mật: Bạn không có quyền truy cập khu vực Phục vụ / Wait Station!'); } catch(e) { console.warn(e); }
                window.location.href = 'login.jsp';
                return;
            }
            if (baristaPages.indexOf(page) !== -1 && role !== 'barista' && role !== 'manager') {
                try { alert('Cảnh báo bảo mật: Bạn không có quyền truy cập khu vực Quầy pha chế (KDS)!'); } catch(e) { console.warn(e); }
                window.location.href = 'login.jsp';
                return;
            }
            if (managerPages.indexOf(page) !== -1 && role !== 'manager') {
                try { alert('Cảnh báo bảo mật: Bạn không có quyền truy cập khu vực Bảng điều khiển Quản lý!'); } catch(e) { console.warn(e); }
                window.location.href = 'login.jsp';
                return;
            }

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

        function handleLocalLogout() {
            localStorage.removeItem('auth_role');
            localStorage.removeItem('auth_user');
            alert('Đã đăng xuất tài khoản làm việc POS! Chuyển hướng về cổng portal.');
            window.location.href = 'index.html';
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
                <a href="waitstation.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Wait Station</a>
                <a href="kds.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Kitchen KDS</a>
                
                <!-- Quick jump selector -->
                <div class="relative group">
                    <button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">
                        <span>Chức năng khác</span>
                        <svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">
                        <a href="dashboard.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">📊 Dashboard panel</a>
                        <a href="reports.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">📈 Báo cáo doanh số</a>
                        <a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">📋 Danh sách Order</a>
                        <a href="staff-management.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🧑‍🤝‍🧑 Quản lý nhân sự</a>
                        <a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🖨️ In mã QR Bàn</a>
                        <a href="member.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🎟️ Khách Thành Viên</a>
                        <a href="order-status.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">🔍 Kiểm tra đơn nước</a>
                    </div>
                </div>
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

<!-- Top-level move/merge warning action bar -->
<div id="transfer-action-banner" class="hidden bg-amber-500 text-white font-bold p-3.5 rounded-2xl flex items-center justify-between text-xs animate-bounce shadow-md mb-4 max-w-4xl mx-auto">
    <div class="flex items-center gap-2">
        <span class="text-lg">🚚</span>
        <span id="transfer-mode-label" class="uppercase">Điêu chuyển vị trí bàn:</span>
        <span class="font-normal">Vui lòng chọn một bàn đích khác trên sơ đồ bên dưới để hoàn tất...</span>
    </div>
    <button onclick="cancelMoveMerge()" class="bg-white/20 hover:bg-white/40 border border-white/30 text-white font-bold px-3 py-1 rounded-lg">
        Huỷ thao tác
    </button>
</div>

<!-- Grid layouts for tables and side inspections -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
    
    <!-- Tables Floor boards: Left Columns -->
    <div class="lg:col-span-2 space-y-4">
        <!-- Zone filters row -->
        <div class="flex items-center justify-between bg-white border border-coffee-sand p-3 rounded-2xl shadow-xs">
            <span class="text-xs font-bold text-coffee-dark px-2 uppercase tracking-wide">Sơ đồ tầng lầu:</span>
            <div id="zone-filter-container" class="flex gap-1 text-[11px] font-bold">
                <button onclick="setZoneFilter('All')" id="tab-zone-all" class="px-3.5 py-1.5 rounded-lg transition-all bg-coffee-rust text-white shadow-xs cursor-pointer">Tất cả</button>
                <button onclick="setZoneFilter('Ground Floor')" id="tab-zone-ground" class="px-3.5 py-1.5 rounded-lg transition-all text-coffee-milk hover:text-coffee-dark cursor-pointer">Trệt</button>
                <button onclick="setZoneFilter('Terrace')" id="tab-zone-terrace" class="px-3.5 py-1.5 rounded-lg transition-all text-coffee-milk hover:text-coffee-dark cursor-pointer">Sân vườn</button>
                <button onclick="setZoneFilter('Upper Floor')" id="tab-zone-upper" class="px-3.5 py-1.5 rounded-lg transition-all text-coffee-milk hover:text-coffee-dark cursor-pointer">Tầng lửng</button>
            </div>
        </div>

        <!-- Desk cards grids -->
        <div id="wait-tables-container" class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
            <!-- Loaded from API -->
        </div>

        <!-- Stable color indicator legends -->
        <div class="flex items-center gap-6 justify-center bg-white p-3 rounded-xl border border-coffee-sand/70 text-[10px] font-bold uppercase text-coffee-milk">
            <div class="flex items-center gap-1.5">
                <span class="w-3 h-3 rounded-md bg-white border border-coffee-sand inline-block"></span>
                <span>Bàn Trống</span>
            </div>
            <div class="flex items-center gap-1.5">
                <span class="w-3 h-3 rounded-md bg-amber-100 border border-amber-200 inline-block"></span>
                <span>Đang Phục Vụ</span>
            </div>
            <div class="flex items-center gap-1.5">
                <span class="w-3 h-3 rounded-md bg-emerald-100 border border-emerald-300 inline-block animate-pulse"></span>
                <span>Pha Xong (Trực trà)</span>
            </div>
            <div class="flex items-center gap-1.5 font-bold text-rose-800">
                <span class="w-3 h-3 rounded-md bg-rose-100 border border-rose-250 inline-block animate-pulse"></span>
                <span>Chờ dọn bàn</span>
            </div>
        </div>
    </div>

    <!-- Active billing inspecting drawer: Right Column -->
    <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs lg:sticky lg:top-24 max-h-[75vh] flex flex-col justify-between overflow-hidden">
        
        <!-- Inspection placeholders when nothing is active -->
        <div id="wait-placeholder" class="py-16 text-center text-coffee-milk space-y-2">
            <span class="text-4xl text-coffee-sand">📋</span>
            <h4 class="font-serif italic font-bold text-coffee-dark text-base">Chưa chọn bàn phục vụ</h4>
            <p class="text-xs">Bấm chọn một bàn bất kỳ trên sơ đồ để xem thông tin hóa đơn, gọi nước bổ sung, đổi bàn hoặc dọn dẹp kết hóa đơn.</p>
        </div>

        <!-- Active details -->
        <div id="wait-active" class="hidden h-full flex flex-col justify-between overflow-hidden space-y-4">
            <!-- Populated from Javascript on table selected -->
        </div>

    </div>

</div>

<!-- SUPPLEMENTARY GUEST ORDER PLACEMENT DRAWER -->
<div id="order-placement-drawer" class="fixed inset-0 bg-coffee-dark/40 z-50 flex justify-end hidden opacity-0 transition-all duration-300">
    <div class="w-full max-w-lg bg-coffee-bg h-full flex flex-col shadow-2xl p-6 transition-all transform translate-x-full">
        
        <div class="flex items-center justify-between border-b border-coffee-sand pb-4">
            <div>
                <h3 class="text-lg font-serif italic font-bold text-coffee-dark" id="drawer-title">Thêm đồ uống bổ sung</h3>
                <p class="text-xs text-coffee-milk">Gọi món tại quầy cho bàn khách hàng đang phục vụ</p>
            </div>
            <button onclick="closeOrderDrawer()" class="p-2 hover:bg-coffee-sand/30 rounded-xl text-coffee-dark transition-colors cursor-pointer text-sm">
                ✕ Đóng
            </button>
        </div>

        <div class="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 overflow-hidden">
            
            <!-- catalog (Left) -->
            <div class="flex flex-col h-full overflow-hidden border-r border-coffee-sand/50 pr-2">
                <div class="space-y-2 mb-2">
                    <div class="flex flex-wrap gap-1" id="drawer-categories-holder">
                        <!-- Filled statically -->
                    </div>
                    <input type="text" id="drawer-search-input" oninput="drawDrawerMenuList()" placeholder="Tìm đồ uống..." class="w-full text-xs px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                </div>

                <div id="drawer-menu-container" class="flex-1 overflow-y-auto space-y-2.5">
                    <!-- Cards -->
                </div>
            </div>

            <!-- compile ticket (Right) -->
            <div class="flex flex-col h-full overflow-hidden">
                <h4 class="text-[10px] uppercase font-bold tracking-wider text-coffee-rust border-b border-coffee-sand pb-2 mb-2">Gọi món bổ sung</h4>
                
                <div id="drawer-cart-container" class="flex-1 overflow-y-auto space-y-3 pr-1">
                    <!-- Items -->
                </div>

                <div class="border-t border-coffee-sand pt-3 mt-2 space-y-2.5">
                    <div>
                        <label class="text-[9px] font-bold uppercase text-coffee-milk block mb-1">Ghi chú gửi bếp</label>
                        <textarea id="drawer-order-notes" placeholder="Mỗi ý phụ cách bằng gạch chéo..." class="w-full text-[11px] px-3 py-1.5 bg-white border border-coffee-sand rounded-xl h-12 focus:outline-none focus:border-coffee-rust"></textarea>
                    </div>

                    <div class="bg-coffee-light rounded-xl p-3 flex justify-between items-center text-xs border border-coffee-sand/50">
                        <span class="font-bold">Tổng thanh toán:</span>
                        <span class="font-mono font-bold text-sm text-coffee-rust" id="drawer-cart-total">0 ₫</span>
                    </div>

                    <button id="submit-ticket-btn" onclick="submitTicket()" class="w-full bg-coffee-rust text-white font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all flex justify-center items-center gap-1.5 shadow-sm cursor-pointer">
                        Xác nhận gọi món 📋
                    </button>
                </div>
            </div>

        </div>

    </div>
</div>

<!-- Checkout Confirmation Modal Overlay -->
<div id="checkout-modal" class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
    <div class="bg-white border-2 border-coffee-sand rounded-3xl max-w-sm w-full p-6 shadow-2xl space-y-4 animate-fade-in">
        <div class="flex justify-between items-center border-b border-coffee-sand/50 pb-3">
            <h4 class="font-serif italic font-bold text-base text-coffee-dark flex items-center gap-2">
                <span>💸</span> Xác nhận Thu tiền POS
            </h4>
            <button onclick="closeCheckoutModal()" class="text-coffee-milk hover:text-coffee-rust text-xs font-bold font-mono">✕ Hủy</button>
        </div>
        
        <div class="bg-coffee-light rounded-2xl p-4 border border-coffee-sand/70 space-y-3">
            <div class="flex justify-between text-xs font-mono">
                <span class="font-bold text-coffee-milk">VỊ TRÍ BÀN:</span>
                <span id="chk-table-name" class="font-bold text-coffee-dark font-sans">-</span>
            </div>
            <div class="flex justify-between text-xs font-mono">
                <span class="font-bold text-coffee-milk">HÓA ĐƠN:</span>
                <span id="chk-order-number" class="text-coffee-rust font-bold font-sans">-</span>
            </div>
            <div class="border-t border-coffee-sand/30 pt-2 space-y-1.5 text-xs">
                <div class="flex justify-between">
                    <span class="text-coffee-milk">Giá trị gốc:</span>
                    <span id="chk-base-sum" class="font-mono text-coffee-dark">-</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-coffee-milk">Thuế VAT (8%):</span>
                    <span id="chk-tax-sum" class="font-mono text-coffee-dark">-</span>
                </div>
                <div class="flex justify-between text-sm font-bold border-t border-coffee-sand/50 pt-1.5 text-coffee-rust font-mono">
                    <span>TỔNG THU:</span>
                    <span id="chk-grand-total">-</span>
                </div>
            </div>
        </div>

        <div class="space-y-2">
            <label class="text-[9px] font-bold uppercase tracking-wider text-coffee-milk font-mono block">Hình thức thanh toán</label>
            <div class="grid grid-cols-3 gap-2" id="chk-methods-grid">
                <button onclick="setCheckoutMethod('Cash')" id="chk-method-cash" class="py-2 bg-coffee-rust text-white rounded-xl text-[10px] font-bold border border-coffee-rust transition-all flex flex-col items-center justify-center cursor-pointer">
                    <span>💵 Tiền mặt</span>
                </button>
                <button onclick="setCheckoutMethod('VietQR')" id="chk-method-vietqr" class="py-2 bg-white text-coffee-dark hover:bg-coffee-light border border-coffee-sand rounded-xl text-[10px] font-bold transition-all flex flex-col items-center justify-center cursor-pointer">
                    <span>📐 VietQR</span>
                </button>
                <button onclick="setCheckoutMethod('Card')" id="chk-method-card" class="py-2 bg-white text-coffee-dark hover:bg-coffee-light border border-coffee-sand rounded-xl text-[10px] font-bold transition-all flex flex-col items-center justify-center cursor-pointer">
                    <span>💳 Quẹt thẻ</span>
                </button>
            </div>
        </div>

        <div class="pt-1.5 flex gap-2">
            <button onclick="closeCheckoutModal()" class="flex-1 bg-white hover:bg-coffee-light border border-coffee-sand text-coffee-dark py-2 rounded-xl text-xs font-bold transition-colors cursor-pointer">
                Hủy bỏ
            </button>
            <button onclick="submitCheckoutPayment()" class="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white py-2 rounded-xl text-xs font-bold uppercase tracking-wide transition-all cursor-pointer shadow-3xs">
                Thu xong ✓
            </button>
        </div>
    </div>
</div>

<!-- Serve Item Verification Modal Overlay -->
<div id="serve-confirm-modal" class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
    <div class="bg-white border-2 border-coffee-sand rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4 animate-fade-in text-coffee-dark">
        <div class="flex justify-between items-center border-b border-coffee-sand/50 pb-3">
            <h4 class="font-serif italic font-bold text-base text-coffee-dark flex items-center gap-2">
                <span>🛎️</span> Xác thực phục vụ đúng bàn
            </h4>
            <button onclick="closeServeConfirmationModal()" class="text-coffee-milk hover:text-coffee-rust text-xs font-bold font-mono">✕ Đóng</button>
        </div>
        
        <!-- Order details panel -->
        <div class="bg-amber-50/50 border border-amber-200 rounded-2xl p-4 space-y-3">
            <div class="flex justify-between items-center text-xs">
                <span class="text-amber-800 font-bold uppercase tracking-wider font-mono">Món nước cần giao:</span>
                <span id="serve-item-qty" class="bg-coffee-rust text-white font-bold px-2 py-0.5 rounded-full text-[10px] font-mono">x1</span>
            </div>
            <div class="text-sm font-bold text-coffee-dark" id="serve-item-name">Traditional Black Coffee</div>
            <div class="border-t border-coffee-sand/30 pt-2 flex justify-between items-center text-xs">
                <span class="text-coffee-milk font-semibold">BÀN ĐÍCH ĐÚNG CỦA KHÁCH:</span>
                <span class="font-bold text-coffee-rust text-sm font-sans" id="serve-target-table-name">Table 1</span>
            </div>
        </div>

        <!-- Verification Steps -->
        <div class="space-y-3">
            <div class="text-xs text-coffee-milk font-medium flex items-center gap-1.5">
                <span class="w-5 h-5 rounded-full bg-coffee-rust text-white flex items-center justify-center text-[10px] font-bold">1</span>
                <span>CHỌN BÀN BẠN ĐANG ĐỨNG PHỤC VỤ TRỰC TIẾP:</span>
            </div>
            
            <div id="verification-tables-grid" class="grid grid-cols-4 gap-2 max-h-[160px] overflow-y-auto p-1 bg-coffee-light rounded-2xl border border-coffee-sand/60">
                <!-- Tables grid goes here -->
            </div>
        </div>

        <!-- Message Alert Area -->
        <div id="verification-alert-area" class="hidden p-3 rounded-2xl text-xs flex items-center gap-2.5 transition-all">
            <!-- Warning/Success message will go here dynamically -->
        </div>

        <div class="pt-2 flex gap-2">
            <button onclick="closeServeConfirmationModal()" class="flex-1 bg-white hover:bg-coffee-light border border-coffee-sand text-coffee-dark py-2.5 rounded-xl text-xs font-bold transition-colors cursor-pointer">
                Hủy bỏ
            </button>
            <button id="btn-submit-serve-verification" disabled onclick="submitServeVerification()" class="flex-1 bg-gray-250 text-gray-400 cursor-not-allowed py-2.5 rounded-xl text-xs font-bold uppercase tracking-wide transition-all shadow-3xs">
                Xác nhận lên đúng bàn ✓
            </button>
        </div>
    </div>
</div>

<script>
    let menu = [];
    let tables = [];
    let orders = [];
    let socket = null;

    let selectedZone = 'All';
    let selectedTableId = null;

    let cartItems = [];
    let drawerCategory = 'All';

    let transferState = {
        mode: null,
        sourceTableId: null
    };

    let checkoutTableId = null;
    let checkoutPaymentMethod = 'Cash';

    function openCheckoutModal(tableId) {
        checkoutTableId = tableId;
        checkoutPaymentMethod = 'Cash';
        setCheckoutMethod('Cash');

        const table = tables.find(t => t.id === tableId);
        const activeOrder = orders.find(o => o.tableId === tableId && o.status !== 'Served');

        if (!table || !activeOrder) {
            alert('Bàn này hiện tại không có hoá đơn nào chưa thanh toán.');
            return;
        }

        document.getElementById('chk-table-name').innerText = table.name;
        document.getElementById('chk-order-number').innerText = '#' + activeOrder.orderNumber;

        let baseSum = 0;
        activeOrder.items.forEach(it => {
            let singlePrice = it.price;
            const sizeChar = it.customization ? it.customization.size : 'M';
            if (sizeChar === 'L') singlePrice += 6000;
            else if (sizeChar === 'S') singlePrice = Math.max(10000, singlePrice - 4000);
            baseSum += singlePrice * it.quantity;
        });

        const taxVal = Math.round(baseSum * 0.08);
        const grandTotal = baseSum + taxVal;

        document.getElementById('chk-base-sum').innerText = formatVND(baseSum);
        document.getElementById('chk-tax-sum').innerText = formatVND(taxVal);
        document.getElementById('chk-grand-total').innerText = formatVND(grandTotal);

        document.getElementById('checkout-modal').classList.remove('hidden');
    }

    function closeCheckoutModal() {
        document.getElementById('checkout-modal').classList.add('hidden');
        checkoutTableId = null;
    }

    function setCheckoutMethod(method) {
        checkoutPaymentMethod = method;
        const methods = ['Cash', 'VietQR', 'Card'];
        methods.forEach(m => {
            const btn = document.getElementById('chk-method-' + m.toLowerCase());
            if (m === method) {
                btn.className = "py-2 bg-coffee-rust text-white rounded-xl text-[10px] font-bold border border-coffee-rust transition-all flex flex-col items-center justify-center cursor-pointer";
            } else {
                btn.className = "py-2 bg-white text-coffee-dark hover:bg-coffee-light border border-coffee-sand rounded-xl text-[10px] font-bold transition-all flex flex-col items-center justify-center cursor-pointer";
            }
        });
    }

    async function submitCheckoutPayment() {
        if (!checkoutTableId) return;
        
        try {
            const resp = await fetch(`/api/tables/${checkoutTableId}/checkout`, { method: 'POST' });
            if (resp.ok) {
                const methodLabel = checkoutPaymentMethod === 'Cash' ? 'Tiền mặt' : checkoutPaymentMethod === 'VietQR' ? 'Chuyển khoản VietQR' : 'Quẹt thẻ';
                const msg = `💸 Thu tiền qua [${methodLabel}] dọn dẹp bàn thành công!`;
                alert(msg);
                flashNotify(msg);
                closeCheckoutModal();
                selectedTableId = null;
                fetchStateCore();
            } else {
                alert('Có lỗi xảy ra trong quá trình thanh toán.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    function formatVND(amt) {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amt);
    }

    let serveState = {
        orderId: null,
        itemId: null,
        itemName: null,
        itemQty: null,
        correctTableId: null,
        correctTableName: null,
        selectedVerificationTableId: null
    };

    function openServeConfirmationModal(orderId, itemId, itemName, itemQty, correctTableId, correctTableName) {
        serveState.orderId = orderId;
        serveState.itemId = itemId;
        serveState.itemName = itemName;
        serveState.itemQty = itemQty;
        serveState.correctTableId = correctTableId;
        serveState.correctTableName = correctTableName;
        serveState.selectedVerificationTableId = null;

        document.getElementById('serve-item-name').innerText = itemName;
        document.getElementById('serve-item-qty').innerText = 'x' + itemQty;
        document.getElementById('serve-target-table-name').innerText = correctTableName;

        const alertContainer = document.getElementById('verification-alert-area');
        alertContainer.classList.add('hidden');
        alertContainer.className = "hidden p-3 rounded-2xl text-xs flex items-center gap-2.5 transition-all";
        alertContainer.innerHTML = "";

        const submitBtn = document.getElementById('btn-submit-serve-verification');
        submitBtn.disabled = true;
        submitBtn.className = "flex-1 bg-gray-200 text-gray-400 cursor-not-allowed py-2.5 rounded-xl text-xs font-bold uppercase tracking-wide transition-all shadow-3xs";

        drawVerificationTables();

        document.getElementById('serve-confirm-modal').classList.remove('hidden');
    }

    function closeServeConfirmationModal() {
        document.getElementById('serve-confirm-modal').classList.add('hidden');
    }

    function selectVerificationTable(tableId) {
        serveState.selectedVerificationTableId = tableId;
        drawVerificationTables();

        const alertContainer = document.getElementById('verification-alert-area');
        alertContainer.classList.remove('hidden');

        const isCorrect = (tableId === serveState.correctTableId);
        const submitBtn = document.getElementById('btn-submit-serve-verification');

        if (isCorrect) {
            alertContainer.className = "p-3 rounded-2xl text-xs flex items-center gap-2.5 bg-emerald-50 border border-emerald-200 text-emerald-800 animate-fade-in";
            alertContainer.innerHTML = `
                <span class="text-base">✓</span>
                <div>
                    <strong class="block">HOÀN TOÀN CHÍNH XÁC!</strong>
                    <span>Bạn đã định vị đúng bàn phục vụ <strong>${serveState.correctTableName}</strong>. Bấm nút bên dưới để lên đồ!</span>
                </div>
            `;
            submitBtn.disabled = false;
            submitBtn.className = "flex-1 bg-emerald-600 hover:bg-emerald-700 text-white py-2.5 rounded-xl text-xs font-bold uppercase tracking-wide transition-all cursor-pointer shadow-3xs";
        } else {
            const selectedTable = tables.find(t => t.id === tableId);
            const selectedName = selectedTable ? selectedTable.name : 'bàn khác';
            alertContainer.className = "p-3 rounded-2xl text-xs flex items-center gap-2.5 bg-rose-50 border border-rose-200 text-rose-800 animate-pulse";
            alertContainer.innerHTML = `
                <span class="text-base">⚠️</span>
                <div>
                    <strong class="block">CẢNH BÁO SAI BÀN!</strong>
                    <span>Món này thuộc về khách ở <strong>${serveState.correctTableName}</strong>, không phải bàn <strong>${selectedName}</strong> bạn vừa chọn! Hãy đem món đến đúng bàn của khách hàng.</span>
                </div>
            `;
            submitBtn.disabled = true;
            submitBtn.className = "flex-1 bg-gray-250 text-gray-400 cursor-not-allowed py-2.5 rounded-xl text-xs font-bold uppercase tracking-wide transition-all shadow-3xs";
        }
    }

    async function submitServeVerification() {
        if (!serveState.orderId || !serveState.itemId || serveState.selectedVerificationTableId !== serveState.correctTableId) {
            return;
        }

        try {
            const response = await fetch(`/api/orders/${serveState.orderId}/items/${serveState.itemId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: 'Served' })
            });

            if (response.ok) {
                flashNotify(`🛎️ Đã phục vụ thành công: ${serveState.itemName} x${serveState.itemQty} lên đúng ${serveState.correctTableName} ✓`);
                closeServeConfirmationModal();
                fetchStateCore();
            } else {
                alert('Có lỗi xảy ra khi cập nhật trạng thái món nước.');
            }
        } catch (err) {
            console.error('Lỗi khi xác nhận dọn đồ:', err);
        }
    }

    function drawVerificationTables() {
        const container = document.getElementById('verification-tables-grid');
        if (!container) return;
        container.innerHTML = '';
        
        tables.forEach(t => {
            if (t.hidden) return;
            
            let btnClass = 'border border-coffee-sand bg-white text-coffee-dark hover:bg-coffee-light';
            if (serveState.selectedVerificationTableId === t.id) {
                if (t.id === serveState.correctTableId) {
                    btnClass = 'border-2 border-emerald-500 bg-emerald-50 text-emerald-800 font-bold shadow-sm scale-105';
                } else {
                    btnClass = 'border-2 border-rose-500 bg-rose-50 text-rose-800 font-bold shadow-sm';
                }
            } else if (t.id === serveState.correctTableId && serveState.selectedVerificationTableId !== null) {
                btnClass = 'border border-emerald-300 bg-emerald-50/20 text-emerald-700 font-semibold';
            }
            
            const tblZoneName = t.zone === 'Ground Floor' ? 'Khu Trệt' : t.zone === 'Terrace' ? 'Sân vườn' : 'Khu lửng';
            container.innerHTML += `
                <button onclick="selectVerificationTable('${t.id}')" class="p-2 py-2.5 rounded-xl text-center text-xs transition-all cursor-pointer ${btnClass}">
                    <div class="font-sans font-bold text-nowrap">${t.name}</div>
                    <div class="text-[8px] opacity-75 font-mono">${tblZoneName}</div>
                </button>
            `;
        });
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
            console.error('Waitstation state fetch error', err);
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
            flashNotify('🔄 Đã nhận thông báo dọn món/gọi món mới trực tiếp!');
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
                <div class="bg-emerald-50 text-emerald-800 border border-emerald-250/60 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold animate-pulse">
                    <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full"></span>
                    <span>Wait station trực tuyến</span>
                </div>
            `;
        } else {
            indicator.innerHTML = `
                <div class="bg-red-50 text-red-800 border border-red-200/60 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold">
                    <span class="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
                    <span>Ngoại tuyến floor map</span>
                </div>
            `;
        }
    }

    function setZoneFilter(z) {
        selectedZone = z;
        ['All', 'Ground Floor', 'Terrace', 'Upper Floor'].forEach(item => {
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

    function drawWaiterTables() {
        const target = document.getElementById('wait-tables-container');
        if (!target) return;
        target.innerHTML = '';

        const activeList = tables.filter(t => !t.hidden && (selectedZone === 'All' || t.zone === selectedZone));

        activeList.forEach(table => {
            const isSel = selectedTableId === table.id;
            const isSrc = transferState.sourceTableId === table.id;

            let colorStyles = 'border-coffee-sand bg-white text-coffee-dark hover:border-coffee-rust/50';
            let statusLabel = 'Bàn Trống';
            let statusBadge = 'bg-coffee-light text-coffee-milk border border-coffee-sand/50';

            if (table.status === 'serving') {
                colorStyles = 'border-coffee-sand bg-[#FDFBF7] hover:shadow-xs';
                statusBadge = 'bg-amber-100 text-amber-800 border-amber-250';
                statusLabel = 'Khách ngồi';
            } else if (table.status === 'ready_to_serve') {
                colorStyles = 'border-emerald-500 bg-emerald-50/15 text-coffee-dark shadow-xs outline outline-2 outline-emerald-400/20 animate-pulse';
                statusBadge = 'bg-emerald-100 text-emerald-800 border-emerald-300';
                statusLabel = 'Trực trà ⚡';
            } else if (table.status === 'served_confirm') {
                colorStyles = 'border-amber-550 bg-amber-50/15 text-coffee-dark shadow-xs outline outline-2 outline-amber-400/30 animate-pulse';
                statusBadge = 'bg-amber-500 text-white border-amber-600';
                statusLabel = 'XN Phục Vụ 🍽️';
            } else if (table.status === 'dirty') {
                colorStyles = 'border-rose-350 bg-rose-50/10 text-coffee-dark shadow-3xs hover:border-rose-450';
                statusBadge = 'bg-rose-100 text-rose-800 border-rose-250 animate-pulse';
                statusLabel = 'Cần dọn 🧹';
            }

            if (isSel) {
                colorStyles += ' ring-2 ring-coffee-rust border-transparent shadow-md transform -translate-y-0.5';
            }
            if (isSrc) {
                colorStyles += ' border-amber-400 bg-amber-50 ring-2 ring-amber-450';
            }

            const zoneLabel = table.zone === 'Ground Floor' ? 'Khu Trệt' : table.zone === 'Terrace' ? 'Sân Vườn' : 'Khu Lửng';

            target.innerHTML += `
                <div onclick="selectWaiterTable('${table.id}')" class="border rounded-2xl p-4 flex flex-col justify-between h-40 transition-all duration-150 cursor-pointer ${colorStyles}">
                    <div>
                        <span class="text-[9px] uppercase font-bold tracking-wider opacity-60 font-mono">${zoneLabel}</span>
                        <h4 class="font-serif font-bold italic text-base leading-tight mt-0.5 text-coffee-dark">${table.name}</h4>
                    </div>
                    
                    <div class="flex items-center justify-between text-xs mt-3">
                        <span class="text-[11px] text-coffee-milk font-mono font-medium">
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
                alert('Không thể chuyển hoá đơn bàn sang chính cùng vị trí bàn!');
                return;
            }

            const src = tables.find(t => t.id === transferState.sourceTableId);
            const dest = tables.find(t => t.id === tableId);

            if (transferState.mode === 'move') {
                if (dest.status !== 'empty') {
                    alert('Bàn cần chuyển tới phải còn trống!');
                    return;
                }
                if (dest.capacity < src.capacity) {
                    alert('Đổi bàn thất bại: Số ghế của bàn mới phải nhiều hơn hoặc bằng bàn cũ!');
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
        let orderObj = orders.find(o => o.tableId === selectedTableId && o.status !== 'Served');
        let isPastOrder = false;

        if (!orderObj && (table.status === 'dirty' || table.status === 'served_confirm')) {
            const tableOrders = orders.filter(o => o.tableId === selectedTableId && o.status === 'Served');
            if (tableOrders.length > 0) {
                orderObj = tableOrders[tableOrders.length - 1];
                isPastOrder = true;
            }
        }

        let checklistHtml = '';
        if (orderObj && orderObj.items.length > 0) {
            orderObj.items.forEach(it => {
                let badgeClass = 'bg-coffee-light border border-coffee-sand/30';
                if (it.status === 'Preparing') badgeClass = 'bg-amber-100 text-amber-800 border-amber-200';
                else if (it.status === 'Ready') badgeClass = 'bg-emerald-100 text-emerald-800 border-emerald-300 animate-pulse';
                else if (it.status === 'Served') badgeClass = 'bg-coffee-rust/10 text-coffee-rust border-transparent';

                const vietnameseItemStatus = it.status === 'Pending' ? 'Chờ quầy' : it.status === 'Preparing' ? 'Pha chế' : it.status === 'Ready' ? 'Dọn' : 'Đã dọn';

                let actionBtnHtml = '';
                if (it.status !== 'Served' && !isPastOrder) {
                    const isReady = it.status === 'Ready';
                    const btnStyle = isReady 
                        ? 'bg-emerald-600 hover:bg-emerald-700 text-white font-bold animate-pulse' 
                        : 'bg-coffee-rust/80 hover:bg-coffee-rust text-white';
                    
                    actionBtnHtml = `
                        <button onclick="openServeConfirmationModal('${orderObj.id}', '${it.id}', '${it.name.replace(/'/g, "\\'")}', ${it.quantity}, '${table.id}', '${table.name}')" 
                                class="text-[10px] font-semibold px-2 py-1 rounded-lg transition-all cursor-pointer flex items-center gap-1 shadow-3xs hover:scale-105 ${btnStyle}">
                            🛎️ Giao món
                        </button>
                    `;
                }

                checklistHtml += `
                    <div class="flex justify-between items-center bg-white border border-coffee-sand/70 rounded-xl px-2.5 py-1.5 text-xs font-medium">
                        <div class="space-y-0.5">
                            <p class="font-bold text-coffee-dark">${it.name} <span class="font-mono text-coffee-rust">x${it.quantity}</span></p>
                            <p class="text-[9.5px] text-coffee-milk">Sz: ${it.customization ? it.customization.size : 'M'} \u2022 Đ:${it.customization ? it.customization.sugar : '100%'} \u2022 Đá:${it.customization ? it.customization.ice : '105%'}</p>
                            ${it.notes ? `<p class="text-[9px] text-coffee-rust italic">"${it.notes}"</p>` : ''}
                        </div>
                        <div class="flex flex-col items-end gap-1.5">
                            <span class="text-[8.5px] font-mono uppercase font-bold px-1.5 py-0.5 rounded-full ${badgeClass}">
                                ${vietnameseItemStatus}
                            </span>
                            ${actionBtnHtml}
                        </div>
                    </div>
                `;
            });
        } else {
            checklistHtml = `
                <div class="text-center py-6 text-xs text-coffee-milk italic bg-coffee-light rounded-xl border border-coffee-sand/65">
                    Không tìm thấy thức uống nào đang phục vụ trên bàn này.
                </div>
            `;
        }

        const tblZoneVi = table.zone === 'Ground Floor' ? 'Tầng trệt' : table.zone === 'Terrace' ? 'Sân vườn' : 'Khu lững';

        act.innerHTML = `
            <div class="h-full flex flex-col justify-between overflow-hidden gap-4">
                <div class="overflow-y-auto space-y-4 pr-1">
                    <div class="flex justify-between items-center border-b border-coffee-sand/70 pb-2.5">
                        <div>
                            <span class="text-[9px] uppercase font-bold tracking-wider text-coffee-milk font-mono">${tblZoneVi}</span>
                            <h3 class="font-serif italic font-bold text-lg text-coffee-dark leading-tight">${table.name}</h3>
                        </div>
                        <span class="text-xs font-bold font-mono bg-coffee-light border border-coffee-sand text-coffee-dark px-2.5 py-1 rounded-lg">
                            Tổng ghế: ${table.capacity}
                        </span>
                    </div>

                    ${orderObj ? `
                        <div class="bg-coffee-light border border-coffee-sand/65 rounded-xl p-3 text-[11px] space-y-1 text-coffee-dark">
                            <div class="flex justify-between font-mono">
                                <span class="text-coffee-milk">ID VẬN ĐƠN</span>
                                <span class="font-bold text-coffee-dark">#${orderObj.orderNumber}</span>
                            </div>
                            <div class="flex justify-between font-mono">
                                <span class="text-coffee-milk">TRẠNG THÁI</span>
                                <span class="font-bold text-coffee-rust uppercase">${table.status === 'served_confirm' ? 'HOÀN TẤT (CHỜ XÁC NHẬN PHỤC VỤ)' : isPastOrder ? 'ĐÃ PHỤC VỤ (CHỜ DỌN)' : (orderObj.status === 'Pending' ? 'Chờ quầy' : orderObj.status === 'Preparing' ? 'Pha chế' : 'Sẵn sàng')}</span>
                            </div>
                        </div>
                    ` : ''}

                    <div class="space-y-1.5">
                        <h5 class="text-[9px] uppercase font-bold tracking-wider text-coffee-milk font-mono">DANH MỤC THỨC UỐNG ĐẶT GỌI</h5>
                        <div class="space-y-1.5 max-h-[170px] overflow-y-auto">
                            ${checklistHtml}
                        </div>
                    </div>
                </div>

                <!-- Control Buttons -->
                <div class="border-t border-coffee-sand/70 pt-3 space-y-2.5">
                    ${orderObj && !isPastOrder ? `
                    <div class="grid grid-cols-2 gap-2">
                        <button onclick="triggerTransfer('move')" class="bg-white border border-coffee-sand hover:bg-coffee-rust/5 text-coffee-dark hover:border-coffee-rust text-xs py-2 rounded-xl flex items-center justify-center gap-1.5 font-bold transition-all cursor-pointer">
                            🚚 Đổi bàn
                        </button>
                        <button onclick="triggerTransfer('merge')" class="bg-white border border-coffee-sand hover:bg-coffee-rust/5 text-coffee-dark hover:border-coffee-rust text-xs py-2 rounded-xl flex items-center justify-center gap-1.5 font-bold transition-all cursor-pointer">
                            🔗 Gộp bàn
                        </button>
                    </div>
                    ` : ''}

                    ${orderObj && !isPastOrder ? `
                        <div class="bg-coffee-light border border-coffee-sand/80 px-3 py-2 rounded-xl flex justify-between items-center text-xs">
                            <span class="font-bold text-coffee-milk">Hóa đơn bàn:</span>
                            <span class="font-mono font-bold text-xs text-coffee-rust">${formatVND(orderObj.totalAmount)}</span>
                        </div>
                        <div class="grid grid-cols-2 gap-2">
                            <button onclick="openStaffOrderDrawer()" class="bg-[#FAF7EE] border border-coffee-sand hover:border-coffee-rust text-xs py-2.5 rounded-xl font-bold transition-all cursor-pointer">
                                ＋ Gọi thêm món
                            </button>
                            <a href="order-summary.jsp?tableId=${table.id}" class="bg-white border border-coffee-sand hover:border-coffee-rust text-coffee-dark text-xs py-2.5 rounded-xl font-bold transition-all text-center flex items-center justify-center gap-1 cursor-pointer">
                                📄 In Hoá Đơn
                            </a>
                        </div>
                        <div class="pt-0.5">
                            <button onclick="openCheckoutModal('${table.id}')" class="w-full bg-emerald-600 hover:bg-emerald-700 text-white text-xs py-2.5 rounded-xl font-bold transition-all text-center flex items-center justify-center gap-1.5 cursor-pointer shadow-3xs uppercase tracking-wider">
                                💸 Xác nhận thu tiền nhanh
                            </button>
                        </div>
                    ` : `
                        ${table.status === 'served_confirm' ? `
                            <button onclick="confirmServedCorrectTable('${table.id}')" class="w-full bg-amber-500 hover:bg-amber-600 text-white py-3.5 rounded-xl font-bold text-xs uppercase tracking-wider transition-all cursor-pointer flex items-center justify-center gap-2 shadow-sm animate-pulse">
                                🍽️ Xác nhận đã phục vụ đúng bàn
                            </button>
                        ` : table.status === 'dirty' ? `
                            <button onclick="cleanTable('${table.id}')" class="w-full bg-emerald-600 hover:bg-emerald-700 text-white py-3.5 rounded-xl font-bold text-xs uppercase tracking-wider transition-all cursor-pointer flex items-center justify-center gap-2 shadow-sm">
                                🧹 Xác nhận đã dọn bàn xong
                            </button>
                        ` : `
                            <button onclick="openStaffOrderDrawer()" class="w-full bg-coffee-rust text-white hover:bg-coffee-rust/95 py-3 rounded-xl font-bold text-xs uppercase tracking-wider transition-all cursor-pointer">
                                ＋ Đặt gọi món phục vụ mới
                            </button>
                        `}
                    `}
                </div>
            </div>
        `;
    }

    function triggerTransfer(mode) {
        if (!selectedTableId) return;
        transferState.mode = mode;
        transferState.sourceTableId = selectedTableId;

        document.getElementById('transfer-mode-label').innerText = mode === 'move' ? 'Điều chuyển vị trí:' : 'Gộp hóa đơn nhóm:';
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
                flashNotify('🚚 Đã điều phối chuyển bàn tiệc thành công!');
            } else {
                const error = await response.json();
                alert(error.error || 'Yêu cầu chuyển đổi bị hệ thống bác bỏ.');
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
                flashNotify('🔗 Gộp hóa đơn và dọn kèm bàn thành công!');
            } else {
                const error = await response.json();
                alert(error.error || 'Yêu cầu gộp hoá đơn bị từ chối.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    async function confirmServedCorrectTable(tableId) {
        try {
            const response = await fetch(`/api/tables/${tableId}/confirm-served`, {
                method: 'POST'
            });
            if (response.ok) {
                flashNotify('🍽️ Đã xác nhận giao đúng đồ uống lên bàn! Trạng thái chuyển sang Cần dọn 🧹');
                fetchStateCore();
            } else {
                alert('Có lỗi khi xác nhận phục vụ.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    async function cleanTable(tableId) {
        try {
            const response = await fetch(`/api/tables/${tableId}/clean`, {
                method: 'POST'
            });
            if (response.ok) {
                flashNotify('🧹 Bàn đã được dọn sạch dẹp trống sẵn sàng đón khách mới!');
                selectedTableId = null;
                fetchStateCore();
            } else {
                alert('Có lỗi khi dọn bàn.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    // Supplementary drawer functions
    function openStaffOrderDrawer() {
        const table = tables.find(t => t.id === selectedTableId);
        document.getElementById('drawer-title').innerText = `Gọi món mới - ${table.name}`;
        
        cartItems = [];
        document.getElementById('drawer-order-notes').value = '';

        const catHolder = document.getElementById('drawer-categories-holder');
        catHolder.innerHTML = '';
        ['All', 'Coffee', 'Tea', 'Specialty', 'Pastry'].forEach(item => {
            const isSel = drawerCategory === item;
            const viewName = item === 'All' ? 'Tất cả' : item === 'Coffee' ? 'Cà phê' : item === 'Tea' ? 'Trà phin' : item === 'Specialty' ? 'Đặc sản' : 'Bánh';
            catHolder.innerHTML += `
                <button onclick="setDrawerCategory('${item}')" class="text-[10px] font-bold px-2 py-1 rounded-md border transition-all cursor-pointer ${isSel ? 'bg-coffee-rust text-white border-transparent' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    ${viewName}
                </button>
            `;
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

    function closeOrderDrawer() {
        const drawer = document.getElementById('order-placement-drawer');
        drawer.classList.add('opacity-0');
        drawer.firstElementChild.classList.add('translate-x-full');
        setTimeout(() => {
            drawer.classList.add('hidden');
        }, 300);
    }

    function setDrawerCategory(cat) {
        drawerCategory = cat;
        openStaffOrderDrawer();
    }

    function drawDrawerMenuList() {
        const container = document.getElementById('drawer-menu-container');
        if (!container) return;
        container.innerHTML = '';

        const key = document.getElementById('drawer-search-input').value.toLowerCase();
        const list = menu.filter(m => {
            const matchesCat = drawerCategory === 'All' || m.category === drawerCategory;
            const matchesKey = m.name.toLowerCase().includes(key) || m.description.toLowerCase().includes(key);
            return matchesCat && matchesKey;
        });

        list.forEach(it => {
            container.innerHTML += `
                <div onclick="addDrawerItem('${it.id}')" class="bg-white border border-coffee-sand hover:border-coffee-rust rounded-xl p-3 flex justify-between items-start cursor-pointer text-xs group transition-all">
                    <div class="space-y-0.5">
                        <h5 class="font-bold text-coffee-dark group-hover:text-coffee-rust transition-colors leading-tight">${it.name}</h5>
                        <p class="text-[10px] text-coffee-milk line-clamp-2 leading-snug">${it.description}</p>
                        <span class="font-mono font-bold text-coffee-rust block mt-1">${formatVND(it.price)}</span>
                    </div>
                </div>
            `;
        });
    }

    function addDrawerItem(menuItemId) {
        const product = menu.find(m => m.id === menuItemId);
        const standardSize = product.availableSizes[0] || 'M';

        cartItems.push({
            menuItem: product,
            quantity: 1,
            customization: {
                size: standardSize,
                sugar: product.category !== 'Pastry' ? '100%' : undefined,
                ice: product.category !== 'Pastry' ? '100%' : undefined
            },
            notes: ''
        });

        drawDrawerCart();
    }

    function drawDrawerCart() {
        const container = document.getElementById('drawer-cart-container');
        if (!container) return;
        container.innerHTML = '';

        if (cartItems.length === 0) {
            container.innerHTML = `
                <div class="h-full flex flex-col items-center justify-center text-center text-coffee-milk/60 text-xs p-8 italic">
                    Chưa chọn nước uống.
                </div>
            `;
            document.getElementById('drawer-cart-total').innerText = '0 ₫';
            return;
        }

        let sum = 0;
        cartItems.forEach((c, idx) => {
            let p = c.menuItem.price;
            if (c.customization.size === 'L') p += 6000;
            else if (c.customization.size === 'S') p = Math.max(10000, p - 4000);

            const itemSub = p * c.quantity;
            sum += itemSub;

            let customLiquid = '';
            if (c.menuItem.category !== 'Pastry') {
                customLiquid = `
                    <div class="grid grid-cols-2 gap-1 px-1">
                        <select onchange="updateStaffCustom(${idx}, 'sugar', this.value)" class="text-[10px] bg-white border border-coffee-sand rounded font-bold outline-none leading-none p-1">
                            <option value="100%" ${c.customization.sugar === '100%' ? 'selected' : ''}>Đường 100%</option>
                            <option value="70%" ${c.customization.sugar === '70%' ? 'selected' : ''}>Đường 70%</option>
                            <option value="50%" ${c.customization.sugar === '50%' ? 'selected' : ''}>Đường 50%</option>
                            <option value="30%" ${c.customization.sugar === '30%' ? 'selected' : ''}>Đường 30%</option>
                            <option value="0%" ${c.customization.sugar === '0%' ? 'selected' : ''}>Không đường</option>
                        </select>
                        <select onchange="updateStaffCustom(${idx}, 'ice', this.value)" class="text-[10px] bg-white border border-coffee-sand rounded font-bold outline-none leading-none p-1">
                            <option value="100%" ${c.customization.ice === '100%' ? 'selected' : ''}>Đá 100%</option>
                            <option value="50%" ${c.customization.ice === '50%' ? 'selected' : ''}>Đá 50%</option>
                            <option value="30%" ${c.customization.ice === '30%' ? 'selected' : ''}>Đá 30%</option>
                            <option value="Ấm" ${c.customization.ice === 'Ấm' ? 'selected' : ''}>Nước Ấm</option>
                        </select>
                    </div>
                `;
            }

            container.innerHTML += `
                <div class="bg-coffee-light border border-coffee-sand/70 rounded-xl p-3 text-xs space-y-1.5 flex flex-col">
                    <div class="flex justify-between items-start gap-1">
                        <div>
                            <h6 class="font-bold text-coffee-dark leading-tight">${c.menuItem.name}</h6>
                            <p class="text-[10px] text-coffee-rust font-mono">${formatVND(itemSub)}</p>
                        </div>
                        <button onclick="removeDrawerCartItem(${idx})" class="p-1 text-[13px] text-coffee-milk hover:text-coffee-rust cursor-pointer">
                            🗑️
                        </button>
                    </div>

                    <div class="flex items-center gap-1.5">
                        <span class="text-[9px] font-bold text-coffee-milk">Size:</span>
                        ${c.menuItem.availableSizes.map(sz => `
                            <button onclick="updateStaffCustom(${idx}, 'size', '${sz}')" class="px-1.5 py-0.5 border text-[9px] font-bold rounded cursor-pointer ${c.customization.size === sz ? 'bg-coffee-rust border-transparent text-white shadow-3xs' : 'bg-white border-coffee-sand text-coffee-milk'}">
                                ${sz}
                            </button>
                        `).join('')}
                    </div>

                    ${customLiquid}

                    <div class="flex items-center justify-between border-t border-coffee-sand/20 pt-1.5">
                        <input type="text" oninput="updateStaffNotes(${idx}, this.value)" placeholder="Vị ngọt, ít tôm..." value="${c.notes}" class="flex-1 text-[10px] bg-white border border-coffee-sand rounded-lg px-2 py-0.5 outline-none focus:border-coffee-rust">
                        <div class="flex items-center gap-1 ml-2">
                            <button onclick="updateStaffQty(${idx}, -1)" class="w-5 h-5 bg-white border border-coffee-sand rounded font-bold text-xs flex items-center justify-center">-</button>
                            <span class="font-mono text-xs w-4 text-center font-bold">${c.quantity}</span>
                            <button onclick="updateStaffQty(${idx}, 1)" class="w-5 h-5 bg-white border border-coffee-sand rounded font-bold text-xs flex items-center justify-center">+</button>
                        </div>
                    </div>
                </div>
            `;
        });

        document.getElementById('drawer-cart-total').innerText = formatVND(sum);
    }

    function updateStaffCustom(idx, attr, val) {
        cartItems[idx].customization[attr] = val;
        drawDrawerCart();
    }

    function updateStaffNotes(idx, val) {
        cartItems[idx].notes = val;
    }

    function updateStaffQty(idx, d) {
        const n = cartItems[idx].quantity + d;
        if (n > 0) {
            cartItems[idx].quantity = n;
            drawDrawerCart();
        }
    }

    function removeDrawerCartItem(idx) {
        cartItems.splice(idx, 1);
        drawDrawerCart();
    }

    async function submitTicket() {
        if (cartItems.length === 0) {
            alert('Vui lòng chọn ít nhất một món nước bổ sung!');
            return;
        }

        const itemsToSend = cartItems.map(c => ({
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

        const comment = document.getElementById('drawer-order-notes').value;

        try {
            const response = await fetch('/api/orders', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    tableId: selectedTableId,
                    items: itemsToSend,
                    notes: comment
                })
            });

            if (response.ok) {
                closeOrderDrawer();
                selectedTableId = null;
                flashNotify('📋 Gửi phiếu dọn món bổ sung thành công!');
            } else {
                const error = await response.json();
                alert(error.error || 'Xảy ra lỗi khi gửi phiếu gọi nước.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    setupWebSocket();

    // Check if redirecting from order summary after payment success
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('paymentSuccess') === '1') {
        flashNotify('💸 Thanh toán thành công!');
        window.history.replaceState({}, document.title, window.location.pathname);
    }
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
