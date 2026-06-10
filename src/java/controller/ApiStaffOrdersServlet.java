package controller;

import dal.MemberDAO;
import dal.OrderDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import model.OrderInfo;
import util.ApiJson;
import util.AppConfig;
import util.AuthUtil;
import util.Permission;

/**
 * API bang don cho nhan vien (pha che + thu ngan):
 *   GET  /api/staff/orders                    -> don dang xu ly + don trong ngay
 *   POST /api/staff/orders  action=advance    -> PENDING > PREPARING > READY > COMPLETED
 *   POST /api/staff/orders  action=markPaid   -> xac nhan da thu tien + tich diem thanh vien
 *   POST /api/staff/orders  action=cancel     -> huy don PENDING, hoan kho
 */
@WebServlet(name = "ApiStaffOrdersServlet", urlPatterns = {"/api/staff/orders"})
public class ApiStaffOrdersServlet extends ApiServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (currentStaff(request) == null) {
            writeError(response, 401, "UNAUTHORIZED", "Vui lòng đăng nhập nhân viên.");
            return;
        }
        if (!AuthUtil.hasAnyPermission(request, Permission.VIEW_STAFF_ORDERS, Permission.VIEW_KITCHEN_ORDER)) {
            writeError(response, 403, "FORBIDDEN", "Bạn không có quyền xem bảng đơn.");
            return;
        }
        List<OrderInfo> orders = new OrderDAO().getBoardOrders();
        StringBuilder sb = new StringBuilder("{\"ok\":true,\"orders\":[");
        for (int i = 0; i < orders.size(); i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append(ApiJson.orderInfo(orders.get(i)));
        }
        sb.append("]}");
        writeJson(response, 200, sb.toString());
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (currentStaff(request) == null) {
            writeError(response, 401, "UNAUTHORIZED", "Vui lòng đăng nhập nhân viên.");
            return;
        }
        Integer orderId = intParam(request, "orderId");
        String action = request.getParameter("action");
        if (orderId == null || action == null) {
            writeError(response, 400, "BAD_REQUEST", "Thiếu orderId hoặc action.");
            return;
        }

        OrderDAO dao = new OrderDAO();
        switch (action) {
            case "advance": {
                if (!AuthUtil.hasPermission(request, Permission.UPDATE_ORDER_STATUS)) {
                    writeError(response, 403, "FORBIDDEN", "Bạn không có quyền cập nhật trạng thái đơn.");
                    return;
                }
                String next = dao.advanceStatus(orderId);
                if (next == null) {
                    writeError(response, 409, "CANNOT_ADVANCE", "Đơn không thể chuyển trạng thái.");
                } else {
                    writeJson(response, 200, "{\"ok\":true,\"status\":\"" + next + "\"}");
                }
                return;
            }
            case "markPaid": {
                if (!AuthUtil.hasPermission(request, Permission.CONFIRM_PAYMENT)) {
                    writeError(response, 403, "FORBIDDEN", "Bạn không có quyền xác nhận thanh toán.");
                    return;
                }
                OrderDAO.PaidResult result = dao.markPaid(orderId);
                if (!result.updated) {
                    writeError(response, 409, "ALREADY_PAID", "Đơn đã được thanh toán trước đó.");
                    return;
                }
                int points = 0;
                if (result.memberId != null) {
                    points = AppConfig.pointsForAmount(result.finalAmount);
                    if (points > 0) {
                        new MemberDAO().addRewardPoints(result.memberId, orderId, points,
                                "Tích điểm đơn #" + orderId);
                    }
                }
                writeJson(response, 200, "{\"ok\":true,\"paid\":true,\"pointsAwarded\":" + points + "}");
                return;
            }
            case "cancel": {
                if (!AuthUtil.hasPermission(request, Permission.CANCEL_ORDER)) {
                    writeError(response, 403, "FORBIDDEN", "Bạn không có quyền hủy đơn.");
                    return;
                }
                boolean ok = dao.cancelOrder(orderId);
                if (ok) {
                    writeJson(response, 200, "{\"ok\":true}");
                } else {
                    writeError(response, 409, "CANNOT_CANCEL", "Chỉ hủy được đơn chưa pha chế.");
                }
                return;
            }
            default:
                writeError(response, 400, "BAD_ACTION", "Action không hợp lệ.");
        }
    }
}
