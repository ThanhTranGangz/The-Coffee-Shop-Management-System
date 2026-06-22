<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nhà cà phê. — quản lý quán</title>
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
        body.menu-loading > nav,
        body.menu-loading > main,
        body.menu-loading > footer {
            opacity: 0;
            transform: translateY(10px);
        }
        body > nav,
        body > main,
        body > footer {
            transition: opacity 520ms ease, transform 520ms ease;
        }
        .menu-loading-screen {
            transition: opacity 520ms ease, visibility 520ms ease;
        }
        .menu-loading-screen.is-hidden {
            opacity: 0;
            visibility: hidden;
            pointer-events: none;
        }
        .menu-loading-card {
            animation: menuLoaderFloat 2.6s ease-in-out infinite;
        }
        .menu-loading-ring {
            width: 76px;
            height: 76px;
            border-radius: 999px;
            border: 1px solid rgba(229, 222, 201, .95);
            position: relative;
        }
        .menu-loading-ring::before {
            content: "";
            position: absolute;
            inset: -1px;
            border-radius: inherit;
            border: 3px solid transparent;
            border-top-color: #A04423;
            border-right-color: rgba(160, 68, 35, .35);
            animation: menuSpin 950ms linear infinite;
        }
        .menu-loading-ring::after {
            content: "";
            position: absolute;
            inset: 20px;
            border-radius: inherit;
            background: #FAF7EE;
            border: 1px solid #E5DEC9;
        }
        .menu-loading-bar {
            overflow: hidden;
            position: relative;
        }
        .menu-loading-bar::after {
            content: "";
            position: absolute;
            inset: 0;
            width: 42%;
            border-radius: inherit;
            background: linear-gradient(90deg, transparent, #A04423, transparent);
            animation: menuLoadSweep 1.35s ease-in-out infinite;
        }
        @keyframes menuSpin {
            to { transform: rotate(360deg); }
        }
        @keyframes menuLoadSweep {
            0% { transform: translateX(-110%); }
            100% { transform: translateX(260%); }
        }
        @keyframes menuLoaderFloat {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-6px); }
        }
    </style>
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

            if (role && waiterPages.indexOf(page) !== -1 && role !== 'waiter' && role !== 'manager') {
                try { alert('Cảnh báo bảo mật: Bạn không có quyền truy cập khu vực Phục vụ / Wait station!'); } catch(e) { console.warn(e); }
                window.location.href = 'login.jsp';
                return;
            }
            if (role && baristaPages.indexOf(page) !== -1 && role !== 'barista' && role !== 'manager') {
                try { alert('Cảnh báo bảo mật: Bạn không có quyền truy cập khu vực Quầy pha chế (KDS)!'); } catch(e) { console.warn(e); }
                window.location.href = 'login.jsp';
                return;
            }
            if (role && managerPages.indexOf(page) !== -1 && role !== 'manager') {
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
                            '<a href="order-status.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'order-status.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Kiểm tra đơn nước</a>' +
                            '<a href="member.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'member.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Khách thành viên</a>';
                    } else if (role === 'waiter') {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors">Trang chủ</a>' +
                            '<a href="waitstation.jsp" class="hover:text-coffee-rust transition-colors font-semibold">Wait station</a>' +
                            '<a href="staff-orders.jsp" class="hover:text-coffee-rust transition-colors">Danh sách order</a>' +
                            '<a href="table-qr.jsp" class="hover:text-coffee-rust transition-colors">In mã QR bàn</a>';
                    } else if (role === 'barista') {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors">Trang chủ</a>' +
                            '<a href="kds.jsp" class="hover:text-coffee-rust transition-colors font-semibold">KDS pha chế</a>';
                    } else if (role === 'manager') {
                        navHtml = 
                            '<a href="index.html" class="hover:text-coffee-rust transition-colors">Trang chủ</a>' +
                            '<a href="dashboard.jsp" class="hover:text-coffee-rust transition-colors">Dashboard</a>' +
                            '<a href="reports.jsp" class="hover:text-coffee-rust transition-colors">Doanh số</a>' +
                            '<a href="staff-management.jsp" class="hover:text-coffee-rust transition-colors">Nhân sự</a>' +
                            '<a href="inventory.jsp" class="hover:text-coffee-rust transition-colors">Kho hàng</a>' +
                           '<div class="relative group">' +
                               '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
                                   '<span>Thao tác trực</span>' +
                                   '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
                               '</button>' +
                               '<div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
                                '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Kho nguyên liệu</a>' +
                                
                                    '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Kho nguyên liệu</a>' +
                                    '<a href="waitstation.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Wait station</a>' +
                                   '<a href="kds.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">KDS pha chế</a>' +
                                   '<a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Danh sách order</a>' +
                                   '<a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">In mã QR bàn</a>' +
                                   '<a href="menu.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Giao diện khách</a>' +
                               '</div>' +
                           '</div>';
                    }
                } else if (role === 'waiter' || waiterPages.indexOf(page) !== -1) {
                    navHtml = 
                        '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                        '<a href="waitstation.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'waitstation.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">Wait station</a>' +
                        '<a href="staff-orders.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'staff-orders.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Danh sách order</a>' +
                        '<a href="table-qr.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'table-qr.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">In mã QR bàn</a>';
                } else if (role === 'barista' || baristaPages.indexOf(page) !== -1) {
                    navHtml = 
                        '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                        '<a href="kds.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'kds.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">KDS pha chế</a>';
                } else if (role === 'manager' || managerPages.indexOf(page) !== -1) {
                    navHtml = 
                        '<a href="index.html" class="hover:text-coffee-rust transition-colors ' + (page === 'index.html' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Trang chủ</a>' +
                        '<a href="dashboard.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'dashboard.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">Dashboard</a>' +
                        '<a href="reports.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'reports.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Doanh số</a>' +
                        '<a href="staff-management.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'staff-management.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Nhân sự</a>' +
                        '<a href="inventory.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'inventory.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + '">Kho hàng</a>' +
                        '<div class="relative group">' +
                            '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
                                '<span>Thao tác trực</span>' +
                                '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
                            '</button>' +
                            '<div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
                                '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Kho nguyên liệu</a>' +
                                
                                    '<a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Kho nguyên liệu</a>' +
                                    '<a href="waitstation.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Wait station</a>' +
                                '<a href="kds.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">KDS pha chế</a>' +
                                '<a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Danh sách order</a>' +
                                '<a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">In mã QR bàn</a>' +
                                '<a href="menu.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Giao diện khách</a>' +
                            '</div>' +
                        '</div>';
                }
                navContainer.innerHTML = navHtml;

                var rightNavArea = document.querySelector('nav div.flex.items-center.gap-3 div.flex.items-center.gap-1\\.5') || document.querySelector('nav div.flex.items-center.gap-3');
                if (rightNavArea && role) {
                    var roleBadge = '';
                    if (role === 'manager') roleBadge = 'Quản lý';
                    else if (role === 'waiter') roleBadge = 'Phục vụ';
                    else if (role === 'barista') roleBadge = 'Pha chế';

                    var badgeHtml = 
                        '<div class="flex items-center gap-2">' +
                            '<div class="bg-coffee-dark text-coffee-bg border border-coffee-rust/30 px-3.5 py-1.5 rounded-xl text-[10px] uppercase font-bold font-mono tracking-wide flex items-center gap-1.5 shadow-xs">' +
                                '<span class="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping"></span>' +
                                '<span>' + roleBadge + ': ' + user + '</span>' +
                            '</div>' +
                            '<button onclick="handleLocalLogout()" class="text-xs font-bold px-2 py-1.5 bg-red-50 hover:bg-red-500 hover:text-white border border-red-200 text-red-600 rounded-xl shadow-xs transition-all cursor-pointer">' +
                                'Đăng xuất' +
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
    <link rel="stylesheet" href="assets/css/pro-ui.css">
    <script defer src="assets/js/ui-polish.js"></script>
</head>
<body class="menu-loading min-h-screen flex flex-col dot-grid-bg relative selection:bg-coffee-rust/20 selection:text-coffee-rust">

    <div id="menu-loading-screen" class="menu-loading-screen fixed inset-0 z-[9999] bg-coffee-bg dot-grid-bg flex items-center justify-center p-6">
        <div class="menu-loading-card w-full max-w-sm bg-white border border-coffee-sand rounded-3xl shadow-xl p-7 text-center space-y-5">
            <div class="mx-auto menu-loading-ring"></div>
            <div class="space-y-2">
                <p class="font-serif text-3xl font-bold text-coffee-dark" data-i18n="loadingTitle">Đang tải menu</p>
                <p id="menu-loading-status" class="text-xs text-coffee-milk leading-5">
                    Đang tải món và bàn.
                </p>
            </div>
            <div class="menu-loading-bar h-1.5 rounded-full bg-coffee-light border border-coffee-sand/70"></div>
        </div>
    </div>

    <nav class="border-b border-coffee-sand/70 bg-coffee-bg/90 backdrop-blur sticky top-0 z-40 px-6 py-4 transition-all">
        <div class="max-w-7xl mx-auto flex items-center justify-between">
            
            <a href="index.html" class="flex items-center gap-2 group">
                <span class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark select-none">
                    nhà cà phê<span class="text-coffee-rust">.</span>
                </span>
            </a>

            <div class="hidden lg:flex items-center gap-4 text-xs font-medium">
                <a href="index.html" class="hover:text-coffee-rust transition-colors text-coffee-milk" data-i18n="navHome">Trang chủ</a>
                <a href="menu.jsp" class="hover:text-coffee-rust transition-colors text-coffee-dark font-bold" data-i18n="navGuestOrder">Khách gọi món</a>
                <a href="order-status.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk" data-i18n="navOrderStatus">Kiểm tra đơn nước</a>
                <a href="member.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk" data-i18n="navMember">Khách thành viên</a>
            </div>

            <div class="flex items-center gap-3">
                
                <div id="connection-status">
                    <div class="bg-amber-50 text-amber-800 border border-amber-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-medium">
                        <span class="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse"></span>
                <span data-i18n="syncLoading">Đang tải...</span>
                    </div>
                </div>

                <div id="menu-language-toggle" class="flex items-center gap-1 bg-white border border-coffee-sand rounded-full p-0.5 shadow-xs">
                    <button id="lang-vi-btn" type="button" onclick="setMenuLanguage('vi')" class="text-[10px] font-bold px-2 py-1 rounded-full transition-all">VI</button>
                    <button id="lang-en-btn" type="button" onclick="setMenuLanguage('en')" class="text-[10px] font-bold px-2 py-1 rounded-full transition-all">EN</button>
                </div>

                <div class="hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>

                <div class="flex items-center gap-1.5">
                    <a href="javascript:history.back()" class="text-xs font-bold px-3 py-1.5 bg-white hover:bg-coffee-rust hover:text-white border border-coffee-sand rounded-xl shadow-xs transition-all pointer">
                        <span data-i18n="back">Quay lại</span>
                    </a>
                </div>

            </div>
        </div>
    </nav>

    <div id="flash-banner-container" class="hidden fixed bottom-6 right-6 z-50 max-w-sm w-full animate-bounce">
        <div id="flash-banner" class="bg-coffee-dark text-white border border-coffee-rust/50 px-4 py-3 rounded-2xl flex items-center gap-2.5 shadow-xl">
            <div class="w-8 h-8 rounded-full bg-coffee-rust flex items-center justify-center shrink-0">
                ☕
            </div>
            <div class="flex-1 text-xs">
                <p id="flash-message" class="font-medium text-coffee-bg" data-i18n="flashDefault">Đã cập nhật đơn.</p>
            </div>
        </div>
    </div>

    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col justify-start">

<div class="space-y-6">
    <div id="ordering-warning-banner" class="hidden"></div>
    <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="space-y-1">
            <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                <span>☕</span> <span data-i18n="menuTitle">Gọi món tại bàn</span>
            </h2>
            <p class="text-xs text-coffee-milk font-medium" data-i18n="menuSubtitle">Chọn món, gửi đơn, chờ nhân viên mang tới.</p>
        </div>

        <div id="table-seating-container" class="flex items-center gap-3 bg-coffee-light border border-coffee-sand px-3 py-2 rounded-2xl">
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        
        <div class="lg:col-span-2 space-y-4">
            <div class="flex flex-col sm:flex-row items-center gap-3 bg-white border border-coffee-sand p-3.5 rounded-2xl shadow-xs">
                <div class="flex flex-wrap gap-1.5 w-full sm:w-auto overflow-x-auto" id="cust-categories">
                    <button onclick="setCustMenuCategory('All')" id="custcat-all" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-rust text-white rounded-lg">Tất cả</button>
                    <button onclick="setCustMenuCategory('Coffee')" id="custcat-coffee" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Cà phê</button>
                    <button onclick="setCustMenuCategory('Tea')" id="custcat-tea" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Trà</button>
                    <button onclick="setCustMenuCategory('Specialty')" id="custcat-specialty" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Đặc biệt</button>
                    <button onclick="setCustMenuCategory('Pastry')" id="custcat-pastry" class="text-[11px] font-bold px-3 py-1.5 bg-coffee-light border border-coffee-sand/70 text-coffee-milk rounded-lg hover:border-coffee-rust transition-all">Bánh</button>
                </div>
                <div class="relative w-full sm:flex-1">
                    <input type="text" id="cust-search" oninput="drawCustMenuList()" placeholder="Tìm món..." data-i18n-placeholder="searchPlaceholder" class="w-full text-xs px-3 py-2 pl-8 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust focus:bg-white">
                    <svg class="w-3.5 h-3.5 text-coffee-milk absolute left-2.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
            </div>

            <div id="cust-menu-container" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            </div>
        </div>

        <div class="space-y-6">
            
            <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4">
                <div class="flex items-center justify-between border-b border-coffee-sand/60 pb-3">
                    <div>
                        <h3 class="font-serif italic font-bold text-base text-coffee-dark" data-i18n="cartTitle">Giỏ hàng của bạn</h3>
                        <p class="text-[10px] text-coffee-milk" data-i18n="cartSubtitle">Món đã chọn.</p>
                    </div>
                    <span id="cart-item-count" class="text-[10px] font-mono font-bold bg-coffee-rust text-white px-2.5 py-0.5 rounded-full">
                        0 món
                    </span>
                </div>

                <div id="guest-cart-container" class="space-y-3 max-h-[300px] overflow-y-auto pr-1">
                </div>

                <div class="border-t border-coffee-sand/60 pt-4 space-y-3">
                    <div>
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block mb-1" data-i18n="orderNoteLabel">Ghi chú pha chế riêng</label>
                        <textarea id="guest-order-notes" placeholder="Ghi chú cho quán..." data-i18n-placeholder="orderNotePlaceholder" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl h-14 focus:outline-none focus:border-coffee-rust focus:bg-white"></textarea>
                    </div>

                    <div id="cart-membership-section" class="bg-coffee-light/60 border border-coffee-sand/70 p-3.5 rounded-2xl text-xs">
                    </div>

                    <div class="bg-[#FAF7EE] border border-coffee-sand/80 px-4 py-3 rounded-2xl flex items-center justify-between">
                        <span class="text-xs font-bold text-coffee-milk" data-i18n="totalLabel">Thành tiền:</span>
                        <span id="guest-cart-total" class="font-mono font-bold text-sm text-coffee-rust">0 ₫</span>
                    </div>

                    <button onclick="submitGuestTicket()" class="w-full bg-coffee-rust text-white font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all cursor-pointer flex justify-center items-center gap-1.5 shadow-sm">
                        <span data-i18n="submitOrder">Gửi đơn</span>
                    </button>
                    
                    <a href="order-status.jsp" class="block w-full text-center text-xs font-bold font-mono text-coffee-rust hover:underline">
                        <span data-i18n="orderDetailLink">Xem trạng thái đơn</span>
                    </a>
                </div>
            </div>

            <div id="guest-history-card" class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4 hidden">
                <div class="border-b border-coffee-sand pb-2">
                    <h4 class="font-serif italic font-bold text-sm text-coffee-dark"><span data-i18n="historyTitlePrefix">Trạng thái pha chế tại</span> <span id="history-table-label" class="text-coffee-rust">Bàn --</span></h4>
                    <p class="text-[9.5px] text-coffee-milk" data-i18n="historySubtitle">Theo dõi đơn vừa gọi.</p>
                </div>
                <div id="guest-history-container" class="space-y-3">
                </div>
            </div>

        </div>

    </div>
</div>

<div id="table-setup-modal" class="fixed inset-0 bg-coffee-dark/55 z-50 hidden items-center justify-center p-4">
    <div class="bg-white border border-coffee-sand rounded-3xl p-6 max-w-lg w-full shadow-2xl space-y-5">
        <div class="space-y-1">
            <p class="text-[10px] uppercase font-bold font-mono tracking-wider text-coffee-milk" data-i18n="tableModalEyebrow">Chọn bàn gọi món</p>
            <h3 class="text-2xl font-serif font-bold text-coffee-dark" data-i18n="tableModalTitle">Bạn đang ngồi bàn nào?</h3>
            <p class="text-xs text-coffee-milk leading-5" data-i18n="tableModalSubtitle">Chọn đúng bàn để nhân viên mang món tới.</p>
        </div>

        <div class="grid grid-cols-2 gap-2">
            <button type="button" onclick="showTableSetupPanel('manual')" id="table-setup-manual-tab" class="bg-coffee-rust text-white border border-coffee-rust text-xs font-bold py-2.5 rounded-xl transition-all">
                <span data-i18n="manualChoose">Chọn thủ công</span>
            </button>
            <button type="button" onclick="showTableSetupPanel('scan')" id="table-setup-scan-tab" class="bg-white text-coffee-dark border border-coffee-sand text-xs font-bold py-2.5 rounded-xl transition-all">
                <span data-i18n="scanQr">Quét mã QR</span>
            </button>
        </div>

        <div id="table-setup-manual-panel" class="space-y-3">
            <label class="text-[10px] font-bold uppercase font-mono tracking-wider text-coffee-milk block" data-i18n="tableSelectLabel">Số bàn hiện tại</label>
            <select id="table-setup-select" class="w-full text-sm font-bold px-4 py-3 bg-white border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust">
            </select>
            <button type="button" onclick="confirmManualTableSelection()" class="w-full bg-coffee-rust text-white font-bold py-3 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 transition-all">
                <span data-i18n="confirmTable">Xác nhận bàn</span>
            </button>
        </div>

        <div id="table-setup-scan-panel" class="hidden space-y-3">
            <div class="bg-coffee-light border border-coffee-sand rounded-2xl p-3">
                <video id="table-qr-video" class="w-full aspect-video rounded-xl bg-coffee-dark object-cover" autoplay muted playsinline></video>
            </div>
                <p id="table-qr-status" class="text-xs text-coffee-milk leading-5" data-i18n="qrStatusIdle">Đưa camera vào mã QR trên bàn.</p>
            <div class="grid grid-cols-2 gap-2">
                <button type="button" onclick="startQrTableScanner()" class="bg-coffee-rust text-white font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider">
                    <span data-i18n="startScan">Bắt đầu quét</span>
                </button>
                <button type="button" onclick="stopQrTableScanner()" class="bg-white text-coffee-dark border border-coffee-sand font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider">
                    <span data-i18n="stopCamera">Tắt camera</span>
                </button>
            </div>
            <div class="border-t border-coffee-sand/70 pt-3 space-y-2">
                <label class="text-[10px] font-bold uppercase font-mono tracking-wider text-coffee-milk block" data-i18n="qrPasteLabel">Dán link QR nếu trình duyệt không hỗ trợ quét</label>
                <div class="flex gap-2">
                    <input id="table-qr-manual-input" type="text" placeholder="menu.jsp?tableCode=TBL-ABC123" class="flex-1 text-xs px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                    <button type="button" onclick="applyQrTextFromInput()" class="bg-coffee-dark text-white text-xs font-bold px-3 rounded-xl" data-i18n="useQrText">Dùng</button>
                </div>
            </div>
        </div>

        <button type="button" onclick="closeTableSetupModal()" class="w-full bg-coffee-light text-coffee-milk border border-coffee-sand font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider">
            <span data-i18n="viewOnly">Chỉ xem menu, chưa gọi món</span>
        </button>
    </div>
</div>

<div id="waiter-confirmation-modal" class="fixed inset-0 bg-coffee-dark/50 z-50 hidden items-center justify-center p-4">
    <div class="bg-[#FAF7EE] border border-coffee-sand rounded-3xl p-6 max-w-sm w-full shadow-2xl relative">
        <button onclick="closeWaiterConfirmationModal()" class="absolute top-4 right-4 text-coffee-milk hover:text-coffee-dark text-xl transition-colors cursor-pointer">
            ✕
        </button>
        
        <div class="space-y-4">
            <div class="text-center pb-2 border-b border-coffee-sand/80">
                <span class="text-2xl">🔑</span>
                <h3 class="text-lg font-serif italic font-bold text-coffee-dark" data-i18n="waiterModalTitle">Phục vụ xác nhận đổi bàn</h3>
                <p class="text-[11px] text-coffee-milk" data-i18n="waiterModalSubtitle">Nhập PIN để đổi bàn.</p>
            </div>
            
            <div class="space-y-1">
                <label class="text-[10px] font-bold uppercase text-coffee-rust block" data-i18n="waiterSelectLabel">Nhân viên xác nhận:</label>
                <select id="modal-waiter-select" class="w-full text-xs font-bold px-3 py-2 bg-white border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust outline-none cursor-pointer">
                </select>
            </div>

            <div class="space-y-1">
                <label class="text-[10px] font-bold uppercase text-coffee-rust block" data-i18n="targetTableLabel">Chọn bàn muốn chuyển đến:</label>
                <select id="modal-target-table-select" class="w-full text-xs font-bold px-3 py-2 bg-white border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust outline-none cursor-pointer">
                </select>
            </div>

            <div class="space-y-1.5 text-center">
                <label class="text-[10px] font-bold uppercase text-coffee-rust block" data-i18n="pinLabel">Mã PIN nhân viên (4 số):</label>
                <input type="password" id="modal-waiter-pin" readonly maxlength="4" placeholder="••••" class="w-32 mx-auto text-center text-lg font-mono font-bold tracking-[0.5em] px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust outline-none font-medium">
            </div>

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
                <button onclick="clearModalPin()" class="bg-red-50 hover:bg-red-100 text-red-600 font-bold py-2 rounded-xl border border-red-100 text-[10px] active:scale-95 transition-all cursor-pointer flex items-center justify-center" data-i18n="clear">Xóa</button>
                <button onclick="tapModalPin('0')" class="bg-white hover:bg-coffee-sand/20 text-coffee-dark font-bold font-mono py-2 rounded-xl border border-coffee-sand/60 text-sm active:scale-95 transition-all cursor-pointer">0</button>
                <button onclick="popModalPin()" class="bg-coffee-light hover:bg-coffee-sand/40 text-coffee-milk font-bold py-2 rounded-xl border border-coffee-sand/60 text-[10px] active:scale-95 transition-all cursor-pointer flex items-center justify-center">⌫</button>
            </div>

            <button onclick="confirmWaiterTableSwap()" class="w-full bg-coffee-rust hover:bg-coffee-rust/95 text-white font-bold py-2.5 px-4 rounded-xl text-xs uppercase tracking-wider active:scale-[0.98] transition-all cursor-pointer text-center shadow-xs">
                <span data-i18n="confirmTableSwap">Xác nhận đổi bàn</span>
            </button>
        </div>
    </div>
</div>

<div id="customization-modal" class="fixed inset-0 bg-coffee-dark/50 z-50 hidden items-center justify-center p-4">
    <div class="bg-[#FAF7EE] border border-coffee-sand rounded-3xl p-6 max-w-sm w-full shadow-2xl relative">
        <button onclick="closeCustomizationModal()" class="absolute top-4 right-4 text-coffee-milk hover:text-coffee-dark text-xl transition-colors cursor-pointer">
            ✕
        </button>
        
        <div id="modal-product-header" class="space-y-1 pr-6 pb-4 border-b border-coffee-sand/80">
        </div>

        <div class="py-4 space-y-4">
            <div class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide" data-i18n="sizeLabel">Kích cỡ đồ uống</label>
                <div id="modal-size-container" class="grid grid-cols-3 gap-2">
                </div>
            </div>

            <div id="modal-sugar-wrapper" class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide" data-i18n="sugarLabel">Độ ngọt</label>
                <div class="grid grid-cols-5 gap-1.5" id="modal-sugar-container">
                </div>
            </div>

            <div id="modal-ice-wrapper" class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide" data-i18n="iceLabel">Lượng đá</label>
                <div class="grid grid-cols-4 gap-1.5" id="modal-ice-container">
                </div>
            </div>

            <div class="space-y-1.5">
                <label class="text-[11px] font-bold uppercase text-coffee-milk tracking-wide" data-i18n="extraNoteLabel">Yêu cầu thêm</label>
                <input type="text" id="modal-notes-input" placeholder="Ghi chú..." data-i18n-placeholder="shortNotePlaceholder" class="w-full text-xs px-3 py-2 bg-white border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
            </div>
        </div>

        <div class="flex items-center gap-3 pt-3 border-t border-coffee-sand/80">
            <div class="flex items-center gap-2">
                <button onclick="changeModalQty(-1)" class="w-8 h-8 rounded-full border border-coffee-sand bg-white flex items-center justify-center font-bold text-coffee-dark hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">-</button>
                <span id="modal-qty-label" class="font-mono text-sm font-bold w-4 text-center">1</span>
                <button onclick="changeModalQty(1)" class="w-8 h-8 rounded-full border border-coffee-sand bg-white flex items-center justify-center font-bold text-coffee-dark hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">+</button>
            </div>
            
            <button id="modal-action-btn" onclick="confirmProductCustomization()" class="flex-1 bg-coffee-rust text-white font-bold py-2.5 px-4 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-colors cursor-pointer text-center">
                <span data-i18n="addToCart">Thêm vào giỏ</span>
            </button>
        </div>
    </div>
</div>

<script>
    let menu = [];
    let tables = [];
    let orders = [];

    let customerCategory = 'All';
    const urlParams = new URLSearchParams(window.location.search);
    const urlTableId = urlParams.get('tableId');
    const urlTableCode = urlParams.get('tableCode');
    const authRole = localStorage.getItem('auth_role') || '';
    const isStaffUser = (authRole === 'waiter' || authRole === 'manager');

    let userSittingTableId = '';
    if (urlTableId) {
        userSittingTableId = urlTableId;
        localStorage.setItem('user_sitting_table_id', urlTableId);
        localStorage.setItem('table_selection_confirmed', 'true');
    } else {
        if (isStaffUser) {
            userSittingTableId = localStorage.getItem('user_sitting_table_id') || 't1';
        } else {
            userSittingTableId = localStorage.getItem('user_sitting_table_id') || '';
        }
    }
    let custCartItems = [];

    let modalActiveProduct = null;
    let modalSize = 'M';
    let modalSugar = '100%';
    let modalIce = '100%';
    let modalQty = 1;

    let socket = null;
    let tableSetupPromptShown = false;
    let initialMenuLoadDone = false;
    const menuLoadStartedAt = Date.now();
    let qrStream = null;
    let qrScanTimer = null;
    let qrDetector = null;

    const LANGUAGE_STORAGE_KEY = 'app_language';
    const supportedLanguages = ['vi', 'en'];
    let menuLanguage = normalizeLanguage(localStorage.getItem(LANGUAGE_STORAGE_KEY) || 'vi');

    const menuText = {
        vi: {
            pageTitle: 'nhà cà phê. — gọi món',
            loadingTitle: 'Đang tải menu',
            loadingMenuTables: 'Đang tải món và bàn.',
            loadingCheckHours: 'Đang kiểm tra giờ mở bán.',
            loadingOrders: 'Đang tải đơn của bạn.',
            loadingRetry: 'Chưa tải được. Đang thử lại.',
            loadingReady: 'Menu đã sẵn sàng.',
            syncLoading: 'Đang tải...',
            syncReady: 'Đã cập nhật',
            syncOffline: 'Mất kết nối',
            flashDefault: 'Đã cập nhật đơn.',
            navHome: 'Trang chủ',
            navGuestOrder: 'Khách gọi món',
            navOrderStatus: 'Kiểm tra đơn nước',
            navMember: 'Khách thành viên',
            navDashboard: 'Dashboard',
            navReports: 'Doanh số',
            navStaff: 'Nhân sự',
            navInventory: 'Kho hàng',
            navOperation: 'Vận hành',
            navWaitstation: 'Wait station',
            navPos: 'Thu ngân POS',
            navKds: 'KDS pha chế',
            navStaffOrders: 'Danh sách order',
            navQr: 'In mã QR bàn',
            back: 'Quay lại',
            menuTitle: 'Gọi món tại bàn',
            menuSubtitle: 'Chọn món, gửi đơn, chờ nhân viên mang tới.',
            searchPlaceholder: 'Tìm món...',
            cartTitle: 'Giỏ hàng của bạn',
            cartSubtitle: 'Món đã chọn.',
            orderNoteLabel: 'Ghi chú pha chế riêng',
            orderNotePlaceholder: 'Ghi chú cho quán...',
            totalLabel: 'Thành tiền:',
            submitOrder: 'Gửi đơn',
            orderDetailLink: 'Xem trạng thái đơn',
            historyTitlePrefix: 'Trạng thái pha chế tại',
            historySubtitle: 'Theo dõi đơn vừa gọi.',
            tableModalEyebrow: 'Chọn bàn gọi món',
            tableModalTitle: 'Bạn đang ngồi bàn nào?',
            tableModalSubtitle: 'Chọn đúng bàn để nhân viên mang món tới.',
            manualChoose: 'Chọn thủ công',
            scanQr: 'Quét mã QR',
            tableSelectLabel: 'Số bàn hiện tại',
            confirmTable: 'Xác nhận bàn',
            qrStatusIdle: 'Đưa camera vào mã QR trên bàn.',
            startScan: 'Bắt đầu quét',
            stopCamera: 'Tắt camera',
            qrPasteLabel: 'Dán link QR nếu trình duyệt không hỗ trợ quét',
            useQrText: 'Dùng',
            viewOnly: 'Chỉ xem menu, chưa gọi món',
            waiterModalTitle: 'Phục vụ xác nhận đổi bàn',
            waiterModalSubtitle: 'Nhập PIN để đổi bàn.',
            waiterSelectLabel: 'Nhân viên xác nhận:',
            targetTableLabel: 'Chọn bàn muốn chuyển đến:',
            pinLabel: 'Mã PIN nhân viên (4 số):',
            clear: 'Xóa',
            confirmTableSwap: 'Xác nhận đổi bàn',
            sizeLabel: 'Kích cỡ đồ uống',
            sugarLabel: 'Độ ngọt',
            iceLabel: 'Lượng đá',
            extraNoteLabel: 'Yêu cầu thêm',
            shortNotePlaceholder: 'Ghi chú...',
            addToCart: 'Thêm vào giỏ',
            noResults: 'Không tìm thấy món phù hợp.',
            outOfStock: 'Tạm hết hàng',
            outOfStockToast: 'Món này hiện tạm hết.',
            sizes: 'Cỡ',
            staffMode: 'NHÂN VIÊN',
            currentTableStaff: 'BÀN ĐANG SỬ DỤNG:',
            currentTableGuest: 'BÀN GỌI MÓN:',
            chooseTable: 'Chọn bàn',
            qrShort: 'Quét QR',
            tableHint: 'Đơn sẽ gửi đúng tới bàn bạn chọn.',
            unknownTable: 'Chưa rõ',
            tablePlaceholder: 'Bàn --',
            manager: 'Quản lý',
            waiter: 'Phục vụ',
            selectedHere: 'Đang ngồi tại đây',
            manualSource: 'chọn thủ công',
            qrSource: 'quét QR',
            tableSelected: 'Đã chọn {table} bằng {source}.',
            chooseTableFirst: 'Vui lòng chọn bàn trước khi gọi món.',
            tableNotFound: 'Không tìm thấy bàn này.',
            qrNotFound: 'Không tìm thấy mã bàn từ QR. Vui lòng chọn bàn thủ công.',
            qrInvalid: 'Không đọc được mã bàn từ QR này. Mã cần có dạng menu.jsp?tableCode=TBL-XXXXXX.',
            cameraNotAllowed: 'Trình duyệt chưa cho phép mở camera. Bạn có thể chọn bàn thủ công hoặc dán link QR.',
            qrUnsupported: 'Trình duyệt chưa hỗ trợ đọc QR trực tiếp. Hãy dùng Chrome/Edge mới, hoặc chọn bàn thủ công.',
            qrScanning: 'Đang quét QR. Đưa camera vào tem QR trên bàn.',
            cameraOpenFailed: 'Không mở được camera. Hãy cấp quyền camera hoặc chọn bàn thủ công.',
            shopClosed: 'Quán đang tạm đóng',
            timeClosed: 'Quán tạm ngưng nhận đơn sau 22:00',
            orderPausedTitle: 'Tạm ngưng nhận đơn',
            orderPausedBody: '{reason}. Bạn vẫn có thể xem menu và kiểm tra đơn đã gọi.',
            unitPrice: 'Đơn giá',
            originalPrice: 'Giá gốc',
            sizePrefix: 'Cỡ',
            addToCartPrice: 'Thêm vào giỏ - {price}',
            noSugar: 'Không đường',
            warm: 'Ấm',
            addedToCart: 'Đã thêm vào giỏ.',
            memberQuestion: 'Bạn là thành viên?',
            loginVoucher: 'Đăng nhập áp voucher',
            memberLabel: 'Hội viên:',
            memberPoints: 'hạt',
            noVoucher: 'Hội viên chưa có voucher.',
            goRedeemVoucher: 'Vào đổi voucher',
            chooseVoucher: 'Chọn voucher giảm giá:',
            noVoucherOption: '-- Không áp dụng voucher --',
            discount: 'Giảm',
            itemCountSuffix: 'món',
            cartEmpty: 'Giỏ hàng đang trống. Chọn món bạn thích nhé.',
            sweet: 'Ngọt',
            ice: 'Đá',
            noteQuote: '"{note}"',
            orderPausedAlert: 'Quán đang tạm ngưng nhận đơn. Bạn có thể xem menu hoặc kiểm tra đơn đã gọi.',
            tableRequiredAlert: 'Vui lòng chọn bàn trước khi gửi đơn.',
            emptyCartAlert: 'Vui lòng chọn ít nhất một món.',
            orderSuccess: 'Gọi món thành công. Mã đơn của bạn là số {order}.',
            orderError: 'Chưa gửi được đơn.',
            pending: 'Đợi duyệt',
            preparing: 'Đang pha chế',
            ready: 'Sẵn sàng',
            served: 'Đã phục vụ',
            counter: 'Đầu quầy',
            complete: 'Hoàn thành',
            orderNumber: 'Mã đơn',
            tableSameAlert: 'Bàn đích trùng với bàn hiện tại.',
            pinWrong: 'Mã PIN không đúng. Vui lòng thử lại.',
            movedTable: 'Đã chuyển khách sang {table} ({staff} xác nhận).'
        },
        en: {
            pageTitle: 'nhà cà phê. — order',
            loadingTitle: 'Loading menu',
            loadingMenuTables: 'Loading menu and tables.',
            loadingCheckHours: 'Checking opening hours.',
            loadingOrders: 'Loading your order.',
            loadingRetry: 'Could not load. Retrying.',
            loadingReady: 'Menu is ready.',
            syncLoading: 'Loading...',
            syncReady: 'Updated',
            syncOffline: 'Offline',
            flashDefault: 'Order updated.',
            navHome: 'Home',
            navGuestOrder: 'Guest order',
            navOrderStatus: 'Check order',
            navMember: 'Member',
            navDashboard: 'Dashboard',
            navReports: 'Sales',
            navStaff: 'Staff',
            navInventory: 'Inventory',
            navOperation: 'Operations',
            navWaitstation: 'Wait station',
            navPos: 'POS',
            navKds: 'Kitchen display',
            navStaffOrders: 'Orders',
            navQr: 'Table QR',
            back: 'Back',
            menuTitle: 'Order at table',
            menuSubtitle: 'Choose items, send the order, and wait for service.',
            searchPlaceholder: 'Search items...',
            cartTitle: 'Your cart',
            cartSubtitle: 'Selected items.',
            orderNoteLabel: 'Order note',
            orderNotePlaceholder: 'Note for the shop...',
            totalLabel: 'Total:',
            submitOrder: 'Send order',
            orderDetailLink: 'View order status',
            historyTitlePrefix: 'Order status at',
            historySubtitle: 'Track your latest order.',
            tableModalEyebrow: 'Choose table',
            tableModalTitle: 'Which table are you at?',
            tableModalSubtitle: 'Choose the right table so staff can serve you.',
            manualChoose: 'Choose manually',
            scanQr: 'Scan QR',
            tableSelectLabel: 'Current table',
            confirmTable: 'Confirm table',
            qrStatusIdle: 'Point the camera at the table QR.',
            startScan: 'Start scan',
            stopCamera: 'Stop camera',
            qrPasteLabel: 'Paste QR link if scan is not supported',
            useQrText: 'Use',
            viewOnly: 'View menu only',
            waiterModalTitle: 'Staff confirms table change',
            waiterModalSubtitle: 'Enter PIN to change table.',
            waiterSelectLabel: 'Confirming staff:',
            targetTableLabel: 'Move to table:',
            pinLabel: 'Staff PIN (4 digits):',
            clear: 'Clear',
            confirmTableSwap: 'Confirm table change',
            sizeLabel: 'Drink size',
            sugarLabel: 'Sweetness',
            iceLabel: 'Ice level',
            extraNoteLabel: 'Extra note',
            shortNotePlaceholder: 'Note...',
            addToCart: 'Add to cart',
            noResults: 'No matching items found.',
            outOfStock: 'Out of stock',
            outOfStockToast: 'This item is currently out of stock.',
            sizes: 'Sizes',
            staffMode: 'STAFF',
            currentTableStaff: 'ACTIVE TABLE:',
            currentTableGuest: 'ORDER TABLE:',
            chooseTable: 'Choose table',
            qrShort: 'Scan QR',
            tableHint: 'The order will be sent to your selected table.',
            unknownTable: 'Unknown',
            tablePlaceholder: 'Table --',
            manager: 'Manager',
            waiter: 'Waiter',
            selectedHere: 'Currently selected',
            manualSource: 'manual selection',
            qrSource: 'QR scan',
            tableSelected: 'Selected {table} by {source}.',
            chooseTableFirst: 'Please choose your table before ordering.',
            tableNotFound: 'Table not found.',
            qrNotFound: 'QR table code not found. Please choose manually.',
            qrInvalid: 'Cannot read this table QR. It should look like menu.jsp?tableCode=TBL-XXXXXX.',
            cameraNotAllowed: 'This browser has not allowed camera access. Choose manually or paste the QR link.',
            qrUnsupported: 'This browser cannot scan QR codes directly. Use a newer Chrome/Edge or choose manually.',
            qrScanning: 'Scanning QR. Point the camera at the table QR.',
            cameraOpenFailed: 'Cannot open camera. Allow camera permission or choose manually.',
            shopClosed: 'The shop is temporarily closed',
            timeClosed: 'Ordering pauses after 22:00',
            orderPausedTitle: 'Ordering paused',
            orderPausedBody: '{reason}. You can still view the menu and check existing orders.',
            unitPrice: 'Unit price',
            originalPrice: 'Base price',
            sizePrefix: 'Size',
            addToCartPrice: 'Add to cart - {price}',
            noSugar: 'No sugar',
            warm: 'Warm',
            addedToCart: 'Added to cart.',
            memberQuestion: 'Are you a member?',
            loginVoucher: 'Log in for voucher',
            memberLabel: 'Member:',
            memberPoints: 'beans',
            noVoucher: 'No vouchers available.',
            goRedeemVoucher: 'Redeem voucher',
            chooseVoucher: 'Choose discount voucher:',
            noVoucherOption: '-- No voucher --',
            discount: 'Discount',
            itemCountSuffix: 'items',
            cartEmpty: 'Your cart is empty. Pick something you like.',
            sweet: 'Sweet',
            ice: 'Ice',
            noteQuote: '"{note}"',
            orderPausedAlert: 'Ordering is paused. You can view the menu or check existing orders.',
            tableRequiredAlert: 'Please choose a table before sending the order.',
            emptyCartAlert: 'Please choose at least one item.',
            orderSuccess: 'Order sent. Your order number is {order}.',
            orderError: 'Could not send the order.',
            pending: 'Pending',
            preparing: 'Preparing',
            ready: 'Ready',
            served: 'Served',
            counter: 'Counter',
            complete: 'Complete',
            orderNumber: 'Order',
            tableSameAlert: 'Target table is the same as current table.',
            pinWrong: 'Incorrect PIN. Please try again.',
            movedTable: 'Moved guest to {table} (confirmed by {staff}).'
        }
    };

    const menuItemCopy = {
        m1: {
            vi: { name: 'Cà phê đen truyền thống', description: 'Cà phê Việt rang đậm, pha bằng phin.' },
            en: { name: 'Traditional Black Coffee', description: 'Bold Vietnamese coffee brewed with a traditional phin filter.' }
        },
        m2: {
            vi: { name: 'Cà phê sữa đá', description: 'Cà phê phin với sữa đặc, uống lạnh.' },
            en: { name: 'Vietnamese Milk Coffee', description: 'Vietnamese drip coffee with condensed milk, served over ice.' }
        },
        m3: {
            vi: { name: 'Cà phê muối', description: 'Cà phê sữa đậm, phủ kem muối béo nhẹ.' },
            en: { name: 'Salted Cream Coffee', description: 'Bold milk coffee topped with smooth salted cream.' }
        },
        m4: {
            vi: { name: 'Cà phê ủ lạnh dừa', description: 'Cold brew dịu vị, kết hợp nước dừa thơm mát.' },
            en: { name: 'Coconut Cold Brew', description: 'Slow-steeped cold brew paired with fresh coconut water.' }
        },
        m5: {
            vi: { name: 'Trà đào cam sả', description: 'Trà đen, đào, cam tươi và sả thơm.' },
            en: { name: 'Peach Tea Lemongrass', description: 'Black tea with peach, fresh orange, and lemongrass.' }
        },
        m6: {
            vi: { name: 'Matcha latte', description: 'Matcha Nhật pha cùng sữa, dùng nóng hoặc lạnh.' },
            en: { name: 'Matcha Latte', description: 'Japanese Uji matcha whisked with milk and light sweetness.' }
        },
        m7: {
            vi: { name: 'Trà sữa ô long kem cheese', description: 'Trà ô long rang, sữa thơm và lớp kem cheese.' },
            en: { name: 'Oolong Milk Tea Cordial', description: 'Roasted oolong milk tea topped with cream cheese.' }
        },
        m8: {
            vi: { name: 'Croissant bơ', description: 'Bánh sừng bò bơ, vỏ giòn, ruột mềm.' },
            en: { name: 'Butter Croissant', description: 'Flaky, buttery French pastry baked fresh daily.' }
        },
        m9: {
            vi: { name: 'Bánh tiramisu', description: 'Bánh kem mascarpone, cà phê espresso và bột cacao.' },
            en: { name: 'Tiramisu Slice', description: 'Espresso-soaked cake with mascarpone cream and cocoa.' }
        }
    };

    const categoryLabels = {
        vi: { All: 'Tất cả', Coffee: 'Cà phê', Tea: 'Trà', Specialty: 'Đặc biệt', Pastry: 'Bánh' },
        en: { All: 'All', Coffee: 'Coffee', Tea: 'Tea', Specialty: 'Specialty', Pastry: 'Pastry' }
    };

    const zoneLabels = {
        vi: { 'Ground Floor': 'Tầng trệt', Terrace: 'Sân vườn', 'Upper Floor': 'Khu lửng' },
        en: { 'Ground Floor': 'Ground floor', Terrace: 'Terrace', 'Upper Floor': 'Mezzanine' }
    };

    function formatVND(amt) {
        const locale = menuLanguage === 'en' ? 'en-US' : 'vi-VN';
        return new Intl.NumberFormat(locale, { style: 'currency', currency: 'VND' }).format(amt);
    }

    function normalizeLanguage(lang) {
        return supportedLanguages.includes(lang) ? lang : 'vi';
    }

    function t(key, values = {}) {
        const bundle = menuText[menuLanguage] || menuText.vi;
        let text = bundle[key] || menuText.vi[key] || key;
        Object.keys(values).forEach(name => {
            text = text.replace(new RegExp('\\{' + name + '\\}', 'g'), values[name]);
        });
        return text;
    }

    function menuItemName(item) {
        const copy = item && menuItemCopy[item.id] && menuItemCopy[item.id][menuLanguage];
        return (copy && copy.name) || (item && item.name) || '';
    }

    function menuItemDescription(item) {
        const copy = item && menuItemCopy[item.id] && menuItemCopy[item.id][menuLanguage];
        return (copy && copy.description) || (item && item.description) || '';
    }

    function orderItemName(item) {
        const fromMenu = menu.find(m => m.id === item.menuItemId);
        if (fromMenu) return menuItemName(fromMenu);
        const copy = item && menuItemCopy[item.menuItemId] && menuItemCopy[item.menuItemId][menuLanguage];
        return (copy && copy.name) || (item && item.name) || '';
    }

    function categoryLabel(category) {
        const labels = categoryLabels[menuLanguage] || categoryLabels.vi;
        return labels[category] || category;
    }

    function itemCountLabel(count) {
        if (menuLanguage === 'en') {
            return count + ' ' + (count === 1 ? 'item' : 'items');
        }
        return count + ' ' + t('itemCountSuffix');
    }

    function sugarLabel(value) {
        return value === '0%' ? t('noSugar') : value;
    }

    function iceLabel(value) {
        return value === 'Ấm' ? t('warm') : value;
    }

    function updateLanguageToggle() {
        const viBtn = document.getElementById('lang-vi-btn');
        const enBtn = document.getElementById('lang-en-btn');
        const activeClass = 'text-[10px] font-bold px-2 py-1 rounded-full transition-all bg-coffee-rust text-white shadow-xs';
        const idleClass = 'text-[10px] font-bold px-2 py-1 rounded-full transition-all text-coffee-milk hover:text-coffee-rust';
        if (viBtn) viBtn.className = menuLanguage === 'vi' ? activeClass : idleClass;
        if (enBtn) enBtn.className = menuLanguage === 'en' ? activeClass : idleClass;
    }

    function updateCategoryLabels() {
        ['All', 'Coffee', 'Tea', 'Specialty', 'Pastry'].forEach(cat => {
            const id = 'custcat-' + (cat === 'All' ? 'all' : cat.toLowerCase());
            const btn = document.getElementById(id);
            if (btn) btn.textContent = categoryLabel(cat);
        });
    }

    function translateNavLinks() {
        const navLabels = {
            'index.html': 'navHome',
            'menu.jsp': 'navGuestOrder',
            'order-status.jsp': 'navOrderStatus',
            'member.jsp': 'navMember',
            'dashboard.jsp': 'navDashboard',
            'reports.jsp': 'navReports',
            'staff-management.jsp': 'navStaff',
            'inventory.jsp': 'navInventory',
            'waitstation.jsp': 'navWaitstation',
            'pos-payment.jsp': 'navPos',
            'kds.jsp': 'navKds',
            'staff-orders.jsp': 'navStaffOrders',
            'table-qr.jsp': 'navQr'
        };
        document.querySelectorAll('nav a[href]').forEach(link => {
            const href = (link.getAttribute('href') || '').split('?')[0].split('#')[0].split('/').pop();
            if (navLabels[href]) {
                link.textContent = t(navLabels[href]);
            }
        });
        document.querySelectorAll('nav button span').forEach(span => {
            if (span.textContent.trim() === 'Vận hành' || span.textContent.trim() === 'Operations') {
                span.textContent = t('navOperation');
            }
        });
    }

    function applyStaticLanguage() {
        document.documentElement.lang = menuLanguage;
        document.title = t('pageTitle');
        document.querySelectorAll('[data-i18n]').forEach(node => {
            node.textContent = t(node.dataset.i18n);
        });
        document.querySelectorAll('[data-i18n-placeholder]').forEach(node => {
            node.setAttribute('placeholder', t(node.dataset.i18nPlaceholder));
        });
        const loadingStatus = document.getElementById('menu-loading-status');
        if (loadingStatus) {
            loadingStatus.textContent = t(loadingStatus.dataset.statusKey || 'loadingMenuTables');
        }
        updateLanguageToggle();
        updateCategoryLabels();
        translateNavLinks();
    }

    function refreshLanguageRenderedViews() {
        applyStaticLanguage();
        drawCustomerDropdown();
        populateTableSetupSelect();
        drawCustMenuList();
        drawCustCartList();
        drawGuestHistory();
        renderCustomizationModal();
        setWsIndicator(socket && socket.readyState === WebSocket.OPEN ? 'connected' : 'disconnected');
        checkOrderingRestriction();
    }

    function setMenuLanguage(lang) {
        const nextLang = normalizeLanguage(lang);
        if (nextLang === menuLanguage) {
            applyStaticLanguage();
            return;
        }
        menuLanguage = nextLang;
        localStorage.setItem(LANGUAGE_STORAGE_KEY, menuLanguage);
        try {
            window.dispatchEvent(new CustomEvent('app-language-change', { detail: { language: menuLanguage } }));
        } catch (e) {
            console.warn(e);
        }
        refreshLanguageRenderedViews();
    }

    let shopClosedGlobal = false;
    let timeLimitUnlockedGlobal = false;

    function setMenuLoadingStatus(key) {
        const target = document.getElementById('menu-loading-status');
        if (target) {
            target.dataset.statusKey = key;
            target.textContent = t(key);
        }
    }

    function fetchWithTimeout(url, options = {}, timeoutMs = 6000) {
        const controller = new AbortController();
        const timer = window.setTimeout(() => controller.abort(), timeoutMs);
        return fetch(url, { ...options, signal: controller.signal })
            .finally(() => window.clearTimeout(timer));
    }

    function finishInitialMenuLoad() {
        if (initialMenuLoadDone) {
            return Promise.resolve();
        }

        initialMenuLoadDone = true;
        setMenuLoadingStatus('loadingReady');

        const elapsed = Date.now() - menuLoadStartedAt;
        const waitMs = Math.max(0, 720 - elapsed);

        return new Promise(resolve => {
            window.setTimeout(() => {
                document.body.classList.remove('menu-loading');
                document.body.classList.add('menu-ready');

                const loader = document.getElementById('menu-loading-screen');
                if (!loader) {
                    resolve();
                    return;
                }

                loader.classList.add('is-hidden');
                window.setTimeout(() => {
                    loader.remove();
                    resolve();
                }, 560);
            }, waitMs);
        });
    }

    function isTableSelectionConfirmed() {
        return localStorage.getItem('table_selection_confirmed') === 'true' && !!userSittingTableId;
    }

    function zoneLabel(zone) {
        const labels = zoneLabels[menuLanguage] || zoneLabels.vi;
        return labels[zone] || zone;
    }

    function populateTableSetupSelect() {
        const select = document.getElementById('table-setup-select');
        if (!select) return;
        select.innerHTML = '';

        tables.forEach(t => {
            const opt = document.createElement('option');
            opt.value = t.id;
            opt.text = `\${t.name} (\${zoneLabel(t.zone)})`;
            if (t.id === userSittingTableId) {
                opt.selected = true;
            }
            select.appendChild(opt);
        });

        if (!select.value && tables.length > 0) {
            select.value = tables[0].id;
        }
    }

    function openTableSetupModal(mode = 'manual') {
        populateTableSetupSelect();
        const modal = document.getElementById('table-setup-modal');
        if (!modal) return;
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        showTableSetupPanel(mode);
    }

    function closeTableSetupModal() {
        stopQrTableScanner();
        const modal = document.getElementById('table-setup-modal');
        if (!modal) return;
        modal.classList.remove('flex');
        modal.classList.add('hidden');
    }

    function showTableSetupPanel(mode) {
        const manualPanel = document.getElementById('table-setup-manual-panel');
        const scanPanel = document.getElementById('table-setup-scan-panel');
        const manualTab = document.getElementById('table-setup-manual-tab');
        const scanTab = document.getElementById('table-setup-scan-tab');
        const scanMode = mode === 'scan';

        if (manualPanel) manualPanel.classList.toggle('hidden', scanMode);
        if (scanPanel) scanPanel.classList.toggle('hidden', !scanMode);
        if (manualTab) {
            manualTab.className = scanMode
                ? 'bg-white text-coffee-dark border border-coffee-sand text-xs font-bold py-2.5 rounded-xl transition-all'
                : 'bg-coffee-rust text-white border border-coffee-rust text-xs font-bold py-2.5 rounded-xl transition-all';
        }
        if (scanTab) {
            scanTab.className = scanMode
                ? 'bg-coffee-rust text-white border border-coffee-rust text-xs font-bold py-2.5 rounded-xl transition-all'
                : 'bg-white text-coffee-dark border border-coffee-sand text-xs font-bold py-2.5 rounded-xl transition-all';
        }
        if (!scanMode) {
            stopQrTableScanner();
        }
    }

    function selectGuestTable(tableId, sourceLabel = t('manualSource')) {
        if (!tableId) {
            alert(t('chooseTableFirst'));
            return;
        }
        const selectedTable = tables.find(t => t.id === tableId);
        if (!selectedTable) {
            alert(t('tableNotFound'));
            return;
        }

        userSittingTableId = tableId;
        localStorage.setItem('user_sitting_table_id', tableId);
        localStorage.setItem('table_selection_confirmed', 'true');
        closeTableSetupModal();
        drawCustomerDropdown();
        drawGuestHistory();
        flashNotify(t('tableSelected', { table: selectedTable.name, source: sourceLabel }));
    }

    function confirmManualTableSelection() {
        const select = document.getElementById('table-setup-select');
        selectGuestTable(select ? select.value : '', t('manualSource'));
    }

    function maybeOpenTableSetupPrompt() {
        if (isStaffUser || urlTableId || urlTableCode || tableSetupPromptShown || isTableSelectionConfirmed() || tables.length === 0) {
            return;
        }
        tableSetupPromptShown = true;
        openTableSetupModal('manual');
    }

    function ensureTableBeforeOrdering() {
        if (isStaffUser || isTableSelectionConfirmed()) {
            return true;
        }
        flashNotify(t('chooseTableFirst'));
        openTableSetupModal('manual');
        return false;
    }

    function applyUrlTableCodeIfNeeded() {
        if (!urlTableCode) return;
        const target = tables.find(t => (t.tableCode || '').toUpperCase() === urlTableCode.trim().toUpperCase());
        if (!target) {
            flashNotify(t('qrNotFound'));
            openTableSetupModal('manual');
            return;
        }
        userSittingTableId = target.id;
        localStorage.setItem('user_sitting_table_id', target.id);
        localStorage.setItem('table_selection_confirmed', 'true');
    }

    function extractTableIdFromQr(value) {
        const raw = String(value || '').trim();
        if (!raw) return '';
        if (tables.some(t => t.id === raw)) {
            return raw;
        }
        const byCode = tables.find(t => (t.tableCode || '').toUpperCase() === raw.toUpperCase());
        if (byCode) {
            return byCode.id;
        }
        try {
            const parsed = new URL(raw, window.location.href);
            const tableId = parsed.searchParams.get('tableId');
            const tableCode = parsed.searchParams.get('tableCode');
            if (tableId) return tableId;
            if (tableCode) {
                const table = tables.find(t => (t.tableCode || '').toUpperCase() === tableCode.trim().toUpperCase());
                return table ? table.id : '';
            }
            return '';
        } catch (e) {
            const idMatch = raw.match(/[?&]tableId=([^&#]+)/);
            if (idMatch) return decodeURIComponent(idMatch[1]);
            const codeMatch = raw.match(/[?&]tableCode=([^&#]+)/);
            if (codeMatch) {
                const code = decodeURIComponent(codeMatch[1]);
                const table = tables.find(t => (t.tableCode || '').toUpperCase() === code.trim().toUpperCase());
                return table ? table.id : '';
            }
            return '';
        }
    }

    function applyQrTableValue(value) {
        const tableId = extractTableIdFromQr(value);
        if (!tableId) {
            setQrStatus(t('qrInvalid'), true);
            return;
        }
        selectGuestTable(tableId, t('qrSource'));
    }

    function applyQrTextFromInput() {
        const input = document.getElementById('table-qr-manual-input');
        applyQrTableValue(input ? input.value : '');
    }

    function setQrStatus(message, isError = false) {
        const status = document.getElementById('table-qr-status');
        if (!status) return;
        status.textContent = message;
        status.className = isError ? 'text-xs text-red-700 leading-5' : 'text-xs text-coffee-milk leading-5';
    }

    async function startQrTableScanner() {
        stopQrTableScanner();
        showTableSetupPanel('scan');

        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            setQrStatus(t('cameraNotAllowed'), true);
            return;
        }
        if (!('BarcodeDetector' in window)) {
            setQrStatus(t('qrUnsupported'), true);
            return;
        }

        try {
            qrStream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: { ideal: 'environment' } },
                audio: false
            });
            const video = document.getElementById('table-qr-video');
            video.srcObject = qrStream;
            await video.play();
            qrDetector = new BarcodeDetector({ formats: ['qr_code'] });
            setQrStatus(t('qrScanning'));

            qrScanTimer = window.setInterval(async () => {
                if (!video || video.readyState < 2 || !qrDetector) return;
                try {
                    const codes = await qrDetector.detect(video);
                    if (codes && codes.length > 0) {
                        applyQrTableValue(codes[0].rawValue || '');
                    }
                } catch (e) {
                    console.warn(e);
                }
            }, 500);
        } catch (e) {
            console.error(e);
            setQrStatus(t('cameraOpenFailed'), true);
        }
    }

    function stopQrTableScanner() {
        if (qrScanTimer) {
            window.clearInterval(qrScanTimer);
            qrScanTimer = null;
        }
        if (qrStream) {
            qrStream.getTracks().forEach(track => track.stop());
            qrStream = null;
        }
        const video = document.getElementById('table-qr-video');
        if (video) {
            video.pause();
            video.srcObject = null;
        }
    }

    async function checkOrderingRestriction() {
        try {
            const res = await fetchWithTimeout('api/shop/status', {}, 4000);
            if (res.ok) {
                const data = await res.json();
                shopClosedGlobal = data.closed;
                timeLimitUnlockedGlobal = data.timeLimitUnlocked === true;
            }
        } catch (e) {
            console.error('Failed to fetch shop status:', e);
        }

        const currentHour = new Date().getHours();
        const hourRestricted = !timeLimitUnlockedGlobal && (currentHour >= 22 || currentHour < 6);
        const restricted = shopClosedGlobal || hourRestricted;

        const warningBanner = document.getElementById('ordering-warning-banner');
        const submitBtn = document.querySelector('button[onclick="submitGuestTicket()"]');

        if (restricted) {
            let reasonStr = "";
            if (shopClosedGlobal) {
                reasonStr = t('shopClosed');
            } else {
                reasonStr = t('timeClosed');
            }

            if (warningBanner) {
                warningBanner.innerHTML = `
                    <div class="bg-red-50 border border-red-250 text-red-800 p-4 rounded-3xl text-xs flex items-center gap-3 animate-pulse my-2">
                        <span class="text-xl">🛑</span>
                        <div>
                            <p class="font-bold uppercase tracking-wider text-red-900">\${t('orderPausedTitle')}</p>
                            <p class="text-[11px] text-red-700 font-medium">\${t('orderPausedBody', { reason: reasonStr })}</p>
                        </div>
                    </div>
                `;
                warningBanner.classList.remove('hidden');
            }

            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.className = "w-full bg-coffee-sand text-coffee-milk font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider cursor-not-allowed flex justify-center items-center gap-1.5 shadow-none";
                submitBtn.innerText = t('orderPausedTitle');
            }
        } else {
            if (warningBanner) {
                warningBanner.classList.add('hidden');
            }
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.className = "w-full bg-coffee-rust text-white font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider hover:bg-coffee-rust/95 active:scale-[0.98] transition-all cursor-pointer flex justify-center items-center gap-1.5 shadow-sm";
                submitBtn.innerText = t('submitOrder');
            }
        }
    }

    function readTrackedOrderNumbers() {
        try {
            const tracked = JSON.parse(localStorage.getItem('guest_order_numbers') || '[]');
            return tracked.map(n => String(n)).filter(Boolean);
        } catch (e) {
            return [];
        }
    }

    function rememberOrder(ticket) {
        if (!ticket || !ticket.orderNumber) return;
        const orderText = String(ticket.orderNumber);
        localStorage.setItem('last_order_number', orderText);
        localStorage.setItem('last_order_id', ticket.id || '');
        localStorage.setItem('last_order_table_id', ticket.tableId || userSittingTableId);

        const tracked = readTrackedOrderNumbers().filter(n => n !== orderText);
        tracked.push(orderText);
        localStorage.setItem('guest_order_numbers', JSON.stringify(tracked.slice(-5)));
    }

    async function loadTrackedOrders() {
        const tracked = readTrackedOrderNumbers();
        if (tracked.length === 0) {
            orders = [];
            return;
        }

        const results = await Promise.all(tracked.map(orderNumber =>
            fetch(`api/orders/lookup?orderNumber=\${encodeURIComponent(orderNumber)}`)
                .then(res => res.ok ? res.json() : null)
                .catch(() => null)
        ));
        orders = results.filter(order => order && order.status !== 'Served');
    }

    async function fetchStateCore() {
        const isInitialLoad = !initialMenuLoadDone;
        try {
            if (isInitialLoad) setMenuLoadingStatus('loadingCheckHours');
            await checkOrderingRestriction();
            if (isInitialLoad) setMenuLoadingStatus('loadingMenuTables');
            const [rMenu, rTables] = await Promise.all([
                fetchWithTimeout('api/menu'),
                fetchWithTimeout('api/tables')
            ]);

            if (rMenu.ok) menu = await rMenu.json();
            if (rTables.ok) tables = await rTables.json();
            if (isInitialLoad) setMenuLoadingStatus('loadingOrders');
            applyUrlTableCodeIfNeeded();
            await loadTrackedOrders();

            drawCustomerDropdown();
            drawCustMenuList();
            drawCustCartList();
            drawGuestHistory();
            if (isInitialLoad) {
                await finishInitialMenuLoad();
                window.setTimeout(maybeOpenTableSetupPrompt, 180);
            } else {
                maybeOpenTableSetupPrompt();
            }
        } catch (err) {
            console.error('Core fetch error', err);
            setMenuLoadingStatus('loadingRetry');
            if (isInitialLoad) {
                drawCustomerDropdown();
                drawCustMenuList();
                drawCustCartList();
                drawGuestHistory();
                await finishInitialMenuLoad();
                window.setTimeout(maybeOpenTableSetupPrompt, 180);
                return;
            }
            window.setTimeout(() => {
                if (!initialMenuLoadDone) {
                    fetchStateCore();
                }
            }, 1600);
        }
    }

    function setupWebSocket() {
        const sockProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const endpoint = `\${sockProtocol}//\${window.location.host}\${window.location.pathname.substring(0, window.location.pathname.lastIndexOf("/"))}/ws`;
        socket = new WebSocket(endpoint);

        socket.onopen = () => {
            setWsIndicator('connected');
            if (initialMenuLoadDone) {
                fetchStateCore();
            }
        };

        socket.onmessage = () => {
            fetchStateCore();
            flashNotify(t('flashDefault'));
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
                    <span>\${t('syncReady')}</span>
                </div>
            `;
        } else {
            indicator.innerHTML = `
                <div class="bg-red-50 text-red-800 border border-red-250/60 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-bold">
                    <span class="w-1.5 h-1.5 bg-red-500 rounded-full"></span>
                    <span>\${t('syncOffline')}</span>
                </div>
            `;
        }
    }

    function changeSittingTable(newId) {
        userSittingTableId = newId;
        localStorage.setItem('user_sitting_table_id', newId);
        localStorage.setItem('table_selection_confirmed', 'true');
        fetchStateCore();
    }

    function drawCustomerDropdown() {
        const container = document.getElementById('table-seating-container');
        if (!container) return;

        const role = localStorage.getItem('auth_role') || '';
        const isStaff = (role === 'waiter' || role === 'manager');

        const activeTableObj = tables.find(t => t.id === userSittingTableId);
        const activeTableName = activeTableObj ? activeTableObj.name : t('tablePlaceholder');

        if (isStaff) {
            let selectHtml = `
                <div class="flex items-center gap-2 flex-wrap">
                    <label class="text-xs font-bold text-coffee-rust shrink-0">\${t('currentTableStaff')}</label>
                    <select id="user-sitting-table" onchange="changeSittingTable(this.value)" class="bg-white text-xs font-bold text-coffee-dark border border-coffee-sand/80 px-2.5 py-1 rounded-xl outline-none focus:border-coffee-rust cursor-pointer">
            `;
            tables.forEach(t => {
                const isSelected = (t.id === userSittingTableId) ? 'selected' : '';
                selectHtml += `<option value="\${t.id}" \${isSelected}>\${t.name} (\${zoneLabel(t.zone)})</option>`;
            });
            selectHtml += `</select>`;
            selectHtml += `
                    <span class="text-[9px] bg-amber-50 text-amber-700 border border-amber-200/50 px-2 py-0.5 rounded-lg font-bold font-mono">\${t('staffMode')}</span>
                </div>
            `;
            container.innerHTML = selectHtml;
        } else {
            let customerHtml = `
                <div class="flex items-center gap-3 flex-wrap">
                    <label class="text-xs font-bold text-coffee-rust shrink-0">\${t('currentTableGuest')}</label>
                    <div class="bg-coffee-dark text-[#FAF7EE] text-xs font-bold px-3.5 py-1.5 rounded-xl flex items-center gap-1.5 shadow-xs select-none">
                        <span>\${activeTableName}</span>
                    </div>
                    <button onclick="openTableSetupModal('manual')" class="text-xs font-bold text-coffee-rust bg-white hover:bg-coffee-light border border-coffee-sand/80 hover:border-coffee-rust px-2.5 py-1.5 rounded-xl transition-all cursor-pointer active:scale-95 shadow-2xs">
                        \${t('chooseTable')}
                    </button>
                    <button onclick="openTableSetupModal('scan')" class="text-xs font-bold text-coffee-dark bg-white hover:bg-coffee-light border border-coffee-sand/80 hover:border-coffee-rust px-2.5 py-1.5 rounded-xl transition-all cursor-pointer active:scale-95 shadow-2xs">
                        \${t('qrShort')}
                    </button>
                    <span class="text-[9.5px] text-coffee-milk font-medium hidden md:inline">
                        \${t('tableHint')}
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

        let roster = JSON.parse(localStorage.getItem('staff_roster')) || [];
        if (roster.length === 0) {
            roster = [
                { id: 1, name: 'Quản lý Hệ Thống', role: 'manager', pin: '8888', shift: 'Toàn thời gian', active: true, username: 'admin', password: '123456' },
                { id: 2, name: 'Nhân viên Phục vụ (waiter1)', role: 'waiter', pin: '1234', shift: 'Ca sáng (06:00 - 12:00)', active: true, username: 'waiter1', password: '123456' },
                { id: 3, name: 'Nhân viên Pha chế (barista1)', role: 'barista', pin: '3333', shift: 'Ca chiều (12:00 - 18:00)', active: true, username: 'barista1', password: '123456' }
            ];
            localStorage.setItem('staff_roster', JSON.stringify(roster));
        }

        const eligibleStaff = roster.filter(s => s.role === 'waiter' || s.role === 'manager');

        const wSelect = document.getElementById('modal-waiter-select');
        if (wSelect) {
            wSelect.innerHTML = '';
            eligibleStaff.forEach(s => {
                const opt = document.createElement('option');
                opt.value = s.username;
                opt.text = `\${s.name} (\${s.role === 'manager' ? t('manager') : t('waiter')})`;
                wSelect.appendChild(opt);
            });
        }

        const tSelect = document.getElementById('modal-target-table-select');
        if (tSelect) {
            tSelect.innerHTML = '';
            tables.forEach(table => {
                const opt = document.createElement('option');
                opt.value = table.id;
                opt.text = `\${table.name} (\${zoneLabel(table.zone)})`;
                if (table.id === userSittingTableId) {
                    opt.text += ` [\${t('selectedHere')}]`;
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
            alert(t('pinWrong'));
            clearModalPin();
            return;
        }

        if (targetTableId === userSittingTableId) {
            alert(t('tableSameAlert'));
            return;
        }

        changeSittingTable(targetTableId);
        closeWaiterConfirmationModal();
        flashNotify(t('movedTable', { table: tables.find(t => t.id === targetTableId).name, staff: match.name }));
    }

    function setCustMenuCategory(cat) {
        customerCategory = cat;
        ['All', 'Coffee', 'Tea', 'Specialty', 'Pastry'].forEach(p => {
            const btn = document.getElementById(`custcat-\${p === 'All' ? 'all' : p.toLowerCase()}`);
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
            const searchText = [
                m.name,
                m.description,
                menuItemName(m),
                menuItemDescription(m),
                categoryLabel(m.category)
            ].join(' ').toLowerCase();
            const matchesKey = searchText.includes(keyword);
            return matchesCat && matchesKey;
        });

        if (list.length === 0) {
            container.innerHTML = `
                <div class="col-span-2 text-center py-12 text-xs text-coffee-milk italic bg-white rounded-3xl border border-coffee-sand/50">
                    \${t('noResults')}
                </div>
            `;
            return;
        }

        list.forEach(item => {
            const itemName = menuItemName(item);
            const itemDescription = menuItemDescription(item);
            const itemCategoryLabel = categoryLabel(item.category);
            const outOfStock = item.inStock === false;
            container.innerHTML += `
                <div onclick="\${outOfStock ? "flashNotify(t('outOfStockToast'))" : `triggerCustomerSettings('\${item.id}')`}" 
                     class="\${outOfStock ? 'opacity-60 relative cursor-not-allowed bg-coffee-light/20' : 'bg-white hover:bg-coffee-light/40 cursor-pointer'} border border-coffee-sand/70 hover:border-coffee-rust/50 transition-all rounded-3xl p-4 flex flex-col justify-between group shadow-xs">
                    
                    \${outOfStock ? `
                    <div class="absolute top-4 right-4 z-10 bg-red-50 text-red-750 border border-red-200 text-[10px] font-bold px-2 py-0.5 rounded-full select-none shadow-xs font-mono">
                        \${t('outOfStock')}
                    </div>
                    ` : ''}

                    <div class="space-y-3">
                        \${item.image ? `
                        <div class="w-full aspect-[4/3] rounded-2xl overflow-hidden bg-coffee-light border border-coffee-sand/30 relative">
                            <img src="\${item.image}" alt="\${itemName}" referrerpolicy="no-referrer" class="w-full h-full object-cover \${outOfStock ? '' : 'group-hover:scale-105'} transition-transform duration-300">
                        </div>
                        ` : ''}
                        <div class="space-y-1.5">
                            <div class="flex items-center justify-between gap-2">
                                <span class="text-[8px] tracking-wider uppercase font-mono font-bold bg-coffee-light text-coffee-rust border border-coffee-sand/40 px-2 py-0.5 rounded-md">
                                    \${itemCategoryLabel}
                                </span>
                                <span class="font-mono font-bold text-coffee-rust text-[13px] \${outOfStock ? 'line-through opacity-70' : ''}">
                                    \${formatVND(item.price)}
                                </span>
                            </div>
                            <h4 class="font-serif font-bold text-coffee-dark text-sm \${outOfStock ? 'opacity-70' : 'group-hover:text-coffee-rust'} transition-colors leading-tight">
                                \${itemName}
                            </h4>
                            <p class="text-[11px] text-coffee-milk/80 line-clamp-2 leading-relaxed">
                                \${itemDescription}
                            </p>
                        </div>
                    </div>
                    <div class="flex items-center justify-between pt-3 mt-3 border-t border-coffee-sand/25">
                        <span class="text-[9px] text-coffee-milk font-mono font-medium">
                            \${t('sizes')}: \${item.availableSizes.join(', ')}
                        </span>
                        <div class="w-6 h-6 rounded-full bg-coffee-light text-coffee-rust flex items-center justify-center text-[10px] \${outOfStock ? '' : 'group-hover:bg-coffee-rust group-hover:text-white'} transition-all duration-200">
                            \${outOfStock ? '✕' : '＋'}
                        </div>
                    </div>
                </div>
            `;
        });
    }

    function triggerCustomerSettings(menuItemId) {
        if (!ensureTableBeforeOrdering()) {
            return;
        }
        const product = menu.find(m => m.id === menuItemId);
        if (!product) return;

        modalActiveProduct = product;
        modalSize = product.availableSizes[0] || 'M';
        modalSugar = '100%';
        modalIce = '100%';
        modalQty = 1;

        document.getElementById('modal-notes-input').value = '';
        document.getElementById('customization-modal').className = 'fixed inset-0 bg-coffee-dark/50 z-50 flex items-center justify-center p-4';
        renderCustomizationModal();
    }

    function renderCustomizationModal() {
        if (!modalActiveProduct) return;
        const product = modalActiveProduct;
        const hdr = document.getElementById('modal-product-header');
        hdr.innerHTML = `
            <span class="text-[9px] font-mono font-bold text-coffee-rust bg-coffee-light px-2 py-0.5 rounded border border-coffee-sand/50 inline-block">
                \${categoryLabel(product.category)}
            </span>
            <h3 class="text-base font-serif font-bold text-coffee-dark mt-1">\${menuItemName(product)}</h3>
            <p class="text-xs text-coffee-milk">\${menuItemDescription(product)}</p>
            <p class="text-xs text-coffee-rust font-mono font-bold pt-1.5" id="modal-product-price-label">\${t('originalPrice')}: \${formatVND(product.price)}</p>
        `;

        const sizeBox = document.getElementById('modal-size-container');
        sizeBox.innerHTML = '';
        product.availableSizes.forEach(sz => {
            const isSel = modalSize === sz;
            sizeBox.innerHTML += `
                <button onclick="setModalAttr('size', '\${sz}')" class="py-1.5 border text-xs font-bold rounded-xl transition-all cursor-pointer \${isSel ? 'bg-coffee-rust border-transparent text-white shadow-xs' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    \${t('sizePrefix')} \${sz}
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

        document.getElementById('modal-qty-label').innerText = modalQty;
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
            priceLabel.innerHTML = `\${t('unitPrice')}: <span class="text-coffee-rust font-bold">\${formatVND(singlePrice)}</span>\${modalSize !== 'M' ? ` <span class="text-[10px] text-coffee-milk font-normal">(\${t('sizePrefix')} \${modalSize})</span>` : ''}`;
        }
        
        const actionBtn = document.getElementById('modal-action-btn');
        if (actionBtn) {
            actionBtn.innerText = t('addToCartPrice', { price: formatVND(totalValue) });
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
            container.innerHTML += `
                <button onclick="setModalAttr('sugar', '\${opt}')" class="py-1 text-[10px] font-bold rounded-lg cursor-pointer \${isSel ? 'bg-coffee-rust border-transparent text-white' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    \${sugarLabel(opt)}
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
                <button onclick="setModalAttr('ice', '\${opt}')" class="py-1 text-[10px] font-bold rounded-lg cursor-pointer \${isSel ? 'bg-coffee-rust border-transparent text-white' : 'bg-white border-coffee-sand text-coffee-milk hover:border-coffee-rust'}">
                    \${iceLabel(opt)}
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
        flashNotify(t('addedToCart'));
    }

    let selectedVoucherCode = '';
    let selectedVoucherDiscount = 0;
    let activeVoucherCatalog = [];
    let activeVoucherCatalogLoaded = false;

    async function loadActiveVoucherCatalog() {
        if (activeVoucherCatalogLoaded) return;
        try {
            const res = await fetch('api/vouchers', { credentials: 'same-origin' });
            if (!res.ok) throw new Error('Voucher API failed');
            activeVoucherCatalog = await res.json();
            activeVoucherCatalogLoaded = true;
        } catch (error) {
            console.warn('Không tải được voucher từ API.', error);
            activeVoucherCatalog = [];
            activeVoucherCatalogLoaded = true;
        }
    }

    function activeVoucherInfo(code) {
        return activeVoucherCatalog.find(v => String(v.code || '').toUpperCase() === String(code || '').toUpperCase() && v.active !== false);
    }

    function activeVoucherName(code) {
        const voucher = activeVoucherInfo(code);
        if (!voucher) return String(code || '');
        return voucher.name || (t('discount') + ' ' + formatVND(voucher.discountAmount));
    }

    async function drawCartMembershipSection() {
        const section = document.getElementById('cart-membership-section');
        if (!section) return;

        const phone = localStorage.getItem('member_phone');
        if (!phone) {
            section.innerHTML = `
                <div class="flex items-center justify-between">
                    <span class="text-coffee-milk font-medium text-[11px]">🎟️ \${t('memberQuestion')}</span>
                    <a href="member.jsp" class="text-coffee-rust font-bold hover:underline hover:text-coffee-rust/80 text-[11px]">\${t('loginVoucher')}</a>
                </div>
            `;
            selectedVoucherCode = '';
            selectedVoucherDiscount = 0;
            updateCartTotalDisplay();
            return;
        }

        try {
            await loadActiveVoucherCatalog();
            const res = await fetch(`api/members/profile?phone=\${phone}`);
            if (res.ok) {
                const member = await res.json();
                const usableVouchers = (member.vouchers || []).filter(vCode => activeVoucherInfo(vCode));
                let html = `
                    <div class="space-y-1.5">
                        <div class="flex justify-between items-center text-[11px]">
                            <span class="text-coffee-dark font-medium flex items-center gap-1">
                                <span class="text-xs">🎟️</span> \${t('memberLabel')} <strong class="text-coffee-rust">\${member.name}</strong>
                            </span>
                            <span class="text-coffee-milk font-mono font-medium">\${member.points} \${t('memberPoints')}</span>
                        </div>
                `;

                if (usableVouchers.length === 0) {
                    html += `
                        <p class="text-[10px] text-coffee-milk italic mt-1">\${t('noVoucher')} <a href="member.jsp" class="text-coffee-rust font-bold hover:underline">\${t('goRedeemVoucher')}</a></p>
                    `;
                    selectedVoucherCode = '';
                    selectedVoucherDiscount = 0;
                } else {
                    html += `
                        <div class="space-y-1">
                            <label class="text-[9px] font-bold uppercase tracking-wider text-coffee-milk block">\${t('chooseVoucher')}</label>
                            <select id="guest-cart-voucher-select" onchange="selectVoucherForCart(this.value)" class="w-full bg-white text-xs border border-coffee-sand rounded-lg px-2 py-1 outline-none font-medium cursor-pointer">
                                <option value="">\${t('noVoucherOption')}</option>
                    `;
                    usableVouchers.forEach(vCode => {
                        const vName = activeVoucherName(vCode);
                        const isSelected = selectedVoucherCode === vCode ? 'selected' : '';
                        html += `<option value="\${vCode}" \${isSelected}>Voucher \${vCode} (\${vName})</option>`;
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
        const voucher = activeVoucherInfo(val);
        selectedVoucherDiscount = voucher ? Number(voucher.discountAmount || 0) : 0;

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
                    <span class="line-through text-coffee-milk text-xs mr-1 font-mono">\${formatVND(totalVal)}</span>
                    <span class="font-mono text-coffee-rust">\${formatVND(payTotal)}</span>
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

        sizeBadge.innerText = itemCountLabel(custCartItems.length);

        if (custCartItems.length === 0) {
            container.innerHTML = `
                <div class="py-10 text-center text-coffee-milk/60 text-xs">
                    <span class="text-3xl mb-1 text-coffee-sand block">🛒</span>
                    \${t('cartEmpty')}
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
                ? `\${t('sizePrefix')} \${c.customization.size} \u2022 \${t('sweet')}: \${sugarLabel(c.customization.sugar)} \u2022 \${t('ice')}: \${iceLabel(c.customization.ice)}`
                : `\${t('sizePrefix')} \${c.customization.size}`;

            container.innerHTML += `
                <div class="bg-coffee-light border border-coffee-sand/60 rounded-2xl p-3 text-xs space-y-1.5 flex flex-col justify-between">
                    <div class="flex justify-between items-start gap-2">
                        <div class="space-y-0.5">
                            <h5 class="font-bold text-coffee-dark">\${menuItemName(c.menuItem)}</h5>
                            <p class="text-[10px] text-coffee-milk font-medium">\${customDetail}</p>
                            \${c.notes ? `<p class="text-[9px] text-coffee-rust italic">\${t('noteQuote', { note: c.notes })}</p>` : ''}
                        </div>
                        <button onclick="removeCustCartItem(\${idx})" class="text-coffee-milk hover:text-coffee-rust text-xs shrink-0 p-1 cursor-pointer">
                            🗑️
                        </button>
                    </div>
                    <div class="flex items-center justify-between border-t border-coffee-sand/30 pt-2 mt-1">
                        <span class="font-mono font-bold text-coffee-rust text-xs">\${formatVND(itemsVal)}</span>
                        <div class="flex items-center gap-2">
                            <button onclick="updateCustItemQty(\${idx}, -1)" class="w-5 h-5 bg-white border border-coffee-sand text-xs flex items-center justify-center rounded font-bold hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">-</button>
                            <span class="font-mono text-xs font-bold">\${c.quantity}</span>
                            <button onclick="updateCustItemQty(\${idx}, 1)" class="w-5 h-5 bg-white border border-coffee-sand text-xs flex items-center justify-center rounded font-bold hover:bg-coffee-rust hover:text-white transition-all cursor-pointer">+</button>
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
        const hourRestricted = !timeLimitUnlockedGlobal && (currentHour >= 22 || currentHour < 6);
        if (shopClosedGlobal || hourRestricted) {
            alert(t('orderPausedAlert'));
            return;
        }

        if (!isTableSelectionConfirmed() || !tables.some(t => t.id === userSittingTableId)) {
            alert(t('tableRequiredAlert'));
            openTableSetupModal('manual');
            return;
        }

        if (custCartItems.length === 0) {
            alert(t('emptyCartAlert'));
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
        const selectedTable = tables.find(t => t.id === userSittingTableId);

        try {
            const response = await fetch('api/orders', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    tableId: userSittingTableId,
                    tableCode: selectedTable ? selectedTable.tableCode : null,
                    items: itemsPayload,
                    notes: globalCommStr,
                    memberPhone: loggedInPhone,
                    appliedVoucherCode: selectedVoucherCode || null
                })
            });

            if (response.ok) {
                const ticket = await response.json();
                rememberOrder(ticket);
                orders = [ticket].concat(orders.filter(o => String(o.orderNumber) !== String(ticket.orderNumber)));
                custCartItems = [];
                selectedVoucherCode = '';
                selectedVoucherDiscount = 0;
                document.getElementById('guest-order-notes').value = '';
                drawCustCartList();
                flashNotify(t('orderSuccess', { order: ticket.orderNumber }));
                
                drawGuestHistory();
            } else {
                const error = await response.json();
                alert(error.error || t('orderError'));
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
        label.innerText = sitTable ? sitTable.name : t('unknownTable');

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
                let stLabel = t('pending');
                let stClass = 'text-coffee-milk text-[10px]';

                if (it.status === 'Preparing') {
                    stLabel = t('preparing');
                    stClass = 'font-bold text-amber-800 text-[10px]';
                } else if (it.status === 'Ready') {
                    stLabel = t('ready');
                    stClass = 'font-bold text-emerald-800 text-[10px]';
                } else if (it.status === 'Served') {
                    stLabel = t('served');
                    stClass = 'text-coffee-milk line-through text-[10px]';
                }

                trackingItemsRows += `
                    <div class="flex justify-between items-center text-[11px] py-1 border-b border-coffee-sand/15 font-medium">
                        <span>\${orderItemName(it)} <span class="font-mono text-coffee-milk">x\${it.quantity}</span></span>
                        <span class="\${stClass}">\${stLabel}</span>
                    </div>
                `;
            });

            box.innerHTML += `
                <div class="bg-coffee-light border border-coffee-sand/60 p-3 rounded-2xl text-xs space-y-2">
                    <div class="flex justify-between items-center bg-white px-2 py-1 rounded-xl">
                        <span class="font-bold text-coffee-rust">\${t('orderNumber')} #\${o.orderNumber}</span>
                        <span class="text-[9px] uppercase font-mono font-bold px-2 py-0.5 rounded border \${statusBadgeClass}">
                            \${o.status === 'Pending' ? t('counter') : o.status === 'Preparing' ? t('preparing') : t('complete')}
                        </span>
                    </div>
                    <div class="space-y-0.5">
                        \${trackingItemsRows}
                    </div>
                </div>
            `;
        });
    }

    applyStaticLanguage();
    document.addEventListener('DOMContentLoaded', () => {
        applyStaticLanguage();
        window.setTimeout(applyStaticLanguage, 450);
    });
    fetchStateCore();
    setupWebSocket();
</script>

    </main>

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

    <script>
        if (document.getElementById('nav-clock')) {
            setInterval(() => {
                const locale = typeof menuLanguage !== 'undefined' && menuLanguage === 'en' ? 'en-US' : 'vi-VN';
                document.getElementById('nav-clock').innerText = new Date().toLocaleTimeString(locale);
            }, 1000);
        }

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
