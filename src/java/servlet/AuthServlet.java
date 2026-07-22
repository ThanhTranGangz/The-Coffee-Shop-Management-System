package servlet;

import context.AppContext;
import model.Staff;
import service.BrewStateService;
import utils.JsonUtils;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Servlet handling authentication operations for staff and members.
 */
public class AuthServlet extends HttpServlet {
    
    private BrewStateService stateService;

    /**
     * Initializes the servlet and retrieves the state service.
     * 
     * @throws ServletException if initialization fails
     */
    @Override
    public void init() throws ServletException {
        this.stateService = AppContext.getInstance().getStateService();
    }

    private void setJsonHeaders(HttpServletResponse resp) {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type");
    }

    /**
     * Handles CORS preflight requests.
     */
    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        resp.setStatus(HttpServletResponse.SC_OK);
    }

    /**
     * Handles GET requests for session information and staff options.
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        String pathInfo = req.getPathInfo();

        if ("/session".equals(pathInfo)) {
            HttpSession session = req.getSession(false);
            String role = session != null ? (String) session.getAttribute("auth_role") : null;
            String user = session != null ? (String) session.getAttribute("auth_user") : null;
            String username = session != null ? (String) session.getAttribute("auth_username") : null;
            String memberPhone = session != null ? (String) session.getAttribute("member_phone") : null;

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("authenticated", role != null);
            payload.put("role", role);
            payload.put("user", user);
                        payload.put("memberAuthenticated", memberPhone != null);
            payload.put("memberPhone", memberPhone);
            if (memberPhone != null) {
                model.Member member = stateService.getMemberByPhone(memberPhone);
                payload.put("memberName", member != null ? member.getName() : memberPhone);
            }
            resp.getWriter().write(JsonUtils.toJson(payload));
            return;
        }

        if ("/staff-options".equals(pathInfo)) {
            List<Map<String, Object>> options = new ArrayList<>();
            for (Staff s : stateService.getStaff()) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("id", s.getId());
                item.put("name", s.getName());

                options.add(item);
            }
            resp.getWriter().write(JsonUtils.toJson(options));
            return;
        }

        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
        resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
    }

    /**
     * Handles POST requests for login and logout operations.
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        setJsonHeaders(resp);
        String pathInfo = req.getPathInfo();

        if (pathInfo == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"Missing auth action route.\"}");
            return;
        }

        try {
            if (pathInfo.equals("/login")) {
                handleLogin(req, resp);
            } else if (pathInfo.equals("/logout")) {
                handleLogout(req, resp);
            } else {
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.getWriter().write("{\"error\": \"Endpoint not found.\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleLogin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String body = readBody(req);
        java.util.Map<String, Object> reqMap = JsonUtils.parseObject(body);
        
        String username = (String) reqMap.get("username");
        String password = (String) reqMap.get("password");
        
        if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"ThiÃ¡ÂºÂ¿u thÃƒÂ´ng tin Ã„â€˜Ã„Æ’ng nhâp.\"}");
            return;
        }
        
        try {
            java.util.Map<String, Object> user = service.LiteService.getInstance().login(username, password);
            if (user != null) {
                jakarta.servlet.http.HttpSession session = req.getSession(true);
                String role = (String) user.get("role");
                String name = (String) user.get("fullName");
                session.setAttribute("auth_role", role);
                session.setAttribute("auth_user", name);
                session.removeAttribute("member_phone");
                session.setMaxInactiveInterval(12 * 60 * 60);
                resp.setStatus(HttpServletResponse.SC_OK);
                resp.getWriter().write("{\"message\": \"Ã„ĐÃ„Æ’ng nhâp thÃƒ nh cÃƒÂ´ng\", \"role\": \"" + role + "\", \"user\": \"" + name + "\"}");
            } else {
                resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                resp.getWriter().write("{\"error\": \"Mã PIN khÃƒÂ´ng hợp lệ! Vui lòng thử lại.\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"Lỗi server.\"}");
        }
    }

    private void handleLogout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write("{\"message\": \"Đã đăng xuất\"}");
    }

    private String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        return sb.toString();
    }

    private String escapeJson(String s) {
        if (s == null) return "error";
        return s.replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
    }
}
