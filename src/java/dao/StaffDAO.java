package dao;

import context.DBContext;
import model.Staff;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Calendar;

/**
 * Data Access Object for managing staff members.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class StaffDAO {
    private List<Staff> fallbackStaff = new ArrayList<>();

    /**
     * Checks if a specific shift is currently active based on the time.
     * 
     * @param shiftText the shift text to check (e.g., "06:00 - 12:00")
     * @return true if the shift is currently active, false otherwise
     */
    public static boolean isShiftCurrentlyActive(String shiftText) {
        if (shiftText == null) return false;
        if (shiftText.contains("Toàn thời gian") || shiftText.toLowerCase().contains("all")) {
            return true;
        }
        int hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
        if (shiftText.contains("06:00") && shiftText.contains("12:00")) {
            return (hour >= 6 && hour < 12);
        }
        if (shiftText.contains("12:00") && shiftText.contains("18:00")) {
            return (hour >= 12 && hour < 18);
        }
        if (shiftText.contains("18:00") && (shiftText.contains("23:00") || shiftText.contains("24:00") || shiftText.contains("00:00"))) {
            return (hour >= 18 && hour < 24);
        }
        return true;
    }

    /**
     * Retrieves all staff members from the database or fallback list.
     * 
     * @return a list of all staff members
     */
    public List<Staff> getAll() {
        List<Staff> list = new ArrayList<>();
        String sql = "SELECT id, name, role, pin, shift, active, username, password, status, overtime FROM dbo.Staff";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                int id = rs.getInt("id");
                String name = rs.getString("name");
                String role = rs.getString("role");
                String pin = rs.getString("pin");
                String shift = rs.getString("shift");
                boolean active = rs.getBoolean("active");
                String username = rs.getString("username");
                String password = rs.getString("password");
                String status = rs.getString("status");
                boolean overtime = rs.getBoolean("overtime");

                // Dynamic Shift/Active state check
                if (!"manager".equalsIgnoreCase(role)) {
                    boolean isShiftActive = isShiftCurrentlyActive(shift);
                    if (!isShiftActive && !overtime) {
                        active = false;
                    } else if (isShiftActive && "Active".equalsIgnoreCase(status)) {
                        active = true;
                    }
                }

                list.add(new Staff(id, name, role, pin, shift, active, username, password, status, overtime));
            }
            // Sync fallback to the database contents
            fallbackStaff = new ArrayList<>(list);
        } catch (Exception e) {
            System.err.println("Database fetch failed in StaffDAO.getAll(), using synced/previous staff list: " + e.getMessage());
            return getFallbackStaff();
        }
        
        if (list.isEmpty()) {
            return getFallbackStaff();
        }
        return list;
    }

    /**
     * Saves a new staff member or updates an existing one in the database.
     * 
     * @param staff the staff member to save or update
     */
    public void save(Staff staff) {
        DBContext db = new DBContext();
        
        // SQL Server compatible merge/save check
        boolean exists = false;
        String checkSql = "SELECT COUNT(*) FROM dbo.Staff WHERE id = ?";
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(checkSql)) {
            st.setInt(1, staff.getId());
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    exists = true;
                }
            }
        } catch (Exception e) {
            System.err.println("Database save check failed: " + e.getMessage());
        }

        if (exists) {
            String updateSql = "UPDATE dbo.Staff SET name=?, role=?, pin=?, shift=?, active=?, username=?, password=?, status=?, overtime=? WHERE id=?";
            try (Connection con = db.getConnection();
                 PreparedStatement st = con.prepareStatement(updateSql)) {
                st.setString(1, staff.getName());
                st.setString(2, staff.getRole());
                st.setString(3, staff.getPin());
                st.setString(4, staff.getShift());
                st.setBoolean(5, staff.isActive());
                st.setString(6, staff.getUsername());
                st.setString(7, staff.getPassword());
                st.setString(8, staff.getStatus());
                st.setBoolean(9, staff.isOvertime());
                st.setInt(10, staff.getId());
                st.executeUpdate();
            } catch (Exception e) {
                System.err.println("Database update in StaffDAO.save() failed: " + e.getMessage());
            }
        } else {
            String insertSql = "INSERT INTO dbo.Staff (id, name, role, pin, shift, active, username, password, status, overtime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try (Connection con = db.getConnection();
                 PreparedStatement st = con.prepareStatement(insertSql)) {
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
                st.executeUpdate();
            } catch (Exception e) {
                System.err.println("Database insert in StaffDAO.save() failed: " + e.getMessage());
            }
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

    /**
     * Deletes a staff member from the database by their ID.
     * 
     * @param id the unique identifier of the staff member to delete
     */
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

    /**
     * Retrieves the fallback memory cache of staff members.
     * 
     * @return the fallback list of staff members
     */
    public List<Staff> getFallbackStaff() {
        return fallbackStaff;
    }
}
