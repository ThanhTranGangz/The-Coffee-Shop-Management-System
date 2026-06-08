package model;

public class Staff {

    private int staffID;
    private String username;
    private String fullName;
    private int roleID;
    private String roleName;
    private boolean active;

    public Staff() {
    }

    public Staff(int staffID, String username, String fullName, int roleID, String roleName, boolean active) {
        this.staffID = staffID;
        this.username = username;
        this.fullName = fullName;
        this.roleID = roleID;
        this.roleName = roleName;
        this.active = active;
    }

    public int getStaffID() {
        return staffID;
    }

    public void setStaffID(int staffID) {
        this.staffID = staffID;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public int getRoleID() {
        return roleID;
    }

    public void setRoleID(int roleID) {
        this.roleID = roleID;
    }

    public String getRoleName() {
        return roleName;
    }

    public void setRoleName(String roleName) {
        this.roleName = roleName;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}