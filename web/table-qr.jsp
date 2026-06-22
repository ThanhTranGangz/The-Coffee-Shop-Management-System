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
                                   '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +                               '</button>' +
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
                        '<a href="staff-management.jsp" class="hover:text-coffee-rust transition-colors ' + (page === 'staff-management.jsp' ? 'text-coffee-dark font-bold' : 'text-coffee-milk') + ' font-semibold">Nhân sự</a>' +
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
    <script src="assets/js/qrcode-generator.js"></script>
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
                        <a href="dashboard.jsp" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">Dashboard</a>
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
    <div class="bg-white border border-coffee-sand/70 p-5 rounded-3xl shadow-xs flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
            <h2 class="text-xl font-serif italic font-bold text-coffee-dark flex items-center gap-2">
                <span>🖨️</span> Xuất các thẻ mã QR gọi món tại bàn
            </h2>
            <p class="text-xs text-coffee-milk font-medium">QR gọi món theo từng bàn.</p>
        </div>
        <button onclick="window.print()" class="bg-coffee-rust text-white font-bold py-2 px-4 rounded-xl text-xs uppercase transition-all cursor-pointer">
            🖨️ In trang tem (A4 Sheets)
        </button>
    </div>

    <div class="bg-[#2B1B17] text-[#FAF7EE] border border-[#A04423]/35 rounded-3xl p-5 shadow-sm grid grid-cols-1 lg:grid-cols-[1.1fr_1fr] gap-4">
        <div class="space-y-1.5">
            <p class="text-[10px] font-mono font-bold uppercase tracking-wider text-[#E5DEC9]">File QR</p>
            <h3 class="text-lg font-serif italic font-bold">Tải QR theo từng bàn</h3>
            <p class="text-xs text-[#E5DEC9] leading-5">
                PNG để in nhanh, SVG cho tem lớn.
            </p>
        </div>
        <div class="bg-[#FAF7EE] text-[#2B1B17] border border-[#E5DEC9] rounded-2xl p-4 text-xs leading-5">
            <p class="font-bold">Quy trình:</p>
            <p>Thêm bàn, tải QR, in và dán tại bàn.</p>
        </div>
    </div>

    <div id="qr-cards-grid" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
    </div>
</div>

<script>
    let tables = [];

    async function loadTableQr() {
        try {
            const r = await fetch('api/tables');
            if (r.ok) {
                tables = await r.json();
                drawTableQrList();
            }
        } catch (e) {
            console.error(e);
        }
    }

    function drawTableQrList() {
        const grid = document.getElementById('qr-cards-grid');
        if (!grid) return;
        grid.innerHTML = '';

        tables.forEach(table => {
            const tableCode = table.tableCode || table.id;
            const originLinkEnv = `\${window.location.protocol}//\${window.location.host}\${window.location.pathname.substring(0, window.location.pathname.lastIndexOf("/"))}/menu.jsp?tableCode=\${encodeURIComponent(tableCode)}`;
            const qrSvg = createLocalQrSvg(originLinkEnv, table.name);
            const qrBoxId = `qr-box-\${table.id.replace(/[^a-zA-Z0-9_-]/g, '')}`;

            const zoneName = table.zone === 'Ground Floor' ? 'Khu Nhà Trệt' : table.zone === 'Terrace' ? 'Khu Sân Vườn' : 'Khu Tầng Lửng';

            grid.innerHTML += `
                <div class="bg-white border-2 border-coffee-sand/75 rounded-3xl p-6 shadow-sm flex flex-col justify-between items-center text-center space-y-4 hover:border-coffee-rust/45 transition-colors relative">
                    <div class="space-y-0.5 border-b border-coffee-sand/40 pb-2 w-full text-center">
                        <span class="text-[8px] uppercase tracking-widest font-bold text-coffee-milk font-mono">TABLE SCAN TERMINAL</span>
                        <h4 class="font-serif italic font-bold text-coffee-rust text-lg">nhà cà phê<span class="font-sans text-coffee-dark">.</span></h4>
                    </div>

                    <div id="\${qrBoxId}" class="bg-coffee-light border border-coffee-sand/80 p-3 rounded-2xl shadow-2xs relative">
                        \${qrSvg}
                        <div class="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-coffee-rust text-white text-[9px] font-mono font-bold flex items-center justify-center border border-white">
                            ✓
                        </div>
                    </div>

                    <div class="space-y-1">
                        <h5 class="text-xl font-serif font-bold italic text-coffee-dark">\${table.name}</h5>
                        <p class="text-[10px] text-coffee-milk font-bold uppercase tracking-wide">\${zoneName} \u2022 Ghế: \${table.capacity}</p>
                        <p class="text-[10px] bg-coffee-dark text-white font-mono font-bold tracking-wider inline-block px-2 py-1 rounded-lg">\${tableCode}</p>
                        <p class="text-[9px] text-coffee-milk/70 font-mono italic break-all max-w-[200px] leading-snug pt-1">\${originLinkEnv}</p>
                    </div>

                    <div class="grid grid-cols-2 gap-2 w-full">
                        <button onclick="downloadQrSvg('\${table.id}', '\${escapeForJs(table.name)}', '\${escapeForJs(originLinkEnv)}')" class="bg-coffee-rust text-white text-[10px] font-bold py-2 rounded-xl uppercase tracking-wider">
                            Tải SVG
                        </button>
                        <button onclick="downloadQrPng('\${table.id}', '\${escapeForJs(table.name)}', '\${escapeForJs(originLinkEnv)}')" class="bg-white text-coffee-dark border border-coffee-sand text-[10px] font-bold py-2 rounded-xl uppercase tracking-wider">
                            Tải PNG
                        </button>
                    </div>

                    <div class="bg-coffee-light/40 border border-coffee-sand/40 p-2 rounded-xl text-[10px] leading-relaxed text-coffee-milk w-full">
                        📌 <strong>Hướng dẫn:</strong> Bật camera điện thoại, quét mã để mở đúng bàn và gọi đồ uống.
                    </div>
                </div>
            `;
        });
    }

    function createLocalQrSvg(text, label) {
        if (typeof qrcode !== 'function') {
            return `<div class="w-36 h-36 flex items-center justify-center text-[10px] text-red-700">Không tải được bộ tạo QR local</div>`;
        }
        const qr = qrcode(0, 'M');
        qr.addData(text);
        qr.make();
        return qr.createSvgTag(4, 3, `Mã QR \${label || ''}`, `\${label || 'Bàn'}`);
    }

    function escapeForJs(value) {
        return String(value || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '&quot;');
    }

    function safeFileName(value) {
        return String(value || 'table').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'table';
    }

    function downloadBlob(filename, blob) {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        URL.revokeObjectURL(link.href);
        link.remove();
    }

    function downloadQrSvg(tableId, tableName, linkText) {
        const svg = createLocalQrSvg(linkText, tableName);
        downloadBlob(`qr-\${safeFileName(tableName || tableId)}.svg`, new Blob([svg], { type: 'image/svg+xml;charset=utf-8' }));
    }

    function downloadQrPng(tableId, tableName, linkText) {
        if (typeof qrcode !== 'function') {
            alert('Không tải được bộ tạo QR local.');
            return;
        }
        const qr = qrcode(0, 'M');
        qr.addData(linkText);
        qr.make();
        const img = new Image();
        img.onload = () => {
            const canvas = document.createElement('canvas');
            canvas.width = 512;
            canvas.height = 512;
            const ctx = canvas.getContext('2d');
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
            canvas.toBlob(blob => {
                if (blob) {
                    downloadBlob(`qr-\${safeFileName(tableName || tableId)}.png`, blob);
                }
            }, 'image/png');
        };
        img.src = qr.createDataURL(8, 4);
    }

    loadTableQr();
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
