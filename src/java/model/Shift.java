package model;

public class Shift {
    private String id;
    private int staffId;
    private String staffName;
    private String shiftDate;
    private String shiftName;
    private String hours;
    private String status;
    private String notes;

    public Shift() {}

    public Shift(String id, int staffId, String staffName, String shiftDate, String shiftName, String hours, String status, String notes) {
        this.id = id;
        this.staffId = staffId;
        this.staffName = staffName;
        this.shiftDate = shiftDate;
        this.shiftName = shiftName;
        this.hours = hours;
        this.status = status;
        this.notes = notes;
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
}
