package dal;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

/**
 * AutoDeductionEngine
 * Tự động trừ kho nguyên liệu khi đơn hàng hoàn tất.
 * Dùng manual transaction để đảm bảo toàn vẹn dữ liệu —
 * rollback toàn bộ nếu bất kỳ nguyên liệu nào không đủ.
 */
public class AutoDeductionEngine extends DBContext {

    private final RecipeDAO    recipeDAO    = new RecipeDAO();
    private final InventoryDAO inventoryDAO = new InventoryDAO();

    /**
     * Trừ kho cho toàn bộ nguyên liệu trong đơn hàng.
     * @param orderId ID đơn đã ở trạng thái COMPLETED / PAID
     */
    public DeductionResult deductStockForOrder(int orderId) {
        List<RecipeDAO.DeductionItem> items = recipeDAO.getDeductionItemsForOrder(orderId);
        if (items.isEmpty())
            return DeductionResult.success("Không có nguyên liệu cần trừ.");

        try {
            connection.setAutoCommit(false);
            for (RecipeDAO.DeductionItem item : items)
                inventoryDAO.deductStock(connection, item.ingredientId, item.totalQty);
            connection.commit();
            return DeductionResult.success("Trừ kho thành công cho đơn #" + orderId);
        } catch (SQLException e) {
            try { connection.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            String msg = e.getMessage();
            if (msg != null && msg.startsWith("INSUFFICIENT_STOCK"))
                return DeductionResult.failure("Không đủ nguyên liệu: " + msg);
            e.printStackTrace();
            return DeductionResult.failure("Lỗi hệ thống: " + msg);
        } finally {
            try { connection.setAutoCommit(true); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    /**
     * Hoàn kho khi đơn bị huỷ sau khi đã trừ kho.
     */
    public DeductionResult rollbackStockForOrder(int orderId) {
        List<RecipeDAO.DeductionItem> items = recipeDAO.getDeductionItemsForOrder(orderId);
        if (items.isEmpty())
            return DeductionResult.success("Không có nguyên liệu cần hoàn kho.");

        try {
            connection.setAutoCommit(false);
            for (RecipeDAO.DeductionItem item : items)
                inventoryDAO.addStock(connection, item.ingredientId, item.totalQty);
            connection.commit();
            return DeductionResult.success("Hoàn kho thành công cho đơn #" + orderId);
        } catch (SQLException e) {
            try { connection.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            e.printStackTrace();
            return DeductionResult.failure("Lỗi hoàn kho: " + e.getMessage());
        } finally {
            try { connection.setAutoCommit(true); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    // ── Result DTO ──────────────────────────────────────────────────────────
    public static class DeductionResult {
        private final boolean success;
        private final String  message;

        private DeductionResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }

        public static DeductionResult success(String msg) { return new DeductionResult(true,  msg); }
        public static DeductionResult failure(String msg) { return new DeductionResult(false, msg); }

        public boolean isSuccess() { return success; }
        public String  getMessage() { return message; }

        @Override
        public String toString() { return (success ? "[OK] " : "[FAIL] ") + message; }
    }
}
