package model;

import java.util.List;

/**
 * Represents a menu item in the coffee shop, including its details, pricing, and availability.
 */
public class MenuItem {
    private String id;
    private String name;
    private String category;
    private int price;
    private String description;
    private List<String> availableSizes;
    private String image;
    private Boolean inStock;

    /**
     * Default constructor.
     */
    public MenuItem() {}

    /**
     * Constructs a MenuItem without an image.
     * 
     * @param id the unique identifier
     * @param name the name of the item
     * @param category the category of the item
     * @param price the price of the item
     * @param description a brief description
     * @param availableSizes the list of available sizes
     */
    public MenuItem(String id, String name, String category, int price, String description, List<String> availableSizes) {
        this(id, name, category, price, description, availableSizes, "");
    }

    /**
     * Constructs a MenuItem with full information including an image.
     * 
     * @param id the unique identifier
     * @param name the name of the item
     * @param category the category of the item
     * @param price the price of the item
     * @param description a brief description
     * @param availableSizes the list of available sizes
     * @param image the image URL or path
     */
    public MenuItem(String id, String name, String category, int price, String description, List<String> availableSizes, String image) {
        this.id = id;
        this.name = name;
        this.category = category;
        this.price = price;
        this.description = description;
        this.availableSizes = availableSizes;
        this.image = image;
        this.inStock = true;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public int getPrice() { return price; }
    public void setPrice(int price) { this.price = price; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public List<String> getAvailableSizes() { return availableSizes; }
    public void setAvailableSizes(List<String> availableSizes) { this.availableSizes = availableSizes; }

    public String getImage() { return image; }
    public void setImage(String image) { this.image = image; }

    public Boolean getInStock() { return inStock; }
    public void setInStock(Boolean inStock) { this.inStock = inStock; }
}
