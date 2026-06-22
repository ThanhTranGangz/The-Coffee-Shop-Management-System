package dao;

import context.DBContext;
import model.Voucher;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class VoucherDAO {
    private List<Voucher> fallbackVouchers = createDefaultVouchers();

    public VoucherDAO() {
        ensureTable();
        seedDefaultsIfEmpty();
    }

    public List<Voucher> getAll() {
        ensureTable();
        List<Voucher> list = new ArrayList<>();
        String sql = "SELECT code, name, discountAmount, pointCost, active FROM dbo.Vouchers ORDER BY pointCost ASC, discountAmount ASC";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                list.add(readVoucher(rs));
            }
            fallbackVouchers = new ArrayList<>(list);
        } catch (Exception e) {
            System.err.println("Database fetch failed in VoucherDAO.getAll(), using fallback: " + e.getMessage());
            return getFallbackVouchers();
        }
        return list.isEmpty() ? getFallbackVouchers() : list;
    }

    public List<Voucher> getActive() {
        List<Voucher> active = new ArrayList<>();
        for (Voucher voucher : getAll()) {
            if (voucher.isActive()) {
                active.add(voucher);
            }
        }
        return active;
    }

    public Voucher getByCode(String code) {
        if (code == null) {
            return null;
        }
        ensureTable();
        String sql = "SELECT code, name, discountAmount, pointCost, active FROM dbo.Vouchers WHERE code = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, code.trim());
            try (ResultSet rs = st.executeQuery()) {
                if (rs.next()) {
                    return readVoucher(rs);
                }
            }
        } catch (Exception e) {
            System.err.println("Database fetch failed in VoucherDAO.getByCode(), searching fallback: " + e.getMessage());
        }
        for (Voucher voucher : getFallbackVouchers()) {
            if (voucher.getCode().equalsIgnoreCase(code.trim())) {
                return voucher;
            }
        }
        return null;
    }

    public void save(Voucher voucher) {
        ensureTable();
        String sql = "MERGE dbo.Vouchers AS target " +
                     "USING (SELECT ? AS code, ? AS name, ? AS discountAmount, ? AS pointCost, ? AS active) AS source " +
                     "ON target.code = source.code " +
                     "WHEN MATCHED THEN UPDATE SET name = source.name, discountAmount = source.discountAmount, pointCost = source.pointCost, active = source.active " +
                     "WHEN NOT MATCHED THEN INSERT (code, name, discountAmount, pointCost, active) VALUES (source.code, source.name, source.discountAmount, source.pointCost, source.active);";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, voucher.getCode());
            st.setString(2, voucher.getName());
            st.setInt(3, voucher.getDiscountAmount());
            st.setInt(4, voucher.getPointCost());
            st.setBoolean(5, voucher.isActive());
            st.executeUpdate();
        } catch (Exception e) {
            throw new IllegalStateException("Không thể lưu voucher: " + e.getMessage(), e);
        }
        saveFallback(voucher);
    }

    public void delete(String code) {
        ensureTable();
        String sql = "DELETE FROM dbo.Vouchers WHERE code = ?";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             PreparedStatement st = con.prepareStatement(sql)) {
            st.setString(1, code);
            st.executeUpdate();
        } catch (Exception e) {
            throw new IllegalStateException("Không thể xoá voucher: " + e.getMessage(), e);
        }
        getFallbackVouchers().removeIf(voucher -> voucher.getCode().equals(code));
    }

    private void ensureTable() {
        DBContext db = new DBContext();
        String sql = "IF OBJECT_ID('dbo.Vouchers', 'U') IS NULL " +
                     "CREATE TABLE dbo.Vouchers (" +
                     "code VARCHAR(50) PRIMARY KEY, " +
                     "name NVARCHAR(255) NOT NULL, " +
                     "discountAmount INT NOT NULL, " +
                     "pointCost INT NOT NULL, " +
                     "active BIT NOT NULL CONSTRAINT DF_Vouchers_active DEFAULT 1" +
                     ");";
        try (Connection con = db.getConnection();
             Statement st = con.createStatement()) {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("VoucherDAO.ensureTable skipped: " + e.getMessage());
        }
    }

    private void seedDefaultsIfEmpty() {
        String sql = "IF NOT EXISTS (SELECT 1 FROM dbo.Vouchers) " +
                     "INSERT INTO dbo.Vouchers (code, name, discountAmount, pointCost, active) VALUES " +
                     "('CAFE15', N'Voucher giảm 15,000đ', 15000, 100, 1), " +
                     "('CAFE30', N'Voucher giảm 30,000đ', 30000, 200, 1), " +
                     "('CAFE50', N'Voucher giảm 50,000đ', 50000, 300, 1), " +
                     "('CAFE100', N'Voucher giảm 100,000đ', 100000, 500, 1);";
        DBContext db = new DBContext();
        try (Connection con = db.getConnection();
             Statement st = con.createStatement()) {
            st.execute(sql);
        } catch (Exception e) {
            System.err.println("VoucherDAO.seedDefaultsIfEmpty skipped: " + e.getMessage());
        }
    }

    private Voucher readVoucher(ResultSet rs) throws Exception {
        return new Voucher(
                rs.getString("code"),
                rs.getString("name"),
                rs.getInt("discountAmount"),
                rs.getInt("pointCost"),
                rs.getBoolean("active")
        );
    }

    private List<Voucher> getFallbackVouchers() {
        if (fallbackVouchers == null || fallbackVouchers.isEmpty()) {
            fallbackVouchers = createDefaultVouchers();
        }
        return fallbackVouchers;
    }

    private List<Voucher> createDefaultVouchers() {
        List<Voucher> defaults = new ArrayList<>();
        defaults.add(new Voucher("CAFE15", "Voucher giảm 15,000đ", 15000, 100, true));
        defaults.add(new Voucher("CAFE30", "Voucher giảm 30,000đ", 30000, 200, true));
        defaults.add(new Voucher("CAFE50", "Voucher giảm 50,000đ", 50000, 300, true));
        defaults.add(new Voucher("CAFE100", "Voucher giảm 100,000đ", 100000, 500, true));
        return defaults;
    }

    private void saveFallback(Voucher voucher) {
        List<Voucher> current = getFallbackVouchers();
        int idx = -1;
        for (int i = 0; i < current.size(); i++) {
            if (current.get(i).getCode().equals(voucher.getCode())) {
                idx = i;
                break;
            }
        }
        if (idx >= 0) {
            current.set(idx, voucher);
        } else {
            current.add(voucher);
        }
    }
}
