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
    private List<MenuItem> fallbackMenu = createDefaultMenu();

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
            // Sync fallback memory context
            fallbackMenu = new ArrayList<>(menuItems);
        } catch (Exception e) {
            System.err.println("Database fetch failed in MenuDAO.getAll(), using cached fallback: " + e.getMessage());
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
            System.err.println("Database fetch failed in MenuDAO.getById(), searching cached fallback...");
        }
        
        return getFallbackMenu().stream()
                .filter(item -> item.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    private List<MenuItem> getFallbackMenu() {
        if (fallbackMenu == null || fallbackMenu.isEmpty()) {
            fallbackMenu = createDefaultMenu();
        }
        return fallbackMenu;
    }

    private List<MenuItem> createDefaultMenu() {
        List<MenuItem> defaults = new ArrayList<>();
        defaults.add(new MenuItem("m1", "Cà phê đen phin", "Coffee", 29000, "Cà phê Việt rang đậm, pha phin.", Arrays.asList("S", "M", "L"), "https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m2", "Cà phê sữa đá", "Coffee", 35000, "Cà phê phin cùng sữa đặc và đá.", Arrays.asList("S", "M", "L"), "https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m3", "Cà phê muối", "Coffee", 45000, "Cà phê sữa phủ kem muối béo nhẹ.", Arrays.asList("S", "M"), "https://images.unsplash.com/photo-1572286258217-40142c1c6a70?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m4", "Cold brew dừa", "Coffee", 49000, "Cold brew dịu vị cùng nước dừa tươi.", Arrays.asList("M", "L"), "https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m5", "Trà đào cam sả", "Tea", 45000, "Trà đen, đào, cam tươi và sả thơm.", Arrays.asList("M", "L"), "https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m6", "Matcha latte", "Specialty", 49000, "Matcha Nhật pha cùng sữa tươi.", Arrays.asList("S", "M", "L"), "https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m7", "Trà sữa ô long", "Tea", 45000, "Ô long rang thơm cùng sữa béo.", Arrays.asList("M", "L"), "https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m8", "Croissant bơ", "Pastry", 29000, "Bánh sừng bò nướng giòn, thơm bơ.", Arrays.asList("S"), "https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=600&auto=format&fit=crop"));
        defaults.add(new MenuItem("m9", "Tiramisu", "Pastry", 45000, "Bánh mascarpone, cà phê và cacao.", Arrays.asList("S"), "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?q=80&w=600&auto=format&fit=crop"));
        return defaults;
    }
}
