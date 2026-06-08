package model;

public class Staff {
    private int staffId;
    private String username;
    private String password;
    private String pinCode;
    private String fullName;
    private int roleId;
    private boolean isActive;

    public Staff() {
    }

    public Staff(int staffId, String username, String password, String pinCode, String fullName, int roleId, boolean isActive) {
        this.staffId = staffId;
        this.username = username;
        this.password = password;
        this.pinCode = pinCode;
        this.fullName = fullName;
        this.roleId = roleId;
        this.isActive = isActive;
    }

    public int getStaffId() {
        return staffId;
    }

    public void setStaffId(int staffId) {
        this.staffId = staffId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getPinCode() {
        return pinCode;
    }

    public void setPinCode(String pinCode) {
        this.pinCode = pinCode;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public int getRoleId() {
        return roleId;
    }

    public void setRoleId(int roleId) {
        this.roleId = roleId;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    @Override
    public String toString() {
        return "Staff{" +
                "staffId=" + staffId +
                ", username='" + username + '\'' +
                ", fullName='" + fullName + '\'' +
                ", roleId=" + roleId +
                ", isActive=" + isActive +
                '}';
    }
}
