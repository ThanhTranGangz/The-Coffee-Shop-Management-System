package dal;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import model.Category;
import model.MenuItem;
import model.Product;

public class ProductDAO extends DBContext {

    /**
     * Mot mon "con hang" khi Status = 1 va moi nguyen lieu trong cong thuc
     * deu du ton kho cho it nhat 1 phan.
     */
    private static final String AVAILABLE_CASE =
            "CASE WHEN p.[Status] = 0 THEN 0 "
            + "WHEN EXISTS (SELECT 1 FROM Recipe r JOIN Inventory i ON r.IngredientID = i.IngredientID "
            + "             WHERE r.ProductID = p.ProductID AND i.StockQuantity < r.QuantityNeeded) THEN 0 "
            + "ELSE 1 END";

    /** Toan bo menu (ke ca mon het hang de hien thi mo + khoa chon). */
    public List<MenuItem> getMenu(String keyword) {
        List<MenuItem> list = new ArrayList<>();
        String sql = "SELECT p.ProductID, p.ProductName, p.Price, p.ImageURL, p.[Status], "
                + "p.CategoryID, c.CategoryName, " + AVAILABLE_CASE + " AS Available "
                + "FROM Product p JOIN Category c ON p.CategoryID = c.CategoryID ";
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        if (hasKeyword) {
            sql += "WHERE p.ProductName LIKE ? ";
        }
        sql += "ORDER BY c.CategoryID, p.ProductName";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            if (hasKeyword) {
                ps.setString(1, "%" + keyword.trim() + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapMenuItem(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Category> getCategories() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT CategoryID, CategoryName FROM Category ORDER BY CategoryID";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Category c = new Category();
                c.setCategoryId(rs.getInt("CategoryID"));
                c.setCategoryName(rs.getString("CategoryName"));
                list.add(c);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Lay nhanh thong tin (gia, ton kho) cua danh sach mon theo ID - dung khi tinh tien. */
    public Map<Integer, MenuItem> findByIds(List<Integer> ids) {
        Map<Integer, MenuItem> map = new LinkedHashMap<>();
        if (ids == null || ids.isEmpty()) {
            return map;
        }
        StringBuilder in = new StringBuilder();
        for (int i = 0; i < ids.size(); i++) {
            in.append(i == 0 ? "?" : ",?");
        }
        String sql = "SELECT p.ProductID, p.ProductName, p.Price, p.ImageURL, p.[Status], "
                + "p.CategoryID, c.CategoryName, " + AVAILABLE_CASE + " AS Available "
                + "FROM Product p JOIN Category c ON p.CategoryID = c.CategoryID "
                + "WHERE p.ProductID IN (" + in + ")";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < ids.size(); i++) {
                ps.setInt(i + 1, ids.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MenuItem m = mapMenuItem(rs);
                    map.put(m.getProductId(), m);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return map;
    }

    private MenuItem mapMenuItem(ResultSet rs) throws SQLException {
        MenuItem m = new MenuItem();
        m.setProductId(rs.getInt("ProductID"));
        m.setProductName(rs.getString("ProductName"));
        m.setPrice(rs.getInt("Price"));
        m.setImageUrl(rs.getString("ImageURL"));
        m.setStatus(rs.getBoolean("Status"));
        m.setCategoryId(rs.getInt("CategoryID"));
        m.setCategoryName(rs.getString("CategoryName"));
        m.setAvailable(rs.getInt("Available") == 1);
        return m;
    }

    public List<Product> getAllProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT ProductID, ProductName, Price, ImageURL, [Status], CategoryID FROM Product ORDER BY CategoryID, ProductName";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Product(
                        rs.getInt("ProductID"),
                        rs.getString("ProductName"),
                        rs.getInt("Price"),
                        rs.getString("ImageURL"),
                        rs.getBoolean("Status"),
                        rs.getInt("CategoryID")));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Product> searchProducts(String keyword, int categoryId) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT ProductID, ProductName, Price, ImageURL, [Status], CategoryID FROM Product WHERE 1=1";
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql += " AND ProductName LIKE ?";
        }
        if (categoryId > 0) {
            sql += " AND CategoryID = ?";
        }
        sql += " ORDER BY CategoryID, ProductName";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            int paramIndex = 1;
            if (keyword != null && !keyword.trim().isEmpty()) {
                ps.setString(paramIndex++, "%" + keyword.trim() + "%");
            }
            if (categoryId > 0) {
                ps.setInt(paramIndex++, categoryId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Product(
                            rs.getInt("ProductID"),
                            rs.getString("ProductName"),
                            rs.getInt("Price"),
                            rs.getString("ImageURL"),
                            rs.getBoolean("Status"),
                            rs.getInt("CategoryID")));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public Product getProductById(int id) {
        String sql = "SELECT ProductID, ProductName, Price, ImageURL, [Status], CategoryID FROM Product WHERE ProductID = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Product(
                            rs.getInt("ProductID"),
                            rs.getString("ProductName"),
                            rs.getInt("Price"),
                            rs.getString("ImageURL"),
                            rs.getBoolean("Status"),
                            rs.getInt("CategoryID"));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean createProduct(Product p) {
        String sql = "INSERT INTO Product (ProductName, Price, ImageURL, [Status], CategoryID) VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, p.getProductName());
            ps.setInt(2, p.getPrice());
            ps.setString(3, p.getImageUrl());
            ps.setBoolean(4, p.isStatus());
            ps.setInt(5, p.getCategoryId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateProduct(Product p) {
        String sql = "UPDATE Product SET ProductName = ?, Price = ?, ImageURL = ?, [Status] = ?, CategoryID = ? WHERE ProductID = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, p.getProductName());
            ps.setInt(2, p.getPrice());
            ps.setString(3, p.getImageUrl());
            ps.setBoolean(4, p.isStatus());
            ps.setInt(5, p.getCategoryId());
            ps.setInt(6, p.getProductId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean toggleProductStatus(int id) {
        String sql = "UPDATE Product SET [Status] = CASE WHEN [Status] = 1 THEN 0 ELSE 1 END WHERE ProductID = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean hasOrderDetails(int id) {
        String sql = "SELECT TOP 1 1 FROM OrderDetail WHERE ProductID = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteProduct(int id) {
        String sql = "DELETE FROM Product WHERE ProductID = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}
