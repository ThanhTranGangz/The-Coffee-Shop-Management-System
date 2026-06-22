package servlet;

import context.AppContext;
import model.Staff;
import service.BrewStateService;
import utils.JsonUtils;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
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
@WebServlet("/api/auth/*")
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
            payload.put("username", username);
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
                item.put("username", s.getUsername());
                item.put("role", s.getRole());
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
        Map<String, Object> reqMap = JsonUtils.parseObject(body);
        
        String username = (String) reqMap.get("username");
        String password = (String) reqMap.get("password");
        String pin = (String) reqMap.get("pin");

        List<Staff> roster = stateService.getStaff();
        Staff matched = null;

        if (pin != null && !pin.isEmpty()) {
            for (Staff s : roster) {
                boolean samePin = pin.equals(s.getPin());
                boolean sameUser = username == null || username.trim().isEmpty() || username.equals(s.getUsername());
                if (samePin && sameUser) {
                    matched = s;
                    break;
                }
            }
            if (matched == null) {
                resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                resp.getWriter().write("{\"error\": \"Mã PIN không hợp lệ! Vui lòng thử lại.\"}");
                return;
            }
        } else {
            if (username == null || username.trim().isEmpty() || password == null) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                resp.getWriter().write("{\"error\": \"Vui lòng nhập đầy đủ tài khoản và mật khẩu.\"}");
                return;
            }
            for (Staff s : roster) {
                if (username.equals(s.getUsername())) {
                    matched = s;
                    break;
                }
            }
            if (matched == null) {
                resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                resp.getWriter().write("{\"error\": \"Tài khoản nhân viên này không tồn tại trên hệ thống!\"}");
                return;
            }
            if (!password.equals(matched.getPassword())) {
                resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                resp.getWriter().write("{\"error\": \"Mật khẩu đăng nhập không chính xác! Vui lòng thử lại.\"}");
                return;
            }
        }

        // Check Status & Shift logic
        if (!"manager".equals(matched.getRole())) {
            String status = matched.getStatus() != null ? matched.getStatus() : "Active";
            
            if ("Temp_Inactive".equals(status)) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                resp.getWriter().write("{\"error\": \"⏸️ Tài khoản của bạn hiện đang bị VÔ HIỆU HÓA TẠM THỜI bởi quản lý cho ngày hôm nay.\"}");
                return;
            }
            if ("Perm_Inactive".equals(status)) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                resp.getWriter().write("{\"error\": \"🔒 Tài khoản của bạn đã bị KHÓA VĨNH VIỄN trên hệ thống.\"}");
                return;
            }
            if ("Off_Duty".equals(status)) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                resp.getWriter().write("{\"error\": \"🕊️ Bạn đã được Quản trị viên thông báo tan làm sớm hôm nay! Trạng thái trực tạm ngưng hiệu lực.\"}");
                return;
            }

            int currentHour = LocalTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).getHour();
            if (!matched.isOvertime()) {
                String shiftStr = matched.getShift() != null ? matched.getShift().toLowerCase() : "";
                if (shiftStr.contains("ca sáng") || shiftStr.contains("sáng")) {
                    if (currentHour < 6 || currentHour >= 12) {
                        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        resp.getWriter().write("{\"error\": \"⏰ Tài khoản của bạn thuộc Ca Sáng (06:00 - 12:00) đã hết giờ trực ca hoặc chưa đến múi trực!\"}");
                        return;
                    }
                } else if (shiftStr.contains("ca chiều") || shiftStr.contains("chiều")) {
                    if (currentHour < 12 || currentHour >= 18) {
                        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        resp.getWriter().write("{\"error\": \"⏰ Tài khoản của bạn thuộc Ca Chiều (12:00 - 18:00) hiện tại không thuộc múi trực ca hoặc chưa đến giờ!\"}");
                        return;
                    }
                } else if (shiftStr.contains("ca tối") || shiftStr.contains("tối")) {
                    if (currentHour < 18 || currentHour >= 24) {
                        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        resp.getWriter().write("{\"error\": \"⏰ Tài khoản của bạn thuộc Ca Tối (18:00 - 24:00) không thuộc múi giờ ca tối hiện hành!\"}");
                        return;
                    }
                }
            } else {
                if (currentHour >= 24 || currentHour < 6) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    resp.getWriter().write("{\"error\": \"⏰ Ca tăng ca phụ vụ trong ngày chỉ kéo dài đến 24:00 đêm! Giao dịch POS đã khép ca.\"}");
                    return;
                }
            }
        }

        HttpSession session = req.getSession(true);
        session.setAttribute("auth_role", matched.getRole());
        session.setAttribute("auth_user", matched.getName());
        session.setAttribute("auth_username", matched.getUsername());
        session.removeAttribute("member_phone");
        // Set explicitly long timeout for authenticated staff (12 hours)
        session.setMaxInactiveInterval(12 * 60 * 60);

        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write("{\"message\": \"Đăng nhập thành công\", \"role\": \"" + matched.getRole() + "\", \"user\": \"" + matched.getName() + "\"}");
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
