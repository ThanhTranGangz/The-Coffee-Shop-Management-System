package servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import service.LiteService;
import service.ShiftAutoScheduler;
import utils.ExcelUtils;
import utils.JsonUtils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

public class LiteApiServlet extends HttpServlet {
    private final LiteService service = LiteService.getInstance();
    private static final long DUPLICATE_ORDER_WINDOW_MS = 5000;
    private static final String ATTR_GUEST_TABLE_NAME = "guestTableName";
    private static final String ATTR_GUEST_TABLE_CODE = "guestTableCode";
    private static final String ATTR_GUEST_TABLE_VERIFIED = "guestTableVerified";
    private static final String ATTR_GUEST_ORDER_IDS = "guestOrderIds";
    private static final String ATTR_LAST_GUEST_ORDER_SIGNATURE = "lastGuestOrderSignature";
    private static final String ATTR_LAST_GUEST_ORDER_AT = "lastGuestOrderAt";
    private static final String ATTR_LAST_GUEST_ORDER_ID = "lastGuestOrderId";
    private static final String ATTR_ROLE = "role";
    private static final String ATTR_USER = "user";
    private static final String ATTR_PAID_ORDER_IDS = "paidOrderIds";
    private static final String ATTR_CUSTOMER_ID = "customerId";
    private static final String ATTR_STAFF_ID = "staffId";
    private static final String ATTR_STAFF_NAME = "staffName";
    private static final String ATTR_USERNAME = "username";
    /** PIN quản trị. Trước đây viết thẳng "8888" trong thân hàm ở nhiều chỗ. */
    private static final String ADMIN_PIN = "8888";
    private final dao.CustomerDAO customerDao = new dao.CustomerDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo() == null ? "/" : req.getPathInfo();
        try {
            if ("/events".equals(path)) {
                handleSse(req, resp);
                return;
            }
            if ("/tables/qr".equals(path)) {
                writeTableQr(req, resp);
                return;
            }
            if ("/menu/import-template".equals(path)) {
                if (!"admin".equals(role(req))) {
                    json(resp);
                    error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được tải mẫu import.");
                    return;
                }
                writeMenuImportTemplate(resp);
                return;
            }
            json(resp);
            switch (path) {
                case "/auth/session":
                    resp.getWriter().write(JsonUtils.toJson(sessionInfo(req)));
                    break;
                case "/roles":
                    resp.getWriter().write(JsonUtils.toJson(service.getRoles()));
                    break;
                case "/staff/roster":
                    // Công khai: màn đăng nhập cần danh sách này trước khi có phiên.
                    // Chỉ gồm id, tên và ca hôm nay — không có gì để mạo danh,
                    // vì vẫn phải nhập đúng PIN cá nhân mới vào được.
                    resp.getWriter().write(JsonUtils.toJson(service.getLoginRoster()));
                    break;
                case "/shifts/on-duty":
                    // Công khai: màn đăng nhập cần danh sách này TRƯỚC khi có phiên.
                    // Chỉ trả id + tên + ca, không lộ gì nhạy cảm.
                    resp.getWriter().write(JsonUtils.toJson(service.getStaffOnDuty(req.getParameter("role"))));
                    break;
                case "/payments/order": {
                    String payRole = role(req);
                    if (payRole.isEmpty() || "runner".equals(payRole) || "barista".equals(payRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ thu ngân hoặc admin xem được thông tin thanh toán.");
                        break;
                    }
                    Map<String, Object> pay = service.getPaymentByOrder(readInt(req.getParameter("orderId"), 0));
                    if (pay == null) error(resp, HttpServletResponse.SC_NOT_FOUND, "Đơn này chưa được thanh toán.");
                    else resp.getWriter().write(JsonUtils.toJson(pay));
                    break;
                }
                case "/payments/summary": {
                    String sumRole = role(req);
                    if (!"admin".equals(sumRole) && !"cashier".equals(sumRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin hoặc thu ngân xem được đối soát.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(
                            service.getPaymentSummary(req.getParameter("from"), req.getParameter("to"))));
                    break;
                }
                case "/reports/revenue-by-floor": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin xem được báo cáo.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(
                            service.getRevenueByFloor(req.getParameter("from"), req.getParameter("to"))));
                    break;
                }
                case "/reports/cogs": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin xem được báo cáo.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(
                            service.getCostOfGoodsSold(req.getParameter("from"), req.getParameter("to"))));
                    break;
                }
                case "/inventory/ledger": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin xem được sổ kho.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(
                            service.getStockLedger(req.getParameter("ingredientId"), readInt(req.getParameter("limit"), 100))));
                    break;
                }
                case "/inventory/audit": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin xem được đối soát kho.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.getStockAudit()));
                    break;
                }
                case "/customer/me": {
                    model.Customer me = currentCustomer(req);
                    if (me == null) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(customerPayload(me)));
                    }
                    break;
                }
                case "/customer/history": {
                    int meId = customerId(req);
                    if (meId <= 0) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(customerDao.getOrderHistory(
                                meId,
                                readInt(req.getParameter("limit"), 50),
                                str(req.getParameter("from")),
                                str(req.getParameter("to")))));
                    }
                    break;
                }
                case "/customer/points": {
                    int meId = customerId(req);
                    if (meId <= 0) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(customerDao.getPointHistory(meId, readInt(req.getParameter("limit"), 50))));
                    }
                    break;
                }
                case "/menu":
                    boolean admin = "admin".equals(role(req));
                    resp.getWriter().write(JsonUtils.toJson(service.getMenu(admin)));
                    break;
                case "/promotions": {
                    String promoRole = role(req);
                    if (!"admin".equals(promoRole) && !"cashier".equals(promoRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem khuyến mãi.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.getPromotions()));
                    break;
                }
                case "/store/tax-config":
                    resp.getWriter().write(JsonUtils.toJson(service.getStoreTaxConfig()));
                    break;
                case "/inventory":
                    java.util.List<java.util.Map<String, Object>> invList = new dao.InventoryDAO().getAll().stream().map(i -> i.toMap()).collect(java.util.stream.Collectors.toList());
                    resp.getWriter().write(JsonUtils.toJson(invList));
                    break;
                case "/tables":
                    if (role(req).isEmpty()) {
                        resp.getWriter().write(JsonUtils.toJson(service.getPublicTables()));
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(service.getTables()));
                    }
                    break;
                case "/tables/all":
                    resp.getWriter().write(JsonUtils.toJson(service.getAllTables()));
                    break;
                case "/tables/map":
                    if ("runner".equals(role(req))) {
                        resp.getWriter().write(JsonUtils.toJson(service.getRunnerTableMap()));
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(service.getTableMap()));
                    }
                    break;
                case "/tables/by-code":
                    Map<String, Object> table = service.getTableByCode(req.getParameter("code"));
                    if (table == null) {
                        error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy bàn.");
                    } else {
                        if (role(req).isEmpty()) {
                            Map<String, Object> locked = lockedGuestTable(req);
                            if (locked != null && !sameTable(locked, table)) {
                                resetGuestProgress(req);
                            }
                            lockGuestTable(req, table);
                        }
                        resp.getWriter().write(JsonUtils.toJson(table));
                    }
                    break;
                case "/orders":
                    resp.getWriter().write(JsonUtils.toJson(service.getOrders(orderViewRole(req), cashierPaidIds(req, false))));
                    break;
                case "/orders/lookup":
                    int orderNumber = readInt(req.getParameter("orderNumber"), 0);
                    Map<String, Object> order = service.getOrderByNumber(orderNumber);
                    if (order == null) {
                        error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy đơn hàng.");
                    } else if (role(req).isEmpty()
                            && !guestOrderIds(req, false).contains(readInt(order.get("id"), 0))
                            && !(customerId(req) > 0 && customerId(req) == readInt(order.get("customerId"), 0))) {
                        // Chủ đơn đã đăng nhập thì tra được đơn của mình ở bất kỳ
                        // thiết bị nào — đây chính là thứ phiên guest không làm được.
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ xem được đơn của phiên gọi món hiện tại.");
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(order));
                    }
                    break;
                case "/orders/invoice": {
                    String currentRole = role(req);
                    if (!"runner".equals(currentRole) && !"admin".equals(currentRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ bồi bàn được in hóa đơn.");
                        break;
                    }
                    int invoiceId = readInt(req.getParameter("id"), 0);
                    Map<String, Object> invoice = service.getOrderInvoice(invoiceId);
                    if (invoice == null) {
                        error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy đơn hàng.");
                    } else if ("runner".equals(currentRole)) {
                        String status = str(invoice.get("status"));
                        if (!"Ready".equals(status) && !"Served".equals(status)) {
                            error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ in được hóa đơn đơn đang phục vụ.");
                        } else {
                            resp.getWriter().write(JsonUtils.toJson(invoice));
                        }
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(invoice));
                    }
                    break;
                }
                case "/orders/table":
                    if (role(req).isEmpty()) {
                        resp.getWriter().write(JsonUtils.toJson(guestTrackOrders(req)));
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(service.getOpenOrdersByTable(req.getParameter("tableCode"), req.getParameter("table"))));
                    }
                    break;
                case "/dashboard":
                    resp.getWriter().write(JsonUtils.toJson(service.getDashboard(req.getParameter("start"), req.getParameter("end"))));
                    break;
                case "/cash/status":
                    resp.getWriter().write(JsonUtils.toJson(service.getCashStatus(role(req))));
                    break;
                case "/cups/status":
                    resp.getWriter().write(JsonUtils.toJson(service.getCupStatus()));
                    break;
                case "/logs":
                    resp.getWriter().write(JsonUtils.toJson(service.getSystemLogs(req.getParameter("actor"))));
                    break;
                case "/staff":
                    boolean isAdminStaffReq = "admin".equals(role(req));
                    java.util.List<java.util.Map<String, Object>> staffList = new dao.StaffDAO().getAll().stream().map(s -> {
                        java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
                        map.put("id", s.getId());
                        map.put("name", s.getName());

                        if (isAdminStaffReq) {
                            map.put("shift", "");
                            map.put("active", s.isActive());
                            
                            
                            map.put("status", s.getStatus());

                        }
                        return map;
                    }).collect(java.util.stream.Collectors.toList());
                    resp.getWriter().write(JsonUtils.toJson(staffList));
                    break;
                case "/shifts":
                    java.util.List<java.util.Map<String, Object>> shiftList = new dao.ShiftDAO().getAll().stream().map(s -> {
                        java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
                        map.put("id", s.getId());
                        map.put("staffId", s.getStaffId());
                        map.put("staffName", s.getStaffName());
                        map.put("date", s.getShiftDate());
                        map.put("shiftName", s.getShiftName());
                        map.put("hours", s.getHours());
                        map.put("status", s.getStatus());
                        map.put("notes", s.getNotes());
                        map.put("assignedRole", s.getAssignedRole());
                        return map;
                    }).collect(java.util.stream.Collectors.toList());
                    resp.getWriter().write(JsonUtils.toJson(shiftList));
                    break;
                case "/payroll":
                    String month = req.getParameter("month"); // e.g., "2026-07"
                    if (month == null || month.isEmpty()) {
                        error(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing 'month' parameter.");
                        return;
                    }
                    java.util.List<java.util.Map<String, Object>> payroll = new dao.ShiftDAO().getPayrollByMonth(month);
                    resp.getWriter().write(JsonUtils.toJson(payroll));
                    break;
                default:
                    error(resp, HttpServletResponse.SC_NOT_FOUND, "Endpoint not found.");
            }
        } catch (Exception e) {
            error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        json(resp);
        String path = req.getPathInfo() == null ? "/" : req.getPathInfo();
        if ("/menu/import".equals(path)) {
            try {
                if (!"admin".equals(role(req))) {
                    error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được import thực đơn.");
                    return;
                }
                Map<String, Object> result = handleMenuImport(req);
                service.addSystemLog(role(req), user(req), "MENU_IMPORT",
                        "Admin import " + result.get("importedCount") + " món từ Excel (bỏ qua " + result.get("skippedCount") + " dòng)",
                        "Admin imported " + result.get("importedCount") + " menu items from Excel (skipped " + result.get("skippedCount") + " rows)",
                        null);
                resp.getWriter().write(JsonUtils.toJson(result));
            } catch (Exception e) {
                error(resp, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
            }
            return;
        }
        Map<String, Object> body = JsonUtils.parseObject(readBody(req));
        try {
            switch (path) {
                case "/auth/login":
                    if ("admin".equals(str(body.get("username")))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Admin mở dashboard.jsp để nhập PIN.");
                        return;
                    }
                    // Đường đăng nhập bằng tài khoản vị trí dùng chung đã bị bỏ.
                    // Giữ lại endpoint để client cũ nhận được lý do rõ ràng thay
                    // vì lỗi khó hiểu, nhưng không cho vào nữa.
                    error(resp, HttpServletResponse.SC_GONE,
                            "Tài khoản dùng chung đã ngừng sử dụng. Vui lòng chọn tên của bạn và nhập PIN cá nhân.");
                    return;
                case "/customer/register": {
                    model.Customer created = customerDao.register(
                            str(body.get("phone")), str(body.get("password")), str(body.get("fullName")));
                    startCustomerSession(req, created);
                    service.addSystemLog("guest", created.getFullName(), "CUSTOMER_REGISTER",
                            "Khách " + maskPhone(created.getPhone()) + " đăng ký tài khoản",
                            "Customer " + maskPhone(created.getPhone()) + " registered an account",
                            created.getId());
                    resp.getWriter().write(JsonUtils.toJson(customerPayload(created)));
                    break;
                }
                case "/customer/login": {
                    model.Customer logged = customerDao.login(str(body.get("phone")), str(body.get("password")));
                    if (logged == null) {
                        // Một thông báo duy nhất cho mọi lý do sai: không tiết lộ
                        // số điện thoại nào đã tồn tại trong hệ thống.
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Số điện thoại hoặc mật khẩu không đúng.");
                        return;
                    }
                    startCustomerSession(req, logged);
                    resp.getWriter().write(JsonUtils.toJson(customerPayload(logged)));
                    break;
                }
                case "/customer/logout": {
                    HttpSession customerSession = req.getSession(false);
                    if (customerSession != null) {
                        customerSession.removeAttribute(tabAttr(req, ATTR_CUSTOMER_ID));
                    }
                    Map<String, Object> bye = new LinkedHashMap<>();
                    bye.put("ok", true);
                    resp.getWriter().write(JsonUtils.toJson(bye));
                    break;
                }
                case "/customer/profile": {
                    int meId = customerId(req);
                    if (meId <= 0) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
                        return;
                    }
                    resp.getWriter().write(JsonUtils.toJson(customerPayload(customerDao.updateProfile(meId, str(body.get("fullName"))))));
                    break;
                }
                case "/customer/password": {
                    int meId = customerId(req);
                    if (meId <= 0) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
                        return;
                    }
                    customerDao.changePassword(meId, str(body.get("oldPassword")), str(body.get("newPassword")));
                    Map<String, Object> ok = new LinkedHashMap<>();
                    ok.put("ok", true);
                    resp.getWriter().write(JsonUtils.toJson(ok));
                    break;
                }
                case "/auth/staff-login": {
                    int loginId = readInt(body.get("staffId"), 0);
                    String pin = str(body.get("pin"));
                    // Mở khoá ngoài ca: phải nhập PIN quản trị, không phải cờ
                    // do trình duyệt tự bật.
                    boolean override = ADMIN_PIN.equals(str(body.get("adminPin")));
                    Map<String, Object> staffSession;
                    try {
                        staffSession = service.loginStaff(loginId, pin, override);
                    } catch (IllegalStateException offShift) {
                        // 409: PIN đúng nhưng không có ca. Giao diện dựa vào mã
                        // này để hiện ô nhập PIN quản trị.
                        error(resp, HttpServletResponse.SC_CONFLICT, offShift.getMessage());
                        return;
                    }
                    if (staffSession == null) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Sai mã PIN.");
                        return;
                    }
                    HttpSession ss = req.getSession(true);
                    String staffRole = str(staffSession.get("role"));
                    ss.setAttribute(tabAttr(req, ATTR_ROLE), staffRole);
                    ss.setAttribute(tabAttr(req, ATTR_USER), staffSession.get("staffName"));
                    ss.setAttribute(tabAttr(req, ATTR_STAFF_ID), loginId);
                    ss.setAttribute(tabAttr(req, ATTR_STAFF_NAME), staffSession.get("staffName"));
                    ss.setAttribute(tabAttr(req, ATTR_USERNAME), staffSession.get("username"));
                    if ("cashier".equals(staffRole)) {
                        ss.setAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS), new ArrayList<Integer>());
                    } else {
                        ss.removeAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
                    }
                    LiteService.setActorStaffId(loginId);
                    String who = str(staffSession.get("staffName"));
                    service.addSystemLog(staffRole, who, "LOGIN",
                            who + " đăng nhập vai trò " + staffRole
                                    + (override ? " (QUẢN LÝ MỞ KHOÁ NGOÀI CA)" : "") + " lúc "
                                    + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy")),
                            who + " signed in as " + staffRole
                                    + (override ? " (MANAGER OVERRIDE, OFF SHIFT)" : "") + " at "
                                    + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy")),
                            loginId);
                    resp.getWriter().write(JsonUtils.toJson(staffSession));
                    break;
                }
                case "/staff/reset-pin": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin đặt lại được mã PIN.");
                        return;
                    }
                    int targetStaff = readInt(body.get("staffId"), 0);
                    String newPin = service.resetStaffPin(targetStaff, str(body.get("pin")));
                    service.addSystemLog("admin", user(req), "STAFF_PIN_RESET",
                            "Admin đặt lại PIN cho nhân viên #" + targetStaff,
                            "Admin reset PIN for staff #" + targetStaff, targetStaff);
                    Map<String, Object> pinResult = new LinkedHashMap<>();
                    pinResult.put("staffId", targetStaff);
                    pinResult.put("pin", newPin);
                    resp.getWriter().write(JsonUtils.toJson(pinResult));
                    break;
                }
                case "/auth/admin-pin":
                    if (!ADMIN_PIN.equals(str(body.get("pin")))) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Sai mã PIN quản trị.");
                        return;
                    }
                    HttpSession adminSession = req.getSession(true);
                    adminSession.setAttribute(tabAttr(req, ATTR_ROLE), "admin");
                    adminSession.setAttribute(tabAttr(req, ATTR_USER), "Quản trị coffeshop");
                    adminSession.setAttribute(tabAttr(req, ATTR_USERNAME), "admin");
                    adminSession.removeAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
                    adminSession.removeAttribute(tabAttr(req, ATTR_STAFF_ID));
                    adminSession.removeAttribute(tabAttr(req, ATTR_STAFF_NAME));
                    service.addSystemLog("admin", "Quản trị coffeshop", "ADMIN_UNLOCK",
                            "Admin mở khoá dashboard lúc " + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy")),
                            "Admin unlocked dashboard at " + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy")),
                            null);
                    Map<String, Object> admin = new LinkedHashMap<>();
                    admin.put("username", "admin");
                    admin.put("role", "admin");
                    admin.put("fullName", "Quản trị coffeshop");
                    resp.getWriter().write(JsonUtils.toJson(admin));
                    break;
                case "/auth/logout":
                    String logoutRole = role(req);
                    String logoutUser = user(req);
                    if (!logoutRole.isEmpty()) {
                        service.addSystemLog(logoutRole, logoutUser, "LOGOUT",
                                logoutUser + " đăng xuất lúc " + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy")),
                                logoutUser + " signed out at " + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy")),
                                null);
                    }
                    clearTabSession(req);
                    resp.getWriter().write("{\"message\":\"Logged out\"}");
                    break;
                case "/orders":
                    if (role(req).isEmpty()) {
                        resp.getWriter().write(JsonUtils.toJson(createGuestOrder(req, body)));
                    } else {
                        // Nhân viên gọi hộ tại quầy: cho phép gắn đơn vào tài khoản
                        // khách qua số điện thoại, nhưng chỉ nhận id do server tra ra.
                        body.remove("customerId");
                        model.Customer byPhone = customerDao.findByPhone(str(body.get("customerPhone")));
                        if (byPhone != null && byPhone.isActive()) body.put("customerId", byPhone.getId());
                        body.remove("redeemPoints");
                        resp.getWriter().write(JsonUtils.toJson(service.createOrder(body, role(req), user(req))));
                    }
                    break;
                case "/orders/status":
                    int orderId = readInt(body.get("id"), 0);
                    String status = str(body.get("status"));
                    String currentRole = role(req);
                    Map<String, Object> order = service.getOrderById(orderId);
                    if (order == null) {
                        error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy đơn hàng.");
                        return;
                    }
                    if (!canSetStatus(currentRole, str(order.get("status")), status)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ được chuyển trạng thái theo đúng thứ tự.");
                        return;
                    }
                    // Thu ngân gửi kèm hình thức thanh toán và số tiền khách đưa.
                    Map<String, Object> paymentInfo = null;
                    if ("Paid".equals(status)) {
                        paymentInfo = new LinkedHashMap<>();
                        paymentInfo.put("method", str(body.get("paymentMethod")));
                        paymentInfo.put("receivedAmount", readInt(body.get("receivedAmount"), 0));
                        paymentInfo.put("tipAmount", readInt(body.get("tipAmount"), 0));
                        paymentInfo.put("cashierUsername", username(req).isEmpty() ? currentRole : username(req));
                        paymentInfo.put("cashierName", staffName(req).isEmpty() ? user(req) : staffName(req));
                        paymentInfo.put("staffId", staffId(req));
                        paymentInfo.put("note", str(body.get("paymentNote")));
                    }
                    Map<String, Object> updatedOrder = service.updateOrderStatus(orderId, status, currentRole, user(req), paymentInfo);
                    if ("cashier".equals(currentRole) && "Paid".equals(status)) {
                        rememberPaidOrder(req, orderId);
                    }
                    if ("runner".equals(currentRole)) sanitizeRunnerOrder(updatedOrder);
                    resp.getWriter().write(JsonUtils.toJson(updatedOrder));
                    break;
                case "/orders/item-prepare": {
                    String prepareRole = role(req);
                    if (!"barista".equals(prepareRole) && !"admin".equals(prepareRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ pha chế được đánh dấu món đã pha.");
                        return;
                    }
                    Map<String, Object> preparedOrder = service.prepareOrderItem(
                            readInt(body.get("orderId"), 0),
                            readInt(body.get("menuItemId"), 0),
                            str(body.get("itemSize")),
                            prepareRole,
                            user(req));
                    resp.getWriter().write(JsonUtils.toJson(preparedOrder));
                    break;
                }
                case "/orders/split":
                    String splitRole = role(req);
                    if (!"cashier".equals(splitRole) && !"admin".equals(splitRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ thu ngân hoặc admin được tách đơn.");
                        return;
                    }
                    Map<String, Object> splitResult = service.splitOrder(readInt(body.get("id"), 0), splitSelections(body.get("items")), splitRole, user(req));
                    resp.getWriter().write(JsonUtils.toJson(splitResult));
                    break;
                case "/orders/invoice/printed": {
                    String printRole = role(req);
                    if (!"runner".equals(printRole) && !"admin".equals(printRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ bồi bàn được ghi nhận in hóa đơn.");
                        break;
                    }
                    int printedOrderId = readInt(body.get("id"), 0);
                    Map<String, Object> existingInvoice = service.getOrderById(printedOrderId);
                    if (existingInvoice == null) {
                        error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy đơn hàng.");
                        break;
                    }
                    if ("runner".equals(printRole)) {
                        status = str(existingInvoice.get("status"));
                        if (!"Ready".equals(status) && !"Served".equals(status)) {
                            error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ in được hóa đơn đơn đang phục vụ.");
                            break;
                        }
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.markInvoicePrinted(printedOrderId)));
                    break;
                }
                case "/orders/cancel": {
                    int cancelId = readInt(body.get("id"), 0);
                    String cancelReason = str(body.get("reason"));
                    String cancelRole = role(req);
                    if (cancelRole.isEmpty()) {
                        // Khách: chỉ hủy được đơn trong phiên guestOrderIds.
                        List<Integer> owned = guestOrderIds(req, false);
                        if (!owned.contains(cancelId)) {
                            error(resp, HttpServletResponse.SC_FORBIDDEN, "Bạn chỉ có thể hủy đơn của chính mình.");
                            break;
                        }
                        cancelRole = "guest";
                    }
                    Map<String, Object> cancelled = service.cancelOrder(cancelId, cancelReason, cancelRole,
                            cancelRole.equals("guest") ? "Khách" : user(req));
                    resp.getWriter().write(JsonUtils.toJson(cancelled));
                    break;
                }
                case "/orders/refund": {
                    String refundRole = role(req);
                    if (!"admin".equals(refundRole) && !"cashier".equals(refundRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ quản trị hoặc thu ngân được hoàn tiền.");
                        break;
                    }
                    // Cashier cần nhập đúng PIN quản trị (không đổi session).
                    if ("cashier".equals(refundRole)) {
                        if (!ADMIN_PIN.equals(str(body.get("adminPin")))) {
                            error(resp, HttpServletResponse.SC_FORBIDDEN, "Hoàn tiền cần đúng PIN quản trị.");
                            break;
                        }
                    }
                    boolean restock = body.get("restock") == null || Boolean.TRUE.equals(body.get("restock"))
                            || "1".equals(String.valueOf(body.get("restock")))
                            || "true".equalsIgnoreCase(String.valueOf(body.get("restock")));
                    Map<String, Object> refunded = service.refundOrder(
                            readInt(body.get("id"), 0),
                            str(body.get("reason")),
                            restock,
                            refundRole,
                            user(req));
                    resp.getWriter().write(JsonUtils.toJson(refunded));
                    break;
                }
                case "/promotions": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin quản lý khuyến mãi.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.savePromotion(body)));
                    break;
                }
                case "/promotions/delete": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin quản lý khuyến mãi.");
                        break;
                    }
                    service.deletePromotion(readInt(body.get("id"), 0));
                    resp.getWriter().write("{\"message\":\"ok\"}");
                    break;
                }
                case "/store/tax-config": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin cấu hình thuế.");
                        break;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.saveStoreTaxConfig(body)));
                    break;
                }
                case "/menu":
                    Map<String, Object> savedMenu = service.saveMenuItem(body);
                    service.addSystemLog(role(req), user(req), "MENU_SAVE",
                            "Admin lưu món " + str(savedMenu.get("nameVi")), "Admin saved menu item " + str(savedMenu.get("nameEn")), readInt(savedMenu.get("id"), 0));
                    resp.getWriter().write(JsonUtils.toJson(savedMenu));
                    break;
                case "/shifts":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được lưu ca làm.");
                        return;
                    }
                    dao.ShiftDAO shiftDAO = new dao.ShiftDAO();
                    String shiftId = str(body.get("id"));
                    boolean isNewShift = shiftId.isEmpty();
                    if (isNewShift) {
                        shiftId = "s" + System.currentTimeMillis() + "-" + Math.abs(java.util.UUID.randomUUID().toString().hashCode());
                    }

                    int staffIdForShift = readInt(body.get("staffId"), 0);
                    String shiftDateForShift = str(body.get("date"));
                    String shiftNameForShift = str(body.get("shiftName"));
                    if (staffIdForShift <= 0 || shiftDateForShift.isEmpty() || shiftNameForShift.isEmpty()) {
                        error(resp, HttpServletResponse.SC_BAD_REQUEST, "Thiếu thông tin phân công ca.");
                        return;
                    }

                    if (shiftDAO.existsOverlap(staffIdForShift, shiftDateForShift, shiftNameForShift, isNewShift ? "" : shiftId)) {
                        error(resp, HttpServletResponse.SC_BAD_REQUEST, "SHIFT_OVERLAP");
                        return;
                    }

                    model.Shift shift = new model.Shift(
                        shiftId,
                        staffIdForShift,
                        str(body.get("staffName")),
                        shiftDateForShift,
                        shiftNameForShift,
                        str(body.get("hours")),
                        str(body.get("status")),
                        str(body.get("notes")),
                        // Chuẩn hoá trước khi lưu: assignedRole nay có khoá ngoại
                        // sang dbo.Roles nên chuỗi lạ sẽ bị CSDL từ chối.
                        LiteService.normalizeRoleCode(str(body.get("assignedRole")))
                    );
                    try {
                        shiftDAO.save(shift);
                    } catch (Exception saveErr) {
                        if (shiftDAO.existsOverlap(staffIdForShift, shiftDateForShift, shiftNameForShift, isNewShift ? "" : shiftId)) {
                            error(resp, HttpServletResponse.SC_BAD_REQUEST, "SHIFT_OVERLAP");
                            return;
                        }
                        throw saveErr;
                    }
                    java.util.Map<String, Object> sMap = new java.util.LinkedHashMap<>();
                    sMap.put("id", shift.getId());
                    sMap.put("staffId", shift.getStaffId());
                    sMap.put("staffName", shift.getStaffName());
                    sMap.put("date", shift.getShiftDate());
                    sMap.put("shiftName", shift.getShiftName());
                    sMap.put("hours", shift.getHours());
                    sMap.put("status", shift.getStatus());
                    sMap.put("notes", shift.getNotes());
                    sMap.put("assignedRole", shift.getAssignedRole());
                    resp.getWriter().write(JsonUtils.toJson(sMap));
                    break;
                case "/shifts/delete":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được xóa ca làm.");
                        return;
                    }
                    new dao.ShiftDAO().delete(str(body.get("id")));
                    resp.getWriter().write("{\"success\":true}");
                    break;
                case "/shifts/carry-over":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được sao chép lịch.");
                        return;
                    }
                    java.time.LocalDate todayForCarry = java.time.LocalDate.now();
                    java.time.LocalDate currentMon = todayForCarry.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
                    java.time.LocalDate nextMon = currentMon.plusWeeks(1);
                    int copied = ShiftAutoScheduler.carryOver(currentMon.toString(), nextMon.toString());
                    java.util.Map<String, Object> carryResult = new java.util.LinkedHashMap<>();
                    carryResult.put("success", true);
                    carryResult.put("copied", copied);
                    if (copied == 0) {
                        carryResult.put("message", "Không có ca làm mới nào được sao chép (tuần này chưa có lịch hoặc tất cả các ca đều đã tồn tại ở tuần tới).");
                    }
                    resp.getWriter().write(JsonUtils.toJson(carryResult));
                    break;
                case "/staff/save": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được lưu nhân viên.");
                        return;
                    }
                    // id vắng mặt hoặc <= 0 nghĩa là THÊM MỚI; mã do server cấp.
                    // Không bao giờ nhận mã từ client cho người mới — đó chính
                    // là đường dẫn tới việc ghi đè hồ sơ người khác.
                    Map<String, Object> savedStaff = service.saveStaff(
                            readInt(body.get("id"), 0), str(body.get("name")), str(body.get("status")));
                    int savedStaffId = readInt(savedStaff.get("id"), 0);
                    String savedStaffName = str(savedStaff.get("name"));
                    // Tạo tài khoản đăng nhập NGAY, không đợi tới lần khởi động sau.
                    // Nếu vừa tạo thì trả PIN mặc định về cho admin đọc một lần.
                    // Rỗng nghĩa là tài khoản đã có sẵn, không phải vừa tạo.
                    savedStaff.put("issuedPin", service.ensureAccountForStaff(savedStaffId, savedStaffName));
                    if (Boolean.TRUE.equals(savedStaff.get("created"))) {
                        service.addSystemLog("admin", user(req), "STAFF_CREATE",
                                "Admin thêm nhân viên " + savedStaffName + ", hệ thống cấp mã #" + savedStaffId,
                                "Admin added staff " + savedStaffName + ", system assigned id #" + savedStaffId,
                                savedStaffId);
                    }
                    resp.getWriter().write(JsonUtils.toJson(savedStaff));
                    break;
                }
                case "/staff/delete": {
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được xóa nhân viên.");
                        return;
                    }
                    int removedId = readInt(body.get("id"), 0);
                    Map<String, Object> removed = service.deleteStaff(removedId);
                    boolean hardDeleted = Boolean.TRUE.equals(removed.get("hardDeleted"));
                    String removedName = str(removed.get("name"));
                    // Ghi rõ đã xoá hẳn hay chỉ cho nghỉ: hai việc khác nhau,
                    // nhật ký mà nói chung chung thì sau này không tra được.
                    service.addSystemLog("admin", user(req), hardDeleted ? "STAFF_PURGE" : "STAFF_DEACTIVATE",
                            hardDeleted
                                    ? "Admin xoá vĩnh viễn nhân viên " + removedName + " #" + removedId
                                      + " (không còn dữ liệu liên quan)"
                                    : "Admin cho nghỉ việc nhân viên " + removedName + " #" + removedId
                                      + " và gỡ tài khoản đăng nhập; hồ sơ giữ lại vì còn lịch sử",
                            hardDeleted
                                    ? "Admin permanently deleted staff " + removedName + " #" + removedId
                                      + " (no related records)"
                                    : "Admin deactivated staff " + removedName + " #" + removedId
                                      + " and removed the login account; profile kept because of history",
                            removedId);
                    removed.put("success", true);
                    resp.getWriter().write(JsonUtils.toJson(removed));
                    break;
                }
                case "/menu/delete":
                    service.deleteMenuItem(readInt(body.get("id"), 0));
                    service.addSystemLog(role(req), user(req), "MENU_DELETE",
                            "Admin xoá/ẩn món #" + readInt(body.get("id"), 0), "Admin deleted/hidden menu item #" + readInt(body.get("id"), 0), readInt(body.get("id"), 0));
                    resp.getWriter().write("{\"message\":\"Menu item deleted\"}");
                    break;
                case "/inventory/save":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được sửa kho nguyên liệu.");
                        return;
                    }
                    try {
                        String originalId = str(body.get("originalId"));
                        boolean isCreate = originalId.isEmpty();
                        String id = str(body.get("id"));
                        String name = str(body.get("name"));
                        String unit = str(body.get("unit"));
                        Integer stock = parseNonNegativeInt(body.get("stock"), "Tồn kho");
                        Integer minStock = parseNonNegativeInt(body.get("minStock"), "Mức tối thiểu");
                        Integer importCost = parseNonNegativeInt(body.get("importCost"), "Giá nhập");
                        if (stock == null || minStock == null || importCost == null) {
                            error(resp, HttpServletResponse.SC_BAD_REQUEST, "Giá trị số không hợp lệ.");
                            return;
                        }

                        String validationError = validateIngredientFields(isCreate ? id : originalId, name, unit);
                        if (validationError != null) {
                            error(resp, HttpServletResponse.SC_BAD_REQUEST, validationError);
                            return;
                        }

                        model.Ingredient ing = new model.Ingredient();
                        ing.setId(isCreate ? id : originalId);
                        ing.setName(name);
                        ing.setUnit(unit);
                        ing.setStock(stock);
                        ing.setMinStock(minStock);
                        ing.setImportCost(importCost);

                        dao.InventoryDAO inventoryDAO = new dao.InventoryDAO();
                        if (isCreate) {
                            try {
                                inventoryDAO.insert(ing);
                            } catch (IllegalStateException duplicate) {
                                if ("DUPLICATE_ID".equals(duplicate.getMessage())) {
                                    error(resp, HttpServletResponse.SC_CONFLICT, "Mã nguyên liệu đã tồn tại.");
                                    return;
                                }
                                throw duplicate;
                            }
                        } else {
                            if (!inventoryDAO.update(originalId, ing)) {
                                error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy nguyên liệu để cập nhật.");
                                return;
                            }
                            ing.setId(originalId);
                        }

                        int disabledMenus = service.refreshMenuAvailability();
                        service.addSystemLog(role(req), user(req), "INVENTORY_SAVE",
                                "Admin lưu nguyên liệu " + ing.getId() + " - " + ing.getName()
                                        + (disabledMenus > 0 ? (" (tắt " + disabledMenus + " món hết hàng)") : ""),
                                "Admin saved ingredient " + ing.getId() + " - " + ing.getName()
                                        + (disabledMenus > 0 ? (" (disabled " + disabledMenus + " out-of-stock items)") : ""),
                                null);
                        java.util.Map<String, Object> savedIng = new java.util.LinkedHashMap<>(ing.toMap());
                        savedIng.put("disabledMenuCount", disabledMenus);
                        resp.getWriter().write(JsonUtils.toJson(savedIng));
                    } catch (IllegalArgumentException badRequest) {
                        error(resp, HttpServletResponse.SC_BAD_REQUEST, badRequest.getMessage());
                    } catch (Exception dbError) {
                        error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                                dbError.getMessage() == null || dbError.getMessage().trim().isEmpty()
                                        ? "Không lưu được nguyên liệu do lỗi hệ thống."
                                        : dbError.getMessage());
                    }
                    break;
                case "/inventory/delete":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được xoá nguyên liệu.");
                        return;
                    }
                    try {
                        String ingId = str(body.get("id"));
                        if (ingId.isEmpty()) {
                            error(resp, HttpServletResponse.SC_BAD_REQUEST, "Thiếu mã nguyên liệu cần xoá.");
                            return;
                        }
                        dao.InventoryDAO inventoryDAO = new dao.InventoryDAO();
                        if (!inventoryDAO.exists(ingId)) {
                            error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy nguyên liệu để xoá.");
                            return;
                        }
                        int recipeUsage = inventoryDAO.countRecipeUsage(ingId);
                        if (recipeUsage > 0) {
                            error(resp, HttpServletResponse.SC_CONFLICT,
                                    "Không thể xoá nguyên liệu đang được dùng trong " + recipeUsage + " công thức món.");
                            return;
                        }
                        if (!inventoryDAO.delete(ingId)) {
                            error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy nguyên liệu để xoá.");
                            return;
                        }
                        int disabledAfterDelete = service.refreshMenuAvailability();
                        service.addSystemLog(role(req), user(req), "INVENTORY_DELETE",
                                "Admin xoá nguyên liệu " + ingId
                                        + (disabledAfterDelete > 0 ? (" (tắt " + disabledAfterDelete + " món hết hàng)") : ""),
                                "Admin deleted ingredient " + ingId
                                        + (disabledAfterDelete > 0 ? (" (disabled " + disabledAfterDelete + " out-of-stock items)") : ""),
                                null);
                        resp.getWriter().write("{\"message\":\"Ingredient deleted\",\"disabledMenuCount\":" + disabledAfterDelete + "}");
                    } catch (IllegalArgumentException badRequest) {
                        error(resp, HttpServletResponse.SC_BAD_REQUEST, badRequest.getMessage());
                    } catch (Exception dbError) {
                        error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                                dbError.getMessage() == null || dbError.getMessage().trim().isEmpty()
                                        ? "Không xoá được nguyên liệu do lỗi hệ thống."
                                        : dbError.getMessage());
                    }
                    break;
                case "/tables":
                    Map<String, Object> savedTable = service.saveTable(body);
                    service.addSystemLog(role(req), user(req), "TABLE_SAVE",
                            "Admin lưu " + str(savedTable.get("name")), "Admin saved " + str(savedTable.get("name")), readInt(savedTable.get("id"), 0));
                    resp.getWriter().write(JsonUtils.toJson(savedTable));
                    break;
                case "/tables/delete":
                    service.deleteTable(readInt(body.get("id"), 0));
                    service.addSystemLog(role(req), user(req), "TABLE_DELETE",
                            "Admin xoá bàn #" + readInt(body.get("id"), 0), "Admin deleted table #" + readInt(body.get("id"), 0), readInt(body.get("id"), 0));
                    resp.getWriter().write("{\"message\":\"Table deleted\"}");
                    break;
                case "/cash/count":
                    if (!"cashier".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ thu ngân được chốt tiền mặt.");
                        return;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.recordCashierCount(readInt(body.get("amount"), -1), user(req))));
                    break;
                case "/cash/withdraw":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được rút tiền mặt.");
                        return;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.withdrawCash(readInt(body.get("amount"), 0), user(req))));
                    break;
                case "/cash/ack-withdrawals":
                    if (!"cashier".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ thu ngân được xác nhận thông báo.");
                        return;
                    }
                    service.acknowledgeCashierWithdrawals();
                    resp.getWriter().write("{\"message\":\"Acknowledged\"}");
                    break;
                case "/cups/update":
                    if (!"admin".equals(role(req))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ admin được sửa số lượng cốc.");
                        return;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.updateCupStock(readInt(body.get("amount"), 0), str(body.get("mode")), user(req))));
                    break;
                case "/tables/regenerate":
                    resp.getWriter().write(JsonUtils.toJson(service.regenerateTableCode(readInt(body.get("id"), 0))));
                    break;
                case "/tables/clear":
                    String clearRole = role(req);
                    if (!"runner".equals(clearRole) && !"admin".equals(clearRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ bồi bàn được dọn bàn.");
                        return;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.clearServedTable(readInt(body.get("tableId"), 0), clearRole, user(req))));
                    break;
                case "/tables/transfer":
                    String transferRole = role(req);
                    if (!"runner".equals(transferRole) && !"cashier".equals(transferRole) && !"admin".equals(transferRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Không có quyền đổi bàn.");
                        return;
                    }
                    resp.getWriter().write(JsonUtils.toJson(service.transferTable(readInt(body.get("fromTableId"), 0), readInt(body.get("toTableId"), 0), transferRole, user(req))));
                    break;
                default:
                    error(resp, HttpServletResponse.SC_NOT_FOUND, "Endpoint not found.");
            }
        } catch (Exception e) {
            error(resp, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        }
    }

    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp) {
        json(resp);
        resp.setStatus(HttpServletResponse.SC_OK);
    }

    private Map<String, Object> createGuestOrder(HttpServletRequest req, Map<String, Object> body) throws Exception {
        HttpSession session = req.getSession(true);
        String postedTableCode = str(body.get("tableCode"));
        boolean hasQrTableCode = !postedTableCode.isEmpty();
        Map<String, Object> requested = requestedTable(body.get("tableCode"), body.get("tableName"));
        Map<String, Object> table;
        if (hasQrTableCode) {
            if (requested == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            Map<String, Object> locked = lockedGuestTable(req);
            if (locked != null && !sameTable(locked, requested)) {
                resetGuestProgress(req);
            }
            table = requested;
        } else {
            List<Integer> orderIds = guestOrderIds(req, false);
            String activeTableName = service.currentTableForOrderIds(orderIds);
            if (!activeTableName.isEmpty()) {
                table = service.getTableByName(activeTableName);
            } else {
                table = lockedGuestTable(req);
                if (table == null || !hasVerifiedGuestTable(req)) {
                    throw new IllegalArgumentException("Vui lòng quét QR trên bàn để gọi món.");
                }
                if (requested != null && !sameTable(table, requested)) {
                    throw new IllegalArgumentException("Bàn đã được cố định theo QR đang sử dụng.");
                }
            }
        }
        if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");

        body.put("tableName", str(table.get("name")));
        body.put("tableCode", str(table.get("code")));
        lockGuestTable(req, table, true);

        String signature = guestOrderSignature(body);
        long now = System.currentTimeMillis();
        String previousSignature = str(session.getAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_SIGNATURE)));
        long previousAt = readLong(session.getAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_AT)), 0L);
        int previousOrderId = readInt(session.getAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_ID)), 0);
        if (signature.equals(previousSignature) && previousOrderId > 0 && now - previousAt <= DUPLICATE_ORDER_WINDOW_MS) {
            Map<String, Object> existing = service.getOrderById(previousOrderId);
            if (existing != null) {
                existing.put("duplicate", true);
                rememberGuestOrder(req, previousOrderId);
                return existing;
            }
        }

        // customerId LUÔN lấy từ phiên trên server, không bao giờ tin body.
        // Nếu trình duyệt tự khai customerId thì giá trị đó bị xoá ở đây.
        body.remove("customerId");
        int sessionCustomerId = customerId(req);
        if (sessionCustomerId > 0) body.put("customerId", sessionCustomerId);
        else body.remove("redeemPoints");

        Map<String, Object> order = service.createOrder(body);
        int orderId = readInt(order.get("id"), 0);
        rememberGuestOrder(req, orderId);
        session.setAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_SIGNATURE), signature);
        session.setAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_AT), now);
        session.setAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_ID), orderId);
        return order;
    }

    /**
     * Theo dõi đơn phía khách: chỉ đơn của phiên hiện tại (+ đơn hôm nay nếu đã đăng nhập).
     * Trả { active, past, tableName } — không lộ đơn người khác trên cùng bàn.
     */
    private Map<String, Object> guestTrackOrders(HttpServletRequest req) throws Exception {
        Map<String, Object> requested = requestedTable(req.getParameter("tableCode"), req.getParameter("table"));
        boolean hasQrTableCode = !str(req.getParameter("tableCode")).isEmpty();
        if (hasQrTableCode && requested != null) {
            Map<String, Object> locked = lockedGuestTable(req);
            if (locked != null && !sameTable(locked, requested)) {
                resetGuestProgress(req);
            }
            ensureGuestTableMatches(req, requested, true);
        } else if (requested != null) {
            Map<String, Object> locked = lockedGuestTable(req);
            if (locked != null && sameTable(locked, requested) && hasVerifiedGuestTable(req)) {
                // giữ bàn đã khoá
            }
        }

        LinkedHashSet<Integer> idSet = new LinkedHashSet<>(guestOrderIds(req, false));
        int custId = customerId(req);
        if (custId > 0) {
            String today = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).toString();
            idSet.addAll(customerDao.getOrderIdsForCustomerOnDate(custId, today));
        }

        List<Map<String, Object>> all = service.getOrdersByIds(new ArrayList<>(idSet));
        rememberGuestTableFromOrders(req, all);

        List<Map<String, Object>> active = new ArrayList<>();
        List<Map<String, Object>> past = new ArrayList<>();
        for (Map<String, Object> order : all) {
            String status = str(order.get("status"));
            if ("Cleared".equals(status) || "Cancelled".equals(status) || "Refunded".equals(status)) {
                past.add(order);
            } else {
                active.add(order);
            }
        }

        String resolvedTable = "";
        Map<String, Object> locked = lockedGuestTable(req);
        if (locked != null) resolvedTable = str(locked.get("name"));
        if (resolvedTable.isEmpty() && requested != null) resolvedTable = str(requested.get("name"));
        if (resolvedTable.isEmpty() && !active.isEmpty()) resolvedTable = str(active.get(0).get("tableName"));
        if (resolvedTable.isEmpty() && !past.isEmpty()) resolvedTable = str(past.get(0).get("tableName"));

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("active", active);
        payload.put("past", past);
        payload.put("tableName", resolvedTable);
        payload.put("scope", custId > 0 ? "session_and_today" : "session");
        return payload;
    }

    private List<Map<String, Object>> guestTableOrders(HttpServletRequest req) throws Exception {
        Map<String, Object> track = guestTrackOrders(req);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> active = (List<Map<String, Object>>) track.get("active");
        return active != null ? active : new ArrayList<>();
    }

    private Map<String, Object> requestedTable(Object tableCode, Object tableName) throws Exception {
        String code = str(tableCode);
        if (!code.isEmpty()) {
            Map<String, Object> table = service.getTableByCode(code);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            return table;
        }
        String name = str(tableName);
        if (name.isEmpty()) return null;
        Map<String, Object> table = service.getTableByName(name);
        if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
        return table;
    }

    private void ensureGuestTableMatches(HttpServletRequest req, Map<String, Object> table, boolean verified) throws Exception {
        Map<String, Object> locked = lockedGuestTable(req);
        if (locked != null && !str(locked.get("name")).equals(str(table.get("name")))) {
            throw new IllegalArgumentException("Bàn đã được cố định theo QR đang sử dụng.");
        }
        lockGuestTable(req, table, verified);
    }

    private void lockGuestTable(HttpServletRequest req, Map<String, Object> table) {
        lockGuestTable(req, table, true);
    }

    private void lockGuestTable(HttpServletRequest req, Map<String, Object> table, boolean verified) {
        if (!role(req).isEmpty() || table == null) return;
        HttpSession session = req.getSession(true);
        session.setAttribute(tabAttr(req, ATTR_GUEST_TABLE_NAME), str(table.get("name")));
        session.setAttribute(tabAttr(req, ATTR_GUEST_TABLE_CODE), str(table.get("code")));
        if (verified) {
            session.setAttribute(tabAttr(req, ATTR_GUEST_TABLE_VERIFIED), Boolean.TRUE);
        } else if (session.getAttribute(tabAttr(req, ATTR_GUEST_TABLE_VERIFIED)) == null) {
            session.setAttribute(tabAttr(req, ATTR_GUEST_TABLE_VERIFIED), Boolean.FALSE);
        }
    }

    private Map<String, Object> lockedGuestTable(HttpServletRequest req) throws Exception {
        if (!role(req).isEmpty()) return null;
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        String name = str(session.getAttribute(tabAttr(req, ATTR_GUEST_TABLE_NAME)));
        if (name.isEmpty()) return null;
        return service.getTableByName(name);
    }

    private boolean hasVerifiedGuestTable(HttpServletRequest req) {
        if (!role(req).isEmpty()) return false;
        HttpSession session = req.getSession(false);
        Object verified = session == null ? null : session.getAttribute(tabAttr(req, ATTR_GUEST_TABLE_VERIFIED));
        return Boolean.TRUE.equals(verified);
    }

    private void rememberGuestTableFromOrders(HttpServletRequest req, List<Map<String, Object>> orders) throws Exception {
        if (orders == null || orders.isEmpty()) return;
        String tableName = str(orders.get(0).get("tableName"));
        if (tableName.isEmpty()) return;
        Map<String, Object> table = service.getTableByName(tableName);
        if (table != null) lockGuestTable(req, table);
    }

    @SuppressWarnings("unchecked")
    private List<Integer> guestOrderIds(HttpServletRequest req, boolean create) {
        if (!role(req).isEmpty()) return new ArrayList<>();
        HttpSession session = req.getSession(create);
        if (session == null) return new ArrayList<>();
        Object value = session.getAttribute(tabAttr(req, ATTR_GUEST_ORDER_IDS));
        if (value instanceof List<?>) return (List<Integer>) value;
        List<Integer> ids = new ArrayList<>();
        session.setAttribute(tabAttr(req, ATTR_GUEST_ORDER_IDS), ids);
        return ids;
    }

    private void rememberGuestOrder(HttpServletRequest req, int orderId) {
        if (orderId <= 0) return;
        List<Integer> ids = guestOrderIds(req, true);
        if (!ids.contains(orderId)) ids.add(0, orderId);
        while (ids.size() > 50) ids.remove(ids.size() - 1);
    }

    private boolean sameTable(Map<String, Object> left, Map<String, Object> right) {
        if (left == null || right == null) return false;
        int leftId = readInt(left.get("id"), 0);
        int rightId = readInt(right.get("id"), 0);
        if (leftId > 0 && rightId > 0) return leftId == rightId;
        return str(left.get("name")).equals(str(right.get("name")));
    }

    private void resetGuestProgress(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return;
        session.removeAttribute(tabAttr(req, ATTR_GUEST_TABLE_NAME));
        session.removeAttribute(tabAttr(req, ATTR_GUEST_TABLE_CODE));
        session.removeAttribute(tabAttr(req, ATTR_GUEST_TABLE_VERIFIED));
        session.removeAttribute(tabAttr(req, ATTR_GUEST_ORDER_IDS));
        session.removeAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_SIGNATURE));
        session.removeAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_AT));
        session.removeAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_ID));
    }

    private String guestOrderSignature(Map<String, Object> body) {
        StringBuilder sb = new StringBuilder();
        sb.append(str(body.get("tableName"))).append('|').append(str(body.get("note"))).append('|');
        Object rawItems = body.get("items");
        if (rawItems instanceof Iterable<?>) {
            for (Object raw : (Iterable<?>) rawItems) {
                if (!(raw instanceof Map<?, ?>)) continue;
                Map<?, ?> item = (Map<?, ?>) raw;
                sb.append(readInt(item.get("menuItemId"), 0)).append(':')
                        .append(str(item.get("size")).toUpperCase()).append(':')
                        .append(readInt(item.get("quantity"), 1)).append(';');
            }
        }
        return sb.toString();
    }

    private Map<String, Object> sessionInfo(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("authenticated", session != null && session.getAttribute(tabAttr(req, ATTR_ROLE)) != null);
        info.put("role", session == null ? null : session.getAttribute(tabAttr(req, ATTR_ROLE)));
        info.put("user", session == null ? null : session.getAttribute(tabAttr(req, ATTR_USER)));
        info.put("tabSession", tabKey(req));
        info.put("staffId", staffId(req));
        info.put("staffName", staffName(req));
        // Thông tin khách hàng để thanh điều hướng biết hiển thị "Đăng nhập"
        // hay tên khách + số điểm. Lỗi ở đây không được làm hỏng cả trang.
        int cid = customerId(req);
        info.put("customerAuthenticated", cid > 0);
        if (cid > 0) {
            try {
                model.Customer customer = customerDao.findById(cid);
                if (customer != null && customer.isActive()) {
                    info.put("customer", customer.toMap());
                } else {
                    info.put("customerAuthenticated", false);
                }
            } catch (Exception e) {
                info.put("customerAuthenticated", false);
            }
        }
        return info;
    }

    private String role(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object role = session == null ? null : session.getAttribute(tabAttr(req, ATTR_ROLE));
        return role == null ? "" : String.valueOf(role);
    }

    // ── Phiên đăng nhập của KHÁCH HÀNG ──────────────────────────────────
    // Tách hẳn khỏi ATTR_ROLE của nhân viên. Một khách đăng nhập vẫn có
    // role rỗng, nên toàn bộ phân quyền nhân viên hiện có không bị ảnh hưởng.

    private int customerId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return 0;
        return readInt(session.getAttribute(tabAttr(req, ATTR_CUSTOMER_ID)), 0);
    }

    private model.Customer currentCustomer(HttpServletRequest req) throws Exception {
        int id = customerId(req);
        if (id <= 0) return null;
        model.Customer customer = customerDao.findById(id);
        if (customer == null || !customer.isActive()) {
            // Tài khoản bị vô hiệu hoá giữa chừng: dọn phiên ngay.
            HttpSession session = req.getSession(false);
            if (session != null) session.removeAttribute(tabAttr(req, ATTR_CUSTOMER_ID));
            return null;
        }
        return customer;
    }

    private void startCustomerSession(HttpServletRequest req, model.Customer customer) {
        if (customer == null) return;
        HttpSession session = req.getSession(true);
        session.setAttribute(tabAttr(req, ATTR_CUSTOMER_ID), customer.getId());
    }

    /** Hồ sơ khách kèm quy tắc tích/đổi điểm để giao diện không hardcode con số. */
    private Map<String, Object> customerPayload(model.Customer customer) {
        Map<String, Object> payload = new LinkedHashMap<>(customer.toMap());
        Map<String, Object> rules = new LinkedHashMap<>();
        rules.put("spendPerPoint", model.Customer.SPEND_PER_POINT);
        rules.put("valuePerPoint", model.Customer.VALUE_PER_POINT);
        rules.put("minRedeemPoints", model.Customer.MIN_REDEEM_POINTS);
        rules.put("maxRedeemPercent", model.Customer.MAX_REDEEM_PERCENT);
        rules.put("silverThreshold", model.Customer.SILVER_THRESHOLD);
        rules.put("goldThreshold", model.Customer.GOLD_THRESHOLD);
        rules.put("tiers", model.Customer.tierGuide());
        payload.put("rules", rules);
        return payload;
    }

    /** Che số điện thoại trước khi ghi vào nhật ký hệ thống. */
    private String maskPhone(String phone) {
        String raw = str(phone);
        if (raw.length() < 5) return "***";
        return raw.substring(0, 3) + "****" + raw.substring(raw.length() - 2);
    }

    private String user(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object user = session == null ? null : session.getAttribute(tabAttr(req, ATTR_USER));
        return user == null ? "" : String.valueOf(user);
    }

    /** Nhân viên thật đang dùng tài khoản vị trí này (0 nếu không khai báo). */
    private int staffId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return 0;
        return readInt(session.getAttribute(tabAttr(req, ATTR_STAFF_ID)), 0);
    }

    private String staffName(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return "";
        return str(session.getAttribute(tabAttr(req, ATTR_STAFF_NAME)));
    }

    private String username(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return "";
        return str(session.getAttribute(tabAttr(req, ATTR_USERNAME)));
    }

    private String orderViewRole(HttpServletRequest req) {
        String currentRole = role(req);
        if (!"admin".equals(currentRole)) return currentRole;
        String view = str(req.getParameter("view"));
        if ("barista".equals(view) || "cashier".equals(view) || "runner".equals(view)) return view;
        return currentRole;
    }

    @SuppressWarnings("unchecked")
    private List<Integer> cashierPaidIds(HttpServletRequest req, boolean create) {
        if (!"cashier".equals(role(req))) return null;
        HttpSession session = req.getSession(create);
        if (session == null) return new ArrayList<>();
        Object value = session.getAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
        if (value instanceof List<?>) return (List<Integer>) value;
        List<Integer> ids = new ArrayList<>();
        session.setAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS), ids);
        return ids;
    }

    private void rememberPaidOrder(HttpServletRequest req, int orderId) {
        List<Integer> ids = cashierPaidIds(req, true);
        if (ids != null && orderId > 0 && !ids.contains(orderId)) ids.add(0, orderId);
    }

    private boolean canSetStatus(String role, String currentStatus, String nextStatus) {
        boolean baristaStep = ("Pending".equals(currentStatus) && "Preparing".equals(nextStatus))
                || ("Preparing".equals(currentStatus) && "Ready".equals(nextStatus));
        boolean cashierStep = "Served".equals(currentStatus) && "Paid".equals(nextStatus);
        boolean runnerStep = "Ready".equals(currentStatus) && "Served".equals(nextStatus);
        if ("admin".equals(role)) return baristaStep || cashierStep || runnerStep;
        if ("barista".equals(role)) return baristaStep;
        if ("cashier".equals(role)) return cashierStep;
        if ("runner".equals(role)) return runnerStep;
        return false;
    }

    @SuppressWarnings("unchecked")
    private void sanitizeRunnerOrder(Map<String, Object> order) {
        if (order == null) return;
        order.remove("total");
        order.remove("customerPhone");
        order.remove("subtotal");
        order.remove("discountAmount");
        order.remove("customerId");
        Object items = order.get("items");
        if (!(items instanceof Iterable<?>)) return;
        for (Object raw : (Iterable<?>) items) {
            if (raw instanceof Map<?, ?>) {
                ((Map<String, Object>) raw).remove("price");
            }
        }
    }

    private void handleSse(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String sseRole = role(req);
        if (sseRole.isEmpty()) {
            json(resp);
            error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Cần đăng nhập để nhận sự kiện realtime.");
            return;
        }
        resp.setContentType("text/event-stream");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        resp.setHeader("Connection", "keep-alive");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.flushBuffer();
        final jakarta.servlet.AsyncContext async = req.startAsync();
        async.setTimeout(0);
        final java.io.PrintWriter writer = resp.getWriter();
        final java.util.concurrent.atomic.AtomicBoolean open = new java.util.concurrent.atomic.AtomicBoolean(true);
        // Keep strong reference via wrapper that self-removes.
        java.util.function.Consumer<String> wrapped = new java.util.function.Consumer<String>() {
            @Override
            public void accept(String t) {
                if (!open.get()) {
                    service.removeEventListener(this);
                    return;
                }
                try {
                    synchronized (writer) {
                        writer.write("event: " + t + "\n");
                        writer.write("data: {\"type\":\"" + t + "\"}\n\n");
                        writer.flush();
                    }
                } catch (Exception e) {
                    open.set(false);
                    service.removeEventListener(this);
                    try { async.complete(); } catch (Exception ignored) {}
                }
            }
        };
        service.addEventListener(wrapped);
        try {
            synchronized (writer) {
                writer.write("event: connected\n");
                writer.write("data: {\"type\":\"connected\"}\n\n");
                writer.flush();
            }
        } catch (Exception ignored) {}
        async.addListener(new jakarta.servlet.AsyncListener() {
            @Override public void onComplete(jakarta.servlet.AsyncEvent event) {
                open.set(false);
                service.removeEventListener(wrapped);
            }
            @Override public void onTimeout(jakarta.servlet.AsyncEvent event) {
                open.set(false);
                service.removeEventListener(wrapped);
                try { async.complete(); } catch (Exception ignored) {}
            }
            @Override public void onError(jakarta.servlet.AsyncEvent event) {
                open.set(false);
                service.removeEventListener(wrapped);
            }
            @Override public void onStartAsync(jakarta.servlet.AsyncEvent event) {}
        });
    }

    private void json(HttpServletResponse resp) {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type,X-Tab-Session");
    }

    private String tabKey(HttpServletRequest req) {
        String key = str(req.getHeader("X-Tab-Session"));
        if (key.isEmpty()) key = str(req.getParameter("tabSession"));
        if (key.isEmpty()) key = "default";
        key = key.replaceAll("[^A-Za-z0-9_-]", "");
        if (key.isEmpty()) key = "default";
        return key.length() > 80 ? key.substring(0, 80) : key;
    }

    private String tabAttr(HttpServletRequest req, String base) {
        return base + "." + tabKey(req);
    }

    private void clearTabSession(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return;
        session.removeAttribute(tabAttr(req, ATTR_ROLE));
        session.removeAttribute(tabAttr(req, ATTR_USER));
        session.removeAttribute(tabAttr(req, ATTR_USERNAME));
        session.removeAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
        session.removeAttribute(tabAttr(req, ATTR_STAFF_ID));
        session.removeAttribute(tabAttr(req, ATTR_STAFF_NAME));
    }

    private void writeTableQr(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String code = str(req.getParameter("code"));
        Map<String, Object> table = service.getTableByCode(code);
        if (table == null) {
            json(resp);
            error(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy bàn.");
            return;
        }
        String base = str(req.getParameter("base"));
        if (base.isEmpty()) base = publicBase(req);
        base = base.replaceAll("/+$", "");
        String url = base + "/menu.jsp?tableCode=" + URLEncoder.encode(code, StandardCharsets.UTF_8);
        int size = Math.max(180, Math.min(960, readInt(req.getParameter("size"), 360)));
        String svg = qrSvg(url, size);

        resp.setContentType("image/svg+xml");
        resp.setCharacterEncoding("UTF-8");
        String filename = "qr-" + sanitizeFileName(String.valueOf(table.get("name"))) + ".svg";
        if ("1".equals(req.getParameter("download"))) {
            resp.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        } else {
            resp.setHeader("Content-Disposition", "inline; filename=\"" + filename + "\"");
        }
        resp.getWriter().write(svg);
    }

    private void writeMenuImportTemplate(HttpServletResponse resp) throws Exception {
        byte[] bytes = ExcelUtils.buildTemplate();
        resp.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        resp.setHeader("Content-Disposition", "attachment; filename=\"mau-import-thuc-don.xlsx\"");
        resp.setContentLength(bytes.length);
        resp.getOutputStream().write(bytes);
        resp.getOutputStream().flush();
    }

    private Map<String, Object> handleMenuImport(HttpServletRequest req) throws Exception {
        Part filePart = req.getPart("file");
        if (filePart == null || filePart.getSize() == 0) {
            throw new IllegalArgumentException("Vui lòng chọn file Excel để import.");
        }
        List<Map<String, Object>> rows;
        try (InputStream in = filePart.getInputStream()) {
            rows = ExcelUtils.parseMenuRows(in);
        }
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy dòng dữ liệu hợp lệ trong file. Vui lòng dùng file mẫu.");
        }
        return service.importMenuItems(rows);
    }

    private String qrSvg(String text, int size) throws Exception {
        EnumMap<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
        hints.put(EncodeHintType.MARGIN, 2);
        BitMatrix matrix = new QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size, hints);
        StringBuilder sb = new StringBuilder();
        sb.append("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 ")
                .append(matrix.getWidth()).append(' ').append(matrix.getHeight())
                .append("\" width=\"").append(size).append("\" height=\"").append(size)
                .append("\" shape-rendering=\"crispEdges\">");
        sb.append("<rect width=\"100%\" height=\"100%\" fill=\"#fffaf1\"/>");
        sb.append("<path fill=\"#241b10\" d=\"");
        for (int y = 0; y < matrix.getHeight(); y++) {
            for (int x = 0; x < matrix.getWidth(); x++) {
                if (matrix.get(x, y)) sb.append('M').append(x).append(' ').append(y).append("h1v1h-1z");
            }
        }
        sb.append("\"/></svg>");
        return sb.toString();
    }

    private String publicBase(HttpServletRequest req) {
        StringBuilder base = new StringBuilder();
        base.append(req.getScheme()).append("://").append(req.getServerName());
        int port = req.getServerPort();
        if (("http".equals(req.getScheme()) && port != 80) || ("https".equals(req.getScheme()) && port != 443)) {
            base.append(':').append(port);
        }
        base.append(req.getContextPath());
        return base.toString();
    }

    private String sanitizeFileName(String value) {
        String clean = value == null ? "table" : value.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        clean = clean.replaceAll("^-+|-+$", "");
        return clean.isEmpty() ? "table" : clean;
    }

    private void error(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.getWriter().write(JsonUtils.toJson(Map.of("error", message == null ? "Error" : message)));
    }

    private String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
        }
        return sb.toString();
    }

    private String str(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private int readInt(Object value, int fallback) {
        if (value instanceof Number) return ((Number) value).intValue();
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception e) {
            return fallback;
        }
    }

    private Integer parseNonNegativeInt(Object value, String fieldLabel) {
        if (value == null) {
            throw new IllegalArgumentException(fieldLabel + " không được để trống.");
        }
        int parsed;
        if (value instanceof Number) {
            parsed = ((Number) value).intValue();
            if (value instanceof Double || value instanceof Float) {
                double raw = ((Number) value).doubleValue();
                if (raw != Math.rint(raw)) {
                    throw new IllegalArgumentException(fieldLabel + " phải là số nguyên không âm.");
                }
            }
        } else {
            String text = String.valueOf(value).trim();
            if (text.isEmpty()) {
                throw new IllegalArgumentException(fieldLabel + " không được để trống.");
            }
            try {
                parsed = Integer.parseInt(text);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(fieldLabel + " phải là số nguyên không âm.");
            }
        }
        if (parsed < 0) {
            throw new IllegalArgumentException(fieldLabel + " không được âm.");
        }
        return parsed;
    }

    private String validateIngredientFields(String id, String name, String unit) {
        if (id == null || id.trim().isEmpty()) {
            return "Mã nguyên liệu không được để trống.";
        }
        String cleanId = id.trim();
        if (cleanId.length() < 2 || cleanId.length() > 50) {
            return "Mã nguyên liệu phải từ 2 đến 50 ký tự.";
        }
        if (!cleanId.matches("[A-Za-z0-9_-]+")) {
            return "Mã nguyên liệu chỉ gồm chữ, số, gạch dưới hoặc gạch ngang.";
        }
        if (name == null || name.trim().isEmpty()) {
            return "Tên nguyên liệu không được để trống.";
        }
        if (name.trim().length() < 2 || name.trim().length() > 120) {
            return "Tên nguyên liệu phải từ 2 đến 120 ký tự.";
        }
        if (unit == null || unit.trim().isEmpty()) {
            return "Đơn vị không được để trống.";
        }
        if (unit.trim().length() > 20) {
            return "Đơn vị tối đa 20 ký tự.";
        }
        return null;
    }

    private List<Map<String, Object>> splitSelections(Object raw) {
        List<Map<String, Object>> selections = new ArrayList<>();
        if (raw instanceof Iterable<?>) {
            for (Object entry : (Iterable<?>) raw) {
                if (!(entry instanceof Map<?, ?>)) continue;
                Map<?, ?> item = (Map<?, ?>) entry;
                Map<String, Object> selection = new LinkedHashMap<>();
                selection.put("id", readInt(item.get("id"), 0));
                selection.put("quantity", readInt(item.get("quantity"), 0));
                selections.add(selection);
            }
        }
        return selections;
    }

    private long readLong(Object value, long fallback) {
        if (value instanceof Number) return ((Number) value).longValue();
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (Exception e) {
            return fallback;
        }
    }
}
