package model;

/**
 * Represents an individual item within an order, along with customizations and specific notes.
 */
public class OrderItem {
    private String id;
    private String menuItemId;
    private String name;
    private int price;
    private int quantity;
    private CustomizationOptions customization;
    private String notes;
    private String status; // Pending, Preparing, Ready, Served

    /**
     * Default constructor.
     */
    public OrderItem() {}

    /**
     * Constructs an OrderItem with full details.
     * 
     * @param id the item ID
     * @param menuItemId the original menu item ID
     * @param name the name of the item
     * @param price the price of a single unit
     * @param quantity the quantity ordered
     * @param customization the selected customization options
     * @param notes any special notes
     * @param status the item preparation status
     */
    public OrderItem(String id, String menuItemId, String name, int price, int quantity, CustomizationOptions customization, String notes, String status) {
        this.id = id;
        this.menuItemId = menuItemId;
        this.name = name;
        this.price = price;
        this.quantity = quantity;
        this.customization = customization;
        this.notes = notes;
        this.status = status;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMenuItemId() { return menuItemId; }
    public void setMenuItemId(String menuItemId) { this.menuItemId = menuItemId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getPrice() { return price; }
    public void setPrice(int price) { this.price = price; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public CustomizationOptions getCustomization() { return customization; }
    public void setCustomization(CustomizationOptions customization) { this.customization = customization; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
