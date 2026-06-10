package util;

import dal.ProductDAO;
import dal.VoucherDAO;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import model.CartLine;
import model.Member;
import model.MenuItem;
import model.PriceQuote;
import model.Voucher;

/**
 * Tinh tam tinh cho gio hang: gia luon lay tu DB (khong tin gia client gui len),
 * cong don giam gia hang thanh vien + voucher, khong vuot qua tien hang.
 */
public class PricingService {

    public static final int MAX_QTY_PER_LINE = 20;

    /**
     * @param lines       gio hang khach gui len
     * @param member      thanh vien dang dang nhap (null neu la khach vang lai)
     * @param voucherCode ma uu dai khach nhap (co the null/rong)
     */
    public PriceQuote quote(List<CartLine> lines, Member member, String voucherCode) {
        PriceQuote quote = new PriceQuote();

        List<Integer> ids = new ArrayList<>();
        for (CartLine line : lines) {
            if (!ids.contains(line.getProductId())) {
                ids.add(line.getProductId());
            }
        }
        Map<Integer, MenuItem> products = new ProductDAO().findByIds(ids);

        int subtotal = 0;
        for (CartLine line : lines) {
            MenuItem p = products.get(line.getProductId());
            if (p == null) {
                continue; // mon khong ton tai -> bo qua dong nay
            }
            int qty = Math.max(1, Math.min(line.getQuantity(), MAX_QTY_PER_LINE));

            PriceQuote.QuoteLine ql = new PriceQuote.QuoteLine();
            ql.setProductId(p.getProductId());
            ql.setProductName(p.getProductName());
            ql.setUnitPrice(p.getPrice());
            ql.setQuantity(qty);
            ql.setLineTotal(p.getPrice() * qty);
            ql.setAvailable(p.isAvailable());
            ql.setNote(line.getNote());
            quote.getLines().add(ql);

            if (p.isAvailable()) {
                subtotal += ql.getLineTotal();
            } else {
                quote.setAllAvailable(false);
            }
        }
        quote.setSubtotal(subtotal);

        // 1. Giam gia theo hang thanh vien (Bronze 0% / Silver 5% / Gold 10%)
        if (member != null && member.getTierDiscountPercent() > 0) {
            quote.setMemberDiscountPercent(member.getTierDiscountPercent());
            quote.setMemberDiscount((int) ((long) subtotal * member.getTierDiscountPercent() / 100));
        }

        // 2. Voucher ap dung tren phan con lai sau giam gia thanh vien
        if (voucherCode != null && !voucherCode.trim().isEmpty()) {
            String code = voucherCode.trim().toUpperCase();
            quote.setVoucherCode(code);
            int tierId = member != null ? member.getTierID() : 0;
            VoucherDAO voucherDAO = new VoucherDAO();
            Voucher v = voucherDAO.findValidVoucher(code, tierId);
            if (v == null) {
                quote.setVoucherValid(false);
                quote.setVoucherMessage(member == null
                        ? "Mã không hợp lệ, đã hết hạn hoặc chỉ dành cho thành viên."
                        : "Mã không hợp lệ, đã hết hạn hoặc cần hạng thành viên cao hơn.");
            } else {
                int remaining = subtotal - quote.getMemberDiscount();
                quote.setVoucherValid(true);
                quote.setVoucherId(v.getVoucherID());
                quote.setVoucherDiscount(voucherDAO.calculateDiscount(remaining, v));
                quote.setVoucherMessage(v.getDiscountPercent() != null
                        ? "Giảm " + v.getDiscountPercent() + "% cho đơn này."
                        : "Giảm " + String.format("%,d", v.getDiscountAmount()).replace(',', '.') + "đ cho đơn này.");
            }
        }

        int total = subtotal - quote.getMemberDiscount() - quote.getVoucherDiscount();
        quote.setTotal(Math.max(0, total));
        quote.setPointsEarn(member != null ? AppConfig.pointsForAmount(quote.getTotal()) : 0);
        return quote;
    }
}
