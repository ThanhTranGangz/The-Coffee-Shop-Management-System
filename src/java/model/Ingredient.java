package model;

/**
 * Represents an ingredient used in the coffee shop inventory.
 */
public class Ingredient {
    private String id;
    private String name;
    private String unit;
    private int stock;
    private int minStock;
    private int importCost;

    /**
     * Default constructor.
     */
    public Ingredient() {}

    /**
     * Constructs an Ingredient with specified values.
     * 
     * @param id the unique identifier of the ingredient
     * @param name the name of the ingredient
     * @param unit the unit of measurement (e.g., kg, ml)
     * @param stock the current stock quantity
     * @param minStock the minimum stock threshold
     * @param importCost the cost of importing the ingredient
     */
    public Ingredient(String id, String name, String unit, int stock, int minStock, int importCost) {
        this.id = id;
        this.name = name;
        this.unit = unit;
        this.stock = stock;
        this.minStock = minStock;
        this.importCost = importCost;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public int getStock() { return stock; }
    public void setStock(int stock) { this.stock = stock; }

    public int getMinStock() { return minStock; }
    public void setMinStock(int minStock) { this.minStock = minStock; }

    public int getImportCost() { return importCost; }
    public void setImportCost(int importCost) { this.importCost = importCost; }
}
