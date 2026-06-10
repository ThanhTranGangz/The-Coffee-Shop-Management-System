package controller;

import dal.OrderDAO;
import dal.ProductDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import model.CartLine;
import model.Member;
import model.MenuItem;
import model.PriceQuote;
import model.Tables;
import util.AppConfig;
import util.JsonUtil;
import util.PricingService;

/**
 * POST /api/orders/create  (API tao don hang)
 * Yeu cau da quet QR ban (session co "table"). Sau khi khach xac nhan
 * thanh toan (chon CASH hoac VIETQR) don moi duoc tao va day sang pha che.
 */
@WebServlet(name = "ApiCreateOrderServlet", urlPatterns = {"/api/orders/create"})
public class ApiCreateOrderServlet extends ApiServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        Tables table = currentTable(request);
        if (table == null) {
            writeError(response, 400, "NO_TABLE",
                    "Bạn chưa chọn bàn. Vui lòng quét mã QR dán tại bàn để gọi món.");
            return;
        }

        String paymentMethod = request.getParameter("paymentMethod");
        if (!"CASH".equals(paymentMethod) && !"VIETQR".equals(paymentMethod)) {
            writeError(response, 400, "BAD_PAYMENT", "Vui lòng chọn hình thức thanh toán.");
            return;
        }

        List<CartLine> lines = readCartLines(request);
        if (lines.isEmpty()) {
            writeError(response, 400, "EMPTY_CART", "Giỏ hàng đang trống.");
            return;
        }

        Member member = currentMember(request);
        String voucherCode = request.getParameter("voucherCode");

        PricingService pricing = new PricingService();
        PriceQuote quote = pricing.quote(lines, member, voucherCode);

        if (quote.getLines().isEmpty() || quote.getSubtotal() <= 0) {
            writeError(response, 400, "EMPTY_CART", "Giỏ hàng không hợp lệ.");
            return;
        }
        if (!quote.isAllAvailable()) {
            StringBuilder names = new StringBuilder();
            for (PriceQuote.QuoteLine l : quote.getLines()) {
                if (!l.isAvailable()) {
                    if (names.length() > 0) {
                        names.append(", ");
                    }
                    names.append(l.getProductName());
                }
            }
            writeError(response, 409, "UNAVAILABLE",
                    "Món sau vừa hết hàng: " + names + ". Vui lòng bỏ khỏi giỏ rồi đặt lại.");
            return;
        }
        if (voucherCode != null && !voucherCode.trim().isEmpty() && !quote.isVoucherValid()) {
            writeError(response, 409, "VOUCHER_INVALID", quote.getVoucherMessage());
            return;
        }

        // Dung so luong da chuan hoa trong quote de ghi don
        List<CartLine> normalized = new ArrayList<>();
        List<Integer> ids = new ArrayList<>();
        for (PriceQuote.QuoteLine l : quote.getLines()) {
            normalized.add(new CartLine(l.getProductId(), l.getQuantity(), l.getNote()));
            if (!ids.contains(l.getProductId())) {
                ids.add(l.getProductId());
            }
        }
        Map<Integer, MenuItem> products = new ProductDAO().findByIds(ids);

        try {
            int orderId = new OrderDAO().createOrder(
                    table.getTableId(),
                    member == null ? null : member.getMemberID(),
                    quote.isVoucherValid() ? quote.getVoucherId() : null,
                    quote.getSubtotal(),
                    quote.getDiscountTotal(),
                    paymentMethod,
                    normalized,
                    products);

            myOrders(request).add(orderId);

            StringBuilder sb = new StringBuilder();
            sb.append("{\"ok\":true,\"orderId\":").append(orderId)
              .append(",\"finalAmount\":").append(quote.getTotal())
              .append(",\"paymentMethod\":\"").append(paymentMethod).append('"')
              .append(",\"pointsEarn\":").append(quote.getPointsEarn());
            if ("VIETQR".equals(paymentMethod)) {
                sb.append(",\"vietqr\":{")
                  .append("\"image\":").append(JsonUtil.str(AppConfig.vietQrImageUrl(quote.getTotal(), orderId)))
                  .append(",\"bankName\":").append(JsonUtil.str(AppConfig.BANK_NAME))
                  .append(",\"accountNo\":").append(JsonUtil.str(AppConfig.BANK_ACCOUNT_NO))
                  .append(",\"accountName\":").append(JsonUtil.str(AppConfig.BANK_ACCOUNT_NAME))
                  .append(",\"memo\":").append(JsonUtil.str(AppConfig.paymentMemo(orderId)))
                  .append('}');
            }
            sb.append('}');
            writeJson(response, 200, sb.toString());
        } catch (IllegalStateException stock) {
            writeError(response, 409, "OUT_OF_STOCK", stock.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, 500, "SERVER_ERROR", "Không tạo được đơn, vui lòng thử lại.");
        }
    }
}
