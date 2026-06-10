package dal;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import model.CartLine;
import model.MenuItem;
import model.OrderInfo;
import model.OrderItemInfo;

public class OrderDAO extends DBContext {

    /** Ket qua khi xac nhan thanh toan. */
    public static class PaidResult {
        public boolean updated;
        public Integer memberId;
        public int finalAmount;
    }

    /**
     * Tao don hang QR trong 1 transaction:
     * kiem tra + tru ton kho nguyen lieu, ghi Orders + OrderDetail,
     * chuyen ban sang OCCUPIED.
     *
     * @throws IllegalStateException neu nguyen lieu vua het (da rollback)
     */
    public int createOrder(int tableId, Integer memberId, Integer voucherId,
                           int totalAmount, int discountAmount, String paymentMethod,
                           List<CartLine> lines, Map<Integer, MenuItem> products) throws SQLException {
        try {
            connection.setAutoCommit(false);

            // 1. Gom tong nguyen lieu can dung cua ca don
            Map<Integer, BigDecimal> needed = new LinkedHashMap<>();
            String recipeSql = "SELECT IngredientID, QuantityNeeded FROM Recipe WHERE ProductID = ?";
            try (PreparedStatement ps = connection.prepareStatement(recipeSql)) {
                for (CartLine line : lines) {
                    ps.setInt(1, line.getProductId());
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int ingId = rs.getInt("IngredientID");
                            BigDecimal qty = rs.getBigDecimal("QuantityNeeded")
                                    .multiply(BigDecimal.valueOf(line.getQuantity()));
                            needed.merge(ingId, qty, BigDecimal::add);
                        }
                    }
                }
            }

            // 2. Tru kho; neu thieu thi bao ro nguyen lieu nao het
            String checkSql = "SELECT IngredientName, StockQuantity FROM Inventory WHERE IngredientID = ?";
            String deductSql = "UPDATE Inventory SET StockQuantity = StockQuantity - ? "
                    + "WHERE IngredientID = ? AND StockQuantity >= ?";
            try (PreparedStatement check = connection.prepareStatement(checkSql);
                 PreparedStatement deduct = connection.prepareStatement(deductSql)) {
                for (Map.Entry<Integer, BigDecimal> e : needed.entrySet()) {
                    deduct.setBigDecimal(1, e.getValue());
                    deduct.setInt(2, e.getKey());
                    deduct.setBigDecimal(3, e.getValue());
                    if (deduct.executeUpdate() == 0) {
                        String ingName = "nguyên liệu";
                        check.setInt(1, e.getKey());
                        try (ResultSet rs = check.executeQuery()) {
                            if (rs.next()) {
                                ingName = rs.getString("IngredientName");
                            }
                        }
                        connection.rollback();
                        throw new IllegalStateException(
                                "Nguyên liệu \"" + ingName + "\" vừa hết, món liên quan tạm thời không phục vụ được.");
                    }
                }
            }

            // 3. Ghi don hang
            String orderSql = "INSERT INTO Orders (TotalAmount, DiscountAmount, PaymentMethod, OrderSource, "
                    + "OrderStatus, PaymentStatus, TableID, MemberID, VoucherID) "
                    + "VALUES (?, ?, ?, 'QR', 'PENDING', ?, ?, ?, ?)";
            int orderId;
            try (PreparedStatement ps = connection.prepareStatement(orderSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, totalAmount);
                ps.setInt(2, discountAmount);
                ps.setString(3, paymentMethod);
                // VIETQR: khach bao da chuyen khoan -> cho thu ngan doi soat (PENDING)
                // CASH:   thanh toan tai quay -> UNPAID
                ps.setString(4, "VIETQR".equals(paymentMethod) ? "PENDING" : "UNPAID");
                ps.setInt(5, tableId);
                if (memberId == null) {
                    ps.setNull(6, java.sql.Types.INTEGER);
                } else {
                    ps.setInt(6, memberId);
                }
                if (voucherId == null) {
                    ps.setNull(7, java.sql.Types.INTEGER);
                } else {
                    ps.setInt(7, voucherId);
                }
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) {
                        connection.rollback();
                        throw new SQLException("Khong lay duoc OrderID");
                    }
                    orderId = keys.getInt(1);
                }
            }

            // 4. Ghi chi tiet mon (kem ghi chu cua khach)
            String detailSql = "INSERT INTO OrderDetail (OrderID, ProductID, Quantity, UnitPrice, Note, ItemStatus) "
                    + "VALUES (?, ?, ?, ?, ?, 'PENDING')";
            try (PreparedStatement ps = connection.prepareStatement(detailSql)) {
                for (CartLine line : lines) {
                    MenuItem p = products.get(line.getProductId());
                    ps.setInt(1, orderId);
                    ps.setInt(2, line.getProductId());
                    ps.setInt(3, line.getQuantity());
                    ps.setInt(4, p.getPrice());
                    if (line.getNote() == null || line.getNote().trim().isEmpty()) {
                        ps.setNull(5, java.sql.Types.NVARCHAR);
                    } else {
                        ps.setNString(5, line.getNote().trim());
                    }
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            // 5. Ban dang co khach
            try (PreparedStatement ps = connection.prepareStatement(
                    "UPDATE Tables SET [Status] = 'OCCUPIED' WHERE TableID = ?")) {
                ps.setInt(1, tableId);
                ps.executeUpdate();
            }

            connection.commit();
            return orderId;
        } catch (SQLException e) {
            try { connection.rollback(); } catch (SQLException ignore) { }
            throw e;
        } finally {
            try { connection.setAutoCommit(true); } catch (SQLException ignore) { }
        }
    }

    /** Lich su don hang cua thanh vien (khong kem chi tiet mon — dung cho danh sach). */
    public List<OrderInfo> findByMemberId(int memberId, int limit) {
        List<OrderInfo> list = new ArrayList<>();
        String sql = "SELECT TOP (?) o.OrderID, o.OrderDate, o.TotalAmount, o.DiscountAmount, o.FinalAmount, "
                + "o.PaymentMethod, o.OrderStatus, o.PaymentStatus, o.TableID, t.TableName "
                + "FROM Orders o LEFT JOIN Tables t ON o.TableID = t.TableID "
                + "WHERE o.MemberID = ? ORDER BY o.OrderDate DESC";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, Math.max(1, Math.min(limit, 50)));
            ps.setInt(2, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    OrderInfo o = new OrderInfo();
                    o.setOrderId(rs.getInt("OrderID"));
                    o.setOrderDate(rs.getTimestamp("OrderDate"));
                    o.setTotalAmount(rs.getInt("TotalAmount"));
                    o.setDiscountAmount(rs.getInt("DiscountAmount"));
                    o.setFinalAmount(rs.getInt("FinalAmount"));
                    o.setPaymentMethod(rs.getString("PaymentMethod"));
                    o.setOrderStatus(rs.getString("OrderStatus"));
                    o.setPaymentStatus(rs.getString("PaymentStatus"));
                    int tableId = rs.getInt("TableID");
                    o.setTableId(rs.wasNull() ? null : tableId);
                    o.setTableName(rs.getString("TableName"));
                    list.add(o);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Don hang + chi tiet de hien thi trang trang thai / bang pha che. */
    public OrderInfo getOrderInfo(int orderId) {
        String sql = baseOrderSelect() + "WHERE o.OrderID = ? ORDER BY d.DetailID";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                Map<Integer, OrderInfo> map = new LinkedHashMap<>();
                while (rs.next()) {
                    collectRow(rs, map);
                }
                return map.get(orderId);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Danh sach don cho bang dieu phoi cua quan:
     * moi don dang xu ly + don hoan tat trong ngay (de thu ngan doi soat).
     */
    public List<OrderInfo> getBoardOrders() {
        String sql = baseOrderSelect()
                + "WHERE o.OrderStatus IN ('PENDING','PREPARING','READY') "
                + "   OR (o.OrderStatus = 'COMPLETED' AND CAST(o.OrderDate AS DATE) = CAST(GETDATE() AS DATE)) "
                + "ORDER BY o.OrderDate, o.OrderID, d.DetailID";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            Map<Integer, OrderInfo> map = new LinkedHashMap<>();
            while (rs.next()) {
                collectRow(rs, map);
            }
            return new ArrayList<>(map.values());
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return new ArrayList<>();
    }

    /** Chuyen trang thai: PENDING -> PREPARING -> READY -> COMPLETED. */
    public String advanceStatus(int orderId) {
        String current = getOrderStatus(orderId);
        if (current == null) {
            return null;
        }
        String next;
        String itemStatus;
        switch (current) {
            case "PENDING":   next = "PREPARING"; itemStatus = "PREPARING"; break;
            case "PREPARING": next = "READY";     itemStatus = "READY";     break;
            case "READY":     next = "COMPLETED"; itemStatus = "SERVED";    break;
            default: return null;
        }
        try {
            try (PreparedStatement ps = connection.prepareStatement(
                    "UPDATE Orders SET OrderStatus = ? WHERE OrderID = ?")) {
                ps.setString(1, next);
                ps.setInt(2, orderId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = connection.prepareStatement(
                    "UPDATE OrderDetail SET ItemStatus = ? WHERE OrderID = ?")) {
                ps.setString(1, itemStatus);
                ps.setInt(2, orderId);
                ps.executeUpdate();
            }
            if ("COMPLETED".equals(next)) {
                freeTableIfIdle(orderId);
            }
            return next;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }

    /** Thu ngan xac nhan da nhan tien (tien mat hoac da nhan chuyen khoan). */
    public PaidResult markPaid(int orderId) {
        PaidResult result = new PaidResult();
        try {
            try (PreparedStatement ps = connection.prepareStatement(
                    "UPDATE Orders SET PaymentStatus = 'PAID' WHERE OrderID = ? AND PaymentStatus <> 'PAID'")) {
                ps.setInt(1, orderId);
                result.updated = ps.executeUpdate() > 0;
            }
            if (result.updated) {
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT MemberID, FinalAmount FROM Orders WHERE OrderID = ?")) {
                    ps.setInt(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            int m = rs.getInt("MemberID");
                            result.memberId = rs.wasNull() ? null : m;
                            result.finalAmount = rs.getInt("FinalAmount");
                        }
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return result;
    }

    /** Huy don con o trang thai PENDING va hoan lai ton kho nguyen lieu. */
    public boolean cancelOrder(int orderId) {
        try {
            connection.setAutoCommit(false);

            String guard = "UPDATE Orders SET OrderStatus = 'CANCELLED' "
                    + "WHERE OrderID = ? AND OrderStatus = 'PENDING'";
            try (PreparedStatement ps = connection.prepareStatement(guard)) {
                ps.setInt(1, orderId);
                if (ps.executeUpdate() == 0) {
                    connection.rollback();
                    return false;
                }
            }

            // Hoan kho theo cong thuc cua tung mon trong don
            String restock = "UPDATE i SET i.StockQuantity = i.StockQuantity + (r.QuantityNeeded * d.Quantity) "
                    + "FROM Inventory i "
                    + "JOIN Recipe r ON r.IngredientID = i.IngredientID "
                    + "JOIN OrderDetail d ON d.ProductID = r.ProductID "
                    + "WHERE d.OrderID = ?";
            try (PreparedStatement ps = connection.prepareStatement(restock)) {
                ps.setInt(1, orderId);
                ps.executeUpdate();
            }

            freeTableIfIdle(orderId);
            connection.commit();
            return true;
        } catch (SQLException e) {
            try { connection.rollback(); } catch (SQLException ignore) { }
            e.printStackTrace();
            return false;
        } finally {
            try { connection.setAutoCommit(true); } catch (SQLException ignore) { }
        }
    }

    private String getOrderStatus(int orderId) {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT OrderStatus FROM Orders WHERE OrderID = ?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Neu ban cua don nay khong con don dang xu ly thi tra ban ve AVAILABLE. */
    private void freeTableIfIdle(int orderId) throws SQLException {
        String sql = "UPDATE Tables SET [Status] = 'AVAILABLE' "
                + "WHERE TableID = (SELECT TableID FROM Orders WHERE OrderID = ?) "
                + "AND NOT EXISTS (SELECT 1 FROM Orders o2 WHERE o2.TableID = Tables.TableID "
                + "                AND o2.OrderStatus IN ('PENDING','PREPARING','READY'))";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.executeUpdate();
        }
    }

    private String baseOrderSelect() {
        return "SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.DiscountAmount, o.FinalAmount, "
                + "o.PaymentMethod, o.OrderSource, o.OrderStatus, o.PaymentStatus, "
                + "o.TableID, t.TableName, o.MemberID, m.FullName AS MemberName, "
                + "d.DetailID, d.ProductID, d.Quantity, d.UnitPrice, d.Subtotal, d.Note, d.ItemStatus, "
                + "p.ProductName "
                + "FROM Orders o "
                + "LEFT JOIN Tables t ON o.TableID = t.TableID "
                + "LEFT JOIN Member m ON o.MemberID = m.MemberID "
                + "JOIN OrderDetail d ON d.OrderID = o.OrderID "
                + "JOIN Product p ON p.ProductID = d.ProductID ";
    }

    private void collectRow(ResultSet rs, Map<Integer, OrderInfo> map) throws SQLException {
        int id = rs.getInt("OrderID");
        OrderInfo o = map.get(id);
        if (o == null) {
            o = new OrderInfo();
            o.setOrderId(id);
            o.setOrderDate(rs.getTimestamp("OrderDate"));
            o.setTotalAmount(rs.getInt("TotalAmount"));
            o.setDiscountAmount(rs.getInt("DiscountAmount"));
            o.setFinalAmount(rs.getInt("FinalAmount"));
            o.setPaymentMethod(rs.getString("PaymentMethod"));
            o.setOrderSource(rs.getString("OrderSource"));
            o.setOrderStatus(rs.getString("OrderStatus"));
            o.setPaymentStatus(rs.getString("PaymentStatus"));
            int tableId = rs.getInt("TableID");
            o.setTableId(rs.wasNull() ? null : tableId);
            o.setTableName(rs.getString("TableName"));
            int memberId = rs.getInt("MemberID");
            o.setMemberId(rs.wasNull() ? null : memberId);
            o.setMemberName(rs.getString("MemberName"));
            map.put(id, o);
        }
        OrderItemInfo item = new OrderItemInfo();
        item.setDetailId(rs.getInt("DetailID"));
        item.setProductId(rs.getInt("ProductID"));
        item.setProductName(rs.getString("ProductName"));
        item.setQuantity(rs.getInt("Quantity"));
        item.setUnitPrice(rs.getInt("UnitPrice"));
        item.setSubtotal(rs.getInt("Subtotal"));
        item.setNote(rs.getString("Note"));
        item.setItemStatus(rs.getString("ItemStatus"));
        o.getItems().add(item);
    }
}
