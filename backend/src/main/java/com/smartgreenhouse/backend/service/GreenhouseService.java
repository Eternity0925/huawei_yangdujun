package com.smartgreenhouse.backend.service;

import com.smartgreenhouse.backend.db.Database;
import com.smartgreenhouse.backend.util.Json;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;

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

    public String listGreenhouses(String userId) {
        Long farmerId = farmerId(userId);
        if (farmerId != null) {
            String query = "select distinct cast(g.id as varchar) as id,g.name,g.location,"
                    + "cast(g.area as varchar) as area,g.crop_stage as stage "
                    + "from greenhouse g "
                    + "left join farmer_greenhouse_binding b on b.greenhouse_id=g.id "
                    + "and (b.deleted is null or b.deleted=false) "
                    + "where (g.deleted is null or g.deleted=false) "
                    + "and (g.owner_user_id=? or b.farmer_user_id=?) "
                    + "order by g.id";
            try (Connection connection = Database.open();
                 PreparedStatement statement = connection.prepareStatement(query)) {
                statement.setLong(1, farmerId);
                statement.setLong(2, farmerId);
                try (ResultSet rs = statement.executeQuery()) {
                    return greenhousesJson(rs);
                }
            } catch (SQLException ignored) {
                // Fall back to the older schema variants below.
            }
        }

        String[] queries = {
                "select cast(id as varchar) as id,name,location,cast(area as varchar) as area,crop_stage as stage from greenhouse where deleted=false order by greenhouse.id",
                "select id,name,location,area,stage from greenhouses order by id",
                "select id,name,location,area,stage from greenhouse order by id",
                "select greenhouse_id as id,greenhouse_name as name,location,area,growth_stage as stage from greenhouse_info order by greenhouse_id"
        };
        for (String query : queries) {
            try (Connection connection = Database.open();
                 Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(query)) {
                return greenhousesJson(rs);
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
        String snapshotQuery = "select t.air_temperature,t.air_humidity,"
                + "t.soil_temperature,t.soil_humidity,t.light_lux as light,t.co2_ppm as co2,"
                + "-1 as o2,t.ph_value as ph,-1 as distance,-1 as fan_gear,"
                + "cast(null as boolean) as light_on,cast(null as boolean) as board_on,"
                + "cast(null as boolean) as water_pump_on,cast(null as boolean) as medicine_pump_on,"
                + "'' as ai_warning,"
                + "case "
                + "when g.crop_stage like '%菌丝%' then 1 "
                + "when g.crop_stage like '%催菇%' then 2 "
                + "when g.crop_stage like '%原基%' then 3 "
                + "when g.crop_stage like '%出菇%' then 4 "
                + "else 0 end as growth_stage,"
                + "t.collected_at as updated_at "
                + "from telemetry_snapshot t left join greenhouse g on g.id=t.greenhouse_id "
                + "where t.greenhouse_id=? order by t.collected_at desc limit 1";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(snapshotQuery)) {
            statement.setLong(1, longValue(greenhouseId, -1));
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return "{\"success\":true,\"sensor\":" + sensorJson(rs) + "}";
                }
            }
        } catch (SQLException ignored) {
            // Try legacy table names below.
        }

        String[] queries = {
                "select air_temperature,air_humidity,soil_temperature,soil_humidity,light,co2,o2,ph,fan_gear,light_on,board_on,water_pump_on,medicine_pump_on,ai_warning,growth_stage,updated_at from sensor_data where greenhouse_id='" + sql(greenhouseId) + "' order by updated_at desc limit 1",
                "select air_temperature,air_humidity,soil_temperature,soil_humidity,light,co2,o2,ph,fan_gear,light_on,board_on,water_pump_on,medicine_pump_on,ai_warning,growth_stage,updated_at from environment_data where greenhouse_id='" + sql(greenhouseId) + "' order by updated_at desc limit 1",
                "select temperature as air_temperature,humidity as air_humidity,soil_temperature,soil_humidity,light,co2,-1 as o2,ph,-1 as fan_gear,cast(null as boolean) as light_on,cast(null as boolean) as board_on,cast(null as boolean) as water_pump_on,cast(null as boolean) as medicine_pump_on,'' as ai_warning,0 as growth_stage,created_at as updated_at from environment_records where greenhouse_id='" + sql(greenhouseId) + "' order by created_at desc limit 1"
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
        long id = longValue(greenhouseId, -1);
        if (id > 0 && ensureGreenhouseRuntimeData(id, 336)) {
            return latestSensor(greenhouseId);
        }
        return "{\"success\":false,\"message\":\"sensor table not found or no rows for greenhouseId=" + Json.escape(greenhouseId) + "\"}";
    }

    public String sensorHistory(String greenhouseId, int limit) {
        long id = longValue(greenhouseId, -1);
        if (id > 0) {
            ensureGreenhouseRuntimeData(id, Math.max(24, Math.min(limit, 336)));
        }
        String query = "select * from (select cast(greenhouse_id as varchar) as greenhouse_id,"
                + "collected_at as time,air_temperature,air_humidity,"
                + "soil_temperature,soil_humidity,light_lux as light,co2_ppm as co2,"
                + "-1 as o2,ph_value as ph "
                + "from telemetry_snapshot where greenhouse_id=? "
                + "order by collected_at desc limit ?) t order by time";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, longValue(greenhouseId, -1));
            statement.setInt(2, Math.max(1, Math.min(limit, 336)));
            try (ResultSet rs = statement.executeQuery()) {
                StringBuilder json = new StringBuilder("{\"success\":true,\"items\":[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) {
                        json.append(',');
                    }
                    first = false;
                    json.append('{')
                            .append("\"greenhouseId\":\"").append(Json.escape(rs.getString("greenhouse_id"))).append("\",")
                            .append("\"time\":\"").append(Json.escape(string(rs, "time", ""))).append("\",")
                            .append("\"temperature\":").append(number(rs, "air_temperature", 0)).append(',')
                            .append("\"humidity\":").append(number(rs, "air_humidity", 0)).append(',')
                            .append("\"soilTemperature\":").append(number(rs, "soil_temperature", 0)).append(',')
                            .append("\"soilHumidity\":").append(number(rs, "soil_humidity", 0)).append(',')
                            .append("\"light\":").append(number(rs, "light", 0)).append(',')
                            .append("\"co2\":").append(number(rs, "co2", 0)).append(',')
                            .append("\"o2\":").append(number(rs, "o2", 0)).append(',')
                            .append("\"ph\":").append(number(rs, "ph", 0))
                            .append('}');
                }
                json.append("]}");
                return json.toString();
            }
        } catch (SQLException ex) {
            return "{\"success\":false,\"items\":[],\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String listDevices(String greenhouseId) {
        long id = longValue(greenhouseId, -1);
        if (id > 0) {
            try (Connection connection = Database.open()) {
                ensureDeviceRows(connection, id);
            } catch (SQLException ignored) {
            }
        }
        String query = "select id,name,category,status,auto_mode,health_score "
                + "from greenhouse_device where greenhouse_id=? "
                + "and (deleted is null or deleted=false) order by id";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, id);
            try (ResultSet rs = statement.executeQuery()) {
                StringBuilder json = new StringBuilder("{\"success\":true,\"items\":[");
                boolean first = true;
                while (rs.next()) {
                    String name = string(rs, "name", "");
                    String category = string(rs, "category", "");
                    String type = deviceType(category, name);
                    String status = string(rs, "status", "");
                    boolean enabled = isDeviceEnabled(status);
                    if (!first) {
                        json.append(',');
                    }
                    first = false;
                    String dbId = rs.getString("id");
                    json.append('{')
                            .append("\"id\":\"").append(Json.escape(greenhouseId + "-" + baseDeviceId(type, dbId) + "-" + dbId)).append("\",")
                            .append("\"name\":\"").append(Json.escape(name)).append("\",")
                            .append("\"type\":\"").append(Json.escape(type)).append("\",")
                            .append("\"status\":\"").append(Json.escape(status)).append("\",")
                            .append("\"greenhouseId\":\"").append(Json.escape(greenhouseId)).append("\",")
                            .append("\"enabled\":").append(enabled)
                            .append('}');
                }
                json.append("]}");
                return json.toString();
            }
        } catch (SQLException ex) {
            return "{\"success\":false,\"items\":[],\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String listAlarms(String greenhouseId) {
        boolean hasGreenhouse = greenhouseId != null && !greenhouseId.trim().isEmpty();
        String query = "select a.id,cast(a.greenhouse_id as varchar) as greenhouse_id,"
                + "coalesce(g.name,'') as greenhouse_name,coalesce(d.name,'环境传感器') as device,"
                + "a.title,a.description,a.level,a.status,a.occurred_at,a.handled_at,a.handled_by "
                + "from greenhouse_alert a "
                + "left join greenhouse g on g.id=a.greenhouse_id "
                + "left join greenhouse_device d on d.id=a.device_id "
                + "where (a.deleted is null or a.deleted=false) "
                + (hasGreenhouse ? "and a.greenhouse_id=? " : "")
                + "order by a.occurred_at desc limit 100";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            if (hasGreenhouse) {
                statement.setLong(1, longValue(greenhouseId, -1));
            }
            try (ResultSet rs = statement.executeQuery()) {
                StringBuilder json = new StringBuilder("{\"success\":true,\"items\":[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) {
                        json.append(',');
                    }
                    first = false;
                    json.append('{')
                            .append("\"id\":\"").append(Json.escape(rs.getString("id"))).append("\",")
                            .append("\"greenhouseId\":\"").append(Json.escape(rs.getString("greenhouse_id"))).append("\",")
                            .append("\"greenhouseName\":\"").append(Json.escape(string(rs, "greenhouse_name", ""))).append("\",")
                            .append("\"device\":\"").append(Json.escape(string(rs, "device", "环境传感器"))).append("\",")
                            .append("\"title\":\"").append(Json.escape(string(rs, "title", ""))).append("\",")
                            .append("\"content\":\"").append(Json.escape(string(rs, "description", ""))).append("\",")
                            .append("\"level\":\"").append(Json.escape(levelLabel(string(rs, "level", "")))).append("\",")
                            .append("\"status\":\"").append(Json.escape(statusLabel(string(rs, "status", "")))).append("\",")
                            .append("\"createdAt\":\"").append(Json.escape(string(rs, "occurred_at", ""))).append("\",")
                            .append("\"handledAt\":\"").append(Json.escape(string(rs, "handled_at", ""))).append("\",")
                            .append("\"handlerName\":\"").append(Json.escape(string(rs, "handled_by", ""))).append("\"")
                            .append('}');
                }
                json.append("]}");
                return json.toString();
            }
        } catch (SQLException ex) {
            return "{\"success\":false,\"items\":[],\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String handleAlarm(String alarmId, String handlerName) {
        String query = "update greenhouse_alert set status='RESOLVED',handled_by=?,handled_at=current_timestamp,"
                + "updated_at=current_timestamp where id=? and (deleted is null or deleted=false)";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setString(1, handlerName == null || handlerName.trim().isEmpty() ? "farmer001" : handlerName);
            statement.setLong(2, longValue(alarmId, -1));
            int updated = statement.executeUpdate();
            return "{\"success\":" + (updated > 0) + "}";
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String threshold(String greenhouseId) {
        long id = longValue(greenhouseId, -1);
        if (id > 0) {
            ensureThresholdRules(id);
        }
        double[] values = defaultThresholdValues();
        String query = "select metric_key,operator,threshold_value from alert_rule "
                + "where enabled=true and (deleted is null or deleted=false) "
                + "and (greenhouse_id is null or greenhouse_id=?) "
                + "order by case when greenhouse_id is null then 0 else 1 end,id";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, id);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    applyThreshold(values, string(rs, "metric_key", ""), string(rs, "operator", ""), rs.getDouble("threshold_value"));
                }
            }
            return "{\"success\":true,\"threshold\":" + thresholdJson(values) + "}";
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String saveThreshold(String greenhouseId, String body) {
        long id = longValue(greenhouseId, -1);
        if (id <= 0) {
            return "{\"success\":false,\"message\":\"invalid greenhouse id\"}";
        }
        double[] values = {
                jsonDouble(body, "tempMin", 16), jsonDouble(body, "tempMax", 24),
                jsonDouble(body, "airHumMin", 70), jsonDouble(body, "airHumMax", 92),
                jsonDouble(body, "soilTempMin", 16), jsonDouble(body, "soilTempMax", 24),
                jsonDouble(body, "humMin", 58), jsonDouble(body, "humMax", 72),
                jsonDouble(body, "co2Min", 450), jsonDouble(body, "co2Max", 1000),
                jsonDouble(body, "o2Min", 19), jsonDouble(body, "o2Max", 22),
                jsonDouble(body, "phMin", 6.3), jsonDouble(body, "phMax", 7.1),
                jsonDouble(body, "lightMin", 2000), jsonDouble(body, "lightMax", 6000)
        };
        try (Connection connection = Database.open()) {
            upsertThresholdRule(connection, id, "air_temperature", "LT", values[0], "空气温度下限");
            upsertThresholdRule(connection, id, "air_temperature", "GT", values[1], "空气温度上限");
            upsertThresholdRule(connection, id, "air_humidity", "LT", values[2], "空气湿度下限");
            upsertThresholdRule(connection, id, "air_humidity", "GT", values[3], "空气湿度上限");
            upsertThresholdRule(connection, id, "soil_temperature", "LT", values[4], "土壤温度下限");
            upsertThresholdRule(connection, id, "soil_temperature", "GT", values[5], "土壤温度上限");
            upsertThresholdRule(connection, id, "soil_humidity", "LT", values[6], "土壤湿度下限");
            upsertThresholdRule(connection, id, "soil_humidity", "GT", values[7], "土壤湿度上限");
            upsertThresholdRule(connection, id, "co2_ppm", "LT", values[8], "二氧化碳下限");
            upsertThresholdRule(connection, id, "co2_ppm", "GT", values[9], "二氧化碳上限");
            upsertThresholdRule(connection, id, "o2", "LT", values[10], "氧气下限");
            upsertThresholdRule(connection, id, "o2", "GT", values[11], "氧气上限");
            upsertThresholdRule(connection, id, "ph_value", "LT", values[12], "pH下限");
            upsertThresholdRule(connection, id, "ph_value", "GT", values[13], "pH上限");
            upsertThresholdRule(connection, id, "light_lux", "LT", values[14], "光照下限");
            upsertThresholdRule(connection, id, "light_lux", "GT", values[15], "光照上限");
            return "{\"success\":true,\"threshold\":" + thresholdJson(values) + "}";
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String submitFeedback(String userId, String content, String contact) {
        if (content == null || content.trim().isEmpty()) {
            return "{\"success\":false,\"message\":\"content is empty\"}";
        }
        String query = "insert into feedback(user_id,category,content,contact,status,created_at,deleted,updated_at) "
                + "values (?,?,?,?,?,current_timestamp,false,current_timestamp)";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            Long uid = farmerId(userId);
            if (uid == null) {
                statement.setNull(1, Types.BIGINT);
            } else {
                statement.setLong(1, uid);
            }
            statement.setString(2, "APP");
            statement.setString(3, content.trim());
            statement.setString(4, contact == null ? "" : contact);
            statement.setString(5, "OPEN");
            statement.executeUpdate();
            return "{\"success\":true}";
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String createGreenhouse(String userId, String name, String location, String area) {
        if (name == null || name.trim().isEmpty()) {
            return "{\"success\":false,\"message\":\"name is empty\"}";
        }
        Long uid = farmerId(userId);
        String query = "insert into greenhouse(owner_user_id,name,location,status,area,crop_stage,created_at,updated_at,deleted) "
                + "values (?,?,?,?,?,?,current_timestamp,current_timestamp,false)";
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            if (uid == null) {
                statement.setNull(1, Types.BIGINT);
            } else {
                statement.setLong(1, uid);
            }
            statement.setString(2, name.trim());
            statement.setString(3, location == null ? "" : location.trim());
            statement.setString(4, "ONLINE");
            statement.setDouble(5, doubleValue(area, 0));
            statement.setString(6, "出菇期");
            statement.executeUpdate();
            return listGreenhouses(uid == null ? "" : uid.toString());
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    public String deleteGreenhouse(String userId, String greenhouseId) {
        long id = longValue(greenhouseId, -1);
        if (id <= 0) {
            return "{\"success\":false,\"message\":\"invalid greenhouse id\"}";
        }
        Long uid = farmerId(userId);
        String query = "update greenhouse set deleted=true,updated_at=current_timestamp "
                + "where id=? and (deleted is null or deleted=false)";
        if (uid != null) {
            query += " and (owner_user_id=? or exists (select 1 from farmer_greenhouse_binding b "
                    + "where b.greenhouse_id=greenhouse.id and b.farmer_user_id=? "
                    + "and (b.deleted is null or b.deleted=false)))";
        }
        try (Connection connection = Database.open();
             PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, id);
            if (uid != null) {
                statement.setLong(2, uid);
                statement.setLong(3, uid);
            }
            int updated = statement.executeUpdate();
            return "{\"success\":" + (updated > 0) + "}";
        } catch (SQLException ex) {
            return "{\"success\":false,\"message\":\"" + Json.escape(ex.getMessage()) + "\"}";
        }
    }

    private String greenhousesJson(ResultSet rs) throws SQLException {
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
                + "\"distance\":" + number(rs, "distance", -1) + ","
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

    private String thresholdJson(double[] values) {
        return "{"
                + "\"tempMin\":" + values[0] + ","
                + "\"tempMax\":" + values[1] + ","
                + "\"airHumMin\":" + values[2] + ","
                + "\"airHumMax\":" + values[3] + ","
                + "\"soilTempMin\":" + values[4] + ","
                + "\"soilTempMax\":" + values[5] + ","
                + "\"humMin\":" + values[6] + ","
                + "\"humMax\":" + values[7] + ","
                + "\"co2Min\":" + values[8] + ","
                + "\"co2Max\":" + values[9] + ","
                + "\"o2Min\":" + values[10] + ","
                + "\"o2Max\":" + values[11] + ","
                + "\"phMin\":" + values[12] + ","
                + "\"phMax\":" + values[13] + ","
                + "\"lightMin\":" + values[14] + ","
                + "\"lightMax\":" + values[15]
                + "}";
    }

    private void applyThreshold(double[] values, String metric, String operator, double value) {
        boolean min = "LT".equalsIgnoreCase(operator) || "<".equals(operator);
        boolean max = "GT".equalsIgnoreCase(operator) || ">".equals(operator);
        if ("air_temperature".equals(metric) || "temperature".equals(metric)) {
            if (min) values[0] = value;
            if (max) values[1] = value;
        } else if ("air_humidity".equals(metric) || "humidity".equals(metric)) {
            if (min) values[2] = value;
            if (max) values[3] = value;
        } else if ("soil_temperature".equals(metric)) {
            if (min) values[4] = value;
            if (max) values[5] = value;
        } else if ("soil_humidity".equals(metric) || "soil_moisture".equals(metric)) {
            if (min) values[6] = value;
            if (max) values[7] = value;
        } else if ("co2_ppm".equals(metric) || "co2".equals(metric)) {
            if (min) values[8] = value;
            if (max) values[9] = value;
        } else if ("o2".equals(metric)) {
            if (min) values[10] = value;
            if (max) values[11] = value;
        } else if ("ph_value".equals(metric) || "ph".equals(metric)) {
            if (min) values[12] = value;
            if (max) values[13] = value;
        } else if ("light_lux".equals(metric) || "light".equals(metric)) {
            if (min) values[14] = value;
            if (max) values[15] = value;
        }
    }

    private double[] defaultThresholdValues() {
        return new double[]{16, 24, 70, 92, 16, 24, 58, 72, 450, 1000, 19, 22, 6.3, 7.1, 2000, 6000};
    }

    private double jsonDouble(String body, String key, double fallback) {
        return doubleValue(Json.extractValue(body, key, Double.toString(fallback)), fallback);
    }

    private boolean ensureGreenhouseRuntimeData(long greenhouseId, int hours) {
        try (Connection connection = Database.open()) {
            ensureTelemetryRows(connection, greenhouseId, hours);
            ensureDeviceRows(connection, greenhouseId);
            ensureThresholdRules(connection, greenhouseId);
            normalizeGreenhouseName(connection, greenhouseId);
            return true;
        } catch (SQLException ex) {
            return false;
        }
    }

    private void ensureTelemetryRows(Connection connection, long greenhouseId, int hours) throws SQLException {
        int count = Math.max(24, Math.min(hours, 336));
        long existing = countForGreenhouse(connection, "telemetry_snapshot", greenhouseId);
        if (existing >= count) {
            return;
        }
        int missing = (int) (count - existing);
        LocalDateTime baseTime = earliestTelemetryTime(connection, greenhouseId);
        String query = "insert into telemetry_snapshot(greenhouse_id,temperature,humidity,air_temperature,air_humidity,"
                + "soil_temperature,soil_humidity,ph_value,light_lux,co2_ppm,soil_moisture,collected_at) "
                + "values (?,?,?,?,?,?,?,?,?,?,?,?)";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            for (int i = missing; i >= 1; i--) {
                double sequence = existing + (missing - i) + 1;
                double wave = Math.sin(sequence / 5.0);
                double dayWave = Math.sin(sequence / 24.0);
                double airTemp = round1(18.8 + wave * 1.6 + (greenhouseId % 3) * 0.4);
                double airHum = round1(84.0 + dayWave * 5.0 - (greenhouseId % 2) * 1.5);
                double soilTemp = round1(17.6 + wave * 1.1);
                double soilHum = round1(63.5 + dayWave * 4.0);
                double ph = round2(6.65 + Math.sin(sequence / 9.0) * 0.12);
                int light = Math.max(1800, (int) Math.round(4100 + Math.sin(sequence / 4.0) * 900));
                int co2 = Math.max(520, (int) Math.round(760 + Math.cos(sequence / 6.0) * 120));
                Timestamp time = Timestamp.valueOf(baseTime.minusHours(i));
                statement.setLong(1, greenhouseId);
                statement.setDouble(2, airTemp);
                statement.setDouble(3, airHum);
                statement.setDouble(4, airTemp);
                statement.setDouble(5, airHum);
                statement.setDouble(6, soilTemp);
                statement.setDouble(7, soilHum);
                statement.setDouble(8, ph);
                statement.setInt(9, light);
                statement.setInt(10, co2);
                statement.setDouble(11, soilHum);
                statement.setTimestamp(12, time);
                statement.addBatch();
            }
            statement.executeBatch();
        }
    }

    private void ensureDeviceRows(Connection connection, long greenhouseId) throws SQLException {
        String query = "insert into greenhouse_device(greenhouse_id,name,category,status,location,auto_mode,health_score,deleted,created_at,updated_at) "
                + "values (?,?,?,?,?,false,?,?,current_timestamp,current_timestamp)";
        if (!deviceTypeExists(connection, greenhouseId, "fan")) {
            insertDevice(connection, query, greenhouseId, "循环风机", "FAN", "RUNNING", "棚内北侧", 92);
        }
        if (!deviceTypeExists(connection, greenhouseId, "light")) {
            insertDevice(connection, query, greenhouseId, "补光灯", "LIGHT", "STOPPED", "棚顶", 88);
        }
        if (!deviceTypeExists(connection, greenhouseId, "water")) {
            insertDevice(connection, query, greenhouseId, "灌溉水泵", "PUMP", "RUNNING", "水肥区", 90);
        }
    }

    private LocalDateTime earliestTelemetryTime(Connection connection, long greenhouseId) throws SQLException {
        String query = "select min(collected_at) from telemetry_snapshot where greenhouse_id=?";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, greenhouseId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    Timestamp time = rs.getTimestamp(1);
                    if (time != null) {
                        return time.toLocalDateTime();
                    }
                }
            }
        }
        return LocalDateTime.now().plusHours(1);
    }

    private boolean deviceTypeExists(Connection connection, long greenhouseId, String expectedType) throws SQLException {
        String query = "select name,category from greenhouse_device where greenhouse_id=? and (deleted is null or deleted=false)";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, greenhouseId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    if (expectedType.equals(deviceType(string(rs, "category", ""), string(rs, "name", "")))) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private void insertDevice(Connection connection, String query, long greenhouseId, String name, String category,
                              String status, String location, int health) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, greenhouseId);
            statement.setString(2, name);
            statement.setString(3, category);
            statement.setString(4, status);
            statement.setString(5, location);
            statement.setInt(6, health);
            statement.setBoolean(7, false);
            statement.executeUpdate();
        }
    }

    private void ensureThresholdRules(long greenhouseId) {
        try (Connection connection = Database.open()) {
            ensureThresholdRules(connection, greenhouseId);
        } catch (SQLException ignored) {
        }
    }

    private void ensureThresholdRules(Connection connection, long greenhouseId) throws SQLException {
        if (thresholdRuleCount(connection, greenhouseId) > 0) {
            return;
        }
        double[] values = defaultThresholdValues();
        upsertThresholdRule(connection, greenhouseId, "air_temperature", "LT", values[0], "空气温度下限");
        upsertThresholdRule(connection, greenhouseId, "air_temperature", "GT", values[1], "空气温度上限");
        upsertThresholdRule(connection, greenhouseId, "air_humidity", "LT", values[2], "空气湿度下限");
        upsertThresholdRule(connection, greenhouseId, "air_humidity", "GT", values[3], "空气湿度上限");
        upsertThresholdRule(connection, greenhouseId, "soil_temperature", "LT", values[4], "土壤温度下限");
        upsertThresholdRule(connection, greenhouseId, "soil_temperature", "GT", values[5], "土壤温度上限");
        upsertThresholdRule(connection, greenhouseId, "soil_humidity", "LT", values[6], "土壤湿度下限");
        upsertThresholdRule(connection, greenhouseId, "soil_humidity", "GT", values[7], "土壤湿度上限");
        upsertThresholdRule(connection, greenhouseId, "co2_ppm", "LT", values[8], "二氧化碳下限");
        upsertThresholdRule(connection, greenhouseId, "co2_ppm", "GT", values[9], "二氧化碳上限");
        upsertThresholdRule(connection, greenhouseId, "o2", "LT", values[10], "氧气下限");
        upsertThresholdRule(connection, greenhouseId, "o2", "GT", values[11], "氧气上限");
        upsertThresholdRule(connection, greenhouseId, "ph_value", "LT", values[12], "pH下限");
        upsertThresholdRule(connection, greenhouseId, "ph_value", "GT", values[13], "pH上限");
        upsertThresholdRule(connection, greenhouseId, "light_lux", "LT", values[14], "光照下限");
        upsertThresholdRule(connection, greenhouseId, "light_lux", "GT", values[15], "光照上限");
    }

    private void upsertThresholdRule(Connection connection, long greenhouseId, String metric, String operator,
                                     double value, String name) throws SQLException {
        String select = "select id from alert_rule where greenhouse_id=? and metric_key=? and operator=? "
                + "and (deleted is null or deleted=false) limit 1";
        try (PreparedStatement statement = connection.prepareStatement(select)) {
            statement.setLong(1, greenhouseId);
            statement.setString(2, metric);
            statement.setString(3, operator);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    try (PreparedStatement update = connection.prepareStatement(
                            "update alert_rule set threshold_value=?,enabled=true,updated_at=current_timestamp where id=?")) {
                        update.setDouble(1, value);
                        update.setLong(2, rs.getLong("id"));
                        update.executeUpdate();
                        return;
                    }
                }
            }
        }
        String code = "APP_" + greenhouseId + "_" + metric + "_" + operator;
        String insert = "insert into alert_rule(rule_code,rule_name,greenhouse_id,metric_key,operator,threshold_value,"
                + "duration_minutes,level,enabled,description,deleted,created_at,updated_at) "
                + "values (?,?,?,?,?,?,5,'WARNING',true,?,false,current_timestamp,current_timestamp)";
        try (PreparedStatement statement = connection.prepareStatement(insert)) {
            statement.setString(1, code);
            statement.setString(2, name);
            statement.setLong(3, greenhouseId);
            statement.setString(4, metric);
            statement.setString(5, operator);
            statement.setDouble(6, value);
            statement.setString(7, "App阈值设置");
            statement.executeUpdate();
        }
    }

    private long thresholdRuleCount(Connection connection, long greenhouseId) throws SQLException {
        String query = "select count(*) from alert_rule where greenhouse_id=? and (deleted is null or deleted=false)";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, greenhouseId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getLong(1) : 0L;
            }
        }
    }

    private long countForGreenhouse(Connection connection, String table, long greenhouseId) throws SQLException {
        String query = "select count(*) from " + table + " where greenhouse_id=? and (deleted is null or deleted=false)";
        if ("telemetry_snapshot".equals(table)) {
            query = "select count(*) from telemetry_snapshot where greenhouse_id=?";
        }
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setLong(1, greenhouseId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getLong(1) : 0L;
            }
        }
    }

    private void normalizeGreenhouseName(Connection connection, long greenhouseId) throws SQLException {
        if (greenhouseId != 8L) {
            return;
        }
        try (PreparedStatement statement = connection.prepareStatement(
                "update greenhouse set name='A04 羊肚菌示范大棚',location='温室二区 / 南侧',crop_stage='出菇期',updated_at=current_timestamp "
                        + "where id=8 and name like 'Codex%'")) {
            statement.executeUpdate();
        }
    }

    private double round1(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
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

    private Long farmerId(String value) {
        long parsed = longValue(value, -1);
        if (parsed > 0) {
            return parsed;
        }
        String query = "select id from app_user where username='farmer001' "
                + "and upper(role_code)='FARMER' and enabled=true and (deleted is null or deleted=false) limit 1";
        try (Connection connection = Database.open();
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(query)) {
            return rs.next() ? rs.getLong("id") : null;
        } catch (SQLException ex) {
            return null;
        }
    }

    private String sql(String value) {
        return value == null ? "" : value.replace("'", "''");
    }

    private long longValue(String value, long fallback) {
        try {
            return Long.parseLong(value == null ? "" : value.trim());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private double doubleValue(String value, double fallback) {
        try {
            return Double.parseDouble(value == null ? "" : value.trim());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private String deviceType(String category, String name) {
        String text = (category + " " + name).toLowerCase();
        if (text.contains("fan") || text.contains("风") || text.contains("通风")) {
            return "fan";
        }
        if (text.contains("light") || text.contains("灯") || text.contains("光")) {
            return "light";
        }
        if (text.contains("board") || text.contains("挡") || text.contains("遮")) {
            return "board";
        }
        if (text.contains("药")) {
            return "medicine";
        }
        if (text.contains("pump") || text.contains("泵") || text.contains("灌溉") || text.contains("加湿")) {
            return "water";
        }
        return "sensor";
    }

    private String baseDeviceId(String type, String dbId) {
        if ("light".equals(type)) {
            return "light_1";
        }
        if ("board".equals(type)) {
            return "board_1";
        }
        if ("fan".equals(type)) {
            return "fan_1";
        }
        if ("water".equals(type)) {
            return "water_pump_1";
        }
        if ("medicine".equals(type)) {
            return "medicine_pump_1";
        }
        return "sensor_" + dbId;
    }

    private boolean isDeviceEnabled(String status) {
        String upper = status == null ? "" : status.toUpperCase();
        return upper.contains("RUNNING") || upper.contains("ONLINE") || upper.equals("ON");
    }

    private String statusLabel(String status) {
        String upper = status == null ? "" : status.toUpperCase();
        return upper.contains("RESOLVED") || upper.contains("CLOSED") || upper.contains("已") ? "已处理" : "未处理";
    }

    private String levelLabel(String level) {
        String upper = level == null ? "" : level.toUpperCase();
        if (upper.contains("CRITICAL")) {
            return "高";
        }
        if (upper.contains("INFO")) {
            return "低";
        }
        return "中";
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
