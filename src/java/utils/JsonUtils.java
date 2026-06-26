package utils;

import java.util.*;

@SuppressWarnings("unchecked")
public class JsonUtils {
    public static String toJson(Object obj) {
        if (obj == null) return "null";
        if (obj instanceof String) return "\"" + escape((String) obj) + "\"";
        if (obj instanceof Number || obj instanceof Boolean) return obj.toString();
        if (obj instanceof Collection<?>) {
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            for (Object item : (Collection<?>) obj) {
                if (!first) sb.append(",");
                sb.append(toJson(item));
                first = false;
            }
            return sb.append("]").toString();
        }
        if (obj instanceof Map<?, ?>) {
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<?, ?> entry : ((Map<?, ?>) obj).entrySet()) {
                if (!first) sb.append(",");
                sb.append(toJson(String.valueOf(entry.getKey()))).append(":").append(toJson(entry.getValue()));
                first = false;
            }
            return sb.append("}").toString();
        }
        return "{}";
    }

    public static Map<String, Object> parseObject(String json) {
        Object parsed = new Parser(json == null ? "" : json).parseValue();
        return parsed instanceof Map ? (Map<String, Object>) parsed : new LinkedHashMap<>();
    }

    private static String escape(String s) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            switch (ch) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default: sb.append(ch);
            }
        }
        return sb.toString();
    }

    private static class Parser {
        private final String src;
        private int pos;

        Parser(String src) {
            this.src = src.trim();
        }

        Object parseValue() {
            skip();
            if (pos >= src.length()) return null;
            char ch = src.charAt(pos);
            if (ch == '{') return parseMap();
            if (ch == '[') return parseList();
            if (ch == '"') return parseString();
            if (src.startsWith("true", pos)) { pos += 4; return Boolean.TRUE; }
            if (src.startsWith("false", pos)) { pos += 5; return Boolean.FALSE; }
            if (src.startsWith("null", pos)) { pos += 4; return null; }
            return parseNumber();
        }

        private Map<String, Object> parseMap() {
            Map<String, Object> map = new LinkedHashMap<>();
            pos++;
            skip();
            while (pos < src.length() && src.charAt(pos) != '}') {
                String key = parseString();
                skip();
                if (pos < src.length() && src.charAt(pos) == ':') pos++;
                map.put(key, parseValue());
                skip();
                if (pos < src.length() && src.charAt(pos) == ',') pos++;
                skip();
            }
            if (pos < src.length()) pos++;
            return map;
        }

        private List<Object> parseList() {
            List<Object> list = new ArrayList<>();
            pos++;
            skip();
            while (pos < src.length() && src.charAt(pos) != ']') {
                list.add(parseValue());
                skip();
                if (pos < src.length() && src.charAt(pos) == ',') pos++;
                skip();
            }
            if (pos < src.length()) pos++;
            return list;
        }

        private String parseString() {
            StringBuilder sb = new StringBuilder();
            if (pos < src.length() && src.charAt(pos) == '"') pos++;
            while (pos < src.length()) {
                char ch = src.charAt(pos++);
                if (ch == '"') break;
                if (ch == '\\' && pos < src.length()) {
                    char next = src.charAt(pos++);
                    if (next == 'n') sb.append('\n');
                    else if (next == 'r') sb.append('\r');
                    else if (next == 't') sb.append('\t');
                    else sb.append(next);
                } else {
                    sb.append(ch);
                }
            }
            return sb.toString();
        }

        private Number parseNumber() {
            int start = pos;
            while (pos < src.length() && "-0123456789.".indexOf(src.charAt(pos)) >= 0) pos++;
            String raw = src.substring(start, pos);
            if (raw.contains(".")) return Double.parseDouble(raw);
            try {
                return Integer.parseInt(raw);
            } catch (NumberFormatException e) {
                return 0;
            }
        }

        private void skip() {
            while (pos < src.length() && Character.isWhitespace(src.charAt(pos))) pos++;
        }
    }
}
