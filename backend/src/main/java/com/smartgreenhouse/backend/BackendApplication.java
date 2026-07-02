package com.smartgreenhouse.backend;

import com.smartgreenhouse.backend.http.ApiServer;

public class BackendApplication {
    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(env("SERVER_PORT", "8080"));
        ApiServer server = new ApiServer(port);
        server.start();
        System.out.println("Smart Greenhouse backend started at http://localhost:" + port);
        System.out.println("Kingbase URL: " + env("KINGBASE_URL", "jdbc:kingbase8://101.42.99.139:54321/smart_greenhouse"));
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }
}
