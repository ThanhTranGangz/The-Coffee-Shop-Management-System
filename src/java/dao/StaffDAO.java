package dao;

import context.DBContext;
import model.Staff;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class StaffDAO {
    private List<Staff> fallbackStaff;

    public List<Staff> getAll() {
        List<Staff> list = new ArrayList<>();
        String sql = "SELECT id, name, role, pin, shift, active, username, password, status, overtime FROM dbo.Staff";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                list.add(new Staff(
                    rs.getInt("id"),
                    rs.getString("name"),
                    rs.getString("role"),
                    rs.getString("pin"),
                    rs.getString("shift"),
                    rs.getBoolean("active"),
                    rs.getString("username"),
                    rs.getString("password"),
                    rs.getString("status"),
                    rs.getBoolean("overtime")
                ));
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in StaffDAO.getAll(), falling back: " + e.getMessage());
            return getFallbackStaff();
        }
        
        if (list.isEmpty()) {
            return getFallbackStaff();
        }
        return list;
    }

    public void save(Staff staff) {
        String sql = "INSERT INTO dbo.Staff (id, name, role, pin, shift, active, username, password, status, overtime) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE name=?, role=?, pin=?, shift=?, active=?, username=?, password=?, status=?, overtime=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setInt(1, staff.getId());
            st.setString(2, staff.getName());
            st.setString(3, staff.getRole());
            st.setString(4, staff.getPin());
            st.setString(5, staff.getShift());
            st.setBoolean(6, staff.isActive());
            st.setString(7, staff.getUsername());
            st.setString(8, staff.getPassword());
            st.setString(9, staff.getStatus());
            st.setBoolean(10, staff.isOvertime());
            
            st.setString(11, staff.getName());
            st.setString(12, staff.getRole());
            st.setString(13, staff.getPin());
            st.setString(14, staff.getShift());
            st.setBoolean(15, staff.isActive());
            st.setString(16, staff.getUsername());
            st.setString(17, staff.getPassword());
            st.setString(18, staff.getStatus());
            st.setBoolean(19, staff.isOvertime());
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database save failed in StaffDAO.save(), updating memory fallback...");
        }

        // Keep fallback context updated
        List<Staff> current = getFallbackStaff();
        int idx = -1;
        for (int i = 0; i < current.size(); i++) {
            if (current.get(i).getId() == staff.getId()) {
                idx = i;
                break;
            }
        }
        if (idx != -1) {
            current.set(idx, staff);
        } else {
            current.add(staff);
        }
    }

    public void delete(int id) {
        String sql = "DELETE FROM dbo.Staff WHERE id=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setInt(1, id);
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database delete failed in StaffDAO.delete()");
        }
        getFallbackStaff().removeIf(s -> s.getId() == id);
    }

    public List<Staff> getFallbackStaff() {
        if (fallbackStaff == null) {
            fallbackStaff = new ArrayList<>();
            // Default seed employees
            fallbackStaff.add(new Staff(1, "Quản lý Hệ Thống", "manager", "8888", "Toàn thời gian", true, "admin", "123456", "Active", false));
            fallbackStaff.add(new Staff(2, "Nguyễn Văn A", "manager", "9999", "Toàn thời gian", true, "nguyenvana", "123456", "Active", false));
            
            // Waiters
            fallbackStaff.add(new Staff(3, "Phạm Minh waiter (Ca sáng)", "waiter", "1234", "Ca sáng (06:00 - 12:00)", true, "waiter1", "123456", "Active", false));
            fallbackStaff.add(new Staff(4, "Nguyễn Thị B (Ca chiều)", "waiter", "2222", "Ca chiều (12:00 - 18:00)", true, "waiter2", "123456", "Active", false));
            fallbackStaff.add(new Staff(5, "Lê Hoàng D (Ca tối)", "waiter", "5555", "Ca tối (18:00 - 24:00)", true, "waiter3", "123456", "Active", false));
            
            // Baristas
            fallbackStaff.add(new Staff(6, "Trần Văn C (Ca sáng)", "barista", "4444", "Ca sáng (06:00 - 12:00)", true, "barista2", "123456", "Active", false));
            fallbackStaff.add(new Staff(7, "Phan Anh barista (Ca chiều)", "barista", "3333", "Ca chiều (12:00 - 18:00)", true, "barista1", "123456", "Active", false));
        }
        return fallbackStaff;
    }
}
