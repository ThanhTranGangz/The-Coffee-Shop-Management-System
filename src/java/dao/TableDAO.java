package dao;

import context.DBContext;
import model.Table;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class TableDAO {
    private List<Table> fallbackTables;

    public List<Table> getAll() {
        List<Table> tables = new ArrayList<>();
        String sql = "SELECT id, name, zone, status, capacity, activeOrderId FROM dbo.Tables";
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
                
                tables.add(new Table(id, name, zone, status, capacity, activeOrderId));
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in TableDAO.getAll(), falling back to mocked list: " + e.getMessage());
            return getFallbackTables();
        }
        
        if (tables.isEmpty()) {
            return getFallbackTables();
        }
        return tables;
    }

    public Table getById(String id) {
        String sql = "SELECT id, name, zone, status, capacity, activeOrderId FROM dbo.Tables WHERE id = ?";
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
                    
                    return new Table(id, name, zone, status, capacity, activeOrderId);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in TableDAO.getById(), searching fallback context...");
        }
        
        return getFallbackTables().stream()
                .filter(table -> table.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    public void update(Table table) {
        String sql = "UPDATE dbo.Tables SET name = ?, zone = ?, status = ?, capacity = ?, activeOrderId = ? WHERE id = ?";
        DBContext db = new DBContext();
        boolean dbSuccess = false;
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, table.getName());
            st.setString(2, table.getZone());
            st.setString(3, table.getStatus());
            st.setInt(4, table.getCapacity());
            st.setString(5, table.getActiveOrderId());
            st.setString(6, table.getId());
            
            int affected = st.executeUpdate();
            if (affected > 0) {
                dbSuccess = true;
            }
        } catch (Exception e) {
            System.err.println("Database update failed in TableDAO.update(), applying memory update to fallback lists: " + e.getMessage());
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
        }
    }

    private List<Table> getFallbackTables() {
        if (fallbackTables == null) {
            fallbackTables = new ArrayList<>();
            // Ground Floor
            fallbackTables.add(new Table("t1", "Table 1", "Ground Floor", "empty", 2, null));
            fallbackTables.add(new Table("t2", "Table 2", "Ground Floor", "empty", 2, null));
            fallbackTables.add(new Table("t3", "Table 3", "Ground Floor", "empty", 4, null));
            fallbackTables.add(new Table("t4", "Table 4", "Ground Floor", "empty", 6, null));

            // Terrace
            fallbackTables.add(new Table("t5", "Terrace A", "Terrace", "empty", 2, null));
            fallbackTables.add(new Table("t6", "Terrace B", "Terrace", "empty", 2, null));
            fallbackTables.add(new Table("t7", "Terrace C", "Terrace", "empty", 4, null));
            fallbackTables.add(new Table("t8", "Terrace Custom", "Terrace", "empty", 4, null));

            // Upper Floor
            fallbackTables.add(new Table("t9", "Upper Room 1", "Upper Floor", "empty", 4, null));
            fallbackTables.add(new Table("t10", "Upper Room 2", "Upper Floor", "empty", 4, null));
            fallbackTables.add(new Table("t11", "Upper Balcony", "Upper Floor", "empty", 2, null));
            fallbackTables.add(new Table("t12", "Upper Lounge", "Upper Floor", "empty", 8, null));
        }
        return fallbackTables;
    }
}

