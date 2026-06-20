package servlet;

import context.AppContext;
import model.*;
import service.BrewStateService;
import utils.JsonUtils;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public class BrewApiServlet extends HttpServlet {
    private BrewStateService stateService;

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
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type");
    }

    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        resp.setStatus(HttpServletResponse.SC_OK);
    }

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
            case "/inventory":
                resp.getWriter().write(JsonUtils.toJson(stateService.getInventory()));
                break;
            case "/inventory/expenses":
                resp.getWriter().write(JsonUtils.toJson(stateService.getExpenses()));
                break;
            case "/staff":
                resp.getWriter().write(JsonUtils.toJson(stateService.getStaff()));
                break;
            case "/members":
                resp.getWriter().write(JsonUtils.toJson(stateService.getMembers()));
                break;
            case "/members/profile":
                String phone = req.getParameter("phone");
                if (phone != null) {
                    Member m = stateService.getMemberByPhone(phone);
                    if (m != null) {
                        resp.getWriter().write(JsonUtils.toJson(m));
                    } else {
                        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                        resp.getWriter().write("{\"error\": \"Không tìm thấy thành viên!\"}");
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Missing phone parameter.\"}");
                }
                break;
            case "/reports/historical":
                resp.getWriter().write(JsonUtils.toJson(stateService.getHistoricalReports()));
                break;
            case "/shop/status":
                resp.getWriter().write("{\"closed\": " + stateService.isShopClosed() + "}");
                break;
            default:
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
                break;
        }
    }

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
            if (pathInfo.equals("/orders")) {
                int currentHour = java.time.LocalTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).getHour();
                if (stateService.isShopClosed() || currentHour >= 22 || currentHour < 6) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Quầy đang tạm đóng cửa nhận đơn (Hệ thống ngắt sau 22:00 tối hoặc ngưng nhận bởi quản lý).\"}");
                    return;
                }

                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String tableId = (String) reqMap.get("tableId");
                List<Map<String, Object>> items = (List<Map<String, Object>>) reqMap.get("items");
                String notes = (String) reqMap.getOrDefault("notes", "");

                if (tableId == null || items == null || items.isEmpty()) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Invalid order payload: 'tableId' and 'items' are required.\"}");
                    return;
                }

                Order newOrder = stateService.placeOrder(tableId, items, notes);
                resp.setStatus(HttpServletResponse.SC_CREATED);
                resp.getWriter().write(JsonUtils.toJson(newOrder));

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
                String username = (String) sMap.get("username");
                String password = (String) sMap.get("password");
                String status = sMap.containsKey("status") && sMap.get("status") != null ? (String) sMap.get("status") : "Active";
                boolean overtime = sMap.containsKey("overtime") && sMap.get("overtime") != null ? (Boolean) sMap.get("overtime") : false;

                // Restrict manager modifications
                List<Staff> roster = stateService.getStaff();
                boolean isExistingManager = false;
                for (Staff existing : roster) {
                    if (existing.getId() == id && "manager".equalsIgnoreCase(existing.getRole())) {
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

                Staff staff = new Staff(id, name, role, pin, shift, active, username, password, status, overtime);
                stateService.saveStaff(staff);
                resp.getWriter().write(JsonUtils.toJson(staff));
            } else if (pathInfo.equals("/staff/delete")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                int id = ((Number) reqMap.get("id")).intValue();
                
                // Block manager deletion
                List<Staff> roster = stateService.getStaff();
                boolean isManager = false;
                for (Staff existing : roster) {
                    if (existing.getId() == id && "manager".equalsIgnoreCase(existing.getRole())) {
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
            } else if (pathInfo.equals("/members")) {
                Map<String, Object> mData = JsonUtils.parseObject(body);
                String mPhone = (String) mData.get("phone");
                String mName = (String) mData.get("name");
                String mRank = (String) mData.getOrDefault("rank", "Silver");
                int mPoints = mData.containsKey("points") ? ((Number) mData.get("points")).intValue() : 50;
                String mEmail = (String) mData.getOrDefault("email", "");
                String mPref = (String) mData.getOrDefault("pref", "Espresso");
                String mDiscount = (String) mData.getOrDefault("discount", "Giảm 5% tổng hoá đơn");

                Member member = new Member(mPhone, mName, mRank, mPoints, mEmail, mPref, mDiscount);
                stateService.saveMember(member);
                resp.getWriter().write(JsonUtils.toJson(member));
            } else if (pathInfo.equals("/members/login")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String lPhone = (String) reqMap.get("phone");
                Member m = stateService.getMemberByPhone(lPhone);
                if (m != null) {
                    resp.getWriter().write(JsonUtils.toJson(m));
                } else {
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    resp.getWriter().write("{\"error\": \"Không tìm thấy thành viên!\"}");
                }
            } else if (pathInfo.equals("/members/register")) {
                Map<String, Object> mData = JsonUtils.parseObject(body);
                String mPhone = (String) mData.get("phone");
                String mName = (String) mData.get("name");
                String mEmail = (String) mData.getOrDefault("email", "");
                String mPref = (String) mData.getOrDefault("pref", "Espresso");

                Member existing = stateService.getMemberByPhone(mPhone);
                if (existing != null) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    resp.getWriter().write("{\"error\": \"Số điện thoại đã tồn tại!\"}");
                } else {
                    Member newM = new Member(mPhone, mName, "Silver", 50, mEmail, mPref, "Giảm 5% tổng hoá đơn");
                    stateService.saveMember(newM);
                    resp.getWriter().write(JsonUtils.toJson(newM));
                }
            } else if (pathInfo.equals("/members/redeem")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                String rPhone = (String) reqMap.get("phone");
                int cost = ((Number) reqMap.get("points")).intValue();
                String rDiscount = (String) reqMap.get("reward");
                Member rMember = stateService.getMemberByPhone(rPhone);
                if (rMember != null) {
                    if (rMember.getPoints() >= cost) {
                        rMember.setPoints(rMember.getPoints() - cost);
                        rMember.setDiscount(rDiscount);
                        stateService.saveMember(rMember);
                        resp.getWriter().write(JsonUtils.toJson(rMember));
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        resp.getWriter().write("{\"error\": \"Không đủ điểm (hạt cà phê) để đổi!\"}");
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    resp.getWriter().write("{\"error\": \"Thành viên không tồn tại!\"}");
                }
            } else if (pathInfo.equals("/shop/toggle")) {
                Map<String, Object> reqMap = JsonUtils.parseObject(body);
                boolean closed = (Boolean) reqMap.get("closed");
                stateService.setShopClosed(closed);
                resp.getWriter().write("{\"closed\":" + closed + "}");
            } else {
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

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
        String status = (String) reqMap.get("status");

        if (status == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"Missing required 'status' property in body.\"}");
            return;
        }

        try {
            if (pathInfo.startsWith("/orders/") && pathInfo.contains("/items/")) {
                // Route format: /orders/{orderId}/items/{itemId}
                String[] parts = pathInfo.split("/");
                if (parts.length >= 5) {
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
}
