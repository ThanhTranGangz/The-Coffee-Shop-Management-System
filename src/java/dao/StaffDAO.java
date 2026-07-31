package dao;

import context.DBContext;
import model.Staff;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.time.LocalDate;

/**
 * Data Access Object for managing staff members.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class StaffDAO {
    private List<Staff> fallbackStaff = new ArrayList<>();

    /**
     * Retrieves all staff members from the database or fallback list.
     * 
     * @return a list of all staff members
     */
    public List<Staff> getAll() {
        List<Staff> list = new ArrayList<>();
        String sql = "SELECT id, name, active, status FROM dbo.Staff";
        String todayStr = LocalDate.now().toString();
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                int id = rs.getInt("id");
                String name = rs.getString("name");

                boolean active = rs.getBoolean("active");
                String status = rs.getString("status");

                

                list.add(new Staff(id, name, active, status));
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
            String updateSql = "UPDATE dbo.Staff SET name=?, active=?, status=? WHERE id=?";
            try (Connection con = db.getConnection();
                 PreparedStatement st = con.prepareStatement(updateSql)) {
                st.setString(1, staff.getName());
                st.setBoolean(2, staff.isActive());
                st.setString(3, staff.getStatus());
                st.setInt(4, staff.getId());
                int affected = st.executeUpdate();
                if (affected <= 0) {
                    throw new IllegalStateException("Không cập nhật được nhân viên #" + staff.getId());
                }
            } catch (RuntimeException e) {
                throw e;
            } catch (Exception e) {
                throw new IllegalStateException("Database update in StaffDAO.save() failed: " + e.getMessage(), e);
            }
        } else {
            String insertSql = "INSERT INTO dbo.Staff (id, name, active, status) VALUES (?, ?, ?, ?)";
            try (Connection con = db.getConnection();
                 PreparedStatement st = con.prepareStatement(insertSql)) {
                st.setInt(1, staff.getId());
                st.setString(2, staff.getName());
                st.setBoolean(3, staff.isActive());
                st.setString(4, staff.getStatus());
                st.executeUpdate();
            } catch (RuntimeException e) {
                throw e;
            } catch (Exception e) {
                throw new IllegalStateException("Database insert in StaffDAO.save() failed: " + e.getMessage(), e);
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
        String sql = "UPDATE dbo.Staff SET active = 0, status = 'Inactive' WHERE id=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setInt(1, id);
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database delete failed in StaffDAO.delete()");
        }
        // Instead of removing from fallback, update it
        for (Staff s : getFallbackStaff()) {
            if (s.getId() == id) {
                s.setActive(false);
                s.setStatus("Inactive");
                break;
            }
        }
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
