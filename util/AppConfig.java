package util;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

/**
 * Cau hinh chung cua quan: ten quan, ty le tich diem, tai khoan nhan
 * chuyen khoan VietQR (demo).
 */
public final class AppConfig {

    private AppConfig() {
    }

    /** Ten quan hien thi tren giao dien khach hang. */
    public static final String SHOP_NAME = "nhà cà phê";

    /** So tien (VND) de tich duoc 1 diem thuong. */
    public static final int VND_PER_POINT = 10_000;

    // ---- Thong tin nhan chuyen khoan (demo, thay bang STK that cua quan) ----
    public static final String BANK_ID = "MB";
    public static final String BANK_NAME = "MB Bank";
    public static final String BANK_ACCOUNT_NO = "0901234567890";
    public static final String BANK_ACCOUNT_NAME = "NHA CA PHE";

    /** So diem tich duoc cho mot don co gia tri finalAmount. */
    public static int pointsForAmount(int finalAmount) {
        if (finalAmount <= 0) {
            return 0;
        }
        return finalAmount / VND_PER_POINT;
    }

    /** Noi dung chuyen khoan de doi soat don. */
    public static String paymentMemo(int orderId) {
        return "CAPHE DON " + orderId;
    }

    /** URL anh ma VietQR dong (dich vu img.vietqr.io). */
    public static String vietQrImageUrl(int amount, int orderId) {
        try {
            return "https://img.vietqr.io/image/" + BANK_ID + "-" + BANK_ACCOUNT_NO
                    + "-compact2.png?amount=" + amount
                    + "&addInfo=" + URLEncoder.encode(paymentMemo(orderId), "UTF-8")
                    + "&accountName=" + URLEncoder.encode(BANK_ACCOUNT_NAME, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            return "";
        }
    }
}
