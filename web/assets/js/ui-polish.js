(function () {
    'use strict';

    var replacements = [
        [/Dashboard panel/g, 'Dashboard'],
        [/Kitchen KDS screen/g, 'KDS pha chế'],
        [/Kitchen KDS/g, 'KDS pha chế'],
        [/Wait station/g, 'Wait station'],
        [/Wait station/g, 'Wait station'],
        [/Khách thành viên/g, 'Khách thành viên'],
        [/Danh sách order/g, 'Danh sách order'],
        [/In mã QR bàn/g, 'In mã QR bàn'],
        [/Kho Nguyên Liệu & Công Thức/g, 'Kho nguyên liệu & công thức'],
        [/Tồn Kho Hiện Tại/g, 'Tồn kho hiện tại'],
        [/Công Thức & Khả Dụng Món/g, 'Công thức & khả dụng món'],
        [/Nhật Ký Nhập Kho/g, 'Nhật ký nhập kho'],
        [/Nhật trình Order & Vận đơn POS/g, 'Nhật trình order & vận đơn POS'],
        [/Chọn đồ uống & Gọi món tại bàn/g, 'Chọn đồ uống & gọi món tại bàn'],
        [/Giao diện khách/g, 'Giao diện khách'],
        [/Quản lý Nhân sự/g, 'Quản lý nhân sự'],
        [/\s{2,}/g, ' ']
    ];

    function cleanText(value) {
        if (!value) return value;
        var next = value;
        replacements.forEach(function (item) {
            next = next.replace(item[0], item[1]);
        });
        return next;
    }

    var LANGUAGE_STORAGE_KEY = 'app_language';
    var appText = {
        vi: {
            close: 'Đóng',
            updated: 'Đã cập nhật.',
            navHome: 'Trang chủ',
            navStaffGate: 'Cổng nhân viên',
            navDashboard: 'Dashboard',
            navMenu: 'Thực đơn',
            navPromotions: 'Khuyến mãi',
            navReports: 'Doanh số',
            navStaff: 'Nhân sự',
            navInventory: 'Kho hàng',
            navOperations: 'Vận hành',
            navWaitstation: 'Wait station',
            navPos: 'Thu ngân POS',
            navKds: 'KDS pha chế',
            navOrders: 'Danh sách order',
            navQr: 'In mã QR bàn',
            navOrder: 'Gọi món',
            navGuestOrder: 'Khách gọi món',
            navMyOrder: 'Đơn nước của tôi',
            navCheckOrder: 'Kiểm tra đơn nước',
            navMember: 'Khách thành viên',
            roleManager: 'Quản lý',
            roleBarista: 'Pha chế',
            roleWaiter: 'Phục vụ',
            roleMember: 'Member',
            account: 'Tài khoản',
            logout: 'Đăng xuất',
            accessWarning: 'Vui lòng đăng nhập đúng vai trò trước khi sử dụng chức năng này.'
        },
        en: {
            close: 'Close',
            updated: 'Updated.',
            navHome: 'Home',
            navStaffGate: 'Staff gate',
            navDashboard: 'Dashboard',
            navMenu: 'Menu',
            navPromotions: 'Promotions',
            navReports: 'Sales',
            navStaff: 'Staff',
            navInventory: 'Inventory',
            navOperations: 'Operations',
            navWaitstation: 'Wait station',
            navPos: 'POS',
            navKds: 'Kitchen display',
            navOrders: 'Orders',
            navQr: 'Table QR',
            navOrder: 'Order',
            navGuestOrder: 'Guest order',
            navMyOrder: 'My order',
            navCheckOrder: 'Check order',
            navMember: 'Member',
            roleManager: 'Manager',
            roleBarista: 'Barista',
            roleWaiter: 'Waiter',
            roleMember: 'Member',
            account: 'Account',
            logout: 'Log out',
            accessWarning: 'Please sign in with the right role before using this feature.'
        }
    };

    var pageTranslations = {
        'nhà cà phê. — quản lý quán': 'nhà cà phê. — cafe management',
        'nhà cà phê. — quản trị thực đơn': 'nhà cà phê. — menu management',
        'nhà cà phê. — khuyến mãi': 'nhà cà phê. — promotions',
        'nhà cà phê. — Cổng thông tin hệ thống': 'nhà cà phê. — system portal',
        'nhà cà phê. — Cổng nội bộ nhân viên': 'nhà cà phê. — staff portal',
        'POS & Payment — nhà cà phê': 'POS & Payment — nhà cà phê',
        'Hôm nay bạn ghé quán theo cách nào?': 'How would you like to use the cafe today?',
        'Hệ thống trực tuyến': 'System online',
        'Bảo mật vai trò': 'Role protected',
        'Cổng nhân viên': 'Staff portal',
        'Dành riêng cho phục vụ, pha chế và quản lý. Sau khi đăng nhập, hệ thống tự đưa bạn vào đúng giao diện theo vai trò.': 'For waiters, baristas, and managers. After sign-in, the system opens the right workspace for your role.',
        'Đăng nhập': 'Sign in',
        'Nhập PIN': 'Enter PIN',
        'Không cần tài khoản': 'No account needed',
        'Khách vãng lai': 'Guest',
        'Xem thực đơn, chọn bàn trước khi gọi món và tra cứu đúng đơn của mình bằng mã đơn. Luồng này dành cho khách chưa có tài khoản.': 'Browse the menu, choose your table, place an order, and check only your own order by code.',
        'Mở thực đơn': 'Open menu',
        'Kiểm tra đơn': 'Check order',
        'Tích điểm & voucher': 'Points & vouchers',
        'Khách thành viên': 'Member customer',
        'Đăng nhập hội viên để xem điểm tích lũy, đổi voucher và gọi món với ưu đãi gắn với tài khoản của mình.': 'Sign in as a member to view points, redeem vouchers, and order with account benefits.',
        'Đăng nhập member': 'Member sign in',
        'Đăng ký': 'Register',
        'nhà cà phê © 2026': 'nhà cà phê © 2026',

        'Staff authentication': 'Staff authentication',
        'Hệ thống nội bộ': 'Internal system',
        'Cổng nội bộ.': 'Internal portal.',
        'Đăng nhập để vào ca làm việc, xử lý order, KDS và bảng quản lý quán.': 'Sign in to start a shift, handle orders, KDS, and management tools.',
        'Sẵn sàng': 'Ready',
        'Kết nối': 'Connected',
        'Nhập mã PIN': 'Enter PIN',
        'Về trang chính': 'Back to main page',
        'Tài khoản nhân viên, quản lý hoặc quầy pha chế.': 'Staff, manager, or barista account.',
        'Tên đăng nhập': 'Username',
        'Mật khẩu': 'Password',
        'Đăng nhập hệ thống': 'Sign in',
        'Đăng nhập tài khoản': 'Sign in',
        'Đăng nhập tài khoản 🔐': 'Sign in 🔐',
        'Quên tài khoản?': 'Forgot account?',
        'Cổng nhân viên': 'Staff portal',
        'Đăng nhập bằng PIN': 'Sign in with PIN',
        'Tài khoản demo': 'Demo accounts',
        'Tài khoản mẫu': 'Sample accounts',
        'Mã PIN nhân viên': 'Staff PIN',
        'Mã PIN POS': 'POS PIN',
        'Xác nhận PIN': 'Confirm PIN',
        'Quay lại': 'Back',
        'Đóng': 'Close',

        'Hội Viên Đăng Nhập': 'Member Sign In',
        'Đăng nhập để tích điểm và nhận ưu đãi.': 'Sign in to collect points and receive rewards.',
        'Số điện thoại đăng ký': 'Registered phone number',
        'Chưa có tài khoản? Nhấn đăng ký hội viên ngay 🎟️': 'No account yet? Register as a member 🎟️',
        'Tài khoản hội viên mẫu:': 'Sample member accounts:',
        'Ghi Danh Hội Viên': 'Member Registration',
        'Đăng ký mới để nhận ngay 10 hạt thưởng ban đầu!': 'Create a new account and receive 10 starter beans.',
        'Họ và tên': 'Full name',
        'Số điện thoại': 'Phone number',
        'Nhập lại mật khẩu': 'Confirm password',
        'Đăng ký ngay tài khoản 🎟️': 'Register account 🎟️',
        'Đã có tài khoản rồi? Trở lại Đăng nhập 🔐': 'Already have an account? Back to sign in 🔐',
        'Hạt Cà Phê tích lũy': 'Collected beans',
        'Cộng điểm thanh toán': 'Payment points',
        'Gọi món với tài khoản': 'Order with account',
        'Kiểm tra đơn của tôi': 'Check my order',
        'Voucher của tôi (Khả dụng gọi nước)': 'My vouchers',
        'Chọn voucher khi thanh toán.': 'Choose a voucher at checkout.',
        'Đổi quà bằng điểm tích lũy': 'Redeem rewards with points',
        'Dùng điểm để đổi voucher.': 'Use points to redeem vouchers.',
        'Quản lý món bán': 'Menu item management',
        'Danh sách món': 'Menu items',
        'Tạo món mới': 'New item',
        'Làm mới': 'Refresh',
        'Thêm món': 'Add item',
        'Chỉnh sửa món': 'Edit item',
        'Tên món': 'Item name',
        'Nhóm': 'Category',
        'Giá bán': 'Price',
        'Kích cỡ': 'Sizes',
        'Ảnh món': 'Item image',
        'Mô tả': 'Description',
        'Lưu món': 'Save item',
        'Huỷ': 'Cancel',
        'Quản lý voucher': 'Voucher management',
        'Danh sách voucher': 'Voucher list',
        'Tạo voucher mới': 'New voucher',
        'Thêm voucher': 'Add voucher',
        'Chỉnh sửa voucher': 'Edit voucher',
        'Mã voucher': 'Voucher code',
        'Tên hiển thị': 'Display name',
        'Mức giảm': 'Discount',
        'Giá đổi': 'Point cost',
        'Đang cho khách đổi': 'Available for redemption',
        'Lưu voucher': 'Save voucher',
        'Đang bật': 'Active',
        'Đã tắt': 'Inactive',

        'Báo cáo Doanh thu & Thống kê sản phẩm': 'Revenue & Product Reports',
        'Doanh thu và sản phẩm bán chạy.': 'Revenue and best sellers.',
        'Xuất báo cáo giấy': 'Print report',
        'Doanh số theo nhóm sản phẩm': 'Sales by product group',
        'Theo số món đã phục vụ.': 'By served items.',
        'Hiệu quả khai thác khu vực ngồi': 'Seating area performance',
        'Theo khu vực bàn.': 'By table area.',
        'Đồ uống bán chạy nhất ca': 'Best sellers this shift',
        'Báo cáo Doanh số & Tài chính lịch sử': 'Sales & Financial History',
        'Doanh thu, chi phí và lợi nhuận.': 'Revenue, cost, and profit.',
        'Năm 2024': 'Year 2024',
        'Năm 2025': 'Year 2025',
        'Năm 2026': 'Year 2026',
        'Đánh giá tài khóa': 'Fiscal review',

        'Kho Nguyên Liệu & Công Thức': 'Inventory & Recipes',
        'Tồn kho, nhập hàng và công thức pha chế.': 'Stock, purchasing, and recipes.',
        'Trạng thái:': 'Status:',
        'Ổn định': 'Stable',
        'Tồn Kho Hiện Tại': 'Current Stock',
        'Nhập Kho & Thanh Toán': 'Import & Payment',
        'Công Thức & Khả Dụng Món': 'Recipes & Availability',
        'Nhật Ký Nhập Kho': 'Import Logs',
        'Trạng thái tồn kho cà phê & phụ liệu': 'Coffee and ingredient stock',
        'Mức tồn và cảnh báo nguyên liệu.': 'Stock levels and ingredient alerts.',
        'Cập nhật tức thời': 'Refresh',
        'Phiếu đề xuất nhập hàng nguyên liệu': 'Ingredient import request',
        'Nhập số lượng cần bổ sung.': 'Enter quantities to restock.',
        'CHI TIẾT THANH TOÁN MUA HÀNG': 'PURCHASE PAYMENT DETAILS',
        'Phí giao hàng & thuế:': 'Delivery & tax:',
        'Tổng tiền cần chi:': 'Total to pay:',
        'Thanh toán & nhập kho': 'Pay & import',
        'Hoàn tất sẽ cộng hàng vào kho.': 'Completed items are added to stock.',
        'Đồ uống, Bánh ngọt & Định lượng cơ bản': 'Drinks, pastries & base recipes',
        'Định lượng cho một phần.': 'Recipe for one serving.',
        'Nhật ký chi phí nhập kho & thanh toán': 'Import cost & payment log',
        'Tổng hợp các đợt phát sinh hoá đơn mua hàng phụ liệu': 'Purchase invoice history',

        'Màn hình điều phối chế biến (Kitchen Display KDS)': 'Kitchen Display System',
        'Đơn pha chế đang chờ.': 'Orders waiting for preparation.',
        'Quầy bar chính': 'Main bar',
        'Hiện không có đơn nào cần làm!': 'No orders to prepare.',
        'Quầy bar đang trống.': 'The bar is clear.',

        'Nhật trình Order & Vận đơn POS': 'Order & POS Log',
        'Theo dõi đơn từ pha chế đến phục vụ.': 'Track orders from preparation to service.',
        'ĐỒNG BỘ MỚI': 'REFRESH',
        'Danh sách toàn bộ phiếu gọi nước phát sinh': 'All drink order tickets',
        'Kéo thả hoặc dọn dẹp các phiếu đã thu ngân': 'Drag or clear paid tickets.',
        'Số hoá đơn': 'Invoice No.',
        'Bàn phục vụ': 'Table',
        'Tình trạng': 'Status',
        'Tổng tiền': 'Total',
        'Tác vụ': 'Actions',

        'Quản lý nhân sự': 'Staff Management',
        'Tài khoản, hội viên và ca làm.': 'Accounts, members, and shifts.',
        'Nhân sự • khách hàng • ca làm': 'Staff • customers • shifts',
        'Tài khoản Nhân sự': 'Staff Accounts',
        'Hồ sơ Khách hàng CRM': 'Customer CRM',
        'Phân ca trực Shift': 'Shift Schedule',
        'Tìm kiếm nhanh...': 'Quick search...',
        'Danh sách tài khoản trực ca': 'Shift account list',
        'Quyền truy cập và trạng thái ca.': 'Access rights and shift status.',
        'Dữ liệu khách hàng hội viên (CRM)': 'Member customer data (CRM)',
        'Thông tin hội viên và hạng thưởng.': 'Member information and reward tier.',
        'Bảng phân lịch ca trực': 'Shift schedule',
        'Ca phục vụ và pha chế trong ngày.': 'Service and bar shifts today.',
        '+ Tạo ca trực mới 📅': '+ New shift 📅',
        'Đăng ký thêm Nhân sự': 'Add staff account',
        'Chỉnh sửa tài khoản': 'Edit account',
        'Ghi danh Roster 🧑‍🤝‍🧑': 'Save roster 🧑‍🤝‍🧑',
        'Cập nhật tài khoản 💾': 'Update account 💾',
        'Huỷ chỉnh sửa': 'Cancel edit',

        'Xuất các thẻ mã QR gọi món tại bàn': 'Export table ordering QR cards',
        'QR gọi món theo từng bàn.': 'Ordering QR for each table.',
        'In trang tem (A4 Sheets)': 'Print label sheet (A4)',
        'File QR': 'QR files',
        'Tải QR theo từng bàn': 'Download QR by table',
        'PNG để in nhanh, SVG cho tem lớn.': 'Use PNG for quick printing, SVG for larger labels.',
        'Quy trình:': 'Flow:',
        'Thêm bàn, tải QR, in và dán tại bàn.': 'Add table, download QR, print and place it on the table.',
        'Tải PNG': 'Download PNG',
        'Tải SVG': 'Download SVG',

        'Chưa chọn bàn phục vụ': 'No table selected',
        'Chọn bàn để xem đơn và thao tác phục vụ.': 'Select a table to view orders and service actions.',
        'Xác nhận Thu tiền POS': 'Confirm POS Payment',
        'Dọn bàn': 'Clear table',
        'Đổi bàn': 'Move table',
        'Gộp bàn': 'Merge tables',
        'Gọi thêm món': 'Add items',
        'Bàn trống': 'Empty table',
        'Đang phục vụ': 'Serving',
        'Sẵn sàng phục vụ': 'Ready to serve',

        'POS & Payment': 'POS & Payment',
        'Cashier workspace': 'Cashier workspace',
        'Thu ngân và chốt ca.': 'Cashier and shift closing.',
        'Ca thu ngân': 'Cashier shift',
        'Chưa mở ca': 'No open shift',
        'Tiền đầu ca': 'Opening cash',
        'Mở ca': 'Open shift',
        'Tiền cuối ca': 'Closing cash',
        'Đóng ca': 'Close shift',
        'Trạm thu ngân': 'Cashier station',
        'Chọn đơn và chốt thanh toán.': 'Select orders and complete payment.',
        'Đơn cần thu': 'Orders to collect',
        'Chưa thanh toán': 'Unpaid',
        'Làm mới': 'Refresh',
        'Hóa đơn đang chọn': 'Selected bill',
        'Chưa chọn đơn': 'No order selected',
        'Chọn một đơn ở danh sách bên trái.': 'Select an order from the list.',
        'Tổng cần thu': 'Amount due',
        'Tách bill': 'Split bill',
        'Ghi chú thu ngân': 'Cashier note',
        'Mã giao dịch / nội dung chuyển khoản': 'Transaction code / bank note',
        'Mã đối soát thanh toán.': 'Payment reference.',
        'Chốt thanh toán': 'Complete payment',
        'Tiền mặt': 'Cash',
        'Chuyển khoản': 'Bank transfer',
        'Thẻ': 'Card',
        'Khách đưa / ngân hàng báo': 'Paid amount / bank notice',
        'Cần thu': 'Due',
        'Tiền thừa': 'Change',
        'Phương thức': 'Method',
        'Xác nhận đã thanh toán': 'Confirm paid',
        'Xác nhận chuyển khoản': 'Confirm bank transfer',
        'Giao dịch gần đây': 'Recent payments',
        'Chưa có giao dịch.': 'No payments yet.',

        'Xác nhận đã thu tiền và dọn bàn?': 'Confirm payment received and clear table?',
        'Mã chuyển khoản': 'Transfer code',
        'Hoàn tất': 'Complete',
        'Hủy': 'Cancel',

        'Đóng/Mở cửa hàng tức thì': 'Open/Close shop now',
        'Tạm dừng nhận đơn mới.': 'Pause new orders.',
        'Quy trình giờ giấc dịch vụ': 'Service hours',
        'Giới hạn order theo giờ đóng ca.': 'Limit ordering by closing time.',
        'Mở khóa giới hạn thời gian': 'Unlock time limit',
        'Hoạt động POS': 'POS activity',
        'Ghi nhận biên lai và dọn dẹp bàn': 'Receipts and table clearing',
        'Đồng bộ biên nhận': 'Sync receipts',
        'Quản lý vận hành quán': 'Cafe operations management',
        'Tạo bàn mới': 'Create table',
        'Thêm nước uống mới': 'Add drink',
        'Tên nước uống': 'Drink name',
        'Nhóm menu': 'Menu group',
        'Bán giá niêm yết (₫)': 'List price (₫)',
        'Đưa lên danh mục thực đơn bán': 'Add to menu',

        'Kiểm tra đơn nước': 'Check drink order',
        'Nhập mã đơn để tra cứu.': 'Enter an order code to check status.',
        'Mã đơn': 'Order code',
        'Tra cứu': 'Search',
        'Đơn nước của tôi': 'My drink order',

        'Trang chủ': 'Home',
        'Doanh số': 'Sales',
        'Nhân sự': 'Staff',
        'Kho hàng': 'Inventory',
        'Vận hành': 'Operations',
        'Wait station': 'Wait station',
        'Thu ngân POS': 'POS',
        'KDS pha chế': 'Kitchen display',
        'Danh sách order': 'Orders',
        'In mã QR bàn': 'Table QR',
        'Giao diện khách': 'Guest view',
        'Khách gọi món': 'Guest order',
        'Báo cáo doanh số': 'Sales reports',
        'Quản lý nhân sự': 'Staff management',
        'Đăng xuất': 'Log out',
        'Tài khoản': 'Account',
        'Quản lý': 'Manager',
        'Pha chế': 'Barista',
        'Phục vụ': 'Waiter',

        'Đã cập nhật trạng thái đồng bộ!': 'Sync status updated.',
        'Đã cập nhật tình trạng kho hàng!': 'Inventory status updated.',
        'Đã cập nhật đơn.': 'Order updated.',
        'Không có đơn phù hợp bộ lọc.': 'No orders match this filter.',
        'Không có hóa đơn để xử lý.': 'No bill to process.',
        'Vui lòng chọn đơn cần thanh toán.': 'Please select an order to pay.',
        'Không thể chốt thanh toán.': 'Unable to complete payment.',
        'Đã thanh toán và trả bàn thành công.': 'Payment completed and table cleared.',
        'Vui lòng chọn đơn để xác nhận thanh toán.': 'Please select an order to confirm payment.',
        'Xác nhận chuyển khoản thất bại.': 'Bank transfer confirmation failed.',
        'Ngân hàng đã xác nhận chuyển khoản thành công.': 'Bank transfer confirmed successfully.',
        'Vui lòng chọn đơn cần tách bill.': 'Please select an order to split.',
        'Không thể tách bill.': 'Unable to split bill.',
        'Không mở được ca.': 'Unable to open shift.',
        'Không đóng được ca.': 'Unable to close shift.'
    };

    var phraseTranslations = [
        ['Vui lòng liên hệ Người quản lý (Manager) để đặt lại mật khẩu.', 'Please contact a manager to reset your password.'],
        ['Không thể kết nối máy chủ để tra cứu đơn. Vui lòng thử lại.', 'Cannot connect to the server to check the order. Please try again.'],
        ['Không tìm thấy mã đơn này. Hãy kiểm tra lại mã trên thông báo gọi món.', 'Order code not found. Please check the code shown after ordering.'],
        ['Vui lòng nhập mã đơn in trên thông báo sau khi gọi món.', 'Enter the order code shown after ordering.'],
        ['Vui lòng chỉ định số lượng nguyên liệu cần nhập kho trước khi tiến hành thanh toán!', 'Enter ingredient quantities before processing the purchase payment.'],
        ['Đăng ký hồ sơ nhân viên', 'Staff profile registered'],
        ['Cập nhật tài khoản nhân sự', 'Staff account updated'],
        ['Đăng nhập thành công với vai trò:', 'Signed in with role:'],
        ['Không thể kết nối máy chủ đăng nhập. Vui lòng thử lại.', 'Cannot connect to the sign-in server. Please try again.'],
        ['Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản.', 'Sign-in failed. Please check your account.'],
        ['Mã PIN không chính xác cho tài khoản này! Vui lòng kiểm tra lại.', 'Incorrect PIN for this account. Please check again.'],
        ['Đăng nhập PIN thành công. Chào mừng', 'PIN sign-in successful. Welcome'],
        ['Tài khoản nhân viên, quản lý hoặc quầy pha chế.', 'Staff, manager, or barista account.'],
        ['Chọn tài khoản ca trực và nhập mã PIN.', 'Choose the shift account and enter the PIN.'],
        ['Bạn hiện chưa tích lũy Voucher giảm giá nào.', 'You do not have any discount vouchers yet.'],
        ['Không thể đổi Voucher này.', 'This voucher cannot be redeemed.'],
        ['Có lỗi xảy ra trong quá trình đăng ký!', 'An error occurred during registration.'],
        ['Đã đăng xuất tài khoản thành viên thành công!', 'Member account logged out successfully.'],
        ['Đang tải trạng thái đơn', 'Loading order status'],
        ['Trạng thái pha chế đơn', 'Order preparation status'],
        ['Nhập mã đơn của bạn để tra cứu tiến độ pha chế', 'Enter your order code to check preparation progress'],
        ['Ví dụ: 101 hoặc #101', 'Example: 101 or #101'],
        ['TRA CỨU', 'SEARCH'],
        ['Tiến độ pha chế vừa khớp lệnh cập nhật mới!', 'Preparation progress was just updated.'],
        ['Đã tải trạng thái đơn', 'Order status loaded'],
        ['Chưa tìm thấy đơn', 'Order not found'],
        ['Chưa có dữ liệu', 'No data yet'],
        ['Đầu quầy nhận', 'Counter received'],
        ['Bếp đang làm', 'Kitchen is preparing'],
        ['Đồ sẵn sàng bưng bạp', 'Ready to serve'],
        ['Sẵn sàng dáp bàn', 'Ready for table service'],
        ['Đã bưng dọn', 'Served and cleared'],
        ['Đang xếp hàng', 'Queued'],
        ['ĐƠN KHÁCH', 'CUSTOMER ORDER'],
        ['Màn hình điều phối chế biến (Kitchen Display KDS)', 'Kitchen Display System'],
        ['Đơn pha chế đang chờ.', 'Orders waiting for preparation.'],
        ['Hiện không có đơn nào cần làm!', 'No orders to prepare.'],
        ['Quầy bar đang trống.', 'The bar is clear.'],
        ['Nhận order pha chế mới từ quầy dọn món!', 'New preparation order received from service.'],
        ['Đồng bộ pha chế trực tiếp', 'Live kitchen sync'],
        ['Mất kết nối KDS', 'KDS disconnected'],
        ['Mới chế', 'Just created'],
        ['phút trước', 'minutes ago'],
        ['Đã sẵn sàng', 'Ready'],
        ['Đã bưng', 'Served'],
        ['Ngọt:', 'Sweetness:'],
        ['Đá:', 'Ice:'],
        ['BÀN:', 'TABLE:'],
        ['HÓA ĐƠN', 'BILL'],
        ['ĐỢI PHÊ', 'WAITING'],
        ['ĐANG PHA', 'PREPARING'],
        ['ĐỒ XONG', 'READY'],
        ['Tiến độ múc:', 'Progress:'],
        ['Ghi chú bếp:', 'Kitchen note:'],
        ['HOÀN TẤT LÊN ĐỒ', 'MARK READY'],
        ['Xuất các thẻ mã QR gọi món tại bàn', 'Export table ordering QR cards'],
        ['QR gọi món theo từng bàn.', 'Ordering QR by table.'],
        ['In trang tem (A4 Sheets)', 'Print label sheet (A4)'],
        ['Tải QR theo từng bàn', 'Download QR by table'],
        ['PNG để in nhanh, SVG cho tem lớn.', 'Use PNG for quick printing, SVG for larger labels.'],
        ['Thêm bàn, tải QR, in và dán tại bàn.', 'Add a table, download the QR, print it, and place it on the table.'],
        ['Khu Nhà Trệt', 'Ground floor'],
        ['Khu Sân Vườn', 'Terrace'],
        ['Khu Tầng Lửng', 'Mezzanine'],
        ['Ghế:', 'Seats:'],
        ['Hướng dẫn:', 'Guide:'],
        ['Bật camera điện thoại, quét mã để mở đúng bàn và gọi đồ uống.', 'Open the phone camera, scan the code, and order for the right table.'],
        ['Không tải được bộ tạo QR local', 'Cannot load the local QR generator'],
        ['Mã QR', 'QR code'],
        ['Sơ đồ tầng lầu:', 'Floor map:'],
        ['Tất cả', 'All'],
        ['Trệt', 'Ground'],
        ['Sân vườn', 'Terrace'],
        ['Tầng lửng', 'Mezzanine'],
        ['Bàn Trống', 'Empty table'],
        ['Đang Phục Vụ', 'Serving'],
        ['Pha Xong (Trực trà)', 'Ready from bar'],
        ['Chờ dọn bàn', 'Waiting to clear'],
        ['Chưa chọn bàn phục vụ', 'No service table selected'],
        ['Chọn bàn để xem đơn và thao tác phục vụ.', 'Select a table to view orders and service actions.'],
        ['Thêm đồ uống bổ sung', 'Add extra drinks'],
        ['Gọi món tại quầy cho bàn khách hàng đang phục vụ', 'Order at the counter for the table being served.'],
        ['Tìm đồ uống...', 'Search drinks...'],
        ['Gọi món bổ sung', 'Add-on order'],
        ['Mỗi ý phụ cách bằng gạch chéo...', 'Separate notes with slashes...'],
        ['Tổng thanh toán:', 'Payment total:'],
        ['Xác nhận Thu tiền POS', 'Confirm POS payment'],
        ['Dọn bàn', 'Clear table'],
        ['Đổi bàn', 'Move table'],
        ['Gộp bàn', 'Merge tables'],
        ['Điêu chuyển vị trí bàn:', 'Moving table:'],
        ['Vui lòng chọn một bàn đích khác trên sơ đồ bên dưới để hoàn tất...', 'Choose another target table on the map below to finish.'],
        ['Báo cáo Doanh thu & Thống kê sản phẩm', 'Revenue & Product Reports'],
        ['Doanh thu và sản phẩm bán chạy.', 'Revenue and best sellers.'],
        ['Xuất báo cáo giấy', 'Print report'],
        ['Doanh số theo nhóm sản phẩm', 'Sales by product group'],
        ['Theo số món đã phục vụ.', 'By served items.'],
        ['Hiệu quả khai thác khu vực ngồi', 'Seating area performance'],
        ['Theo khu vực bàn.', 'By table area.'],
        ['Đồ uống bán chạy nhất ca', 'Best sellers this shift'],
        ['Báo cáo Doanh số & Tài chính lịch sử', 'Sales & Financial History'],
        ['Doanh thu, chi phí và lợi nhuận.', 'Revenue, cost, and profit.'],
        ['Tổng doanh thu cả năm', 'Total yearly revenue'],
        ['Tổng chi phí vận hành', 'Total operating expenses'],
        ['Lợi nhuận ròng', 'Net profit'],
        ['Trạng thái tài chính', 'Financial status'],
        ['Đang tính...', 'Calculating...'],
        ['Kinh doanh có Lãi', 'Profitable'],
        ['Kinh doanh Thua lỗ', 'Loss-making'],
        ['Hòa vốn cân bằng', 'Break-even'],
        ['món', 'items'],
        ['ly', 'cups'],
        ['hóa đơn', 'bills'],
        ['Cà phê truyền thống', 'Traditional coffee'],
        ['Trà phin mộc hoa quả', 'Fruit tea'],
        ['Đặc sản sữa quầy bar', 'House milk specialties'],
        ['Bánh ngọt lò nướng Pháp', 'French pastries'],
        ['Kho Nguyên Liệu & Công Thức', 'Inventory & Recipes'],
        ['Tồn kho, nhập hàng và công thức pha chế.', 'Stock, imports, and recipes.'],
        ['Tồn Kho Hiện Tại', 'Current Stock'],
        ['Nhập Kho & Thanh Toán', 'Import & Payment'],
        ['Công Thức & Khả Dụng Món', 'Recipes & Availability'],
        ['Nhật Ký Nhập Kho', 'Import Logs'],
        ['Trạng thái tồn kho cà phê & phụ liệu', 'Coffee and ingredient stock'],
        ['Mức tồn và cảnh báo nguyên liệu.', 'Stock levels and ingredient alerts.'],
        ['Cập nhật tức thời', 'Refresh'],
        ['Phiếu đề xuất nhập hàng nguyên liệu', 'Ingredient import request'],
        ['Nhập số lượng cần bổ sung.', 'Enter quantities to restock.'],
        ['CHI TIẾT THANH TOÁN MUA HÀNG', 'PURCHASE PAYMENT DETAILS'],
        ['Phí giao hàng & thuế:', 'Delivery & tax:'],
        ['Miễn phí', 'Free'],
        ['Tổng tiền cần chi:', 'Total to pay:'],
        ['Thanh toán & nhập kho', 'Pay & import'],
        ['Hoàn tất sẽ cộng hàng vào kho.', 'Completed items will be added to stock.'],
        ['Đồ uống, Bánh ngọt & Định lượng cơ bản', 'Drinks, pastries & base recipes'],
        ['Định lượng cho một phần.', 'Recipe for one serving.'],
        ['Nhật ký chi phí nhập kho & thanh toán', 'Import cost & payment log'],
        ['Tổng hợp các đợt phát sinh hoá đơn mua hàng phụ liệu', 'Purchase invoice history'],
        ['Thời gian thanh toán', 'Payment time'],
        ['Mã giao dịch', 'Transaction code'],
        ['Chi tiết nguyên liệu nhập', 'Imported ingredients'],
        ['Số tiền đã trả', 'Paid amount'],
        ['Hết nguyên liệu', 'Out of ingredients'],
        ['Nguyên liệu sắp hết', 'Low ingredients'],
        ['Hết hàng', 'Out of stock'],
        ['Sắp hết hàng', 'Low stock'],
        ['Đầy đủ', 'Full'],
        ['Tồn hiện có:', 'Current stock:'],
        ['Đơn giá nhập hộ:', 'Import unit cost:'],
        ['Tồn thực:', 'Actual stock:'],
        ['Đơn giá mua:', 'Purchase unit price:'],
        ['Nhập số...', 'Enter qty...'],
        ['Chưa chọn nguyên liệu để thanh toán nhập hàng.', 'No ingredients selected for import payment.'],
        ['Đang thanh toán chi quỹ...', 'Processing purchase payment...'],
        ['Thanh toán thành công! Đã chi quỹ:', 'Payment successful. Spent:'],
        ['Giao dịch thất bại:', 'Transaction failed:'],
        ['Đã xảy ra lỗi kết nối khi thanh toán mua hàng.', 'Connection error while processing purchase payment.'],
        ['Chưa có định lượng cố định.', 'No fixed recipe yet.'],
        ['Nguyên liệu định lượng định sẵn:', 'Preset recipe ingredients:'],
        ['Sẵn sàng bán', 'Available for sale'],
        ['Giá bán gốc niêm yết:', 'Base list price:'],
        ['Chưa ghi nhận giao dịch chi quỹ nhập kho nguyên liệu nào.', 'No ingredient purchase transactions recorded yet.'],
        ['Nhập phụ liệu tổng hợp', 'General ingredient import'],
        ['Đồng bộ kho thực tế', 'Live inventory sync'],
        ['Đã ghi nhận nghiệp vụ mới, tồn kho đã cập nhật!', 'New inventory transaction recorded. Stock updated.'],
        ['Quản lý nhân sự', 'Staff Management'],
        ['Tài khoản, hội viên và ca làm.', 'Accounts, members, and shifts.'],
        ['Nhân sự • khách hàng • ca làm', 'Staff • customers • shifts'],
        ['Tài khoản Nhân sự', 'Staff Accounts'],
        ['Hồ sơ Khách hàng CRM', 'Customer CRM'],
        ['Phân ca trực Shift', 'Shift Schedule'],
        ['Danh sách tài khoản trực ca', 'Shift account list'],
        ['Quyền truy cập và trạng thái ca.', 'Access rights and shift status.'],
        ['Dữ liệu khách hàng hội viên (CRM)', 'Member customer data (CRM)'],
        ['Thông tin hội viên và hạng thưởng.', 'Member information and reward tier.'],
        ['Bảng phân lịch ca trực', 'Shift schedule'],
        ['Ca phục vụ và pha chế trong ngày.', 'Service and bar shifts today.'],
        ['Tạo ca trực mới', 'New shift'],
        ['Ca Sáng', 'Morning shift'],
        ['Ca Chiều', 'Afternoon shift'],
        ['Ca Tối', 'Evening shift'],
        ['Đăng ký thêm Nhân sự', 'Add staff account'],
        ['Chỉnh sửa tài khoản', 'Edit account'],
        ['Ghi danh Roster', 'Save roster'],
        ['Cập nhật tài khoản', 'Update account'],
        ['Huỷ chỉnh sửa', 'Cancel edit'],
        ['Lên ca trực mới', 'New shift'],
        ['Chỉnh sửa ca trực', 'Edit shift'],
        ['Vui lòng chọn nhân viên làm việc!', 'Please choose a staff member.'],
        ['Đã cập nhật thành công ca trực nhân viên!', 'Staff shift updated successfully.'],
        ['Khởi tạo ca trực thất bại!', 'Could not create shift.'],
        ['Đã xoá bỏ nhiệm vụ ca trực.', 'Shift assignment deleted.'],
        ['Giám sát', 'Supervisor'],
        ['Tăng ca', 'Overtime'],
        ['Kích hoạt lại / Hoạt động', 'Reactivate / Active'],
        ['Khoá ngày hôm nay, tự động phục hồi hôm sau', 'Lock today, auto restore tomorrow'],
        ['Khóa vĩnh viễn không tự phục hồi', 'Permanent lock'],
        ['Cần cho ra ca, tạm khóa hôm nay', 'Take off shift, lock today'],
        ['Phê duyệt quyền tăng ca', 'Approve overtime'],
        ['Hủy tăng ca', 'Cancel overtime'],
        ['Duyệt Tăng ca', 'Approve overtime'],
        ['Cà phê Espresso sữa', 'Milk espresso coffee'],
        ['Trà Trái Cây mát', 'Fresh fruit tea'],
        ['Đặc sản Sữa lắc', 'House milkshake'],
        ['Bánh croissants', 'Croissants'],
        ['Đã đổi trạng thái', 'Status changed'],
        ['Trạng thái Tăng ca', 'Overtime status'],
        ['CHO PHÉP TĂNG CA', 'OVERTIME ALLOWED'],
        ['Không tăng ca', 'No overtime'],
        ['Đã bãi miễn nhân viên khỏi danh sách Roster.', 'Staff removed from roster.'],
        ['Mã PIN POS nhanh phải đúng 4 ký tự số!', 'Quick POS PIN must be exactly 4 digits.'],
        ['Có lỗi xảy ra khi lưu nhân tố!', 'An error occurred while saving staff data.'],
        ['Quản lý quán cafe', 'Cafe management'],
        ['Bán hàng', 'Sales'],
        ['Đơn hàng', 'Orders'],
        ['Thu ngân', 'Cashier'],
        ['Quản lý bàn', 'Table management'],
        ['Mã QR bàn', 'Table QR'],
        ['Thực đơn', 'Menu'],
        ['Nhân viên', 'Staff'],
        ['Khách hàng', 'Customers'],
        ['Báo cáo', 'Reports'],
        ['Khuyến mãi', 'Promotions'],
        ['Cài đặt cá nhân', 'Personal settings'],
        ['Xem thông tin', 'View profile'],
        ['Xin chào,', 'Hello,'],
        ['Chúc bạn một ngày làm việc hiệu quả!', 'Have a productive workday.'],
        ['Đang hoạt động', 'Active'],
        ['Tháng', 'Month'],
        ['Hôm nay', 'Today'],
        ['Hôm qua', 'Yesterday'],
        ['Thông báo hôm nay', 'Today notifications'],
        ['Đã xem hết', 'All read'],
        ['Thấp hàng tồn kho', 'Low inventory'],
        ['Nguyên liệu', 'Ingredient'],
        ['sắp cạn kiệt', 'is nearly depleted'],
        ['còn', 'remaining'],
        ['Hoá đơn thanh toán', 'Payment bill'],
        ['thanh toán hoá đơn', 'paid bill'],
        ['thành công', 'successfully'],
        ['Lịch phân ca mới', 'New shift schedule'],
        ['Đã cập nhật ca trực tuần này.', 'This week shift schedule was updated.'],
        ['Mã QR gọi món tại bàn', 'Table ordering QR'],
        ['Tải QR cho từng bàn ngay tại khu quản trị', 'Download QR codes for each table in admin'],
        ['Doanh thu hôm nay', 'Today revenue'],
        ['so với hôm qua', 'vs yesterday'],
        ['Đơn hàng hôm nay', 'Today orders'],
        ['Bàn đang phục vụ', 'Tables in service'],
        ['đáp ứng', 'occupied'],
        ['Nguyên liệu sắp hết', 'Low ingredients'],
        ['Bàn đang phục vụ', 'Tables in service'],
        ['Danh sách thực tế tại sơ đồ', 'Live list from floor map'],
        ['Trống', 'Empty'],
        ['Top nước uống bán chạy nhất', 'Best-selling drinks'],
        ['Cơ cấu tiêu dùng tại quầy POS Family', 'POS consumption mix'],
        ['Vật tư sắp hết', 'Low supplies'],
        ['Hàng tồn báo động đỏ', 'Critical stock alerts'],
        ['Thao tác nhanh', 'Quick actions'],
        ['Tạo đơn mới', 'Create order'],
        ['Thêm bàn nhanh', 'Quick add table'],
        ['Tải QR bàn', 'Download table QR'],
        ['Nhập kho vật tư', 'Import supplies'],
        ['Thêm món uống', 'Add drink'],
        ['Xem báo cáo', 'View reports'],
        ['Đóng/Mở cửa hàng tức thì', 'Open/close shop now'],
        ['Tạm dừng nhận đơn mới.', 'Pause new orders.'],
        ['Quy trình giờ giấc dịch vụ', 'Service hours'],
        ['Giới hạn order theo giờ đóng ca.', 'Limit ordering by closing time.'],
        ['Ca sáng:', 'Morning shift:'],
        ['Ca chiều:', 'Afternoon shift:'],
        ['Ca tối:', 'Evening shift:'],
        ['Hết hoạt động', 'Closed'],
        ['Giới hạn giờ đang bật', 'Time limit enabled'],
        ['Sau 22:00 khách không thể gửi đơn.', 'After 22:00 customers cannot send orders.'],
        ['Hoạt động POS', 'POS activity'],
        ['Ghi nhận biên lai và dọn dẹp bàn', 'Receipts and table clearing'],
        ['Đồng bộ biên nhận', 'Sync receipts'],
        ['Quản lý vận hành quán', 'Cafe operations management'],
        ['Tạo bàn mới', 'Create table'],
        ['Thêm nước uống mới', 'Add drink'],
        ['Tên nước uống', 'Drink name'],
        ['Nhóm menu', 'Menu group'],
        ['Bán giá niêm yết', 'List price'],
        ['Đưa lên danh mục thực đơn bán', 'Add to sale menu'],
        ['Đăng nhập nội bộ', 'Staff sign in'],
        ['Tên tài khoản', 'Username'],
        ['Nhập username', 'Enter username'],
        ['Ghi nhớ tài khoản', 'Remember account'],
        ['Quên mật khẩu?', 'Forgot password?'],
        ['Đăng nhập bằng PIN', 'Sign in with PIN'],
        ['Tài khoản demo', 'Demo accounts'],
        ['Xem tài khoản demo', 'Show demo accounts'],
        ['Tài khoản mẫu', 'Sample accounts'],
        ['Mã PIN nhân viên', 'Staff PIN'],
        ['Mã PIN POS', 'POS PIN'],
        ['Xác nhận PIN', 'Confirm PIN'],
        ['Tài khoản', 'Account'],
        ['Mã PIN', 'PIN'],
        ['MK', 'Pass'],
        ['Vào', 'Enter'],
        ['Chào mừng', 'Welcome'],
        ['Quay lại', 'Back'],
        ['Chức năng khác', 'More'],
        ['Thao tác trực', 'Operations'],
        ['Báo cáo doanh số', 'Sales reports'],
        ['Kho nguyên liệu', 'Inventory'],
        ['Giao diện khách', 'Guest view'],
        ['Đang kết nối...', 'Connecting...'],
        ['Đang đồng bộ...', 'Syncing...'],
        ['Đã cập nhật trạng thái đồng bộ!', 'Sync status updated.'],
        ['Mất kết nối', 'Disconnected'],
        ['Quy trình:', 'Flow:'],
        ['Cảnh báo bảo mật:', 'Security warning:'],
        ['Bạn không có quyền truy cập', 'You do not have permission to access'],
        ['khu vực Phục vụ / Wait station', 'the waiter / wait station area'],
        ['khu vực Quầy pha chế (KDS)', 'the barista area (KDS)'],
        ['khu vực Bảng điều khiển Quản lý', 'the manager dashboard'],
        ['khu vực Kho nguyên liệu', 'the inventory area'],
        ['Vui lòng đăng nhập', 'Please sign in'],
        ['Đã đăng xuất tài khoản làm việc POS!', 'POS work account has been logged out.'],
        ['Chuyển hướng về cổng portal.', 'Redirecting to the portal.'],
        ['Đang tải', 'Loading'],
        ['Đang mở', 'Open'],
        ['Đã đóng', 'Closed'],
        ['Đã thanh toán', 'Paid'],
        ['Đang pha', 'Preparing'],
        ['Chờ quầy', 'Waiting'],
        ['Sẵn sàng', 'Ready'],
        ['Đã phục vụ', 'Served'],
        ['Tổng chi', 'Total cost'],
        ['Tổng tiền', 'Total'],
        ['Thành tiền', 'Total'],
        ['Số lượng', 'Quantity'],
        ['Đơn giá', 'Unit price'],
        ['Tồn thực', 'Stock'],
        ['Định mức', 'Minimum'],
        ['Mã:', 'Code:'],
        ['Bàn', 'Table'],
        ['Ca sáng', 'Morning shift'],
        ['Ca chiều', 'Afternoon shift'],
        ['Ca tối', 'Evening shift'],
        ['nhân sự', 'staff'],
        ['Sửa', 'Edit'],
        ['Xoá', 'Delete'],
        ['Xóa', 'Clear'],
        ['Lưu', 'Save'],
        ['Cập nhật', 'Update'],
        ['Tạo mới', 'Create'],
        ['Tạo', 'Create'],
        ['Chọn', 'Select'],
        ['Tất cả', 'All'],
        ['Đang mở', 'Open'],
        ['Hết nguyên liệu', 'Out of stock'],
        ['Nguyên liệu sắp hết', 'Low stock'],
        ['Hoạt động', 'Active'],
        ['Tạm khóa', 'Temporarily locked'],
        ['Khóa', 'Locked'],
        ['Tăng ca', 'Overtime'],
        ['Hội viên', 'Member'],
        ['Điểm', 'Points'],
        ['Hạng', 'Tier'],
        ['Mật khẩu', 'Password'],
        ['Tên đăng nhập', 'Username'],
        ['Số điện thoại', 'Phone number']
    ];

    function appLanguage() {
        return localStorage.getItem(LANGUAGE_STORAGE_KEY) === 'en' ? 'en' : 'vi';
    }

    function tr(key) {
        var lang = appLanguage();
        return (appText[lang] && appText[lang][key]) || appText.vi[key] || key;
    }

    function globalTranslationEnabled() {
        return pageName() !== 'menu.jsp';
    }

    function translateCore(text) {
        if (!globalTranslationEnabled() || appLanguage() !== 'en') {
            return text;
        }
        if (!text || !String(text).trim()) {
            return text;
        }

        var value = String(text);
        var leading = value.match(/^\s*/)[0];
        var trailing = value.match(/\s*$/)[0];
        var core = value.trim().replace(/\s+/g, ' ');

        if (pageTranslations[core]) {
            return leading + pageTranslations[core] + trailing;
        }

        var next = core;
        phraseTranslations
            .slice()
            .sort(function (a, b) { return b[0].length - a[0].length; })
            .forEach(function (pair) {
                next = next.split(pair[0]).join(pair[1]);
            });
        return leading + next + trailing;
    }

    function translateTextNode(node) {
        if (!node || shouldSkip(node)) return;
        var current = node.nodeValue;
        if (node.__appI18nRendered !== current) {
            node.__appI18nSource = cleanText(current);
        }
        var source = node.__appI18nSource || cleanText(current);
        var rendered = appLanguage() === 'en' ? translateCore(source) : source;
        node.__appI18nRendered = rendered;
        if (current !== rendered) {
            node.nodeValue = rendered;
        }
    }

    function translateAttribute(element, attrName) {
        if (!element || !element.getAttribute || !element.hasAttribute(attrName)) return;
        var propName = '__appI18nAttr_' + attrName.replace(/[^A-Za-z0-9]/g, '_');
        var current = element.getAttribute(attrName);
        if (element[propName + '_rendered'] !== current) {
            element[propName] = cleanText(current);
        }
        var source = element[propName] || cleanText(current);
        var rendered = appLanguage() === 'en' ? translateCore(source) : source;
        element[propName + '_rendered'] = rendered;
        if (current !== rendered) {
            element.setAttribute(attrName, rendered);
        }
    }

    function translateDocumentTitle() {
        if (!globalTranslationEnabled()) return;
        var current = document.title || '';
        if (document.__appI18nTitleRendered !== current) {
            document.__appI18nTitleSource = cleanText(current);
        }
        var source = document.__appI18nTitleSource || cleanText(current);
        var rendered = appLanguage() === 'en' ? translateCore(source) : source;
        document.__appI18nTitleRendered = rendered;
        if (current !== rendered) {
            document.title = rendered;
        }
    }

    function translateAttributes(root) {
        if (!globalTranslationEnabled() || !root || root.nodeType !== Node.ELEMENT_NODE) return;
        var elements = [root].concat(Array.prototype.slice.call(root.querySelectorAll('[placeholder], [title], [aria-label], [value]')));
        elements.forEach(function (element) {
            ['placeholder', 'title', 'aria-label'].forEach(function (attrName) {
                translateAttribute(element, attrName);
            });
            if ((element.tagName === 'INPUT' || element.tagName === 'BUTTON') && element.type !== 'password') {
                translateAttribute(element, 'value');
            }
        });
    }

    function setAppLanguage(lang) {
        localStorage.setItem(LANGUAGE_STORAGE_KEY, lang === 'en' ? 'en' : 'vi');
        document.documentElement.lang = appLanguage();
        translateDocumentTitle();
        if (document.body) {
            cleanTree(document.body);
        }
        try {
            window.dispatchEvent(new CustomEvent('app-language-change', { detail: { language: appLanguage() } }));
        } catch (e) {
            return null;
        }
    }

    window.setAppLanguage = setAppLanguage;

    function shouldSkip(node) {
        if (!node || !node.parentElement) return true;
        var tagName = node.parentElement.tagName;
        return tagName === 'SCRIPT' || tagName === 'STYLE' || tagName === 'TEXTAREA';
    }

    function cleanTree(root) {
        if (!root || !document.body) return;
        var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
            acceptNode: function (node) {
                return shouldSkip(node) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT;
            }
        });
        var node;
        while ((node = walker.nextNode())) {
            translateTextNode(node);
        }
        if (root.nodeType === Node.ELEMENT_NODE) {
            translateAttributes(root);
        }
    }

    function toastType(message) {
        var text = String(message || '').toLowerCase();
        if (text.indexOf('lỗi') !== -1 || text.indexOf('thất bại') !== -1 || text.indexOf('không') !== -1 || text.indexOf('sai') !== -1) {
            return 'error';
        }
        if (text.indexOf('cảnh báo') !== -1 || text.indexOf('vui lòng') !== -1 || text.indexOf('tạm ngưng') !== -1) {
            return 'warning';
        }
        return 'info';
    }

    function showToast(message, type) {
        if (!document.body) return;
        var stack = document.querySelector('.app-toast-stack');
        if (!stack) {
            stack = document.createElement('div');
            stack.className = 'app-toast-stack';
            document.body.appendChild(stack);
        }

        var toast = document.createElement('div');
        toast.className = 'app-toast';
        toast.setAttribute('data-type', type || toastType(message));
        toast.innerHTML =
            '<span class="app-toast-dot" aria-hidden="true"></span>' +
            '<div class="app-toast-message"></div>' +
            '<button type="button" class="app-toast-close" aria-label="' + tr('close') + '">×</button>';
        toast.querySelector('.app-toast-message').textContent = cleanText(String(message || tr('updated')));
        toast.querySelector('.app-toast-close').addEventListener('click', function () {
            toast.remove();
        });
        stack.appendChild(toast);

        window.setTimeout(function () {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(6px)';
            window.setTimeout(function () {
                toast.remove();
            }, 180);
        }, 3600);
    }

    function installAlertToast() {
        window.appToast = showToast;
        window.alert = function (message) {
            showToast(message, toastType(message));
        };
    }

    function pageName() {
        var path = window.location.pathname || '';
        return path.substring(path.lastIndexOf('/') + 1) || 'index.html';
    }

    function navClass(href) {
        var current = pageName();
        var active = current === href;
        return 'hover:text-coffee-rust transition-colors ' + (active ? 'text-coffee-dark font-bold' : 'text-coffee-milk');
    }

    function navLink(href, label, extraClass) {
        return '<a href="' + href + '" class="' + navClass(href) + (extraClass ? ' ' + extraClass : '') + '">' + label + '</a>';
    }

    function currentMemberPhone() {
        return localStorage.getItem('member_phone') || '';
    }

    function dropdown(label, links) {
        var items = links.map(function (item) {
            return '<a href="' + item.href + '" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">' + item.label + '</a>';
        }).join('');
        return '<div class="relative group">' +
            '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
            '<span>' + label + '</span>' +
            '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
            '</button>' +
            '<div class="absolute left-0 mt-1 w-56 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
            items +
            '</div>' +
            '</div>';
    }

    function roleNavigation(role) {
        var current = pageName();
        var authPages = ['login.jsp', 'pin-login.jsp', 'staff.html'];
        if (authPages.indexOf(current) !== -1) {
            return [
                navLink('index.html', tr('navHome')),
                navLink('staff.html', tr('navStaffGate'))
            ].join('');
        }

        if (role === 'manager') {
            return [
                navLink('dashboard.jsp', tr('navDashboard')),
                navLink('admin-menu.jsp', tr('navMenu')),
                navLink('promotions.jsp', tr('navPromotions')),
                navLink('reports.jsp', tr('navReports')),
                navLink('staff-management.jsp', tr('navStaff')),
                navLink('inventory.jsp', tr('navInventory')),
                dropdown(tr('navOperations'), [
                    { href: 'waitstation.jsp', label: tr('navWaitstation') },
                    { href: 'pos-payment.jsp', label: tr('navPos') },
                    { href: 'kds.jsp', label: tr('navKds') },
                    { href: 'staff-orders.jsp', label: tr('navOrders') },
                    { href: 'table-qr.jsp', label: tr('navQr') }
                ])
            ].join('');
        }

        if (role === 'waiter') {
            return [
                navLink('waitstation.jsp', tr('navWaitstation'), 'font-semibold'),
                navLink('pos-payment.jsp', tr('navPos')),
                navLink('staff-orders.jsp', tr('navOrders')),
                navLink('table-qr.jsp', tr('navQr'))
            ].join('');
        }

        if (role === 'barista') {
            return [
                navLink('kds.jsp', tr('navKds'), 'font-semibold')
            ].join('');
        }

        if (currentMemberPhone()) {
            return [
                navLink('menu.jsp', tr('navOrder'), 'font-semibold'),
                navLink('order-status.jsp', tr('navMyOrder')),
                navLink('member.jsp', tr('navMember'))
            ].join('');
        }

        return [
            navLink('index.html', tr('navHome')),
            navLink('menu.jsp', tr('navGuestOrder'), 'font-semibold'),
            navLink('order-status.jsp', tr('navCheckOrder'))
        ].join('');
    }

    function applyRoleNavigation() {
        var navContainer = document.querySelector('nav div.hidden.lg\\:flex');
        if (!navContainer) return;
        var role = localStorage.getItem('auth_role') || '';
        navContainer.innerHTML = roleNavigation(role);
    }

    function syncSessionFromServer() {
        return fetch('api/auth/session', {
            credentials: 'same-origin'
        }).then(function (response) {
            return response.ok ? response.json() : null;
        }).then(function (data) {
            if (!data) return;

            if (data.authenticated && data.role) {
                localStorage.setItem('auth_role', data.role);
                localStorage.setItem('auth_user', data.user || data.username || 'Tài khoản');
                localStorage.removeItem('member_phone');
                localStorage.removeItem('member_name');
            } else {
                localStorage.removeItem('auth_role');
                localStorage.removeItem('auth_user');
            }

            if (data.memberAuthenticated && data.memberPhone) {
                localStorage.setItem('member_phone', data.memberPhone);
                localStorage.setItem('member_name', data.memberName || data.memberPhone);
            } else if (!data.authenticated) {
                localStorage.removeItem('member_phone');
                localStorage.removeItem('member_name');
            }
        }).catch(function () {
            return null;
        });
    }

    function installAccessGuard() {
        var protectedPages = {
            'dashboard.jsp': ['manager'],
            'admin-menu.jsp': ['manager'],
            'promotions.jsp': ['manager'],
            'reports.jsp': ['manager'],
            'staff-management.jsp': ['manager'],
            'inventory.jsp': ['manager'],
            'waitstation.jsp': ['waiter', 'manager'],
            'staff-orders.jsp': ['waiter', 'manager'],
            'table-qr.jsp': ['waiter', 'manager'],
            'order-summary.jsp': ['waiter', 'manager'],
            'pos-payment.jsp': ['waiter', 'manager'],
            'kds.jsp': ['barista', 'manager']
        };

        document.addEventListener('click', function (event) {
            var link = event.target.closest ? event.target.closest('a[href]') : null;
            if (!link) return;

            var href = link.getAttribute('href') || '';
            var file = href.split('?')[0].split('#')[0].split('/').pop();
            var allowedRoles = protectedPages[file];
            if (!allowedRoles) return;

            var role = localStorage.getItem('auth_role') || '';
            if (!role) return;
            if (allowedRoles.indexOf(role) === -1) {
                event.preventDefault();
                showToast(tr('accessWarning'), 'warning');
                window.setTimeout(function () {
                    window.location.href = 'login.jsp';
                }, 350);
            }
        }, true);
    }

    function installLogoutHandler() {
        window.handleLocalLogout = function () {
            localStorage.removeItem('auth_role');
            localStorage.removeItem('auth_user');
            fetch('api/auth/logout', {
                method: 'POST',
                credentials: 'same-origin',
                keepalive: true
            }).catch(function () {
                return null;
            }).finally(function () {
                window.location.href = 'index.html';
            });
        };

        window.handleMemberLogout = function () {
            localStorage.removeItem('member_phone');
            localStorage.removeItem('member_name');
            fetch('api/members/logout', {
                method: 'POST',
                credentials: 'same-origin',
                keepalive: true
            }).catch(function () {
                return null;
            }).finally(function () {
                window.location.href = 'index.html';
            });
        };
    }

    function renderSessionControls() {
        document.querySelectorAll('.app-session-control').forEach(function (node) {
            node.remove();
        });

        var role = localStorage.getItem('auth_role') || '';
        var memberPhone = currentMemberPhone();
        if (!role && !memberPhone) return;

        var user = localStorage.getItem('auth_user') || tr('account');
        var memberName = localStorage.getItem('member_name') || memberPhone;
        var roleLabel = role ? (role === 'manager' ? tr('roleManager') : role === 'barista' ? tr('roleBarista') : tr('roleWaiter')) : tr('roleMember');
        var accountLabel = role ? user : memberName;
        var logoutHandler = role ? 'handleLocalLogout()' : 'handleMemberLogout()';
        var holder = document.querySelector('header .flex.items-center.gap-3\\.5') ||
            document.querySelector('main header') ||
            document.querySelector('nav div.flex.items-center.gap-3') ||
            document.querySelector('nav > div') ||
            document.body;

        var control = document.createElement('div');
        control.className = 'app-session-control';
        control.innerHTML =
            '<div class="app-session-badge">' +
                '<span class="app-session-dot"></span>' +
                '<span class="app-session-text">' + roleLabel + ': ' + accountLabel + '</span>' +
            '</div>' +
            '<button type="button" class="app-session-logout" onclick="' + logoutHandler + '">' + tr('logout') + '</button>';
        holder.appendChild(control);
    }

    function renderLanguageSwitch() {
        document.querySelectorAll('.app-language-control').forEach(function (node) {
            node.remove();
        });
        if (pageName() === 'menu.jsp') return;

        var holder = document.querySelector('header .flex.items-center.gap-3\\.5') ||
            document.querySelector('main header') ||
            document.querySelector('nav div.flex.items-center.gap-3') ||
            document.querySelector('nav > div') ||
            document.body;
        var lang = appLanguage();
        var activeClass = 'text-[10px] font-bold px-2 py-1 rounded-full transition-all bg-coffee-rust text-white shadow-xs';
        var idleClass = 'text-[10px] font-bold px-2 py-1 rounded-full transition-all text-coffee-milk hover:text-coffee-rust';
        var control = document.createElement('div');
        control.className = 'app-language-control flex items-center gap-1 bg-white border border-coffee-sand rounded-full p-0.5 shadow-xs';
        control.innerHTML =
            '<button type="button" onclick="setAppLanguage(&quot;vi&quot;)" class="' + (lang === 'vi' ? activeClass : idleClass) + '">VI</button>' +
            '<button type="button" onclick="setAppLanguage(&quot;en&quot;)" class="' + (lang === 'en' ? activeClass : idleClass) + '">EN</button>';
        holder.appendChild(control);
    }

    function redirectLoggedMemberFromHome() {
        if (localStorage.getItem('auth_role')) return;
        if (!currentMemberPhone()) return;
        var current = pageName();
        var publicEntryPages = ['index.html', 'staff.html', 'login.jsp', 'pin-login.jsp'];
        if (publicEntryPages.indexOf(current) !== -1) {
            window.location.replace('member.jsp');
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.documentElement.lang = appLanguage();
        translateDocumentTitle();
        document.body.classList.add('app-polished');
        cleanTree(document.body);
        installAlertToast();
        installLogoutHandler();
        installAccessGuard();

        syncSessionFromServer().then(function () {
            applyRoleNavigation();
            redirectLoggedMemberFromHome();
            renderSessionControls();
            renderLanguageSwitch();
        });
        window.setTimeout(renderSessionControls, 250);
        window.setTimeout(renderLanguageSwitch, 250);
        window.addEventListener('app-language-change', function () {
            document.documentElement.lang = appLanguage();
            translateDocumentTitle();
            cleanTree(document.body);
            applyRoleNavigation();
            renderSessionControls();
            renderLanguageSwitch();
        });

        var observer = new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                if (mutation.type === 'characterData' && !shouldSkip(mutation.target)) {
                    translateTextNode(mutation.target);
                    return;
                }
                if (mutation.type === 'attributes' && mutation.target && mutation.target.nodeType === Node.ELEMENT_NODE) {
                    translateAttributes(mutation.target);
                    return;
                }
                mutation.addedNodes.forEach(function (node) {
                    if (node.nodeType === Node.TEXT_NODE && !shouldSkip(node)) {
                        translateTextNode(node);
                    } else if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== 'SCRIPT' && node.tagName !== 'STYLE') {
                        cleanTree(node);
                    }
                });
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            characterData: true,
            attributes: true,
            attributeFilter: ['placeholder', 'title', 'aria-label', 'value']
        });
    });
})();
