package com.smartgreenhouse.backend.service;

import com.smartgreenhouse.backend.util.Json;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public class DeepSeekService {
    private static final String DEFAULT_ENDPOINT = "https://api.deepseek.com/chat/completions";
    private static final String DEFAULT_MODEL = "deepseek-chat";

    public String chat(String text, String history) {
        if (text == null || text.trim().isEmpty()) {
            return "{\"answer\":\"请输入问题。\"}";
        }
        String prompt = "你是羊肚菌智慧大棚系统里的种植助手。请用中文回答，"
                + "回答要具体、简洁、可执行。不要编造传感器数据。";
        String user = "历史对话：\n" + value(history) + "\n\n用户问题：\n" + text.trim();
        return "{\"answer\":\"" + Json.escape(callDeepSeek(prompt, user)) + "\"}";
    }

    public String suggestion(String prompt) {
        String system = "你是羊肚菌智慧大棚的种植决策专家。请严格按以下四段输出：\n"
                + "风险等级：低/中/高\n"
                + "核心问题：一句话概括\n"
                + "紧急操作：给出1到3条立即可做的操作\n"
                + "详细建议：结合温度、湿度、光照、CO2、土壤数据给出后续建议。";
        String user = value(prompt);
        if (user.trim().isEmpty()) {
            user = "请根据当前大棚环境数据生成种植建议。";
        }
        return "{\"suggestion\":\"" + Json.escape(callDeepSeek(system, user)) + "\"}";
    }

    private String callDeepSeek(String system, String user) {
        String apiKey = env("DEEPSEEK_API_KEY", "");
        if (apiKey.isEmpty()) {
            return "AI 服务未配置 DeepSeek API Key，请在后端设置 DEEPSEEK_API_KEY。";
        }

        HttpURLConnection connection = null;
        try {
            URL url = new URL(env("DEEPSEEK_API_URL", DEFAULT_ENDPOINT));
            connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(12000);
            connection.setReadTimeout(45000);
            connection.setRequestMethod("POST");
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            connection.setRequestProperty("Authorization", "Bearer " + apiKey);

            String body = "{"
                    + "\"model\":\"" + Json.escape(env("DEEPSEEK_MODEL", DEFAULT_MODEL)) + "\","
                    + "\"temperature\":0.4,"
                    + "\"stream\":false,"
                    + "\"messages\":["
                    + "{\"role\":\"system\",\"content\":\"" + Json.escape(system) + "\"},"
                    + "{\"role\":\"user\",\"content\":\"" + Json.escape(user) + "\"}"
                    + "]"
                    + "}";
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            try (OutputStream output = connection.getOutputStream()) {
                output.write(bytes);
            }

            int code = connection.getResponseCode();
            String response = read(code >= 200 && code < 300 ? connection.getInputStream() : connection.getErrorStream());
            if (code < 200 || code >= 300) {
                return "AI 服务调用失败：" + summarize(response);
            }
            String content = Json.extractString(response, "content", "");
            return content.isEmpty() ? "AI 暂未返回有效内容，请稍后重试。" : content;
        } catch (Exception ex) {
            return "AI 服务暂时不可用：" + ex.getMessage();
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    private String read(InputStream input) throws Exception {
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

    private String summarize(String text) {
        String value = text == null ? "" : text.replace('\n', ' ').replace('\r', ' ').trim();
        return value.length() > 180 ? value.substring(0, 180) : value;
    }

    private String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private String value(String text) {
        return text == null ? "" : text;
    }
}
