package model;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
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

    /** Tên hạng kế tiếp; rỗng nếu đã Gold. */
    public static String nextTierName(int totalSpent) {
        if (totalSpent < SILVER_THRESHOLD) return "Silver";
        if (totalSpent < GOLD_THRESHOLD) return "Gold";
        return "";
    }

    /**
     * Mô tả chương trình hạng / tích điểm để UI giới thiệu.
     * Hạng hiện tại chỉ dựa trên tổng chi tiêu; quyền đổi điểm áp dụng mọi hạng.
     */
    public static List<Map<String, Object>> tierGuide() {
        List<Map<String, Object>> tiers = new ArrayList<>();
        tiers.add(tierInfo("Bronze", 0, SILVER_THRESHOLD - 1,
                "Thành viên cơ bản",
                "Basic member",
                Arrays.asList(
                        "Tích điểm mỗi lần thanh toán (1 điểm / " + (SPEND_PER_POINT / 1000) + ".000đ)",
                        "Đổi điểm giảm giá đơn (1 điểm = " + (VALUE_PER_POINT / 1000) + ".000đ)",
                        "Đổi tối thiểu " + MIN_REDEEM_POINTS + " điểm, tối đa " + MAX_REDEEM_PERCENT + "% giá trị đơn",
                        "Xem lịch sử đơn và sổ điểm trên tài khoản"
                ),
                Arrays.asList(
                        "Earn points on every paid order (1 point / " + (SPEND_PER_POINT / 1000) + ",000 VND)",
                        "Redeem points for discounts (1 point = " + (VALUE_PER_POINT / 1000) + ",000 VND)",
                        "Min " + MIN_REDEEM_POINTS + " points, up to " + MAX_REDEEM_PERCENT + "% of the order",
                        "View order history and points ledger in your account"
                )));
        tiers.add(tierInfo("Silver", SILVER_THRESHOLD, GOLD_THRESHOLD - 1,
                "Thành viên Bạc",
                "Silver member",
                Arrays.asList(
                        "Toàn bộ quyền lợi hạng Đồng",
                        "Huy hiệu Hạng Bạc trên thẻ thành viên",
                        "Đạt khi tổng chi tiêu từ " + formatVnd(SILVER_THRESHOLD) + " trở lên"
                ),
                Arrays.asList(
                        "All Bronze benefits",
                        "Silver badge on your membership card",
                        "Unlocked from " + formatVndEn(SILVER_THRESHOLD) + " total spend"
                )));
        tiers.add(tierInfo("Gold", GOLD_THRESHOLD, Integer.MAX_VALUE,
                "Thành viên Vàng",
                "Gold member",
                Arrays.asList(
                        "Toàn bộ quyền lợi hạng Bạc",
                        "Huy hiệu Hạng Vàng — hạng cao nhất",
                        "Đạt khi tổng chi tiêu từ " + formatVnd(GOLD_THRESHOLD) + " trở lên"
                ),
                Arrays.asList(
                        "All Silver benefits",
                        "Gold badge — the top tier",
                        "Unlocked from " + formatVndEn(GOLD_THRESHOLD) + " total spend"
                )));
        return tiers;
    }

    private static Map<String, Object> tierInfo(String code, int minSpent, int maxSpent,
                                                String titleVi, String titleEn,
                                                List<String> benefitsVi, List<String> benefitsEn) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("minSpent", minSpent);
        m.put("maxSpent", maxSpent == Integer.MAX_VALUE ? null : maxSpent);
        m.put("titleVi", titleVi);
        m.put("titleEn", titleEn);
        m.put("benefitsVi", benefitsVi);
        m.put("benefitsEn", benefitsEn);
        return m;
    }

    private static String formatVnd(int amount) {
        return String.format(java.util.Locale.GERMAN, "%,d", amount).replace(',', '.') + "đ";
    }

    private static String formatVndEn(int amount) {
        return String.format(java.util.Locale.US, "%,d", amount) + " VND";
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
        map.put("nextTier", nextTierName(totalSpent));
        map.put("spentToNextTier", spentToNextTier(totalSpent));
        map.put("active", active);
        map.put("createdAt", createdAt);
        return map;
    }
}
