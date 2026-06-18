package model;

import java.util.List;

public class Order {
    private String id;
    private String tableId;
    private String tableName;
    private int orderNumber;
    private List<OrderItem> items;
    private String status; // Pending, Preparing, Ready, Served
    private String createdAt;
    private String updatedAt;
    private String notes;
    private int totalAmount;

    public Order() {}

    public Order(String id, String tableId, String tableName, int orderNumber, List<OrderItem> items, String status, String createdAt, String updatedAt, String notes, int totalAmount) {
        this.id = id;
        this.tableId = tableId;
        this.tableName = tableName;
        this.orderNumber = orderNumber;
        this.items = items;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.notes = notes;
        this.totalAmount = totalAmount;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTableId() { return tableId; }
    public void setTableId(String tableId) { this.tableId = tableId; }

    public String getTableName() { return tableName; }
    public void setTableName(String tableName) { this.tableName = tableName; }

    public int getOrderNumber() { return orderNumber; }
    public void setOrderNumber(int orderNumber) { this.orderNumber = orderNumber; }

    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public int getTotalAmount() { return totalAmount; }
    public void setTotalAmount(int totalAmount) { this.totalAmount = totalAmount; }
}
