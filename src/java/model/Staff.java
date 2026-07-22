package model;

/**
 * Represents a staff member in the coffee shop system, detailing their roles and shifts.
 */
public class Staff {
    private int id;
    private String name;
    private boolean active;
    private String status; // "Active", "Temp_Inactive", "Perm_Inactive", "Off_Duty"


    /**
     * Default constructor. Initializes status as Active and overtime as false.
     */
    public Staff() {
        this.status = "Active";
    }

    

    /**
     * Constructs a Staff member with all details, including status and overtime.
     * 
     * @param id the staff ID
     * @param name the staff name
     * @param role the staff role
     * @param pin the login pin
     * @param shift the assigned shift
     * @param active whether the staff is active
     * @param status the staff status
     * @param overtime whether overtime is allowed
     */
    public Staff(int id, String name, boolean active, String status) {
        this.id = id;
        this.name = name;
        this.active = active;
        this.status = status;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }



    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

}
