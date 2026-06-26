const LANG_KEY = 'coffeshop_lang';
const dict = {
    vi: {
        home: 'Trang chủ', order: 'Gọi món', status: 'Tra đơn', login: 'Đăng nhập',
        dashboard: 'Dashboard', staffOrders: 'Pha chế', cashier: 'Thu ngân', runner: 'Bồi bàn', menuAdmin: 'Thực đơn', tablesAdmin: 'Bàn & QR', systemLogs: 'Log hệ thống',
        logout: 'Đăng xuất', language: 'Ngôn ngữ', refresh: 'Làm mới', save: 'Lưu', cancel: 'Huỷ', delete: 'Xoá', backToPrevious: 'Quay lại',
        heroEyebrow: 'Đặt món tại bàn', heroTitle: 'coffeshop', heroText: 'Chọn món, gửi đơn và theo dõi trạng thái ngay tại bàn.',
        homeCardTitle: 'Dành cho khách tại quán', homeFeatureMenu: 'Quét QR trên bàn để gọi món', homeFeatureStatus: 'Theo dõi đơn bằng mã đơn',
        openMenu: 'Quét QR tại bàn', staffLogin: 'Nhân viên', checkOrder: 'Kiểm tra đơn',
        roleChoose: 'Vị trí', pin: 'Mã PIN', demoPins: '',
        table: 'Bàn', quantity: 'Số lượng', size: 'Size', cart: 'Giỏ hàng', sendOrder: 'Gửi đơn', total: 'Tổng tiền',
        counterOrder: 'Gọi món tại quầy', orderForTable: 'Gọi món cho bàn', orderCreated: 'Đã tạo đơn',
        orderNumber: 'Mã đơn', orders: 'đơn', pending: 'Chờ xử lý', preparing: 'Đang pha', ready: 'Sẵn sàng', served: 'Đã phục vụ', cleared: 'Đã dọn',
        nameVi: 'Tên tiếng Việt', nameEn: 'Tên tiếng Anh', category: 'Nhóm', price: 'Giá', imagePath: 'Ảnh local', active: 'Đang bán', activeTable: 'Đang dùng', inactiveTable: 'Đã ẩn',
        note: 'Ghi chú', orderNote: 'Ghi chú đơn', notePlaceholder: 'Ít đá, ít đường, giao trước món nóng...', emptyCart: 'Chưa có món nào',
        orderError: 'Không gửi được đơn', notFound: 'Không tìm thấy đơn', tracking: 'Theo dõi đơn',
        trackCurrentTable: 'Đơn đang xử lý', noTableOrders: 'Bàn này chưa có đơn đang xử lý',
        operations: 'Vận hành quán', overview: 'Tổng quan', salesDashboard: 'Kinh doanh',
        menuCount: 'Món đang bán', activeOrderCount: 'Đơn đang mở', readyOrderCount: 'Chưa thanh toán', orderCount: 'Tổng đơn', revenue: 'Doanh thu',
        addNew: 'Thêm mới', itemInfo: 'Thông tin món', edit: 'Sửa', deleteItemConfirm: 'Xoá món này?',
        loginFailed: 'Đăng nhập không thành công',
        searchMenu: 'Tìm món, ví dụ: cà phê sữa...', all: 'Tất cả', addToCart: 'Thêm vào giỏ',
        cartSummary: 'Xem giỏ hàng', tableHelp: 'Chọn bàn trước khi gửi đơn',
        checkout: 'Xác nhận gọi món', orderSent: 'Đơn đã gửi cho quán', viewStatus: 'Theo dõi đơn',
        remove: 'Bỏ món', cartNote: 'Ghi chú cho quán', noMenu: 'Không thấy món phù hợp',
        noOrder: 'Chưa có đơn nào', nextStep: 'Chuyển trạng thái',
        newBaristaWork: 'Có đơn mới chờ pha chế',
        newCashierWork: 'Có đơn mới chờ thanh toán',
        newWaiterWork: 'Có việc mới cho bồi bàn',
        statusMoveFailed: 'Không chuyển được trạng thái',
        pendingColumn: 'Chờ xử lý', preparingColumn: 'Đang pha', readyColumn: 'Sẵn sàng', servedColumn: 'Đã phục vụ',
        serveColumn: 'Phục vụ', cleaningColumn: 'Chờ dọn',
        unpaid: 'Chưa thanh toán', paid: 'Đã thanh toán',
        collectedRevenue: 'Doanh thu đã thu', unpaidRevenue: 'Chưa thu', openRevenue: 'Đang xử lý',
        revenueToday: 'Hôm nay', revenueMonth: 'Tháng này', revenueYear: 'Năm nay',
        soldProducts: 'Sản phẩm đã bán', bestSeller: 'Bán chạy nhất', rangeBestSeller: 'Bán chạy trong khoảng này', noSalesData: 'Chưa có dữ liệu',
        today: 'Hôm nay', items: 'sản phẩm', paidOrders: 'Đơn đã thanh toán', topProducts: 'Top sản phẩm',
        revenueTrend: 'Biến động doanh thu', last7Days: '7 ngày',
        rangeDay: 'Ngày', rangeWeek: 'Tuần', rangeMonth: 'Tháng', rangeYear: 'Năm', rangeAll: 'Tất cả', rangeCustom: 'Thủ công',
        tableMap: 'Sơ đồ bàn', floor: 'Tầng', serving: 'Đang phục vụ', available: 'Sẵn sàng', needsCleaning: 'Chờ dọn', tableReady: 'Bàn đã sẵn sàng',
        transferTable: 'Đổi bàn', fromTable: 'Bàn hiện tại', toTable: 'Bàn mới', transferDone: 'Đã đổi bàn', noTransferTable: 'Không có bàn cần chuyển',
        details: 'Chi tiết', operationDetail: 'Vận hành',
        todayOverview: 'Tổng quan hôm nay',
        enterOrderNumber: 'Nhập mã đơn của bạn',
        orderItems: 'Món trong đơn',
        completePayment: 'Hoàn tất thanh toán', paymentDone: 'Đơn đã hoàn tất',
        roleAdmin: 'Admin', roleBarista: 'Pha chế', roleCashier: 'Thu ngân', roleRunner: 'Bồi bàn',
        qrBaseUrl: 'Link gốc QR',
        qrBaseHelp: 'Dùng địa chỉ mà điện thoại khách có thể truy cập, ví dụ IP cùng mạng.',
        tableInfo: 'Thông tin bàn', tableName: 'Tên bàn', tableNumber: 'Số bàn', floorNumber: 'Tầng', addTable: 'Thêm bàn',
        downloadQr: 'Tải QR', copyLink: 'Sao chép link', regenerateQr: 'Đổi mã QR', hideTable: 'Ẩn bàn', showTable: 'Hiện bàn',
        tableSaved: 'Đã lưu bàn', tableDeleted: 'Đã xoá bàn', copyDone: 'Đã sao chép link', deleteTableConfirm: 'Ẩn bàn này?',
        deleteTableHard: 'Xoá bàn', deleteTableConfirm1: 'Bàn sẽ bị xoá khỏi hệ thống. Tiếp tục?', deleteTableConfirm2: 'Nhập đúng tên bàn để xác nhận xoá:', confirmTextMismatch: 'Nội dung xác nhận không đúng.',
        regenerateQrConfirm: 'Đổi mã QR sẽ làm QR cũ không dùng được. Tiếp tục?',
        qrWelcomeTitle: 'Đã nhận bàn', qrMissingTable: 'Không tìm thấy bàn từ mã QR này.',
        hasSizes: 'Sản phẩm có size', sizeName: 'Tên size', extraPrice: 'Tiền chênh', addSize: 'Thêm size', baseSizeHelp: 'Size S dùng giá gốc.', fromDate: 'Từ ngày', toDate: 'Đến ngày', apply: 'Áp dụng',
        cashOnHand: 'Tiền mặt hiện có', cashCountBeforeLogout: 'Nhập tiền mặt hiện tại để đăng xuất', cashCountRequired: 'Cần nhập tiền mặt hiện tại trước khi đăng xuất.', cashCountInvalid: 'Số tiền mặt không hợp lệ.',
        cashHistory: 'Lịch sử tiền mặt', withdrawCash: 'Rút tiền mặt', withdrawAmount: 'Nhập số tiền cần rút', cashWithdrawn: 'Đã rút tiền mặt', adminWithdrawNotice: 'Quản lý vừa rút tiền mặt', cashCountSaved: 'Đã ghi nhận tiền mặt',
        cashPayment: 'Thanh toán', cashCount: 'Kiểm kê', adminWithdrawEvent: 'Admin rút tiền', selectedRange: 'Khoảng đang xem',
        cupsAvailable: 'Cốc hiện có', editCupStock: 'Sửa số cốc', updateCups: 'Cập nhật cốc', gotIt: 'Đã hiểu',
        adminPinTitle: 'Mã PIN quản trị', adminPinText: 'Nhập mã PIN để mở dashboard.', unlock: 'Mở khoá', adminPinInvalid: 'Sai mã PIN quản trị.',
        actorAll: 'Tất cả', actorGuest: 'Khách', actorAdmin: 'Admin', actorBarista: 'Pha chế', actorCashier: 'Thu ngân', actorRunner: 'Bồi bàn', noLogs: 'Chưa có log'
    },
    en: {
        home: 'Home', order: 'Order', status: 'Track', login: 'Sign in',
        dashboard: 'Dashboard', staffOrders: 'Barista', cashier: 'Cashier', runner: 'Waiter', menuAdmin: 'Menu', tablesAdmin: 'Tables & QR', systemLogs: 'System logs',
        logout: 'Log out', language: 'Language', refresh: 'Refresh', save: 'Save', cancel: 'Cancel', delete: 'Delete', backToPrevious: 'Back',
        heroEyebrow: 'Order at your table', heroTitle: 'coffeshop', heroText: 'Choose, order, and follow your drinks from the table.',
        homeCardTitle: 'For in-store guests', homeFeatureMenu: 'Scan the table QR to order', homeFeatureStatus: 'Track your order by code',
        openMenu: 'Scan table QR', staffLogin: 'Staff', checkOrder: 'Check order',
        roleChoose: 'Position', pin: 'PIN', demoPins: '',
        table: 'Table', quantity: 'Quantity', size: 'Size', cart: 'Cart', sendOrder: 'Send order', total: 'Total',
        counterOrder: 'Counter order', orderForTable: 'Order for table', orderCreated: 'Order created',
        orderNumber: 'Order number', orders: 'orders', pending: 'Pending', preparing: 'Preparing', ready: 'Ready', served: 'Served', cleared: 'Cleared',
        nameVi: 'Vietnamese name', nameEn: 'English name', category: 'Category', price: 'Price', imagePath: 'Local image', active: 'Active', activeTable: 'Active', inactiveTable: 'Hidden',
        note: 'Note', orderNote: 'Order note', notePlaceholder: 'Less ice, less sugar, serve hot items first...', emptyCart: 'No items yet',
        orderError: 'Could not send order', notFound: 'Order not found', tracking: 'Order tracking',
        trackCurrentTable: 'Orders in progress', noTableOrders: 'No active orders at this table',
        operations: 'Store operations', overview: 'Overview', salesDashboard: 'Sales',
        menuCount: 'Menu items', activeOrderCount: 'Open orders', readyOrderCount: 'Unpaid', orderCount: 'Total orders', revenue: 'Revenue',
        addNew: 'Add new', itemInfo: 'Item details', edit: 'Edit', deleteItemConfirm: 'Delete this item?',
        loginFailed: 'Sign in failed',
        searchMenu: 'Search drinks, for example: milk coffee...', all: 'All', addToCart: 'Add to cart',
        cartSummary: 'View cart', tableHelp: 'Choose a table before sending the order',
        checkout: 'Confirm order', orderSent: 'Order sent to the counter', viewStatus: 'Track order',
        remove: 'Remove', cartNote: 'Note for the cafe', noMenu: 'No matching items',
        noOrder: 'No orders yet', nextStep: 'Move status',
        newBaristaWork: 'New order waiting for barista',
        newCashierWork: 'New order waiting for payment',
        newWaiterWork: 'New waiter task',
        statusMoveFailed: 'Could not move status',
        pendingColumn: 'Pending', preparingColumn: 'Preparing', readyColumn: 'Ready', servedColumn: 'Served',
        serveColumn: 'Serve', cleaningColumn: 'Clean',
        unpaid: 'Unpaid', paid: 'Paid',
        collectedRevenue: 'Collected revenue', unpaidRevenue: 'Uncollected', openRevenue: 'In progress',
        revenueToday: 'Today', revenueMonth: 'This month', revenueYear: 'This year',
        soldProducts: 'Products sold', bestSeller: 'Best seller', rangeBestSeller: 'Best sellers in this range', noSalesData: 'No data yet',
        today: 'Today', items: 'products', paidOrders: 'Paid orders', topProducts: 'Top products',
        revenueTrend: 'Revenue movement', last7Days: '7 days',
        rangeDay: 'Day', rangeWeek: 'Week', rangeMonth: 'Month', rangeYear: 'Year', rangeAll: 'All', rangeCustom: 'Custom',
        tableMap: 'Table map', floor: 'Floor', serving: 'Serving', available: 'Available', needsCleaning: 'Needs cleaning', tableReady: 'Table is ready',
        transferTable: 'Move table', fromTable: 'Current table', toTable: 'New table', transferDone: 'Table moved', noTransferTable: 'No table to move',
        details: 'Details', operationDetail: 'Operations',
        todayOverview: 'Today overview',
        enterOrderNumber: 'Enter your order number',
        orderItems: 'Order items',
        completePayment: 'Complete payment', paymentDone: 'Order completed',
        roleAdmin: 'Admin', roleBarista: 'Barista', roleCashier: 'Cashier', roleRunner: 'Waiter',
        qrBaseUrl: 'QR base link',
        qrBaseHelp: 'Use the address guests can open on their phones, such as your LAN IP.',
        tableInfo: 'Table details', tableName: 'Table name', tableNumber: 'Table number', floorNumber: 'Floor', addTable: 'Add table',
        downloadQr: 'Download QR', copyLink: 'Copy link', regenerateQr: 'New QR code', hideTable: 'Hide table', showTable: 'Show table',
        tableSaved: 'Table saved', tableDeleted: 'Table deleted', copyDone: 'Link copied', deleteTableConfirm: 'Hide this table?',
        deleteTableHard: 'Delete table', deleteTableConfirm1: 'This table will be removed from the system. Continue?', deleteTableConfirm2: 'Type the table name to confirm deletion:', confirmTextMismatch: 'Confirmation text does not match.',
        regenerateQrConfirm: 'Changing the QR code makes the old QR unusable. Continue?',
        qrWelcomeTitle: 'Table detected', qrMissingTable: 'Could not find a table for this QR code.',
        hasSizes: 'Product has sizes', sizeName: 'Size name', extraPrice: 'Extra price', addSize: 'Add size', baseSizeHelp: 'Size S uses the base price.', fromDate: 'From', toDate: 'To', apply: 'Apply',
        cashOnHand: 'Cash on hand', cashCountBeforeLogout: 'Enter current cash before logging out', cashCountRequired: 'Current cash is required before logging out.', cashCountInvalid: 'Invalid cash amount.',
        cashHistory: 'Cash history', withdrawCash: 'Withdraw cash', withdrawAmount: 'Enter withdrawal amount', cashWithdrawn: 'Cash withdrawn', adminWithdrawNotice: 'Manager withdrew cash', cashCountSaved: 'Cash count saved',
        cashPayment: 'Payment', cashCount: 'Cash count', adminWithdrawEvent: 'Admin withdrawal', selectedRange: 'Selected range',
        cupsAvailable: 'Cups available', editCupStock: 'Edit cups', updateCups: 'Update cups', gotIt: 'Got it',
        adminPinTitle: 'Admin PIN', adminPinText: 'Enter the PIN to unlock the dashboard.', unlock: 'Unlock', adminPinInvalid: 'Incorrect admin PIN.',
        actorAll: 'All', actorGuest: 'Guest', actorAdmin: 'Admin', actorBarista: 'Barista', actorCashier: 'Cashier', actorRunner: 'Waiter', noLogs: 'No logs yet'
    }
};

function lang() { return localStorage.getItem(LANG_KEY) === 'en' ? 'en' : 'vi'; }
function t(key) { return (dict[lang()] && dict[lang()][key]) || key; }
function api(path, options) {
    return fetch('api' + path, Object.assign({ credentials: 'same-origin' }, options || {}));
}
function money(value) {
    return new Intl.NumberFormat(lang() === 'en' ? 'en-US' : 'vi-VN', { style: 'currency', currency: 'VND' }).format(value || 0);
}
function statusText(status) {
    const map = { Pending: 'pending', Preparing: 'preparing', Ready: 'ready', Served: 'served', Paid: 'paid', Cleared: 'cleared' };
    return t(map[status] || status);
}
function categoryText(category) {
    const vi = { Coffee: 'Cà phê', Tea: 'Trà', Special: 'Đặc biệt', Food: 'Bánh ngọt' };
    const en = { 'Cà phê': 'Coffee', 'Trà': 'Tea', 'Đặc biệt': 'Special', 'Bánh ngọt': 'Pastry' };
    if (lang() === 'vi') return vi[category] || category;
    return en[category] || category;
}
function setLang(value) {
    localStorage.setItem(LANG_KEY, value);
    applyI18n();
    if (window.renderPage) window.renderPage();
}
function nextLang() {
    return lang() === 'vi' ? 'en' : 'vi';
}
function toggleLang() {
    setLang(nextLang());
}
function applyI18n() {
    document.querySelectorAll('[data-i18n]').forEach(el => el.textContent = t(el.dataset.i18n));
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => el.placeholder = t(el.dataset.i18nPlaceholder));
    const select = document.getElementById('lang-select');
    if (select) select.value = lang();
    const toggle = document.getElementById('lang-toggle');
    if (toggle) {
        toggle.textContent = nextLang().toUpperCase();
        toggle.setAttribute('aria-label', lang() === 'vi' ? 'Switch to English' : 'Chuyển sang tiếng Việt');
        toggle.title = toggle.getAttribute('aria-label');
    }
}
function nav(role) {
    const admin = role === 'admin';
    const barista = role === 'barista';
    const cashier = role === 'cashier';
    const runner = role === 'runner';
    if (admin) {
        return `
            <a class="link" href="dashboard.jsp" data-i18n="dashboard">${t('dashboard')}</a>
            <a class="link" href="admin-tables.jsp" data-i18n="tablesAdmin">${t('tablesAdmin')}</a>
            <a class="link" href="admin-menu.jsp" data-i18n="menuAdmin">${t('menuAdmin')}</a>
            <a class="link" href="staff-orders.jsp" data-i18n="staffOrders">${t('staffOrders')}</a>
            <a class="link" href="cashier.jsp" data-i18n="cashier">${t('cashier')}</a>
            <a class="link" href="counter-order.jsp" data-i18n="counterOrder">${t('counterOrder')}</a>
            <a class="link" href="runner.jsp" data-i18n="runner">${t('runner')}</a>
            <a class="link" href="table-transfer.jsp" data-i18n="transferTable">${t('transferTable')}</a>
            <a class="link" href="system-logs.jsp" data-i18n="systemLogs">${t('systemLogs')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    if (barista) {
        return `
            <a class="link" href="staff-orders.jsp" data-i18n="staffOrders">${t('staffOrders')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    if (cashier) {
        return `
            <a class="link" href="cashier.jsp" data-i18n="cashier">${t('cashier')}</a>
            <a class="link" href="counter-order.jsp" data-i18n="counterOrder">${t('counterOrder')}</a>
            <a class="link" href="table-transfer.jsp" data-i18n="transferTable">${t('transferTable')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    if (runner) {
        return `
            <a class="link" href="runner.jsp" data-i18n="runner">${t('runner')}</a>
            <a class="link" href="table-transfer.jsp" data-i18n="transferTable">${t('transferTable')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    const tableCode = sessionStorage.getItem('selectedTableCode') || '';
    const tableName = sessionStorage.getItem('selectedTable') || '';
    const statusHref = tableCode
        ? `order-status.jsp?tableCode=${encodeURIComponent(tableCode)}`
        : (tableName ? `order-status.jsp?table=${encodeURIComponent(tableName)}` : 'order-status.jsp');
    return `
        <a class="link" href="menu.jsp" data-i18n="order">${t('order')}</a>
        <a class="link" href="${statusHref}" data-i18n="status">${t('status')}</a>
    `;
}
async function loadNav() {
    const res = await api('/auth/session');
    const session = res.ok ? await res.json() : {};
    const holder = document.getElementById('nav-links');
    if (holder) holder.innerHTML = nav(session.role || '');
    const brand = document.querySelector('.nav .brand');
    if (brand) {
        const homeByRole = {
            admin: 'dashboard.jsp',
            barista: 'staff-orders.jsp',
            cashier: 'cashier.jsp',
            runner: 'runner.jsp'
        };
        brand.href = homeByRole[session.role] || 'index.html';
    }
    applyI18n();
}
async function logout() {
    const sessionRes = await api('/auth/session');
    const session = sessionRes.ok ? await sessionRes.json() : {};
    const redirectTarget = session.role === 'admin' ? 'dashboard.jsp' : 'staff-login.jsp';
    if (session.role === 'cashier') {
        const cashRes = await api('/cash/status');
        const cash = cashRes.ok ? await cashRes.json() : { balance: 0 };
        const value = await inputModal({
            title: t('cashCountBeforeLogout'),
            message: `${t('cashOnHand')}: ${money(cash.balance)}`,
            value: String(cash.balance || 0),
            actionLabel: t('logout'),
            inputMode: 'numeric'
        });
        if (value === null) return;
        const amount = parseMoneyInput(value);
        if (!Number.isFinite(amount) || amount < 0) {
            alert(t('cashCountInvalid'));
            return;
        }
        const countRes = await api('/cash/count', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount })
        });
        if (!countRes.ok) {
            const err = await countRes.json().catch(() => ({}));
            alert(err.error || t('cashCountInvalid'));
            return;
        }
    }
    await api('/auth/logout', { method: 'POST' });
    window.location.href = redirectTarget;
}

function parseMoneyInput(value) {
    const raw = String(value || '').replace(/[^\d]/g, '');
    return raw ? Number(raw) : NaN;
}

function inputModal(options) {
    return new Promise(resolve => {
        const opts = Object.assign({ title: '', message: '', value: '', actionLabel: t('save'), inputMode: 'text' }, options || {});
        const overlay = document.createElement('div');
        overlay.className = 'app-modal-backdrop';
        overlay.innerHTML = `
            <section class="app-modal-card">
                <div>
                    <p class="eyebrow">${escapeModal(opts.title)}</p>
                    ${opts.message ? `<h2>${escapeModal(opts.message)}</h2>` : ''}
                </div>
                <input class="app-modal-input" inputmode="${escapeModal(opts.inputMode)}" value="${escapeModal(opts.value)}">
                <div class="app-modal-actions">
                    <button class="btn" type="button" data-modal-cancel>${t('cancel')}</button>
                    <button class="btn primary" type="button" data-modal-ok>${escapeModal(opts.actionLabel)}</button>
                </div>
            </section>
        `;
        document.body.appendChild(overlay);
        const input = overlay.querySelector('input');
        const cleanup = value => {
            overlay.remove();
            resolve(value);
        };
        overlay.querySelector('[data-modal-cancel]').addEventListener('click', () => cleanup(null));
        overlay.querySelector('[data-modal-ok]').addEventListener('click', () => cleanup(input.value));
        overlay.addEventListener('keydown', event => {
            if (event.key === 'Escape') cleanup(null);
            if (event.key === 'Enter') cleanup(input.value);
        });
        setTimeout(() => {
            input.focus();
            input.select();
        }, 30);
    });
}

function escapeModal(value) {
    return String(value || '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
}

function cashEventText(type) {
    const map = { PAYMENT: 'cashPayment', CASHIER_COUNT: 'cashCount', ADMIN_WITHDRAW: 'adminWithdrawEvent' };
    return t(map[type] || type);
}

function rememberWorkPage(page) {
    const knownPages = ['dashboard.jsp', 'staff-orders.jsp', 'cashier.jsp', 'runner.jsp'];
    if (knownPages.includes(page)) sessionStorage.setItem('lastWorkPage', page);
}

async function goBackToWork(defaultPage) {
    let role = '';
    try {
        const res = await api('/auth/session');
        const session = res.ok ? await res.json() : {};
        role = session.role || '';
    } catch (err) {}

    const fallbackByRole = {
        admin: 'dashboard.jsp',
        barista: 'staff-orders.jsp',
        cashier: 'cashier.jsp',
        runner: 'runner.jsp'
    };
    const allowedByRole = {
        admin: ['dashboard.jsp', 'staff-orders.jsp', 'cashier.jsp', 'runner.jsp'],
        barista: ['staff-orders.jsp'],
        cashier: ['cashier.jsp'],
        runner: ['runner.jsp']
    };
    const lastPage = sessionStorage.getItem('lastWorkPage') || '';
    const allowed = allowedByRole[role] || [];
    const target = (lastPage && (!allowed.length || allowed.includes(lastPage)))
        ? lastPage
        : (fallbackByRole[role] || defaultPage || 'staff-login.jsp');
    window.location.href = target;
}

function notifyWork(message) {
    let box = document.getElementById('work-toast');
    if (!box) {
        box = document.createElement('div');
        box.id = 'work-toast';
        box.className = 'work-toast';
        document.body.appendChild(box);
    }
    box.textContent = message;
    box.classList.add('show');
    clearTimeout(box.hideTimer);
    box.hideTimer = setTimeout(() => box.classList.remove('show'), 3200);
    playDing();
}

function playDing() {
    try {
        const AudioContext = window.AudioContext || window.webkitAudioContext;
        if (!AudioContext) return;
        const ctx = new AudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(880, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1320, ctx.currentTime + 0.08);
        gain.gain.setValueAtTime(0.0001, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.16, ctx.currentTime + 0.015);
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.22);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.24);
        setTimeout(() => ctx.close(), 320);
    } catch (err) {
        // Browsers may block sound until the first user gesture.
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const select = document.getElementById('lang-select');
    if (select) select.addEventListener('change', e => setLang(e.target.value));
    loadNav();
    applyI18n();
});
