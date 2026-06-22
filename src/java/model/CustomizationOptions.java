package model;

/**
 * Represents the customization options for an order item, such as size, sugar, and ice levels.
 */
public class CustomizationOptions {
    private String size;  // S, M, L
    private String sugar; // 0%, 30%, 50%, 100%
    private String ice;   // 0%, 50%, 100%

    /**
     * Default constructor. Sets default values for size (M), sugar (100%), and ice (100%).
     */
    public CustomizationOptions() {
        this.size = "M";
        this.sugar = "100%";
        this.ice = "100%";
    }

    /**
     * Constructs a CustomizationOptions with specified values.
     * 
     * @param size the size of the drink (e.g., S, M, L)
     * @param sugar the sugar level (e.g., 0%, 50%, 100%)
     * @param ice the ice level (e.g., 0%, 50%, 100%)
     */
    public CustomizationOptions(String size, String sugar, String ice) {
        this.size = size != null ? size : "M";
        this.sugar = sugar != null ? sugar : "100%";
        this.ice = ice != null ? ice : "100%";
    }

    // Getters and Setters
    public String getSize() { return size; }
    public void setSize(String size) { this.size = size; }

    public String getSugar() { return sugar; }
    public void setSugar(String sugar) { this.sugar = sugar; }

    public String getIce() { return ice; }
    public void setIce(String ice) { this.ice = ice; }
}
