package model;

public class PaymentStats {
    private String paymentMethod;
    private int totalOrders;
    private int totalRevenue;

    public PaymentStats() {}

    public PaymentStats(String paymentMethod, int totalOrders, int totalRevenue) {
        this.paymentMethod = paymentMethod;
        this.totalOrders = totalOrders;
        this.totalRevenue = totalRevenue;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
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
