const LANG_KEY = 'coffeshop_lang';
const TAB_SESSION_KEY = 'coffeshop_tab_session';
const dict = {
    vi: {
        home: 'Trang chủ', order: 'Gọi món', status: 'Tra đơn', login: 'Đăng nhập',
        dashboard: 'Dashboard', staffOrders: 'Pha chế', cashier: 'Thu ngân', runner: 'Bồi bàn', menuAdmin: 'Thực đơn', inventoryAdmin: 'Kho nguyên liệu', tablesAdmin: 'Bàn & QR', staffAdmin: 'Nhân viên', promoAdmin: 'Khuyến mãi', systemLogs: 'Log hệ thống',
        logout: 'Đăng xuất', language: 'Ngôn ngữ', refresh: 'Làm mới', save: 'Lưu', cancel: 'Huỷ', delete: 'Xoá', backToPrevious: 'Quay lại',
        cancelOrder: 'Hủy đơn', cancelReason: 'Lý do hủy', cancelConfirm: 'Xác nhận hủy đơn này?', cancelled: 'Đã hủy', cancelSuccess: 'Đã hủy đơn', cancelNotAllowed: 'Không thể hủy đơn này', cancelFailed: 'Hủy đơn thất bại',
        refundOrder: 'Hoàn tiền', refundReason: 'Lý do hoàn tiền', refundConfirm: 'Xác nhận hoàn tiền đơn này?', refundSuccess: 'Đã hoàn tiền', refundFailed: 'Hoàn tiền thất bại', restockOnRefund: 'Hoàn kho nguyên liệu',
        cancelledOrders: 'Đơn hủy', refundedOrders: 'Đơn hoàn', tipAmount: 'Tip', tipOptional: 'Tip (tuỳ chọn)',
        takeaway: 'Mang đi', dineIn: 'Tại chỗ', orderType: 'Loại đơn', promoCode: 'Mã khuyến mãi', openOrdersBadge: 'đơn',
        taxAmount: 'Trong đó VAT', serviceCharge: 'Phí phục vụ', subtotalLabel: 'Tạm tính', discountLabel: 'Giảm giá', revenueBeforeTax: 'Doanh thu trước thuế',
        heroEyebrow: 'Đặt món tại bàn', heroTitle: 'coffeshop', heroText: 'Chọn món, gửi đơn và theo dõi trạng thái ngay tại bàn.',
        homeCardTitle: 'Dành cho khách tại quán', homeFeatureMenu: 'Quét QR trên bàn để gọi món', homeFeatureStatus: 'Theo dõi đơn bằng mã đơn',
        openMenu: 'Quét QR tại bàn', staffLogin: 'Nhân viên', checkOrder: 'Kiểm tra đơn',
        scanTableQrEyebrow: 'Gọi món tại bàn', scanTableQrText: 'Quét mã QR trên bàn để mở thực đơn.', scanTableQrButton: 'Quét QR tại bàn',
        scanTableQrHint: 'Đưa mã QR trên bàn vào giữa khung hình.', scanStarting: 'Đang mở camera...', stopScan: 'Dừng quét',
        cameraUnsupported: 'Trình duyệt này không hỗ trợ mở camera.', cameraPermissionError: 'Không mở được camera. Hãy cấp quyền camera hoặc dùng HTTPS.', invalidTableQr: 'QR này không thuộc bàn đang hoạt động.', tableQrDetected: 'Đã nhận bàn, đang mở thực đơn...',
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
        importExcel: 'Import từ Excel', downloadTemplate: 'Tải file mẫu', importDone: 'Đã thêm', importSkipped: 'Bỏ qua', importNoFile: 'Vui lòng chọn file Excel.',
        loginFailed: 'Đăng nhập không thành công',
        searchMenu: 'Tìm món, ví dụ: cà phê sữa...', all: 'Tất cả', addToCart: 'Thêm vào giỏ',
        cartSummary: 'Xem giỏ hàng', tableHelp: 'Chọn bàn trước khi gửi đơn',
        checkout: 'Xác nhận gọi món', orderSent: 'Đơn đã gửi cho quán', viewStatus: 'Theo dõi đơn',
        confirmOrderTitle: 'Xác nhận gọi món', confirmOrderText: 'Kiểm tra lại giỏ hàng trước khi gửi đơn cho quầy.',
        holdToOrder: 'Giữ 1 giây để gửi đơn', releaseToCancel: 'Thả tay để huỷ thao tác', orderConfirmItems: 'Số món', orderConfirmTotal: 'Tổng thanh toán',
        remove: 'Bỏ món', cartNote: 'Ghi chú cho quán', noMenu: 'Không thấy món phù hợp',
        noOrder: 'Chưa có đơn nào', nextStep: 'Chuyển trạng thái',
        newBaristaWork: 'Có đơn mới chờ pha chế',
        newCashierWork: 'Có đơn mới chờ thanh toán',
        newWaiterWork: 'Có việc mới cho bồi bàn',
        statusMoveFailed: 'Không chuyển được trạng thái',
        paymentBlockedUntilServed: 'Bàn còn món chưa phục vụ, chưa thể thanh toán.',
        pendingTableItems: 'Món chưa ra bàn',
        pendingColumn: 'Chờ xử lý', preparingColumn: 'Đang pha', readyColumn: 'Sẵn sàng', servedColumn: 'Đã phục vụ',
        serveColumn: 'Phục vụ', cleaningColumn: 'Chờ dọn',
        unpaid: 'Chưa thanh toán', paid: 'Đã thanh toán',
        splitBill: 'Tách đơn', splitTitle: 'Tách hóa đơn', splitHint: 'Chọn số lượng mỗi món để tách sang hóa đơn mới.',
        splitToNewBill: 'Tách sang hóa đơn mới', splitConfirm: 'Xác nhận tách', splitNeedOne: 'Phải để lại ít nhất 1 món trên hóa đơn gốc.',
        splitNothing: 'Chưa chọn món nào để tách.', splitDone: 'Đã tách hóa đơn', splitFailed: 'Không tách được hóa đơn',
        collectedRevenue: 'Doanh thu đã thu', unpaidRevenue: 'Chưa thu', openRevenue: 'Đang xử lý',
        revenueToday: 'Hôm nay', revenueMonth: 'Tháng này', revenueYear: 'Năm nay',
        soldProducts: 'Sản phẩm đã bán', bestSeller: 'Bán chạy nhất', rangeBestSeller: 'Bán chạy trong khoảng này', noSalesData: 'Chưa có dữ liệu',
        favoriteItems: 'Các món được yêu thích nhất',
        staffSchedule: 'Lịch làm việc tuần này', jumpToPayroll: 'Bảng Chấm Công', carryOverShifts: '📋 Sao chép → Tuần sau', prevWeek: '< Tuần trước', nextWeek: 'Tuần sau >',
        shiftFormTitle: 'Phân công ca làm', addShiftTitle: 'Thêm nhân viên vào ca', editShiftTitle: 'Sửa phân công',
        staffLabel: 'Nhân viên', dateLabel: 'Ngày (YYYY-MM-DD)', shiftLabel: 'Ca làm', roleLabel: 'Vị trí (Vai trò)',
        notesLabel: 'Ghi chú', notesPlaceholder: 'Ghi chú thêm...', statusLabel: 'Trạng thái', saveShift: 'LƯU CA LÀM',
        payrollSection: 'Bảng chấm công (Tính tổng giờ)', roleFilter: 'Vai trò:', monthFilter: 'Tháng:',
        totalShifts: 'Tổng số ca (Đã làm)', totalHours: 'Tổng số giờ', loadingData: 'Đang tải dữ liệu...',
        payrollNote1: '* Chỉ tính số giờ cho những ca làm có trạng thái là "Đã làm" hoặc "Hoàn thành".',
        payrollNote2: '* Ca Sáng / Ca Chiều: 6 giờ. Ca Tối: 5 giờ.',
        shiftMorning: 'Ca Sáng (06:00 - 12:00)', shiftAfternoon: 'Ca Chiều (12:00 - 18:00)', shiftEvening: 'Ca Tối (18:00 - 23:00)',
        roleBaristaFull: 'Barista (Pha chế)', roleCashierFull: 'Cashier (Thu ngân)', roleWaiterFull: 'Waiter (Phục vụ)',
        statusScheduled: 'Đã xếp lịch', statusDone: 'Đã làm', statusAbsent: 'Vắng', allRoles: 'Tất cả',
        staffManagementTitle: 'Quản lý danh sách nhân viên',
        scrollToTop: 'Lên đầu trang',
        printInvoice: 'In hóa đơn', invoiceTitle: 'Hóa đơn', invoiceHint: 'Đưa hóa đơn này kèm món cho khách. Khi thanh toán, khách đưa hóa đơn cho thu ngân.',
        printNow: 'In hóa đơn', closeInvoice: 'Đóng', invoiceLoadFailed: 'Không tải được hóa đơn',
        invoiceDate: 'Thời gian', invoicePayHint: 'Mang hóa đơn này đến quầy thu ngân để thanh toán.',
        serveWithoutInvoiceTitle: 'Chưa in hóa đơn',
        serveWithoutInvoiceText: 'Đơn này chưa in hóa đơn. Vẫn xác nhận đã phục vụ?',
        serveAnyway: 'Vẫn phục vụ',
        reprintInvoice: 'In lại hóa đơn',
        reprintInvoiceHint: 'Đơn đã phục vụ nhưng có thể in lại hóa đơn cho khách.',
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
        qrWelcomeTitle: 'Đã nhận bàn', noTableYet: 'Chưa chọn bàn', qrMissingTable: 'Không tìm thấy bàn từ mã QR này.', qrRequired: 'Vui lòng quét QR trên bàn để mở thực đơn.',
        hasSizes: 'Sản phẩm có size', sizeName: 'Tên size', extraPrice: 'Tiền chênh', addSize: 'Thêm size', baseSizeHelp: 'Size S dùng giá gốc.', recipeInfo: 'Công thức món', fromDate: 'Từ ngày', toDate: 'Đến ngày', apply: 'Áp dụng',
        cashOnHand: 'Tiền mặt hiện có', cashCountBeforeLogout: 'Nhập tiền mặt hiện tại để đăng xuất', cashCountRequired: 'Cần nhập tiền mặt hiện tại trước khi đăng xuất.', cashCountInvalid: 'Số tiền mặt không hợp lệ.',
        cashHistory: 'Lịch sử tiền mặt', withdrawCash: 'Rút tiền mặt', withdrawAmount: 'Nhập số tiền cần rút', cashWithdrawn: 'Đã rút tiền mặt', adminWithdrawNotice: 'Quản lý vừa rút tiền mặt', cashCountSaved: 'Đã ghi nhận tiền mặt',
        cashPayment: 'Thanh toán', cashCount: 'Kiểm kê', adminWithdrawEvent: 'Admin rút tiền', selectedRange: 'Khoảng đang xem',
        cupsAvailable: 'Cốc hiện có', editCupStock: 'Sửa số cốc', updateCups: 'Cập nhật cốc', gotIt: 'Đã hiểu',
        adminPinTitle: 'Mã PIN quản trị', adminPinText: 'Nhập mã PIN để mở dashboard.', unlock: 'Mở khoá', adminPinInvalid: 'Sai mã PIN quản trị.',
        actorAll: 'Tất cả', actorGuest: 'Khách', actorAdmin: 'Admin', actorBarista: 'Pha chế', actorCashier: 'Thu ngân', actorRunner: 'Bồi bàn', noLogs: 'Chưa có log',
        cookByOrder: 'Nấu theo đơn', cookByItem: 'Nấu theo món', confirmMoveOrderStatus: 'Chuyển đơn #{order} sang trạng thái {status}?',
        addMaterialBtn: 'Thêm nguyên liệu', materialId: 'Mã NL', materialName: 'Tên nguyên liệu', stock: 'Tồn kho', minStock: 'Tối thiểu', unit: 'Đơn vị', importPrice: 'Giá nhập', materialInfo: 'Thông tin nguyên liệu', materialIdFull: 'Mã nguyên liệu (ID)', materialIdPlaceholder: 'VD: CF_01', unitHelp: 'Đơn vị (g, ml...)', importPriceVND: 'Giá nhập (đ)', currentStock: 'Tồn kho hiện tại', minStockLevel: 'Mức tối thiểu', saveMaterial: 'Lưu nguyên liệu', inventoryEmpty: 'Chưa có nguyên liệu nào trong kho.', addNewMaterial: 'Thêm nguyên liệu mới', editMaterial: 'Sửa nguyên liệu:', deleteMaterialConfirm: 'Bạn có chắc chắn muốn xoá nguyên liệu {id}? Nếu nguyên liệu đang được dùng trong công thức món thì hệ thống sẽ từ chối xoá.', inventoryDuplicateId: 'Mã nguyên liệu đã tồn tại.', inventoryMissingRequired: 'Vui lòng nhập đầy đủ mã, tên và đơn vị.', inventoryIdLength: 'Mã nguyên liệu phải từ 2 đến 50 ký tự.', inventoryIdFormat: 'Mã nguyên liệu chỉ gồm chữ, số, gạch dưới hoặc gạch ngang.', inventoryNameLength: 'Tên nguyên liệu phải từ 2 đến 120 ký tự.', inventoryUnitLength: 'Đơn vị tối đa 20 ký tự.', inventoryFieldRequired: '{field} không được để trống.', inventoryFieldNonNegative: '{field} phải là số nguyên không âm.', systemError: 'Lỗi hệ thống', networkError: 'Mất kết nối mạng',
        lowStockWarning: 'Cảnh báo sắp hết hàng', lowStockBanner: 'Có {count} nguyên liệu dưới mức tối thiểu — cần nhập thêm.',
        lowStockItemLine: '{name}: còn {stock}/{min} {unit}',
        stockNotEnough: 'Không còn đủ hàng để phục vụ (còn {count}).',
        stockSoldOut: 'Món này hiện đã hết hàng.',
        menuDisabledByStock: 'Đã tự tắt {count} món vì không còn đủ nguyên liệu.',
        daySun: 'Chủ nhật', dayMon: 'Thứ 2', dayTue: 'Thứ 3', dayWed: 'Thứ 4', dayThu: 'Thứ 5', dayFri: 'Thứ 6', daySat: 'Thứ 7',
        shiftMorningShort: 'Ca Sáng', shiftAfternoonShort: 'Ca Chiều', shiftEveningShort: 'Ca Tối',
        selectStaff: '-- Chọn nhân viên --', staffInactiveSuffix: '(đã nghỉ)', understaffed: 'Thiếu người',
        addRoleTitle: 'Thêm {role}', selectStaffRequired: 'Vui lòng chọn nhân viên.',
        shiftStatusDateRule: 'Chỉ đánh dấu "Đã làm" hoặc "Vắng" cho hôm nay hoặc ngày đã qua.',
        shiftSaved: 'Đã lưu ca làm thành công!', shiftDeleted: 'Đã xóa ca làm!',
        shiftSaveFailed: 'Lỗi lưu ca làm.', shiftDeleteFailed: 'Lỗi xóa ca làm.',
        shiftOverlap: 'Nhân viên này đã được phân công vào ca này rồi.',
        shiftMissingInfo: 'Thiếu thông tin phân công ca.',
        selectShiftToDelete: 'Hãy chọn một ca để xóa.', deleteShiftConfirm: 'Bạn có chắc chắn muốn xóa ca làm này?',
        loadDataFailed: 'Lỗi tải dữ liệu.', networkErrorShort: 'Lỗi mạng.',
        payrollEmpty: 'Không có dữ liệu phù hợp với bộ lọc (hoặc chưa có ca nào "Đã làm").',
        hoursUnit: 'giờ', roleUnknown: 'Chưa rõ',
        staffActive: 'Đang làm', staffInactive: 'Đã nghỉ', staffTempInactive: 'Tạm nghỉ',
        noStaff: 'Chưa có nhân viên nào.', addStaff: '+ Thêm nhân viên', editStaff: 'Sửa nhân viên', saveStaff: 'LƯU NHÂN VIÊN',
        staffIdLabel: 'ID Nhân viên (chỉ nhập số)', staffNameLabel: 'Tên nhân viên', actions: 'Thao tác',
        staffSaved: 'Đã lưu nhân viên thành công!', staffSaveFailed: 'Lỗi lưu nhân viên.',
        staffDeleted: 'Đã xóa nhân viên thành công!', staffDeleteFailed: 'Lỗi xóa nhân viên.',
        deleteStaffConfirm: 'Bạn có chắc muốn xóa nhân viên này? Lịch sử ca làm sẽ được giữ lại nhưng nhân viên sẽ chuyển trạng thái Đã nghỉ.',
        jumpToPayrollTitle: 'Trượt xuống Bảng chấm công', staffAdminTitle: 'Quản lý nhân viên',
        recipeHelp: 'Nhập định lượng nguyên liệu cho món này.', selectMaterial: '-- Chọn nguyên liệu --', recipeQty: 'Định lượng',
        tableNamePattern: 'Tầng {floor} - Bàn {no}',
        errorPrefix: 'Lỗi:', tableWelcome: 'Bạn đang ngồi {table}. Chúc bạn một ngày vui vẻ ^^!',
        itemNamePlaceholder: 'Tên món', inventoryPageTitle: 'Kho nguyên liệu', menuAdminTitle: 'Quản lý thực đơn',
        tablesAdminTitle: 'Quản lý bàn & QR', dashboardTitle: 'Dashboard', cashierTitle: 'Thu ngân',
        runnerTitle: 'Bồi bàn', baristaTitle: 'Pha chế', loginTitle: 'Đăng nhập nhân viên',
        orderStatusTitle: 'Tra cứu đơn', menuPageTitle: 'Thực đơn', systemLogsTitle: 'Log hệ thống',
        counterOrderTitle: 'Gọi món tại quầy', transferTableTitle: 'Đổi bàn', homeTitle: 'coffeshop',

        // ── Tài khoản khách hàng & tích điểm ──
        customerLoginTitle: 'Đăng nhập khách hàng', customerAccountTitle: 'Tài khoản của tôi',
        customerLogin: 'Đăng nhập', customerRegister: 'Đăng ký', myAccount: 'Tài khoản',
        phoneNumber: 'Số điện thoại', password: 'Mật khẩu', passwordConfirm: 'Nhập lại mật khẩu',
        fullName: 'Họ và tên', fullNamePlaceholder: 'Nguyễn Văn A',
        passwordHint: 'Tối thiểu 6 ký tự.', passwordMismatch: 'Hai mật khẩu không khớp.',
        registerFailed: 'Không đăng ký được. Vui lòng kiểm tra lại thông tin.',
        networkError: 'Không kết nối được máy chủ. Vui lòng thử lại.',
        loyaltyPitch: 'Đăng nhập để tích điểm và xem lại lịch sử đơn hàng.',
        continueAsGuest: 'Tiếp tục gọi món không cần tài khoản',
        points: 'điểm', totalSpent: 'Tổng chi tiêu', orderCountLabel: 'Số đơn', memberSince: 'Thành viên từ',
        tierBronze: 'Hạng Đồng', tierSilver: 'Hạng Bạc', tierGold: 'Hạng Vàng',
        tierProgress: 'Chi thêm {amount} để lên hạng tiếp theo.', tierMaxReached: 'Bạn đang ở hạng cao nhất.',
        tierProgressNamed: 'Chi thêm {amount} để lên {tier}.',
        yourTierBenefit: 'Quyền lợi hạng', yourTier: 'Hạng của bạn',
        tapTierGuide: 'Chạm để xem chương trình hạng & tích điểm',
        loyaltyProgram: 'Chương trình thành viên', tierGuideTitle: 'Tích điểm & thăng hạng',
        howPointsWork: 'Cách tích và đổi điểm',
        howEarn: 'Thanh toán đủ {spend} được 1 điểm.',
        howRedeem: '1 điểm đổi được {value} giảm giá.',
        howRedeemCap: 'Đổi tối thiểu {min} điểm, tối đa {max}% giá trị đơn.',
        howTierBySpend: 'Hạng Đồng / Bạc / Vàng dựa trên tổng chi tiêu tích lũy.',
        tierFrom: 'Từ {amount}', tierUpTo: 'Dưới {amount}', tierBetween: '{from} – {to}',
        orderHistory: 'Lịch sử đơn', pointHistory: 'Sổ điểm', accountSettings: 'Tài khoản',
        orderHistoryRange: 'Khoảng thời gian', rangeToday: 'Hôm nay', rangeLast7: '7 ngày', rangeLast30: '30 ngày',
        rangeAllTime: 'Tất cả', applyFilter: 'Áp dụng', fromDate: 'Từ ngày', toDate: 'Đến ngày',
        pickDateRange: 'Vui lòng chọn khoảng ngày.', invalidDateRange: 'Ngày bắt đầu phải trước ngày kết thúc.',
        trackCurrentSession: 'Đơn phiên hiện tại', noSessionOrders: 'Chưa có đơn trong phiên này',
        noSessionOrdersHint: 'Đơn bạn vừa gọi sẽ hiện ở đây. Đơn đã xong xem ở mục bên dưới.',
        pastOrdersToday: 'Đơn đã hoàn thành (phiên / hôm nay)',
        noOrderHistory: 'Bạn chưa có đơn hàng nào.', noPointHistory: 'Chưa có giao dịch điểm nào.',
        close: 'Đóng',
        pointEarned: 'Tích điểm', pointRedeemed: 'Đổi điểm', pointAdjusted: 'Điều chỉnh',
        balanceAfter: 'Số dư', discountByPoints: 'Giảm giá bằng {points} điểm',
        profileInfo: 'Thông tin cá nhân', changePassword: 'Đổi mật khẩu',
        currentPassword: 'Mật khẩu hiện tại', newPassword: 'Mật khẩu mới',
        saved: 'Đã lưu.', saveFailed: 'Không lưu được.', passwordChanged: 'Đã đổi mật khẩu.',
        usePoints: 'Dùng điểm', pointsAvailable: 'Bạn có {points} điểm', pointsWorth: 'trị giá {amount}',
        redeemPlaceholder: 'Số điểm muốn dùng', redeemApply: 'Áp dụng', redeemClear: 'Bỏ dùng điểm',
        redeemMax: 'Tối đa {points} điểm cho đơn này', redeemTooFew: 'Cần tối thiểu {points} điểm mới đổi được.',
        subtotalLabel: 'Tiền hàng', discountLabel: 'Giảm giá', payableLabel: 'Phải trả',
        loginToEarn: 'Đăng nhập để tích điểm cho đơn này',
        earnPreview: 'Đơn này sẽ tích khoảng {points} điểm',

        // ── Trang đăng nhập khách (giao diện mới) ──
        loyaltyHeroTitle: 'Mỗi ly cà phê đều được cộng điểm',
        loyaltyHeroText: 'Tạo tài khoản để tích điểm, đổi điểm lấy giảm giá và xem lại toàn bộ đơn đã gọi.',
        benefitEarnTitle: 'Tích điểm tự động', benefitEarnText: 'Cứ 10.000đ thanh toán là 1 điểm.',
        benefitRedeemTitle: 'Đổi điểm lấy giảm giá', benefitRedeemText: '1 điểm bằng 1.000đ, dùng ngay khi gọi món.',
        benefitHistoryTitle: 'Lịch sử đơn hàng', benefitHistoryText: 'Xem lại mọi đơn đã gọi trên mọi thiết bị.',
        welcomeBack: 'Chào bạn quay lại', loginSubtitle: 'Đăng nhập bằng số điện thoại đã đăng ký.',
        createAccount: 'Tạo tài khoản', registerSubtitle: 'Chỉ cần số điện thoại, mất khoảng 30 giây.',
        showPassword: 'Hiện mật khẩu', hidePassword: 'Ẩn mật khẩu', orLabel: 'hoặc',
        pwWeak: 'Mật khẩu yếu — nên thêm chữ và số.',
        pwMedium: 'Mật khẩu tạm ổn.',
        pwStrong: 'Mật khẩu mạnh.',

        // ── Vai trò, thanh toán, sổ kho ──
        whoAreYou: 'Bạn là ai?', staffPickerNone: '— Không chọn —',
        staffPickerHint: 'Chọn tên để hệ thống ghi đúng người thao tác.',
        paymentMethod: 'Hình thức thanh toán', payCash: 'Tiền mặt', payTransfer: 'Chuyển khoản',
        receivedAmount: 'Khách đưa', changeAmount: 'Tiền thối', confirmPayment: 'Xác nhận thu tiền',
        receivedTooLow: 'Số tiền khách đưa nhỏ hơn số phải trả.',
        paymentSummary: 'Đối soát ca', stockLedger: 'Sổ kho', stockAudit: 'Đối soát kho',
        revenueByFloor: 'Doanh thu theo tầng', grossProfit: 'Lợi nhuận gộp', cogsLabel: 'Giá vốn',

        // ── Đăng nhập bằng tài khoản cá nhân ──
        pickYourself: 'Chọn tên của bạn', personalPin: 'Mã PIN cá nhân',
        rosterToday: 'Ca làm hôm nay · {date}', rosterEmpty: 'Chưa có nhân viên nào đang làm việc.',
        noShiftToday: 'Hôm nay không có ca', managerPin: 'PIN quản lý',
        overrideHint: 'Người này không có ca hôm nay. Quản lý nhập PIN để mở khoá.',
        offShiftBlocked: 'Hôm nay bạn không được xếp ca.',
        resetPin: 'Đặt lại PIN', pinResetDone: 'PIN mới là {pin}',
        noAccountYet: 'Chưa có tài khoản', nextShiftOn: 'Ca gần nhất: {date}',
        rosterLoadFailed: 'Không tải được danh sách nhân viên. Kiểm tra log Tomcat.',
        noAccountHelp: 'Nhân viên này chưa có tài khoản đăng nhập. Quản lý mở màn hình Nhân viên, bấm Lưu để hệ thống tạo tài khoản.',
        pinIssued: 'Đã tạo tài khoản. PIN đăng nhập: {pin}'
    },
    en: {
        home: 'Home', order: 'Order', status: 'Track', login: 'Sign in',
        dashboard: 'Dashboard', staffOrders: 'Barista', cashier: 'Cashier', runner: 'Waiter', menuAdmin: 'Menu', inventoryAdmin: 'Inventory', tablesAdmin: 'Tables & QR', staffAdmin: 'Staff', promoAdmin: 'Promotions', systemLogs: 'System logs',
        logout: 'Log out', language: 'Language', refresh: 'Refresh', save: 'Save', cancel: 'Cancel', delete: 'Delete', backToPrevious: 'Back',
        cancelOrder: 'Cancel order', cancelReason: 'Cancel reason', cancelConfirm: 'Cancel this order?', cancelled: 'Cancelled', cancelSuccess: 'Order cancelled', cancelNotAllowed: 'Cannot cancel this order', cancelFailed: 'Cancel failed',
        refundOrder: 'Refund', refundReason: 'Refund reason', refundConfirm: 'Refund this order?', refundSuccess: 'Refund completed', refundFailed: 'Refund failed', restockOnRefund: 'Restock inventory',
        cancelledOrders: 'Cancelled', refundedOrders: 'Refunded', tipAmount: 'Tip', tipOptional: 'Tip (optional)',
        takeaway: 'Takeaway', dineIn: 'Dine in', orderType: 'Order type', promoCode: 'Promo code', openOrdersBadge: 'orders',
        taxAmount: 'VAT included', serviceCharge: 'Service charge', subtotalLabel: 'Subtotal', discountLabel: 'Discount', revenueBeforeTax: 'Revenue before tax',
        heroEyebrow: 'Order at your table', heroTitle: 'coffeshop', heroText: 'Choose, order, and follow your drinks from the table.',
        homeCardTitle: 'For in-store guests', homeFeatureMenu: 'Scan the table QR to order', homeFeatureStatus: 'Track your order by code',
        openMenu: 'Scan table QR', staffLogin: 'Staff', checkOrder: 'Check order',
        scanTableQrEyebrow: 'Order at your table', scanTableQrText: 'Scan the QR code on your table to open the menu.', scanTableQrButton: 'Scan table QR',
        scanTableQrHint: 'Place the table QR code inside the frame.', scanStarting: 'Opening camera...', stopScan: 'Stop scanning',
        cameraUnsupported: 'This browser cannot open the camera.', cameraPermissionError: 'Could not open the camera. Allow camera access or use HTTPS.', invalidTableQr: 'This QR code is not an active table QR.', tableQrDetected: 'Table detected, opening the menu...',
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
        importExcel: 'Import from Excel', downloadTemplate: 'Download template', importDone: 'Added', importSkipped: 'Skipped', importNoFile: 'Please choose an Excel file.',
        loginFailed: 'Sign in failed',
        searchMenu: 'Search drinks, for example: milk coffee...', all: 'All', addToCart: 'Add to cart',
        cartSummary: 'View cart', tableHelp: 'Choose a table before sending the order',
        checkout: 'Confirm order', orderSent: 'Order sent to the counter', viewStatus: 'Track order',
        confirmOrderTitle: 'Confirm order', confirmOrderText: 'Review your cart before sending it to the counter.',
        holdToOrder: 'Hold 1 second to order', releaseToCancel: 'Release to cancel', orderConfirmItems: 'Items', orderConfirmTotal: 'Total',
        remove: 'Remove', cartNote: 'Note for the cafe', noMenu: 'No matching items',
        noOrder: 'No orders yet', nextStep: 'Move status',
        newBaristaWork: 'New order waiting for barista',
        newCashierWork: 'New order waiting for payment',
        newWaiterWork: 'New waiter task',
        statusMoveFailed: 'Could not move status',
        paymentBlockedUntilServed: 'This table still has unserved items.',
        pendingTableItems: 'Unserved items',
        pendingColumn: 'Pending', preparingColumn: 'Preparing', readyColumn: 'Ready', servedColumn: 'Served',
        serveColumn: 'Serve', cleaningColumn: 'Clean',
        unpaid: 'Unpaid', paid: 'Paid',
        splitBill: 'Split bill', splitTitle: 'Split bill', splitHint: 'Choose how many of each item to move to a new bill.',
        splitToNewBill: 'Move to new bill', splitConfirm: 'Confirm split', splitNeedOne: 'At least one item must remain on the original bill.',
        splitNothing: 'No items selected to split.', splitDone: 'Bill split', splitFailed: 'Could not split the bill',
        collectedRevenue: 'Collected revenue', unpaidRevenue: 'Uncollected', openRevenue: 'In progress',
        revenueToday: 'Today', revenueMonth: 'This month', revenueYear: 'This year',
        soldProducts: 'Products sold', bestSeller: 'Best seller', rangeBestSeller: 'Best sellers in this range', noSalesData: 'No data yet',
        favoriteItems: 'Most loved items',
        staffSchedule: 'This week\'s schedule', jumpToPayroll: 'Payroll', carryOverShifts: '📋 Copy → Next week', prevWeek: '< Prev week', nextWeek: 'Next week >',
        shiftFormTitle: 'Shift assignment', addShiftTitle: 'Add staff to shift', editShiftTitle: 'Edit assignment',
        staffLabel: 'Staff', dateLabel: 'Date (YYYY-MM-DD)', shiftLabel: 'Shift', roleLabel: 'Role',
        notesLabel: 'Notes', notesPlaceholder: 'Additional notes...', statusLabel: 'Status', saveShift: 'SAVE SHIFT',
        payrollSection: 'Payroll (Total hours)', roleFilter: 'Role:', monthFilter: 'Month:',
        totalShifts: 'Total shifts (Done)', totalHours: 'Total hours', loadingData: 'Loading data...',
        payrollNote1: '* Only counts hours for shifts with "Done" or "Completed" status.',
        payrollNote2: '* Morning / Afternoon: 6 hrs. Evening: 5 hrs.',
        shiftMorning: 'Morning (06:00 - 12:00)', shiftAfternoon: 'Afternoon (12:00 - 18:00)', shiftEvening: 'Evening (18:00 - 23:00)',
        roleBaristaFull: 'Barista', roleCashierFull: 'Cashier', roleWaiterFull: 'Waiter',
        statusScheduled: 'Scheduled', statusDone: 'Done', statusAbsent: 'Absent', allRoles: 'All',
        staffManagementTitle: 'Staff management',
        scrollToTop: 'Back to top',
        printInvoice: 'Print invoice', invoiceTitle: 'Invoice', invoiceHint: 'Give this invoice with the order. At payment, the guest shows it to the cashier.',
        printNow: 'Print invoice', closeInvoice: 'Close', invoiceLoadFailed: 'Could not load invoice',
        invoiceDate: 'Time', invoicePayHint: 'Bring this invoice to the cashier to pay.',
        serveWithoutInvoiceTitle: 'Invoice not printed',
        serveWithoutInvoiceText: 'This order has no printed invoice yet. Mark as served anyway?',
        serveAnyway: 'Serve anyway',
        reprintInvoice: 'Reprint invoice',
        reprintInvoiceHint: 'These orders are already served and can still be reprinted.',
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
        qrWelcomeTitle: 'Table detected', noTableYet: 'No table yet', qrMissingTable: 'Could not find a table for this QR code.', qrRequired: 'Please scan the QR code on your table to open the menu.',
        hasSizes: 'Product has sizes', sizeName: 'Size name', extraPrice: 'Extra price', addSize: 'Add size', baseSizeHelp: 'Size S uses the base price.', recipeInfo: 'Recipe', fromDate: 'From', toDate: 'To', apply: 'Apply',
        cashOnHand: 'Cash on hand', cashCountBeforeLogout: 'Enter current cash before logging out', cashCountRequired: 'Current cash is required before logging out.', cashCountInvalid: 'Invalid cash amount.',
        cashHistory: 'Cash history', withdrawCash: 'Withdraw cash', withdrawAmount: 'Enter withdrawal amount', cashWithdrawn: 'Cash withdrawn', adminWithdrawNotice: 'Manager withdrew cash', cashCountSaved: 'Cash count saved',
        cashPayment: 'Payment', cashCount: 'Cash count', adminWithdrawEvent: 'Admin withdrawal', selectedRange: 'Selected range',
        cupsAvailable: 'Cups available', editCupStock: 'Edit cups', updateCups: 'Update cups', gotIt: 'Got it',
        adminPinTitle: 'Admin PIN', adminPinText: 'Enter the PIN to unlock the dashboard.', unlock: 'Unlock', adminPinInvalid: 'Incorrect admin PIN.',
        actorAll: 'All', actorGuest: 'Guest', actorAdmin: 'Admin', actorBarista: 'Barista', actorCashier: 'Cashier', actorRunner: 'Waiter', noLogs: 'No logs yet',
        cookByOrder: 'Cook by Order', cookByItem: 'Cook by Item', confirmMoveOrderStatus: 'Move order #{order} to {status}?',
        addMaterialBtn: 'Add material', materialId: 'Material ID', materialName: 'Material name', stock: 'Stock', minStock: 'Min stock', unit: 'Unit', importPrice: 'Import cost', materialInfo: 'Material details', materialIdFull: 'Material ID', materialIdPlaceholder: 'Ex: CF_01', unitHelp: 'Unit (g, ml...)', importPriceVND: 'Import cost (VND)', currentStock: 'Current stock', minStockLevel: 'Min stock level', saveMaterial: 'Save material', inventoryEmpty: 'No materials in inventory.', addNewMaterial: 'Add new material', editMaterial: 'Edit material:', deleteMaterialConfirm: 'Are you sure you want to delete material {id}? The system will reject deletion if recipes still use it.', inventoryDuplicateId: 'Material ID already exists.', inventoryMissingRequired: 'Please enter ID, name, and unit.', inventoryIdLength: 'Material ID must be 2 to 50 characters.', inventoryIdFormat: 'Material ID may only contain letters, numbers, underscore, or hyphen.', inventoryNameLength: 'Material name must be 2 to 120 characters.', inventoryUnitLength: 'Unit must be at most 20 characters.', inventoryFieldRequired: '{field} is required.', inventoryFieldNonNegative: '{field} must be a non-negative integer.', systemError: 'System error', networkError: 'Network disconnected',
        lowStockWarning: 'Low stock warning', lowStockBanner: '{count} ingredient(s) are at or below minimum — please restock.',
        lowStockItemLine: '{name}: {stock}/{min} {unit} left',
        stockNotEnough: 'Not enough stock to serve (only {count} left).',
        stockSoldOut: 'This item is currently sold out.',
        menuDisabledByStock: 'Automatically disabled {count} item(s) due to insufficient ingredients.',
        daySun: 'Sunday', dayMon: 'Monday', dayTue: 'Tuesday', dayWed: 'Wednesday', dayThu: 'Thursday', dayFri: 'Friday', daySat: 'Saturday',
        shiftMorningShort: 'Morning', shiftAfternoonShort: 'Afternoon', shiftEveningShort: 'Evening',
        selectStaff: '-- Select staff --', staffInactiveSuffix: '(inactive)', understaffed: 'Understaffed',
        addRoleTitle: 'Add {role}', selectStaffRequired: 'Please select a staff member.',
        shiftStatusDateRule: 'Mark Done or Absent only for today or past dates.',
        shiftSaved: 'Shift saved!', shiftDeleted: 'Shift deleted!',
        shiftSaveFailed: 'Could not save shift.', shiftDeleteFailed: 'Could not delete shift.',
        shiftOverlap: 'This staff member is already assigned to this shift.',
        shiftMissingInfo: 'Shift assignment details are incomplete.',
        selectShiftToDelete: 'Select a shift to delete.', deleteShiftConfirm: 'Are you sure you want to delete this shift?',
        loadDataFailed: 'Failed to load data.', networkErrorShort: 'Network error.',
        payrollEmpty: 'No matching payroll data (or no completed shifts yet).',
        hoursUnit: 'hrs', roleUnknown: 'Unknown',
        staffActive: 'Active', staffInactive: 'Inactive', staffTempInactive: 'Temporarily inactive',
        noStaff: 'No staff yet.', addStaff: '+ Add staff', editStaff: 'Edit staff', saveStaff: 'SAVE STAFF',
        staffIdLabel: 'Staff ID (numbers only)', staffNameLabel: 'Staff name', actions: 'Actions',
        staffSaved: 'Staff saved!', staffSaveFailed: 'Could not save staff.',
        staffDeleted: 'Staff deleted!', staffDeleteFailed: 'Could not delete staff.',
        deleteStaffConfirm: 'Delete this staff member? Shift history is kept, but status will become Inactive.',
        jumpToPayrollTitle: 'Scroll to payroll', staffAdminTitle: 'Staff management',
        recipeHelp: 'Enter ingredient quantities for this item.', selectMaterial: '-- Select material --', recipeQty: 'Quantity',
        tableNamePattern: 'Floor {floor} - Table {no}',
        errorPrefix: 'Error:', tableWelcome: 'You are seated at {table}. Have a lovely day ^^!',
        itemNamePlaceholder: 'Item name', inventoryPageTitle: 'Inventory', menuAdminTitle: 'Menu management',
        tablesAdminTitle: 'Tables & QR', dashboardTitle: 'Dashboard', cashierTitle: 'Cashier',
        runnerTitle: 'Waiter', baristaTitle: 'Barista', loginTitle: 'Staff sign in',
        orderStatusTitle: 'Order tracking', menuPageTitle: 'Menu', systemLogsTitle: 'System logs',
        counterOrderTitle: 'Counter order', transferTableTitle: 'Move table', homeTitle: 'coffeshop',

        // ── Customer accounts & loyalty ──
        customerLoginTitle: 'Customer sign in', customerAccountTitle: 'My account',
        customerLogin: 'Sign in', customerRegister: 'Sign up', myAccount: 'Account',
        phoneNumber: 'Phone number', password: 'Password', passwordConfirm: 'Confirm password',
        fullName: 'Full name', fullNamePlaceholder: 'Jane Doe',
        passwordHint: 'At least 6 characters.', passwordMismatch: 'Passwords do not match.',
        registerFailed: 'Could not sign up. Please check your details.',
        networkError: 'Cannot reach the server. Please try again.',
        loyaltyPitch: 'Sign in to earn points and see your order history.',
        continueAsGuest: 'Continue ordering without an account',
        points: 'points', totalSpent: 'Total spent', orderCountLabel: 'Orders', memberSince: 'Member since',
        tierBronze: 'Bronze', tierSilver: 'Silver', tierGold: 'Gold',
        tierProgress: 'Spend {amount} more to reach the next tier.', tierMaxReached: 'You are at the top tier.',
        tierProgressNamed: 'Spend {amount} more to reach {tier}.',
        yourTierBenefit: 'Your tier perk', yourTier: 'Your tier',
        tapTierGuide: 'Tap to view the loyalty & tier program',
        loyaltyProgram: 'Loyalty program', tierGuideTitle: 'Points & tiers',
        howPointsWork: 'How points work',
        howEarn: 'Pay {spend} to earn 1 point.',
        howRedeem: '1 point = {value} discount.',
        howRedeemCap: 'Redeem at least {min} points, up to {max}% of the order.',
        howTierBySpend: 'Bronze / Silver / Gold tiers are based on lifetime spend.',
        tierFrom: 'From {amount}', tierUpTo: 'Below {amount}', tierBetween: '{from} – {to}',
        orderHistory: 'Order history', pointHistory: 'Points ledger', accountSettings: 'Account',
        orderHistoryRange: 'Date range', rangeToday: 'Today', rangeLast7: '7 days', rangeLast30: '30 days',
        rangeAllTime: 'All time', applyFilter: 'Apply', fromDate: 'From', toDate: 'To',
        pickDateRange: 'Please pick a date range.', invalidDateRange: 'Start date must be before end date.',
        trackCurrentSession: 'Orders in this session', noSessionOrders: 'No orders in this session yet',
        noSessionOrdersHint: 'Orders you place now appear here. Finished ones are listed below.',
        pastOrdersToday: 'Completed orders (session / today)',
        noOrderHistory: 'You have no orders yet.', noPointHistory: 'No point activity yet.',
        close: 'Close',
        pointEarned: 'Points earned', pointRedeemed: 'Points redeemed', pointAdjusted: 'Adjustment',
        balanceAfter: 'Balance', discountByPoints: 'Discount using {points} points',
        profileInfo: 'Profile', changePassword: 'Change password',
        currentPassword: 'Current password', newPassword: 'New password',
        saved: 'Saved.', saveFailed: 'Could not save.', passwordChanged: 'Password changed.',
        usePoints: 'Use points', pointsAvailable: 'You have {points} points', pointsWorth: 'worth {amount}',
        redeemPlaceholder: 'Points to use', redeemApply: 'Apply', redeemClear: 'Remove points',
        redeemMax: 'Up to {points} points on this order', redeemTooFew: 'You need at least {points} points to redeem.',
        subtotalLabel: 'Subtotal', discountLabel: 'Discount', payableLabel: 'To pay',
        loginToEarn: 'Sign in to earn points on this order',
        earnPreview: 'This order earns about {points} points',

        // ── Customer sign-in page (new layout) ──
        loyaltyHeroTitle: 'Every cup earns you points',
        loyaltyHeroText: 'Create an account to earn points, redeem them for discounts and revisit every order.',
        benefitEarnTitle: 'Automatic points', benefitEarnText: 'Every 10,000 VND paid earns 1 point.',
        benefitRedeemTitle: 'Redeem for discounts', benefitRedeemText: '1 point equals 1,000 VND, used at checkout.',
        benefitHistoryTitle: 'Order history', benefitHistoryText: 'Revisit every order from any device.',
        welcomeBack: 'Welcome back', loginSubtitle: 'Sign in with your registered phone number.',
        createAccount: 'Create an account', registerSubtitle: 'Just a phone number, about 30 seconds.',
        showPassword: 'Show password', hidePassword: 'Hide password', orLabel: 'or',
        pwWeak: 'Weak password — add letters and numbers.',
        pwMedium: 'Decent password.',
        pwStrong: 'Strong password.',

        // ── Roles, payments, stock ledger ──
        whoAreYou: 'Who are you?', staffPickerNone: '— Not specified —',
        staffPickerHint: 'Pick your name so actions are logged to the right person.',
        paymentMethod: 'Payment method', payCash: 'Cash', payTransfer: 'Bank transfer',
        receivedAmount: 'Received', changeAmount: 'Change', confirmPayment: 'Confirm payment',
        receivedTooLow: 'Received amount is less than the amount due.',
        paymentSummary: 'Shift reconciliation', stockLedger: 'Stock ledger', stockAudit: 'Stock audit',
        revenueByFloor: 'Revenue by floor', grossProfit: 'Gross profit', cogsLabel: 'Cost of goods',

        // ── Personal account sign-in ──
        pickYourself: 'Select your name', personalPin: 'Your PIN',
        rosterToday: 'Today\'s roster · {date}', rosterEmpty: 'No active staff yet.',
        noShiftToday: 'No shift today', managerPin: 'Manager PIN',
        overrideHint: 'This person has no shift today. A manager PIN unlocks sign-in.',
        offShiftBlocked: 'You are not scheduled today.',
        resetPin: 'Reset PIN', pinResetDone: 'New PIN is {pin}',
        noAccountYet: 'No account yet', nextShiftOn: 'Next shift: {date}',
        rosterLoadFailed: 'Could not load the staff list. Check the Tomcat log.',
        noAccountHelp: 'This staff member has no login account. A manager can open the Staff screen and press Save to create one.',
        pinIssued: 'Account created. Login PIN: {pin}'
    }
};

function lang() { return localStorage.getItem(LANG_KEY) === 'en' ? 'en' : 'vi'; }
function t(key) { return (dict[lang()] && dict[lang()][key]) || key; }
function tf(key, vars) {
    let text = t(key);
    const data = vars || {};
    Object.keys(data).forEach(name => {
        text = text.replace(new RegExp('\\{' + name + '\\}', 'g'), String(data[name]));
    });
    return text;
}
function shiftNameText(name) {
    const map = {
        'Ca Sáng': 'shiftMorningShort',
        'Ca Chiều': 'shiftAfternoonShort',
        'Ca Tối': 'shiftEveningShort'
    };
    return t(map[name] || name) || name;
}
function dayName(index) {
    return t(['daySun', 'dayMon', 'dayTue', 'dayWed', 'dayThu', 'dayFri', 'daySat'][index] || 'daySun');
}
function staffStatusText(status) {
    if (status === 'Active') return t('staffActive');
    if (status === 'Inactive' || status === 'Perm_Inactive') return t('staffInactive');
    if (status === 'Temp_Inactive') return t('staffTempInactive');
    return status || '—';
}
function roleScheduleText(role) {
    // Sau khi chuẩn hoá, CSDL lưu mã thường (barista/cashier/runner).
    // Vẫn nhận dạng cũ để dữ liệu chưa migrate không hiện ra chuỗi thô.
    const map = {
        barista: 'roleBarista', cashier: 'roleCashier', runner: 'roleRunner',
        Barista: 'roleBarista', Cashier: 'roleCashier', Waiter: 'roleRunner'
    };
    return t(map[role] || role) || role;
}
function formatTableName(name) {
    const match = String(name || '').match(/(?:Tầng|Floor)\s*(\d+)\s*-\s*(?:Bàn|Table)\s*(\d+)/i);
    if (match) return tf('tableNamePattern', { floor: match[1], no: match[2] });
    return name || '';
}
function formatTableShort(name) {
    const match = String(name || '').match(/(?:Bàn|Table)\s*(\d+)/i);
    if (match) return (lang() === 'en' ? 'T' : 'B') + match[1];
    return name || '';
}
function tabSessionId() {
    let id = sessionStorage.getItem(TAB_SESSION_KEY);
    if (!id) {
        id = (window.crypto && crypto.randomUUID)
            ? crypto.randomUUID()
            : 'tab-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 10);
        sessionStorage.setItem(TAB_SESSION_KEY, id);
    }
    return id;
}
function withTab(url) {
    if (!url || url.startsWith('#') || url.startsWith('javascript:') || url.startsWith('mailto:') || url.startsWith('tel:')) return url;
    try {
        const parsed = new URL(url, window.location.href);
        if (parsed.origin !== window.location.origin) return url;
        if (!parsed.pathname.endsWith('.jsp')) return url;
        parsed.searchParams.set('tabSession', tabSessionId());
        return parsed.pathname.split('/').pop() + parsed.search + parsed.hash;
    } catch (err) {
        return url;
    }
}
function api(path, options) {
    const opts = Object.assign({}, options || {});
    const headers = new Headers(opts.headers || {});
    headers.set('X-Tab-Session', tabSessionId());
    opts.headers = headers;
    opts.credentials = 'same-origin';
    return fetch('api' + path, opts);
}

/** Realtime SSE với fallback polling. onEvent() được gọi khi có thay đổi. */
function subscribeLive(onEvent, pollMs) {
    const reload = typeof onEvent === 'function' ? onEvent : () => {};
    const interval = Math.max(3000, Number(pollMs) || 5000);
    let source = null;
    let timer = null;
    let usingSse = false;
    function startPoll() {
        if (timer) return;
        timer = setInterval(() => reload({ type: 'poll' }), interval);
    }
    function stopPoll() {
        if (timer) { clearInterval(timer); timer = null; }
    }
    try {
        source = new EventSource('api/events?tabSession=' + encodeURIComponent(tabSessionId()));
        source.addEventListener('connected', () => { usingSse = true; stopPoll(); });
        source.addEventListener('orders', () => reload({ type: 'orders' }));
        source.onerror = () => {
            usingSse = false;
            try { source.close(); } catch (e) {}
            source = null;
            startPoll();
        };
    } catch (e) {
        startPoll();
    }
    // Giữ polling dự phòng trong 8s đầu nếu SSE chưa connect.
    setTimeout(() => { if (!usingSse) startPoll(); }, 8000);
    return () => {
        stopPoll();
        if (source) try { source.close(); } catch (e) {}
    };
}

async function cancelOrderPrompt(orderId) {
    const reason = await inputModal({
        title: t('cancelOrder'),
        message: t('cancelConfirm'),
        actionLabel: t('cancelOrder'),
        value: ''
    });
    if (reason == null) return null;
    const trimmed = String(reason).trim();
    if (!trimmed) {
        notifyWork(t('cancelReason'));
        return null;
    }
    const res = await api('/orders/cancel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: orderId, reason: trimmed })
    });
    if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        notifyWork(err.error || t('cancelFailed'));
        return null;
    }
    notifyWork(t('cancelSuccess'));
    return res.json();
}

async function refundOrderPrompt(orderId) {
    const reason = await inputModal({
        title: t('refundOrder'),
        message: t('refundConfirm'),
        actionLabel: t('refundOrder'),
        value: ''
    });
    if (reason == null) return null;
    const trimmed = String(reason).trim();
    if (!trimmed) {
        notifyWork(t('refundReason'));
        return null;
    }
    let adminPin = '';
    try {
        const session = await api('/auth/session').then(r => r.ok ? r.json() : {});
        if (session && session.role === 'cashier') {
            const pin = await inputModal({
                title: t('refundOrder'),
                message: 'PIN admin',
                actionLabel: t('save'),
                value: '',
                inputMode: 'numeric'
            });
            if (pin == null) return null;
            adminPin = String(pin).trim();
        }
    } catch (e) {}
    const res = await api('/orders/refund', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: orderId, reason: trimmed, restock: true, adminPin })
    });
    if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        notifyWork(err.error || t('refundFailed'));
        return null;
    }
    notifyWork(t('refundSuccess'));
    return res.json();
}

function money(value) {
    const amount = Number(value || 0);
    const formatted = new Intl.NumberFormat(lang() === 'en' ? 'en-US' : 'vi-VN', {
        maximumFractionDigits: 0
    }).format(amount);
    return lang() === 'en' ? `VND ${formatted}` : `${formatted} đ`;
}
function statusText(status) {
    const map = { Pending: 'pending', Preparing: 'preparing', Ready: 'ready', Served: 'served', Paid: 'paid', Cleared: 'cleared', Cancelled: 'cancelled', Refunded: 'refundedOrders' };
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
    document.documentElement.lang = lang() === 'en' ? 'en' : 'vi';
    document.querySelectorAll('[data-i18n]').forEach(el => el.textContent = t(el.dataset.i18n));
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => el.placeholder = t(el.dataset.i18nPlaceholder));
    document.querySelectorAll('[data-i18n-title]').forEach(el => el.title = t(el.dataset.i18nTitle));
    document.querySelectorAll('[data-i18n-aria]').forEach(el => el.setAttribute('aria-label', t(el.dataset.i18nAria)));
    document.querySelectorAll('[data-page-title]').forEach(el => {
        document.title = t(el.dataset.pageTitle);
    });
    const pageTitleMeta = document.querySelector('meta[name="page-title-key"]');
    if (pageTitleMeta && pageTitleMeta.content) {
        document.title = t(pageTitleMeta.content);
    }
    document.querySelectorAll('[data-category-option]').forEach(option => option.textContent = categoryText(option.value));
    document.querySelectorAll('a[href]').forEach(link => {
        const href = link.getAttribute('href');
        if (href && href.includes('.jsp')) link.setAttribute('href', withTab(href));
    });
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
            <a class="link" href="${withTab('dashboard.jsp')}" data-i18n="dashboard">${t('dashboard')}</a>
            <a class="link" href="${withTab('admin-tables.jsp')}" data-i18n="tablesAdmin">${t('tablesAdmin')}</a>
            <a class="link" href="${withTab('admin-menu.jsp')}" data-i18n="menuAdmin">${t('menuAdmin')}</a>
            <a class="link" href="${withTab('admin-promotions.jsp')}" data-i18n="promoAdmin">${t('promoAdmin')}</a>
            <a class="link" href="${withTab('inventory.jsp')}" data-i18n="inventoryAdmin">${t('inventoryAdmin')}</a>
            <a class="link" href="${withTab('admin-staff.jsp')}" data-i18n="staffAdmin">${t('staffAdmin')}</a>
            <a class="link" href="${withTab('staff-orders.jsp')}" data-i18n="staffOrders">${t('staffOrders')}</a>
            <a class="link" href="${withTab('cashier.jsp')}" data-i18n="cashier">${t('cashier')}</a>
            <a class="link" href="${withTab('counter-order.jsp')}" data-i18n="counterOrder">${t('counterOrder')}</a>
            <a class="link" href="${withTab('runner.jsp')}" data-i18n="runner">${t('runner')}</a>
            <a class="link" href="${withTab('table-transfer.jsp')}" data-i18n="transferTable">${t('transferTable')}</a>
            <a class="link" href="${withTab('system-logs.jsp')}" data-i18n="systemLogs">${t('systemLogs')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    if (barista) {
        return `
            <a class="link" href="${withTab('staff-orders.jsp')}" data-i18n="staffOrders">${t('staffOrders')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    if (cashier) {
        return `
            <a class="link" href="${withTab('cashier.jsp')}" data-i18n="cashier">${t('cashier')}</a>
            <a class="link" href="${withTab('counter-order.jsp')}" data-i18n="counterOrder">${t('counterOrder')}</a>
            <a class="link" href="${withTab('table-transfer.jsp')}" data-i18n="transferTable">${t('transferTable')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    if (runner) {
        return `
            <a class="link" href="${withTab('runner.jsp')}" data-i18n="runner">${t('runner')}</a>
            <a class="link" href="${withTab('table-transfer.jsp')}" data-i18n="transferTable">${t('transferTable')}</a>
            <button class="btn danger" onclick="logout()" data-i18n="logout">${t('logout')}</button>
        `;
    }
    const tableCode = sessionStorage.getItem('selectedTableCode') || '';
    const tableName = sessionStorage.getItem('selectedTable') || '';
    const statusHref = tableCode
        ? `order-status.jsp?tableCode=${encodeURIComponent(tableCode)}`
        : (tableName ? `order-status.jsp?table=${encodeURIComponent(tableName)}` : 'order-status.jsp');
    // customerSession do loadNav() gán trước khi gọi nav(). Khách đã đăng nhập
    // thấy tên + số điểm; khách vãng lai thấy nút đăng nhập. Cả hai đều gọi
    // món được như nhau — đăng nhập không phải điều kiện để đặt hàng.
    const customer = window.customerSession || null;
    const accountLink = customer
        ? `<a class="link nav-account" href="${withTab('customer-account.jsp')}">
               <span class="nav-account-name">${escapeNav(customer.fullName || t('myAccount'))}</span>
               <span class="nav-account-points">${Number(customer.points || 0)} ${t('points')}</span>
           </a>`
        : `<a class="link" href="${withTab('customer-login.jsp?return=menu.jsp')}" data-i18n="customerLogin">${t('customerLogin')}</a>`;
    return `
        <a class="link" href="${withTab('menu.jsp')}" data-i18n="order">${t('order')}</a>
        <a class="link" href="${withTab(statusHref)}" data-i18n="status">${t('status')}</a>
        ${accountLink}
    `;
}

function escapeNav(value) {
    return String(value == null ? '' : value)
        .replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
}
async function loadNav() {
    const res = await api('/auth/session');
    const session = res.ok ? await res.json() : {};
    window.customerSession = session.customerAuthenticated ? (session.customer || null) : null;
    // Trang chủ (index.html) không có #nav-links mà chỉ có một liên kết tài khoản.
    // Xử lý riêng ở đây để mọi trang đều có lối vào tài khoản khách.
    const homeAccount = document.getElementById('home-account-link');
    if (homeAccount) {
        if (window.customerSession) {
            homeAccount.href = withTab('customer-account.jsp');
            homeAccount.removeAttribute('data-i18n');
            homeAccount.textContent = window.customerSession.fullName || t('myAccount');
        } else {
            homeAccount.href = withTab('customer-login.jsp?return=menu.jsp');
            homeAccount.setAttribute('data-i18n', 'customerLogin');
            homeAccount.textContent = t('customerLogin');
        }
    }
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
        brand.href = session.role ? withTab(homeByRole[session.role]) : 'index.html';
    }
    applyI18n();
}
async function logout() {
    const sessionRes = await api('/auth/session');
    const session = sessionRes.ok ? await sessionRes.json() : {};
    const redirectTarget = session.role === 'admin' ? 'index.html' : 'staff-login.jsp';
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
    window.location.href = withTab(redirectTarget);
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
    window.location.href = withTab(target);
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

/**
 * Điểm được cộng lúc thu ngân bấm "Đã thanh toán" — tức là ở máy khác.
 * Trình duyệt của khách không có cách nào biết việc đó vừa xảy ra.
 * Cách rẻ nhất mà vẫn đúng: mỗi lần khách quay lại tab, hỏi lại server một
 * lần. Không tốn gì khi tab đang ẩn, và đúng vào lúc khách thực sự nhìn.
 */
document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') loadNav();
});
