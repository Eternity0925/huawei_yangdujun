package com.smartgreenhouse.backend.http;

import com.smartgreenhouse.backend.service.GreenhouseService;
import com.smartgreenhouse.backend.service.HuaweiCloudService;
import com.smartgreenhouse.backend.service.AuthService;
import com.smartgreenhouse.backend.service.DeepSeekService;
import com.smartgreenhouse.backend.util.Json;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;

public class ApiServer {
    private final HttpServer server;
    private final GreenhouseService greenhouseService = new GreenhouseService();
    private final HuaweiCloudService huaweiCloudService = new HuaweiCloudService();
    private final AuthService authService = new AuthService();
    private final DeepSeekService deepSeekService = new DeepSeekService();

    public ApiServer(int port) throws IOException {
        server = HttpServer.create(new InetSocketAddress("0.0.0.0", port), 0);
        server.setExecutor(Executors.newFixedThreadPool(8));
        routes();
    }

    public void start() {
        server.start();
    }

    private void routes() {
        server.createContext("/health", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, "{\"success\":true,\"message\":\"ok\"}");
        });

        server.createContext("/db/health", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, greenhouseService.checkDatabase());
        });

        server.createContext("/db/tables", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, greenhouseService.listTables());
        });

        server.createContext("/greenhouses", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                String body = read(exchange);
                String userId = Json.extractString(body, "userId", "");
                String name = Json.extractString(body, "name", "");
                String location = Json.extractString(body, "location", "");
                String area = Json.extractString(body, "area", "");
                send(exchange, 200, greenhouseService.createGreenhouse(userId, name, location, area));
                return;
            }
            String userId = queryParam(exchange, "userId");
            send(exchange, 200, greenhouseService.listGreenhouses(userId));
        });

        server.createContext("/greenhouse/delete", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String userId = Json.extractString(body, "userId", "");
            String greenhouseId = Json.extractString(body, "greenhouseId", "");
            send(exchange, 200, greenhouseService.deleteGreenhouse(userId, greenhouseId));
        });

        server.createContext("/auth/login", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String account = Json.extractString(body, "account", "");
            String password = Json.extractString(body, "password", "");
            send(exchange, 200, authService.loginFarmer(account, password));
        });

        server.createContext("/auth/register", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String phone = Json.extractString(body, "phone", "");
            String password = Json.extractString(body, "password", "");
            send(exchange, 200, authService.registerFarmer(phone, password));
        });

        server.createContext("/auth/reset-password", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String phone = Json.extractString(body, "phone", "");
            String password = Json.extractString(body, "password", "");
            send(exchange, 200, authService.resetFarmerPassword(phone, password));
        });

        server.createContext("/sensor/latest", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String greenhouseId = queryParam(exchange, "greenhouseId");
            send(exchange, 200, greenhouseService.latestSensor(greenhouseId));
        });

        server.createContext("/sensor/history", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String greenhouseId = queryParam(exchange, "greenhouseId");
            int limit = intParam(exchange, "limit", 24);
            send(exchange, 200, greenhouseService.sensorHistory(greenhouseId, limit));
        });

        server.createContext("/devices", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String greenhouseId = queryParam(exchange, "greenhouseId");
            send(exchange, 200, greenhouseService.listDevices(greenhouseId));
        });

        server.createContext("/alarms", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String greenhouseId = queryParam(exchange, "greenhouseId");
            send(exchange, 200, greenhouseService.listAlarms(greenhouseId));
        });

        server.createContext("/alarm/handle", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String alarmId = Json.extractString(body, "alarmId", "");
            String handlerName = Json.extractString(body, "handlerName", "");
            send(exchange, 200, greenhouseService.handleAlarm(alarmId, handlerName));
        });

        server.createContext("/threshold", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                String body = read(exchange);
                String greenhouseId = Json.extractString(body, "greenhouseId", "");
                send(exchange, 200, greenhouseService.saveThreshold(greenhouseId, body));
                return;
            }
            String greenhouseId = queryParam(exchange, "greenhouseId");
            send(exchange, 200, greenhouseService.threshold(greenhouseId));
        });

        server.createContext("/feedback", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String userId = Json.extractString(body, "userId", "");
            String content = Json.extractString(body, "content", "");
            String contact = Json.extractString(body, "contact", "");
            send(exchange, 200, greenhouseService.submitFeedback(userId, content, contact));
        });

        server.createContext("/iot/shadow", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            read(exchange);
            send(exchange, 200, huaweiCloudService.latestShadow());
        });

        server.createContext("/iot/command", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String commandName = Json.extractString(body, "commandName", "");
            String value = Json.extractValue(body, "value", "");
            send(exchange, 200, huaweiCloudService.sendCommand(commandName, value));
        });

        server.createContext("/ai/chat", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String text = Json.extractString(body, "text", "");
            String history = Json.extractString(body, "history", "");
            send(exchange, 200, deepSeekService.chat(text, history));
        });

        server.createContext("/ai/suggestion", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String prompt = Json.extractString(body, "prompt", "");
            send(exchange, 200, deepSeekService.suggestion(prompt));
        });

    }

    private boolean handleCors(HttpExchange exchange) throws IOException {
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type");
        exchange.getResponseHeaders().set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
        if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
            exchange.sendResponseHeaders(204, -1);
            exchange.close();
            return true;
        }
        return false;
    }

    private String read(HttpExchange exchange) throws IOException {
        InputStream input = exchange.getRequestBody();
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int read;
        while ((read = input.read(buffer)) != -1) {
            output.write(buffer, 0, read);
        }
        return new String(output.toByteArray(), StandardCharsets.UTF_8);
    }

    private String queryParam(HttpExchange exchange, String name) {
        String query = exchange.getRequestURI().getRawQuery();
        if (query == null || query.isEmpty()) {
            return "";
        }
        String prefix = name + "=";
        String[] parts = query.split("&");
        for (String part : parts) {
            if (part.startsWith(prefix)) {
                try {
                    return java.net.URLDecoder.decode(part.substring(prefix.length()), "UTF-8");
                } catch (java.io.UnsupportedEncodingException ex) {
                    return part.substring(prefix.length());
                }
            }
        }
        return "";
    }

    private int intParam(HttpExchange exchange, String name, int fallback) {
        try {
            String value = queryParam(exchange, name);
            return value.isEmpty() ? fallback : Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private void send(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
