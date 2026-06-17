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
            var managerPages = ['dashboard.jsp', 'reports.jsp', 'staff-management.jsp'];

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
                    <a href="index.html" class="text-xs font-bold px-3 py-1.5 bg-white hover:bg-coffee-rust hover:text-white border border-coffee-sand rounded-xl shadow-xs transition-all pointer">
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
    <!-- Header Summary Block -->
    <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex justify-between items-center">
        <div>
            <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                <span>📊</span> Bảng điều khiển quản trị (POS Dashboard)
            </h2>
            <p class="text-xs text-coffee-milk font-medium">Giám sát doanh số, tỷ lệ trống bàn và thông số hoạt động điều phối của quán.</p>
        </div>
        <div class="bg-[#FAF7EE] border border-coffee-sand hover:border-coffee-rust text-coffee-dark px-3 py-1.5 rounded-full text-xs font-bold transition-all">
            Ca trực: <span class="text-coffee-rust font-mono" id="shift-time">Hàng ngày</span>
        </div>
    </div>

    <!-- Stats summary grid -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        
        <!-- Revenue Stat -->
        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-2">
            <p class="text-[10px] font-bold uppercase tracking-wider text-coffee-milk font-mono">Doanh thu đạt quầy</p>
            <div class="flex items-baseline justify-between">
                <span id="stat-revenue" class="text-2xl font-serif font-extrabold text-coffee-dark">0 ₫</span>
                <span class="text-[10px] font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">+12%</span>
            </div>
            <p class="text-[9.5px] text-coffee-milk">Tổng tiền mặt và chuyển khoản VietQR</p>
        </div>

        <!-- Occupancy Stat -->
        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-2">
            <p class="text-[10px] font-bold uppercase tracking-wider text-coffee-milk font-mono">Tỷ lệ sử dụng bàn</p>
            <div class="flex items-baseline justify-between">
                <span id="stat-occupancy" class="text-2xl font-serif font-extrabold text-coffee-dark">0%</span>
                <span class="text-[10px] font-bold text-coffee-rust font-mono" id="stat-table-ratio">0 / 0 bàn</span>
            </div>
            <p class="text-[9.5px] text-coffee-milk">Số lượng bàn có khách lưu trú</p>
        </div>

        <!-- Waiting queue Stat -->
        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-2">
            <p class="text-[10px] font-bold uppercase tracking-wider text-coffee-milk font-mono">Đơn nước chờ chế biến</p>
            <div class="flex items-baseline justify-between">
                <span id="stat-pending" class="text-2xl font-serif font-extrabold text-coffee-dark">0 phiếu</span>
                <span class="text-[10px] font-bold text-amber-800 bg-amber-50 px-2 py-0.5 rounded border border-amber-200 animate-pulse">Quầy bar hot</span>
            </div>
            <p class="text-[9.5px] text-coffee-milk">Các ly đang xếp hàng chuẩn bị làm</p>
        </div>

        <!-- Completed Stat -->
        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-2">
            <p class="text-[10px] font-bold uppercase tracking-wider text-coffee-milk font-mono">Số hóa đơn hoàn thành</p>
            <div class="flex items-baseline justify-between">
                <span id="stat-completed" class="text-2xl font-serif font-extrabold text-coffee-dark">0 hóa đơn</span>
                <span class="text-[10px] font-mono text-coffee-milk">Mục tiêu: 50</span>
            </div>
            <p class="text-[9.5px] text-coffee-milk">Số hóa đơn đã thanh toán bàn</p>
        </div>

    </div>

    <!-- Main columns -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        
        <!-- Live activity queue: Left standard -->
        <div class="lg:col-span-2 bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4">
            <div class="flex justify-between items-center border-b border-coffee-light pb-3">
                <div>
                    <h3 class="font-serif italic font-bold text-base text-coffee-dark">Log hoạt động quầy POS</h3>
                    <p class="text-[10px] text-coffee-milk">Màn hình cập nhật vệt nghiệp vụ ca dọn món nhanh</p>
                </div>
                <button onclick="fetchStateCore()" class="text-xs font-mono font-bold text-coffee-rust hover:underline">
                    🔄 Làm mới logs
                </button>
            </div>

            <!-- List box -->
            <div id="dashboard-orders-container" class="space-y-3 max-h-[400px] overflow-y-auto pr-1">
                <!-- Loaded dynamically -->
            </div>
        </div>

        <!-- Quick Administration toolset card: Right -->
        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4">
            <h4 class="font-serif italic font-bold text-base text-coffee-dark border-b border-coffee-light pb-2">Bảng điều hướng nhanh</h4>
            <div class="grid grid-cols-1 gap-2.5">
                <a href="reports.jsp" class="flex items-center gap-3 bg-coffee-light hover:bg-coffee-sand/35 border border-coffee-sand/70 p-3 rounded-2xl text-xs font-medium text-coffee-dark hover:text-coffee-rust transition-all">
                    <span class="text-md">📈</span>
                    <div>
                        <p class="font-bold">Báo cáo doanh thu & Đồ hoạ</p>
                        <p class="text-[9.5px] text-coffee-milk font-normal">Xem biểu đồ hình phễu bán và xu hướng</p>
                    </div>
                </a>
                <a href="staff-management.jsp" class="flex items-center gap-3 bg-coffee-light hover:bg-coffee-sand/35 border border-coffee-sand/70 p-3 rounded-2xl text-xs font-medium text-coffee-dark hover:text-coffee-rust transition-all">
                    <span class="text-md">🧑‍🤝‍🧑</span>
                    <div>
                        <p class="font-bold">Quản lý ca trực nhân sự</p>
                        <p class="text-[9.5px] text-coffee-milk font-normal">Danh sách phân quyền Waiters, Baristas</p>
                    </div>
                </a>
                <a href="table-qr.jsp" class="flex items-center gap-3 bg-coffee-light hover:bg-coffee-sand/35 border border-coffee-sand/70 p-3 rounded-2xl text-xs font-medium text-coffee-dark hover:text-coffee-rust transition-all">
                    <span class="text-md">🖨️</span>
                    <div>
                        <p class="font-bold">Xuất mã QR Bàn hàng</p>
                        <p class="text-[9.5px] text-coffee-milk font-normal">In tem dán quét gọi món cho từng số bàn</p>
                    </div>
                </a>
                <a href="staff-orders.jsp" class="flex items-center gap-3 bg-coffee-light hover:bg-coffee-sand/35 border border-coffee-sand/70 p-3 rounded-2xl text-xs font-medium text-coffee-dark hover:text-coffee-rust transition-all">
                    <span class="text-md">📋</span>
                    <div>
                        <p class="font-bold">Quản lý vệt hoá đơn POS</p>
                        <p class="text-[9.5px] text-coffee-milk font-normal">Truy vết tình trạng nấu nướng của bếp</p>
                    </div>
                </a>
            </div>
        </div>

    </div>
</div>

<script>
    let menu = [];
    let tables = [];
    let orders = [];

    function formatVND(amt) {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amt);
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

            calculateStats();
            drawDashboardOrders();
        } catch (err) {
            console.error('Stats aggregation failed', err);
        }
    }

    function calculateStats() {
        // Revenue metric
        let totalRev = 0;
        let completes = 0;
        orders.forEach(o => {
            if (o.status === 'Served') {
                totalRev += o.totalAmount;
                completes++;
            }
        });

        // Occupancy metric
        const busyTables = tables.filter(t => t.status !== 'empty').length;
        const totalTables = tables.length;
        const ratio = totalTables > 0 ? Math.round((busyTables / totalTables) * 100) : 0;

        // Pending metric
        const pendings = orders.filter(o => o.status === 'Pending').length;

        // Update labels
        document.getElementById('stat-revenue').innerText = formatVND(totalRev);
        document.getElementById('stat-occupancy').innerText = `${ratio}%`;
        document.getElementById('stat-table-ratio').innerText = `${busyTables} / ${totalTables} bàn`;
        document.getElementById('stat-pending').innerText = `${pendings} đơn`;
        document.getElementById('stat-completed').innerText = `${completes} h.đơn`;
    }

    function drawDashboardOrders() {
        const container = document.getElementById('dashboard-orders-container');
        if (!container) return;
        container.innerHTML = '';

        if (orders.length === 0) {
            container.innerHTML = `
                <div class="text-center py-12 text-xs text-coffee-milk italic">
                    Chưa có bất kỳ hóa đơn nào phát sinh trong ngày trực hôm nay.
                </div>
            `;
            return;
        }

        const reversed = [...orders].reverse();

        reversed.forEach(o => {
            let badgeClass = 'bg-coffee-light border-coffee-sand text-coffee-milk';
            let label = 'Mâm bếp';
            if (o.status === 'Preparing') {
                badgeClass = 'bg-amber-100 border-amber-250 text-amber-800';
                label = 'Pha chế';
            } else if (o.status === 'Ready') {
                badgeClass = 'bg-emerald-100 border-emerald-300 text-emerald-800 animate-pulse';
                label = 'Dâng dọn';
            } else if (o.status === 'Served') {
                badgeClass = 'bg-coffee-rust/10 text-coffee-rust border-transparent';
                label = 'Thanh toán✓';
            }

            const activeLengthCount = o.items.reduce((s, it) => s + it.quantity, 0);

            container.innerHTML += `
                <div class="bg-coffee-light/40 border border-coffee-sand/50 rounded-2xl p-4 text-xs flex flex-col sm:flex-row sm:items-center justify-between gap-3 font-medium">
                    <div class="space-y-1">
                        <div class="flex items-center gap-2">
                            <span class="font-bold text-coffee-dark">Hóa đơn #${o.orderNumber}</span>
                            <span class="text-[9px] font-mono bg-white px-2 py-0.5 rounded border border-coffee-sand text-coffee-rust">BÀN: ${o.tableName}</span>
                        </div>
                        <p class="text-[10px] text-coffee-milk">Tổng đồ đặt: <span class="font-mono font-bold text-coffee-dark">${activeLengthCount} cốc</span> \u2022 Ghi chú: "${o.notes || 'Không ghi chú'}"</p>
                    </div>
                    <div class="flex sm:flex-col items-center sm:items-end justify-between sm:justify-start gap-1">
                        <span class="font-mono font-bold text-coffee-rust text-xs">${formatVND(o.totalAmount)}</span>
                        <span class="text-[9px] font-mono font-bold uppercase py-0.5 px-2 rounded-full border ${badgeClass}">
                            ${label}
                        </span>
                    </div>
                </div>
            `;
        });
    }

    // Begin
    fetchStateCore();
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
