package controller;

import dal.ReportDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import model.DailyRevenue;
import model.ProductSales;
import model.SourceStats;
import model.PaymentStats;
import model.MemberTierStats;
import util.AuthUtil;
import util.Permission;
import static util.JsonUtil.str;

@WebServlet(name = "ApiReportsServlet", urlPatterns = {"/api/staff/reports"})
public class ApiReportsServlet extends ApiServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        
        model.Staff staff = currentStaff(request);
        if (staff == null) {
            writeError(response, 401, "UNAUTHORIZED", "Vui lòng đăng nhập nhân viên.");
            return;
        }
        
        // MANAGER role bypasses permission check (consistent with StaffAuthFilter)
        boolean isManager = "MANAGER".equalsIgnoreCase(staff.getRoleName());
        if (!isManager && !AuthUtil.hasPermission(request, Permission.VIEW_REPORT)) {
            writeError(response, 403, "FORBIDDEN", "Bạn không có quyền truy cập dữ liệu báo cáo.");
            return;
        }
        
        String startParam = request.getParameter("startDate");
        String endParam = request.getParameter("endDate");
        LocalDate start, end;
        try {
            if (startParam != null && !startParam.trim().isEmpty()) {
                start = LocalDate.parse(startParam.trim());
            } else {
                start = LocalDate.now().minusDays(30);
            }
            if (endParam != null && !endParam.trim().isEmpty()) {
                end = LocalDate.parse(endParam.trim());
            } else {
                end = LocalDate.now();
            }
        } catch (DateTimeParseException e) {
            start = LocalDate.now().minusDays(30);
            end = LocalDate.now();
        }
        
        if (start.isAfter(end)) {
            LocalDate temp = start;
            start = end;
            end = temp;
        }
        
        ReportDAO dao = new ReportDAO();
        List<DailyRevenue> dailyList = dao.getDailyRevenueReport(start, end);
        List<ProductSales> productList = dao.getTopSellingProducts(start, end, 10);
        List<SourceStats> sourceList = dao.getOrderSourceStats(start, end);
        List<PaymentStats> paymentList = dao.getPaymentMethodStats(start, end);
        List<MemberTierStats> memberList = dao.getMemberTierStats();
        
        StringBuilder sb = new StringBuilder();
        sb.append("{\"ok\":true");
        
        // 1. Daily Revenue
        sb.append(",\"dailyRevenue\":[");
        for (int i = 0; i < dailyList.size(); i++) {
            if (i > 0) sb.append(',');
            DailyRevenue r = dailyList.get(i);
            sb.append("{\"date\":").append(str(r.getDate()))
              .append(",\"totalOrders\":").append(r.getTotalOrders())
              .append(",\"totalRevenue\":").append(r.getTotalRevenue())
              .append(",\"cashRevenue\":").append(r.getCashRevenue())
              .append(",\"vietQrRevenue\":").append(r.getVietQrRevenue())
              .append('}');
        }
        sb.append(']');
        
        // 2. Top Products
        sb.append(",\"topProducts\":[");
        for (int i = 0; i < productList.size(); i++) {
            if (i > 0) sb.append(',');
            ProductSales p = productList.get(i);
            sb.append("{\"productName\":").append(str(p.getProductName()))
              .append(",\"categoryName\":").append(str(p.getCategoryName()))
              .append(",\"quantitySold\":").append(p.getQuantitySold())
              .append(",\"totalRevenue\":").append(p.getTotalRevenue())
              .append('}');
        }
        sb.append(']');
        
        // 3. Source Stats
        sb.append(",\"sourceStats\":[");
        for (int i = 0; i < sourceList.size(); i++) {
            if (i > 0) sb.append(',');
            SourceStats s = sourceList.get(i);
            sb.append("{\"source\":").append(str(s.getSource()))
              .append(",\"totalOrders\":").append(s.getTotalOrders())
              .append(",\"totalRevenue\":").append(s.getTotalRevenue())
              .append('}');
        }
        sb.append(']');
        
        // 4. Payment Stats
        sb.append(",\"paymentStats\":[");
        for (int i = 0; i < paymentList.size(); i++) {
            if (i > 0) sb.append(',');
            PaymentStats p = paymentList.get(i);
            sb.append("{\"paymentMethod\":").append(str(p.getPaymentMethod()))
              .append(",\"totalOrders\":").append(p.getTotalOrders())
              .append(",\"totalRevenue\":").append(p.getTotalRevenue())
              .append('}');
        }
        sb.append(']');
        
        // 5. Member Stats
        sb.append(",\"memberStats\":[");
        for (int i = 0; i < memberList.size(); i++) {
            if (i > 0) sb.append(',');
            MemberTierStats m = memberList.get(i);
            sb.append("{\"tierName\":").append(str(m.getTierName()))
              .append(",\"memberCount\":").append(m.getMemberCount())
              .append('}');
        }
        sb.append(']');
        
        sb.append('}');
        
        writeJson(response, 200, sb.toString());
    }
}
