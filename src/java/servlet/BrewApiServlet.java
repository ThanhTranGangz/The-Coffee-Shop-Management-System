package servlet;

import context.AppContext;
import model.Order;
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
