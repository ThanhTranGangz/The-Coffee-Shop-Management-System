package model;

import java.sql.Timestamp;

public class Voucher {
    private int voucherId;
    private String voucherCode;
    private Integer discountAmount;
    private Integer discountPercent;
    private Integer minTierRequired;
    private Timestamp expiryDate;
    private boolean isActive;

    public Voucher() {
    }

    public Voucher(int voucherId, String voucherCode, Integer discountAmount, Integer discountPercent, Integer minTierRequired, Timestamp expiryDate, boolean isActive) {
        this.voucherId = voucherId;
        this.voucherCode = voucherCode;
        this.discountAmount = discountAmount;
        this.discountPercent = discountPercent;
        this.minTierRequired = minTierRequired;
        this.expiryDate = expiryDate;
        this.isActive = isActive;
    }

    public int getVoucherId() { return voucherId; }
    public void setVoucherId(int voucherId) { this.voucherId = voucherId; }

    public String getVoucherCode() { return voucherCode; }
    public void setVoucherCode(String voucherCode) { this.voucherCode = voucherCode; }

    public Integer getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(Integer discountAmount) { this.discountAmount = discountAmount; }

    public Integer getDiscountPercent() { return discountPercent; }
    public void setDiscountPercent(Integer discountPercent) { this.discountPercent = discountPercent; }

    public Integer getMinTierRequired() { return minTierRequired; }
    public void setMinTierRequired(Integer minTierRequired) { this.minTierRequired = minTierRequired; }

    public Timestamp getExpiryDate() { return expiryDate; }
    public void setExpiryDate(Timestamp expiryDate) { this.expiryDate = expiryDate; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }
}
