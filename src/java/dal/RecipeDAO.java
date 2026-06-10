package dal;

import model.Recipe;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class RecipeDAO extends DBContext {

    public List<Recipe> getRecipeByProduct(int productId) {
        List<Recipe> list = new ArrayList<>();
        String sql = "SELECT ProductID, IngredientID, QuantityNeeded FROM Recipe WHERE ProductID=?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();
            while (rs.next())
                list.add(new Recipe(rs.getInt("ProductID"), rs.getInt("IngredientID"), rs.getDouble("QuantityNeeded")));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Lưu công thức: xóa cũ → insert mới trong một transaction.
     */
    public boolean saveRecipe(int productId, List<Recipe> ingredients) {
        try {
            connection.setAutoCommit(false);

            PreparedStatement del = connection.prepareStatement("DELETE FROM Recipe WHERE ProductID=?");
            del.setInt(1, productId);
            del.executeUpdate();

            for (Recipe r : ingredients) {
                PreparedStatement ins = connection.prepareStatement(
                        "INSERT INTO Recipe (ProductID, IngredientID, QuantityNeeded) VALUES (?,?,?)");
                ins.setInt(1, productId);
                ins.setInt(2, r.getIngredientId());
                ins.setDouble(3, r.getQuantityNeeded());
                ins.executeUpdate();
            }
            connection.commit();
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            try { connection.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
        } finally {
            try { connection.setAutoCommit(true); } catch (SQLException e) { e.printStackTrace(); }
        }
        return false;
    }

    /**
     * Tính tổng nguyên liệu cần trừ cho một đơn hàng.
     * Dùng bởi AutoDeductionEngine.
     */
    public List<DeductionItem> getDeductionItemsForOrder(int orderId) {
        List<DeductionItem> list = new ArrayList<>();
        String sql = "SELECT r.IngredientID, SUM(r.QuantityNeeded * od.Quantity) AS TotalQty "
                + "FROM OrderDetail od JOIN Recipe r ON od.ProductID=r.ProductID "
                + "WHERE od.OrderID=? GROUP BY r.IngredientID";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, orderId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                DeductionItem di = new DeductionItem();
                di.ingredientId = rs.getInt("IngredientID");
                di.totalQty     = rs.getDouble("TotalQty");
                list.add(di);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ── Inner DTOs ──────────────────────────────────────────────────────────
    public static class DeductionItem {
        public int    ingredientId;
        public double totalQty;
    }
}
