package controller;

import dal.VoucherDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import model.Voucher;
import util.AppConfig;
import static util.JsonUtil.str;

@WebServlet(name = "ApiCalculatorSimServlet", urlPatterns = {"/api/staff/calculate-sim"})
public class ApiCalculatorSimServlet extends ApiServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        
        if (currentStaff(request) == null) {
            writeError(response, 401, "UNAUTHORIZED", "Vui lòng đăng nhập nhân viên.");
            return;
        }
        
        Integer startingPoints = intParam(request, "startingPoints");
        Integer cartAmount = intParam(request, "cartAmount");
        String voucherCode = request.getParameter("voucherCode");
        
        if (startingPoints == null || startingPoints < 0) {
            startingPoints = 0;
        }
        if (cartAmount == null || cartAmount < 0) {
            cartAmount = 0;
        }
        
        // 1. Determine Starting Tier
        int startingTierID = 1;
        String startingTierName = "Bronze";
        int discountPercent = 0;
        
        if (startingPoints >= 500) {
            startingTierID = 3;
            startingTierName = "Gold";
            discountPercent = 10;
        } else if (startingPoints >= 100) {
            startingTierID = 2;
            startingTierName = "Silver";
            discountPercent = 5;
        }
        
        // 2. Member Discount
        int memberDiscount = (int) ((long) cartAmount * discountPercent / 100);
        int remaining = cartAmount - memberDiscount;
        
        // 3. Voucher calculation
        boolean voucherValid = false;
        int voucherDiscount = 0;
        String voucherMessage = "";
        Integer voucherId = null;
        
        if (voucherCode != null && !voucherCode.trim().isEmpty()) {
            String code = voucherCode.trim().toUpperCase();
            VoucherDAO voucherDAO = new VoucherDAO();
            Voucher v = voucherDAO.findValidVoucher(code, startingTierID);
            if (v == null) {
                voucherValid = false;
                voucherMessage = "Mã không hợp lệ, đã hết hạn hoặc cần hạng thành viên cao hơn.";
            } else {
                voucherValid = true;
                voucherId = v.getVoucherID();
                voucherDiscount = voucherDAO.calculateDiscount(remaining, v);
                voucherMessage = v.getDiscountPercent() != null
                        ? "Giảm " + v.getDiscountPercent() + "% cho đơn này."
                        : "Giảm " + String.format("%,d", v.getDiscountAmount()).replace(',', '.') + "đ cho đơn này.";
            }
        }
        
        // 4. Final calculation
        int finalAmount = Math.max(0, remaining - voucherDiscount);
        int pointsEarned = AppConfig.pointsForAmount(finalAmount);
        int endingPoints = startingPoints + pointsEarned;
        
        // 5. Determine Ending Tier
        int endingTierID = 1;
        String endingTierName = "Bronze";
        if (endingPoints >= 500) {
            endingTierID = 3;
            endingTierName = "Gold";
        } else if (endingPoints >= 100) {
            endingTierID = 2;
            endingTierName = "Silver";
        }
        
        boolean upgraded = endingTierID > startingTierID;
        
        StringBuilder sb = new StringBuilder();
        sb.append("{\"ok\":true")
          .append(",\"startingPoints\":").append(startingPoints)
          .append(",\"startingTier\":").append(str(startingTierName))
          .append(",\"cartAmount\":").append(cartAmount)
          .append(",\"memberDiscountPercent\":").append(discountPercent)
          .append(",\"memberDiscount\":").append(memberDiscount)
          .append(",\"voucherCode\":").append(str(voucherCode))
          .append(",\"voucherValid\":").append(voucherValid)
          .append(",\"voucherDiscount\":").append(voucherDiscount)
          .append(",\"voucherMessage\":").append(str(voucherMessage))
          .append(",\"finalAmount\":").append(finalAmount)
          .append(",\"pointsEarned\":").append(pointsEarned)
          .append(",\"endingPoints\":").append(endingPoints)
          .append(",\"endingTier\":").append(str(endingTierName))
          .append(",\"upgraded\":").append(upgraded)
          .append('}');
        
        writeJson(response, 200, sb.toString());
    }
}
