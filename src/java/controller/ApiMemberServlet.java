package controller;

import dal.MemberDAO;
import dal.OrderDAO;
import dal.VoucherDAO;
import java.util.List;
import model.OrderInfo;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import model.Member;
import util.ApiJson;
import util.PasswordUtil;

/**
 * API tai khoan thanh vien (khach hang than thiet):
 *   GET  /api/member/me       -> thong tin + uu dai kha dung
 *   POST /api/member/login    -> dang nhap bang SDT + mat khau
 *   POST /api/member/register -> dang ky moi (hang Bronze)
 *   POST /api/member/logout
 */
@WebServlet(name = "ApiMemberServlet", urlPatterns = {
    "/api/member/me", "/api/member/login", "/api/member/register", "/api/member/logout",
    "/api/member/orders"})
public class ApiMemberServlet extends ApiServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String path = request.getServletPath();
        if (path.endsWith("/orders")) {
            orders(request, response);
            return;
        }
        if (!path.endsWith("/me")) {
            writeError(response, 405, "METHOD_NOT_ALLOWED", "Dùng POST cho endpoint này.");
            return;
        }
        Member member = currentMember(request);
        if (member != null) {
            // Lay so diem / hang moi nhat tu DB
            Member fresh = new MemberDAO().findById(member.getMemberID());
            if (fresh != null) {
                member = fresh;
                request.getSession(true).setAttribute("member", fresh);
            }
        }
        int tierId = member == null ? 0 : member.getTierID();
        String vouchers = ApiJson.vouchers(new VoucherDAO().findAvailableForTier(tierId));
        writeJson(response, 200, "{\"ok\":true,\"loggedIn\":" + (member != null)
                + ",\"member\":" + ApiJson.member(member)
                + ",\"vouchers\":" + vouchers + "}");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String path = request.getServletPath();
        if (path.endsWith("/login")) {
            login(request, response);
        } else if (path.endsWith("/register")) {
            register(request, response);
        } else if (path.endsWith("/logout")) {
            logout(request, response);
        } else {
            writeError(response, 405, "METHOD_NOT_ALLOWED", "Dùng GET cho endpoint này.");
        }
    }

    private void login(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String phone = trim(request.getParameter("phone"));
        String password = trim(request.getParameter("password"));
        if (phone.isEmpty() || password.isEmpty()) {
            writeError(response, 400, "BAD_REQUEST", "Vui lòng nhập số điện thoại và mật khẩu.");
            return;
        }
        Member member = new MemberDAO().loginByPhonePassword(phone, PasswordUtil.sha256(password));
        if (member == null) {
            writeError(response, 401, "LOGIN_FAILED", "Số điện thoại hoặc mật khẩu chưa đúng.");
            return;
        }
        request.getSession(true).setAttribute("member", member);
        writeJson(response, 200, "{\"ok\":true,\"member\":" + ApiJson.member(member) + "}");
    }

    private void register(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String fullName = trim(request.getParameter("fullName"));
        String phone = trim(request.getParameter("phone"));
        String password = trim(request.getParameter("password"));

        if (fullName.length() < 2) {
            writeError(response, 400, "BAD_NAME", "Vui lòng nhập họ tên.");
            return;
        }
        if (!phone.matches("0\\d{8,10}")) {
            writeError(response, 400, "BAD_PHONE", "Số điện thoại chưa đúng định dạng.");
            return;
        }
        if (password.length() < 6) {
            writeError(response, 400, "BAD_PASSWORD", "Mật khẩu cần ít nhất 6 ký tự.");
            return;
        }

        Member member = new MemberDAO().register(fullName, phone, PasswordUtil.sha256(password));
        if (member == null) {
            writeError(response, 409, "PHONE_EXISTS", "Số điện thoại này đã đăng ký thành viên.");
            return;
        }
        request.getSession(true).setAttribute("member", member);
        writeJson(response, 200, "{\"ok\":true,\"member\":" + ApiJson.member(member) + "}");
    }

    private void orders(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Member member = currentMember(request);
        if (member == null) {
            writeError(response, 401, "UNAUTHORIZED", "Vui lòng đăng nhập thành viên.");
            return;
        }
        List<OrderInfo> orders = new OrderDAO().findByMemberId(member.getMemberID(), 20);
        StringBuilder sb = new StringBuilder("{\"ok\":true,\"orders\":[");
        for (int i = 0; i < orders.size(); i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append(ApiJson.orderBrief(orders.get(i)));
        }
        sb.append("]}");
        writeJson(response, 200, sb.toString());
    }

    private void logout(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.removeAttribute("member");
        }
        writeJson(response, 200, "{\"ok\":true}");
    }

    private String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
