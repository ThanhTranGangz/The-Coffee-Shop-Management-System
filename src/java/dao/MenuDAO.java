package dao;

import context.DBContext;
import model.MenuItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class MenuDAO {
    private List<MenuItem> fallbackMenu = createDefaultMenu();

    public MenuDAO() {
        ensureMenuColumns();
    }

    public List<MenuItem> getAll() {
        ensureMenuColumns();
        List<MenuItem> menuItems = new ArrayList<>();
        String sql = "SELECT id, name, category, price, description, availableSizes, image FROM dbo.MenuItems WHERE active = 1";
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
        ensureMenuColumns();
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

    public void create(MenuItem item) {
        ensureMenuColumns();
        String sql = "INSERT INTO dbo.MenuItems (id, name, category, price, description, availableSizes, image, active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {

            st.setString(1, item.getId());
            st.setString(2, item.getName());
            st.setString(3, item.getCategory());
            st.setInt(4, item.getPrice());
            st.setString(5, item.getDescription());
            st.setString(6, joinSizes(item.getAvailableSizes()));
            st.setString(7, item.getImage());
            st.executeUpdate();
            fallbackMenu.add(item);
        } catch (Exception e) {
            throw new IllegalStateException("Không thể thêm món vào cơ sở dữ liệu: " + e.getMessage(), e);
        }
    }

    public void update(MenuItem item) {
        ensureMenuColumns();
        String sql = "UPDATE dbo.MenuItems SET name = ?, category = ?, price = ?, description = ?, availableSizes = ?, image = ?, active = 1 WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {

            st.setString(1, item.getName());
            st.setString(2, item.getCategory());
            st.setInt(3, item.getPrice());
            st.setString(4, item.getDescription());
            st.setString(5, joinSizes(item.getAvailableSizes()));
            st.setString(6, item.getImage());
            st.setString(7, item.getId());
            int rows = st.executeUpdate();
            if (rows == 0) {
                throw new IllegalArgumentException("Không tìm thấy món cần cập nhật.");
            }
            saveFallback(item);
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Không thể cập nhật món: " + e.getMessage(), e);
        }
    }

    public void delete(String id) {
        ensureMenuColumns();
        String sql = "UPDATE dbo.MenuItems SET active = 0 WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, id);
            int rows = st.executeUpdate();
            if (rows == 0) {
                throw new IllegalArgumentException("Không tìm thấy món cần xoá.");
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Không thể xoá món: " + e.getMessage(), e);
        }
        getFallbackMenu().removeIf(item -> item.getId().equals(id));
    }

    private String joinSizes(List<String> sizes) {
        if (sizes == null || sizes.isEmpty()) {
            return "M";
        }
        return sizes.stream()
                .filter(size -> size != null && !size.trim().isEmpty())
                .map(String::trim)
                .collect(Collectors.joining(","));
    }

    private List<MenuItem> getFallbackMenu() {
        if (fallbackMenu == null || fallbackMenu.isEmpty()) {
            fallbackMenu = createDefaultMenu();
        }
        return fallbackMenu;
    }

    private void saveFallback(MenuItem item) {
        List<MenuItem> current = getFallbackMenu();
        int idx = -1;
        for (int i = 0; i < current.size(); i++) {
            if (current.get(i).getId().equals(item.getId())) {
                idx = i;
                break;
            }
        }
        if (idx >= 0) {
            current.set(idx, item);
        } else {
            current.add(item);
        }
    }

    private void ensureMenuColumns() {
        DBContext db = new DBContext();
        String sql = "IF COL_LENGTH('dbo.MenuItems', 'active') IS NULL " +
                     "ALTER TABLE dbo.MenuItems ADD active BIT NOT NULL CONSTRAINT DF_MenuItems_active DEFAULT 1;";
        try (Connection con = db.getConnection();
             Statement st = con.createStatement()) {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("MenuDAO.ensureMenuColumns skipped: " + e.getMessage());
        }
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
