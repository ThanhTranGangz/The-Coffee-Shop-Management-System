package dal;

import model.MenuItem;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class MenuDAO extends DBContext {

    // Lấy toàn bộ menu hiển thị cho khách hàng
    public List<MenuItem> getAllMenuItems() {
        List<MenuItem> list = new ArrayList<>();
        String sql = "SELECT p.ProductID, p.ProductName, p.Price, c.CategoryName, "
                   + "CASE WHEN p.Stock > 0 THEN 1 ELSE 0 END AS Available "
                   + "FROM Product p "
                   + "JOIN Category c ON p.CategoryID = c.CategoryID "
                   + "ORDER BY c.CategoryName, p.ProductName";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                MenuItem item = new MenuItem();
                item.setProductName(rs.getString("ProductName"));
                item.setPrice(rs.getInt("Price"));
                item.setCategoryName(rs.getString("CategoryName"));
                item.setAvailable(rs.getBoolean("Available"));
                list.add(item);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    // Lấy menu theo danh mục
    public List<MenuItem> getMenuByCategory(int categoryID) {
        List<MenuItem> list = new ArrayList<>();
        String sql = "SELECT p.ProductID, p.ProductName, p.Price, c.CategoryName, "
                   + "CASE WHEN p.Stock > 0 THEN 1 ELSE 0 END AS Available "
                   + "FROM Product p "
                   + "JOIN Category c ON p.CategoryID = c.CategoryID "
                   + "WHERE c.CategoryID = ?";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, categoryID);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                MenuItem item = new MenuItem();
                item.setProductName(rs.getString("ProductName"));
                item.setPrice(rs.getInt("Price"));
                item.setCategoryName(rs.getString("CategoryName"));
                item.setAvailable(rs.getBoolean("Available"));
                list.add(item);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    // Cập nhật trạng thái còn hàng (ví dụ khi hết nguyên liệu)
    public boolean updateAvailability(int productID, boolean available) {
        String sql = "UPDATE Product SET Stock = ? WHERE ProductID = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, available ? 1 : 0); // giả sử Stock=0 là hết hàng
            ps.setInt(2, productID);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}
