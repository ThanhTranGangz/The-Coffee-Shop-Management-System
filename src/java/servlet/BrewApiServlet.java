package servlet;

import context.AppContext;
import model.*;
import service.BrewStateService;
import utils.JsonUtils;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Main API servlet for handling coffee shop operations such as menu, orders, tables, and inventory.
 */
public class BrewApiServlet extends HttpServlet {
    private static final String BANK_WEBHOOK_TOKEN = "bank-webhook-token";
    private BrewStateService stateService;

    /**
     * Initializes the servlet and retrieves the state service.
     * 
     * @throws ServletException if initialization fails
     */
    @Override
    public void init() throws ServletException {
        // Retrieve singleton business service
        this.stateService = AppContext.getInstance().getStateService();
    }

    private void setJsonHeaders(HttpServletResponse resp) {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        // Assist testing and local setup integrations with CORS headers
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type, X-Bank-Webhook-Token");
    }

    /**
     * Handles CORS preflight requests.
     */
    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        resp.setStatus(HttpServletResponse.SC_OK);
    }

    /**
     * Handles GET requests to retrieve various data entities like menu, tables, orders, etc.
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        String pathInfo = req.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"Missing resource route specification.\"}");
            return;
        }

        switch (pathInfo) {
            case "/menu":
                resp.getWriter().write(JsonUtils.toJson(stateService.getMenu()));
                break;

            case "/tables":
                resp.getWriter().write(JsonUtils.toJson(stateService.getTables()));
                break;
            case "/orders":
                resp.getWriter().write(JsonUtils.toJson(stateService.getOrders()));
                break;
            case "/orders/lookup":
                Order foundOrder = null;
                String orderId = req.getParameter("id");
                String orderNumber = req.getParameter("orderNumber");
                if (orderId != null && !orderId.trim().isEmpty()) {
                    foundOrder = stateService.getOrderById(orderId.trim());
                }
                if (foundOrder == null && orderNumber != null && !orderNumber.trim().isEmpty()) {
                    try {
                        String cleanOrderNumber = orderNumber.trim().replace("#", "");
                        foundOrder = stateService.getOrderByNumber(Integer.parseInt(cleanOrderNumber));
                    } catch (NumberFormatException ignored) {
                        foundOrder = null;
                    }
                }
                if (foundOrder != null) {
                    resp.getWriter().write(JsonUtils.toJson(foundOrder));
                } else {
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    resp.getWriter().write("{\"error\": \"Không tìm thấy đơn theo mã đã nhập.\"}");
                }
                break;
            case "/inventory":
                resp.getWriter().write(JsonUtils.toJson(stateService.getInventory()));
                break;
            case "/inventory/expenses":
                resp.getWriter().write(JsonUtils.toJson(stateService.getExpenses()));
                break;
            case "/staff":
                resp.getWriter().write(JsonUtils.toJson(stateService.getStaff()));
                break;
            case "/shifts":
                resp.getWriter().write(JsonUtils.toJson(stateService.getShifts()));
                break;

            case "/reports/historical":
                resp.getWriter().write(JsonUtils.toJson(stateService.getHistoricalReports()));
                break;
            case "/shop/status":
                resp.getWriter().write("{\"closed\": " + stateService.isShopClosed() + ", \"timeLimitUnlocked\": " + stateService.isTimeLimitUnlocked() + "}");
                break;
            case "/pos/shift":
                resp.getWriter().write(JsonUtils.toJson(stateService.getPosShiftSnapshot()));
                break;
            default:
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
                break;
        }
    }

    /**
     * Handles POST requests to create or modify data entities.
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        String pathInfo = req.getPathInfo();

        if (pathInfo == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"Missing POST action route.\"}");
            return;
        }

        String body = readBody(req);
        
        try {
            if (pathInfo.equals("/menu")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String name = (String) reqMap.get("name");
                String category = (String) reqMap.getOrDefault("category", "Specialty");
                String description = (String) reqMap.getOrDefault("description", "");
                String image = (String) reqMap.getOrDefault("image", "");
                int price = readInt(reqMap.get("price"), 0);
                List<String> sizes = readStringList(reqMap.get("availableSizes"));

                MenuItem createdMenuItem = stateService.createMenuItem(name, category, price, description, sizes, image);
                resp.setStatus(HttpServletResponse.SC_CREATED);
                resp.getWriter().write(JsonUtils.toJson(createdMenuItem));

            } else if (pathInfo.equals("/menu/delete")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String id = (String) reqMap.get("id");
                stateService.deleteMenuItem(id);
                resp.getWriter().write("{\"message\": \"Menu item deleted.\"}");


            } else if (pathInfo.equals("/orders")) {
                int currentHour = java.time.LocalTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).getHour();
                boolean outsideOrderingHours = currentHour >= 22 || currentHour < 6;
                if (stateService.isShopClosed() || (!stateService.isTimeLimitUnlocked() && outsideOrderingHours)) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Quầy đang tạm đóng cửa nhận đơn (Hệ thống ngắt sau 22:00 tối hoặc ngưng nhận bởi quản lý).\"}");
                    return;
                }

                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String tableId = (String) reqMap.get("tableId");
                String tableCode = (String) reqMap.get("tableCode");
                List<Map<String, Object>> items = (List<Map<String, Object>>) reqMap.get("items");
                String notes = (String) reqMap.getOrDefault("notes", "");


                if ((tableId == null || tableId.trim().isEmpty()) && tableCode != null) {
                    Table codedTable = stateService.getTableByCode(tableCode);
                    if (codedTable != null) {
                        tableId = codedTable.getId();
                    }
                }

                if (tableId == null || items == null || items.isEmpty()) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Invalid order payload: 'tableId' and 'items' are required.\"}");
                    return;
                }

                int discountAmount = 0;
                String orderNotes = notes == null ? "" : notes;
                Order newOrder = stateService.placeOrder(tableId, items, orderNotes, discountAmount);
                resp.setStatus(HttpServletResponse.SC_CREATED);
                resp.getWriter().write(JsonUtils.toJson(newOrder));

            } else if (pathInfo.equals("/pos/shift/open")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String cashierName = (String) reqMap.getOrDefault("cashierName", getSessionUser(req));
                int openingCash = readInt(reqMap.get("openingCash"), 0);
                resp.getWriter().write(JsonUtils.toJson(stateService.openPosShift(cashierName, openingCash)));

            } else if (pathInfo.equals("/pos/shift/close")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                int closingCash = readInt(reqMap.get("closingCash"), 0);
                String notes = (String) reqMap.getOrDefault("notes", "");
                resp.getWriter().write(JsonUtils.toJson(stateService.closePosShift(closingCash, notes)));

            } else if (pathInfo.equals("/payments/confirm")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String orderId = (String) reqMap.get("orderId");
                String method = (String) reqMap.getOrDefault("method", "Cash");
                int amount = readInt(reqMap.get("amount"), 0);
                String reference = (String) reqMap.getOrDefault("reference", "");
                if (orderId == null || orderId.trim().isEmpty()) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Thiếu mã đơn cần thanh toán.\"}");
                    return;
                }
                resp.getWriter().write(JsonUtils.toJson(stateService.confirmPayment(orderId.trim(), method, amount, reference, getSessionUser(req))));

            } else if (pathInfo.equals("/payments/webhook")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String token = req.getHeader("X-Bank-Webhook-Token");
                if (token == null || token.trim().isEmpty()) {
                    token = (String) reqMap.get("token");
                }
                if (!BANK_WEBHOOK_TOKEN.equals(token)) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    resp.getWriter().write("{\"error\": \"Webhook thanh toán thiếu hoặc sai token xác thực.\"}");
                    return;
                }
                String orderId = (String) reqMap.get("orderId");
                int amount = readInt(reqMap.get("amount"), 0);
                String reference = (String) reqMap.getOrDefault("reference", "");
                String bankTrace = (String) reqMap.getOrDefault("bankTrace", "");
                resp.getWriter().write(JsonUtils.toJson(stateService.handleBankWebhook(orderId, amount, reference, bankTrace)));

            } else if (pathInfo.startsWith("/orders/") && pathInfo.endsWith("/split-bill")) {
                String[] parts = pathInfo.split("/");
                if (parts.length >= 3) {
                    Map<String, Object> reqMap = JsonUtils.parseObject(body);
                    int splitParts = readInt(reqMap.get("parts"), 2);
                    resp.getWriter().write(JsonUtils.toJson(stateService.splitBill(parts[2], splitParts)));
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted split-bill endpoint.\"}");
                }

            } else if (pathInfo.equals("/tables")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String tableName = (String) reqMap.get("name");
                String tableZone = (String) reqMap.getOrDefault("zone", "Ground Floor");
                int capacity = readInt(reqMap.get("capacity"), 4);

                if (tableName == null || tableName.trim().isEmpty()) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Tên bàn không được để trống.\"}");
                    return;
                }

                Table createdTable = stateService.createTable(tableName.trim(), tableZone, capacity);
                resp.setStatus(HttpServletResponse.SC_CREATED);
                resp.getWriter().write(JsonUtils.toJson(createdTable));

            } else if (pathInfo.equals("/tables/move")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String sourceTableId = (String) reqMap.get("sourceTableId");
                String targetTableId = (String) reqMap.get("targetTableId");

                if (sourceTableId == null || targetTableId == null) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Missing 'sourceTableId' or 'targetTableId'.\"}");
                    return;
                }

                stateService.moveTable(sourceTableId, targetTableId);
                resp.getWriter().write("{\"message\": \"Table moved successfully.\"}");

            } else if (pathInfo.equals("/tables/merge")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String sourceTableId = (String) reqMap.get("sourceTableId");
                String targetTableId = (String) reqMap.get("targetTableId");

                if (sourceTableId == null || targetTableId == null) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Missing 'sourceTableId' or 'targetTableId'.\"}");
                    return;
                }

                stateService.mergeTables(sourceTableId, targetTableId);
                resp.getWriter().write("{\"message\": \"Tables merged successfully.\"}");

            } else if (pathInfo.startsWith("/tables/") && pathInfo.endsWith("/checkout")) {
                // Route format: /tables/{tableId}/checkout
                String[] parts = pathInfo.split("/");
                if (parts.length >= 3) {
                    String tableId = parts[2];
                    Order checkedOrder = stateService.checkoutTable(tableId);
                    if (checkedOrder != null) {
                        resp.getWriter().write("{\"message\": \"Table check out completed\", \"order\":" + JsonUtils.toJson(checkedOrder) + "}");
                    } else {
                        resp.getWriter().write("{\"message\": \"Table is already check out or empty\"}");
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted checkout endpoint.\"}");
                }
            } else if (pathInfo.startsWith("/tables/") && pathInfo.endsWith("/confirm-served")) {
                String[] parts = pathInfo.split("/");
                if (parts.length >= 3) {
                    Table table = stateService.confirmTableServed(parts[2]);
                    resp.getWriter().write(JsonUtils.toJson(table));
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted confirm-served endpoint.\"}");
                }
            } else if (pathInfo.startsWith("/tables/") && pathInfo.endsWith("/clean")) {
                String[] parts = pathInfo.split("/");
                if (parts.length >= 3) {
                    Table table = stateService.cleanTable(parts[2]);
                    resp.getWriter().write(JsonUtils.toJson(table));
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted clean endpoint.\"}");
                }
            } else if (pathInfo.equals("/inventory/import")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                List<Map<String, Object>> imports = (List<Map<String, Object>>) reqMap.get("imports");

                if (imports == null) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Dữ liệu nhập kho không hợp lệ!\"}");
                    return;
                }

                Map<String, Object> importResult = stateService.importInventory(imports);
                resp.getWriter().write(JsonUtils.toJson(importResult));
            } else if (pathInfo.equals("/staff")) {
                Map<String, Object> sMap = JsonUtils.parseObject(body);
                int id = 0;
                if (sMap.containsKey("id") && sMap.get("id") != null) {
                    id = ((Number) sMap.get("id")).intValue();
                }
                if (id == 0) {
                    id = (int) (System.currentTimeMillis() & 0xfffffff);
                }
                String name = (String) sMap.get("name");
                String role = (String) sMap.get("role");
                String pin = (String) sMap.get("pin");
                String shift = (String) sMap.get("shift");
                boolean active = sMap.get("active") != null ? (Boolean) sMap.get("active") : true;
                                String password = (String) sMap.get("password");
                String status = sMap.containsKey("status") && sMap.get("status") != null ? (String) sMap.get("status") : "Active";
                boolean overtime = sMap.containsKey("overtime") && sMap.get("overtime") != null ? (Boolean) sMap.get("overtime") : false;

                // Restrict manager modifications
                List<Staff> roster = stateService.getStaff();
                boolean isExistingManager = false;
                for (Staff existing : roster) {
                    if (existing.getId() == id && true) {
                        isExistingManager = true;
                        break;
                    }
                }

                if (isExistingManager) {
                    role = "manager";
                    active = true;
                    status = "Active";
                } else if ("manager".equalsIgnoreCase(role)) {
                    role = "waiter"; // Prevent duplicate manager creation
                }

                Staff staff = new Staff(id, name, active, status);
                stateService.saveStaff(staff);
                resp.getWriter().write(JsonUtils.toJson(staff));
            } else if (pathInfo.equals("/staff/delete")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                int id = ((Number) reqMap.get("id")).intValue();
                
                // Block manager deletion
                List<Staff> roster = stateService.getStaff();
                boolean isManager = false;
                for (Staff existing : roster) {
                    if (existing.getId() == id && true) {
                        isManager = true;
                        break;
                    }
                }
                
                if (isManager) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    resp.getWriter().write("{\"error\": \"Cannot delete system manager!\"}");
                    return;
                }

                stateService.deleteStaff(id);
                resp.getWriter().write("{\"message\": \"Staff deleted successfully.\"}");
            } else if (pathInfo.equals("/shifts")) {
                Map<String, Object> shiftData = JsonUtils.parseObject(body);
                String id = (String) shiftData.get("id");
                int staffId = readInt(shiftData.get("staffId"), 0);
                String shiftDate = (String) shiftData.get("shiftDate");
                String shiftName = (String) shiftData.get("shiftName");
                String hours = (String) shiftData.get("hours");
                String status = (String) shiftData.getOrDefault("status", "Hoạt động");
                String notes = (String) shiftData.getOrDefault("notes", "");

                if (id == null || id.trim().isEmpty()) {
                    id = "shift-" + UUID.randomUUID().toString().substring(0, 8);
                }
                if (staffId <= 0 || shiftDate == null || shiftName == null || hours == null) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Dữ liệu ca trực không hợp lệ.\"}");
                    return;
                }

                Staff selectedStaff = null;
                for (Staff s : stateService.getStaff()) {
                    if (s.getId() == staffId) {
                        selectedStaff = s;
                        break;
                    }
                }
                if (selectedStaff == null) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Nhân sự được chọn không tồn tại.\"}");
                    return;
                }

                Shift shift = new Shift(id, staffId, selectedStaff.getName(), shiftDate, shiftName, hours, status, notes);
                stateService.saveShift(shift);
                resp.getWriter().write(JsonUtils.toJson(shift));
            } else if (pathInfo.equals("/shifts/delete")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String id = (String) reqMap.get("id");
                if (id == null || id.trim().isEmpty()) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Missing shift id.\"}");
                    return;
                }
                stateService.deleteShift(id);
                resp.getWriter().write("{\"message\": \"Shift deleted successfully.\"}");

            } else if (pathInfo.equals("/shop/toggle")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                boolean closed = (Boolean) reqMap.get("closed");
                stateService.setShopClosed(closed);
                resp.getWriter().write("{\"closed\":" + closed + ",\"timeLimitUnlocked\":" + stateService.isTimeLimitUnlocked() + "}");
            } else if (pathInfo.equals("/shop/time-limit")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                boolean unlocked = reqMap.get("unlocked") instanceof Boolean ? (Boolean) reqMap.get("unlocked") : false;
                stateService.setTimeLimitUnlocked(unlocked);
                resp.getWriter().write("{\"closed\":" + stateService.isShopClosed() + ",\"timeLimitUnlocked\":" + unlocked + "}");
            } else {
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
            }
        } catch (IllegalArgumentException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        } catch (IllegalStateException e) {
            resp.setStatus(HttpServletResponse.SC_CONFLICT);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    /**
     * Handles PUT requests to update existing data entities.
     */
    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        String pathInfo = req.getPathInfo();

        if (pathInfo == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"Missing PUT action route.\"}");
            return;
        }

        String body = readBody(req);
        Map<String, Object> reqMap = JsonUtils.parseObject(body);

        try {
            if (pathInfo.startsWith("/menu/")) {
                String[] parts = pathInfo.split("/");
                if (parts.length >= 3) {
                    String id = parts[2];
                    String name = (String) reqMap.get("name");
                    String category = (String) reqMap.getOrDefault("category", "Specialty");
                    String description = (String) reqMap.getOrDefault("description", "");
                    String image = (String) reqMap.getOrDefault("image", "");
                    int price = readInt(reqMap.get("price"), 0);
                    List<String> sizes = readStringList(reqMap.get("availableSizes"));
                    MenuItem updated = stateService.updateMenuItem(id, name, category, price, description, sizes, image);
                    resp.getWriter().write(JsonUtils.toJson(updated));
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted menu endpoint.\"}");
                }
            } else if (pathInfo.startsWith("/orders/") && pathInfo.contains("/items/")) {
                // Route format: /orders/{orderId}/items/{itemId}
                String[] parts = pathInfo.split("/");
                if (parts.length >= 5) {
                    String status = (String) reqMap.get("status");
                    if (status == null) {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        resp.getWriter().write("{\"error\": \"Missing required 'status' property in body.\"}");
                        return;
                    }
                    String orderId = parts[2];
                    String itemId = parts[4];
                    stateService.updateItemStatus(orderId, itemId, status);
                    resp.getWriter().write("{\"message\": \"Order item status updated to " + status + ".\"}");
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted items status endpoint.\"}");
                }
            } else if (pathInfo.startsWith("/orders/") && pathInfo.endsWith("/status")) {
                // Route format: /orders/{orderId}/status
                String[] parts = pathInfo.split("/");
                if (parts.length >= 4) {
                    String status = (String) reqMap.get("status");
                    if (status == null) {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        resp.getWriter().write("{\"error\": \"Missing required 'status' property in body.\"}");
                        return;
                    }
                    String orderId = parts[2];
                    stateService.updateOrderStatus(orderId, status);
                    resp.getWriter().write("{\"message\": \"Order overall status updated to " + status + ".\"}");
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Malformatted order status endpoint.\"}");
                }
            } else {
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
            }
        } catch (IllegalArgumentException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        } catch (IllegalStateException e) {
            resp.setStatus(HttpServletResponse.SC_CONFLICT);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        return sb.toString();
    }

    private String escapeJson(String s) {
        if (s == null) return "error";
        return s.replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
    }

    private int readInt(Object value, int fallback) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value instanceof String) {
            try {
                return Integer.parseInt(((String) value).trim());
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    private boolean readBoolean(Object value, boolean fallback) {
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        if (value instanceof String) {
            return Boolean.parseBoolean(((String) value).trim());
        }
        return fallback;
    }

    private List<String> readStringList(Object value) {
        if (value instanceof List<?>) {
            List<String> result = new java.util.ArrayList<>();
            for (Object item : (List<?>) value) {
                if (item != null && !String.valueOf(item).trim().isEmpty()) {
                    result.add(String.valueOf(item).trim());
                }
            }
            return result;
        }
        if (value instanceof String) {
            List<String> result = new java.util.ArrayList<>();
            String[] parts = ((String) value).split(",");
            for (String part : parts) {
                if (!part.trim().isEmpty()) {
                    result.add(part.trim());
                }
            }
            return result;
        }
        return java.util.Collections.emptyList();
    }

    private String getSessionUser(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object user = session != null ? session.getAttribute("auth_user") : null;
        return user == null ? "POS" : String.valueOf(user);
    }
}
