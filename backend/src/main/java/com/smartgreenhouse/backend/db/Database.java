package com.smartgreenhouse.backend.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class Database {
    private Database() {
    }

    public static Connection open() throws SQLException {
        try {
            Class.forName("com.kingbase8.Driver");
        } catch (ClassNotFoundException ex) {
            throw new SQLException("KingbaseES JDBC driver not found. Put kingbase8.jar in backend/lib.", ex);
        }

        String url = env("KINGBASE_URL", "jdbc:kingbase8://192.168.43.36:54321/smart_greenhouse");
        String username = env("KINGBASE_USERNAME", "system");
        String password = env("KINGBASE_PASSWORD", "123456");
        return DriverManager.getConnection(url, username, password);
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }
}
