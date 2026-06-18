package model;

public class Staff {
    private int id;
    private String name;
    private String role;
    private String pin;
    private String shift;
    private boolean active;
    private String username;
    private String password;
    private String status; // "Active", "Temp_Inactive", "Perm_Inactive", "Off_Duty"
    private boolean overtime; // true if allowed to work overtime outside their shift hours

    public Staff() {
        this.status = "Active";
        this.overtime = false;
    }

    public Staff(int id, String name, String role, String pin, String shift, boolean active, String username, String password) {
        this.id = id;
        this.name = name;
        this.role = role;
        this.pin = pin;
        this.shift = shift;
        this.active = active;
        this.username = username;
        this.password = password;
        this.status = "Active";
        this.overtime = false;
    }

    public Staff(int id, String name, String role, String pin, String shift, boolean active, String username, String password, String status, boolean overtime) {
        this.id = id;
        this.name = name;
        this.role = role;
        this.pin = pin;
        this.shift = shift;
        this.active = active;
        this.username = username;
        this.password = password;
        this.status = status;
        this.overtime = overtime;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getPin() { return pin; }
    public void setPin(String pin) { this.pin = pin; }

    public String getShift() { return shift; }
    public void setShift(String shift) { this.shift = shift; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isOvertime() { return overtime; }
    public void setOvertime(boolean overtime) { this.overtime = overtime; }
}
