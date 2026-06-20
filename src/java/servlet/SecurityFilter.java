package servlet;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
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

    private final List<String> managerPages = Arrays.asList("/dashboard.jsp", "/reports.jsp", "/staff-management.jsp", "/inventory.jsp");
    private final List<String> baristaPages = Arrays.asList("/kds.jsp");
    private final List<String> waiterPages = Arrays.asList("/waitstation.jsp", "/staff-orders.jsp", "/table-qr.jsp", "/order-summary.jsp");
    private final List<String> publicPages = Arrays.asList("/login.jsp", "/pin-login.jsp", "/member.jsp", "/menu.jsp", "/order-status.jsp");

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization if needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String uri = req.getRequestURI();
        String path = uri.substring(req.getContextPath().length());

        // Allow static resources, API endpoints, HTML files (like index.html, staff.html), and public JSPs
        if (path.startsWith("/api/") || path.startsWith("/assets/") || path.equals("/") || 
            path.endsWith(".html") || path.endsWith(".css") || path.endsWith(".js") ||
            publicPages.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        // Only check session for our specific restricted JSPs
        if (managerPages.contains(path) || baristaPages.contains(path) || waiterPages.contains(path)) {
            HttpSession session = req.getSession(false);
            String role = (session != null) ? (String) session.getAttribute("auth_role") : null;

            if (role == null) {
                // Not logged in -> redirect to staff portal
                res.sendRedirect(req.getContextPath() + "/staff.html");
                return;
            }

            // Check specific role constraints
            if (managerPages.contains(path) && !"manager".equals(role)) {
                res.sendRedirect(req.getContextPath() + "/staff.html");
                return;
            }
            if (baristaPages.contains(path) && !"manager".equals(role) && !"barista".equals(role)) {
                res.sendRedirect(req.getContextPath() + "/staff.html");
                return;
            }
            if (waiterPages.contains(path) && !"manager".equals(role) && !"waiter".equals(role)) {
                res.sendRedirect(req.getContextPath() + "/staff.html");
                return;
            }
        }

        // Proceed if allowed
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup if needed
    }
}
