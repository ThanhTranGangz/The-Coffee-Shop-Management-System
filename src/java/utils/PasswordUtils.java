package utils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;

/**
 * Băm mật khẩu khách hàng bằng SHA-256 kèm salt ngẫu nhiên cho từng tài khoản.
 *
 * Vì sao không lưu mật khẩu thô như bảng dbo.Users:
 *   - Users chỉ có 4 tài khoản nội bộ do quán tự quản lý.
 *   - Customers là tài khoản của người ngoài, và người dùng thường
 *     tái sử dụng mật khẩu ở nơi khác. Lộ DB không được phép đồng nghĩa
 *     với lộ mật khẩu.
 *
 * Ghi chú thẳng thắn: SHA-256 + salt là mức tối thiểu chấp nhận được.
 * Hệ thống chạy thật nên dùng bcrypt/scrypt/Argon2 (có hệ số chi phí
 * chống brute-force bằng GPU). Ở đây chọn SHA-256 vì dự án không được
 * phép thêm thư viện ngoài, và JDK có sẵn MessageDigest.
 */
public final class PasswordUtils {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int SALT_BYTES = 8;   // 16 ký tự hex
    private static final int MIN_LENGTH = 6;
    private static final int MAX_LENGTH = 64;

    private PasswordUtils() {
    }

    /** Sinh salt ngẫu nhiên dạng hex thường, dài 16 ký tự. */
    public static String newSalt() {
        byte[] bytes = new byte[SALT_BYTES];
        RANDOM.nextBytes(bytes);
        return toHex(bytes);
    }

    /** Băm mật khẩu: SHA-256(salt + password) trả về 64 ký tự hex. */
    public static String hash(String password, String salt) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(value(salt).getBytes(StandardCharsets.UTF_8));
            digest.update(value(password).getBytes(StandardCharsets.UTF_8));
            return toHex(digest.digest());
        } catch (Exception e) {
            throw new IllegalStateException("Không băm được mật khẩu.", e);
        }
    }

    /**
     * So khớp mật khẩu. Dùng so sánh thời gian hằng số để không rò rỉ
     * thông tin qua thời gian phản hồi.
     */
    public static boolean matches(String password, String salt, String expectedHash) {
        String actual = hash(password, salt);
        return constantTimeEquals(actual, value(expectedHash));
    }

    /** Ném IllegalArgumentException nếu mật khẩu không đạt yêu cầu tối thiểu. */
    public static void validate(String password) {
        String raw = value(password);
        if (raw.length() < MIN_LENGTH) {
            throw new IllegalArgumentException("Mật khẩu phải có ít nhất " + MIN_LENGTH + " ký tự.");
        }
        if (raw.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Mật khẩu tối đa " + MAX_LENGTH + " ký tự.");
        }
        if (raw.chars().distinct().count() < 2) {
            throw new IllegalArgumentException("Mật khẩu quá đơn giản.");
        }
    }

    /**
     * Chuẩn hoá số điện thoại Việt Nam về dạng chỉ chứa chữ số.
     * Trả về chuỗi rỗng nếu không hợp lệ.
     */
    public static String normalizePhone(String phone) {
        String digits = value(phone).replaceAll("[^0-9+]", "");
        if (digits.startsWith("+84")) digits = "0" + digits.substring(3);
        else if (digits.startsWith("84") && digits.length() > 10) digits = "0" + digits.substring(2);
        digits = digits.replaceAll("[^0-9]", "");
        if (digits.length() < 9 || digits.length() > 11) return "";
        if (!digits.startsWith("0")) return "";
        return digits;
    }

    private static boolean constantTimeEquals(String left, String right) {
        if (left == null || right == null) return false;
        if (left.length() != right.length()) return false;
        int diff = 0;
        for (int i = 0; i < left.length(); i++) {
            diff |= left.charAt(i) ^ right.charAt(i);
        }
        return diff == 0;
    }

    private static String toHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(Character.forDigit((b >> 4) & 0xF, 16));
            sb.append(Character.forDigit(b & 0xF, 16));
        }
        return sb.toString();
    }

    private static String value(String raw) {
        return raw == null ? "" : raw;
    }
}
