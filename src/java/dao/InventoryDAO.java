package dao;

import context.DBContext;
import model.Ingredient;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class InventoryDAO {
    private List<Ingredient> fallbackInventory = new ArrayList<>();

    public List<Ingredient> getAll() {
        List<Ingredient> list = new ArrayList<>();
        String sql = "SELECT id, name, unit, stock, minStock, importCost FROM dbo.Inventory";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                String id = rs.getString("id");
                String name = rs.getString("name");
                String unit = rs.getString("unit");
                int stock = rs.getInt("stock");
                int minStock = rs.getInt("minStock");
                int importCost = rs.getInt("importCost");
                
                list.add(new Ingredient(id, name, unit, stock, minStock, importCost));
            }
            // Sync fallback to the database contents
            fallbackInventory = new ArrayList<>(list);
        } catch (Exception e) {
            System.err.println("Database fetch failed in InventoryDAO.getAll(), falling back to synced list: " + e.getMessage());
            return getFallbackInventory();
        }
        
        if (list.isEmpty()) {
            return getFallbackInventory();
        }
        return list;
    }

    public Ingredient getById(String id) {
        String sql = "SELECT id, name, unit, stock, minStock, importCost FROM dbo.Inventory WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, id);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    String name = rs.getString("name");
                    String unit = rs.getString("unit");
                    int stock = rs.getInt("stock");
                    int minStock = rs.getInt("minStock");
                    int importCost = rs.getInt("importCost");
                    
                    return new Ingredient(id, name, unit, stock, minStock, importCost);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in InventoryDAO.getById(), searching cached fallback context...");
        }
        
        return getFallbackInventory().stream()
                .filter(i -> i.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    public void save(Ingredient ing) {
        DBContext db = new DBContext();
        boolean exists = false;
        String checkSql = "SELECT COUNT(*) FROM dbo.Inventory WHERE id = ?";
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(checkSql)) {
            st.setString(1, ing.getId());
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    exists = true;
                }
            }
        } catch (Exception e) {
            System.err.println("Database save check failed in InventoryDAO: " + e.getMessage());
        }

        if (exists) {
            String updateSql = "UPDATE dbo.Inventory SET name = ?, unit = ?, stock = ?, minStock = ?, importCost = ? WHERE id = ?";
            try (Connection con = db.getConnection();
                 PreparedStatement st = con.prepareStatement(updateSql)) {
                st.setString(1, ing.getName());
                st.setString(2, ing.getUnit());
                st.setInt(3, ing.getStock());
                st.setInt(4, ing.getMinStock());
                st.setInt(5, ing.getImportCost());
                st.setString(6, ing.getId());
                st.executeUpdate();
            } catch (Exception e) {
                System.err.println("Database update in InventoryDAO.save() failed: " + e.getMessage());
            }
        } else {
            String insertSql = "INSERT INTO dbo.Inventory (id, name, unit, stock, minStock, importCost) VALUES (?, ?, ?, ?, ?, ?)";
            try (Connection con = db.getConnection();
                 PreparedStatement st = con.prepareStatement(insertSql)) {
                st.setString(1, ing.getId());
                st.setString(2, ing.getName());
                st.setString(3, ing.getUnit());
                st.setInt(4, ing.getStock());
                st.setInt(5, ing.getMinStock());
                st.setInt(6, ing.getImportCost());
                st.executeUpdate();
            } catch (Exception e) {
                System.err.println("Database insert in InventoryDAO.save() failed: " + e.getMessage());
            }
        }

        // Maintain fallback list in memory
        List<Ingredient> current = getFallbackInventory();
        int idx = -1;
        for (int i = 0; i < current.size(); i++) {
            if (current.get(i).getId().equals(ing.getId())) {
                idx = i;
                break;
            }
        }
        if (idx != -1) {
            current.set(idx, ing);
        } else {
            current.add(ing);
        }
    }

    public void delete(String id) {
        String sql = "DELETE FROM dbo.Inventory WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, id);
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database delete failed in InventoryDAO.delete(): " + e.getMessage());
        }
        getFallbackInventory().removeIf(i -> i.getId().equals(id));
    }

    public List<Ingredient> getFallbackInventory() {
        return fallbackInventory;
    }
}
