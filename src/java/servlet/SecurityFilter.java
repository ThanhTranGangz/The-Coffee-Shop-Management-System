package servlet;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@WebFilter("/*")
public class SecurityFilter implements Filter {
    private final List<String> adminPages = Arrays.asList("/admin-menu.jsp", "/admin-tables.jsp", "/system-logs.jsp");
    private final List<String> baristaPages = Arrays.asList("/staff-orders.jsp");
    private final List<String> cashierPages = Arrays.asList("/cashier.jsp", "/counter-order.jsp");
    private final List<String> runnerPages = Arrays.asList("/runner.jsp");
    private final List<String> transferPages = Arrays.asList("/table-transfer.jsp");
    private final List<String> publicPages = Arrays.asList("/", "/index.html", "/staff-login.jsp", "/dashboard.jsp", "/menu.jsp", "/order-status.jsp");

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String path = req.getRequestURI().substring(req.getContextPath().length());

        if (path.startsWith("/assets/") || publicPages.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        if (path.startsWith("/api/")) {
            if (isPublicApi(req.getMethod(), path) || isAllowedApi(req, path)) {
                chain.doFilter(request, response);
                return;
            }
            writeError(res, HttpServletResponse.SC_UNAUTHORIZED, "Vui lòng đăng nhập đúng vai trò.");
            return;
        }

        String role = role(req);
        if (adminPages.contains(path) && !isAdmin(role)) {
            res.sendRedirect(req.getContextPath() + "/staff-login.jsp");
            return;
        }
        if (baristaPages.contains(path) && !isAdmin(role) && !"barista".equals(role)) {
            res.sendRedirect(req.getContextPath() + "/staff-login.jsp");
            return;
        }
        if (cashierPages.contains(path) && !isAdmin(role) && !"cashier".equals(role)) {
            res.sendRedirect(req.getContextPath() + "/staff-login.jsp");
            return;
        }
        if (runnerPages.contains(path) && !isAdmin(role) && !"runner".equals(role)) {
            res.sendRedirect(req.getContextPath() + "/staff-login.jsp");
            return;
        }
        if (transferPages.contains(path) && !isAdmin(role) && !"cashier".equals(role) && !"runner".equals(role)) {
            res.sendRedirect(req.getContextPath() + "/staff-login.jsp");
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isPublicApi(String method, String path) {
        if (path.equals("/api/auth/login") || path.equals("/api/auth/admin-pin") || path.equals("/api/auth/logout") || path.equals("/api/auth/session")) return true;
        if ("GET".equals(method) || "HEAD".equals(method)) {
            return path.equals("/api/menu") || path.equals("/api/tables") || path.equals("/api/tables/by-code") || path.equals("/api/tables/qr") || path.equals("/api/orders/lookup") || path.equals("/api/orders/table");
        }
        return "POST".equals(method) && path.equals("/api/orders");
    }

    private boolean isAllowedApi(HttpServletRequest req, String path) {
        String role = role(req);
        if (isAdmin(role)) return true;
        if ("barista".equals(role)) {
            return path.equals("/api/orders") || path.equals("/api/orders/status") || path.equals("/api/cups/status");
        }
        if ("cashier".equals(role)) {
            return path.equals("/api/orders") || path.equals("/api/orders/status")
                    || path.equals("/api/tables/map") || path.equals("/api/tables/transfer")
                    || path.equals("/api/cash/status") || path.equals("/api/cash/count") || path.equals("/api/cash/ack-withdrawals");
        }
        if ("runner".equals(role)) {
            return path.equals("/api/orders") || path.equals("/api/orders/status")
                    || path.equals("/api/tables/map") || path.equals("/api/tables/clear") || path.equals("/api/tables/transfer");
        }
        return false;
    }

    private boolean isAdmin(String role) {
        return "admin".equals(role);
    }

    private String role(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object role = session == null ? null : session.getAttribute("role");
        return role == null ? "" : String.valueOf(role);
    }

    private void writeError(HttpServletResponse res, int status, String message) throws IOException {
        res.setStatus(status);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write("{\"error\":\"" + message + "\"}");
    }
}
