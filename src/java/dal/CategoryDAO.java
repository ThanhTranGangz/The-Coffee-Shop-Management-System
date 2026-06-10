package dal;

import model.Category;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class CategoryDAO extends DBContext {

    public List<Category> getAllCategories() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT CategoryID, CategoryName FROM Category ORDER BY CategoryID";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next())
                list.add(new Category(rs.getInt("CategoryID"), rs.getString("CategoryName")));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public Category getCategoryById(int id) {
        String sql = "SELECT CategoryID, CategoryName FROM Category WHERE CategoryID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return new Category(rs.getInt("CategoryID"), rs.getString("CategoryName"));
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public boolean createCategory(String name) {
        String sql = "INSERT INTO Category (CategoryName) VALUES (?)";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, name.trim());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateCategory(int id, String name) {
        String sql = "UPDATE Category SET CategoryName=? WHERE CategoryID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, name.trim());
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean deleteCategory(int id) {
        if (hasProducts(id)) return false;
        String sql = "DELETE FROM Category WHERE CategoryID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean hasProducts(int categoryId) {
        String sql = "SELECT COUNT(1) FROM Product WHERE CategoryID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, categoryId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }
}
