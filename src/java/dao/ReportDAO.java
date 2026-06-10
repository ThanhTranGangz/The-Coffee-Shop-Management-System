package dal;

import model.ReportSummary;
import model.DailyRevenue;
import model.ProductSales;
import model.SourceStats;
import model.PaymentStats;
import model.MemberTierStats;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

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

    public List<DailyRevenue> getDailyRevenueReport(LocalDate start, LocalDate end) {
        List<DailyRevenue> list = new ArrayList<>();
        if (start == null || end == null) {
            return list;
        }

        String sql = "SELECT "
                + "CAST(OrderDate AS DATE) AS OrderDay, "
                + "COUNT(OrderID) AS TotalOrders, "
                + "ISNULL(SUM(FinalAmount), 0) AS TotalRevenue, "
                + "ISNULL(SUM(CASE WHEN PaymentMethod = 'CASH' THEN FinalAmount ELSE 0 END), 0) AS CashRevenue, "
                + "ISNULL(SUM(CASE WHEN PaymentMethod = 'VIETQR' THEN FinalAmount ELSE 0 END), 0) AS VietQrRevenue "
                + "FROM Orders "
                + "WHERE PaymentStatus = 'PAID' "
                + "AND OrderDate >= ? "
                + "AND OrderDate < ? "
                + "GROUP BY CAST(OrderDate AS DATE) "
                + "ORDER BY OrderDay ASC";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setTimestamp(1, java.sql.Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, java.sql.Timestamp.valueOf(end.plusDays(1).atStartOfDay()));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DailyRevenue r = new DailyRevenue();
                    r.setDate(rs.getDate("OrderDay").toString());
                    r.setTotalOrders(rs.getInt("TotalOrders"));
                    r.setTotalRevenue(rs.getInt("TotalRevenue"));
                    r.setCashRevenue(rs.getInt("CashRevenue"));
                    r.setVietQrRevenue(rs.getInt("VietQrRevenue"));
                    list.add(r);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<ProductSales> getTopSellingProducts(LocalDate start, LocalDate end, int limit) {
        List<ProductSales> list = new ArrayList<>();
        if (start == null || end == null) {
            return list;
        }

        String sql = "SELECT TOP (?) "
                + "p.ProductName, "
                + "c.CategoryName, "
                + "SUM(od.Quantity) AS QuantitySold, "
                + "SUM(od.Quantity * od.UnitPrice) AS TotalRevenue "
                + "FROM OrderDetail od "
                + "JOIN Orders o ON od.OrderID = o.OrderID "
                + "JOIN Product p ON od.ProductID = p.ProductID "
                + "JOIN Category c ON p.CategoryID = c.CategoryID "
                + "WHERE o.PaymentStatus = 'PAID' "
                + "AND o.OrderDate >= ? "
                + "AND o.OrderDate < ? "
                + "GROUP BY p.ProductName, c.CategoryName "
                + "ORDER BY QuantitySold DESC, TotalRevenue DESC";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setTimestamp(2, java.sql.Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(3, java.sql.Timestamp.valueOf(end.plusDays(1).atStartOfDay()));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductSales p = new ProductSales();
                    p.setProductName(rs.getString("ProductName"));
                    p.setCategoryName(rs.getString("CategoryName"));
                    p.setQuantitySold(rs.getInt("QuantitySold"));
                    p.setTotalRevenue(rs.getInt("TotalRevenue"));
                    list.add(p);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<SourceStats> getOrderSourceStats(LocalDate start, LocalDate end) {
        List<SourceStats> list = new ArrayList<>();
        if (start == null || end == null) {
            return list;
        }

        String sql = "SELECT "
                + "OrderSource, "
                + "COUNT(OrderID) AS TotalOrders, "
                + "ISNULL(SUM(FinalAmount), 0) AS TotalRevenue "
                + "FROM Orders "
                + "WHERE PaymentStatus = 'PAID' "
                + "AND OrderDate >= ? "
                + "AND OrderDate < ? "
                + "GROUP BY OrderSource "
                + "ORDER BY TotalRevenue DESC";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setTimestamp(1, java.sql.Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, java.sql.Timestamp.valueOf(end.plusDays(1).atStartOfDay()));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SourceStats s = new SourceStats();
                    s.setSource(rs.getString("OrderSource"));
                    s.setTotalOrders(rs.getInt("TotalOrders"));
                    s.setTotalRevenue(rs.getInt("TotalRevenue"));
                    list.add(s);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<PaymentStats> getPaymentMethodStats(LocalDate start, LocalDate end) {
        List<PaymentStats> list = new ArrayList<>();
        if (start == null || end == null) {
            return list;
        }

        String sql = "SELECT "
                + "PaymentMethod, "
                + "COUNT(OrderID) AS TotalOrders, "
                + "ISNULL(SUM(FinalAmount), 0) AS TotalRevenue "
                + "FROM Orders "
                + "WHERE PaymentStatus = 'PAID' "
                + "AND OrderDate >= ? "
                + "AND OrderDate < ? "
                + "GROUP BY PaymentMethod "
                + "ORDER BY TotalRevenue DESC";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setTimestamp(1, java.sql.Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, java.sql.Timestamp.valueOf(end.plusDays(1).atStartOfDay()));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PaymentStats p = new PaymentStats();
                    p.setPaymentMethod(rs.getString("PaymentMethod"));
                    p.setTotalOrders(rs.getInt("TotalOrders"));
                    p.setTotalRevenue(rs.getInt("TotalRevenue"));
                    list.add(p);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<MemberTierStats> getMemberTierStats() {
        List<MemberTierStats> list = new ArrayList<>();

        String sql = "SELECT "
                + "t.TierName, "
                + "COUNT(m.MemberID) AS MemberCount "
                + "FROM Member m "
                + "JOIN Tier t ON m.TierID = t.TierID "
                + "WHERE m.IsActive = 1 "
                + "GROUP BY t.TierName, t.MinPoints "
                + "ORDER BY t.MinPoints ASC";

        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                MemberTierStats m = new MemberTierStats();
                m.setTierName(rs.getString("TierName"));
                m.setMemberCount(rs.getInt("MemberCount"));
                list.add(m);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
}
