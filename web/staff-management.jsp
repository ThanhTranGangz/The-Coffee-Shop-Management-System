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
                            bg: '#FAF8F3',       
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
            background-color: #FAF8F3;
            color: #2B1B17;
        }
        .font-serif {
            font-family: 'Playfair Display', serif;
        }
        .font-mono {
            font-family: 'JetBrains Mono', monospace;
        }
        
        .dot-grid-bg {
            background-color: #FAF8F3;
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

            <div class="hidden lg:flex items-center gap-4 text-xs font-medium">
                <a href="index.html" class="hover:text-coffee-rust transition-colors text-coffee-milk">Trang chủ</a>
                <a href="menu.jsp" class="hover:text-coffee-rust transition-colors text-coffee-dark font-bold">Khách gọi món</a>
                <a href="waitstation.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Wait station</a>
                <a href="kds.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">KDS pha chế</a>
                
                <div class="relative group">
                    <button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">
                        <span>Chức năng khác</span>
                        <svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <div class="absolute left-0 mt-1 w-52 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">
                        <a href="dashboard.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-medium">Dashboard</a>
                        <a href="inventory.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors font-semibold">Kho nguyên liệu</a>
                        <a href="reports.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Báo cáo doanh số</a>
                        <a href="staff-orders.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Danh sách order</a>
                        <a href="staff-management.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Quản lý nhân sự</a>
                        <a href="table-qr.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">In mã QR bàn</a>
                        <a href="member.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Khách thành viên</a>
                        <a href="order-status.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Kiểm tra đơn nước</a>
                    </div>
                </div>
            </div>

            <div class="flex items-center gap-3">
                
                <div id="connection-status">
                    <div class="bg-amber-50 text-amber-800 border border-amber-200/50 px-3 py-1 rounded-full text-xs flex items-center gap-1.5 font-medium">
                        <span class="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse"></span>
                        <span>Đang kết nối...</span>
                    </div>
                </div>

                <div class="hidden md:flex bg-coffee-light border border-coffee-sand/60 px-3 py-1 rounded-full items-center gap-1.5 font-mono text-xs text-coffee-dark font-medium">
                    <svg class="w-3.5 h-3.5 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span id="nav-clock">--:--:--</span>
                </div>

                <div class="flex items-center gap-1.5">
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
                <span>🛡️</span> Quản lý nhân sự
            </h2>
            <p class="text-xs text-coffee-milk font-medium">Tài khoản, hội viên và ca làm.</p>
        </div>
        <div class="bg-coffee-rust text-white font-mono text-[11px] font-bold px-3 py-1.5 rounded-full uppercase tracking-wider">
            Nhân sự • khách hàng • ca làm
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        
        <div class="lg:col-span-2 bg-white border border-coffee-sand rounded-3xl p-6 shadow-sm space-y-4">
            
            <div class="flex items-center justify-between border-b border-coffee-sand/55 pb-2">
                <div class="flex gap-2">
                    <button onclick="setManagementTab('staff')" id="tab-btn-staff" class="px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer">
                        🧑‍🤝‍🧑 Tài khoản Nhân sự
                    </button>
                    <button onclick="setManagementTab('crm')" id="tab-btn-crm" class="px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer">
                        🎯 Hồ sơ Khách hàng CRM
                    </button>
                    <button onclick="setManagementTab('shifts')" id="tab-btn-shifts" class="px-3 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer">
                        📅 Phân ca trực Shift
                    </button>
                </div>
                <div class="hidden sm:block">
                    <input type="text" id="management-search-input" oninput="handleDirectorySearch()" placeholder="Tìm kiếm nhanh..." class="text-xs px-3 py-1.5 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                </div>
            </div>

            <div id="panel-staff" class="space-y-4">
                <div>
                     <h3 class="font-serif italic font-bold text-base text-coffee-dark">Danh sách tài khoản trực ca</h3>
                     <p class="text-[10px] text-coffee-milk">Quyền truy cập và trạng thái ca.</p>
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
                        </tbody>
                    </table>
                </div>
            </div>

            <div id="panel-crm" class="hidden space-y-4">
                <div>
                     <h3 class="font-serif italic font-bold text-base text-coffee-dark">Dữ liệu khách hàng hội viên (CRM)</h3>
                     <p class="text-[10px] text-coffee-milk">Thông tin hội viên và hạng thưởng.</p>
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
                        </tbody>
                    </table>
                </div>
            </div>

            <div id="panel-shifts" class="hidden space-y-4">
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
                    <div>
                         <h3 class="font-serif italic font-bold text-base text-coffee-dark">Bảng phân lịch ca trực</h3>
                         <p class="text-[10px] text-coffee-milk">Ca phục vụ và pha chế trong ngày.</p>
                    </div>
                    <button onclick="openAddShiftModal()" class="px-3.5 py-1.5 text-xs font-bold bg-coffee-rust text-white rounded-xl hover:bg-coffee-rust/95 cursor-pointer">
                        + Tạo ca trực mới 📅
                    </button>
                </div>

                <div class="grid grid-cols-3 gap-3">
                    <div class="bg-coffee-light/60 p-3 rounded-2xl border border-coffee-sand/40">
                         <span class="text-[9.5px] uppercase font-mono font-bold text-coffee-milk block">Ca Sáng (06:00 - 12:00)</span>
                         <span id="shift-count-morning" class="text-sm font-serif italic font-bold text-coffee-dark">0 nhân sự</span>
                    </div>
                    <div class="bg-coffee-light/60 p-3 rounded-2xl border border-coffee-sand/40">
                         <span class="text-[9.5px] uppercase font-mono font-bold text-coffee-milk block">Ca Chiều (12:00 - 18:00)</span>
                         <span id="shift-count-afternoon" class="text-sm font-serif italic font-bold text-coffee-dark">0 nhân sự</span>
                    </div>
                    <div class="bg-coffee-light/60 p-3 rounded-2xl border border-coffee-sand/40">
                         <span class="text-[9.5px] uppercase font-mono font-bold text-coffee-milk block">Ca Tối (18:00 - 24:00)</span>
                         <span id="shift-count-evening" class="text-sm font-serif italic font-bold text-coffee-dark">0 nhân sự</span>
                    </div>
                </div>

                <div class="overflow-x-auto">
                    <table class="w-full text-left text-xs border-collapse">
                        <thead>
                            <tr class="border-b border-coffee-sand font-bold text-coffee-milk text-[10px] uppercase font-mono bg-coffee-light/50">
                                <th class="py-3 px-4">Nhân viên trực</th>
                                <th class="py-3 px-4">Ngày trực</th>
                                <th class="py-3 px-4">Ca làm việc</th>
                                <th class="py-3 px-4">Khung giờ</th>
                                <th class="py-3 px-4">Trạng thái</th>
                                <th class="py-3 px-4">Ghi chú</th>
                                <th class="py-3 px-4 text-center">Tác vụ</th>
                            </tr>
                        </thead>
                        <tbody id="shifts-table-body" class="divide-y divide-coffee-sand/20 font-medium animate-fade-in">
                        </tbody>
                    </table>
                </div>
            </div>

        </div>

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
        
        if (shiftText.includes("06:00") && shiftText.includes("12:00")) {
            return (hour >= 6 && hour < 12);
        }
        
        if (shiftText.includes("12:00") && shiftText.includes("18:00")) {
            return (hour >= 12 && hour < 18);
        }
        
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
    let shiftsList = [];

    async function loadAllData() {
        try {
            const [staffRes, crmRes, shiftsRes] = await Promise.all([
                fetch('api/staff'),
                fetch('api/members'),
                fetch('api/shifts')
            ]);
            
            if (staffRes.ok) {
                staffRoster = await staffRes.json();
            }
            if (crmRes.ok) {
                crmCustomers = await crmRes.json();
            }
            if (shiftsRes.ok) {
                shiftsList = await shiftsRes.json();
            }
        } catch (e) {
            console.warn('API error, falling back to local cookies or storage', e);
            staffRoster = JSON.parse(localStorage.getItem('staff_roster')) || [];
            crmCustomers = JSON.parse(localStorage.getItem('local_member_db')) || [];
            shiftsList = JSON.parse(localStorage.getItem('shifts_list')) || [];
        }

        localStorage.setItem('staff_roster', JSON.stringify(staffRoster));
        localStorage.setItem('local_member_db', JSON.stringify(crmCustomers));
        localStorage.setItem('shifts_list', JSON.stringify(shiftsList));

        populateStaffSelector();

        handleDirectorySearch();
    }

    function setManagementTab(tab) {
        activeManagementTab = tab;
        const btnStaff = document.getElementById('tab-btn-staff');
        const btnCrm = document.getElementById('tab-btn-crm');
        const btnShifts = document.getElementById('tab-btn-shifts');
        const pStaff = document.getElementById('panel-staff');
        const pCrm = document.getElementById('panel-crm');
        const pShifts = document.getElementById('panel-shifts');

        btnStaff.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer";
        btnCrm.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer";
        btnShifts.className = "px-3 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-sand text-coffee-milk hover:text-coffee-dark bg-white hover:bg-coffee-light/40 cursor-pointer";

        pStaff.classList.add('hidden');
        pCrm.classList.add('hidden');
        pShifts.classList.add('hidden');

        if (tab === 'staff') {
            btnStaff.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer";
            pStaff.classList.remove('hidden');
        } else if (tab === 'crm') {
            btnCrm.className = "px-4 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer";
            pCrm.classList.remove('hidden');
        } else if (tab === 'shifts') {
            btnShifts.className = "px-3 py-2 text-xs font-bold rounded-xl transition-all border border-coffee-rust bg-coffee-rust text-white shadow-3xs cursor-pointer";
            pShifts.classList.remove('hidden');
        }
        handleDirectorySearch();
    }

    function handleDirectorySearch() {
        searchQuery = document.getElementById('management-search-input').value.toLowerCase().trim();
        if (activeManagementTab === 'staff') {
            drawStaffRoster();
        } else if (activeManagementTab === 'crm') {
            drawCrmDirectory();
        } else if (activeManagementTab === 'shifts') {
            drawShiftsPanel();
        }
    }

    function populateStaffSelector() {
        const select = document.getElementById('shift-staff-id');
        if (!select) return;
        select.innerHTML = '<option value="">-- Chọn nhân sự --</option>';
        staffRoster.forEach(s => {
            if (s.role !== 'manager') {
                const roleText = s.role === 'barista' ? 'Pha chế' : 'Phục vụ';
                select.innerHTML += `<option value="\${s.id}">\${s.name} (\${roleText})</option>`;
            }
        });
    }

    function suggestShiftHours() {
        const val = document.getElementById('shift-name-sel').value;
        const input = document.getElementById('shift-hours');
        if (!input) return;
        if (val === 'Ca sáng') {
            input.value = '06:00 - 12:00';
        } else if (val === 'Ca chiều') {
            input.value = '12:00 - 18:00';
        } else if (val === 'Ca tối') {
            input.value = '18:00 - 24:00';
        } else {
            input.value = '08:00 - 17:00';
        }
    }

    function drawShiftsPanel() {
        const tbody = document.getElementById('shifts-table-body');
        if (!tbody) return;
        tbody.innerHTML = '';

        let morningCount = 0;
        let afternoonCount = 0;
        let eveningCount = 0;

        shiftsList.forEach(s => {
            if (s.shiftName === 'Ca sáng') morningCount++;
            else if (s.shiftName === 'Ca chiều') afternoonCount++;
            else if (s.shiftName === 'Ca tối') eveningCount++;
        });

        const morningText = document.getElementById('shift-count-morning');
        const afternoonText = document.getElementById('shift-count-afternoon');
        const eveningText = document.getElementById('shift-count-evening');
        if (morningText) morningText.innerText = `\${morningCount} nhân sự`;
        if (afternoonText) afternoonText.innerText = `\${afternoonCount} nhân sự`;
        if (eveningText) eveningText.innerText = `\${eveningCount} nhân sự`;

        const list = shiftsList.filter(s => {
            return searchQuery === '' ||
                s.staffName.toLowerCase().includes(searchQuery) ||
                s.shiftName.toLowerCase().includes(searchQuery) ||
                s.shiftDate.includes(searchQuery) ||
                (s.notes && s.notes.toLowerCase().includes(searchQuery));
        });

        if (list.length === 0) {
            tbody.innerHTML = `<tr><td colspan="7" class="py-6 text-center text-coffee-milk italic">Không tìm thấy ca trực nào!</td></tr>`;
            return;
        }

        list.forEach(s => {
            const statusClr = s.status === 'Tăng ca'
                ? 'bg-orange-50 text-orange-800 border-orange-200'
                : s.status === 'Tan ca'
                    ? 'bg-gray-100 text-gray-700 border-gray-200'
                    : s.status === 'Vắng mặt'
                        ? 'bg-red-50 text-red-700 border-red-200'
                        : 'bg-emerald-50 text-emerald-800 border-emerald-200';

            tbody.innerHTML += `
                <tr class="hover:bg-coffee-light/25 transition-colors">
                    <td class="py-3 px-4 font-bold text-coffee-dark">\${s.staffName}</td>
                    <td class="py-3 px-4 font-mono font-bold text-coffee-milk">\${s.shiftDate}</td>
                    <td class="py-3 px-4">
                        <span class="text-[9.5px] font-bold px-2 py-0.5 border border-coffee-sand/70 rounded-full bg-coffee-light text-coffee-dark font-mono">
                            \${s.shiftName}
                        </span>
                    </td>
                    <td class="py-3 px-4 font-mono text-coffee-dark">\${s.hours}</td>
                    <td class="py-3 px-4">
                        <span class="text-[9.5px] font-bold px-2 py-0.5 border rounded-full \${statusClr}">
                            \${s.status}
                        </span>
                    </td>
                    <td class="py-3 px-4 text-coffee-milk italic text-[11px]">\${s.notes || '-'}</td>
                    <td class="py-3 px-4 text-center">
                        <div class="flex items-center justify-center gap-1.5">
                            <button onclick="openEditShiftModal('\${s.id}')" class="text-coffee-dark hover:text-coffee-rust font-bold cursor-pointer">Sửa</button>
                            <span class="text-coffee-sand">|</span>
                            <button onclick="deleteShiftItem('\${s.id}')" class="text-coffee-milk hover:text-red-650 cursor-pointer">Xoá</button>
                        </div>
                    </td>
                </tr>
            `;
        });
    }

    function openAddShiftModal() {
        document.getElementById('shift-id').value = '';
        document.getElementById('shift-staff-id').value = '';
        document.getElementById('shift-date').value = new Date().toISOString().split('T')[0];
        document.getElementById('shift-name-sel').value = 'Ca sáng';
        document.getElementById('shift-hours').value = '06:00 - 12:00';
        document.getElementById('shift-status-sel').value = 'Hoạt động';
        document.getElementById('shift-notes').value = '';

        document.getElementById('shift-modal-title').innerText = 'Lên ca trực mới';
        document.getElementById('shift-modal').classList.remove('hidden');
    }

    function closeShiftModal() {
        document.getElementById('shift-modal').classList.add('hidden');
    }

    function openEditShiftModal(id) {
        const s = shiftsList.find(x => x.id === id);
        if (!s) return;

        document.getElementById('shift-id').value = s.id;
        document.getElementById('shift-staff-id').value = s.staffId || '';
        document.getElementById('shift-date').value = s.shiftDate || '';
        document.getElementById('shift-name-sel').value = s.shiftName || 'Ca sáng';
        document.getElementById('shift-hours').value = s.hours || '06:00 - 12:00';
        document.getElementById('shift-status-sel').value = s.status || 'Hoạt động';
        document.getElementById('shift-notes').value = s.notes || '';

        document.getElementById('shift-modal-title').innerText = 'Chỉnh sửa ca trực';
        document.getElementById('shift-modal').classList.remove('hidden');
    }

    async function handleSaveShift(e) {
        e.preventDefault();
        const id = document.getElementById('shift-id').value;
        const staffId = document.getElementById('shift-staff-id').value;
        const shiftDate = document.getElementById('shift-date').value;
        const shiftName = document.getElementById('shift-name-sel').value;
        const hours = document.getElementById('shift-hours').value;
        const status = document.getElementById('shift-status-sel').value;
        const notes = document.getElementById('shift-notes').value;

        if (!staffId) {
            alert('Vui lòng chọn nhân viên làm việc!');
            return;
        }

        const payload = { id, staffId, shiftDate, shiftName, hours, status, notes };

        try {
            const res = await fetch('api/shifts', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                flashNotify('📅 Đã cập nhật thành công ca trực nhân viên!');
                closeShiftModal();
                loadAllData();
            } else {
                alert('Khởi tạo ca trực thất bại!');
            }
        } catch (err) {
            console.error(err);
        }
    }

    async function deleteShiftItem(id) {
        if (!confirm('Xóa ca trực này khỏi ca làm ngày hôm nay?')) return;
        try {
            const res = await fetch('api/shifts/delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id })
            });
            if (res.ok) {
                flashNotify('🗑️ Đã xoá bỏ nhiệm vụ ca trực.');
                loadAllData();
            }
        } catch (err) {
            console.error(err);
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
                            <span>\${s.name}</span>
                            \${otBadge}
                        </div>
                        <div class="text-[9.5px] text-coffee-milk font-mono flex items-center gap-1.5">
                            <span>User: <strong class="text-coffee-dark font-semibold">\${s.username || 'unspecified'}</strong></span>
                            <span>•</span>
                            <span>PIN: <strong class="text-coffee-rust">\${s.pin}</strong></span>
                        </div>
                    </td>
                    <td class="py-3 px-4">
                        <span class="text-[9.5px] font-bold uppercase tracking-wider px-2 py-0.5 border rounded-full \${roleBadge}">
                            \${roleName}
                        </span>
                    </td>
                    <td class="py-3 px-4 text-coffee-milk font-mono text-[11px]">
                        <div>\${s.shift}</div>
                    </td>
                    <td class="py-3 px-4">
                        <div class="space-y-2 py-1">
                            <div>
                                <span class="text-[9px] font-bold px-2 py-0.5 border rounded-full \${statusClr}">
                                    \${statusText}
                                </span>
                            </div>
                            
                            <div class="flex flex-wrap gap-1 max-w-[280px]">
                                <button onclick="updateStaffState(\${s.id}, 'Active')" class="text-[8px] font-bold bg-white hover:bg-emerald-50 border border-coffee-sand hover:border-emerald-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Kích hoạt lại / Hoạt động">
                                    🟢 Kích phục
                                </button>
                                <button onclick="updateStaffState(\${s.id}, 'Temp_Inactive')" class="text-[8px] font-bold bg-white hover:bg-amber-100 border border-coffee-sand hover:border-amber-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Khoá ngày hôm nay, tự động phục hồi hôm sau">
                                    ⏸️ Khóa tạm thời
                                </button>
                                <button onclick="updateStaffState(\${s.id}, 'Perm_Inactive')" class="text-[8px] font-bold bg-white hover:bg-red-100 border border-coffee-sand hover:border-red-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Khóa vĩnh viễn không tự phục hồi">
                                    🔒 Khóa vĩnh viễn
                                </button>
                                <button onclick="updateStaffState(\${s.id}, 'Off_Duty')" class="text-[8px] font-bold bg-white hover:bg-gray-100 border border-coffee-sand hover:border-gray-400 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Cần cho ra ca, tạm khóa hôm nay">
                                    🕊️ Cho Tan Làm
                                </button>
                                <button onclick="approveOvertime(\${s.id})" class="text-[8px] font-bold bg-[#FAF7EE] hover:bg-orange-50 border border-coffee-sand hover:border-orange-300 text-coffee-dark px-1.5 py-0.5 rounded cursor-pointer transition-colors" title="Phê duyệt quyền tăng ca">
                                    🕒 \${s.overtime ? 'Hủy tăng ca' : 'Duyệt Tăng ca'}
                                </button>
                            </div>
                        </div>
                    </td>
                    <td class="py-3 px-4 text-center">
                        <div class="flex items-center justify-center gap-2">
                            <button onclick="editRosterItem(\${s.id})" class="text-coffee-dark hover:text-coffee-rust text-xs font-bold font-sans cursor-pointer">
                                📝 Sửa
                            </button>
                            <span class="text-coffee-sand">|</span>
                            <button onclick="deleteRosterItem(\${s.id})" class="text-coffee-milk hover:text-red-600 text-xs cursor-pointer">
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
                        <div class="font-bold text-coffee-dark">\${c.name}</div>
                        <div class="text-[10px] text-coffee-milk font-mono font-bold">\${c.phone}</div>
                    </td>
                    <td class="py-3 px-4 font-mono text-coffee-dark text-[11px]">\${c.email || 'không có'}</td>
                    <td class="py-3 px-4">
                        <span class="text-[9.5px] font-bold px-2.5 py-0.5 border rounded-full \${rankBadge}">
                            \${c.rank}
                        </span>
                    </td>
                    <td class="py-3 px-4 font-mono font-bold text-coffee-rust text-xs">\${c.points} hạt</td>
                    <td class="py-3 px-4 text-coffee-milk italic text-[11px]">\${prefName}</td>
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
                const res = await fetch('api/staff', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(item)
                });
                if (res.ok) {
                    flashNotify(`🧑‍🤝‍🧑 Đã đổi trạng thái "\${item.name}" thành \${status}!`);
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
                const res = await fetch('api/staff', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(item)
                });
                if (res.ok) {
                    flashNotify(`🧑‍🤝‍🧑 Trạng thái Tăng ca của "\${item.name}" chỉnh thành: \${item.overtime ? 'CHO PHÉP TĂNG CA 🕒' : 'Không tăng ca'}`);
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
        if (!confirm('Xác nhận rút tên nhân viên này khỏi danh sách làm việc?')) return;
        try {
            const res = await fetch('api/staff/delete', {
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
            const res = await fetch('api/staff', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                if (editingStaffId !== null) {
                    alert(`🧑‍🤝‍🧑 Cập nhật tài khoản nhân sự "\${name}" thành công!`);
                } else {
                    alert(`🧑‍🤝‍🧑 Đăng ký hồ sơ nhân viên "\${name}" thành công! Có hiệu ứng trực ca lập tức.`);
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

    loadAllData();
</script>

    </main>

    <div id="shift-modal" class="hidden fixed inset-0 bg-coffee-dark/40 backdrop-blur-xs flex items-center justify-center z-50 p-4 animate-fade-in">
        <div class="bg-white border border-coffee-sand rounded-3xl p-6 shadow-2xl max-w-md w-full space-y-4">
            <h4 class="font-serif italic font-bold text-lg text-coffee-dark border-b border-coffee-light pb-2 flex items-center justify-between">
                <span id="shift-modal-title">Lên ca trực mới</span>
                <button onclick="closeShiftModal()" class="text-sm text-coffee-milk hover:text-coffee-rust cursor-pointer">✕</button>
            </h4>
            <form onsubmit="handleSaveShift(event)" class="space-y-4">
                <input type="hidden" id="shift-id">
                
                <div class="space-y-1">
                    <label class="text-[10px] font-bold uppercase text-coffee-milk block">Chọn Nhân viên trực</label>
                    <select id="shift-staff-id" required class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust cursor-pointer">
                    </select>
                </div>

                <div class="space-y-1">
                    <label class="text-[10px] font-bold uppercase text-coffee-milk block">Ngày phân ca</label>
                    <input type="date" id="shift-date" required class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                </div>

                <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block font-mono">Tên ca trực</label>
                        <select id="shift-name-sel" onchange="suggestShiftHours()" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust cursor-pointer">
                            <option value="Ca sáng">Ca sáng</option>
                            <option value="Ca chiều">Ca chiều</option>
                            <option value="Ca tối">Ca tối</option>
                            <option value="Toàn thời gian">Toàn thời gian</option>
                        </select>
                    </div>
                    <div class="space-y-1">
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block">Khung giờ trực</label>
                        <input type="text" id="shift-hours" required placeholder="06:00 - 12:00" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none focus:border-coffee-rust">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                    <div class="space-y-1">
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block">Trạng thái</label>
                        <select id="shift-status-sel" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl text-coffee-dark focus:outline-none focus:border-coffee-rust cursor-pointer font-semibold text-emerald-800">
                            <option value="Hoạt động" class="text-emerald-800">🟢 Hoạt động</option>
                            <option value="Tăng ca" class="text-amber-800">🕒 Tăng ca</option>
                            <option value="Tan ca" class="text-gray-800">🕊️ Đã tan ca</option>
                            <option value="Vắng mặt" class="text-red-800">❌ Vắng mặt</option>
                        </select>
                    </div>
                    <div class="space-y-1">
                        <label class="text-[10px] font-bold uppercase text-coffee-milk block">Ghi chú công việc</label>
                        <input type="text" id="shift-notes" placeholder="Trực quầy bar trà sữa" class="w-full text-xs px-3 py-2 bg-coffee-light border border-coffee-sand rounded-xl focus:outline-none">
                    </div>
                </div>

                <div class="flex gap-2.5 pt-2">
                    <button type="button" onclick="closeShiftModal()" class="flex-1 bg-coffee-light border border-coffee-sand/70 text-coffee-dark font-bold py-2.5 rounded-xl text-xs uppercase hover:bg-coffee-sand/20 cursor-pointer text-center">
                        Hủy bỏ
                    </button>
                    <button type="submit" class="flex-1 bg-coffee-rust text-white font-bold py-2.5 rounded-xl text-xs uppercase hover:bg-coffee-rust/95 cursor-pointer text-center">
                        Lưu ca trực 💾
                    </button>
                </div>
            </form>
        </div>
    </div>

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
