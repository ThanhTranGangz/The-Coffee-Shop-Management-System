package dao;

import context.DBContext;
import model.Member;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class MemberDAO {
    private List<Member> fallbackMembers = new ArrayList<>();

    public List<Member> getAll() {
        List<Member> list = new ArrayList<>();
        String sql = "SELECT phone, name, rank, points, email, pref, discount FROM dbo.Members";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                list.add(new Member(
                    rs.getString("phone"),
                    rs.getString("name"),
                    rs.getString("rank"),
                    rs.getInt("points"),
                    rs.getString("email"),
                    rs.getString("pref"),
                    rs.getString("discount")
                ));
            }
            // Sync fallback memory context
            fallbackMembers = new ArrayList<>(list);
        } catch (Exception e) {
            System.err.println("Database fetch failed in MemberDAO.getAll(), falling back to cache: " + e.getMessage());
            return getFallbackMembers();
        }
        
        if (list.isEmpty()) {
            return getFallbackMembers();
        }
        return list;
    }

    public Member getByPhone(String phone) {
        String sql = "SELECT phone, name, rank, points, email, pref, discount FROM dbo.Members WHERE phone=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, phone);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    return new Member(
                        rs.getString("phone"),
                        rs.getString("name"),
                        rs.getString("rank"),
                        rs.getInt("points"),
                        rs.getString("email"),
                        rs.getString("pref"),
                        rs.getString("discount")
                    );
                }
            }
        } catch (Exception e) {
            System.err.println("Database getByPhone failed in MemberDAO.getByPhone(), searching cached fallback...");
        }

        return getFallbackMembers().stream()
                .filter(m -> m.getPhone().equals(phone))
                .findFirst()
                .orElse(null);
    }

    public void save(Member member) {
        String sql = "INSERT INTO dbo.Members (phone, name, rank, points, email, pref, discount) VALUES (?, ?, ?, ?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE name=?, rank=?, points=?, email=?, pref=?, discount=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, member.getPhone());
            st.setString(2, member.getName());
            st.setString(3, member.getRank());
            st.setInt(4, member.getPoints());
            st.setString(5, member.getEmail());
            st.setString(6, member.getPref());
            st.setString(7, member.getDiscount());
            
            st.setString(8, member.getName());
            st.setString(9, member.getRank());
            st.setInt(10, member.getPoints());
            st.setString(11, member.getEmail());
            st.setString(12, member.getPref());
            st.setString(13, member.getDiscount());
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database save failed in MemberDAO.save(), updating memory fallback...");
        }

        // Keep fallback context updated
        List<Member> current = getFallbackMembers();
        int idx = -1;
        for (int i = 0; i < current.size(); i++) {
            if (current.get(i).getPhone().equals(member.getPhone())) {
                idx = i;
                break;
            }
        }
        if (idx != -1) {
            current.set(idx, member);
        } else {
            current.add(member);
        }
    }

    public void delete(String phone) {
        String sql = "DELETE FROM dbo.Members WHERE phone=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, phone);
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database delete failed in MemberDAO.delete()");
        }
        getFallbackMembers().removeIf(m -> m.getPhone().equals(phone));
    }

    public List<Member> getFallbackMembers() {
        return fallbackMembers;
    }
}
