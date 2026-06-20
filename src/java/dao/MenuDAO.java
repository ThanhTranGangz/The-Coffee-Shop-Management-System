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
    private List<MenuItem> fallbackMenu = new ArrayList<>();

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
        return fallbackMenu;
    }
}
