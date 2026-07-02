package com.smartgreenhouse.backend.service;

import com.smartgreenhouse.backend.util.Json;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class HuaweiCloudService {
    private static final String IOT_IAM_URL = env("HUAWEI_IOT_IAM_URL",
            "https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens");
    private static final String IOT_ENDPOINT = env("HUAWEI_IOTDA_ENDPOINT",
            "https://b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com:443");
    private static final String IOT_PROJECT_ID = env("HUAWEI_IOT_PROJECT_ID",
            "0e7c5e04a662439c813433f94d7ad4e7");
    private static final String IOT_DEVICE_ID = env("HUAWEI_IOT_DEVICE_ID",
            "6a3a6da1cbb0cf6bb96829a4_WHYwhy");
    private static final String IOT_SERVICE_ID = env("HUAWEI_IOT_SERVICE_ID", "王昊洋");

    private static final CloudAccount IOT_ACCOUNT = new CloudAccount(
            env("HUAWEI_IOT_USERNAME", "why"),
            env("HUAWEI_IOT_PASSWORD", "why123456"),
            env("HUAWEI_IOT_DOMAIN", "why66665"),
            env("HUAWEI_IOT_PROJECT_NAME", "cn-north-4"));

    private String iotToken = "";
    private long iotTokenExpireAtMs = 0L;

    public String latestShadow() {
        try {
            String token = iotToken();
            String url = IOT_ENDPOINT + "/v5/iot/" + IOT_PROJECT_ID + "/devices/" + IOT_DEVICE_ID + "/shadow";
            HttpResult result = request("GET", url, null, token, "application/json");
            if (result.status < 200 || result.status >= 300) {
                return "{\"success\":false,\"message\":\"Huawei IoT shadow HTTP " + result.status + ": "
                        + Json.escape(result.body) + "\"}";
            }
            return "{\"success\":true,\"sensor\":" + sensorJsonFromShadow(result.body) + "}";
        } catch (IOException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String sendCommand(String commandName, String value) {
        try {
            Command command = command(commandName, value);
            String token = iotToken();
            String url = IOT_ENDPOINT + "/v5/iot/" + IOT_PROJECT_ID + "/devices/" + IOT_DEVICE_ID + "/commands";
            String body = "{"
                    + "\"service_id\":\"" + Json.escape(IOT_SERVICE_ID) + "\","
                    + "\"command_name\":\"" + Json.escape(command.name) + "\","
                    + "\"expire_time\":0,"
                    + "\"paras\":{\"" + Json.escape(command.param) + "\":" + command.jsonValue + "}"
                    + "}";
            HttpResult result = request("POST", url, body, token, "application/json;charset=UTF-8", 5_000, 8_000, true);
            if (result.status >= 200 && result.status < 300) {
                return "{\"success\":true}";
            }
            return "{\"success\":false,\"message\":\"Huawei IoT command HTTP " + result.status + ": "
                    + Json.escape(result.body) + "\"}";
        } catch (IOException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    private synchronized String iotToken() throws IOException {
        long now = System.currentTimeMillis();
        if (iotToken.length() > 0 && now < iotTokenExpireAtMs - 60_000L) {
            return iotToken;
        }
        Token token = fetchToken(IOT_IAM_URL, IOT_ACCOUNT);
        iotToken = token.value;
        iotTokenExpireAtMs = token.expireAtMs;
        return iotToken;
    }

    private Token fetchToken(String url, CloudAccount account) throws IOException {
        HttpResult result = request("POST", url, authBody(account), null, "application/json; charset=utf-8");
        if (result.status < 200 || result.status >= 300) {
            throw new IOException("Huawei IAM HTTP " + result.status + ": " + result.body);
        }
        String token = result.header("X-Subject-Token");
        if (token.length() == 0) {
            throw new IOException("Huawei IAM response missing X-Subject-Token");
        }
        return new Token(token, System.currentTimeMillis() + 60 * 60_000L);
    }

    private String authBody(CloudAccount account) {
        return "{"
                + "\"auth\":{"
                + "\"identity\":{"
                + "\"methods\":[\"password\"],"
                + "\"password\":{\"user\":{"
                + "\"name\":\"" + Json.escape(account.username) + "\","
                + "\"password\":\"" + Json.escape(account.password) + "\","
                + "\"domain\":{\"name\":\"" + Json.escape(account.domain) + "\"}"
                + "}}"
                + "},"
                + "\"scope\":{\"project\":{\"name\":\"" + Json.escape(account.projectName) + "\"}}"
                + "}"
                + "}";
    }

    private HttpResult request(String method, String urlText, String body, String token, String contentType)
            throws IOException {
        return request(method, urlText, body, token, contentType, 12_000, 20_000);
    }

    private HttpResult request(String method, String urlText, String body, String token, String contentType,
                               int connectTimeoutMs, int readTimeoutMs)
            throws IOException {
        return request(method, urlText, body, token, contentType, connectTimeoutMs, readTimeoutMs, false);
    }

    private HttpResult request(String method, String urlText, String body, String token, String contentType,
                               int connectTimeoutMs, int readTimeoutMs, boolean skipSuccessBody)
            throws IOException {
        HttpURLConnection connection = (HttpURLConnection) new URL(urlText).openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(connectTimeoutMs);
        connection.setReadTimeout(readTimeoutMs);
        connection.setRequestProperty("Content-Type", contentType);
        connection.setRequestProperty("Connection", "close");
        if (token != null && token.length() > 0) {
            connection.setRequestProperty("X-Auth-Token", token);
        }
        if (body != null) {
            connection.setDoOutput(true);
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            connection.setRequestProperty("Content-Length", Integer.toString(bytes.length));
            try (OutputStream output = connection.getOutputStream()) {
                output.write(bytes);
            }
        }
        int status = connection.getResponseCode();
        if (skipSuccessBody && status >= 200 && status < 300) {
            return new HttpResult(status, "", connection.getHeaderField("X-Subject-Token"));
        }
        String response = read(status >= 400 ? connection.getErrorStream() : connection.getInputStream());
        return new HttpResult(status, response, connection.getHeaderField("X-Subject-Token"));
    }

    private String read(InputStream input) throws IOException {
        if (input == null) {
            return "";
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int read;
        while ((read = input.read(buffer)) != -1) {
            output.write(buffer, 0, read);
        }
        return new String(output.toByteArray(), StandardCharsets.UTF_8);
    }

    private String sensorJsonFromShadow(String body) {
        return "{"
                + "\"airTemperature\":" + firstNumber(body, -1, "Temp", "temperature", "airTemperature") + ","
                + "\"airHumidity\":" + firstNumber(body, -1, "Humi", "humidity", "airHumidity") + ","
                + "\"soilTemperature\":" + firstNumber(body, -1, "Soil_Temp", "SoilTemp", "soilTemperature") + ","
                + "\"soilHumidity\":" + firstNumber(body, -1, "Soil_Humi", "SoilHumi", "soilHumidity", "hum") + ","
                + "\"light\":" + firstNumber(body, -1, "Lumi", "light", "lightIntensity") + ","
                + "\"co2\":" + firstNumber(body, -1, "CO2", "co2", "Co2") + ","
                + "\"o2\":" + firstNumber(body, -1, "O2", "o2") + ","
                + "\"ph\":" + firstNumber(body, -1, "pH", "PH", "ph") + ","
                + "\"distance\":" + firstNumber(body, -1, "Dist", "distance", "Distance") + ","
                + "\"fanGear\":" + integer(body, 0, "Fengd", "fengdegree", "fanGear") + ","
                + "\"lightOn\":" + bool(body, "LightSt", "LampST", "light") + ","
                + "\"boardOn\":" + bool(body, "board", "DangGuangBan", "windBoardStatus") + ","
                + "\"waterPumpOn\":" + bool(body, "Bump", "BUMP", "bump", "pump") + ","
                + "\"medicinePumpOn\":" + bool(body, "MedicinePump", "MedicineBump", "DrugPump", "YaoPump", "YaoBump") + ","
                + "\"aiWarning\":\"" + Json.escape(firstText(body, "", "AIWarning", "aiWarning")) + "\","
                + "\"growthStage\":" + integer(body, 0, "GrowthStage", "State", "growthStage") + ","
                + "\"updatedAt\":\"" + Json.escape(firstText(body, "", "event_time", "last_update_time")) + "\""
                + "}";
    }

    private Command command(String commandName, String value) {
        if ("LightSt".equals(commandName) || "Light".equals(commandName)) {
            return new Command("Light", "light", jsonValue(value));
        }
        if ("DangGuangBan".equals(commandName) || "Board".equals(commandName)) {
            return new Command("Board", "board", jsonValue(value));
        }
        if ("Fengd".equals(commandName) || "Fengdegree".equals(commandName)) {
            int gear = (int) Math.max(0, Math.min(9, parseDouble(value, 0)));
            return new Command("Fengdegree", "fengdegree", Integer.toString(gear));
        }
        if ("BUMP".equals(commandName)) {
            return new Command("BUMP", "bump", jsonValue(value));
        }
        return new Command(commandName, commandName, jsonValue(value));
    }

    private String jsonValue(String value) {
        if ("true".equalsIgnoreCase(value) || "false".equalsIgnoreCase(value)) {
            return value.toLowerCase();
        }
        if (value != null && value.matches("-?\\d+(\\.\\d+)?")) {
            return value;
        }
        return "\"" + Json.escape(value == null ? "" : value) + "\"";
    }

    private double firstNumber(String body, double fallback, String... keys) {
        for (String key : keys) {
            String value = extract(body, key);
            if (value.length() > 0) {
                return parseDouble(value, fallback);
            }
        }
        return fallback;
    }

    private double number(String body, String key, double fallback) {
        return firstNumber(body, fallback, key);
    }

    private int integer(String body, int fallback, String... keys) {
        return (int) firstNumber(body, fallback, keys);
    }

    private boolean bool(String body, String... keys) {
        String value = firstText(body, "", keys);
        return "ON".equalsIgnoreCase(value)
                || "true".equalsIgnoreCase(value)
                || "1".equals(value)
                || "开".equals(value);
    }

    private String firstText(String body, String fallback, String... keys) {
        for (String key : keys) {
            String value = extract(body, key);
            if (value.length() > 0) {
                return value;
            }
        }
        return fallback;
    }

    private String extract(String body, String key) {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*(\"((?:\\\\.|[^\"])*)\"|-?\\d+(?:\\.\\d+)?|true|false|null)");
        Matcher matcher = pattern.matcher(body == null ? "" : body);
        if (!matcher.find()) {
            return "";
        }
        String quoted = matcher.group(2);
        if (quoted != null) {
            return quoted;
        }
        String raw = matcher.group(1);
        return raw == null || "null".equals(raw) ? "" : raw;
    }

    private double parseDouble(String value, double fallback) {
        if (value == null) {
            return fallback;
        }
        try {
            return Double.parseDouble(value.trim());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private static final class CloudAccount {
        final String username;
        final String password;
        final String domain;
        final String projectName;

        CloudAccount(String username, String password, String domain, String projectName) {
            this.username = username;
            this.password = password;
            this.domain = domain;
            this.projectName = projectName;
        }
    }

    private static final class Token {
        final String value;
        final long expireAtMs;

        Token(String value, long expireAtMs) {
            this.value = value;
            this.expireAtMs = expireAtMs;
        }
    }

    private static final class HttpResult {
        final int status;
        final String body;
        final String subjectToken;

        HttpResult(int status, String body, String subjectToken) {
            this.status = status;
            this.body = body == null ? "" : body;
            this.subjectToken = subjectToken == null ? "" : subjectToken;
        }

        String header(String name) {
            return "X-Subject-Token".equalsIgnoreCase(name) ? subjectToken : "";
        }
    }

    private static final class Command {
        final String name;
        final String param;
        final String jsonValue;

        Command(String name, String param, String jsonValue) {
            this.name = name;
            this.param = param;
            this.jsonValue = jsonValue;
        }
    }
}
