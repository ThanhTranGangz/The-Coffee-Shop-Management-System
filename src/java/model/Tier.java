package model;

public class Tier {
    private int tierId;
    private String tierName;
    private int minPoints;
    private int discountPercent;

    public Tier() {
    }

    public Tier(int tierId, String tierName, int minPoints, int discountPercent) {
        this.tierId = tierId;
        this.tierName = tierName;
        this.minPoints = minPoints;
        this.discountPercent = discountPercent;
    }

    public int getTierId() { return tierId; }
    public void setTierId(int tierId) { this.tierId = tierId; }

    public String getTierName() { return tierName; }
    public void setTierName(String tierName) { this.tierName = tierName; }

    public int getMinPoints() { return minPoints; }
    public void setMinPoints(int minPoints) { this.minPoints = minPoints; }

    public int getDiscountPercent() { return discountPercent; }
    public void setDiscountPercent(int discountPercent) { this.discountPercent = discountPercent; }
}
