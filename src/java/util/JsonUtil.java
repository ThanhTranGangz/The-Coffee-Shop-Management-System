package util;

/**
 * Tien ich nho de tu sinh chuoi JSON (khong dung thu vien ngoai
 * vi mon hoc gioi han thu vien duoc phep).
 */
public final class JsonUtil {

    private JsonUtil() {
    }

    /** Escape noi dung chuoi theo chuan JSON. */
    public static String esc(String s) {
        if (s == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder(s.length() + 8);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"':  sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b");  break;
                case '\f': sb.append("\\f");  break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                default:
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        return sb.toString();
    }

    /** Tra ve chuoi JSON dang "..." hoac null. */
    public static String str(String s) {
        return s == null ? "null" : "\"" + esc(s) + "\"";
    }
}
