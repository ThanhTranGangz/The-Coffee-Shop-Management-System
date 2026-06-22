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
                <a href="menu.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Khách gọi món</a>
                <a href="order-status.jsp" class="hover:text-coffee-rust transition-colors text-coffee-dark font-bold">Kiểm tra đơn nước</a>
                <a href="member.jsp" class="hover:text-coffee-rust transition-colors text-coffee-milk">Khách thành viên</a>
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

<div class="max-w-xl w-full mx-auto space-y-6 animate-fade-in my-6">
    <div class="bg-white border border-coffee-sand rounded-3xl p-6 sm:p-8 shadow-sm space-y-4">
        <div class="text-center space-y-1">
            <span class="text-3xl">🔍</span>
            <h2 class="text-2xl font-serif font-bold text-coffee-dark">Trạng thái pha chế đơn</h2>
            <p class="text-xs text-coffee-milk">Nhập mã đơn của bạn để tra cứu tiến độ pha chế</p>
        </div>

        <div class="flex items-center gap-2 bg-coffee-light border border-coffee-sand p-2 rounded-2xl">
            <input id="lookup-order-number" type="text" inputmode="numeric" placeholder="Ví dụ: 101 hoặc #101" class="flex-1 text-xs font-bold text-coffee-dark border-none bg-transparent outline-none p-2">
            <button onclick="lookupOrderQueue()" class="bg-coffee-rust hover:bg-coffee-rust/95 text-white font-bold py-2 px-4 rounded-xl text-xs font-mono transition-transform cursor-pointer">
                TRA CỨU
            </button>
        </div>

        <div id="lookup-result-box" class="space-y-4 pt-2">
            <div class="text-center py-8 text-xs text-coffee-milk italic bg-coffee-light rounded-xl border border-coffee-sand/70">
                Vui lòng nhập mã đơn in trên thông báo sau khi gọi món.
            </div>
        </div>
    </div>
</div>

<script>
    let socket = null;

    async function loadLookupState() {
        const input = document.getElementById('lookup-order-number');
        const savedOrderNumber = getSavedOrderNumber();
        if (input && savedOrderNumber) {
            input.value = savedOrderNumber;
            lookupOrderQueue(true);
        } else {
            renderEmptyLookup('Vui lòng nhập mã đơn in trên thông báo sau khi gọi món.');
        }
    }

    function setupWebSocket() {
        const sockProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const endpoint = `\${sockProtocol}//\${window.location.host}\${window.location.pathname.substring(0, window.location.pathname.lastIndexOf("/"))}/ws`;
        socket = new WebSocket(endpoint);

        socket.onopen = () => {
            loadLookupState();
        };

        socket.onmessage = () => {
            const input = document.getElementById('lookup-order-number');
            if (input && input.value.trim()) {
                lookupOrderQueue(true);
                flashNotify('🔄 Tiến độ pha chế vừa khớp lệnh cập nhật mới!');
            }
        };

        socket.onclose = () => {
            setTimeout(setupWebSocket, 4000);
        };
    }

    function getSavedOrderNumber() {
        const latest = localStorage.getItem('last_order_number');
        if (latest) return latest;
        try {
            const tracked = JSON.parse(localStorage.getItem('guest_order_numbers') || '[]');
            if (tracked.length > 0) {
                return tracked[tracked.length - 1];
            }
        } catch (e) {
            console.warn(e);
        }
        return '';
    }

    function rememberOrderNumber(orderNumber) {
        if (!orderNumber) return;
        const orderText = String(orderNumber);
        localStorage.setItem('last_order_number', orderText);
        try {
            const tracked = JSON.parse(localStorage.getItem('guest_order_numbers') || '[]');
            const cleaned = tracked.filter(n => String(n) !== orderText);
            cleaned.push(orderText);
            localStorage.setItem('guest_order_numbers', JSON.stringify(cleaned.slice(-5)));
        } catch (e) {
            localStorage.setItem('guest_order_numbers', JSON.stringify([orderText]));
        }
    }

    function normalizeOrderNumber(value) {
        return String(value || '').replace('#', '').trim();
    }

    async function lookupOrderQueue(silent = false) {
        const orderNo = normalizeOrderNumber(document.getElementById('lookup-order-number').value);
        const resultBox = document.getElementById('lookup-result-box');
        
        if (!orderNo) {
            renderEmptyLookup('Vui lòng nhập mã đơn in trên thông báo sau khi gọi món.');
            return;
        }

        try {
            const res = await fetch(`api/orders/lookup?orderNumber=\${encodeURIComponent(orderNo)}`);
            if (!res.ok) {
                renderEmptyLookup('Không tìm thấy mã đơn này. Hãy kiểm tra lại mã trên thông báo gọi món.', 'Chưa tìm thấy đơn');
                return;
            }
            const order = await res.json();
            rememberOrderNumber(order.orderNumber);
            renderOrderTickets([order]);
            if (!silent) {
                flashNotify(`Đã tải trạng thái đơn #\${order.orderNumber}`);
            }
        } catch (e) {
            console.error(e);
            resultBox.innerHTML = `
                <div class="text-center py-8 text-xs text-red-700 bg-red-50 rounded-xl border border-red-200">
                    Không thể kết nối máy chủ để tra cứu đơn. Vui lòng thử lại.
                </div>
            `;
        }
    }

    function renderEmptyLookup(message, title = 'Chưa có dữ liệu') {
        const resultBox = document.getElementById('lookup-result-box');
        resultBox.innerHTML = `
            <div class="text-center py-10 bg-[#FAF7EE] border border-coffee-sand/70 rounded-2xl text-coffee-milk space-y-1.5 p-6">
                <span class="text-3xl text-coffee-sand block">✓</span>
                <p class="font-serif italic font-bold text-coffee-dark text-sm">\${title}</p>
                <p class="text-[10px]">\${message}</p>
            </div>
        `;
    }

    function renderOrderTickets(activeTickets) {
        const resultBox = document.getElementById('lookup-result-box');
        resultBox.innerHTML = '';
        activeTickets.forEach(o => {
            let statusBadge = 'bg-coffee-light text-coffee-milk border-coffee-sand/70';
            let statusVi = 'Đầu quầy nhận';
            if (o.status === 'Preparing') {
                statusBadge = 'bg-amber-100 text-amber-808 border-amber-200';
                statusVi = 'Bếp đang làm 🧑‍🍳';
            } else if (o.status === 'Ready') {
                statusBadge = 'bg-emerald-100 text-emerald-808 border-emerald-250 animate-pulse';
                statusVi = 'Đồ sẵn sàng bưng bạp ⚡';
            } else if (o.status === 'Served') {
                statusBadge = 'bg-coffee-sand text-coffee-dark border-coffee-sand';
                statusVi = 'Đã phục vụ xong';
            }

            let queueItemsHtml = '';
            o.items.forEach(it => {
                let itStatusText = 'Đang xếp hàng';
                let itStatusStyle = 'text-coffee-milk';
                if (it.status === 'Preparing') {
                    itStatusText = 'Đang pha chế...';
                    itStatusStyle = 'text-amber-800 font-bold';
                } else if (it.status === 'Ready') {
                    itStatusText = 'Sẵn sàng dáp bàn!';
                    itStatusStyle = 'text-emerald-800 font-bold';
                } else if (it.status === 'Served') {
                    itStatusText = 'Đã bưng dọn ✓';
                    itStatusStyle = 'text-coffee-milk line-through';
                }

                queueItemsHtml += `
                    <div class="flex justify-between items-center text-xs py-2 border-b border-coffee-sand/15">
                        <div class="space-y-0.5 pr-2">
                            <span class="font-bold text-coffee-dark">\${it.name} <span class="text-[10px] text-coffee-milk">x\${it.quantity}</span></span>
                            <p class="text-[9.5px] text-coffee-milk">Size \${it.customization ? it.customization.size : 'M'}</p>
                        </div>
                        <span class="\${itStatusStyle} text-[11px] font-medium">\${itStatusText}</span>
                    </div>
                `;
            });

            resultBox.innerHTML += `
                <div class="bg-white border border-coffee-sand/80 rounded-2xl p-4 space-y-3 shadow-2xs">
                    <div class="flex justify-between items-center border-b border-coffee-light pb-2">
                        <div>
                            <span class="text-[9px] font-mono tracking-wider bg-coffee-rust text-white font-bold px-2 py-0.5 rounded uppercase">ĐƠN KHÁCH #\${o.orderNumber}</span>
                            <p class="text-[10px] text-coffee-milk font-mono mt-0.5">\${o.tableName || 'Bàn'} · \${new Date(o.createdAt).toLocaleTimeString('vi-VN')}</p>
                        </div>
                        <span class="text-[9.5px] font-bold px-2 py-0.5 border rounded-full \${statusBadge}">
                            \${statusVi}
                        </span>
                    </div>
                    <div class="space-y-0.5">
                        \${queueItemsHtml}
                    </div>
                </div>
            `;
        });
    }

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
