package dal;

import model.Product;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ProductDAO extends DBContext {

    public List<Product> getAllProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT ProductID, ProductName, Price, ImageURL, Status, CategoryID "
                + "FROM Product ORDER BY ProductID DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapProduct(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Product> searchProducts(String keyword, int categoryId) {
        List<Product> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT ProductID, ProductName, Price, ImageURL, Status, CategoryID "
                + "FROM Product WHERE 1=1 ");
        if (keyword != null && !keyword.trim().isEmpty()) sql.append("AND ProductName LIKE ? ");
        if (categoryId > 0) sql.append("AND CategoryID = ? ");
        sql.append("ORDER BY ProductID DESC");
        try {
            PreparedStatement ps = connection.prepareStatement(sql.toString());
            int idx = 1;
            if (keyword != null && !keyword.trim().isEmpty()) ps.setString(idx++, "%" + keyword.trim() + "%");
            if (categoryId > 0) ps.setInt(idx++, categoryId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapProduct(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public Product getProductById(int productId) {
        String sql = "SELECT ProductID, ProductName, Price, ImageURL, Status, CategoryID "
                + "FROM Product WHERE ProductID = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapProduct(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    /** Dùng bởi ApiCreateOrderServlet / ApiProductsServlet */
    public java.util.Map<Integer, model.MenuItem> findByIds(List<Integer> ids) {
        java.util.Map<Integer, model.MenuItem> map = new java.util.LinkedHashMap<>();
        if (ids == null || ids.isEmpty()) return map;
        StringBuilder sb = new StringBuilder(
                "SELECT ProductID, ProductName, Price, ImageURL, Status, CategoryID FROM Product WHERE ProductID IN (");
        for (int i = 0; i < ids.size(); i++) { if (i > 0) sb.append(','); sb.append('?'); }
        sb.append(')');
        try {
            PreparedStatement ps = connection.prepareStatement(sb.toString());
            for (int i = 0; i < ids.size(); i++) ps.setInt(i + 1, ids.get(i));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                model.MenuItem mi = new model.MenuItem();
                mi.setProductId(rs.getInt("ProductID"));
                mi.setProductName(rs.getString("ProductName"));
                mi.setPrice(rs.getInt("Price"));
                mi.setImageUrl(rs.getString("ImageURL"));
                mi.setAvailable(rs.getBoolean("Status"));
                mi.setCategoryId(rs.getInt("CategoryID"));
                map.put(mi.getProductId(), mi);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return map;
    }

    public boolean createProduct(Product p) {
        String sql = "INSERT INTO Product (ProductName, Price, ImageURL, Status, CategoryID) VALUES (?,?,?,?,?)";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, p.getProductName());
            ps.setInt(2, p.getPrice());
            ps.setString(3, p.getImageUrl());
            ps.setBoolean(4, p.isStatus());
            ps.setInt(5, p.getCategoryId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateProduct(Product p) {
        String sql = "UPDATE Product SET ProductName=?, Price=?, ImageURL=?, Status=?, CategoryID=? WHERE ProductID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, p.getProductName());
            ps.setInt(2, p.getPrice());
            ps.setString(3, p.getImageUrl());
            ps.setBoolean(4, p.isStatus());
            ps.setInt(5, p.getCategoryId());
            ps.setInt(6, p.getProductId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean toggleProductStatus(int productId) {
        String sql = "UPDATE Product SET Status = CASE WHEN Status=1 THEN 0 ELSE 1 END WHERE ProductID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, productId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean deleteProduct(int productId) {
        String sql = "DELETE FROM Product WHERE ProductID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, productId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean hasOrderDetails(int productId) {
        String sql = "SELECT COUNT(1) FROM OrderDetail WHERE ProductID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public List<model.Category> getCategories() {
        return new CategoryDAO().getAllCategories();
    }

    public List<model.MenuItem> getMenu(String keyword) {
        List<model.MenuItem> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT p.ProductID, p.ProductName, p.Price, p.ImageURL, p.Status, p.CategoryID, c.CategoryName, "
                + "(CASE WHEN EXISTS ( "
                + "    SELECT 1 FROM Recipe r JOIN Inventory i ON r.IngredientID = i.IngredientID "
                + "    WHERE r.ProductID = p.ProductID AND i.StockQuantity < r.QuantityNeeded "
                + ") THEN 0 ELSE 1 END) AS IsAvailable "
                + "FROM Product p JOIN Category c ON p.CategoryID = c.CategoryID "
                + "WHERE p.Status = 1 ");
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND p.ProductName LIKE ? ");
        }
        sql.append("ORDER BY c.CategoryID, p.ProductID DESC");
        try {
            PreparedStatement ps = connection.prepareStatement(sql.toString());
            if (keyword != null && !keyword.trim().isEmpty()) {
                ps.setString(1, "%" + keyword.trim() + "%");
            }
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                model.MenuItem mi = new model.MenuItem();
                mi.setProductId(rs.getInt("ProductID"));
                mi.setProductName(rs.getString("ProductName"));
                mi.setPrice(rs.getInt("Price"));
                mi.setImageUrl(rs.getString("ImageURL"));
                mi.setStatus(rs.getBoolean("Status"));
                mi.setCategoryId(rs.getInt("CategoryID"));
                mi.setCategoryName(rs.getString("CategoryName"));
                mi.setAvailable(rs.getInt("IsAvailable") == 1);
                list.add(mi);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    private Product mapProduct(ResultSet rs) throws SQLException {
        Product p = new Product();
        p.setProductId(rs.getInt("ProductID"));
        p.setProductName(rs.getString("ProductName"));
        p.setPrice(rs.getInt("Price"));
        p.setImageUrl(rs.getString("ImageURL"));
        p.setStatus(rs.getBoolean("Status"));
        p.setCategoryId(rs.getInt("CategoryID"));
        return p;
    }
}
