package controller;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import model.CartLine;
import model.PriceQuote;
import util.ApiJson;
import util.PricingService;

/**
 * POST /api/orders/quote  (API tinh tong tien - tam tinh)
 * Body (form-encoded): productId/quantity/note lap lai theo dong + voucherCode.
 * Gia luon duoc tinh lai tu DB tren server.
 */
@WebServlet(name = "ApiQuoteServlet", urlPatterns = {"/api/orders/quote"})
public class ApiQuoteServlet extends ApiServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        List<CartLine> lines = readCartLines(request);
        if (lines.isEmpty()) {
            writeError(response, 400, "EMPTY_CART", "Giỏ hàng đang trống.");
            return;
        }

        PriceQuote quote = new PricingService().quote(
                lines, currentMember(request), request.getParameter("voucherCode"));

        writeJson(response, 200, "{\"ok\":true,\"quote\":" + ApiJson.quote(quote) + "}");
    }
}
