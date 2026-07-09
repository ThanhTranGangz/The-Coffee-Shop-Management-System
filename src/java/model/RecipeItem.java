package model;

/**
 * Represents an ingredient and its quantity required to make a specific menu item.
 */
public class RecipeItem {
    private String id;
    private String menuItemId;
    private String ingredientId;
    private int quantity;
    
    // For convenience in frontend, we can also store the ingredient name and unit
    private String ingredientName;
    private String ingredientUnit;

    public RecipeItem() {}

    public RecipeItem(String id, String menuItemId, String ingredientId, int quantity) {
        this.id = id;
        this.menuItemId = menuItemId;
        this.ingredientId = ingredientId;
        this.quantity = quantity;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMenuItemId() { return menuItemId; }
    public void setMenuItemId(String menuItemId) { this.menuItemId = menuItemId; }

    public String getIngredientId() { return ingredientId; }
    public void setIngredientId(String ingredientId) { this.ingredientId = ingredientId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public String getIngredientName() { return ingredientName; }
    public void setIngredientName(String ingredientName) { this.ingredientName = ingredientName; }

    public String getIngredientUnit() { return ingredientUnit; }
    public void setIngredientUnit(String ingredientUnit) { this.ingredientUnit = ingredientUnit; }

    public java.util.Map<String, Object> toMap() {
        java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
        map.put("id", id);
        map.put("menuItemId", menuItemId);
        map.put("ingredientId", ingredientId);
        map.put("quantity", quantity);
        map.put("ingredientName", ingredientName);
        map.put("ingredientUnit", ingredientUnit);
        return map;
    }
}
