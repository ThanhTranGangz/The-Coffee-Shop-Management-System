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

import service.LiteService;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@WebFilter(urlPatterns = "/*", asyncSupported = true)
public class SecurityFilter implements Filter {
    private static final String ATTR_ROLE = "role";
    private static final String ATTR_STAFF_ID = "staffId";
    private final List<String> adminPages = Arrays.asList(
            "/admin-menu.jsp",
            "/admin-tables.jsp",
            "/admin-staff.jsp",
            "/admin-promotions.jsp",
            "/inventory.jsp",
            "/system-logs.jsp"
    );
    private final List<String> baristaPages = Arrays.asList("/staff-orders.jsp");
    private final List<String> cashierPages = Arrays.asList("/cashier.jsp", "/counter-order.jsp");
    private final List<String> runnerPages = Arrays.asList("/runner.jsp");
    private final List<String> transferPages = Arrays.asList("/table-transfer.jsp");
    private final List<String> publicPages = Arrays.asList("/", "/index.html", "/staff-login.jsp", "/dashboard.jsp", "/menu.jsp", "/order-status.jsp",
            "/customer-login.jsp", "/customer-account.jsp");

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String path = req.getRequestURI().substring(req.getContextPath().length());

        // Gắn nhân viên thật vào ngữ cảnh của request để mọi bản ghi nhật ký
        // và sổ quỹ sinh ra bên trong đều quy được trách nhiệm.
        // BẮT BUỘC dọn ở finally: Tomcat dùng lại thread cho request khác,
        // quên clear là log của người này sẽ mang tên người kia.
        LiteService.setActorStaffId(staffIdOf(req));
        try {
            filterInternal(req, res, chain, path);
        } finally {
            LiteService.clearActorStaffId();
        }
    }

    private void filterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain, String path)
            throws IOException, ServletException {
        ServletRequest request = req;
        ServletResponse response = res;

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
            res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
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
        // Đăng nhập bằng tài khoản cá nhân: phải công khai vì đây chính là
        // cửa vào. Bản thân endpoint tự xác thực PIN đã băm.
        if (path.equals("/api/auth/staff-login")) return true;
        // Toàn bộ API khách hàng đi qua đây vì khách KHÔNG có role nhân viên.
        // "Public" ở tầng filter chỉ nghĩa là không đòi role; bản thân servlet
        // vẫn kiểm tra phiên đăng nhập khách cho /me, /history, /points,
        // /profile, /password và trả 401 nếu chưa đăng nhập.
        if (path.startsWith("/api/customer/")) return true;
        // Màn đăng nhập cần hai danh sách này TRƯỚC khi có phiên, để khách
        // chọn đúng vị trí và đúng người đang trong ca. Cả hai chỉ đọc và
        // không lộ gì nhạy cảm (mã vai trò, id + tên nhân viên trong ca).
        if ("GET".equals(method) || "HEAD".equals(method)) {
            if (path.equals("/api/roles") || path.equals("/api/shifts/on-duty")
                    || path.equals("/api/staff/roster")) return true;
        }
        if ("GET".equals(method) || "HEAD".equals(method)) {
            return path.equals("/api/menu") || path.equals("/api/tables") || path.equals("/api/tables/by-code") || path.equals("/api/tables/qr") || path.equals("/api/orders/lookup") || path.equals("/api/orders/table")
                    || path.equals("/api/store/tax-config");
        }
        return "POST".equals(method) && (path.equals("/api/orders") || path.equals("/api/orders/cancel"));
    }

    private boolean isAllowedApi(HttpServletRequest req, String path) {
        String role = role(req);
        if (isAdmin(role)) return true;
        if ("barista".equals(role)) {
            return path.equals("/api/orders") || path.equals("/api/orders/status")
                    || path.equals("/api/orders/item-prepare") || path.equals("/api/cups/status")
                    || path.equals("/api/orders/cancel") || path.equals("/api/events");
        }
        if ("cashier".equals(role)) {
            return path.equals("/api/orders") || path.equals("/api/orders/status") || path.equals("/api/orders/split")
                    || path.equals("/api/tables/map") || path.equals("/api/tables/transfer")
                    || path.equals("/api/cash/status") || path.equals("/api/cash/count") || path.equals("/api/cash/ack-withdrawals")
                    || path.equals("/api/payments/order") || path.equals("/api/payments/summary")
                    || path.equals("/api/orders/cancel") || path.equals("/api/orders/refund")
                    || path.equals("/api/promotions") || path.equals("/api/store/tax-config")
                    || path.equals("/api/events");
        }
        if ("runner".equals(role)) {
            return path.equals("/api/orders") || path.equals("/api/orders/status") || path.equals("/api/orders/invoice")
                    || path.equals("/api/orders/invoice/printed")
                    || path.equals("/api/tables/map") || path.equals("/api/tables/clear") || path.equals("/api/tables/transfer")
                    || path.equals("/api/orders/cancel") || path.equals("/api/events");
        }
        return false;
    }

    private boolean isAdmin(String role) {
        return "admin".equals(role);
    }

    private int staffIdOf(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return 0;
        Object value = session.getAttribute(tabAttr(req, ATTR_STAFF_ID));
        if (value == null) return 0;
        try {
            return Integer.parseInt(String.valueOf(value).trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private String role(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object role = session == null ? null : session.getAttribute(tabAttr(req, ATTR_ROLE));
        return role == null ? "" : String.valueOf(role);
    }

    private String tabKey(HttpServletRequest req) {
        String key = value(req.getHeader("X-Tab-Session"));
        if (key.isEmpty()) key = value(req.getParameter("tabSession"));
        if (key.isEmpty()) key = "default";
        key = key.replaceAll("[^A-Za-z0-9_-]", "");
        if (key.isEmpty()) key = "default";
        return key.length() > 80 ? key.substring(0, 80) : key;
    }

    private String tabAttr(HttpServletRequest req, String base) {
        return base + "." + tabKey(req);
    }

    private String value(Object raw) {
        return raw == null ? "" : String.valueOf(raw).trim();
    }

    private void writeError(HttpServletResponse res, int status, String message) throws IOException {
        res.setStatus(status);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write("{\"error\":\"" + message + "\"}");
    }
}
