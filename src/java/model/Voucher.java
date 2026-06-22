package model;

public class Voucher {
    private String code;
    private String name;
    private int discountAmount;
    private int pointCost;
    private boolean active;

    public Voucher() {}

    public Voucher(String code, String name, int discountAmount, int pointCost, boolean active) {
        this.code = code;
        this.name = name;
        this.discountAmount = discountAmount;
        this.pointCost = pointCost;
        this.active = active;
    }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(int discountAmount) { this.discountAmount = discountAmount; }

    public int getPointCost() { return pointCost; }
    public void setPointCost(int pointCost) { this.pointCost = pointCost; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
