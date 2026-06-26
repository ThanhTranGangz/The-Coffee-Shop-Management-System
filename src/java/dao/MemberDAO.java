package dao;

import context.DBContext;
import model.Member;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Access Object for managing members.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class MemberDAO {
    private List<Member> fallbackMembers = new ArrayList<>();

    /**
     * Retrieves all members from the database or fallback list.
     * 
     * @return a list of all members
     */
    public List<Member> getAll() {
        ensureMemberColumns();
        List<Member> list = new ArrayList<>();
        String sql = "SELECT phone, name, rank, points, email, pref, discount, vouchers FROM dbo.Members";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                list.add(readMember(rs));
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

    /**
     * Retrieves a specific member by their phone number.
     * 
     * @param phone the phone number of the member
     * @return the member if found, null otherwise
     */
    public Member getByPhone(String phone) {
        ensureMemberColumns();
        String sql = "SELECT phone, name, rank, points, email, pref, discount, vouchers FROM dbo.Members WHERE phone=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, phone);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    return readMember(rs);
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

    /**
     * Saves a new member or updates an existing one in the database.
     * 
     * @param member the member to save or update
     */
    public void save(Member member) {
        ensureMemberColumns();
        String sql = "MERGE dbo.Members AS target " +
                     "USING (SELECT ? AS phone, ? AS name, ? AS rank, ? AS points, ? AS email, ? AS pref, ? AS discount, ? AS vouchers) AS source " +
                     "ON target.phone = source.phone " +
                     "WHEN MATCHED THEN UPDATE SET name = source.name, rank = source.rank, points = source.points, email = source.email, pref = source.pref, discount = source.discount, vouchers = source.vouchers " +
                     "WHEN NOT MATCHED THEN INSERT (phone, name, rank, points, email, pref, discount, vouchers) VALUES (source.phone, source.name, source.rank, source.points, source.email, source.pref, source.discount, source.vouchers);";
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
            st.setString(8, joinVouchers(member.getVouchers()));
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database save failed in MemberDAO.save(), updating memory fallback: " + e.getMessage());
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

    /**
     * Saves a member along with their password in the database.
     * 
     * @param member the member to save or update
     * @param password the password for the member
     */
    public void saveWithPassword(Member member, String password) {
        ensureMemberColumns();
        String sql = "MERGE dbo.Members AS target " +
                     "USING (SELECT ? AS phone, ? AS name, ? AS rank, ? AS points, ? AS email, ? AS pref, ? AS discount, ? AS vouchers, ? AS password) AS source " +
                     "ON target.phone = source.phone " +
                     "WHEN MATCHED THEN UPDATE SET name = source.name, rank = source.rank, points = source.points, email = source.email, pref = source.pref, discount = source.discount, vouchers = source.vouchers, password = CASE WHEN source.password IS NULL OR source.password = '' THEN target.password ELSE source.password END " +
                     "WHEN NOT MATCHED THEN INSERT (phone, name, rank, points, email, pref, discount, vouchers, password) VALUES (source.phone, source.name, source.rank, source.points, source.email, source.pref, source.discount, source.vouchers, source.password);";
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
            st.setString(8, joinVouchers(member.getVouchers()));
            st.setString(9, password != null ? password : "123456");
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database saveWithPassword failed in MemberDAO.saveWithPassword(), updating memory fallback: " + e.getMessage());
        }
        saveMemberInFallback(member);
    }

    /**
     * Authenticates a member using their phone number and password.
     * 
     * @param phone the phone number of the member
     * @param password the password to verify
     * @return the authenticated member if successful, null otherwise
     */
    public Member authenticate(String phone, String password) {
        ensureMemberColumns();
        String sql = "SELECT phone, name, rank, points, email, pref, discount, vouchers FROM dbo.Members WHERE phone=? AND password=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, phone);
            st.setString(2, password);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    return readMember(rs);
                }
            }
        } catch (Exception e) {
            System.err.println("Database authenticate failed in MemberDAO.authenticate(), checking fallback members...");
        }

        if (!"123456".equals(password)) {
            return null;
        }
        return getFallbackMembers().stream()
                .filter(m -> m.getPhone().equals(phone))
                .findFirst()
                .orElse(null);
    }

    /**
     * Deletes a member from the database by their phone number.
     * 
     * @param phone the phone number of the member to delete
     */
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

    /**
     * Retrieves the fallback memory cache of members.
     * 
     * @return the fallback list of members
     */
    public List<Member> getFallbackMembers() {
        return fallbackMembers;
    }

    private void ensureMemberColumns() {
        DBContext db = new DBContext();
        String sql = "IF COL_LENGTH('dbo.Members', 'password') IS NULL " +
                     "ALTER TABLE dbo.Members ADD password VARCHAR(255) NOT NULL CONSTRAINT DF_Members_password DEFAULT '123456'; " +
                     "IF COL_LENGTH('dbo.Members', 'vouchers') IS NULL " +
                     "ALTER TABLE dbo.Members ADD vouchers NVARCHAR(MAX) NULL;";
        try (Connection con = db.getConnection();
             Statement st = con.createStatement()) {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("MemberDAO.ensureMemberColumns skipped: " + e.getMessage());
        }
    }

    private Member readMember(ResultSet rs) throws Exception {
        return new Member(
            rs.getString("phone"),
            rs.getString("name"),
            rs.getString("rank"),
            rs.getInt("points"),
            rs.getString("email"),
            rs.getString("pref"),
            rs.getString("discount"),
            parseVouchers(rs.getString("vouchers"))
        );
    }

    private List<String> parseVouchers(String raw) {
        List<String> vouchers = new ArrayList<>();
        if (raw == null || raw.trim().isEmpty()) {
            return vouchers;
        }
        String[] parts = raw.split(",");
        for (String part : parts) {
            String code = part.trim();
            if (!code.isEmpty() && !vouchers.contains(code)) {
                vouchers.add(code);
            }
        }
        return vouchers;
    }

    private String joinVouchers(List<String> vouchers) {
        if (vouchers == null || vouchers.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (String voucher : vouchers) {
            if (voucher == null || voucher.trim().isEmpty()) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(",");
            }
            sb.append(voucher.trim());
        }
        return sb.toString();
    }

    private void saveMemberInFallback(Member member) {
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
}
