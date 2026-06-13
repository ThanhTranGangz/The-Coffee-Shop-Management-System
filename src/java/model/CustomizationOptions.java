package model;

public class CustomizationOptions {
    private String size;  // S, M, L
    private String sugar; // 0%, 30%, 50%, 100%
    private String ice;   // 0%, 50%, 100%

    public CustomizationOptions() {
        this.size = "M";
        this.sugar = "100%";
        this.ice = "100%";
    }

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
