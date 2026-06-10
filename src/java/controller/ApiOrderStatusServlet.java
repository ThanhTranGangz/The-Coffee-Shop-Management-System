package controller;

import dal.OrderDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import model.OrderInfo;
import util.ApiJson;
import util.AppConfig;
import util.JsonUtil;

/**
 * GET /api/orders/status?id=123
 * Khach theo doi don cua minh (chi xem duoc don tao trong phien nay);
 * nhan vien dang nhap xem duoc moi don.
 */
@WebServlet(name = "ApiOrderStatusServlet", urlPatterns = {"/api/orders/status"})
public class ApiOrderStatusServlet extends ApiServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        Integer orderId = intParam(request, "id");
        if (orderId == null) {
            writeError(response, 400, "BAD_REQUEST", "Thiếu mã đơn.");
            return;
        }

        boolean isStaff = currentStaff(request) != null;
        OrderDAO orderDAO = new OrderDAO();
        if (!isStaff && !myOrders(request).contains(orderId)) {
            model.Member member = currentMember(request);
            OrderInfo owned = orderDAO.getOrderInfo(orderId);
            boolean memberOwns = member != null && owned != null
                    && owned.getMemberId() != null
                    && owned.getMemberId() == member.getMemberID();
            if (!memberOwns) {
                writeError(response, 403, "FORBIDDEN", "Bạn không có quyền xem đơn này.");
                return;
            }
        }

        OrderInfo order = orderDAO.getOrderInfo(orderId);
        if (order == null) {
            writeError(response, 404, "NOT_FOUND", "Không tìm thấy đơn.");
            return;
        }

        StringBuilder sb = new StringBuilder();
        sb.append("{\"ok\":true,\"order\":").append(ApiJson.orderInfo(order));
        if ("VIETQR".equals(order.getPaymentMethod()) && !"PAID".equals(order.getPaymentStatus())) {
            sb.append(",\"vietqr\":{")
              .append("\"image\":").append(JsonUtil.str(AppConfig.vietQrImageUrl(order.getFinalAmount(), order.getOrderId())))
              .append(",\"bankName\":").append(JsonUtil.str(AppConfig.BANK_NAME))
              .append(",\"accountNo\":").append(JsonUtil.str(AppConfig.BANK_ACCOUNT_NO))
              .append(",\"accountName\":").append(JsonUtil.str(AppConfig.BANK_ACCOUNT_NAME))
              .append(",\"memo\":").append(JsonUtil.str(AppConfig.paymentMemo(order.getOrderId())))
              .append('}');
        }
        if (order.getMemberId() != null && "PAID".equals(order.getPaymentStatus())) {
            sb.append(",\"pointsEarned\":").append(AppConfig.pointsForAmount(order.getFinalAmount()));
        }
        sb.append('}');
        writeJson(response, 200, sb.toString());
    }
}
