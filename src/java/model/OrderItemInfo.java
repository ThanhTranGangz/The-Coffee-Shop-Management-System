package model;

/**
 * Mot dong chi tiet don hang (da kem ten san pham) de hien thi.
 */
public class OrderItemInfo {

    private int detailId;
    private int productId;
    private String productName;
    private int quantity;
    private int unitPrice;
    private int subtotal;
    private String note;
    private String itemStatus;

    public int getDetailId() { return detailId; }
    public void setDetailId(int detailId) { this.detailId = detailId; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

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
