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

    private final List<String> managerPages = Arrays.asList("/dashboard.jsp", "/reports.jsp", "/staff-management.jsp", "/inventory.jsp", "/admin-menu.jsp", "/promotions.jsp", "/customers.jsp");
    private final List<String> baristaPages = Arrays.asList("/kds.jsp");
    private final List<String> waiterPages = Arrays.asList("/waitstation.jsp", "/staff-orders.jsp", "/table-qr.jsp", "/order-summary.jsp", "/pos-payment.jsp");
    private final List<String> authEntryPages = Arrays.asList("/", "/index.html", "/staff.html", "/login.jsp", "/pin-login.jsp");
    private final List<String> guestOnlyPages = Arrays.asList("/member.jsp", "/menu.jsp", "/order-status.jsp");
    private final List<String> publicPages = Arrays.asList("/", "/index.html", "/staff.html", "/login.jsp", "/pin-login.jsp", "/member.jsp", "/menu.jsp", "/order-status.jsp");

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

        if (path.startsWith("/api/")) {
            if (isPublicApi(req.getMethod(), path)) {
                chain.doFilter(request, response);
                return;
            }

            if (isMemberApiAllowed(req.getMethod(), path, req)) {
                chain.doFilter(request, response);
                return;
            }

            HttpSession session = req.getSession(false);
            String role = (session != null) ? (String) session.getAttribute("auth_role") : null;
            if (role == null) {
                writeJsonError(res, HttpServletResponse.SC_UNAUTHORIZED, "Vui lòng đăng nhập trước khi thao tác.");
                return;
            }
            if (!isApiAllowedForRole(req.getMethod(), path, role)) {
                writeJsonError(res, HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thực hiện thao tác này.");
                return;
            }

            chain.doFilter(request, response);
            return;
        }

        if (authEntryPages.contains(path) || guestOnlyPages.contains(path)) {
            HttpSession session = req.getSession(false);
            String role = (session != null) ? (String) session.getAttribute("auth_role") : null;
            if (role != null) {
                res.sendRedirect(req.getContextPath() + landingPageForRole(role));
                return;
            }
        }

        // Allow only known public pages and static assets. Staff/admin pages are checked below.
        if (path.startsWith("/assets/") || path.endsWith(".css") || path.endsWith(".js") || publicPages.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        // Only check session for our specific restricted JSPs
        if (managerPages.contains(path) || baristaPages.contains(path) || waiterPages.contains(path)) {
            HttpSession session = req.getSession(false);
            String role = (session != null) ? (String) session.getAttribute("auth_role") : null;

            if (role == null) {
                // Not logged in -> go straight to authentication.
                res.sendRedirect(req.getContextPath() + "/login.jsp");
                return;
            }

            // Check specific role constraints
            if (managerPages.contains(path) && !"manager".equals(role)) {
                res.sendRedirect(req.getContextPath() + "/login.jsp");
                return;
            }
            if (baristaPages.contains(path) && !"manager".equals(role) && !"barista".equals(role)) {
                res.sendRedirect(req.getContextPath() + "/login.jsp");
                return;
            }
            if (waiterPages.contains(path) && !"manager".equals(role) && !"waiter".equals(role)) {
                res.sendRedirect(req.getContextPath() + "/login.jsp");
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

    private boolean isPublicApi(String method, String path) {
        if (path.startsWith("/api/auth/")) return true;

        if ("GET".equals(method)) {
            return path.equals("/api/menu") ||
                   path.equals("/api/vouchers") ||
                   path.equals("/api/tables") ||
                   path.equals("/api/orders/lookup") ||
                   path.equals("/api/shop/status");
        }

        if ("POST".equals(method)) {
            return path.equals("/api/orders") ||
                   path.equals("/api/payments/webhook") ||
                   path.equals("/api/members/login") ||
                   path.equals("/api/members/register") ||
                   path.equals("/api/members/logout");
        }

        return false;
    }

    private boolean isMemberApiAllowed(String method, String path, HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        String memberPhone = (session != null) ? (String) session.getAttribute("member_phone") : null;
        if (memberPhone == null) {
            return false;
        }

        if ("GET".equals(method) && path.equals("/api/members/profile")) {
            String requestedPhone = req.getParameter("phone");
            return memberPhone.equals(requestedPhone);
        }

        return "POST".equals(method) && path.equals("/api/members/redeem");
    }

    private boolean isApiAllowedForRole(String method, String path, String role) {
        if ("manager".equals(role)) return true;

        if ("barista".equals(role)) {
            boolean readOrders = "GET".equals(method) && path.equals("/api/orders");
            boolean updateOrders = "PUT".equals(method) && path.startsWith("/api/orders/");
            return readOrders || updateOrders;
        }

        if ("waiter".equals(role)) {
            boolean readOrders = "GET".equals(method) && path.equals("/api/orders");
            boolean shiftRead = "GET".equals(method) && path.equals("/api/pos/shift");
            boolean shiftAction = "POST".equals(method) && path.startsWith("/api/pos/shift/");
            boolean paymentAction = "POST".equals(method) && path.equals("/api/payments/confirm");
            boolean splitBill = "POST".equals(method) && path.startsWith("/api/orders/") && path.endsWith("/split-bill");
            boolean tableAction = path.startsWith("/api/tables/") || path.equals("/api/tables/move") || path.equals("/api/tables/merge");
            boolean orderAction = "PUT".equals(method) && path.startsWith("/api/orders/");
            return readOrders || shiftRead || shiftAction || paymentAction || splitBill || tableAction || orderAction;
        }

        return false;
    }

    private void writeJsonError(HttpServletResponse res, int status, String message) throws IOException {
        res.setStatus(status);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write("{\"error\":\"" + message + "\"}");
    }

    private String landingPageForRole(String role) {
        if ("manager".equals(role)) {
            return "/dashboard.jsp";
        }
        if ("waiter".equals(role)) {
            return "/waitstation.jsp";
        }
        if ("barista".equals(role)) {
            return "/kds.jsp";
        }
        return "/login.jsp";
    }
}
