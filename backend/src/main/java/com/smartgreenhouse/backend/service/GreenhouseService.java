package com.smartgreenhouse.backend.service;

import com.smartgreenhouse.backend.db.Database;
import com.smartgreenhouse.backend.util.Json;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class GreenhouseService {
    public String checkDatabase() {
        try (Connection connection = Database.open();
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("select 1")) {
            return "{\"success\":true,\"message\":\"database connected\"}";
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String listGreenhouses() {
        String[] queries = {
                "select id,name,location,area,stage from greenhouses order by id",
                "select id,name,location,area,stage from greenhouse order by id",
                "select greenhouse_id as id,greenhouse_name as name,location,area,growth_stage as stage from greenhouse_info order by greenhouse_id"
        };

        for (String query : queries) {
            try (Connection connection = Database.open();
                 Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(query)) {
                StringBuilder json = new StringBuilder("{\"success\":true,\"items\":[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) {
                        json.append(',');
                    }
                    first = false;
                    json.append('{')
                            .append("\"id\":\"").append(Json.escape(rs.getString("id"))).append("\",")
                            .append("\"name\":\"").append(Json.escape(rs.getString("name"))).append("\",")
                            .append("\"location\":\"").append(Json.escape(rs.getString("location"))).append("\",")
                            .append("\"area\":\"").append(Json.escape(rs.getString("area"))).append("\",")
                            .append("\"stage\":\"").append(Json.escape(rs.getString("stage"))).append("\"")
                            .append('}');
                }
                json.append("]}");
                return json.toString();
            } catch (SQLException ignored) {
                // Try the next common schema variant.
            }
        }
        return "{\"success\":false,\"items\":[],\"message\":\"greenhouse table not found; /db/health can still verify database connectivity\"}";
    }

    public String listTables() {
        String query = "select table_schema, table_name from information_schema.tables "
                + "where table_type='BASE TABLE' "
                + "and table_schema not in ('sys_catalog','information_schema','pg_catalog') "
                + "order by table_schema, table_name";

        try (Connection connection = Database.open();
             Statement statement = connection.createStatement()) {
            connection.setReadOnly(true);
            statement.setQueryTimeout(8);
            ResultSet rs = statement.executeQuery(query);
            try {
            StringBuilder json = new StringBuilder("{\"success\":true,\"items\":[");
            boolean first = true;
            while (rs.next()) {
                String schema = rs.getString("table_schema");
                String table = rs.getString("table_name");
                Long rows = countRows(connection, schema, table);
                if (!first) {
                    json.append(',');
                }
                first = false;
                json.append('{')
                        .append("\"schema\":\"").append(Json.escape(schema)).append("\",")
                        .append("\"name\":\"").append(Json.escape(table)).append("\",")
                        .append("\"rows\":").append(rows == null ? "null" : rows.toString())
                        .append('}');
            }
            json.append("]}");
            return json.toString();
            } finally {
                rs.close();
            }
        } catch (SQLException ex) {
            return "{\"success\":false,\"items\":[],\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String latestSensor(String greenhouseId) {
        String[] queries = {
                "select air_temperature,air_humidity,soil_temperature,soil_humidity,light,co2,o2,ph,fan_gear,light_on,board_on,water_pump_on,medicine_pump_on,ai_warning,growth_stage,updated_at from sensor_data where greenhouse_id='" + sql(greenhouseId) + "' order by updated_at desc limit 1",
                "select air_temperature,air_humidity,soil_temperature,soil_humidity,light,co2,o2,ph,fan_gear,light_on,board_on,water_pump_on,medicine_pump_on,ai_warning,growth_stage,updated_at from environment_data where greenhouse_id='" + sql(greenhouseId) + "' order by updated_at desc limit 1",
                "select temperature as air_temperature,humidity as air_humidity,soil_temperature,soil_humidity,light,co2,o2,ph,0 as fan_gear,false as light_on,false as board_on,false as water_pump_on,false as medicine_pump_on,'' as ai_warning,0 as growth_stage,created_at as updated_at from environment_records where greenhouse_id='" + sql(greenhouseId) + "' order by created_at desc limit 1"
        };

        for (String query : queries) {
            try (Connection connection = Database.open();
                 Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(query)) {
                if (rs.next()) {
                    return "{\"success\":true,\"sensor\":" + sensorJson(rs) + "}";
                }
            } catch (SQLException ignored) {
                // Try the next common schema variant.
            }
        }
        return "{\"success\":false,\"message\":\"sensor table not found or no rows for greenhouseId=" + Json.escape(greenhouseId) + "\"}";
    }

    private String sensorJson(ResultSet rs) throws SQLException {
        return "{"
                + "\"airTemperature\":" + number(rs, "air_temperature", 0) + ","
                + "\"airHumidity\":" + number(rs, "air_humidity", 0) + ","
                + "\"soilTemperature\":" + number(rs, "soil_temperature", 0) + ","
                + "\"soilHumidity\":" + number(rs, "soil_humidity", 0) + ","
                + "\"light\":" + number(rs, "light", 0) + ","
                + "\"co2\":" + number(rs, "co2", 0) + ","
                + "\"o2\":" + number(rs, "o2", 0) + ","
                + "\"ph\":" + number(rs, "ph", 0) + ","
                + "\"fanGear\":" + integer(rs, "fan_gear", 0) + ","
                + "\"lightOn\":" + bool(rs, "light_on") + ","
                + "\"boardOn\":" + bool(rs, "board_on") + ","
                + "\"waterPumpOn\":" + bool(rs, "water_pump_on") + ","
                + "\"medicinePumpOn\":" + bool(rs, "medicine_pump_on") + ","
                + "\"aiWarning\":\"" + Json.escape(string(rs, "ai_warning", "")) + "\","
                + "\"growthStage\":" + integer(rs, "growth_stage", 0) + ","
                + "\"updatedAt\":\"" + Json.escape(string(rs, "updated_at", "")) + "\""
                + "}";
    }

    private Long countRows(Connection connection, String schema, String table) {
        String query = "select count(*) from \"" + schema.replace("\"", "\"\"") + "\".\""
                + table.replace("\"", "\"\"") + "\"";
        try (Statement statement = connection.createStatement()) {
            statement.setQueryTimeout(5);
            try (ResultSet rs = statement.executeQuery(query)) {
                return rs.next() ? rs.getLong(1) : null;
            }
        } catch (SQLException ex) {
            return null;
        }
    }

    private String sql(String value) {
        return value == null ? "" : value.replace("'", "''");
    }

    private String number(ResultSet rs, String column, double fallback) {
        try {
            double value = rs.getDouble(column);
            return rs.wasNull() ? Double.toString(fallback) : Double.toString(value);
        } catch (SQLException ex) {
            return Double.toString(fallback);
        }
    }

    private int integer(ResultSet rs, String column, int fallback) {
        try {
            int value = rs.getInt(column);
            return rs.wasNull() ? fallback : value;
        } catch (SQLException ex) {
            return fallback;
        }
    }

    private boolean bool(ResultSet rs, String column) {
        try {
            return rs.getBoolean(column);
        } catch (SQLException ex) {
            return false;
        }
    }

    private String string(ResultSet rs, String column, String fallback) {
        try {
            String value = rs.getString(column);
            return value == null ? fallback : value;
        } catch (SQLException ex) {
            return fallback;
        }
    }
}
