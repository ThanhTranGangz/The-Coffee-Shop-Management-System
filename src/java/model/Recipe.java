package model;

public class Recipe {
    private int productId;
    private int ingredientId;
    private double quantityNeeded;

    public Recipe() {
    }

    public Recipe(int productId, int ingredientId, double quantityNeeded) {
        this.productId = productId;
        this.ingredientId = ingredientId;
        this.quantityNeeded = quantityNeeded;
    }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public int getIngredientId() { return ingredientId; }
    public void setIngredientId(int ingredientId) { this.ingredientId = ingredientId; }

    public double getQuantityNeeded() { return quantityNeeded; }
    public void setQuantityNeeded(double quantityNeeded) { this.quantityNeeded = quantityNeeded; }
}
