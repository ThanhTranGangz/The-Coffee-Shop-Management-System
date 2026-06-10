package model;

import java.util.ArrayList;
import java.util.List;

/**
 * Ket qua tam tinh cho gio hang: tung dong, giam gia hang thanh vien,
 * giam gia voucher va tong phai tra.
 */
public class PriceQuote {

    public static class QuoteLine {
        private int productId;
        private String productName;
        private int unitPrice;
        private int quantity;
        private int lineTotal;
        private boolean available;
        private String note;

        public int getProductId() { return productId; }
        public void setProductId(int productId) { this.productId = productId; }

        public String getProductName() { return productName; }
        public void setProductName(String productName) { this.productName = productName; }

        public int getUnitPrice() { return unitPrice; }
        public void setUnitPrice(int unitPrice) { this.unitPrice = unitPrice; }

        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }

        public int getLineTotal() { return lineTotal; }
        public void setLineTotal(int lineTotal) { this.lineTotal = lineTotal; }

        public boolean isAvailable() { return available; }
        public void setAvailable(boolean available) { this.available = available; }

        public String getNote() { return note; }
        public void setNote(String note) { this.note = note; }
    }

    private List<QuoteLine> lines = new ArrayList<>();
    private int subtotal;

    private int memberDiscountPercent;
    private int memberDiscount;

    private String voucherCode;
    private boolean voucherValid;
    private String voucherMessage;
    private Integer voucherId;
    private int voucherDiscount;

    private int total;
    private int pointsEarn;
    private boolean allAvailable = true;

    public List<QuoteLine> getLines() { return lines; }
    public void setLines(List<QuoteLine> lines) { this.lines = lines; }

    public int getSubtotal() { return subtotal; }
    public void setSubtotal(int subtotal) { this.subtotal = subtotal; }

    public int getMemberDiscountPercent() { return memberDiscountPercent; }
    public void setMemberDiscountPercent(int memberDiscountPercent) { this.memberDiscountPercent = memberDiscountPercent; }

    public int getMemberDiscount() { return memberDiscount; }
    public void setMemberDiscount(int memberDiscount) { this.memberDiscount = memberDiscount; }

    public String getVoucherCode() { return voucherCode; }
    public void setVoucherCode(String voucherCode) { this.voucherCode = voucherCode; }

    public boolean isVoucherValid() { return voucherValid; }
    public void setVoucherValid(boolean voucherValid) { this.voucherValid = voucherValid; }

    public String getVoucherMessage() { return voucherMessage; }
    public void setVoucherMessage(String voucherMessage) { this.voucherMessage = voucherMessage; }

    public Integer getVoucherId() { return voucherId; }
    public void setVoucherId(Integer voucherId) { this.voucherId = voucherId; }

    public int getVoucherDiscount() { return voucherDiscount; }
    public void setVoucherDiscount(int voucherDiscount) { this.voucherDiscount = voucherDiscount; }

    public int getTotal() { return total; }
    public void setTotal(int total) { this.total = total; }

    public int getPointsEarn() { return pointsEarn; }
    public void setPointsEarn(int pointsEarn) { this.pointsEarn = pointsEarn; }

    public boolean isAllAvailable() { return allAvailable; }
    public void setAllAvailable(boolean allAvailable) { this.allAvailable = allAvailable; }

    public int getDiscountTotal() {
        return memberDiscount + voucherDiscount;
    }
}
