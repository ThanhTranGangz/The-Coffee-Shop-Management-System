package dal;

import model.ReportSummary;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

public class ReportDAO extends DBContext {

    public ReportSummary getDailySummary(LocalDate date) {
        String sql = "SELECT "
                + "COUNT(OrderID) AS TotalOrders, "
                + "ISNULL(SUM(FinalAmount), 0) AS TotalRevenue, "
                + "ISNULL(SUM(CASE WHEN PaymentMethod = 'CASH' THEN FinalAmount ELSE 0 END), 0) AS CashRevenue, "
                + "ISNULL(SUM(CASE WHEN PaymentMethod = 'VIETQR' THEN FinalAmount ELSE 0 END), 0) AS VietQrRevenue "
                + "FROM Orders "
                + "WHERE PaymentStatus = 'PAID' "
                + "AND CAST(OrderDate AS DATE) = ?";

        try {
            PreparedStatement ps = connection.prepareStatement(sql);

            ps.setDate(1, Date.valueOf(date));

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                ReportSummary report = new ReportSummary();

                report.setTotalOrders(rs.getInt("TotalOrders"));
                report.setTotalRevenue(rs.getInt("TotalRevenue"));
                report.setCashRevenue(rs.getInt("CashRevenue"));
                report.setVietQrRevenue(rs.getInt("VietQrRevenue"));

                return report;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return new ReportSummary(0, 0, 0, 0);
    }
}