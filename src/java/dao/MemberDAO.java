package dal;

import model.Member;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class MemberDAO extends DBContext {

    public Member findByPhone(String phone) {
        String sql = "SELECT m.MemberID, m.FullName, m.Phone, m.RewardPoints, "
                + "m.TierID, t.TierName, m.IsActive "
                + "FROM Member m "
                + "JOIN Tier t ON m.TierID = t.TierID "
                + "WHERE m.Phone = ? AND m.IsActive = 1";

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

            PreparedStatement ps1 = connection.prepareStatement(updatePointSql);
            ps1.setInt(1, points);
            ps1.setInt(2, memberID);
            ps1.executeUpdate();

            PreparedStatement ps2 = connection.prepareStatement(insertHistorySql);
            ps2.setInt(1, memberID);

            if (orderID == null) {
                ps2.setNull(2, java.sql.Types.INTEGER);
            } else {
                ps2.setInt(2, orderID);
            }

            ps2.setInt(3, points);
            ps2.setString(4, reason);
            ps2.executeUpdate();

            PreparedStatement ps3 = connection.prepareStatement(updateTierSql);
            ps3.setInt(1, memberID);
            ps3.setInt(2, memberID);
            ps3.executeUpdate();

            connection.commit();
            connection.setAutoCommit(true);

            return true;

        } catch (SQLException e) {
            try {
                connection.rollback();
                connection.setAutoCommit(true);
            } catch (SQLException ex) {
                ex.printStackTrace();
            }

            e.printStackTrace();
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
        member.setActive(rs.getBoolean("IsActive"));

        return member;
    }
}