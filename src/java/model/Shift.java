package model;

/**
 * Represents a working shift for a staff member.
 */
public class Shift {
    private String id;
    private int staffId;
    private String staffName;
    private String shiftDate;
    private String shiftName;
    private String hours;
    private String status;
    private String notes;
    private String assignedRole;

    /**
     * Default constructor.
     */
    public Shift() {}

    /**
     * Constructs a Shift without assignedRole (backward compatibility).
     */
    public Shift(String id, int staffId, String staffName, String shiftDate, String shiftName, String hours, String status, String notes) {
        this.id = id;
        this.staffId = staffId;
        this.staffName = staffName;
        this.shiftDate = shiftDate;
        this.shiftName = shiftName;
        this.hours = hours;
        this.status = status;
        this.notes = notes;
        this.assignedRole = null;
    }

    /**
     * Constructs a Shift with full details.
     * 
     * @param id the shift ID
     * @param staffId the staff member's ID
     * @param staffName the staff member's name
     * @param shiftDate the date of the shift
     * @param shiftName the name or type of shift
     * @param hours the hours worked
     * @param status the status of the shift
     * @param notes any remarks
     * @param assignedRole the role assigned for this shift
     */
    public Shift(String id, int staffId, String staffName, String shiftDate, String shiftName, String hours, String status, String notes, String assignedRole) {
        this.id = id;
        this.staffId = staffId;
        this.staffName = staffName;
        this.shiftDate = shiftDate;
        this.shiftName = shiftName;
        this.hours = hours;
        this.status = status;
        this.notes = notes;
        this.assignedRole = assignedRole;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public int getStaffId() { return staffId; }
    public void setStaffId(int staffId) { this.staffId = staffId; }

    public String getStaffName() { return staffName; }
    public void setStaffName(String staffName) { this.staffName = staffName; }

    public String getShiftDate() { return shiftDate; }
    public void setShiftDate(String shiftDate) { this.shiftDate = shiftDate; }

    public String getShiftName() { return shiftName; }
    public void setShiftName(String shiftName) { this.shiftName = shiftName; }

    public String getHours() { return hours; }
    public void setHours(String hours) { this.hours = hours; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getAssignedRole() { return assignedRole; }
    public void setAssignedRole(String assignedRole) { this.assignedRole = assignedRole; }
}
