package model;

/**
 * Represents a table in the coffee shop, including its location, capacity, and current status.
 */
public class Table {
    private String id;
    private String name;
    private String zone;
    private String status; // empty, serving, ready_to_serve
    private int capacity;
    private String activeOrderId;
    private String tableCode;

    /**
     * Default constructor.
     */
    public Table() {}

    /**
     * Constructs a Table without a specific table code.
     * 
     * @param id the table ID
     * @param name the table name
     * @param zone the zone or area of the table
     * @param status the current status (e.g., empty, serving)
     * @param capacity the seating capacity
     * @param activeOrderId the ID of the active order, if any
     */
    public Table(String id, String name, String zone, String status, int capacity, String activeOrderId) {
        this(id, name, zone, status, capacity, activeOrderId, null);
    }

    /**
     * Constructs a Table with all details including a table code.
     * 
     * @param id the table ID
     * @param name the table name
     * @param zone the zone or area of the table
     * @param status the current status
     * @param capacity the seating capacity
     * @param activeOrderId the ID of the active order
     * @param tableCode a unique code for the table
     */
    public Table(String id, String name, String zone, String status, int capacity, String activeOrderId, String tableCode) {
        this.id = id;
        this.name = name;
        this.zone = zone;
        this.status = status;
        this.capacity = capacity;
        this.activeOrderId = activeOrderId;
        this.tableCode = tableCode;
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

    public String getTableCode() { return tableCode; }
    public void setTableCode(String tableCode) { this.tableCode = tableCode; }
}
