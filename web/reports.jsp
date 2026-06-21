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
        .reports-admin-nav {
            display: none;
            align-items: center;
            gap: 0.35rem;
            padding: 0.3rem;
            border: 1px solid rgba(229, 222, 201, 0.9);
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.72);
            box-shadow: 0 10px 30px rgba(43, 27, 23, 0.06);
            backdrop-filter: blur(14px);
            max-width: min(54vw, 680px);
            overflow: visible;
        }
        @media (min-width: 1280px) {
            .reports-admin-nav {
                display: flex;
            }
        }
        .reports-admin-link,
        .reports-admin-menu-button {
            min-height: 34px;
            display: inline-flex;
            align-items: center;
            gap: 0.45rem;
            padding: 0.5rem 0.82rem;
            border-radius: 999px;
            color: #8E7D6F;
            font-size: 0.72rem;
            font-weight: 800;
            line-height: 1;
            white-space: nowrap;
            transition: background 160ms ease, color 160ms ease, transform 160ms ease, box-shadow 160ms ease;
        }
        .reports-admin-link:hover,
        .reports-admin-menu-button:hover {
            color: #2B1B17;
            background: rgba(250, 247, 238, 0.95);
            transform: translateY(-1px);
        }
        .reports-admin-link.is-active {
            color: #FAF7EE;
            background: #2B1B17;
            box-shadow: 0 8px 18px rgba(43, 27, 23, 0.16);
        }
        .reports-admin-menu {
            min-width: 230px;
            border-radius: 14px;
            border: 1px solid #E5DEC9;
            background: rgba(255, 255, 255, 0.98);
            box-shadow: 0 18px 40px rgba(43, 27, 23, 0.12);
            padding: 0.45rem;
        }
        .reports-admin-menu a {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            padding: 0.62rem 0.72rem;
            border-radius: 10px;
            color: #2B1B17;
            font-size: 0.76rem;
            font-weight: 700;
        }
        .reports-admin-menu a:hover {
            background: #FAF7EE;
            color: #A04423;
        }
        .reports-mobile-menu {
            border: 1px solid #E5DEC9;
            background: rgba(255, 255, 255, 0.92);
            border-radius: 999px;
            padding: 0.5rem 0.85rem;
            font-size: 0.75rem;
            font-weight: 800;
            color: #2B1B17;
        }
        @media (max-width: 1279px) {
            .reports-nav-support {
                display: none !important;
            }
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
<body class="min-h-screen flex flex-col dot-grid-bg relative selection:bg-coffee-rust/20 selection:text-coffee-rust">

    <nav class="border-b border-coffee-sand/70 bg-coffee-bg/90 backdrop-blur sticky top-0 z-40 px-6 py-4 transition-all">
        <div class="max-w-7xl mx-auto flex items-center justify-between">
            
            <a href="index.html" class="flex items-center gap-2 group">
                <span class="text-2xl font-serif font-extrabold tracking-tight text-coffee-dark select-none">
                    nhà cà phê<span class="text-coffee-rust">.</span>
                </span>
            </a>

            <div id="reports-admin-nav" class="reports-admin-nav">
                <a href="dashboard.jsp" class="reports-admin-link">
                    <span>⌂</span>
                    <span>Dashboard</span>
                </a>
                <a href="reports.jsp" class="reports-admin-link is-active">
                    <span>↗</span>
                    <span>Doanh số</span>
                </a>
                <a href="staff-management.jsp" class="reports-admin-link">
                    <span>◎</span>
                    <span>Nhân sự</span>
                </a>
                <a href="inventory.jsp" class="reports-admin-link">
                    <span>▦</span>
                    <span>Kho hàng</span>
                </a>
                <div class="relative group">
                    <button type="button" class="reports-admin-menu-button">
                        <span>⋯</span>
                        <span>Vận hành</span>
                        <svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        </svg>
                    </button>
                    <div class="reports-admin-menu absolute left-1/2 -translate-x-1/2 mt-2 hidden group-hover:block z-50">
                        <a href="waitstation.jsp"><span>Wait station</span><span>→</span></a>
                        <a href="pos-payment.jsp"><span>Thu ngân POS</span><span>→</span></a>
                        <a href="kds.jsp"><span>KDS pha chế</span><span>→</span></a>
                        <a href="staff-orders.jsp"><span>Danh sách order</span><span>→</span></a>
                        <a href="table-qr.jsp"><span>In mã QR bàn</span><span>→</span></a>
                    </div>
                </div>
            </div>

            <div class="relative group xl:hidden">
                <button type="button" class="reports-mobile-menu flex items-center gap-2">
                    <span>↗</span>
                    <span>Doanh số</span>
                    <svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                </button>
                <div class="reports-admin-menu absolute left-1/2 -translate-x-1/2 mt-2 hidden group-hover:block z-50">
                    <a href="dashboard.jsp"><span>Dashboard</span><span>→</span></a>
                    <a href="reports.jsp"><span>Doanh số</span><span>✓</span></a>
                    <a href="staff-management.jsp"><span>Nhân sự</span><span>→</span></a>
                    <a href="inventory.jsp"><span>Kho hàng</span><span>→</span></a>
                    <a href="waitstation.jsp"><span>Wait station</span><span>→</span></a>
                    <a href="kds.jsp"><span>KDS pha chế</span><span>→</span></a>
                </div>
            </div>

            <div class="flex items-center gap-3">
                
                <div id="connection-status" class="reports-nav-support">
                    <div class="bg-amber-50 text-amber-800 border border-amber-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-medium">
                        <span class="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse"></span>
                        <span>Đang kết nối...</span>
                    </div>
                </div>

                <div class="reports-nav-support hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>

                <div class="reports-nav-support flex items-center gap-1.5">
                    <a href="javascript:history.back()" class="text-xs font-bold px-3 py-1.5 bg-white hover:bg-coffee-rust hover:text-white border border-coffee-sand rounded-xl shadow-xs transition-all pointer">
                        Quay lại
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
                <p id="flash-message" class="font-medium text-coffee-bg">Đã cập nhật trạng thái đồng bộ!</p>
            </div>
        </div>
    </div>

    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col justify-start">

<div class="space-y-6">
    <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex justify-between items-center">
        <div>
            <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                <span>📈</span> Báo cáo Doanh thu & Thống kê sản phẩm
            </h2>
            <p class="text-xs text-coffee-milk font-medium">Doanh thu và sản phẩm bán chạy.</p>
        </div>
        <div class="flex gap-2">
            <button onclick="window.print()" class="bg-white text-coffee-dark border border-coffee-sand px-3 py-1.5 rounded-xl text-xs font-bold font-mono hover:border-coffee-rust transition-colors cursor-pointer">
                🖨️ Xuất báo cáo giấy
            </button>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        
        <div class="lg:col-span-2 space-y-6">
            
            <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-sm space-y-5">
                <div>
                     <h3 class="font-serif italic font-bold text-base text-coffee-dark">Doanh số theo nhóm sản phẩm</h3>
                     <p class="text-[10px] text-coffee-milk">Theo số món đã phục vụ.</p>
                </div>

                <div class="space-y-4">
                    <div class="space-y-1.5">
                        <div class="flex justify-between items-center text-xs font-medium">
                            <span class="text-coffee-dark font-bold">☕ Cà phê truyền thống</span>
                            <span class="font-mono text-coffee-rust" id="label-sales-coffee">0 ly (0 ₫)</span>
                        </div>
                        <div class="w-full bg-coffee-light h-3.5 rounded-full overflow-hidden border border-coffee-sand/30">
                            <div id="bar-sales-coffee" class="bg-coffee-rust h-full rounded-full transition-all duration-500" style="width: 0%"></div>
                        </div>
                    </div>

                    <div class="space-y-1.5">
                        <div class="flex justify-between items-center text-xs font-medium">
                            <span class="text-coffee-dark font-bold">🍵 Trà phin mộc hoa quả</span>
                            <span class="font-mono text-coffee-rust" id="label-sales-tea">0 ly (0 ₫)</span>
                        </div>
                        <div class="w-full bg-coffee-light h-3.5 rounded-full overflow-hidden border border-coffee-sand/30">
                            <div id="bar-sales-tea" class="bg-coffee-dark h-full rounded-full transition-all duration-500" style="width: 0%"></div>
                        </div>
                    </div>

                    <div class="space-y-1.5">
                        <div class="flex justify-between items-center text-xs font-medium">
                            <span class="text-coffee-dark font-bold">🥤 Đặc sản sữa quầy bar</span>
                            <span class="font-mono text-coffee-rust" id="label-sales-specialty">0 ly (0 ₫)</span>
                        </div>
                        <div class="w-full bg-coffee-light h-3.5 rounded-full overflow-hidden border border-coffee-sand/30">
                            <div id="bar-sales-specialty" class="bg-coffee-milk h-full rounded-full transition-all duration-500" style="width: 0%"></div>
                        </div>
                    </div>

                    <div class="space-y-1.5">
                        <div class="flex justify-between items-center text-xs font-medium">
                            <span class="text-coffee-dark font-bold">🥐 Bánh ngọt lò nướng Pháp</span>
                            <span class="font-mono text-coffee-rust" id="label-sales-pastry">0 ly (0 ₫)</span>
                        </div>
                        <div class="w-full bg-coffee-light h-3.5 rounded-full overflow-hidden border border-coffee-sand/30">
                            <div id="bar-sales-pastry" class="bg-amber-400 h-full rounded-full transition-all duration-500" style="width: 0%"></div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-sm space-y-4">
                <div>
                     <h3 class="font-serif italic font-bold text-base text-coffee-dark">Hiệu quả khai thác khu vực ngồi</h3>
                     <p class="text-[10px] text-coffee-milk">Theo khu vực bàn.</p>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4" id="zone-perf-holder">
                </div>
            </div>

        </div>

        <div class="bg-white border border-coffee-sand rounded-3xl p-5 shadow-xs space-y-4">
            <h4 class="font-serif italic font-bold text-base text-coffee-dark border-b border-coffee-light pb-2">Đồ uống bán chạy nhất ca</h4>
            <div id="hot-seller-list" class="space-y-3.5">
            </div>
        </div>

    </div>

    <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-sm space-y-6 mt-6">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-coffee-light pb-4">
            <div>
                 <h3 class="font-serif italic font-bold text-lg text-coffee-dark flex items-center gap-2">
                     <span>📊</span> Báo cáo Doanh số & Tài chính lịch sử
                 </h3>
                 <p class="text-[10px] text-coffee-milk">Doanh thu, chi phí và lợi nhuận.</p>
            </div>
            
            <div class="flex gap-2 bg-coffee-light p-1 rounded-xl border border-coffee-sand/50">
                <button btn-year="2024" onclick="setHistoricalYear(2024)" class="px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer bg-white text-coffee-dark shadow-3xs" id="btn-year-2024">
                    Năm 2024
                </button>
                <button btn-year="2025" onclick="setHistoricalYear(2025)" class="px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer text-coffee-milk hover:text-coffee-dark" id="btn-year-2025">
                    Năm 2025
                </button>
            </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-4 gap-4">
            <div class="p-4 rounded-2xl bg-amber-50 border border-coffee-sand/40 space-y-1">
                <span class="text-[9px] uppercase tracking-wider font-mono font-bold text-coffee-milk">Tổng doanh thu cả năm</span>
                <p class="text-lg font-serif font-bold text-coffee-dark" id="hist-total-revenue">0 ₫</p>
            </div>
            <div class="p-4 rounded-2xl bg-coffee-light/40 border border-coffee-sand/40 space-y-1">
                <span class="text-[9px] uppercase tracking-wider font-mono font-bold text-coffee-milk">Tổng chi phí vận hành</span>
                <p class="text-lg font-serif font-bold text-coffee-dark" id="hist-total-expenses">0 ₫</p>
            </div>
            <div class="p-4 rounded-2xl bg-white border border-coffee-sand/40 space-y-1">
                <span class="text-[9px] uppercase tracking-wider font-mono font-bold text-coffee-milk">Lợi nhuận ròng</span>
                <p class="text-lg font-serif font-bold text-coffee-rust" id="hist-total-profit">0 ₫</p>
            </div>
            <div class="p-4 rounded-2xl bg-coffee-light/60 border border-coffee-sand/40 flex items-center justify-between">
                <div>
                    <span class="text-[9px] uppercase tracking-wider font-mono font-bold text-coffee-milk d-block">Trạng thái tài chính</span>
                    <p class="text-sm font-bold text-coffee-dark mt-0.5" id="hist-year-status">Đang tính...</p>
                </div>
                <span class="text-2xl" id="hist-year-icon">⚖️</span>
            </div>
        </div>

        <div class="border border-coffee-sand/40 rounded-2xl overflow-hidden mt-4 bg-white">
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-coffee-light text-coffee-dark border-b border-coffee-sand/60 text-[10px] font-bold uppercase tracking-wider font-mono">
                            <th class="py-3 px-4">Tháng hoạt động</th>
                            <th class="py-3 px-4">Doanh số bán ra (Revenue)</th>
                            <th class="py-3 px-4">Chi phí (Vận hành & Materials)</th>
                            <th class="py-3 px-4">Lợi nhuận ròng (Net Profit)</th>
                            <th class="py-3 px-4 text-center">Đánh giá tài khóa</th>
                        </tr>
                    </thead>
                    <tbody id="historical-table-body" class="divide-y divide-coffee-sand/15 font-medium text-xs">
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</div>

<script>
    let menu = [];
    let tables = [];
    let orders = [];
    let historicalReports = [];
    let selectedHistoricalYear = 2024;

    function formatVND(amt) {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amt);
    }

    async function loadReports() {
        try {
            const [rMenu, rTables, rOrders, rHist] = await Promise.all([
                fetch('api/menu'),
                fetch('api/tables'),
                fetch('api/orders'),
                fetch('api/reports/historical')
            ]);
            if (rMenu.ok) menu = await rMenu.json();
            if (rTables.ok) tables = await rTables.json();
            if (rOrders.ok) orders = await rOrders.json();
            if (rHist.ok) historicalReports = await rHist.json();

            generateAnalytics();
            drawHistoricalReports();
        } catch (e) {
            console.error('Reports load fail', e);
        }
    }

    function setHistoricalYear(year) {
        selectedHistoricalYear = year;
        
        const btn2024 = document.getElementById('btn-year-2024');
        const btn2025 = document.getElementById('btn-year-2025');
        
        if (year === 2024) {
            btn2024.className = "px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer bg-white text-coffee-dark shadow-3xs";
            btn2025.className = "px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer text-coffee-milk hover:text-coffee-dark";
        } else {
            btn2025.className = "px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer bg-white text-coffee-dark shadow-3xs";
            btn2024.className = "px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer text-coffee-milk hover:text-coffee-dark";
        }
        
        drawHistoricalReports();
    }

    function drawHistoricalReports() {
        const tbody = document.getElementById('historical-table-body');
        if (!tbody) return;
        tbody.innerHTML = '';
        
        const filtered = historicalReports.filter(r => r.year === selectedHistoricalYear);
        if (filtered.length === 0) {
            tbody.innerHTML = `<tr><td colspan="5" class="py-6 text-center text-coffee-milk italic">Chưa có số liệu tài khóa của năm này!</td></tr>`;
            return;
        }
        
        let totalRev = 0;
        let totalExp = 0;
        let totalProf = 0;
        
        filtered.forEach(r => {
            totalRev += r.revenue;
            totalExp += r.expenses;
            totalProf += r.profit;
            
            let badgeClass = '';
            let labelText = '';
            if (r.profit > 0) {
                badgeClass = 'bg-emerald-100 text-emerald-800 border border-emerald-250';
                labelText = '📈 Lãi phát sinh';
            } else if (r.profit < 0) {
                badgeClass = 'bg-red-100 text-red-800 border border-red-200';
                labelText = '📉 Thâm hụt (Lỗ)';
            } else {
                badgeClass = 'bg-slate-100 text-slate-800 border border-slate-200';
                labelText = '⚖️ Hòa vốn';
            }
            
            tbody.innerHTML += `
                <tr class="hover:bg-coffee-light/25 transition-colors">
                    <td class="py-3.5 px-4 font-bold text-coffee-dark">Tháng \${r.month} / \${r.year}</td>
                    <td class="py-3.5 px-4 text-coffee-dark font-mono font-semibold">\${formatVND(r.revenue)}</td>
                    <td class="py-3.5 px-4 text-coffee-milk font-mono">\${formatVND(r.expenses)}</td>
                    <td class="py-3.5 px-4 font-mono font-bold \${r.profit >= 0 ? 'text-coffee-rust' : 'text-red-650'}">\${formatVND(r.profit)}</td>
                    <td class="py-3.5 px-4 text-center">
                        <span class="text-[9.5px] font-bold px-2.5 py-0.5 rounded-full \${badgeClass}">
                            \${labelText}
                        </span>
                    </td>
                </tr>
            `;
        });
        
        document.getElementById('hist-total-revenue').innerText = formatVND(totalRev);
        document.getElementById('hist-total-expenses').innerText = formatVND(totalExp);
        
        const profElement = document.getElementById('hist-total-profit');
        profElement.innerText = formatVND(totalProf);
        if (totalProf > 0) {
            profElement.className = "text-lg font-serif font-bold text-coffee-rust";
            document.getElementById('hist-year-status').innerText = "Kinh doanh có Lãi";
            document.getElementById('hist-year-icon').innerText = "📈";
        } else if (totalProf < 0) {
            profElement.className = "text-lg font-serif font-bold text-red-650";
            document.getElementById('hist-year-status').innerText = "Kinh doanh Thua lỗ";
            document.getElementById('hist-year-icon').innerText = "📉";
        } else {
            profElement.className = "text-lg font-serif font-bold text-coffee-dark";
            document.getElementById('hist-year-status').innerText = "Hòa vốn cân bằng";
            document.getElementById('hist-year-icon').innerText = "⚖️";
        }
    }

    function generateAnalytics() {
        const paidTickets = orders.filter(o => o.status === 'Served');

        let catCounts = { Coffee: 0, Tea: 0, Specialty: 0, Pastry: 0 };
        let catRevenues = { Coffee: 0, Tea: 0, Specialty: 0, Pastry: 0 };
        let itemFrequency = {};

        paidTickets.forEach(o => {
            o.items.forEach(it => {
                const menuItem = menu.find(m => m.id === it.menuItemId);
                if (menuItem) {
                    const cat = menuItem.category;
                    catCounts[cat] = (catCounts[cat] || 0) + it.quantity;
                    
                    let singlePrice = it.price;
                    if (it.customization && it.customization.size === 'L') singlePrice += 6000;
                    else if (it.customization && it.customization.size === 'S') singlePrice = Math.max(10000, singlePrice - 4000);

                    catRevenues[cat] = (catRevenues[cat] || 0) + (singlePrice * it.quantity);

                    itemFrequency[it.name] = (itemFrequency[it.name] || 0) + it.quantity;
                }
            });
        });

        const maxSales = Math.max(1, catCounts.Coffee, catCounts.Tea, catCounts.Specialty, catCounts.Pastry);
        
        ['Coffee', 'Tea', 'Specialty', 'Pastry'].forEach(cat => {
            const count = catCounts[cat];
            const money = catRevenues[cat];
            const p = Math.max(10, Math.round((count / maxSales) * 100));

            const idStr = cat.toLowerCase();
            document.getElementById(`label-sales-\${idStr}`).innerText = `\${count} món (\${formatVND(money)})`;
            document.getElementById(`bar-sales-\${idStr}`).style.width = `\${p}%`;
        });

        let zoneStats = {
            'Ground Floor': { count: 0, revenue: 0, name: 'Khu Nhà Trệt' },
            'Terrace': { count: 0, revenue: 0, name: 'Khu Sân Vườn' },
            'Upper Floor': { count: 0, revenue: 0, name: 'Khu Tầng Lửng' }
        };

        paidTickets.forEach(o => {
            const relatedTable = tables.find(t => t.id === o.tableId);
            if (relatedTable && zoneStats[relatedTable.zone]) {
                zoneStats[relatedTable.zone].count++;
                zoneStats[relatedTable.zone].revenue += o.totalAmount;
            }
        });

        const zonePerfBox = document.getElementById('zone-perf-holder');
        zonePerfBox.innerHTML = '';
        Object.keys(zoneStats).forEach(key => {
            const z = zoneStats[key];
            zonePerfBox.innerHTML += `
                <div class="bg-coffee-light/60 border border-coffee-sand/70 rounded-2xl p-4 text-xs font-medium text-center space-y-1">
                    <span class="text-coffee-milk uppercase tracking-wider font-mono text-[9px] font-bold block">\${z.name}</span>
                    <p class="text-base font-serif font-bold text-coffee-dark mt-1">\${z.count} hóa đơn</p>
                    <p class="text-[11px] font-mono font-bold text-coffee-rust">\${formatVND(z.revenue)}</p>
                </div>
            `;
        });

        const sortedItems = Object.keys(itemFrequency).map(name => ({
            name, quantity: itemFrequency[name]
        })).sort((a,b) => b.quantity - a.quantity);

        const hotList = document.getElementById('hot-seller-list');
        hotList.innerHTML = '';
        if (sortedItems.length === 0) {
            hotList.innerHTML = `
                <div class="text-center py-6 text-xs text-coffee-milk italic">
                    Chưa có xếp hạng. Hãy hoàn tất dâng dọn nước để bắt đầu thống kê.
                </div>
            `;
            return;
        }

        sortedItems.slice(0, 5).forEach((it, idx) => {
            hotList.innerHTML += `
                <div class="flex items-center gap-3 bg-coffee-light/40 border border-coffee-sand/50 p-2.5 rounded-xl text-xs font-medium justify-between shadow-3xs">
                    <div class="flex items-center gap-2">
                        <span class="w-5 h-5 rounded-full bg-coffee-rust text-white flex items-center justify-center font-bold text-[10px] font-mono shrink-0">\${idx+1}</span>
                        <span class="text-coffee-dark font-bold">\${it.name}</span>
                    </div>
                    <span class="font-mono text-coffee-rust font-bold bg-white px-2 py-0.5 border border-coffee-sand rounded-md shrink-0">
                        \${it.quantity} ly đã nạp
                    </span>
                </div>
            `;
        });
    }

    loadReports();
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
                document.getElementById('nav-clock').innerText = new Date().toLocaleTimeString('vi-VN');
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
