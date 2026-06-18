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

        // This page may have specific custom behaviors for logout or continue
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

<div class="max-w-xl w-full mx-auto space-y-6 animate-fade-in my-6">
    
    <!-- Printable Invoice Receipt layout -->
    <div class="bg-white border border-coffee-sand rounded-3xl p-6 sm:p-8 shadow-sm space-y-6 font-sans relative">
        <!-- Print decorative header dots -->
        <div class="text-center space-y-1.5 border-b border-dashed border-coffee-sand pb-4">
            <h2 class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark uppercase select-none">
                nhà cà phê<span class="text-coffee-rust font-sans font-bold">.</span>
            </h2>
            <p class="text-[10px] text-coffee-milk uppercase tracking-widest font-bold">Quán cà phê gia đình - gọi món tại bàn</p>
            <p class="text-[10px] text-coffee-milk/70 font-mono">Địa chỉ: Khu Phố 2, Phường Linh Trung, Thủ Đức, HCM</p>
            <p class="text-[11px] text-coffee-milk/80 font-serif italic">Hotline dọn bàn & đặt món: 0392 345 678</p>
        </div>

        <div class="space-y-4">
            <!-- Order metadata -->
            <div class="grid grid-cols-2 gap-y-1.5 text-xs text-coffee-milk/90 font-mono border-b border-coffee-light pb-3">
                <span class="font-bold">BÀN PHỤC VỤ:</span>
                <span id="bill-table-name" class="text-right text-coffee-dark font-sans font-bold">Bàn --</span>
                
                <span>MÃ HÓA ĐƠN:</span>
                <span id="bill-order-number" class="text-right text-coffee-dark font-sans font-medium">#----</span>

                <span>THỜI GIAN ĐẦU:</span>
                <span id="bill-created-at" class="text-right">--:--:--</span>

                <span>TRẠNG THÁI CA:</span>
                <span id="bill-status" class="text-right font-bold text-coffee-rust uppercase">Chờ duyệt</span>
            </div>

            <!-- Items listed -->
            <div class="space-y-2">
                <h4 class="text-[10px] uppercase font-bold tracking-wider text-coffee-milk font-mono">Chi tiết đồ uống phục vụ</h4>
                <div id="bill-items-container" class="space-y-2 max-h-[250px] overflow-y-auto divide-y divide-coffee-light pr-1">
                    <!-- Loaded dynamically -->
                </div>
            </div>

            <!-- Calculated values -->
            <div class="border-t border-dashed border-coffee-sand pt-4 space-y-1.5 text-xs text-coffee-dark font-mono">
                <div class="flex justify-between">
                    <span>Tổng đơn gốc (Base Sum):</span>
                    <span id="bill-subtotal">0 ₫</span>
                </div>
                <div class="flex justify-between text-coffee-milk">
                    <span>Dịch vụ VAT (8%):</span>
                    <span id="bill-tax">0 ₫</span>
                </div>
                <div class="flex justify-between text-coffee-milk">
                    <span>Chiết khấu mã bàn (Promo):</span>
                    <span class="text-emerald-700">- 0 ₫</span>
                </div>
                <div class="flex justify-between text-sm font-bold border-t border-coffee-light pt-2 text-coffee-dark font-sans">
                    <span>TỔNG KHÁCH TRẢ (GRAND TOTAL):</span>
                    <span id="bill-grand-total" class="font-mono text-coffee-rust text-base font-bold">0 ₫</span>
                </div>
            </div>
        </div>

        <!-- Digital payment mock gateway -->
        <div class="border-t border-dashed border-coffee-sand pt-6 text-center space-y-4">
            <p class="text-[10px] uppercase font-mono tracking-wider font-bold text-coffee-milk">Thanh toán chuyển khoản tức thì VietQR</p>
            <div class="bg-coffee-light border border-coffee-sand/70 rounded-2xl p-4 flex flex-col items-center justify-center max-w-sm mx-auto space-y-3">
                
                <!-- SVG QRCode pattern matching screenshot -->
                <div class="bg-white p-3 rounded-xl border border-coffee-sand flex items-center justify-center shadow-2xs relative overflow-hidden group">
                    <img id="vietqr-image-mock" src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=VietQR-Simulated-Payment" alt="VietQR Simulated Transfer Code" class="w-40 h-40 object-contain">
                    <!-- Overlay stamp -->
                    <div class="absolute inset-0 bg-coffee-dark/80 flex flex-col items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity text-white p-3 text-center">
                        <span class="text-xl">💳</span>
                        <p class="text-[10px] font-bold">Mô phỏng VietQR</p>
                        <p class="text-[9px] opacity-70">Ngân hàng MBBank<br>STK: 0392345678<br>Tên: NHÀ CÀ PHÊ</p>
                    </div>
                </div>
                
                <div class="space-y-0.5 text-xs">
                    <p class="font-bold text-coffee-dark">Chuyển khoản trực tiếp</p>
                    <p class="text-[10px] text-coffee-milk">Nhà hàng tự động duyệt hoá đơn ngay khi khớp lệnh.</p>
                </div>
            </div>
        </div>

        <!-- Layout receipts print buttons -->
        <div class="pt-2 flex gap-3">
            <button onclick="window.print()" class="flex-1 bg-white hover:bg-coffee-light border border-coffee-sand text-coffee-dark py-2.5 rounded-xl text-xs font-bold font-mono transition-colors cursor-pointer">
                🖨️ In Phiếu Tem
            </button>
            <button onclick="simulateMockPayment()" class="flex-1 bg-coffee-rust text-white hover:bg-coffee-rust/95 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-all cursor-pointer">
                Xác nhận đã thu tiền 💸
            </button>
        </div>
    </div>
    
    <div class="text-center">
        <a href="waitstation.jsp" class="text-xs text-coffee-rust font-bold hover:underline font-mono">
            ← Quay lại sơ đồ Floor Wait Station
        </a>
    </div>
</div>

<!-- Custom Confirmation Modal -->
<div id="confirm-payment-modal" class="fixed inset-0 bg-coffee-dark/60 backdrop-blur-xs z-50 hidden flex items-center justify-center p-4 transition-all">
    <div class="bg-white border border-coffee-sand rounded-3xl p-6 max-w-sm w-full space-y-4 shadow-xl text-center animate-fade-in">
        <div class="space-y-1.5">
            <span class="text-3xl">💸</span>
            <h3 class="text-lg font-serif font-bold text-coffee-dark">Xác nhận thanh toán</h3>
            <p class="text-xs text-coffee-milk">Xác nhận dọn dẹp bàn, đã thu đầy đủ tiền mặt hoặc chuyển khoản thành công từ khách hàng này?</p>
        </div>
        <div class="flex gap-3 pt-2">
            <button onclick="closeConfirmPaymentModal()" class="flex-1 bg-white hover:bg-coffee-light border border-coffee-sand text-coffee-dark py-2 rounded-xl text-xs font-bold transition-all cursor-pointer">
                Quay lại
            </button>
            <button onclick="executeCheckoutPayment()" class="flex-1 bg-coffee-rust text-white hover:bg-coffee-rust/95 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-all cursor-pointer">
                Xác nhận ✓
            </button>
        </div>
    </div>
</div>

<script>
    let tables = [];
    let orders = [];
    let urlParams = new URLSearchParams(window.location.search);
    let tableId = urlParams.get('tableId') || 't1';

    function formatVND(amt) {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amt);
    }

    async function loadBillState() {
        try {
            const [rTables, rOrders] = await Promise.all([
                fetch('/api/tables'),
                fetch('/api/orders')
            ]);
            if (rTables.ok) tables = await rTables.json();
            if (rOrders.ok) orders = await rOrders.json();

            const table = tables.find(t => t.id === tableId);
            const activeOrder = orders.find(o => o.tableId === tableId && o.status !== 'Served');

            if (!table) {
                alert('Vị trí bàn không tồn tại.');
                window.location.href = 'waitstation.jsp';
                return;
            }

            document.getElementById('bill-table-name').innerText = table.name + ` (${table.zone === 'Ground Floor' ? 'Khu Trệt' : 'Sân Sát'})`;
            
            if (!activeOrder) {
                document.getElementById('bill-items-container').innerHTML = `
                    <div class="text-center py-6 text-xs text-coffee-milk italic">
                        Bàn này hiện tại không có hoá đơn nào chưa thanh toán.
                    </div>
                `;
                return;
            }

            document.getElementById('bill-order-number').innerText = '#' + activeOrder.orderNumber;
            document.getElementById('bill-created-at').innerText = new Date(activeOrder.createdAt).toLocaleTimeString('vi-VN') + ' ' + new Date(activeOrder.createdAt).toLocaleDateString('vi-VN');
            document.getElementById('bill-status').innerText = activeOrder.status === 'Pending' ? 'Đầu quầy' : activeOrder.status === 'Preparing' ? 'Đang làm' : 'Đồ sẵn sàng';

            // Draw items rows
            const itemsBox = document.getElementById('bill-items-container');
            itemsBox.innerHTML = '';
            
            let baseSum = 0;
            activeOrder.items.forEach(it => {
                let singlePrice = it.price;
                const sizeChar = it.customization ? it.customization.size : 'M';
                if (sizeChar === 'L') singlePrice += 6000;
                else if (sizeChar === 'S') singlePrice = Math.max(10000, singlePrice - 4000);

                const itemTotal = singlePrice * it.quantity;
                baseSum += itemTotal;

                itemsBox.innerHTML += `
                    <div class="flex justify-between items-start text-xs pt-2 font-medium">
                        <div class="space-y-0.5 pr-2">
                            <p class="font-bold text-coffee-dark">${it.name} <span class="text-[10px] text-coffee-rust font-mono">x${it.quantity}</span></p>
                            <p class="text-[9.5px] text-coffee-milk">Size ${sizeChar} \u2022 Ngọt:${it.customization ? it.customization.sugar : '100%'} \u2022 Đá:${it.customization ? it.customization.ice : '100%'}</p>
                            ${it.notes ? `<p class="text-[9.5px] italic text-coffee-rust">"${it.notes}"</p>` : ''}
                        </div>
                        <span class="font-bold font-mono text-coffee-dark text-[11px] shrink-0">${formatVND(itemTotal)}</span>
                    </div>
                `;
            });

            // Math sums
            const taxVal = Math.round(baseSum * 0.08);
            const grandTotal = baseSum + taxVal;

            document.getElementById('bill-subtotal').innerText = formatVND(baseSum);
            document.getElementById('bill-tax').innerText = formatVND(taxVal);
            document.getElementById('bill-grand-total').innerText = formatVND(grandTotal);

            // Update QR code dynamically with payment parameters
            const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=VietQR-Bank-MBBank-NHACAPHE-STK0392345678-Amount${grandTotal}-Order${activeOrder.orderNumber}`;
            document.getElementById('vietqr-image-mock').src = qrUrl;

        } catch (err) {
            console.error('Invoice load fail', err);
        }
    }

    function simulateMockPayment() {
        document.getElementById('confirm-payment-modal').classList.remove('hidden');
    }

    function closeConfirmPaymentModal() {
        document.getElementById('confirm-payment-modal').classList.add('hidden');
    }

    async function executeCheckoutPayment() {
        try {
            const resp = await fetch(`/api/tables/${tableId}/checkout`, { method: 'POST' });
            if (resp.ok) {
                closeConfirmPaymentModal();
                window.location.href = 'waitstation.jsp?paymentSuccess=1';
            } else {
                alert('Có lỗi thanh toán.');
            }
        } catch (err) {
            console.error(err);
        }
    }

    loadBillState();
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
