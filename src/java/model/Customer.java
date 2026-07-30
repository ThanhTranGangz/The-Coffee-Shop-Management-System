package model;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Tài khoản khách hàng của quán.
 *
 * Khác với model.Staff (nhân sự nội bộ), Customer là người ngoài tự đăng ký.
 * Định danh nghiệp vụ là số điện thoại — đã đặt UNIQUE ở tầng CSDL, không
 * dựa vào tầng ứng dụng để bảo đảm duy nhất.
 *
 * Lưu ý bảo mật: passwordHash và passwordSalt KHÔNG BAO GIỜ được đưa vào
 * toMap(), vì toMap() là thứ được serialize thẳng ra JSON cho trình duyệt.
 */
public class Customer {

    /** Mốc tổng chi tiêu để lên hạng (đơn vị: đồng). */
    public static final int SILVER_THRESHOLD = 1_000_000;
    public static final int GOLD_THRESHOLD = 3_000_000;

    /** 10.000đ đã thanh toán = 1 điểm. */
    public static final int SPEND_PER_POINT = 10_000;
    /** 1 điểm đổi được 1.000đ. */
    public static final int VALUE_PER_POINT = 1_000;
    /** Phải có tối thiểu ngần này điểm mới được đổi. */
    public static final int MIN_REDEEM_POINTS = 10;
    /** Giảm giá không được vượt quá 50% tiền hàng — tránh đơn 0đ. */
    public static final int MAX_REDEEM_PERCENT = 50;

    private int id;
    private String phone;
    private String fullName;
    private int points;
    private int totalSpent;
    private int orderCount;
    private String tier;
    private boolean active;
    private String createdAt;

    public Customer() {
        this.tier = "Bronze";
        this.active = true;
    }

    /** Hạng tương ứng với tổng chi tiêu. Một nơi duy nhất quyết định hạng. */
    public static String tierForSpent(int totalSpent) {
        if (totalSpent >= GOLD_THRESHOLD) return "Gold";
        if (totalSpent >= SILVER_THRESHOLD) return "Silver";
        return "Bronze";
    }

    /** Số điểm nhận được khi thanh toán số tiền này. */
    public static int pointsForSpend(int paidAmount) {
        if (paidAmount <= 0) return 0;
        return paidAmount / SPEND_PER_POINT;
    }

    /** Số tiền còn thiếu để lên hạng kế tiếp; 0 nếu đã ở hạng cao nhất. */
    public static int spentToNextTier(int totalSpent) {
        if (totalSpent < SILVER_THRESHOLD) return SILVER_THRESHOLD - totalSpent;
        if (totalSpent < GOLD_THRESHOLD) return GOLD_THRESHOLD - totalSpent;
        return 0;
    }

    /**
     * Số điểm tối đa được phép dùng cho một đơn có tiền hàng là subtotal.
     * Chặn cả 3 phía: số dư điểm, trần 50% đơn, và bội số điểm hợp lệ.
     */
    public static int maxRedeemablePoints(int availablePoints, int subtotal) {
        if (availablePoints < MIN_REDEEM_POINTS || subtotal <= 0) return 0;
        int capByOrder = (subtotal * MAX_REDEEM_PERCENT / 100) / VALUE_PER_POINT;
        int allowed = Math.min(availablePoints, capByOrder);
        return allowed < MIN_REDEEM_POINTS ? 0 : allowed;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public int getPoints() { return points; }
    public void setPoints(int points) { this.points = points; }

    public int getTotalSpent() { return totalSpent; }
    public void setTotalSpent(int totalSpent) { this.totalSpent = totalSpent; }

    public int getOrderCount() { return orderCount; }
    public void setOrderCount(int orderCount) { this.orderCount = orderCount; }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    /** Dữ liệu an toàn để trả ra trình duyệt. Không chứa hash/salt. */
    public Map<String, Object> toMap() {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", id);
        map.put("phone", phone);
        map.put("fullName", fullName);
        map.put("points", points);
        map.put("pointsValue", points * VALUE_PER_POINT);
        map.put("totalSpent", totalSpent);
        map.put("orderCount", orderCount);
        map.put("tier", tier);
        map.put("spentToNextTier", spentToNextTier(totalSpent));
        map.put("active", active);
        map.put("createdAt", createdAt);
        return map;
    }
}
