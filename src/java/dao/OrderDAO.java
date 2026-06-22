package dao;

import context.DBContext;
import model.Order;
import model.OrderItem;
import model.CustomizationOptions;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Access Object for managing orders.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class OrderDAO {
    private final List<Order> fallbackOrders = new ArrayList<>();

    /**
     * Retrieves all orders from the database or fallback list.
     * 
     * @return a list of all orders
     */
    public List<Order> getAll() {
        List<Order> orders = new ArrayList<>();
        String sql = "SELECT id, tableId, tableName, orderNumber, status, createdAt, updatedAt, notes, totalAmount FROM dbo.Orders ORDER BY createdAt DESC";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                String id = rs.getString("id");
                String tableId = rs.getString("tableId");
                String tableName = rs.getString("tableName");
                int orderNumber = rs.getInt("orderNumber");
                String status = rs.getString("status");
                String createdAt = rs.getString("createdAt");
                String updatedAt = rs.getString("updatedAt");
                String notes = rs.getString("notes");
                int totalAmount = rs.getInt("totalAmount");
                
                List<OrderItem> items = getOrderItems(con, id);
                orders.add(new Order(id, tableId, tableName, orderNumber, items, status, createdAt, updatedAt, notes, totalAmount));
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in OrderDAO.getAll(), falling back to mockup: " + e.getMessage());
            return fallbackOrders;
        }
        
        if (orders.isEmpty()) {
            return fallbackOrders;
        }
        return orders;
    }

    /**
     * Retrieves a specific order by its ID.
     * 
     * @param id the unique identifier of the order
     * @return the order if found, null otherwise
     */
    public Order getById(String id) {
        String sql = "SELECT id, tableId, tableName, orderNumber, status, createdAt, updatedAt, notes, totalAmount FROM dbo.Orders WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, id);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    String tableId = rs.getString("tableId");
                    String tableName = rs.getString("tableName");
                    int orderNumber = rs.getInt("orderNumber");
                    String status = rs.getString("status");
                    String createdAt = rs.getString("createdAt");
                    String updatedAt = rs.getString("updatedAt");
                    String notes = rs.getString("notes");
                    int totalAmount = rs.getInt("totalAmount");
                    
                    List<OrderItem> items = getOrderItems(con, id);
                    return new Order(id, tableId, tableName, orderNumber, items, status, createdAt, updatedAt, notes, totalAmount);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in OrderDAO.getById(), searching fallback mockup list...");
        }
        
        return fallbackOrders.stream()
                .filter(order -> order.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    /**
     * Creates a new order along with its order items in the database.
     * 
     * @param order the order to create
     */
    public void create(Order order) {
        String insertOrderSql = "INSERT INTO dbo.Orders (id, tableId, tableName, orderNumber, status, createdAt, updatedAt, notes, totalAmount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        String insertItemSql = "INSERT INTO dbo.OrderItems (id, orderId, menuItemId, name, price, quantity, size, sugar, ice, notes, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                // Insert Order Header
                try (PreparedStatement st = con.prepareStatement(insertOrderSql)) {
                    st.setString(1, order.getId());
                    st.setString(2, order.getTableId());
                    st.setString(3, order.getTableName());
                    st.setInt(4, order.getOrderNumber());
                    st.setString(5, order.getStatus());
                    st.setString(6, order.getCreatedAt());
                    st.setString(7, order.getUpdatedAt());
                    st.setString(8, order.getNotes());
                    st.setInt(9, order.getTotalAmount());
                    st.executeUpdate();
                }
                
                // Insert Order Items Detail
                if (order.getItems() != null) {
                    for (OrderItem item : order.getItems()) {
                        try (PreparedStatement st = con.prepareStatement(insertItemSql)) {
                            st.setString(1, item.getId());
                            st.setString(2, order.getId());
                            st.setString(3, item.getMenuItemId());
                            st.setString(4, item.getName());
                            st.setInt(5, item.getPrice());
                            st.setInt(6, item.getQuantity());
                            
                            CustomizationOptions custom = item.getCustomization();
                            String sizeStr = (custom != null && custom.getSize() != null) ? custom.getSize() : "M";
                            String sugarStr = (custom != null && custom.getSugar() != null) ? custom.getSugar() : "100%";
                            String iceStr = (custom != null && custom.getIce() != null) ? custom.getIce() : "100%";
                            
                            st.setString(7, sizeStr);
                            st.setString(8, sugarStr);
                            st.setString(9, iceStr);
                            st.setString(10, item.getNotes());
                            st.setString(11, item.getStatus());
                            st.executeUpdate();
                        }
                    }
                }
                con.commit();
            } catch (Exception ex) {
                con.rollback();
                throw ex;
            }
        } catch (Exception e) {
            System.err.println("Database insert failed in OrderDAO.create(), saving to memory list: " + e.getMessage());
        }
        
        fallbackOrders.add(order);
    }

    /**
     * Updates an existing order and recreates its order items in the database.
     * 
     * @param order the order to update
     */
    public void update(Order order) {
        String updateOrderSql = "UPDATE dbo.Orders SET tableId = ?, tableName = ?, orderNumber = ?, status = ?, updatedAt = ?, notes = ?, totalAmount = ? WHERE id = ?";
        String deleteItemsSql = "DELETE FROM dbo.OrderItems WHERE orderId = ?";
        String insertItemSql = "INSERT INTO dbo.OrderItems (id, orderId, menuItemId, name, price, quantity, size, sugar, ice, notes, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                // Update header
                try (PreparedStatement st = con.prepareStatement(updateOrderSql)) {
                    st.setString(1, order.getTableId());
                    st.setString(2, order.getTableName());
                    st.setInt(3, order.getOrderNumber());
                    st.setString(4, order.getStatus());
                    st.setString(5, order.getUpdatedAt());
                    st.setString(6, order.getNotes());
                    st.setInt(7, order.getTotalAmount());
                    st.setString(8, order.getId());
                    st.executeUpdate();
                }
                
                if (order.getItems() != null) {
                    try (PreparedStatement st = con.prepareStatement(deleteItemsSql)) {
                        st.setString(1, order.getId());
                        st.executeUpdate();
                    }
                    for (OrderItem item : order.getItems()) {
                        try (PreparedStatement st = con.prepareStatement(insertItemSql)) {
                            st.setString(1, item.getId());
                            st.setString(2, order.getId());
                            st.setString(3, item.getMenuItemId());
                            st.setString(4, item.getName());
                            st.setInt(5, item.getPrice());
                            st.setInt(6, item.getQuantity());

                            CustomizationOptions custom = item.getCustomization();
                            String sizeStr = (custom != null && custom.getSize() != null) ? custom.getSize() : "M";
                            String sugarStr = (custom != null && custom.getSugar() != null) ? custom.getSugar() : "100%";
                            String iceStr = (custom != null && custom.getIce() != null) ? custom.getIce() : "100%";

                            st.setString(7, sizeStr);
                            st.setString(8, sugarStr);
                            st.setString(9, iceStr);
                            st.setString(10, item.getNotes());
                            st.setString(11, item.getStatus());
                            st.executeUpdate();
                        }
                    }
                }
                con.commit();
            } catch (Exception ex) {
                con.rollback();
                throw ex;
            }
        } catch (Exception e) {
            System.err.println("Database update failed in OrderDAO.update(), applying memory update: " + e.getMessage());
        }
        
        // Always mirror on fallbackOrders memory cache
        Order existing = fallbackOrders.stream()
                .filter(o -> o.getId().equals(order.getId()))
                .findFirst()
                .orElse(null);
        if (existing != null) {
            existing.setTableId(order.getTableId());
            existing.setTableName(order.getTableName());
            existing.setOrderNumber(order.getOrderNumber());
            existing.setStatus(order.getStatus());
            existing.setItems(order.getItems());
            existing.setUpdatedAt(order.getUpdatedAt());
            existing.setNotes(order.getNotes());
            existing.setTotalAmount(order.getTotalAmount());
        } else {
            fallbackOrders.add(order);
        }
    }

    private List<OrderItem> getOrderItems(Connection con, String orderId) throws Exception {
        List<OrderItem> items = new ArrayList<>();
        String sql = "SELECT id, menuItemId, name, price, quantity, size, sugar, ice, notes, status FROM dbo.OrderItems WHERE orderId = ?";
        try (PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, orderId);
            try (ResultSet rs = st.executeQuery()) {
                while (rs.next()) {
                    String id = rs.getString("id");
                    String menuItemId = rs.getString("menuItemId");
                    String name = rs.getString("name");
                    int price = rs.getInt("price");
                    int quantity = rs.getInt("quantity");
                    String size = rs.getString("size");
                    String sugar = rs.getString("sugar");
                    String ice = rs.getString("ice");
                    String notes = rs.getString("notes");
                    String status = rs.getString("status");
                    
                    CustomizationOptions custom = new CustomizationOptions(size, sugar, ice);
                    items.add(new OrderItem(id, menuItemId, name, price, quantity, custom, notes, status));
                }
            }
        }
        return items;
    }
}
