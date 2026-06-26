package model;

/**
 * Represents a discount or reward voucher that can be redeemed by members.
 */
public class Voucher {
    private String code;
    private String name;
    private int discountAmount;
    private int pointCost;
    private boolean active;

    /**
     * Default constructor.
     */
    public Voucher() {}

    /**
     * Constructs a Voucher with full details.
     * 
     * @param code the voucher code
     * @param name the name or description of the voucher
     * @param discountAmount the discount amount in currency
     * @param pointCost the cost in points to redeem
     * @param active whether the voucher is currently active
     */
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
