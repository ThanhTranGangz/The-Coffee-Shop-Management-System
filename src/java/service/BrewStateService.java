package service;

import dal.MenuDAO;
import dal.TableDAO;
import dal.OrderDAO;
import model.*;
import websocket.BrewWebSocketHandler;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.*;

public class BrewStateService {
    private final MenuDAO menuDAO;
    private final TableDAO tableDAO;
    private final OrderDAO orderDAO;
    private final BrewWebSocketHandler webSocketHandler;

    public BrewStateService(MenuDAO menuDAO, TableDAO tableDAO, OrderDAO orderDAO, BrewWebSocketHandler webSocketHandler) {
        this.menuDAO = menuDAO;
        this.tableDAO = tableDAO;
        this.orderDAO = orderDAO;
        this.webSocketHandler = webSocketHandler;
    }

    // ------------------- Menu & Tables -------------------

    /** Lấy toàn bộ menu hiển thị cho khách */
    public List<MenuItem> getMenu() {
        return menuDAO.getAllMenuItems();
    }

    /** Lấy danh sách bàn kèm QR token */
    public List<TableDAO.TableWithToken> getTables() {
        return tableDAO.getAllWithToken();
    }

    // ------------------- Orders -------------------

    /** Lấy danh sách đơn cho bảng điều phối (KDS/Wait Station) */
    public List<OrderInfo> getBoardOrders() {
        return orderDAO.getBoardOrders();
    }

    /** Lấy chi tiết một đơn hàng */
    public OrderInfo getOrderInfo(int orderId) {
        return orderDAO.getOrderInfo(orderId);
    }

    /** Đặt order mới cho một bàn */
    public OrderInfo placeOrder(String tableId, List<Map<String,Object>> rawItems, String notes) throws SQLException {
        int tid = Integer.parseInt(tableId.replace("t",""));
        Tables table = tableDAO.findById(tid);
        if (table == null) throw new IllegalArgumentException("Table not found: " + tableId);

        // Chuyển rawItems thành CartLine
        List<CartLine> lines = new ArrayList<>();
        Map<Integer, MenuItem> products = new HashMap<>();
        for (Map<String,Object> raw : rawItems) {
            int productId = Integer.parseInt((String) raw.get("menuItemId"));
            int quantity = ((Number) raw.getOrDefault("quantity",1)).intValue();
            String note = (String) raw.getOrDefault("notes","");
            CartLine line = new CartLine(productId, quantity, note);
            lines.add(line);

            MenuItem item = menuDAO.getMenuByCategory(productId).stream().findFirst().orElse(null);
            if (item != null) {
                products.put(productId, item);
            }
        }

        int totalAmount = lines.stream().mapToInt(l -> products.get(l.getProductId()).getPrice() * l.getQuantity()).sum();

        int orderId = orderDAO.createOrder(tid, null, null, totalAmount, 0, "CASH", lines, products);
        notifyStateChange();
        return orderDAO.getOrderInfo(orderId);
    }

    public void updateItemStatus(String orderId, String itemId, String newStatus) {
        orderDAO.updateItemStatus(Integer.parseInt(orderId), Integer.parseInt(itemId), newStatus);
        notifyStateChange();
    }

    public void updateOrderStatus(String orderId, String newStatus) {
        orderDAO.updateOrderStatus(Integer.parseInt(orderId), newStatus);
        notifyStateChange();
    }


    /** Chuyển order từ bàn nguồn sang bàn đích */
    public void moveTable(String sourceTableId, String targetTableId) {
        tableDAO.moveTable(sourceTableId, targetTableId);
        notifyStateChange();
    }

    /** Gộp order từ bàn nguồn sang bàn đích */
    public void mergeTables(String sourceTableId, String targetTableId) {
        tableDAO.mergeTables(sourceTableId, targetTableId);
        notifyStateChange();
    }

    /** Checkout bàn: hoàn tất order và trả bàn về AVAILABLE */
    public OrderInfo checkoutTable(String tableId) {
        int tid = Integer.parseInt(tableId.replace("t",""));
        boolean ok = tableDAO.checkoutTable(tid);
        notifyStateChange();
        return ok ? orderDAO.getOrderInfo(tid) : null;
    }

    // ------------------- Các hàm bổ sung -------------------

    public String advanceOrderStatus(int orderId) {
        String next = orderDAO.advanceStatus(orderId);
        notifyStateChange();
        return next;
    }

    public OrderDAO.PaidResult markPaid(int orderId) {
        OrderDAO.PaidResult result = orderDAO.markPaid(orderId);
        notifyStateChange();
        return result;
    }

    public boolean cancelOrder(int orderId) {
        boolean ok = orderDAO.cancelOrder(orderId);
        if (ok) notifyStateChange();
        return ok;
    }

    // ------------------- Helper -------------------

    private void notifyStateChange() {
        if (webSocketHandler != null) {
            webSocketHandler.broadcast("{\"type\":\"STATE_UPDATED\"}");
        }
    }
    private CustomizationOptions parseCustomization(Object rawCustObj) {
        CustomizationOptions custom = new CustomizationOptions();
        if (rawCustObj instanceof Map) {
            Map<String, Object> rawCust = (Map<String, Object>) rawCustObj;
            custom.setSize((String) rawCust.getOrDefault("size", "M"));
            custom.setSugar((String) rawCust.getOrDefault("sugar", "100%"));
            custom.setIce((String) rawCust.getOrDefault("ice", "100%"));
        } else {
            custom.setSize("M");
            custom.setSugar("100%");
            custom.setIce("100%");
        }
        return custom;
    }
    private int adjustPrice(int basePrice, String size, String sugar, String ice) {
        int price = basePrice;
        if ("L".equalsIgnoreCase(size)) price += 6000;
        if ("S".equalsIgnoreCase(size)) price = Math.max(10000, price - 4000);

        // Ví dụ: thêm 1000đ nếu yêu cầu "extra ice"
        if ("extra".equalsIgnoreCase(ice)) price += 1000;
        // Không tính thêm tiền cho sugar, nhưng bạn có thể mở rộng

        return price;
    }

}
