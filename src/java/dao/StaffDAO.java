package dal;

import model.Staff;
import util.PasswordUtil;
import model.Role;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class StaffDAO extends DBContext {

    public Staff loginByUsernamePassword(String username, String password) {
        String sql = "SELECT s.StaffID, s.Username, s.FullName, s.RoleID, r.RoleName, s.IsActive "
                + "FROM Staff s "
                + "JOIN Role r ON s.RoleID = r.RoleID "
                + "WHERE s.Username = ? AND s.Password = ? AND s.IsActive = 1";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setString(1, username);
            ps.setString(2, PasswordUtil.sha256(password));

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return mapStaff(rs);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    public Staff loginByPIN(String username, String pin, String deviceName) {
        String sql = "SELECT s.StaffID, s.Username, s.FullName, s.RoleID, r.RoleName, s.IsActive, "
                + "s.PIN_Code, s.LockedUntil "
                + "FROM Staff s "
                + "JOIN Role r ON s.RoleID = r.RoleID "
                + "WHERE s.Username = ? AND s.IsActive = 1";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, username);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                int staffID = rs.getInt("StaffID");
                String storedPIN = rs.getString("PIN_Code");
                String inputPIN = PasswordUtil.sha256(pin);

                if (rs.getTimestamp("LockedUntil") != null
                        && rs.getTimestamp("LockedUntil").getTime() > System.currentTimeMillis()) {
                    return null;
                }

                if (storedPIN.equals(inputPIN)) {
                    resetFailedPIN(staffID);
                    createSession(staffID, deviceName);
                    return mapStaff(rs);
                } else {
                    increaseFailedPIN(staffID);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    public Set<String> getPermissionsByStaffID(int staffID) {
        Set<String> permissions = new HashSet<>();

        String sql = "SELECT p.PermissionName "
                + "FROM Staff s "
                + "JOIN RolePermission rp ON s.RoleID = rp.RoleID "
                + "JOIN Permission p ON rp.PermissionID = p.PermissionID "
                + "WHERE s.StaffID = ? AND s.IsActive = 1";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, staffID);

            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                permissions.add(rs.getString("PermissionName"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return permissions;
    }

    public boolean hasPermission(int staffID, String permissionName) {
        String sql = "SELECT 1 "
                + "FROM Staff s "
                + "JOIN RolePermission rp ON s.RoleID = rp.RoleID "
                + "JOIN Permission p ON rp.PermissionID = p.PermissionID "
                + "WHERE s.StaffID = ? AND p.PermissionName = ? AND s.IsActive = 1";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setInt(1, staffID);
            ps.setString(2, permissionName);

            ResultSet rs = ps.executeQuery();

            return rs.next();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean createStaff(String username, String password, String pin, String fullName, int roleID) {
        String sql = "INSERT INTO Staff (Username, Password, PIN_Code, FullName, RoleID, IsActive) "
                + "VALUES (?, ?, ?, ?, ?, 1)";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setString(1, username);
            ps.setString(2, PasswordUtil.sha256(password));
            ps.setString(3, PasswordUtil.sha256(pin));
            ps.setString(4, fullName);
            ps.setInt(5, roleID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean deactivateStaff(int staffID) {
        String sql = "UPDATE Staff SET IsActive = 0 WHERE StaffID = ?";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setInt(1, staffID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    private void increaseFailedPIN(int staffID) throws SQLException {
        String sql = "UPDATE Staff "
                + "SET FailedPINAttempts = FailedPINAttempts + 1, "
                + "LastFailedPINAt = GETDATE(), "
                + "LockedUntil = CASE "
                + "WHEN FailedPINAttempts + 1 >= 5 THEN DATEADD(MINUTE, 30, GETDATE()) "
                + "ELSE LockedUntil END "
                + "WHERE StaffID = ?";

        PreparedStatement ps = connection.prepareStatement(sql);
        ps.setInt(1, staffID);
        ps.executeUpdate();
    }

    private void resetFailedPIN(int staffID) throws SQLException {
        String sql = "UPDATE Staff "
                + "SET FailedPINAttempts = 0, LockedUntil = NULL, LastFailedPINAt = NULL "
                + "WHERE StaffID = ?";

        PreparedStatement ps = connection.prepareStatement(sql);
        ps.setInt(1, staffID);
        ps.executeUpdate();
    }

    private void createSession(int staffID, String deviceName) throws SQLException {
        String closeOldSessionSql = "UPDATE StaffSession "
                + "SET IsActive = 0, LogoutTime = GETDATE() "
                + "WHERE StaffID = ? AND IsActive = 1";

        PreparedStatement closePs = connection.prepareStatement(closeOldSessionSql);
        closePs.setInt(1, staffID);
        closePs.executeUpdate();

        String createSessionSql = "INSERT INTO StaffSession (StaffID, DeviceName, IsActive) "
                + "VALUES (?, ?, 1)";

        PreparedStatement createPs = connection.prepareStatement(createSessionSql);
        createPs.setInt(1, staffID);
        createPs.setString(2, deviceName);
        createPs.executeUpdate();
    }

    private Staff mapStaff(ResultSet rs) throws SQLException {
        Staff staff = new Staff();

        staff.setStaffID(rs.getInt("StaffID"));
        staff.setUsername(rs.getString("Username"));
        staff.setFullName(rs.getString("FullName"));
        staff.setRoleID(rs.getInt("RoleID"));
        staff.setRoleName(rs.getString("RoleName"));
        staff.setActive(rs.getBoolean("IsActive"));

        return staff;
    }

    public List<Staff> getAllStaff() {
        List<Staff> list = new ArrayList<>();

        String sql = "SELECT s.StaffID, s.Username, s.FullName, s.RoleID, r.RoleName, s.IsActive "
                + "FROM Staff s "
                + "JOIN Role r ON s.RoleID = r.RoleID "
                + "ORDER BY s.StaffID DESC";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                Staff staff = new Staff();

                staff.setStaffID(rs.getInt("StaffID"));
                staff.setUsername(rs.getString("Username"));
                staff.setFullName(rs.getString("FullName"));
                staff.setRoleID(rs.getInt("RoleID"));
                staff.setRoleName(rs.getString("RoleName"));
                staff.setActive(rs.getBoolean("IsActive"));

                list.add(staff);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    public List<Role> getAllRoles() {
        List<Role> list = new ArrayList<>();

        String sql = "SELECT RoleID, RoleName FROM Role ORDER BY RoleID";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                Role role = new Role();

                role.setRoleID(rs.getInt("RoleID"));
                role.setRoleName(rs.getString("RoleName"));

                list.add(role);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

   

    public boolean activateStaff(int staffID) {
        String sql = "UPDATE Staff SET IsActive = 1 WHERE StaffID = ?";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setInt(1, staffID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }
}
