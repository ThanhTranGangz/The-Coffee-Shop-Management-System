package dao;

import context.DBContext;
import model.Shift;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class ShiftDAO {
    private List<Shift> fallbackShifts = new ArrayList<>();

    public List<Shift> getAll() {
        List<Shift> shifts = new ArrayList<>();
        String sql = "SELECT id, staffId, staffName, shiftDate, shiftName, hours, status, notes FROM dbo.Shifts ORDER BY shiftDate DESC, shiftName";
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
                    rs.getString("notes")
                ));
            }
            fallbackShifts = new ArrayList<>(shifts);
        } catch (Exception e) {
            System.err.println("Database fetch failed in ShiftDAO.getAll(), using fallback: " + e.getMessage());
            return fallbackShifts;
        }
        return shifts;
    }

    public void save(Shift shift) {
        String sql = "MERGE dbo.Shifts AS target " +
                     "USING (SELECT ? AS id, ? AS staffId, ? AS staffName, ? AS shiftDate, ? AS shiftName, ? AS hours, ? AS status, ? AS notes) AS source " +
                     "ON target.id = source.id " +
                     "WHEN MATCHED THEN UPDATE SET staffId = source.staffId, staffName = source.staffName, shiftDate = source.shiftDate, shiftName = source.shiftName, hours = source.hours, status = source.status, notes = source.notes " +
                     "WHEN NOT MATCHED THEN INSERT (id, staffId, staffName, shiftDate, shiftName, hours, status, notes) VALUES (source.id, source.staffId, source.staffName, source.shiftDate, source.shiftName, source.hours, source.status, source.notes);";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, shift.getId());
            st.setInt(2, shift.getStaffId());
            st.setString(3, shift.getStaffName());
            st.setString(4, shift.getShiftDate());
            st.setString(5, shift.getShiftName());
            st.setString(6, shift.getHours());
            st.setString(7, shift.getStatus());
            st.setString(8, shift.getNotes());
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database save failed in ShiftDAO.save(), updating fallback: " + e.getMessage());
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
}
