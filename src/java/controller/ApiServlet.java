package controller;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import model.CartLine;
import model.Member;
import model.Staff;
import model.Tables;

/**
 * Lop cha cho cac servlet API JSON: doc gio hang tu form-encoded,
 * doc session, ghi JSON ra response.
 */
public abstract class ApiServlet extends HttpServlet {

    protected void writeJson(HttpServletResponse resp, int status, String json) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().write(json);
    }

    protected void writeError(HttpServletResponse resp, int status, String code, String message)
            throws IOException {
        writeJson(resp, status, "{\"ok\":false,\"error\":\"" + code + "\",\"message\":\""
                + util.JsonUtil.esc(message) + "\"}");
    }

    /**
     * Gio hang duoc gui dang 3 mang song song:
     * productId=1&quantity=2&note=it+da&productId=5&quantity=1&note=
     */
    protected List<CartLine> readCartLines(HttpServletRequest req) {
        List<CartLine> lines = new ArrayList<>();
        String[] ids = req.getParameterValues("productId");
        String[] qtys = req.getParameterValues("quantity");
        String[] notes = req.getParameterValues("note");
        if (ids == null) {
            return lines;
        }
        for (int i = 0; i < ids.length; i++) {
            try {
                int productId = Integer.parseInt(ids[i].trim());
                int qty = (qtys != null && i < qtys.length) ? Integer.parseInt(qtys[i].trim()) : 1;
                String note = (notes != null && i < notes.length) ? notes[i] : null;
                if (note != null) {
                    note = note.trim();
                    if (note.length() > 200) {
                        note = note.substring(0, 200);
                    }
                    if (note.isEmpty()) {
                        note = null;
                    }
                }
                if (qty > 0) {
                    lines.add(new CartLine(productId, qty, note));
                }
            } catch (NumberFormatException ignore) {
                // bo qua dong loi
            }
        }
        return lines;
    }

    protected Member currentMember(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        return session == null ? null : (Member) session.getAttribute("member");
    }

    protected Staff currentStaff(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        return session == null ? null : (Staff) session.getAttribute("staff");
    }

    protected Tables currentTable(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        return session == null ? null : (Tables) session.getAttribute("table");
    }

    /** Danh sach OrderID khach da tao trong phien nay (de xem trang thai don). */
    @SuppressWarnings("unchecked")
    protected List<Integer> myOrders(HttpServletRequest req) {
        HttpSession session = req.getSession(true);
        List<Integer> list = (List<Integer>) session.getAttribute("myOrders");
        if (list == null) {
            list = new ArrayList<>();
            session.setAttribute("myOrders", list);
        }
        return list;
    }

    protected Integer intParam(HttpServletRequest req, String name) {
        String raw = req.getParameter(name);
        if (raw == null || raw.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
