package model;

/**
 * Product hien thi tren menu khach hang:
 * kem ten danh muc va trang thai con hang (du nguyen lieu) hay khong.
 */
public class MenuItem extends Product {

    private String categoryName;
    private boolean available;

    public MenuItem() {
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public boolean isAvailable() {
        return available;
    }

    public void setAvailable(boolean available) {
        this.available = available;
    }
}
