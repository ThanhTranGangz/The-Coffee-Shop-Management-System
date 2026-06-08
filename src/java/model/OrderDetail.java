package model;

public class OrderDetail {
    private int detailId;
    private int orderId;
    private int productId;
    private int quantity;
    private int unitPrice;
    private int subtotal;
    private String note;
    private String itemStatus;

    public OrderDetail() {
    }

    public OrderDetail(int detailId, int orderId, int productId, int quantity, int unitPrice, int subtotal, String note, String itemStatus) {
        this.detailId = detailId;
        this.orderId = orderId;
        this.productId = productId;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.subtotal = subtotal;
        this.note = note;
        this.itemStatus = itemStatus;
    }

    public int getDetailId() { return detailId; }
    public void setDetailId(int detailId) { this.detailId = detailId; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public int getUnitPrice() { return unitPrice; }
    public void setUnitPrice(int unitPrice) { this.unitPrice = unitPrice; }

    public int getSubtotal() { return subtotal; }
    public void setSubtotal(int subtotal) { this.subtotal = subtotal; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public String getItemStatus() { return itemStatus; }
    public void setItemStatus(String itemStatus) { this.itemStatus = itemStatus; }
}
