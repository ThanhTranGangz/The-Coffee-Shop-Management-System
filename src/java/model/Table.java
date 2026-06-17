package model;

public class Table {
    private String id;
    private String name;
    private String zone;
    private String status; // empty, serving, ready_to_serve
    private int capacity;
    private String activeOrderId;

    public Table() {}

    public Table(String id, String name, String zone, String status, int capacity, String activeOrderId) {
        this.id = id;
        this.name = name;
        this.zone = zone;
        this.status = status;
        this.capacity = capacity;
        this.activeOrderId = activeOrderId;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getZone() { return zone; }
    public void setZone(String zone) { this.zone = zone; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getCapacity() { return capacity; }
    public void setCapacity(int capacity) { this.capacity = capacity; }

    public String getActiveOrderId() { return activeOrderId; }
    public void setActiveOrderId(String activeOrderId) { this.activeOrderId = activeOrderId; }
}
