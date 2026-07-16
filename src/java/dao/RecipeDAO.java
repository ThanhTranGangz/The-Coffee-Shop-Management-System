package dao;

import context.DBContext;
import model.RecipeItem;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Access Object for managing recipe items.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class RecipeDAO {
    private List<RecipeItem> fallbackRecipes = createDefaultRecipes();

    public RecipeDAO() {
        ensureRecipeTable();
    }

    /**
     * Retrieves all recipe items for a specific menu item.
     * 
     * @param menuItemId the unique identifier of the menu item
     * @return a list of recipe items
     */
    public List<RecipeItem> getByMenuItemId(String menuItemId) {
        List<RecipeItem> list = new ArrayList<>();
        String sql = "SELECT id, menuItemId, ingredientId, quantity FROM dbo.RecipeItems WHERE menuItemId = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, menuItemId);
            try (ResultSet rs = st.executeQuery()) {
                while (rs.next()) {
                    String id = rs.getString("id");
                    String ingredientId = rs.getString("ingredientId");
                    int quantity = rs.getInt("quantity");
                    
                    list.add(new RecipeItem(id, menuItemId, ingredientId, quantity));
                }
            }
            if (!list.isEmpty()) {
                return list;
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in RecipeDAO.getByMenuItemId(), falling back: " + e.getMessage());
        }
        
        // Fallback
        for (RecipeItem item : getFallbackRecipes()) {
            if (item.getMenuItemId().equals(menuItemId)) {
                list.add(item);
            }
        }
        return list;
    }

    /**
     * Retrieves all recipe items mapped by their menu item id.
     * This avoids N+1 queries when loading the entire menu.
     *
     * @return a map of menu item id to a list of recipe items
     */
    public java.util.Map<String, List<RecipeItem>> getAllRecipesMappedByMenuItemId() {
        java.util.Map<String, List<RecipeItem>> map = new java.util.HashMap<>();
        String sql = "SELECT id, menuItemId, ingredientId, quantity FROM dbo.RecipeItems";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                String menuId = rs.getString("menuItemId");
                RecipeItem item = new RecipeItem(
                    rs.getString("id"), menuId,
                    rs.getString("ingredientId"), rs.getInt("quantity")
                );
                map.computeIfAbsent(menuId, k -> new ArrayList<>()).add(item);
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in RecipeDAO.getAllRecipesMappedByMenuItemId(), falling back: " + e.getMessage());
            for (RecipeItem item : getFallbackRecipes()) {
                map.computeIfAbsent(item.getMenuItemId(), k -> new ArrayList<>()).add(item);
            }
        }
        return map;
    }

    /**
     * Saves (inserts or updates) a list of recipe items for a specific menu item.
     * This will clear existing recipes for the menu item and insert the new ones.
     * 
     * @param menuItemId the unique identifier of the menu item
     * @param items the new list of recipe items
     */
    public void saveForMenuItem(String menuItemId, List<RecipeItem> items) {
        DBContext db = new DBContext();
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                // Delete existing
                String deleteSql = "DELETE FROM dbo.RecipeItems WHERE menuItemId = ?";
                try (PreparedStatement st = con.prepareStatement(deleteSql)) {
                    st.setString(1, menuItemId);
                    st.executeUpdate();
                }

                // Insert new
                if (items != null && !items.isEmpty()) {
                    String insertSql = "INSERT INTO dbo.RecipeItems (id, menuItemId, ingredientId, quantity) VALUES (?, ?, ?, ?)";
                    for (RecipeItem item : items) {
                        try (PreparedStatement st = con.prepareStatement(insertSql)) {
                            String newId = item.getId() != null && !item.getId().isEmpty() ? item.getId() : java.util.UUID.randomUUID().toString();
                            item.setId(newId);
                            item.setMenuItemId(menuItemId); // Ensure consistency
                            
                            st.setString(1, newId);
                            st.setString(2, menuItemId);
                            st.setString(3, item.getIngredientId());
                            st.setInt(4, item.getQuantity());
                            st.executeUpdate();
                        }
                    }
                }
                con.commit();
            } catch (Exception ex) {
                con.rollback();
                throw ex;
            }
        } catch (Exception e) {
            System.err.println("Database save failed in RecipeDAO.saveForMenuItem(), updating fallback list: " + e.getMessage());
        }

        // Update fallback
        List<RecipeItem> fallback = getFallbackRecipes();
        fallback.removeIf(item -> item.getMenuItemId().equals(menuItemId));
        if (items != null) {
            for (RecipeItem item : items) {
                if (item.getId() == null || item.getId().isEmpty()) {
                    item.setId(java.util.UUID.randomUUID().toString());
                }
                item.setMenuItemId(menuItemId);
                fallback.add(item);
            }
        }
    }

    private List<RecipeItem> getFallbackRecipes() {
        if (fallbackRecipes == null) {
            fallbackRecipes = new ArrayList<>();
        }
        return fallbackRecipes;
    }

    /**
     * Kiểm tra và tự động tạo bảng dbo.RecipeItems trong cơ sở dữ liệu nếu bảng này chưa tồn tại.
     * Hàm này giúp hệ thống tự động khởi tạo (auto-migration) mà không cần chạy file SQL thủ công.
     */
    private void ensureRecipeTable() {
        DBContext db = new DBContext();
        // Câu lệnh SQL kiểm tra sự tồn tại của bảng và khởi tạo bảng mới nếu chưa có
        String sql = "IF OBJECT_ID('dbo.RecipeItems','U') IS NULL " +
                     "CREATE TABLE dbo.RecipeItems (" +
                     "id VARCHAR(50) PRIMARY KEY, " +
                     "menuItemId VARCHAR(50) NOT NULL, " +
                     "ingredientId VARCHAR(50) NOT NULL, " +
                     "quantity INT NOT NULL" +
                     ");";
        try (Connection con = db.getConnection();
             Statement st = con.createStatement()) {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("RecipeDAO.ensureRecipeTable skipped: " + e.getMessage());
        }
        // Gọi hàm đổ dữ liệu mặc định ngay sau khi đảm bảo bảng đã được tạo
        seedDefaultRecipesIfEmpty();
    }

    /**
     * Kiểm tra xem bảng dbo.RecipeItems có đang trống không.
     * Nếu bảng trống (chưa có dòng dữ liệu nào), hệ thống sẽ tự động thêm (seed) các công thức cơ bản vào CSDL.
     */
    private void seedDefaultRecipesIfEmpty() {
        DBContext db = new DBContext();
        try (Connection con = db.getConnection(); Statement st = con.createStatement()) {
            // Xóa dữ liệu seed cũ bị lỗi (m1, m2...) nếu có
            st.execute("DELETE FROM dbo.RecipeItems WHERE menuItemId LIKE 'm%'");
            
            String checkSql = "SELECT COUNT(*) AS total FROM dbo.RecipeItems";
            try (ResultSet rs = st.executeQuery(checkSql)) {
                // Nếu có kết quả trả về và số lượng = 0 (bảng trống)
                if (rs.next() && rs.getInt("total") == 0) {
                    
                    // Lấy ID thực tế của các món ăn từ CSDL dựa vào tên tiếng Việt
                    java.util.Map<String, String> menuMap = new java.util.HashMap<>();
                    try (ResultSet rsMenu = st.executeQuery("SELECT id, nameVi FROM dbo.MenuItems")) {
                        while (rsMenu.next()) {
                            menuMap.put(rsMenu.getString("nameVi"), rsMenu.getString("id"));
                        }
                    }
                    
                    // Lấy dữ liệu công thức mặc định và ánh xạ sang ID thực tế
                    List<RecipeItem> defaults = new java.util.ArrayList<>();
                    if (menuMap.containsKey("Cà phê đen")) defaults.add(new RecipeItem("r1", menuMap.get("Cà phê đen"), "i1", 20));
                    if (menuMap.containsKey("Cà phê sữa")) {
                        defaults.add(new RecipeItem("r2", menuMap.get("Cà phê sữa"), "i1", 20));
                        defaults.add(new RecipeItem("r3", menuMap.get("Cà phê sữa"), "i2", 30));
                    }
                    if (menuMap.containsKey("Bạc xỉu")) { // "Cà phê muối" cũ đổi thành Bạc xỉu
                        defaults.add(new RecipeItem("r4", menuMap.get("Bạc xỉu"), "i1", 20));
                        defaults.add(new RecipeItem("r5", menuMap.get("Bạc xỉu"), "i2", 20));
                        defaults.add(new RecipeItem("r6", menuMap.get("Bạc xỉu"), "i4", 50));
                    }
                    if (menuMap.containsKey("Trà đào")) {
                        defaults.add(new RecipeItem("r9", menuMap.get("Trà đào"), "i5", 30));
                        defaults.add(new RecipeItem("r10", menuMap.get("Trà đào"), "i6", 1));
                    }
                    if (menuMap.containsKey("Matcha latte")) {
                        defaults.add(new RecipeItem("r11", menuMap.get("Matcha latte"), "i7", 10));
                        defaults.add(new RecipeItem("r12", menuMap.get("Matcha latte"), "i3", 150));
                    }

                    if (!defaults.isEmpty()) {
                        String insertSql = "INSERT INTO dbo.RecipeItems (id, menuItemId, ingredientId, quantity) VALUES (?, ?, ?, ?)";
                        // Mở transaction để đảm bảo tính toàn vẹn dữ liệu
                        con.setAutoCommit(false);
                        try (PreparedStatement pst = con.prepareStatement(insertSql)) {
                            for (RecipeItem item : defaults) {
                                pst.setString(1, item.getId());
                                pst.setString(2, item.getMenuItemId());
                                pst.setString(3, item.getIngredientId());
                                pst.setInt(4, item.getQuantity());
                                // Thêm vào batch để tối ưu tốc độ insert
                                pst.addBatch();
                            }
                            pst.executeBatch(); // Thực thi lô
                            con.commit(); // Lưu thay đổi
                            System.out.println("RecipeDAO: Seeded default recipes into database.");
                        } catch (Exception e) {
                            con.rollback(); // Hoàn tác nếu xảy ra lỗi
                            throw e;
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("RecipeDAO.seedDefaultRecipesIfEmpty failed: " + e.getMessage());
        }
    }

    private List<RecipeItem> createDefaultRecipes() {
        List<RecipeItem> defaults = new ArrayList<>();
        // m1: Cà phê đen phin
        defaults.add(new RecipeItem("r1", "m1", "i1", 20)); // Hạt cà phê nguyên chất
        // m2: Cà phê sữa đá
        defaults.add(new RecipeItem("r2", "m2", "i1", 20)); // Hạt cà phê nguyên chất
        defaults.add(new RecipeItem("r3", "m2", "i2", 30)); // Sữa đặc
        // m3: Cà phê muối
        defaults.add(new RecipeItem("r4", "m3", "i1", 20)); // Hạt cà phê nguyên chất
        defaults.add(new RecipeItem("r5", "m3", "i2", 20)); // Sữa đặc
        defaults.add(new RecipeItem("r6", "m3", "i4", 50)); // Kem muối
        // m4: Cold brew dừa
        defaults.add(new RecipeItem("r7", "m4", "i1", 15)); // Hạt cà phê nguyên chất
        defaults.add(new RecipeItem("r8", "m4", "i3", 100)); // Sữa tươi (using as substitute since no coconut water in defaults)
        // m5: Trà đào cam sả
        defaults.add(new RecipeItem("r9", "m5", "i5", 30)); // Siro đào
        defaults.add(new RecipeItem("r10", "m5", "i6", 1)); // Sả tươi
        // m6: Matcha latte
        defaults.add(new RecipeItem("r11", "m6", "i7", 10)); // Bột matcha
        defaults.add(new RecipeItem("r12", "m6", "i3", 150)); // Sữa tươi
        // m7: Trà sữa ô long
        defaults.add(new RecipeItem("r13", "m7", "i8", 15)); // Lá trà ô long
        defaults.add(new RecipeItem("r14", "m7", "i3", 100)); // Sữa tươi
        return defaults;
    }
}
