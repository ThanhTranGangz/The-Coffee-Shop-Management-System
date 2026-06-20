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

<div class="max-w-md w-full mx-auto bg-white border border-coffee-sand rounded-3xl p-8 shadow-sm space-y-6 my-12 animate-fade-in">
    <div class="text-center space-y-1">
        <span class="text-3xl">🔑</span>
        <h2 class="text-2xl font-serif font-bold text-coffee-dark">Đăng nhập Nhân viên</h2>
        <p class="text-xs text-coffee-milk">Hệ Thống Điều Hành Nhà Cây • POS terminal</p>
    </div>

    <!-- Static Login credentials form -->
    <form onsubmit="return handleMockLogin(event)" class="space-y-4">
        <div class="space-y-1">
            <label class="text-[10px] font-mono tracking-wider font-bold uppercase text-coffee-milk block">Tên tài khoản (Username)</label>
            <input type="text" id="username" placeholder="Nhập admin, waiter1 hoặc barista1..." required class="w-full text-xs px-4 py-2.5 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white transition-all font-mono">
        </div>
        
        <div class="space-y-1">
            <label class="text-[10px] font-mono tracking-wider font-bold uppercase text-coffee-milk block">Mật khẩu bảo mật</label>
            <input type="password" id="password" required class="w-full text-xs px-4 py-2.5 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white transition-all font-mono">
        </div>

        <div class="flex items-center justify-between text-xs pt-1">
            <label class="flex items-center gap-1.5 text-coffee-milk font-medium select-none">
                <input type="checkbox" checked class="w-3.5 h-3.5 accent-coffee-rust rounded">
                Ghi nhớ tài khoản POS
            </label>
            <a href="#" onclick="alert('Vui lòng liên hệ Người quản lý (Manager) để đặt lại mật khẩu.')" class="text-coffee-rust hover:underline">Quên mật khẩu?</a>
        </div>

        <button type="submit" class="w-full bg-coffee-rust text-white font-bold py-3 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all cursor-pointer shadow-xs text-center mt-2 flex justify-center items-center gap-2">
            Đăng nhập điều hành 💼
        </button>
    </form>

    <!-- Smart dynamically aligned suggestions -->
    <div class="bg-[#FAF7EE] border border-coffee-sand/70 rounded-2xl p-4 text-left space-y-1.5 text-xs text-coffee-milk">
        <p class="font-bold uppercase tracking-wider text-coffee-dark font-mono text-[10px] mb-1 text-center">📋 Tài khoản mẫu phục vụ ca</p>
        <p class="flex justify-between">
            <span>• Phục vụ (<strong class="text-coffee-dark font-mono">waiter1</strong>):</span>
            <span class="font-bold text-coffee-rust">Mat khau: 123456</span>
        </p>
        <p class="flex justify-between">
            <span>• Pha chế (<strong class="text-coffee-dark font-mono">barista1</strong>):</span>
            <span class="font-bold text-coffee-rust">Mat khau: 123456</span>
        </p>
        <p class="flex justify-between">
            <span>• Quản lý (<strong class="text-coffee-dark font-mono">admin</strong>):</span>
            <span class="font-bold text-coffee-rust">Mat khau: 123456</span>
        </p>
    </div>

    <div class="border-t border-coffee-sand/50 pt-4 text-center space-y-2">
        <p class="text-[10px] text-coffee-milk uppercase font-mono tracking-wide">Truy cập ca nhanh không cần mật khẩu</p>
        <div class="grid grid-cols-2 gap-2">
            <a href="waitstation.jsp" class="border border-coffee-sand rounded-xl py-2 px-3 hover:border-coffee-rust text-xs text-coffee-dark bg-coffee-light font-bold hover:bg-white transition-colors">
                Wait Station
            </a>
            <a href="kds.jsp" class="border border-coffee-sand rounded-xl py-2 px-3 hover:border-coffee-rust text-xs text-coffee-dark bg-coffee-light font-bold hover:bg-white transition-colors">
                Kitchen KDS
            </a>
        </div>
    </div>
</div>

<script>
    async function handleMockLogin(e) {
        e.preventDefault();
        const typedUser = document.getElementById('username').value.trim();
        const typedPass = document.getElementById('password').value;

        let roster = [];
        try {
            const res = await fetch('/api/staff');
            if (res.ok) roster = await res.json();
        } catch (err) {
            console.warn('API error fetching staff, using local storage.');
        }

        if (roster.length === 0) {
            roster = JSON.parse(localStorage.getItem('staff_roster')) || [];
        }

        if (roster.length === 0 || !roster.some(s => s.username === 'waiter1')) {
            roster = [
                { id: 1, name: 'Quản lý Hệ Thống', role: 'manager', pin: '8888', shift: 'Toàn thời gian', active: true, username: 'admin', password: '123456', status: 'Active', overtime: false },
                { id: 2, name: 'Nhân viên Phục vụ (waiter1)', role: 'waiter', pin: '1234', shift: 'Ca sáng (06:00 - 12:00)', active: true, username: 'waiter1', password: '123456', status: 'Active', overtime: false },
                { id: 3, name: 'Nhân viên Pha chế (barista1)', role: 'barista', pin: '3333', shift: 'Ca chiều (12:00 - 18:00)', active: true, username: 'barista1', password: '123456', status: 'Active', overtime: false }
            ];
            localStorage.setItem('staff_roster', JSON.stringify(roster));
        }

        let matched = roster.find(s => s.username === typedUser);

        if (!matched) {
            alert('Tài khoản nhân viên này không tồn tại trên hệ thống!');
            return false;
        }

        if (matched.password !== typedPass) {
            alert('Mật khẩu đăng nhập không chính xác! Vui lòng thử lại.');
            return false;
        }

        // Perform Gating hours & deactivation check
        if (matched.role !== 'manager') {
            const currentHour = new Date().getHours();
            
            // Auto restore Temp_Inactive and Off_Duty if day advanced
            const todayStr = new Date().toDateString();
            const lastSessionDay = localStorage.getItem('last_deactivation_check_day');
            if (lastSessionDay && lastSessionDay !== todayStr) {
                if (matched.status === 'Temp_Inactive' || matched.status === 'Off_Duty') {
                    matched.status = 'Active';
                    matched.active = true;
                    try {
                        await fetch('/api/staff', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(matched)
                        });
                    } catch (e) {}
                }
                localStorage.setItem('last_deactivation_check_day', todayStr);
            } else {
                localStorage.setItem('last_deactivation_check_day', todayStr);
            }

            const status = matched.status || 'Active';
            if (status === 'Temp_Inactive') {
                alert('⏸️ Tài khoản của bạn hiện đang bị VÔ HIỆU HÓA TẠM THỜI bởi quản lý cho ngày hôm nay. Vui lòng quay lại vào ngày mai khi tài khoản được kích hoạt lại tự động!');
                return false;
            }
            if (status === 'Perm_Inactive') {
                alert('🔒 Tài khoản của bạn đã bị KHÓA VĨNH VIỄN trên hệ thống. Vui lòng liên hệ Người quản lý trực tiếp để được mở khóa thủ công.');
                return false;
            }
            if (status === 'Off_Duty') {
                alert('🕊️ Bạn đã được Quản trị viên thông báo tan làm sớm hôm nay! Trạng thái trực tạm ngưng hiệu lực.');
                return false;
            }

            // Check shift boundaries unless they have approved overtime
            if (!matched.overtime) {
                const shiftStr = matched.shift || '';
                if (shiftStr.includes('Ca sáng') || shiftStr.includes('sáng')) {
                    if (currentHour < 6 || currentHour >= 12) {
                        alert('⏰ Tài khoản của bạn thuộc Ca Sáng (06:00 - 12:00) đã hết giờ trực ca hoặc chưa đến múi trực! Vui lòng chờ đến ngày mai hoặc yêu cầu quản lý cho phép Tăng ca (Overtime).');
                        return false;
                    }
                } else if (shiftStr.includes('Ca chiều') || shiftStr.includes('chiều')) {
                    if (currentHour < 12 || currentHour >= 18) {
                        alert('⏰ Tài khoản của bạn thuộc Ca Chiều (12:00 - 18:00) hiện tại không thuộc múi trực ca hoặc chưa đến giờ! Vui lòng xin cấp tăng ca hoặc chờ đến ca chiều.');
                        return false;
                    }
                } else if (shiftStr.includes('Ca tối') || shiftStr.includes('tối')) {
                    if (currentHour < 18 || currentHour >= 24) {
                        alert('⏰ Tài khoản của bạn thuộc Ca Tối (18:00 - 24:00) không thuộc múi giờ ca tối hiện hành!');
                        return false;
                    }
                }
            } else {
                // Past 24:00 (midnight), overtime concludes
                if (currentHour >= 24 || currentHour < 6) {
                    alert('⏰ Ca tăng ca phụ vụ trong ngày chỉ kéo dài đến 24:00 đêm! Giao dịch POS đã khép ca.');
                    return false;
                }
            }
        }

        const finalRole = matched.role;
        const finalUser = matched.name;

        localStorage.setItem('auth_role', finalRole);
        localStorage.setItem('auth_user', finalUser);

        alert(`🔑 Đăng nhập thành công với vai trò: ${finalRole === 'manager' ? 'Quản lý (Manager)' : finalRole === 'barista' ? 'Pha chế (Barista)' : 'Phục vụ (Waiter)'}! Chào mừng ${finalUser}.`);

        if (finalRole === 'barista') {
            window.location.href = 'kds.jsp';
        } else if (finalRole === 'manager') {
            window.location.href = 'dashboard.jsp';
        } else {
            window.location.href = 'waitstation.jsp';
        }
        return false;
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
