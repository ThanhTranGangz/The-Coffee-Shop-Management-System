package dal;

import model.Voucher;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class VoucherDAO extends DBContext {

    public Voucher findValidVoucher(String voucherCode, int memberTierID) {
        String sql = "SELECT VoucherID, VoucherCode, DiscountAmount, DiscountPercent, "
                + "MinTierRequired, ExpiryDate, IsActive "
                + "FROM Voucher "
                + "WHERE VoucherCode = ? "
                + "AND IsActive = 1 "
                + "AND ExpiryDate >= GETDATE() "
                + "AND (MinTierRequired IS NULL OR MinTierRequired <= ?)";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setString(1, voucherCode);
            ps.setInt(2, memberTierID);

            ResultSet rs = ps.executeQuery();

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

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    public int calculateDiscount(int totalAmount, Voucher voucher) {
        if (voucher == null) {
            return 0;
        }

        if (voucher.getDiscountAmount() != null) {
            return Math.min(voucher.getDiscountAmount(), totalAmount);
        }

        if (voucher.getDiscountPercent() != null) {
            return totalAmount * voucher.getDiscountPercent() / 100;
        }

        return 0;
    }
}