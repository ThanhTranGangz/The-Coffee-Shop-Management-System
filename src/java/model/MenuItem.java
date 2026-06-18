package model;

import java.util.List;

public class MenuItem {
    private String id;
    private String name;
    private String category;
    private int price;
    private String description;
    private List<String> availableSizes;
    private String image;
    private Boolean inStock;

    public MenuItem() {}

    public MenuItem(String id, String name, String category, int price, String description, List<String> availableSizes) {
        this(id, name, category, price, description, availableSizes, "");
    }

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
