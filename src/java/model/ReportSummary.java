package model;

public class ReportSummary {

    private int totalOrders;
    private int totalRevenue;
    private int cashRevenue;
    private int vietQrRevenue;

    public ReportSummary() {
    }

    public ReportSummary(int totalOrders, int totalRevenue, int cashRevenue, int vietQrRevenue) {
        this.totalOrders = totalOrders;
        this.totalRevenue = totalRevenue;
        this.cashRevenue = cashRevenue;
        this.vietQrRevenue = vietQrRevenue;
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

    public int getCashRevenue() {
        return cashRevenue;
    }

    public void setCashRevenue(int cashRevenue) {
        this.cashRevenue = cashRevenue;
    }

    public int getVietQrRevenue() {
        return vietQrRevenue;
    }

    public void setVietQrRevenue(int vietQrRevenue) {
        this.vietQrRevenue = vietQrRevenue;
    }
}