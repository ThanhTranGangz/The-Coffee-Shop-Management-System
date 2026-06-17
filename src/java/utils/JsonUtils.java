package utils;

import java.lang.reflect.Field;
import java.util.*;

@SuppressWarnings("unchecked")
public class JsonUtils {

    /**
     * Converts a Java Object (model bean, list, map, string, number, boolean) into a valid JSON string.
     */
    public static String toJson(Object obj) {
        if (obj == null) {
            return "null";
        }
        if (obj instanceof String) {
            return "\"" + escapeString((String) obj) + "\"";
        }
        if (obj instanceof Number || obj instanceof Boolean) {
            return obj.toString();
        }
        if (obj instanceof Collection) {
            Collection<?> col = (Collection<?>) obj;
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            for (Object item : col) {
                if (!first) sb.append(",");
                sb.append(toJson(item));
                first = false;
            }
            sb.append("]");
            return sb.toString();
        }
        if (obj instanceof Map) {
            Map<?, ?> map = (Map<?, ?>) obj;
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                if (!first) sb.append(",");
                sb.append("\"").append(escapeString(entry.getKey().toString())).append("\":");
                sb.append(toJson(entry.getValue()));
                first = false;
            }
            sb.append("}");
            return sb.toString();
        }
        // Reflection-based serialization for PoJos
        try {
            StringBuilder sb = new StringBuilder("{");
            Field[] fields = obj.getClass().getDeclaredFields();
            boolean first = true;
            for (Field field : fields) {
                field.setAccessible(true);
                Object val = field.get(obj);
                if (!first) sb.append(",");
                sb.append("\"").append(field.getName()).append("\":");
                sb.append(toJson(val));
                first = false;
            }
            sb.append("}");
            return sb.toString();
        } catch (Exception e) {
            return "{}";
        }
    }

    private static String escapeString(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            switch (ch) {
                case '"':  sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch < ' ') {
                        String t = "000" + Integer.toHexString(ch);
                        sb.append("\\u").append(t.substring(t.length() - 4));
                    } else {
                        sb.append(ch);
                    }
            }
        }
        return sb.toString();
    }

    /**
     * Parses a JSON string representing an object (map) into a Map<String, Object>.
     */
    public static Map<String, Object> parseObject(String json) {
        if (json == null) return new HashMap<>();
        json = json.trim();
        if (json.isEmpty() || !json.startsWith("{") || !json.endsWith("}")) {
            return new HashMap<>();
        }
        Parser parser = new Parser(json);
        Object result = parser.parseValue();
        if (result instanceof Map) {
            return (Map<String, Object>) result;
        }
        return new HashMap<>();
    }

    /**
     * Private tokenizer and parser class.
     */
    private static class Parser {
        private final String src;
        private int pos = 0;

        public Parser(String src) {
            this.src = src;
        }

        private void skipWhitespace() {
            while (pos < src.length() && Character.isWhitespace(src.charAt(pos))) {
                pos++;
            }
        }

        public Object parseValue() {
            skipWhitespace();
            if (pos >= src.length()) return null;

            char ch = src.charAt(pos);
            if (ch == '{') {
                return parseMap();
            } else if (ch == '[') {
                return parseList();
            } else if (ch == '"') {
                return parseString();
            } else if (ch == 't' || ch == 'f') {
                return parseBoolean();
            } else if (ch == 'n') {
                parseNull();
                return null;
            } else if (ch == '-' || Character.isDigit(ch)) {
                return parseNumber();
            }
            pos++;
            return null;
        }

        private Map<String, Object> parseMap() {
            Map<String, Object> map = new LinkedHashMap<>();
            pos++; // skip '{'
            skipWhitespace();
            if (pos < src.length() && src.charAt(pos) == '}') {
                pos++; // skip '}'
                return map;
            }

            while (true) {
                skipWhitespace();
                if (pos >= src.length() || src.charAt(pos) != '"') {
                    break;
                }
                String key = parseString();
                skipWhitespace();
                if (pos < src.length() && src.charAt(pos) == ':') {
                    pos++; // skip ':'
                }
                Object val = parseValue();
                map.put(key, val);

                skipWhitespace();
                if (pos < src.length() && src.charAt(pos) == ',') {
                    pos++; // skip ','
                } else if (pos < src.length() && src.charAt(pos) == '}') {
                    pos++; // skip '}'
                    break;
                } else {
                    break;
                }
            }
            return map;
        }

        private List<Object> parseList() {
            List<Object> list = new ArrayList<>();
            pos++; // skip '['
            skipWhitespace();
            if (pos < src.length() && src.charAt(pos) == ']') {
                pos++; // skip ']'
                return list;
            }

            while (true) {
                Object val = parseValue();
                list.add(val);

                skipWhitespace();
                if (pos < src.length() && src.charAt(pos) == ',') {
                    pos++; // skip ','
                } else if (pos < src.length() && src.charAt(pos) == ']') {
                    pos++; // skip ']'
                    break;
                } else {
                    break;
                }
            }
            return list;
        }

        private String parseString() {
            pos++; // skip initial '"'
            StringBuilder sb = new StringBuilder();
            while (pos < src.length()) {
                char ch = src.charAt(pos);
                if (ch == '"') {
                    pos++; // skip closing '"'
                    break;
                } else if (ch == '\\' && pos + 1 < src.length()) {
                    pos++;
                    char next = src.charAt(pos);
                    switch (next) {
                        case '"': sb.append('"'); break;
                        case '\\': sb.append('\\'); break;
                        case '/': sb.append('/'); break;
                        case 'b': sb.append('\b'); break;
                        case 'f': sb.append('\f'); break;
                        case 'n': sb.append('\n'); break;
                        case 'r': sb.append('\r'); break;
                        case 't': sb.append('\t'); break;
                        case 'u':
                            if (pos + 4 < src.length()) {
                                String hex = src.substring(pos + 1, pos + 5);
                                sb.append((char) Integer.parseInt(hex, 16));
                                pos += 4;
                            }
                            break;
                        default: sb.append(next);
                    }
                } else {
                    sb.append(ch);
                }
                pos++;
            }
            return sb.toString();
        }

        private Boolean parseBoolean() {
            if (src.startsWith("true", pos)) {
                pos += 4;
                return Boolean.TRUE;
            } else if (src.startsWith("false", pos)) {
                pos += 5;
                return Boolean.FALSE;
            }
            return null;
        }

        private void parseNull() {
            if (src.startsWith("null", pos)) {
                pos += 4;
            }
        }

        private Number parseNumber() {
            int start = pos;
            while (pos < src.length()) {
                char ch = src.charAt(pos);
                if (Character.isDigit(ch) || ch == '.' || ch == '-' || ch == '+' || ch == 'e' || ch == 'E') {
                    pos++;
                } else {
                    break;
                }
            }
            String numStr = src.substring(start, pos);
            if (numStr.contains(".") || numStr.contains("e") || numStr.contains("E")) {
                return Double.parseDouble(numStr);
            } else {
                return Long.parseLong(numStr);
            }
        }
    }
}
