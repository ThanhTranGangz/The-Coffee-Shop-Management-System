package dal;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.Tables;

public class TableDAO extends DBContext {

    /** Tim ban theo ma QR token (in tren ma QR dan tai ban). */
    public Tables findByToken(String token) {
        String sql = "SELECT TableID, TableName, [Status] FROM Tables WHERE QRToken = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapTable(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public Tables findById(int tableId) {
        String sql = "SELECT TableID, TableName, [Status] FROM Tables WHERE TableID = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapTable(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Danh sach ban kem token (dung cho trang in ma QR cua nhan vien). */
    public List<TableWithToken> getAllWithToken() {
        List<TableWithToken> list = new ArrayList<>();
        String sql = "SELECT TableID, TableName, [Status], QRToken FROM Tables ORDER BY TableID";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                TableWithToken t = new TableWithToken();
                t.setTableId(rs.getInt("TableID"));
                t.setTableName(rs.getString("TableName"));
                t.setStatus(rs.getString("Status"));
                t.setQrToken(rs.getString("QRToken"));
                list.add(t);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    private Tables mapTable(ResultSet rs) throws SQLException {
        Tables t = new Tables();
        t.setTableId(rs.getInt("TableID"));
        t.setTableName(rs.getString("TableName"));
        t.setStatus(rs.getString("Status"));
        return t;
    }

    /** Ban + QR token, chi dung noi bo cho trang quan ly. */
    public static class TableWithToken extends Tables {
        private String qrToken;

        public String getQrToken() { return qrToken; }
        public void setQrToken(String qrToken) { this.qrToken = qrToken; }
    }
    
    // Chuyển order từ bàn nguồn sang bàn đích
    public boolean moveTable(String sourceTableId, String targetTableId) {
        String sql = "UPDATE Orders SET TableID=? WHERE TableID=? AND OrderStatus IN ('PENDING','PREPARING','READY')";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, Integer.parseInt(targetTableId.replace("t","")));
            ps.setInt(2, Integer.parseInt(sourceTableId.replace("t","")));
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // Gộp order từ bàn nguồn sang bàn đích
    public boolean mergeTables(String sourceTableId, String targetTableId) {
        // TODO: viết logic gộp order chi tiết hơn
        return true;
    }

    // Checkout bàn: trả bàn về AVAILABLE
    public boolean checkoutTable(int tableId) {
        String sql = "UPDATE Tables SET Status='AVAILABLE', ActiveOrderID=NULL WHERE TableID=?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, tableId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

}
