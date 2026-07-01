package com.smartgreenhouse.backend.util;

public final class Json {
    private Json() {
    }

    public static String escape(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n")
                .replace("\t", "\\t");
    }

    public static String extractString(String json, String key, String fallback) {
        if (json == null || key == null) {
            return fallback;
        }
        String marker = "\"" + key + "\"";
        int keyIndex = json.indexOf(marker);
        if (keyIndex < 0) {
            return fallback;
        }
        int colon = json.indexOf(':', keyIndex + marker.length());
        if (colon < 0) {
            return fallback;
        }
        int startQuote = json.indexOf('"', colon + 1);
        if (startQuote < 0) {
            return fallback;
        }
        StringBuilder result = new StringBuilder();
        boolean escaped = false;
        for (int i = startQuote + 1; i < json.length(); i++) {
            char c = json.charAt(i);
            if (escaped) {
                result.append(c);
                escaped = false;
            } else if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                return result.toString();
            } else {
                result.append(c);
            }
        }
        return fallback;
    }

    public static String extractValue(String json, String key, String fallback) {
        if (json == null || key == null) {
            return fallback;
        }
        String marker = "\"" + key + "\"";
        int keyIndex = json.indexOf(marker);
        if (keyIndex < 0) {
            return fallback;
        }
        int colon = json.indexOf(':', keyIndex + marker.length());
        if (colon < 0) {
            return fallback;
        }
        int valueStart = colon + 1;
        while (valueStart < json.length() && Character.isWhitespace(json.charAt(valueStart))) {
            valueStart++;
        }
        if (valueStart >= json.length()) {
            return fallback;
        }
        if (json.charAt(valueStart) == '"') {
            return extractString(json, key, fallback);
        }
        int valueEnd = valueStart;
        while (valueEnd < json.length()) {
            char c = json.charAt(valueEnd);
            if (c == ',' || c == '}' || Character.isWhitespace(c)) {
                break;
            }
            valueEnd++;
        }
        return valueEnd > valueStart ? json.substring(valueStart, valueEnd) : fallback;
    }
}
