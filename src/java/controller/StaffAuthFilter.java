package controller;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import model.Staff;
import util.AuthUtil;
import util.Permission;

/**
 * Yeu cau dang nhap nhan vien cho cac duong dan noi bo.
 * Mot so trang con kiem tra quyen cu the (permission) truoc khi cho vao.
 */
@WebFilter(filterName = "StaffAuthFilter", urlPatterns = {"/staff/*", "/api/staff/*", "/staff-management"})
public class StaffAuthFilter implements Filter {

    private static final Map<String, String> PAGE_PERMISSIONS = Map.of(
            "/staff-management", Permission.MANAGE_STAFF,
            "/staff/table-qr", Permission.MANAGE_TABLE_QR
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        Staff staff = AuthUtil.currentStaff(req);
        if (staff == null) {
            denyUnauthenticated(req, resp);
            return;
        }

        String path = req.getRequestURI().substring(req.getContextPath().length());
        String requiredPermission = PAGE_PERMISSIONS.get(path);
        if (requiredPermission != null && !AuthUtil.hasPermission(req, requiredPermission)) {
            denyForbidden(req, resp);
            return;
        }

        chain.doFilter(request, response);
    }

    private void denyUnauthenticated(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (path.startsWith("/api/")) {
            AuthUtil.writeUnauthorizedJson(resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
        }
    }

    private void denyForbidden(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (path.startsWith("/api/")) {
            AuthUtil.writeForbiddenJson(resp, "Bạn không có quyền thực hiện thao tác này.");
        } else {
            resp.sendRedirect(req.getContextPath() + "/dashboard.jsp?denied=1");
        }
    }
}
