package dal;

import model.ReportSummary;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

public class ReportDAO extends DBContext {

    public ReportSummary getDailySummary(LocalDate date) {
        if (date == null) {
            return new ReportSummary(0, 0, 0, 0);
        }

        String sql = "SELECT "
                + "COUNT(OrderID) AS TotalOrders, "
                + "ISNULL(SUM(FinalAmount), 0) AS TotalRevenue, "
                + "ISNULL(SUM(CASE WHEN PaymentMethod = 'CASH' THEN FinalAmount ELSE 0 END), 0) AS CashRevenue, "
                + "ISNULL(SUM(CASE WHEN PaymentMethod = 'VIETQR' THEN FinalAmount ELSE 0 END), 0) AS VietQrRevenue "
                + "FROM Orders "
                + "WHERE PaymentStatus = 'PAID' "
                + "AND OrderDate >= ? "
                + "AND OrderDate < ?";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setTimestamp(1, java.sql.Timestamp.valueOf(date.atStartOfDay()));
            ps.setTimestamp(2, java.sql.Timestamp.valueOf(date.plusDays(1).atStartOfDay()));

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ReportSummary report = new ReportSummary();

                    report.setTotalOrders(rs.getInt("TotalOrders"));
                    report.setTotalRevenue(rs.getInt("TotalRevenue"));
                    report.setCashRevenue(rs.getInt("CashRevenue"));
                    report.setVietQrRevenue(rs.getInt("VietQrRevenue"));

                    return report;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return new ReportSummary(0, 0, 0, 0);
    }
}
