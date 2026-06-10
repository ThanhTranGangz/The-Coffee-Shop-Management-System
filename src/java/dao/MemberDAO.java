package dal;

import model.Member;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class MemberDAO extends DBContext {

    private static final String BASE_SELECT =
            "SELECT m.MemberID, m.FullName, m.Phone, m.RewardPoints, "
            + "m.TierID, t.TierName, t.DiscountPercent, m.IsActive "
            + "FROM Member m "
            + "JOIN Tier t ON m.TierID = t.TierID ";

    public Member findByPhone(String phone) {
        String sql = BASE_SELECT + "WHERE m.Phone = ? AND m.IsActive = 1";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setString(1, phone);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return mapMember(rs);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    /** Dang nhap thanh vien bang so dien thoai + mat khau (da hash SHA-256). */
    public Member loginByPhonePassword(String phone, String passwordHash) {
        String sql = BASE_SELECT
                + "WHERE m.Phone = ? AND m.PasswordHash = ? AND m.IsActive = 1";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, phone);
            ps.setString(2, passwordHash);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapMember(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Lay lai thong tin moi nhat (diem, hang) cua thanh vien. */
    public Member findById(int memberId) {
        String sql = BASE_SELECT + "WHERE m.MemberID = ? AND m.IsActive = 1";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapMember(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Dang ky thanh vien moi (hang Bronze).
     *
     * @return Member vua tao, hoac null neu so dien thoai da ton tai / loi
     */
    public Member register(String fullName, String phone, String passwordHash) {
        String checkSql = "SELECT 1 FROM Member WHERE Phone = ?";
        String insertSql = "INSERT INTO Member (FullName, Phone, RewardPoints, TierID, IsActive, PasswordHash) "
                + "VALUES (?, ?, 0, 1, 1, ?)";
        try {
            try (PreparedStatement ps = connection.prepareStatement(checkSql)) {
                ps.setString(1, phone);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return null; // da co tai khoan voi SDT nay
                    }
                }
            }
            try (PreparedStatement ps = connection.prepareStatement(insertSql)) {
                ps.setNString(1, fullName);
                ps.setString(2, phone);
                ps.setString(3, passwordHash);
                ps.executeUpdate();
            }
            return findByPhone(phone);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean addRewardPoints(int memberID, Integer orderID, int points, String reason) {
        String updatePointSql = "UPDATE Member "
                + "SET RewardPoints = RewardPoints + ? "
                + "WHERE MemberID = ? AND IsActive = 1";

        String insertHistorySql = "INSERT INTO RewardPointTransaction "
                + "(MemberID, OrderID, PointsChanged, Reason) "
                + "VALUES (?, ?, ?, ?)";

        String updateTierSql = "UPDATE Member "
                + "SET TierID = ( "
                + "SELECT TOP 1 TierID FROM Tier "
                + "WHERE MinPoints <= (SELECT RewardPoints FROM Member WHERE MemberID = ?) "
                + "ORDER BY MinPoints DESC "
                + ") "
                + "WHERE MemberID = ?";

        try {
            connection.setAutoCommit(false);

            try (PreparedStatement ps1 = connection.prepareStatement(updatePointSql); PreparedStatement ps2 = connection.prepareStatement(insertHistorySql); PreparedStatement ps3 = connection.prepareStatement(updateTierSql)) {

                ps1.setInt(1, points);
                ps1.setInt(2, memberID);

                int updatedRows = ps1.executeUpdate();

                if (updatedRows == 0) {
                    connection.rollback();
                    return false;
                }

                ps2.setInt(1, memberID);

                if (orderID == null) {
                    ps2.setNull(2, java.sql.Types.INTEGER);
                } else {
                    ps2.setInt(2, orderID);
                }

                ps2.setInt(3, points);
                ps2.setString(4, reason);
                ps2.executeUpdate();

                ps3.setInt(1, memberID);
                ps3.setInt(2, memberID);
                ps3.executeUpdate();

                connection.commit();
                return true;
            }

        } catch (SQLException e) {
            try {
                connection.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }

            e.printStackTrace();
        } finally {
            try {
                connection.setAutoCommit(true);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        return false;
    }

    private Member mapMember(ResultSet rs) throws SQLException {
        Member member = new Member();

        member.setMemberID(rs.getInt("MemberID"));
        member.setFullName(rs.getString("FullName"));
        member.setPhone(rs.getString("Phone"));
        member.setRewardPoints(rs.getInt("RewardPoints"));
        member.setTierID(rs.getInt("TierID"));
        member.setTierName(rs.getString("TierName"));
        member.setTierDiscountPercent(rs.getInt("DiscountPercent"));
        member.setActive(rs.getBoolean("IsActive"));

        return member;
    }
}
