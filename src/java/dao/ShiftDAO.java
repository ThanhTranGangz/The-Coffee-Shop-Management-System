package dao;

import context.DBContext;
import model.Shift;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/**
 * Data Access Object for managing shifts.
 * Handles database operations and provides a memory fallback mechanism.
 */
public class ShiftDAO {
    private List<Shift> fallbackShifts = new ArrayList<>();

    /**
     * Retrieves all shifts from the database or fallback list.
     * 
     * @return a list of all shifts
     */
    public List<Shift> getAll() {
        List<Shift> shifts = new ArrayList<>();
        String sql = "SELECT s.id, s.staffId, st.name as staffName, s.shiftDate, s.shiftName, s.hours, s.status, s.notes, s.assignedRole " +
                     "FROM dbo.Shifts s JOIN dbo.Staff st ON s.staffId = st.id " +
                     "ORDER BY s.shiftDate DESC, s.shiftName";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                shifts.add(new Shift(
                    rs.getString("id"),
                    rs.getInt("staffId"),
                    rs.getString("staffName"),
                    rs.getString("shiftDate"),
                    rs.getString("shiftName"),
                    rs.getString("hours"),
                    rs.getString("status"),
                    rs.getString("notes"),
                    rs.getString("assignedRole")
                ));
            }
            fallbackShifts = new ArrayList<>(shifts);
        } catch (Exception e) {
            System.err.println("Database fetch failed in ShiftDAO.getAll(), using fallback: " + e.getMessage());
            return fallbackShifts;
        }
        return shifts;
    }

    public boolean existsOverlap(int staffId, String shiftDate, String shiftName, String excludeId) {
        if (staffId <= 0 || shiftDate == null || shiftDate.isEmpty() || shiftName == null || shiftName.isEmpty()) {
            return false;
        }
        String sql = "SELECT COUNT(*) FROM dbo.Shifts WHERE staffId=? AND shiftDate=? AND shiftName=?"
                + (excludeId != null && !excludeId.isEmpty() ? " AND id<>?" : "");
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setInt(1, staffId);
            st.setString(2, shiftDate);
            st.setString(3, shiftName);
            if (excludeId != null && !excludeId.isEmpty()) {
                st.setString(4, excludeId);
            }
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return true;
            }
        } catch (Exception e) {
            System.err.println("Database overlap check failed in ShiftDAO.existsOverlap(): " + e.getMessage());
            for (Shift existing : fallbackShifts) {
                if (existing.getStaffId() == staffId
                        && shiftDate.equals(existing.getShiftDate())
                        && shiftName.equals(existing.getShiftName())
                        && (excludeId == null || excludeId.isEmpty() || !excludeId.equals(existing.getId()))) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Checks if a specific shift slot (date + shiftName) already has ANY staff assigned.
     */
    public boolean isShiftSlotFilled(String shiftDate, String shiftName) {
        if (shiftDate == null || shiftDate.isEmpty() || shiftName == null || shiftName.isEmpty()) {
            return false;
        }
        String sql = "SELECT COUNT(*) FROM dbo.Shifts WHERE shiftDate=? AND shiftName=?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, shiftDate);
            st.setString(2, shiftName);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return true;
            }
        } catch (Exception e) {
            System.err.println("Database check failed in ShiftDAO.isShiftSlotFilled(): " + e.getMessage());
            for (Shift existing : fallbackShifts) {
                if (shiftDate.equals(existing.getShiftDate()) && shiftName.equals(existing.getShiftName())) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Saves a new shift or updates an existing one in the database.
     * 
     * @param shift the shift to save or update
     */
    public void save(Shift shift) {
        String sql = "MERGE dbo.Shifts AS target " +
                     "USING (SELECT ? AS id, ? AS staffId, ? AS shiftDate, ? AS shiftName, ? AS hours, ? AS status, ? AS notes, ? AS assignedRole) AS source " +
                     "ON target.id = source.id " +
                     "WHEN MATCHED THEN UPDATE SET staffId = source.staffId, shiftDate = source.shiftDate, shiftName = source.shiftName, hours = source.hours, status = source.status, notes = source.notes, assignedRole = source.assignedRole " +
                     "WHEN NOT MATCHED THEN INSERT (id, staffId, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES (source.id, source.staffId, source.shiftDate, source.shiftName, source.hours, source.status, source.notes, source.assignedRole);";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, shift.getId());
            st.setInt(2, shift.getStaffId());
            st.setString(3, shift.getShiftDate());
            st.setString(4, shift.getShiftName());
            st.setString(5, shift.getHours());
            st.setString(6, shift.getStatus());
            st.setString(7, shift.getNotes());
            st.setString(8, shift.getAssignedRole());
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database save failed in ShiftDAO.save(): " + e.getMessage());
            throw new IllegalStateException(e.getMessage(), e);
        }

        int idx = -1;
        for (int i = 0; i < fallbackShifts.size(); i++) {
            if (fallbackShifts.get(i).getId().equals(shift.getId())) {
                idx = i;
                break;
            }
        }
        if (idx >= 0) {
            fallbackShifts.set(idx, shift);
        } else {
            fallbackShifts.add(shift);
        }
    }

    /**
     * Deletes a shift from the database by its ID.
     * 
     * @param id the unique identifier of the shift to delete
     */
    public void delete(String id) {
        String sql = "DELETE FROM dbo.Shifts WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, id);
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database delete failed in ShiftDAO.delete(): " + e.getMessage());
        }
        fallbackShifts.removeIf(s -> s.getId().equals(id));
    }
    
    /**
     * Calculates total hours worked by each staff for a specific month.
     * Only includes shifts with status 'Đã làm' or 'Hoàn thành'.
     * 
     * @param yyyyMM the month in 'YYYY-MM' format (e.g., '2026-07')
     * @return A list of Maps containing staffName, role, totalShifts, and totalHours
     */
    public List<Map<String, Object>> getPayrollByMonth(String yyyyMM) {
        List<Map<String, Object>> payroll = new ArrayList<>();
        String sql = "SELECT s.staffId, st.name as staffName, s.assignedRole, " +
                     "COUNT(*) as totalShifts, " +
                     "SUM(CASE WHEN s.shiftName = N'Ca Tối' THEN 5 ELSE 6 END) as totalHours " +
                     "FROM dbo.Shifts s JOIN dbo.Staff st ON s.staffId = st.id " +
                     "WHERE s.shiftDate LIKE ? AND (s.status = N'Đã làm' OR s.status = N'Hoàn thành') " +
                     "GROUP BY s.staffId, st.name, s.assignedRole " +
                     "ORDER BY st.name ASC";
                     
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, yyyyMM + "-%");
            ResultSet rs = st.executeQuery();
            while (rs.next()) {
                Map<String, Object> record = new HashMap<>();
                record.put("staffId", rs.getInt("staffId"));
                record.put("staffName", rs.getString("staffName"));
                record.put("role", rs.getString("assignedRole"));
                record.put("totalShifts", rs.getInt("totalShifts"));
                record.put("totalHours", rs.getInt("totalHours"));
                payroll.add(record);
            }
        } catch (Exception e) {
            System.err.println("Database query failed in ShiftDAO.getPayrollByMonth(): " + e.getMessage());
        }
        return payroll;
    }

    /**
     * Retrieves all shifts for a specific week (Monday to Sunday).
     *
     * @param mondayDate the Monday date in 'YYYY-MM-DD' format
     * @return a list of shifts within the week
     */
    public List<Shift> getShiftsByWeek(String mondayDate) {
        List<Shift> shifts = new ArrayList<>();
        // Calculate Sunday = Monday + 6 days
        java.time.LocalDate monday = java.time.LocalDate.parse(mondayDate);
        String sundayDate = monday.plusDays(6).toString();

        String sql = "SELECT s.id, s.staffId, st.name as staffName, s.shiftDate, s.shiftName, s.hours, s.status, s.notes, s.assignedRole " +
                     "FROM dbo.Shifts s JOIN dbo.Staff st ON s.staffId = st.id " +
                     "WHERE s.shiftDate BETWEEN ? AND ? " +
                     "ORDER BY s.shiftDate, s.shiftName";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, mondayDate);
            st.setString(2, sundayDate);
            try (ResultSet rs = st.executeQuery()) {
                while (rs.next()) {
                    shifts.add(new Shift(
                        rs.getString("id"),
                        rs.getInt("staffId"),
                        rs.getString("staffName"),
                        rs.getString("shiftDate"),
                        rs.getString("shiftName"),
                        rs.getString("hours"),
                        rs.getString("status"),
                        rs.getString("notes"),
                        rs.getString("assignedRole")
                    ));
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in ShiftDAO.getShiftsByWeek(): " + e.getMessage());
        }
        return shifts;
    }

    /**
     * Checks whether any shifts exist for a specific week (Monday to Sunday).
     *
     * @param mondayDate the Monday date in 'YYYY-MM-DD' format
     * @return true if at least one shift exists in the week
     */
    public boolean hasShiftsInWeek(String mondayDate) {
        java.time.LocalDate monday = java.time.LocalDate.parse(mondayDate);
        String sundayDate = monday.plusDays(6).toString();

        String sql = "SELECT COUNT(*) FROM dbo.Shifts WHERE shiftDate BETWEEN ? AND ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, mondayDate);
            st.setString(2, sundayDate);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return true;
            }
        } catch (Exception e) {
            System.err.println("Database check failed in ShiftDAO.hasShiftsInWeek(): " + e.getMessage());
        }
        return false;
    }
}
