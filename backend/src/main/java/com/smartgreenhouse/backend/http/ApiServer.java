package com.smartgreenhouse.backend.http;

import com.smartgreenhouse.backend.service.GreenhouseService;
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
            send(exchange, 200, greenhouseService.listGreenhouses());
        });

        server.createContext("/iot/shadow", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            String body = read(exchange);
            String greenhouseId = Json.extractString(body, "greenhouseId", "default");
            send(exchange, 200, greenhouseService.latestSensor(greenhouseId));
        });

        server.createContext("/iot/command", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, "{\"success\":true}");
        });

        server.createContext("/ai/chat", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, "{\"answer\":\"后端已连接。AI 服务接口暂未配置。\"}");
        });

        server.createContext("/ai/suggestion", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, "{\"suggestion\":\"风险等级：低\\n核心问题：后端已连接数据库，可继续接入真实 AI 分析。\\n紧急操作：保持温湿度稳定。\\n详细建议：请根据实时传感器数据调整设备。\"}");
        });

        server.createContext("/voice/asr", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, "{\"answer\":\"\"}");
        });

        server.createContext("/map/baidu/token", exchange -> {
            if (handleCors(exchange)) {
                return;
            }
            send(exchange, 200, "{\"token\":\"\"}");
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

    private void send(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
