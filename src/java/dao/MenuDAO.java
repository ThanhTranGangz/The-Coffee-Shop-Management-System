package dao;

import context.DBContext;
import model.MenuItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class MenuDAO {

    public List<MenuItem> getAll() {
        List<MenuItem> menuItems = new ArrayList<>();
        String sql = "SELECT id, name, category, price, description, availableSizes, image FROM dbo.MenuItems";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                String id = rs.getString("id");
                String name = rs.getString("name");
                String category = rs.getString("category");
                int price = rs.getInt("price");
                String description = rs.getString("description");
                String sizesStr = rs.getString("availableSizes");
                String image = rs.getString("image");
                
                List<String> availableSizes = new ArrayList<>();
                if (sizesStr != null && !sizesStr.trim().isEmpty()) {
                    availableSizes = Arrays.asList(sizesStr.split("\\s*,\\s*"));
                }
                
                menuItems.add(new MenuItem(id, name, category, price, description, availableSizes, image));
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in MenuDAO.getAll(), falling back to mocked list: " + e.getMessage());
            return getFallbackMenu();
        }
        
        if (menuItems.isEmpty()) {
            return getFallbackMenu();
        }
        return menuItems;
    }

    public MenuItem getById(String id) {
        String sql = "SELECT id, name, category, price, description, availableSizes, image FROM dbo.MenuItems WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, id);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    String name = rs.getString("name");
                    String category = rs.getString("category");
                    int price = rs.getInt("price");
                    String description = rs.getString("description");
                    String sizesStr = rs.getString("availableSizes");
                    String image = rs.getString("image");
                    
                    List<String> availableSizes = new ArrayList<>();
                    if (sizesStr != null && !sizesStr.trim().isEmpty()) {
                        availableSizes = Arrays.asList(sizesStr.split("\\s*,\\s*"));
                    }
                    
                    return new MenuItem(id, name, category, price, description, availableSizes, image);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in MenuDAO.getById(), searching fallback context...");
        }
        
        return getFallbackMenu().stream()
                .filter(item -> item.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    private List<MenuItem> getFallbackMenu() {
        List<MenuItem> list = new ArrayList<>();
        list.add(new MenuItem(
            "m1", "Traditional Black Coffee (Cafe Den)", "Coffee", 29000,
            "Bold, dark-roasted Vietnamese coffee beans brewed with a traditional phin filter.",
            Arrays.asList("S", "M", "L"),
            "https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m2", "Vietnamese Milk Coffee (Café Sữa Đá)", "Coffee", 35000,
            "Traditional Vietnamese drip coffee sweetened with rich condensed milk, served over ice.",
            Arrays.asList("S", "M", "L"),
            "https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m3", "Salted Cream Coffee (Café Muối)", "Coffee", 45000,
            "A unique combination of bold coffee with sweet condensed milk, topped with a velvety, slightly salty whipping cream.",
            Arrays.asList("S", "M"),
            "https://images.unsplash.com/photo-1572286258217-40142c1c6a70?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m4", "Coconut Cold Brew", "Coffee", 49000,
            "Slow-steeped cold brew coffee paired with sweet and aromatic fresh coconut water.",
            Arrays.asList("M", "L"),
            "https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m5", "Peach Tea Lemongrass (Trà Đào Cam Sả)", "Tea", 45000,
            "Refreshing black tea infused with peach syrup, fresh orange juice, and a fragrant stalk of lemongrass.",
            Arrays.asList("M", "L"),
            "https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m6", "Matcha Latte", "Specialty", 49000,
            "Premium Japanese Uji matcha whisked with warm or iced milk and a hint of sweetness.",
            Arrays.asList("S", "M", "L"),
            "https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m7", "Oolong Milk Tea Cordial", "Tea", 45000,
            "Roasted oolong tea leaves blended with gourmet milk powder, topped with cream cheese cap.",
            Arrays.asList("M", "L"),
            "https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m8", "Butter Croissant", "Pastry", 29000,
            "Flaky, buttery, golden French pastry baked fresh daily.",
            Arrays.asList("S"),
            "https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=600&auto=format&fit=crop"
        ));
        list.add(new MenuItem(
            "m9", "Tiramisu Slice", "Pastry", 45000,
            "Espresso-soaked ladyfingers nested in a light and airy mascarpone cream, dusted with cocoa powder.",
            Arrays.asList("S"),
            "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?q=80&w=600&auto=format&fit=crop"
        ));
        return list;
    }
}

