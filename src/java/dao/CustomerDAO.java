package dao;

import context.DBContext;
import model.Customer;
import utils.PasswordUtils;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Truy xuất tài khoản khách hàng, số dư điểm và sổ cái điểm.
 *
 * Nguyên tắc xuyên suốt lớp này: điểm KHÔNG BAO GIỜ được sửa bằng một lệnh
 * UPDATE đơn lẻ. Mọi thay đổi đều đi qua {@link #applyPointChange} để luôn
 * sinh kèm một dòng trong dbo.PointTransactions. Nhờ vậy số dư luôn có thể
 * đối chiếu lại bằng SUM(points) — nếu lệch là biết ngay có can thiệp tay.
 */
public class CustomerDAO {

    private final DBContext db = new DBContext();

    private static final String SELECT_COLUMNS =
            "id, phone, fullName, points, totalSpent, orderCount, tier, active, createdAt";

    // ── Đăng ký & đăng nhập ─────────────────────────────────────────────

    /**
     * Tạo tài khoản mới. Ném IllegalArgumentException nếu dữ liệu không hợp lệ
     * hoặc số điện thoại đã tồn tại.
     */
    public Customer register(String rawPhone, String password, String fullName) throws Exception {
        String phone = PasswordUtils.normalizePhone(rawPhone);
        if (phone.isEmpty()) {
            throw new IllegalArgumentException("Số điện thoại không hợp lệ.");
        }
        PasswordUtils.validate(password);
        String name = fullName == null ? "" : fullName.trim();
        if (name.isEmpty()) name = "Khách " + phone.substring(Math.max(0, phone.length() - 4));
        if (name.length() > 120) name = name.substring(0, 120);

        if (findByPhone(phone) != null) {
            throw new IllegalArgumentException("Số điện thoại này đã được đăng ký.");
        }

        String salt = PasswordUtils.newSalt();
        String hash = PasswordUtils.hash(password, salt);
        String sql = "INSERT INTO dbo.Customers (phone, passwordHash, passwordSalt, fullName) VALUES (?,?,?,?)";
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, phone);
            ps.setString(2, hash);
            ps.setString(3, salt);
            ps.setString(4, name);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return findById(keys.getInt(1));
            }
        } catch (java.sql.SQLException e) {
            // 2601/2627 = vi phạm UNIQUE. Hai người đăng ký cùng lúc cùng số.
            if (e.getErrorCode() == 2601 || e.getErrorCode() == 2627) {
                throw new IllegalArgumentException("Số điện thoại này đã được đăng ký.");
            }
            throw e;
        }
        return findByPhone(phone);
    }

    /** Trả về khách nếu đúng mật khẩu, null nếu sai. Không phân biệt lý do sai. */
    public Customer login(String rawPhone, String password) throws Exception {
        String phone = PasswordUtils.normalizePhone(rawPhone);
        if (phone.isEmpty()) return null;
        String sql = "SELECT " + SELECT_COLUMNS + ", passwordHash, passwordSalt FROM dbo.Customers WHERE phone=?";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, phone);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                if (!rs.getBoolean("active")) return null;
                boolean ok = PasswordUtils.matches(password, rs.getString("passwordSalt"), rs.getString("passwordHash"));
                return ok ? map(rs) : null;
            }
        }
    }

    /** Đổi mật khẩu. Yêu cầu mật khẩu cũ đúng. */
    public void changePassword(int customerId, String oldPassword, String newPassword) throws Exception {
        PasswordUtils.validate(newPassword);
        try (Connection con = db.getConnection()) {
            String salt;
            String hash;
            try (PreparedStatement ps = con.prepareStatement("SELECT passwordHash, passwordSalt FROM dbo.Customers WHERE id=?")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy tài khoản.");
                    salt = rs.getString("passwordSalt");
                    hash = rs.getString("passwordHash");
                }
            }
            if (!PasswordUtils.matches(oldPassword, salt, hash)) {
                throw new IllegalArgumentException("Mật khẩu hiện tại không đúng.");
            }
            String newSalt = PasswordUtils.newSalt();
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE dbo.Customers SET passwordHash=?, passwordSalt=?, updatedAt=SYSUTCDATETIME() WHERE id=?")) {
                ps.setString(1, PasswordUtils.hash(newPassword, newSalt));
                ps.setString(2, newSalt);
                ps.setInt(3, customerId);
                ps.executeUpdate();
            }
        }
    }

    /** Cập nhật tên hiển thị. */
    public Customer updateProfile(int customerId, String fullName) throws Exception {
        String name = fullName == null ? "" : fullName.trim();
        if (name.isEmpty()) throw new IllegalArgumentException("Tên không được để trống.");
        if (name.length() > 120) name = name.substring(0, 120);
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE dbo.Customers SET fullName=?, updatedAt=SYSUTCDATETIME() WHERE id=?")) {
            ps.setString(1, name);
            ps.setInt(2, customerId);
            ps.executeUpdate();
        }
        return findById(customerId);
    }

    // ── Đọc ─────────────────────────────────────────────────────────────

    public Customer findById(int id) throws Exception {
        if (id <= 0) return null;
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT " + SELECT_COLUMNS + " FROM dbo.Customers WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public Customer findByPhone(String rawPhone) throws Exception {
        String phone = PasswordUtils.normalizePhone(rawPhone);
        if (phone.isEmpty()) return null;
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT " + SELECT_COLUMNS + " FROM dbo.Customers WHERE phone=?")) {
            ps.setString(1, phone);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /** Lịch sử đơn của một khách, mới nhất trước, kèm các món trong đơn. */
    public List<Map<String, Object>> getOrderHistory(int customerId, int limit) throws Exception {
        List<Map<String, Object>> orders = new ArrayList<>();
        if (customerId <= 0) return orders;
        int take = limit <= 0 || limit > 200 ? 50 : limit;
        String sql = "SELECT TOP (" + take + ") id, orderNumber, tableName, status, subtotal, discountAmount, "
                + "total, pointsEarned, pointsRedeemed, note, createdAt "
                + "FROM dbo.Orders WHERE customerId=? ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> order = new LinkedHashMap<>();
                    order.put("id", rs.getInt("id"));
                    order.put("orderNumber", rs.getInt("orderNumber"));
                    order.put("tableName", rs.getString("tableName"));
                    order.put("status", rs.getString("status"));
                    order.put("subtotal", rs.getInt("subtotal"));
                    order.put("discountAmount", rs.getInt("discountAmount"));
                    order.put("total", rs.getInt("total"));
                    order.put("pointsEarned", rs.getInt("pointsEarned"));
                    order.put("pointsRedeemed", rs.getInt("pointsRedeemed"));
                    order.put("note", rs.getString("note"));
                    order.put("createdAt", String.valueOf(rs.getObject("createdAt")));
                    orders.add(order);
                }
            }
            for (Map<String, Object> order : orders) {
                order.put("items", loadItems(con, (Integer) order.get("id")));
            }
        }
        return orders;
    }

    private List<Map<String, Object>> loadItems(Connection con, int orderId) throws Exception {
        List<Map<String, Object>> items = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT itemName, itemSize, quantity, price FROM dbo.OrderItems WHERE orderId=? ORDER BY id")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("itemName", rs.getString("itemName"));
                    item.put("itemSize", rs.getString("itemSize"));
                    item.put("quantity", rs.getInt("quantity"));
                    item.put("price", rs.getInt("price"));
                    items.add(item);
                }
            }
        }
        return items;
    }

    /** Sổ cái điểm của một khách, mới nhất trước. */
    public List<Map<String, Object>> getPointHistory(int customerId, int limit) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        if (customerId <= 0) return list;
        int take = limit <= 0 || limit > 200 ? 50 : limit;
        String sql = "SELECT TOP (" + take + ") pt.id, pt.type, pt.points, pt.balanceAfter, pt.note, pt.createdAt, "
                + "o.orderNumber FROM dbo.PointTransactions pt "
                + "LEFT JOIN dbo.Orders o ON o.id = pt.orderId "
                + "WHERE pt.customerId=? ORDER BY pt.id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> tx = new LinkedHashMap<>();
                    tx.put("id", rs.getInt("id"));
                    tx.put("type", rs.getString("type"));
                    tx.put("points", rs.getInt("points"));
                    tx.put("balanceAfter", rs.getInt("balanceAfter"));
                    tx.put("note", rs.getString("note"));
                    tx.put("orderNumber", rs.getInt("orderNumber"));
                    tx.put("createdAt", String.valueOf(rs.getObject("createdAt")));
                    list.add(tx);
                }
            }
        }
        return list;
    }

    // ── Thay đổi điểm (dùng chung cho cộng và trừ) ───────────────────────

    /**
     * Cộng/trừ điểm trong MỘT giao dịch đang mở, đồng thời ghi sổ cái.
     *
     * @param con        connection đang trong transaction của lời gọi bên ngoài
     * @param customerId khách nhận thay đổi
     * @param delta      dương = cộng, âm = trừ
     * @param type       EARN | REDEEM | ADJUST
     * @param orderId    đơn liên quan, 0 nếu không có
     * @param note       diễn giải cho khách đọc
     * @param paidAmount số tiền cộng vào tổng chi tiêu (chỉ dùng khi EARN)
     * @return số dư điểm sau thay đổi
     */
    public int applyPointChange(Connection con, int customerId, int delta, String type,
                                int orderId, String note, int paidAmount) throws Exception {
        if (customerId <= 0) return 0;

        int currentPoints;
        int currentSpent;
        int currentOrders;
        // UPDLOCK: khoá dòng khách để hai đơn thanh toán cùng lúc không ghi đè nhau.
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT points, totalSpent, orderCount FROM dbo.Customers WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy tài khoản khách hàng.");
                currentPoints = rs.getInt("points");
                currentSpent = rs.getInt("totalSpent");
                currentOrders = rs.getInt("orderCount");
            }
        }

        int newPoints = currentPoints + delta;
        if (newPoints < 0) {
            throw new IllegalArgumentException("Số điểm không đủ để sử dụng.");
        }
        int newSpent = currentSpent + Math.max(0, paidAmount);
        int newOrders = currentOrders + (paidAmount > 0 ? 1 : 0);
        String newTier = Customer.tierForSpent(newSpent);

        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Customers SET points=?, totalSpent=?, orderCount=?, tier=?, updatedAt=SYSUTCDATETIME() WHERE id=?")) {
            ps.setInt(1, newPoints);
            ps.setInt(2, newSpent);
            ps.setInt(3, newOrders);
            ps.setString(4, newTier);
            ps.setInt(5, customerId);
            ps.executeUpdate();
        }

        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO dbo.PointTransactions (customerId, orderId, type, points, balanceAfter, note) VALUES (?,?,?,?,?,?)")) {
            ps.setInt(1, customerId);
            if (orderId > 0) ps.setInt(2, orderId); else ps.setNull(2, java.sql.Types.INTEGER);
            ps.setString(3, type);
            ps.setInt(4, delta);
            ps.setInt(5, newPoints);
            ps.setString(6, note);
            ps.executeUpdate();
        }
        return newPoints;
    }

    /** Đọc số dư điểm trong một transaction đang mở. */
    public int currentPoints(Connection con, int customerId) throws Exception {
        if (customerId <= 0) return 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT points FROM dbo.Customers WHERE id=?")) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("points") : 0;
            }
        }
    }

    // ── Tiện ích khởi động ──────────────────────────────────────────────

    /**
     * Tạo 2 tài khoản demo nếu bảng còn trống (mật khẩu 123456).
     * Hash được tính bằng đúng PasswordUtils nên chắc chắn đăng nhập được —
     * đây là lý do việc seed nằm ở Java chứ không nằm trong file .sql.
     */
    public void seedDemoAccounts() {
        try {
            if (!tableExists()) return;
            try (Connection con = db.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Customers");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return;
            }
            register("0901234567", "123456", "Nguyễn Văn An");
            register("0912345678", "123456", "Trần Thị Bình");
            System.out.println("CustomerDAO: đã tạo 2 tài khoản khách demo (mật khẩu 123456).");
        } catch (Exception e) {
            System.err.println("CustomerDAO.seedDemoAccounts bỏ qua: " + e.getMessage());
        }
    }

    /** Bảng Customers có tồn tại không — dùng để chạy được cả khi chưa chạy migration. */
    public boolean tableExists() {
        try (Connection con = db.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT OBJECT_ID('dbo.Customers','U')");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() && rs.getObject(1) != null;
        } catch (Exception e) {
            return false;
        }
    }

    private Customer map(ResultSet rs) throws Exception {
        Customer c = new Customer();
        c.setId(rs.getInt("id"));
        c.setPhone(rs.getString("phone"));
        c.setFullName(rs.getString("fullName"));
        c.setPoints(rs.getInt("points"));
        c.setTotalSpent(rs.getInt("totalSpent"));
        c.setOrderCount(rs.getInt("orderCount"));
        c.setTier(rs.getString("tier"));
        c.setActive(rs.getBoolean("active"));
        c.setCreatedAt(String.valueOf(rs.getObject("createdAt")));
        return c;
    }
}
