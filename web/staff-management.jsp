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
                        <a href="dashboard.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-medium">📊 Dashboard panel</a>
                        <a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">📦 Kho nguyên liệu</a>
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

<div class="space-y-6">
    <!-- Header visual -->
    <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex justify-between items-center">
        <div>
            <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                <span>🛡️</span> Hệ thống Quản lí (Admin Manager Panel)
            </h2>
            <p class="text-xs text-coffee-milk font-medium">Lập danh sách tài khoản nhân sự, điều phối bộ phận trực và theo dõi hồ sơ CRM hội viên thân thiết.</p>
        </div>
        <div class="bg-coffee-rust text-white font-mono text-[11px] font-bold px-3 py-1.5 rounded-full uppercase tracking-wider">
            POS ROSTER • CRM SYSTEM
        </div>
    </div>

    <!-- Main split cols -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        
        <!-- Interactive Left Card with Switchable Tabs: Left -->
        <div class="lg:col-span-2 bg-white border border-coffee-sand rounded-3xl p-6 shadow-sm space-y-4">
            
            <!-- Tab switches header -->
            <div class="flex items-center justify-between border-b border-coffee-sand/55 pb-2">
                <div class="flex gap-2">
                    <button onclick="setManagementTab('staff')" id="tab-btn-staff" class="px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer">
                        🧑‍🤝‍🧑 Tài khoản Nhân sự
                    </button>
                    <button onclick="setManagementTab('crm')" id="tab-btn-crm" class="px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer">
                        🎯 Hồ sơ Khách hàng CRM
                    </button>
                </div>
                <div class="hidden sm:block">
                    <input type="text" id="management-search-input" oninput="handleDirectorySearch()" placeholder="Tìm kiếm nhanh..." class="text-xs px-3 py-1.5 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                </div>
            </div>

            <!-- Content Panel 1: Staff Directory -->
            <div id="panel-staff" class="space-y-4">
                <div>
                     <h3 class="font-serif italic font-bold text-base text-coffee-dark">Danh sách tài khoản trực ca</h3>
                     <p class="text-[10px] text-coffee-milk">Nhấp đúp hoặc bấm Sửa để cập nhật quyền truy cập, mật khẩu và trạng thái ca của Waiters, Baristas & Managers.</p>
                </div>

                <div class="overflow-x-auto">
                    <table class="w-full text-left text-xs border-collapse">
                        <thead>
                            <tr class="border-b border-coffee-sand font-bold text-coffee-milk text-[10px] uppercase font-mono bg-coffee-light/50">
                                <th class="py-3 px-4">Nhân viên / Login</th>
                                <th class="py-3 px-4">Chức danh / Bộ phận</th>
                                <th class="py-3 px-4 font-mono">Ca trực</th>
                                <th class="py-3 px-4">Trạng thái</th>
                                <th class="py-3 px-4 text-center">Tác vụ</th>
                            </tr>
                        </thead>
                        <tbody id="staff-table-body" class="divide-y divide-coffee-sand/20 font-medium">
                            <!-- Loaded dynamically -->
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Content Panel 2: CRM Customers Directory (Initially hidden) -->
            <div id="panel-crm" class="hidden space-y-4">
                <div>
                     <h3 class="font-serif italic font-bold text-base text-coffee-dark">Dữ liệu khách hàng hội viên (CRM)</h3>
                     <p class="text-[10px] text-coffee-milk">Dữ liệu các hội viên đăng ký nhận ưu đãi tại nhà cà phê. Theo dõi bậc thưởng, email liên hệ và thói quen gọi món.</p>
                </div>

                <div class="overflow-x-auto">
                    <table class="w-full text-left text-xs border-collapse">
                        <thead>
                            <tr class="border-b border-coffee-sand font-bold text-coffee-milk text-[10px] uppercase font-mono bg-coffee-light/50">
                                <th class="py-3 px-4">Họ tên / SĐT</th>
                                <th class="py-3 px-4">Email liên hệ</th>
                                <th class="py-3 px-4">Hạng Hội viên</th>
                                <th class="py-3 px-4 font-mono">Điểm (Hạt)</th>
                                <th class="py-3 px-4">Sở thích gu nước</th>
                            </tr>
                        </thead>
                        <tbody id="crm-table-body" class="divide-y divide-coffee-sand/20 font-medium">
                            <!-- Loaded dynamically from localStorage/MemberDb -->
                        </tbody>
                    </table>
                </div>
            </div>

        </div>

        <!-- Add/Edit staff card form: Right -->
        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4 relative overflow-hidden" id="staff-form-container">
            <h4 class="font-serif italic font-bold text-base text-coffee-dark border-b border-coffee-light pb-2 flex items-center justify-between">
                <span id="form-mode-title">Đăng ký thêm Nhân sự</span>
                <button onclick="resetRosterForm()" id="cancel-edit-btn" class="hidden text-[10px] font-sans font-bold text-coffee-milk hover:text-coffee-rust">
                    ✕ Huỷ sửa
                </button>
            </h4>
            
            <form onsubmit="handleNewStaff(event)" class="space-y-3.5">
                <div class="space-y-1">
                    <label class="text-[10px] font-bold uppercase text-coffee-milk block">Họ tên nhân viên</label>
                    <input type="text" id="staff-name" required placeholder="Lưu Kỳ Duyên" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white transition-all">
                </div>

                <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                        <label class="text-[10px] font-mono font-bold uppercase text-coffee-milk block">Tên Tài khoản</label>
                        <input type="text" id="staff-username" required placeholder="duyen_coffeetree" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white transition-all font-mono">
                    </div>
                    <div class="space-y-1">
                        <label class="text-[10px] font-mono font-bold uppercase text-coffee-milk block">Mật khẩu</label>
                        <input type="password" id="staff-password" required placeholder="•••••" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white transition-all font-mono">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block">Mã PIN POS (4 số)</label>
                        <input type="text" id="staff-pin" required maxlength="4" placeholder="1122" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white font-mono transition-all text-center">
                    </div>

                    <div class="space-y-1">
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block">Vai trò (Role)</label>
                        <select id="staff-role" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust cursor-pointer font-bold">
                            <option value="waiter">Phục vụ sàn (Waiter)</option>
                            <option value="barista">Pha chế bar (Barista)</option>
                        </select>
                    </div>
                </div>

                <div class="space-y-1">
                    <label class="text-[10px] font-bold uppercase text-coffee-milk block">Phân ca đăng ký</label>
                    <select id="staff-shift" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none cursor-pointer">
                        <option value="Toàn thời gian">Toàn thời gian</option>
                        <option value="Ca sáng (06:00 - 12:00)">Ca sáng (06:00 - 12:00)</option>
                        <option value="Ca chiều (12:00 - 18:00)">Ca chiều (12:00 - 18:00)</option>
                        <option value="Ca tối (18:00 - 23:00)">Ca tối (18:00 - 23:00)</option>
                    </select>
                </div>

                <button type="submit" id="form-submit-btn" class="w-full bg-coffee-rust text-white font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-colors cursor-pointer text-center mt-2 flex items-center justify-center gap-1.5 shadow-3xs">
                    Ghi danh Roster 🧑‍🤝‍🧑
                </button>
            </form>
        </div>

    </div>
</div>

<script>
    function isShiftCurrentlyActive(shiftText) {
        if (!shiftText) return false;
        const now = new Date();
        const hour = now.getHours();
        
        if (shiftText.includes("Toàn thời gian") || shiftText.toLowerCase().includes("all")) {
            return true;
        }
        
        // Ca sáng (06:00 - 12:00)
        if (shiftText.includes("06:00") && shiftText.includes("12:00")) {
            return (hour >= 6 && hour < 12);
        }
        
        // Ca chiều (12:00 - 18:00)
        if (shiftText.includes("12:00") && shiftText.includes("18:00")) {
            return (hour >= 12 && hour < 18);
        }
        
        // Ca tối (18:00 - 23:00) or Ca tối (18:00 - 24:00)
        if (shiftText.includes("18:00") && (shiftText.includes("23:00") || shiftText.includes("24:00") || shiftText.includes("00:00"))) {
            return (hour >= 18 && hour < 24);
        }
        
        return true; // Fallback
    }

    let activeManagementTab = 'staff';
    let searchQuery = '';
    let editingStaffId = null;

    let staffRoster = [];
    let crmCustomers = [];

    // Load data from Java API endpoints
    async function loadAllData() {
        try {
            const [staffRes, crmRes] = await Promise.all([
                fetch('/api/staff'),
                fetch('/api/members')
            ]);
            
            if (staffRes.ok) {
                staffRoster = await staffRes.json();
            }
            if (crmRes.ok) {
                crmCustomers = await crmRes.json();
            }
        } catch (e) {
            console.warn('API error, falling back to local cookies or storage', e);
            // Fallback loads
            staffRoster = JSON.parse(localStorage.getItem('staff_roster')) || [];
            crmCustomers = JSON.parse(localStorage.getItem('local_member_db')) || [];
        }

        // Cache inside localStorage as fallback index
        localStorage.setItem('staff_roster', JSON.stringify(staffRoster));
        localStorage.setItem('local_member_db', JSON.stringify(crmCustomers));

        // Re-draw panels
        handleDirectorySearch();
    }

    // Switch CRM / Staff tabs
    function setManagementTab(tab) {
        activeManagementTab = tab;
        const btnStaff = document.getElementById('tab-btn-staff');
        const btnCrm = document.getElementById('tab-btn-crm');
        const pStaff = document.getElementById('panel-staff');
        const pCrm = document.getElementById('panel-crm');

        if (tab === 'staff') {
            btnStaff.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer";
            btnCrm.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer";
            pStaff.classList.remove('hidden');
            pCrm.classList.add('hidden');
        } else {
            btnCrm.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer";
            btnStaff.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer";
            pStaff.classList.add('hidden');
            pCrm.classList.remove('hidden');
        }
        handleDirectorySearch();
    }

    function handleDirectorySearch() {
        searchQuery = document.getElementById('management-search-input').value.toLowerCase().trim();
        if (activeManagementTab === 'staff') {
            drawStaffRoster();
        } else {
            drawCrmDirectory();
        }
    }

    function drawStaffRoster() {
        const tbody = document.getElementById('staff-table-body');
        if (!tbody) return;
        tbody.innerHTML = '';

        const list = staffRoster.filter(s => {
            if (s.role === 'manager') return false;
            return searchQuery === '' || 
                s.name.toLowerCase().includes(searchQuery) || 
                s.role.toLowerCase().includes(searchQuery) ||
                (s.username && s.username.toLowerCase().includes(searchQuery));
        });

        if (list.length === 0) {
            tbody.innerHTML = `<tr><td colspan="5" class="py-6 text-center text-coffee-milk italic">Không tìm thấy tài khoản nhân sự nào!</td></tr>`;
            return;
        }

        list.forEach(s => {
            const roleBadge = s.role === 'manager' 
                ? 'bg-purple-150 text-purple-800 border-purple-250' 
                : s.role === 'barista' 
                    ? 'bg-amber-100 text-amber-800 border-amber-200' 
                    : 'bg-blue-100 text-blue-800 border-blue-200';

            const roleName = s.role === 'manager' ? 'Giám sát (Manager)' : s.role === 'barista' ? 'Pha chế (Barista)' : 'Phục vụ (Waiter)';

            let statusText = "● Hoạt động";
            let statusClr = "bg-emerald-100 text-emerald-800 border-emerald-250";
            const staffStatus = s.status || "Active";
            
            const isShiftActive = isShiftCurrentlyActive(s.shift);
            
            if (staffStatus === 'Temp_Inactive') {
                statusText = "⏸️ Khóa tạm thời";
                statusClr = "bg-amber-100 text-amber-800 border-amber-250";
            } else if (staffStatus === 'Perm_Inactive') {
                statusText = "🔒 Khóa vĩnh viễn";
                statusClr = "bg-red-150 text-red-800 border-red-250";
            } else if (staffStatus === 'Off_Duty') {
                statusText = "🕊️ Tan làm sớm";
                statusClr = "bg-gray-150 text-gray-800 border-gray-250";
            } else if (!isShiftActive && !s.overtime) {
                statusText = "💤 Hết ca / Tắt hoạt động";
                statusClr = "bg-indigo-50 text-indigo-700 border-indigo-200";
            }

            const otBadge = s.overtime ? `<span class="bg-orange-50 text-orange-850 border border-orange-200 px-1.5 py-0.5 rounded text-[8px] font-mono uppercase font-bold ml-1.5 animate-pulse">Tăng ca 🕒</span>` : '';

            tbody.innerHTML += `
                <tr class="hover:bg-coffee-light/25 transition-colors">
                    <td class="py-3 px-4">
                        <div class="font-bold text-coffee-dark flex items-center gap-1">
                            <span>${s.name}</span>
                            ${otBadge}
                        </div>
                        <div class="text-[9.5px] text-coffee-milk font-mono flex items-center gap-1.5">
                            <span>User: <strong class="text-coffee-dark font-semibold">${s.username || 'unspecified'}</strong></span>
                            <span>•</span>
                            <span>PIN: <strong class="text-coffee-rust">${s.pin}</strong></span>
                        </div>
                    </td>
                    <td class="py-3 px-4">
                        <span class="text-[9.5px] font-bold uppercase tracking-wider px-2 py-0.5 border rounded-full ${roleBadge}">
                            ${roleName}
                        </span>
                    </td>
                    <td class="py-3 px-4 text-coffee-milk font-mono text-[11px]">
                        <div>${s.shift}</div>
                    </td>
                    <td class="py-3 px-4">
                        <div class="space-y-2 py-1">
                            <div>
                                <span class="text-[9px] font-bold px-2 py-0.5 border rounded-full ${statusClr}">
                                    ${statusText}
                                </span>
                            </div>
                            
                            <!-- Actions panel to alter shift context in real time -->
                            <div class="flex flex-wrap gap-1 max-w-[280px]">
                                <button onclick="updateStaffState(${s.id}, 'Active')" class="text-[8px] font-bold bg-white hover:bg-emerald-50 border border-coffee-sand hover:border-emerald-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Kích hoạt lại / Hoạt động">
                                    🟢 Kích phục
                                </button>
                                <button onclick="updateStaffState(${s.id}, 'Temp_Inactive')" class="text-[8px] font-bold bg-white hover:bg-amber-100 border border-coffee-sand hover:border-amber-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Khoá ngày hôm nay, tự động phục hồi hôm sau">
                                    ⏸️ Khóa tạm thời
                                </button>
                                <button onclick="updateStaffState(${s.id}, 'Perm_Inactive')" class="text-[8px] font-bold bg-white hover:bg-red-100 border border-coffee-sand hover:border-red-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Khóa vĩnh viễn không tự phục hồi">
                                    🔒 Khóa vĩnh viễn
                                </button>
                                <button onclick="updateStaffState(${s.id}, 'Off_Duty')" class="text-[8px] font-bold bg-white hover:bg-gray-100 border border-coffee-sand hover:border-gray-400 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Cần cho ra ca, tạm khóa hôm nay">
                                    🕊️ Cho Tan Làm
                                </button>
                                <button onclick="approveOvertime(${s.id})" class="text-[8px] font-bold bg-[#FAF7EE] hover:bg-orange-50 border border-coffee-sand hover:border-orange-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Phê duyệt quyền tăng ca">
                                    🕒 ${s.overtime ? 'Hủy tăng ca' : 'Duyệt Tăng ca'}
                                </button>
                            </div>
                        </div>
                    </td>
                    <td class="py-3 px-4 text-center">
                        <div class="flex items-center justify-center gap-2">
                            <button onclick="editRosterItem(${s.id})" class="text-coffee-dark hover:text-coffee-rust text-xs font-bold font-sans cursor-pointer">
                                📝 Sửa
                            </button>
                            <span class="text-coffee-sand">|</span>
                            <button onclick="deleteRosterItem(${s.id})" class="text-coffee-milk hover:text-red-600 text-xs cursor-pointer">
                                🗑️ Xoá
                            </button>
                        </div>
                    </td>
                </tr>
            `;
        });
    }

    function drawCrmDirectory() {
        const tbody = document.getElementById('crm-table-body');
        if (!tbody) return;
        tbody.innerHTML = '';

        const list = crmCustomers.filter(c => 
            searchQuery === '' || 
            c.name.toLowerCase().includes(searchQuery) || 
            c.phone.includes(searchQuery) ||
            (c.email && c.email.toLowerCase().includes(searchQuery))
        );

        if (list.length === 0) {
            tbody.innerHTML = `<tr><td colspan="5" class="py-6 text-center text-coffee-milk italic">Không tìm thấy khách hàng thành viên nào khớp bộ lọc!</td></tr>`;
            return;
        }

        list.forEach(c => {
            const rankBadge = c.rank === 'Platinum' 
                ? 'bg-yellow-100 text-yellow-800 border-yellow-300' 
                : c.rank === 'Gold' 
                    ? 'bg-orange-100 text-orange-800 border-orange-200' 
                    : 'bg-slate-100 text-slate-800 border-slate-200';

            const prefName = c.pref === 'Espresso' ? 'Cà phê Espresso sữa' : c.pref === 'Tea' ? 'Trà Trái Cây mát' : c.pref === 'Special' ? 'Đặc sản Sữa lắc' : 'Bánh croissants';

            tbody.innerHTML += `
                <tr class="hover:bg-coffee-light/25 transition-colors">
                    <td class="py-3 px-4">
                        <div class="font-bold text-coffee-dark">${c.name}</div>
                        <div class="text-[10px] text-coffee-milk font-mono font-bold">${c.phone}</div>
                    </td>
                    <td class="py-3 px-4 font-mono text-coffee-dark text-[11px]">${c.email || 'không có'}</td>
                    <td class="py-3 px-4">
                        <span class="text-[9.5px] font-bold px-2.5 py-0.5 border rounded-full ${rankBadge}">
                            ${c.rank}
                        </span>
                    </td>
                    <td class="py-3 px-4 font-mono font-bold text-coffee-rust text-xs">${c.points} hạt</td>
                    <td class="py-3 px-4 text-coffee-milk italic text-[11px]">${prefName}</td>
                </tr>
            `;
        });
    }

    async function updateStaffState(id, status) {
        const item = staffRoster.find(s => s.id === id);
        if (item) {
            item.status = status;
            if (status === 'Active') {
                item.active = true;
            } else {
                item.active = false;
            }
            try {
                const res = await fetch('/api/staff', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(item)
                });
                if (res.ok) {
                    flashNotify(`🧑‍🤝‍🧑 Đã đổi trạng thái "${item.name}" thành ${status}!`);
                    loadAllData();
                }
            } catch(e) {
                console.error(e);
            }
        }
    }

    async function approveOvertime(id) {
        const item = staffRoster.find(s => s.id === id);
        if (item) {
            item.overtime = !item.overtime;
            if (item.overtime) {
                item.status = 'Active';
                item.active = true;
            }
            try {
                const res = await fetch('/api/staff', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(item)
                });
                if (res.ok) {
                    flashNotify(`🧑‍🤝‍🧑 Trạng thái Tăng ca của "${item.name}" chỉnh thành: ${item.overtime ? 'CHO PHÉP TĂNG CA 🕒' : 'Không tăng ca'}`);
                    loadAllData();
                }
            } catch(e) {
                console.error(e);
            }
        }
    }

    function editRosterItem(id) {
        const s = staffRoster.find(s => s.id === id);
        if (!s) return;
        editingStaffId = id;

        document.getElementById('staff-name').value = s.name;
        document.getElementById('staff-username').value = s.username || '';
        document.getElementById('staff-password').value = s.password || '';
        document.getElementById('staff-pin').value = s.pin || '';
        document.getElementById('staff-role').value = s.role;
        document.getElementById('staff-shift').value = s.shift;

        document.getElementById('form-mode-title').innerText = 'Chỉnh sửa tài khoản';
        document.getElementById('form-submit-btn').innerText = 'Cập nhật tài khoản 💾';
        document.getElementById('cancel-edit-btn').classList.remove('hidden');

        // Scroll form card into view smoothly
        document.getElementById('staff-form-container').scrollIntoView({ behavior: 'smooth' });
    }

    function resetRosterForm() {
        editingStaffId = null;
        document.getElementById('staff-name').value = '';
        document.getElementById('staff-username').value = '';
        document.getElementById('staff-password').value = '';
        document.getElementById('staff-pin').value = '';
        document.getElementById('staff-role').value = 'waiter';
        document.getElementById('staff-shift').value = 'Toàn thời gian';

        document.getElementById('form-mode-title').innerText = 'Đăng ký thêm Nhân sự';
        document.getElementById('form-submit-btn').innerText = 'Ghi danh Roster 🧑‍🤝‍🧑';
        document.getElementById('cancel-edit-btn').classList.add('hidden');
    }

    async function deleteRosterItem(id) {
        if (!confirm('Xác nhận rút tên nhân viên này khỏi hệ thống quầy chính?')) return;
        try {
            const res = await fetch('/api/staff/delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: id })
            });
            if (res.ok) {
                flashNotify('🧑‍🤝‍🧑 Đã bãi miễn nhân viên khỏi danh sách Roster.');
                loadAllData();
            }
        } catch(e) {
            console.error(e);
        }
    }

    async function handleNewStaff(e) {
        e.preventDefault();
        const name = document.getElementById('staff-name').value;
        const username = document.getElementById('staff-username').value.trim();
        const password = document.getElementById('staff-password').value;
        const pin = document.getElementById('staff-pin').value.trim();
        const role = document.getElementById('staff-role').value;
        const shift = document.getElementById('staff-shift').value;

        if (pin.length !== 4 || isNaN(pin)) {
            alert('Mã PIN POS nhanh phải đúng 4 ký tự số!');
            return;
        }

        const existing = editingStaffId ? staffRoster.find(s => s.id === editingStaffId) : null;
        const payload = {
            id: editingStaffId ? editingStaffId : 0,
            name, username, password, pin, role, shift,
            active: existing ? existing.active : true,
            status: existing ? existing.status : "Active",
            overtime: existing ? existing.overtime : false
        };

        try {
            const res = await fetch('/api/staff', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                if (editingStaffId !== null) {
                    alert(`🧑‍🤝‍🧑 Cập nhật tài khoản nhân sự "${name}" thành công!`);
                } else {
                    alert(`🧑‍🤝‍🧑 Đăng ký hồ sơ nhân viên "${name}" thành công! Có hiệu ứng trực ca lập tức.`);
                }
                resetRosterForm();
                loadAllData();
            } else {
                alert('Có lỗi xảy ra khi lưu nhân tố!');
            }
        } catch (err) {
            console.error(err);
        }
    }

    // Initial load
    loadAllData();
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
