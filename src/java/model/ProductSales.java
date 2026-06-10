package model;

public class ProductSales {
    private String productName;
    private String categoryName;
    private int quantitySold;
    private int totalRevenue;

    public ProductSales() {}

    public ProductSales(String productName, String categoryName, int quantitySold, int totalRevenue) {
        this.productName = productName;
        this.categoryName = categoryName;
        this.quantitySold = quantitySold;
        this.totalRevenue = totalRevenue;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public int getQuantitySold() {
        return quantitySold;
    }

    public void setQuantitySold(int quantitySold) {
        this.quantitySold = quantitySold;
    }

    public int getTotalRevenue() {
        return totalRevenue;
    }

    public void setTotalRevenue(int totalRevenue) {
        this.totalRevenue = totalRevenue;
    }
}
