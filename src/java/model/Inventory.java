package model;

public class Inventory {
    private int ingredientId;
    private String ingredientName;
    private double stockQuantity;
    private double minStockLevel;
    private String unit;

    public Inventory() {
    }

    public Inventory(int ingredientId, String ingredientName, double stockQuantity, double minStockLevel, String unit) {
        this.ingredientId = ingredientId;
        this.ingredientName = ingredientName;
        this.stockQuantity = stockQuantity;
        this.minStockLevel = minStockLevel;
        this.unit = unit;
    }

    public int getIngredientId() { return ingredientId; }
    public void setIngredientId(int ingredientId) { this.ingredientId = ingredientId; }

    public String getIngredientName() { return ingredientName; }
    public void setIngredientName(String ingredientName) { this.ingredientName = ingredientName; }

    public double getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(double stockQuantity) { this.stockQuantity = stockQuantity; }

    public double getMinStockLevel() { return minStockLevel; }
    public void setMinStockLevel(double minStockLevel) { this.minStockLevel = minStockLevel; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }
}
