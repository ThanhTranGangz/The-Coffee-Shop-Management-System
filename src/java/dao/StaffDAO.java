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

    /*
     * Việc lưu nhân viên nằm ở LiteService.saveStaff().
     *
     * Ở đây từng có save(Staff): hỏi "mã này có sẵn chưa", có thì UPDATE, chưa
     * thì INSERT với mã do client gửi lên. Nghe thì tiện, nhưng nó biến việc
     * "thêm nhân viên mới mang mã 8" thành "đổi tên người mang mã 8" — cả một
     * đời ca làm, hoá đơn và nhật ký của người cũ lặng lẽ sang tên người mới.
     * Thêm mới và sửa là hai việc khác nhau, và mã nhân viên phải do hệ thống
     * cấp chứ không phải do người dùng gõ.
     */

    /*
     * Việc xoá nhân viên nằm ở LiteService.deleteStaff().
     *
     * Ở đây từng có một hàm delete() chỉ chạy UPDATE active=0 — nó không đụng
     * tới bảng Users nên tài khoản của người đã nghỉ vẫn sống với PIN dùng
     * được, và người tạo nhầm thì vĩnh viễn không xoá nổi. Xoá nhân viên phải
     * xem lịch sử ở năm bảng rồi mới quyết định, việc đó thuộc về tầng dịch
     * vụ chứ không phải một câu UPDATE trong DAO.
     */

    /**
     * Retrieves the fallback memory cache of staff members.
     * 
     * @return the fallback list of staff members
     */
    public List<Staff> getFallbackStaff() {
        return fallbackStaff;
    }
}
