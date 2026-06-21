package dao;

import context.DBContext;
import model.Table;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class TableDAO {
    private List<Table> fallbackTables = new ArrayList<>();

    public List<Table> getAll() {
        ensureTableCodeColumn();
        List<Table> tables = new ArrayList<>();
        String sql = "SELECT id, name, zone, status, capacity, activeOrderId, tableCode FROM dbo.Tables";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            
            while (rs.next()) {
                String id = rs.getString("id");
                String name = rs.getString("name");
                String zone = rs.getString("zone");
                String status = rs.getString("status");
                int capacity = rs.getInt("capacity");
                String activeOrderId = rs.getString("activeOrderId");
                String tableCode = normalizeTableCode(id, rs.getString("tableCode"));
                
                tables.add(new Table(id, name, zone, status, capacity, activeOrderId, tableCode));
            }
            // Sync fallback to the database contents
            fallbackTables = new ArrayList<>(tables);
        } catch (Exception e) {
            System.err.println("Database fetch failed in TableDAO.getAll(), falling back to synced list: " + e.getMessage());
            return getFallbackTables();
        }
        
        if (tables.isEmpty()) {
            return getFallbackTables();
        }
        return tables;
    }

    public Table getById(String id) {
        ensureTableCodeColumn();
        String sql = "SELECT id, name, zone, status, capacity, activeOrderId, tableCode FROM dbo.Tables WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, id);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    String name = rs.getString("name");
                    String zone = rs.getString("zone");
                    String status = rs.getString("status");
                    int capacity = rs.getInt("capacity");
                    String activeOrderId = rs.getString("activeOrderId");
                    String tableCode = normalizeTableCode(id, rs.getString("tableCode"));
                    
                    return new Table(id, name, zone, status, capacity, activeOrderId, tableCode);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in TableDAO.getById(), searching cached fallback context...");
        }
        
        return getFallbackTables().stream()
                .filter(table -> table.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    public Table getByCode(String tableCode) {
        if (tableCode == null || tableCode.trim().isEmpty()) {
            return null;
        }
        String normalized = tableCode.trim().toUpperCase();
        ensureTableCodeColumn();
        String sql = "SELECT id, name, zone, status, capacity, activeOrderId, tableCode FROM dbo.Tables WHERE UPPER(tableCode) = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, normalized);
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    String id = rs.getString("id");
                    return new Table(
                        id,
                        rs.getString("name"),
                        rs.getString("zone"),
                        rs.getString("status"),
                        rs.getInt("capacity"),
                        rs.getString("activeOrderId"),
                        normalizeTableCode(id, rs.getString("tableCode"))
                    );
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in TableDAO.getByCode(), searching cached fallback context...");
        }

        return getFallbackTables().stream()
                .filter(table -> normalized.equalsIgnoreCase(table.getTableCode()))
                .findFirst()
                .orElse(null);
    }

    public void update(Table table) {
        ensureTableCodeColumn();
        table.setTableCode(normalizeTableCode(table.getId(), table.getTableCode()));
        String sql = "UPDATE dbo.Tables SET name = ?, zone = ?, status = ?, capacity = ?, activeOrderId = ?, tableCode = ? WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, table.getName());
            st.setString(2, table.getZone());
            st.setString(3, table.getStatus());
            st.setInt(4, table.getCapacity());
            st.setString(5, table.getActiveOrderId());
            st.setString(6, table.getTableCode());
            st.setString(7, table.getId());
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database update failed in TableDAO.update(), applying memory update to cached list: " + e.getMessage());
        }
        
        // Ensure memory fallback stays updated in real-time
        Table existing = getFallbackTables().stream()
                .filter(t -> t.getId().equals(table.getId()))
                .findFirst()
                .orElse(null);
        if (existing != null) {
            existing.setName(table.getName());
            existing.setZone(table.getZone());
            existing.setStatus(table.getStatus());
            existing.setCapacity(table.getCapacity());
            existing.setActiveOrderId(table.getActiveOrderId());
            existing.setTableCode(table.getTableCode());
        } else {
            fallbackTables.add(table);
        }
    }

    public void create(Table table) {
        ensureTableCodeColumn();
        table.setTableCode(normalizeTableCode(table.getId(), table.getTableCode()));
        String sql = "INSERT INTO dbo.Tables (id, name, zone, status, capacity, activeOrderId, tableCode) VALUES (?, ?, ?, ?, ?, ?, ?)";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, table.getId());
            st.setString(2, table.getName());
            st.setString(3, table.getZone());
            st.setString(4, table.getStatus());
            st.setInt(5, table.getCapacity());
            st.setString(6, table.getActiveOrderId());
            st.setString(7, table.getTableCode());
            st.executeUpdate();
        } catch (Exception e) {
            System.err.println("Database create failed in TableDAO.create(), adding to cached list: " + e.getMessage());
        }

        boolean exists = getFallbackTables().stream().anyMatch(t -> t.getId().equals(table.getId()));
        if (!exists) {
            fallbackTables.add(table);
        }
    }

    private List<Table> getFallbackTables() {
        return fallbackTables;
    }

    private void ensureTableCodeColumn() {
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             Statement st = con.createStatement()) {
            st.execute("IF COL_LENGTH('dbo.Tables', 'tableCode') IS NULL ALTER TABLE dbo.Tables ADD tableCode VARCHAR(50) NULL");
            st.execute("UPDATE dbo.Tables SET tableCode = CONCAT('TBL-', UPPER(id), '-', RIGHT('0000' + CONVERT(VARCHAR(32), ABS(CHECKSUM(NEWID()))), 4)) WHERE tableCode IS NULL OR tableCode = ''");
        } catch (Exception e) {
            System.err.println("TableDAO.ensureTableCodeColumn skipped: " + e.getMessage());
        }
    }

    private String normalizeTableCode(String id, String code) {
        if (code != null && !code.trim().isEmpty()) {
            return code.trim().toUpperCase();
        }
        String safeId = id == null ? "TABLE" : id.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
        return "TBL-" + safeId;
    }
}
