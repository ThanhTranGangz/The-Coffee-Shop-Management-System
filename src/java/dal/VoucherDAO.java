package dal;

import model.Voucher;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class VoucherDAO extends DBContext {

    /**
     * Cac uu dai con hieu luc ma khach/thanh vien duoc dung
     * (tierId = 0 cho khach vang lai -> chi thay voucher cong khai).
     */
    public List<Voucher> findAvailableForTier(int tierId) {
        List<Voucher> list = new ArrayList<>();
        String sql = "SELECT VoucherID, VoucherCode, DiscountAmount, DiscountPercent, "
                + "MinTierRequired, ExpiryDate, IsActive "
                + "FROM Voucher "
                + "WHERE IsActive = 1 AND ExpiryDate >= GETDATE() "
                + "AND (MinTierRequired IS NULL OR MinTierRequired <= ?) "
                + "ORDER BY CASE WHEN MinTierRequired IS NULL THEN 1 ELSE 0 END, VoucherCode";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, tierId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Voucher v = new Voucher();
                    v.setVoucherID(rs.getInt("VoucherID"));
                    v.setVoucherCode(rs.getString("VoucherCode"));
                    int amount = rs.getInt("DiscountAmount");
                    v.setDiscountAmount(rs.wasNull() ? null : amount);
                    int percent = rs.getInt("DiscountPercent");
                    v.setDiscountPercent(rs.wasNull() ? null : percent);
                    int tier = rs.getInt("MinTierRequired");
                    v.setMinTierRequired(rs.wasNull() ? null : tier);
                    v.setExpiryDate(rs.getTimestamp("ExpiryDate"));
                    v.setActive(rs.getBoolean("IsActive"));
                    list.add(v);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public Voucher findValidVoucher(String voucherCode, int memberTierID) {
        String sql = "SELECT VoucherID, VoucherCode, DiscountAmount, DiscountPercent, "
                + "MinTierRequired, ExpiryDate, IsActive "
                + "FROM Voucher "
                + "WHERE VoucherCode = ? "
                + "AND IsActive = 1 "
                + "AND ExpiryDate >= GETDATE() "
                + "AND (MinTierRequired IS NULL OR MinTierRequired <= ?)";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, voucherCode);
            ps.setInt(2, memberTierID);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Voucher voucher = new Voucher();

                    voucher.setVoucherID(rs.getInt("VoucherID"));
                    voucher.setVoucherCode(rs.getString("VoucherCode"));

                    int amount = rs.getInt("DiscountAmount");
                    voucher.setDiscountAmount(rs.wasNull() ? null : amount);

                    int percent = rs.getInt("DiscountPercent");
                    voucher.setDiscountPercent(rs.wasNull() ? null : percent);

                    int tier = rs.getInt("MinTierRequired");
                    voucher.setMinTierRequired(rs.wasNull() ? null : tier);

                    voucher.setExpiryDate(rs.getTimestamp("ExpiryDate"));
                    voucher.setActive(rs.getBoolean("IsActive"));

                    return voucher;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    public int calculateDiscount(int totalAmount, Voucher voucher) {
        if (totalAmount <= 0) {
            return 0;
        }

        if (voucher == null) {
            return 0;
        }

        if (voucher.getDiscountAmount() != null) {
            int discountAmount = voucher.getDiscountAmount();

            if (discountAmount <= 0) {
                return 0;
            }

            return Math.min(discountAmount, totalAmount);
        }

        if (voucher.getDiscountPercent() != null) {
            int discountPercent = voucher.getDiscountPercent();

            if (discountPercent <= 0) {
                return 0;
            }

            if (discountPercent > 100) {
                discountPercent = 100;
            }

            long discount = (long) totalAmount * discountPercent / 100;

            return (int) Math.min(discount, totalAmount);
        }

        return 0;
    }
}
