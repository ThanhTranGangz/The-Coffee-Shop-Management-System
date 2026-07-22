package dao;

import context.DBContext;
import model.MenuItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Access Object for managing menu items.
 */
public class MenuDAO {

    public List<MenuItem> getAll() {
        List<MenuItem> menuItems = new ArrayList<>();
        String sql = "SELECT id, nameVi, category, price, imagePath FROM dbo.MenuItems WHERE active = 1";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                int id = rs.getInt("id");
                String name = rs.getString("nameVi");
                String category = rs.getString("category");
                int price = rs.getInt("price");
                String image = rs.getString("imagePath");
                
                List<String> availableSizes = fetchSizes(con, id);
                menuItems.add(new MenuItem(String.valueOf(id), name, category, price, "", availableSizes, image));
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in MenuDAO.getAll(): " + e.getMessage());
        }
        return menuItems;
    }

    public MenuItem getById(String id) {
        if (id == null || id.startsWith("m")) return null; // Legacy IDs won't match integer DB
        String sql = "SELECT id, nameVi, category, price, imagePath FROM dbo.MenuItems WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setInt(1, Integer.parseInt(id));
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    String name = rs.getString("nameVi");
                    String category = rs.getString("category");
                    int price = rs.getInt("price");
                    String image = rs.getString("imagePath");
                    
                    List<String> availableSizes = fetchSizes(con, Integer.parseInt(id));
                    return new MenuItem(String.valueOf(id), name, category, price, "", availableSizes, image);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in MenuDAO.getById(): " + e.getMessage());
        }
        return null;
    }

    public void create(MenuItem item) {
        String sql = "INSERT INTO dbo.MenuItems (nameVi, nameEn, category, price, active, imagePath) VALUES (?, ?, ?, ?, 1, ?)";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            st.setString(1, item.getName());
            st.setString(2, item.getName());
            st.setString(3, item.getCategory());
            st.setInt(4, item.getPrice());
            st.setString(5, item.getImage());
            st.executeUpdate();
            
            try (ResultSet rs = st.getGeneratedKeys()) {
                if (rs.next()) {
                    int newId = rs.getInt(1);
                    item.setId(String.valueOf(newId));
                    saveSizes(con, newId, item.getAvailableSizes());
                }
            }
        } catch (Exception e) {
            throw new IllegalStateException("Không thể thêm món vào cơ sở dữ liệu: " + e.getMessage(), e);
        }
    }

    public void update(MenuItem item) {
        if (item.getId() == null || item.getId().startsWith("m")) return;
        String sql = "UPDATE dbo.MenuItems SET nameVi = ?, nameEn = ?, category = ?, price = ?, imagePath = ?, active = 1 WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {

            st.setString(1, item.getName());
            st.setString(2, item.getName());
            st.setString(3, item.getCategory());
            st.setInt(4, item.getPrice());
            st.setString(5, item.getImage());
            st.setInt(6, Integer.parseInt(item.getId()));
            int rows = st.executeUpdate();
            if (rows == 0) {
                throw new IllegalArgumentException("Không tìm thấy món cần cập nhật.");
            }
            saveSizes(con, Integer.parseInt(item.getId()), item.getAvailableSizes());
        } catch (Exception e) {
            throw new IllegalStateException("Không thể cập nhật món: " + e.getMessage(), e);
        }
    }

    public void delete(String id) {
        if (id == null || id.startsWith("m")) return;
        String sql = "UPDATE dbo.MenuItems SET active = 0 WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setInt(1, Integer.parseInt(id));
            int rows = st.executeUpdate();
            if (rows == 0) {
                throw new IllegalArgumentException("Không tìm thấy món cần xoá.");
            }
        } catch (Exception e) {
            throw new IllegalStateException("Không thể xoá món: " + e.getMessage(), e);
        }
    }

    private List<String> fetchSizes(Connection con, int menuItemId) {
        List<String> sizes = new ArrayList<>();
        String sql = "SELECT sizeName FROM dbo.MenuItemSizes WHERE menuItemId = ? ORDER BY sortOrder, id";
        try (PreparedStatement st = con.prepareStatement(sql)) {
            st.setInt(1, menuItemId);
            try (ResultSet rs = st.executeQuery()) {
                while (rs.next()) {
                    sizes.add(rs.getString(1));
                }
            }
        } catch (Exception e) {
            // ignore
        }
        if (sizes.isEmpty()) sizes.add("M");
        return sizes;
    }
    
    private void saveSizes(Connection con, int menuItemId, List<String> sizes) {
        if (sizes == null || sizes.isEmpty()) return;
        try {
            try (PreparedStatement del = con.prepareStatement("DELETE FROM dbo.MenuItemSizes WHERE menuItemId = ?")) {
                del.setInt(1, menuItemId);
                del.executeUpdate();
            }
            try (PreparedStatement ins = con.prepareStatement("INSERT INTO dbo.MenuItemSizes (menuItemId, sizeName, extraPrice, sortOrder) VALUES (?, ?, 0, ?)")) {
                int order = 0;
                for (String size : sizes) {
                    if (size == null || size.trim().isEmpty()) continue;
                    ins.setInt(1, menuItemId);
                    ins.setString(2, size.trim());
                    ins.setInt(3, order++);
                    ins.addBatch();
                }
                ins.executeBatch();
            }
        } catch (Exception e) {
            // ignore
        }
    }
}
