package model;

/**
 * Mot dong trong gio hang khach gui len (productId + so luong + ghi chu tu do).
 */
public class CartLine {

    private int productId;
    private int quantity;
    private String note;

    public CartLine() {
    }

    public CartLine(int productId, int quantity, String note) {
        this.productId = productId;
        this.quantity = quantity;
        this.note = note;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
