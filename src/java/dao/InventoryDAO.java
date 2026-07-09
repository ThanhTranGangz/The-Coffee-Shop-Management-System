package dao;

import context.DBContext;
import model.Ingredient;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Access Object for managing inventory ingredients.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class InventoryDAO {
    private List<Ingredient> fallbackInventory = createDefaultInventory();

    public InventoryDAO() {
        ensureInventoryTable();
    }

    /**
     * Kiểm tra và tự động tạo bảng dbo.Inventory trong cơ sở dữ liệu nếu bảng này chưa tồn tại.
     * Hàm này giúp hệ thống tự động khởi tạo (auto-migration) mà không cần chạy file SQL thủ công.
     */
    private void ensureInventoryTable() {
        DBContext db = new DBContext();
        // Câu lệnh SQL kiểm tra sự tồn tại của bảng và khởi tạo bảng mới nếu chưa có
        String sql = "IF OBJECT_ID('dbo.Inventory','U') IS NULL " +
                     "CREATE TABLE dbo.Inventory (" +
                     "id VARCHAR(50) PRIMARY KEY, " +
                     "name NVARCHAR(120) NOT NULL, " +
                     "unit NVARCHAR(20) NOT NULL, " +
                     "stock INT NOT NULL DEFAULT 0, " +
                     "minStock INT NOT NULL DEFAULT 0, " +
                     "importCost INT NOT NULL DEFAULT 0" +
                     ");";
        try (Connection con = db.getConnection();
             java.sql.Statement st = con.createStatement()) {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("InventoryDAO.ensureInventoryTable skipped: " + e.getMessage());
        }
        // Gọi hàm đổ dữ liệu mặc định ngay sau khi đảm bảo bảng đã được tạo
        seedDefaultInventoryIfEmpty();
    }

    /**
     * Kiểm tra xem bảng dbo.Inventory có đang trống không.
     * Nếu bảng trống (chưa có dòng dữ liệu nào), hệ thống sẽ tự động thêm (seed) các nguyên liệu cơ bản vào CSDL.
     */
    private void seedDefaultInventoryIfEmpty() {
        DBContext db = new DBContext();
        String checkSql = "SELECT COUNT(*) AS total FROM dbo.Inventory";
        try (Connection con = db.getConnection();
             java.sql.Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(checkSql)) {
            
            // Nếu có kết quả trả về và số lượng = 0 (bảng trống)
            if (rs.next() && rs.getInt("total") == 0) {
                List<Ingredient> defaults = createDefaultInventory();
                String insertSql = "INSERT INTO dbo.Inventory (id, name, unit, stock, minStock, importCost) VALUES (?, ?, ?, ?, ?, ?)";
                
                // Mở transaction (setAutoCommit(false)) để đảm bảo nếu insert bị lỗi giữa chừng thì sẽ rollback lại toàn bộ
                con.setAutoCommit(false);
                try (PreparedStatement pst = con.prepareStatement(insertSql)) {
                    for (Ingredient item : defaults) {
                        pst.setString(1, item.getId());
                        pst.setString(2, item.getName());
                        pst.setString(3, item.getUnit());
                        pst.setInt(4, item.getStock());
                        pst.setInt(5, item.getMinStock());
                        pst.setInt(6, item.getImportCost());
                        // Thêm vào batch để gửi nhiều câu lệnh insert lên SQL Server cùng lúc giúp tăng hiệu năng
                        pst.addBatch();
                    }
                    pst.executeBatch(); // Thực thi lô các câu lệnh insert
                    con.commit(); // Lưu thay đổi
                    System.out.println("InventoryDAO: Seeded default ingredients into database.");
                } catch (Exception e) {
                    con.rollback(); // Hoàn tác nếu có lỗi
                    throw e;
                }
            }
        } catch (Exception e) {
            System.err.println("InventoryDAO.seedDefaultInventoryIfEmpty failed: " + e.getMessage());
        }
    }

    /**
     * Retrieves all ingredients from the database or fallback list.
     * 
     * @return a list of all ingredients
     */
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

    /**
     * Retrieves a specific ingredient by its ID.
     * 
     * @param id the unique identifier of the ingredient
     * @return the ingredient if found, null otherwise
     */
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

    /**
     * Saves a new ingredient or updates an existing one in the database.
     * 
     * @param ing the ingredient to save or update
     */
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

    /**
     * Deletes an ingredient from the database by its ID.
     * 
     * @param id the unique identifier of the ingredient to delete
     */
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

    /**
     * Retrieves the fallback memory cache of the inventory.
     * 
     * @return the fallback list of ingredients
     */
    public List<Ingredient> getFallbackInventory() {
        if (fallbackInventory == null || fallbackInventory.isEmpty()) {
            fallbackInventory = createDefaultInventory();
        }
        return fallbackInventory;
    }

    private List<Ingredient> createDefaultInventory() {
        List<Ingredient> defaults = new ArrayList<>();
        defaults.add(new Ingredient("i1", "Hạt cà phê nguyên chất", "g", 1500, 300, 50));
        defaults.add(new Ingredient("i2", "Sữa đặc", "g", 1000, 200, 40));
        defaults.add(new Ingredient("i3", "Sữa tươi", "ml", 2000, 500, 20));
        defaults.add(new Ingredient("i4", "Kem muối", "ml", 600, 150, 80));
        defaults.add(new Ingredient("i5", "Siro đào", "ml", 600, 100, 60));
        defaults.add(new Ingredient("i6", "Sả tươi", "nhánh", 20, 5, 1000));
        defaults.add(new Ingredient("i7", "Bột matcha", "g", 500, 100, 200));
        defaults.add(new Ingredient("i8", "Lá trà ô long", "g", 500, 100, 100));
        defaults.add(new Ingredient("i9", "Vỏ croissant", "cái", 15, 4, 15000));
        defaults.add(new Ingredient("i10", "Bánh tiramisu", "lát", 15, 3, 25000));
        return defaults;
    }
}
