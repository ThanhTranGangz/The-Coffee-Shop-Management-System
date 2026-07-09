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
import java.util.List;
import java.util.Map;

public class LiteApiServlet extends HttpServlet {
    private final LiteService service = LiteService.getInstance();
    private static final long DUPLICATE_ORDER_WINDOW_MS = 5000;
    private static final String ATTR_GUEST_TABLE_NAME = "guestTableName";
    private static final String ATTR_GUEST_TABLE_CODE = "guestTableCode";
    private static final String ATTR_GUEST_ORDER_IDS = "guestOrderIds";
    private static final String ATTR_LAST_GUEST_ORDER_SIGNATURE = "lastGuestOrderSignature";
    private static final String ATTR_LAST_GUEST_ORDER_AT = "lastGuestOrderAt";
    private static final String ATTR_LAST_GUEST_ORDER_ID = "lastGuestOrderId";
    private static final String ATTR_ROLE = "role";
    private static final String ATTR_USER = "user";
    private static final String ATTR_PAID_ORDER_IDS = "paidOrderIds";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo() == null ? "/" : req.getPathInfo();
        try {
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
                case "/menu":
                    boolean admin = "admin".equals(role(req));
                    resp.getWriter().write(JsonUtils.toJson(service.getMenu(admin)));
                    break;
                case "/inventory":
                    java.util.List<java.util.Map<String, Object>> invList = new dao.InventoryDAO().getAll().stream().map(i -> i.toMap()).collect(java.util.stream.Collectors.toList());
                    resp.getWriter().write(JsonUtils.toJson(invList));
                    break;
                case "/tables":
                    resp.getWriter().write(JsonUtils.toJson(service.getTables()));
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
                        lockGuestTable(req, table);
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
                    } else if (role(req).isEmpty() && !guestOrderIds(req, false).contains(readInt(order.get("id"), 0))) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ xem được đơn của phiên gọi món hiện tại.");
                    } else {
                        resp.getWriter().write(JsonUtils.toJson(order));
                    }
                    break;
                case "/orders/table":
                    if (role(req).isEmpty()) {
                        resp.getWriter().write(JsonUtils.toJson(guestTableOrders(req)));
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
                    Map<String, Object> user = service.login(str(body.get("username")), str(body.get("password")));
                    if (user == null) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Sai tài khoản hoặc mật khẩu.");
                    } else {
                        HttpSession session = req.getSession(true);
                        session.setAttribute(tabAttr(req, ATTR_ROLE), user.get("role"));
                        session.setAttribute(tabAttr(req, ATTR_USER), user.get("fullName"));
                        if ("cashier".equals(user.get("role"))) {
                            session.setAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS), new ArrayList<Integer>());
                        } else {
                            session.removeAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
                        }
                        service.addSystemLog(str(user.get("role")), str(user.get("fullName")), "LOGIN",
                                str(user.get("fullName")) + " đăng nhập lúc " + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy")),
                                str(user.get("fullName")) + " signed in at " + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy")),
                                null);
                        resp.getWriter().write(JsonUtils.toJson(user));
                    }
                    break;
                case "/auth/admin-pin":
                    if (!"8888".equals(str(body.get("pin")))) {
                        error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Sai mã PIN quản trị.");
                        return;
                    }
                    HttpSession adminSession = req.getSession(true);
                    adminSession.setAttribute(tabAttr(req, ATTR_ROLE), "admin");
                    adminSession.setAttribute(tabAttr(req, ATTR_USER), "Quản trị coffeshop");
                    adminSession.removeAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
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
                        resp.getWriter().write(JsonUtils.toJson(service.createOrder(body)));
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
                    Map<String, Object> updatedOrder = service.updateOrderStatus(orderId, status, currentRole, user(req));
                    if ("cashier".equals(currentRole) && "Paid".equals(status)) {
                        rememberPaidOrder(req, orderId);
                    }
                    if ("runner".equals(currentRole)) sanitizeRunnerOrder(updatedOrder);
                    resp.getWriter().write(JsonUtils.toJson(updatedOrder));
                    break;
                case "/orders/split":
                    String splitRole = role(req);
                    if (!"cashier".equals(splitRole) && !"admin".equals(splitRole)) {
                        error(resp, HttpServletResponse.SC_FORBIDDEN, "Chỉ thu ngân hoặc admin được tách đơn.");
                        return;
                    }
                    Map<String, Object> splitResult = service.splitOrder(readInt(body.get("id"), 0), splitSelections(body.get("items")), splitRole, user(req));
                    resp.getWriter().write(JsonUtils.toJson(splitResult));
                    break;
                case "/menu":
                    Map<String, Object> savedMenu = service.saveMenuItem(body);
                    service.addSystemLog(role(req), user(req), "MENU_SAVE",
                            "Admin lưu món " + str(savedMenu.get("nameVi")), "Admin saved menu item " + str(savedMenu.get("nameEn")), readInt(savedMenu.get("id"), 0));
                    resp.getWriter().write(JsonUtils.toJson(savedMenu));
                    break;
                case "/menu/delete":
                    service.deleteMenuItem(readInt(body.get("id"), 0));
                    service.addSystemLog(role(req), user(req), "MENU_DELETE",
                            "Admin xoá/ẩn món #" + readInt(body.get("id"), 0), "Admin deleted/hidden menu item #" + readInt(body.get("id"), 0), readInt(body.get("id"), 0));
                    resp.getWriter().write("{\"message\":\"Menu item deleted\"}");
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
        List<Integer> orderIds = guestOrderIds(req, false);
        String activeTableName = service.currentTableForOrderIds(orderIds);
        Map<String, Object> table;
        if (!activeTableName.isEmpty()) {
            table = service.getTableByName(activeTableName);
        } else {
            table = lockedGuestTable(req);
            Map<String, Object> requested = requestedTable(body.get("tableCode"), body.get("tableName"));
            if (table != null && requested != null && !str(table.get("name")).equals(str(requested.get("name")))) {
                throw new IllegalArgumentException("Bàn đã được cố định theo QR đang sử dụng.");
            }
            if (table == null) table = requested;
        }
        if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");

        body.put("tableName", str(table.get("name")));
        body.put("tableCode", str(table.get("code")));
        lockGuestTable(req, table);

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

        Map<String, Object> order = service.createOrder(body);
        int orderId = readInt(order.get("id"), 0);
        rememberGuestOrder(req, orderId);
        session.setAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_SIGNATURE), signature);
        session.setAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_AT), now);
        session.setAttribute(tabAttr(req, ATTR_LAST_GUEST_ORDER_ID), orderId);
        return order;
    }

    private List<Map<String, Object>> guestTableOrders(HttpServletRequest req) throws Exception {
        List<Integer> orderIds = guestOrderIds(req, false);
        if (!orderIds.isEmpty()) {
            List<Map<String, Object>> orders = service.getOpenOrdersByIds(orderIds);
            rememberGuestTableFromOrders(req, orders);
            return orders;
        }

        Map<String, Object> requested = requestedTable(req.getParameter("tableCode"), req.getParameter("table"));
        if (requested != null) {
            ensureGuestTableMatches(req, requested);
        }
        return new ArrayList<>();
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

    private void ensureGuestTableMatches(HttpServletRequest req, Map<String, Object> table) throws Exception {
        Map<String, Object> locked = lockedGuestTable(req);
        if (locked != null && !str(locked.get("name")).equals(str(table.get("name")))) {
            throw new IllegalArgumentException("Bàn đã được cố định theo QR đang sử dụng.");
        }
        lockGuestTable(req, table);
    }

    private void lockGuestTable(HttpServletRequest req, Map<String, Object> table) {
        if (!role(req).isEmpty() || table == null) return;
        HttpSession session = req.getSession(true);
        session.setAttribute(tabAttr(req, ATTR_GUEST_TABLE_NAME), str(table.get("name")));
        session.setAttribute(tabAttr(req, ATTR_GUEST_TABLE_CODE), str(table.get("code")));
    }

    private Map<String, Object> lockedGuestTable(HttpServletRequest req) throws Exception {
        if (!role(req).isEmpty()) return null;
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        String name = str(session.getAttribute(tabAttr(req, ATTR_GUEST_TABLE_NAME)));
        if (name.isEmpty()) return null;
        return service.getTableByName(name);
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
        return info;
    }

    private String role(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object role = session == null ? null : session.getAttribute(tabAttr(req, ATTR_ROLE));
        return role == null ? "" : String.valueOf(role);
    }

    private String user(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object user = session == null ? null : session.getAttribute(tabAttr(req, ATTR_USER));
        return user == null ? "" : String.valueOf(user);
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
        Object items = order.get("items");
        if (!(items instanceof Iterable<?>)) return;
        for (Object raw : (Iterable<?>) items) {
            if (raw instanceof Map<?, ?>) {
                ((Map<String, Object>) raw).remove("price");
            }
        }
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
        session.removeAttribute(tabAttr(req, ATTR_PAID_ORDER_IDS));
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
