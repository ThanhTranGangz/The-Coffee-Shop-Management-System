package util;

import dal.StaffDAO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import model.Staff;

public final class AuthUtil {

    private AuthUtil() {
    }

    public static Staff currentStaff(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session == null ? null : (Staff) session.getAttribute("staff");
    }

    @SuppressWarnings("unchecked")
    public static Set<String> permissions(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return Collections.emptySet();
        }
        Set<String> perms = (Set<String>) session.getAttribute("permissions");
        return perms == null ? Collections.emptySet() : perms;
    }

    public static boolean hasPermission(HttpServletRequest request, String permission) {
        return permissions(request).contains(permission);
    }

    public static boolean hasAnyPermission(HttpServletRequest request, String... permissionNames) {
        Set<String> perms = permissions(request);
        for (String name : permissionNames) {
            if (perms.contains(name)) {
                return true;
            }
        }
        return false;
    }

    public static void bindStaffSession(HttpSession session, Staff staff) {
        session.setAttribute("staff", staff);
        session.setAttribute("permissions",
                new StaffDAO().getPermissionsByStaffID(staff.getStaffID()));
    }

    public static void writeUnauthorizedJson(HttpServletResponse response) throws IOException {
        writeJsonError(response, 401, "UNAUTHORIZED", "Vui lòng đăng nhập nhân viên.");
    }

    public static void writeForbiddenJson(HttpServletResponse response, String message)
            throws IOException {
        writeJsonError(response, 403, "FORBIDDEN", message);
    }

    private static void writeJsonError(HttpServletResponse response, int status,
            String code, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");
        response.getWriter().write("{\"ok\":false,\"error\":\"" + code + "\",\"message\":\""
                + JsonUtil.esc(message) + "\"}");
    }
}
