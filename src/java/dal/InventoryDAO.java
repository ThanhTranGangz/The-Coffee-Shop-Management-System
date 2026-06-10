package dal;

import model.Inventory;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class InventoryDAO extends DBContext {

    public List<Inventory> getAllIngredients() {
        List<Inventory> list = new ArrayList<>();
        String sql = "SELECT IngredientID, IngredientName, StockQuantity, MinStockLevel, Unit "
                + "FROM Inventory ORDER BY IngredientID";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Inventory> getLowStockIngredients() {
        List<Inventory> list = new ArrayList<>();
        String sql = "SELECT IngredientID, IngredientName, StockQuantity, MinStockLevel, Unit "
                + "FROM Inventory WHERE StockQuantity <= MinStockLevel ORDER BY StockQuantity ASC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public Inventory getIngredientById(int id) {
        String sql = "SELECT IngredientID, IngredientName, StockQuantity, MinStockLevel, Unit "
                + "FROM Inventory WHERE IngredientID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public boolean createIngredient(Inventory i) {
        String sql = "INSERT INTO Inventory (IngredientName, StockQuantity, MinStockLevel, Unit) VALUES (?,?,?,?)";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, i.getIngredientName());
            ps.setDouble(2, i.getStockQuantity());
            ps.setDouble(3, i.getMinStockLevel());
            ps.setString(4, i.getUnit());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateIngredient(Inventory i) {
        String sql = "UPDATE Inventory SET IngredientName=?, MinStockLevel=?, Unit=? WHERE IngredientID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, i.getIngredientName());
            ps.setDouble(2, i.getMinStockLevel());
            ps.setString(3, i.getUnit());
            ps.setInt(4, i.getIngredientId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean restockIngredient(int id, double qty) {
        String sql = "UPDATE Inventory SET StockQuantity = StockQuantity + ? WHERE IngredientID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setDouble(1, qty);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    /**
     * Trừ kho – nhận Connection chung để dùng trong transaction của AutoDeductionEngine.
     * Ném SQLException với prefix INSUFFICIENT_STOCK nếu không đủ tồn kho.
     */
    public void deductStock(Connection conn, int ingredientId, double qty) throws SQLException {
        PreparedStatement chk = conn.prepareStatement(
                "SELECT StockQuantity FROM Inventory WHERE IngredientID=?");
        chk.setInt(1, ingredientId);
        ResultSet rs = chk.executeQuery();
        if (rs.next()) {
            double cur = rs.getDouble("StockQuantity");
            if (cur < qty) throw new SQLException(
                    "INSUFFICIENT_STOCK:id=" + ingredientId + ",need=" + qty + ",have=" + cur);
        }
        PreparedStatement ps = conn.prepareStatement(
                "UPDATE Inventory SET StockQuantity = StockQuantity - ? WHERE IngredientID=?");
        ps.setDouble(1, qty);
        ps.setInt(2, ingredientId);
        ps.executeUpdate();
    }

    /** Hoàn kho – dùng khi rollback */
    public void addStock(Connection conn, int ingredientId, double qty) throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
                "UPDATE Inventory SET StockQuantity = StockQuantity + ? WHERE IngredientID=?");
        ps.setDouble(1, qty);
        ps.setInt(2, ingredientId);
        ps.executeUpdate();
    }

    private Inventory map(ResultSet rs) throws SQLException {
        return new Inventory(
                rs.getInt("IngredientID"),
                rs.getString("IngredientName"),
                rs.getDouble("StockQuantity"),
                rs.getDouble("MinStockLevel"),
                rs.getString("Unit"));
    }
}
