package dao;

import context.DBContext;
import model.Table;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class TableDAO {
    private List<Table> fallbackTables = new ArrayList<>();

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
            System.err.println("Database fetch failed in TableDAO.getById(), searching cached fallback context...");
        }
        
        return getFallbackTables().stream()
                .filter(table -> table.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    public void update(Table table) {
        String sql = "UPDATE dbo.Tables SET name = ?, zone = ?, status = ?, capacity = ?, activeOrderId = ? WHERE id = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            
            st.setString(1, table.getName());
            st.setString(2, table.getZone());
            st.setString(3, table.getStatus());
            st.setInt(4, table.getCapacity());
            st.setString(5, table.getActiveOrderId());
            st.setString(6, table.getId());
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
        } else {
            fallbackTables.add(table);
        }
    }

    private List<Table> getFallbackTables() {
        return fallbackTables;
    }
}
