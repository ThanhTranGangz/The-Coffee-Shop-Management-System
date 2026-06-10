package model;

public class SourceStats {
    private String source;
    private int totalOrders;
    private int totalRevenue;

    public SourceStats() {}

    public SourceStats(String source, int totalOrders, int totalRevenue) {
        this.source = source;
        this.totalOrders = totalOrders;
        this.totalRevenue = totalRevenue;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public int getTotalOrders() {
        return totalOrders;
    }

    public void setTotalOrders(int totalOrders) {
        this.totalOrders = totalOrders;
    }

    public int getTotalRevenue() {
        return totalRevenue;
    }

    public void setTotalRevenue(int totalRevenue) {
        this.totalRevenue = totalRevenue;
    }
}
