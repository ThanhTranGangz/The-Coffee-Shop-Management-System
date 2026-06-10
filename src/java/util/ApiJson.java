package util;

import java.text.SimpleDateFormat;
import java.util.List;
import model.Member;
import model.MenuItem;
import model.OrderInfo;
import model.OrderItemInfo;
import model.PriceQuote;
import model.Voucher;

import static util.JsonUtil.str;

/**
 * Chuyen cac model sang chuoi JSON cho cac API (tu viet, khong dung lib ngoai).
 */
public final class ApiJson {

    private ApiJson() {
    }

    public static String menuItem(MenuItem m) {
        return "{"
                + "\"productId\":" + m.getProductId()
                + ",\"name\":" + str(m.getProductName())
                + ",\"price\":" + m.getPrice()
                + ",\"image\":" + str(m.getImageUrl())
                + ",\"categoryId\":" + m.getCategoryId()
                + ",\"categoryName\":" + str(m.getCategoryName())
                + ",\"available\":" + m.isAvailable()
                + "}";
    }

    public static String member(Member m) {
        if (m == null) {
            return "null";
        }
        return "{"
                + "\"memberId\":" + m.getMemberID()
                + ",\"fullName\":" + str(m.getFullName())
                + ",\"phone\":" + str(m.getPhone())
                + ",\"points\":" + m.getRewardPoints()
                + ",\"tierId\":" + m.getTierID()
                + ",\"tierName\":" + str(m.getTierName())
                + ",\"tierDiscountPercent\":" + m.getTierDiscountPercent()
                + "}";
    }

    public static String voucher(Voucher v) {
        SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy");
        return "{"
                + "\"code\":" + str(v.getVoucherCode())
                + ",\"discountAmount\":" + (v.getDiscountAmount() == null ? "null" : v.getDiscountAmount())
                + ",\"discountPercent\":" + (v.getDiscountPercent() == null ? "null" : v.getDiscountPercent())
                + ",\"memberOnly\":" + (v.getMinTierRequired() != null)
                + ",\"expiry\":" + str(v.getExpiryDate() == null ? null : df.format(v.getExpiryDate()))
                + "}";
    }

    public static String vouchers(List<Voucher> list) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append(voucher(list.get(i)));
        }
        return sb.append(']').toString();
    }

    public static String quote(PriceQuote q) {
        StringBuilder sb = new StringBuilder("{\"lines\":[");
        for (int i = 0; i < q.getLines().size(); i++) {
            PriceQuote.QuoteLine l = q.getLines().get(i);
            if (i > 0) {
                sb.append(',');
            }
            sb.append("{\"productId\":").append(l.getProductId())
              .append(",\"name\":").append(str(l.getProductName()))
              .append(",\"unitPrice\":").append(l.getUnitPrice())
              .append(",\"quantity\":").append(l.getQuantity())
              .append(",\"lineTotal\":").append(l.getLineTotal())
              .append(",\"available\":").append(l.isAvailable())
              .append(",\"note\":").append(str(l.getNote()))
              .append('}');
        }
        sb.append("],\"subtotal\":").append(q.getSubtotal())
          .append(",\"memberDiscountPercent\":").append(q.getMemberDiscountPercent())
          .append(",\"memberDiscount\":").append(q.getMemberDiscount())
          .append(",\"voucherCode\":").append(str(q.getVoucherCode()))
          .append(",\"voucherValid\":").append(q.isVoucherValid())
          .append(",\"voucherMessage\":").append(str(q.getVoucherMessage()))
          .append(",\"voucherDiscount\":").append(q.getVoucherDiscount())
          .append(",\"discountTotal\":").append(q.getDiscountTotal())
          .append(",\"total\":").append(q.getTotal())
          .append(",\"pointsEarn\":").append(q.getPointsEarn())
          .append(",\"allAvailable\":").append(q.isAllAvailable())
          .append('}');
        return sb.toString();
    }

    public static String orderInfo(OrderInfo o) {
        SimpleDateFormat tf = new SimpleDateFormat("HH:mm");
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"orderId\":").append(o.getOrderId())
          .append(",\"time\":").append(str(o.getOrderDate() == null ? null : tf.format(o.getOrderDate())))
          .append(",\"orderStatus\":").append(str(o.getOrderStatus()))
          .append(",\"paymentStatus\":").append(str(o.getPaymentStatus()))
          .append(",\"paymentMethod\":").append(str(o.getPaymentMethod()))
          .append(",\"tableName\":").append(str(o.getTableName()))
          .append(",\"memberName\":").append(str(o.getMemberName()))
          .append(",\"totalAmount\":").append(o.getTotalAmount())
          .append(",\"discountAmount\":").append(o.getDiscountAmount())
          .append(",\"finalAmount\":").append(o.getFinalAmount())
          .append(",\"items\":[");
        List<OrderItemInfo> items = o.getItems();
        for (int i = 0; i < items.size(); i++) {
            OrderItemInfo it = items.get(i);
            if (i > 0) {
                sb.append(',');
            }
            sb.append("{\"name\":").append(str(it.getProductName()))
              .append(",\"quantity\":").append(it.getQuantity())
              .append(",\"unitPrice\":").append(it.getUnitPrice())
              .append(",\"subtotal\":").append(it.getSubtotal())
              .append(",\"note\":").append(str(it.getNote()))
              .append(",\"itemStatus\":").append(str(it.getItemStatus()))
              .append('}');
        }
        sb.append("]}");
        return sb.toString();
    }

    /** Don hang rut gon (lich su thanh vien, khong kem chi tiet mon). */
    public static String orderBrief(OrderInfo o) {
        SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        return "{"
                + "\"orderId\":" + o.getOrderId()
                + ",\"date\":" + str(o.getOrderDate() == null ? null : df.format(o.getOrderDate()))
                + ",\"orderStatus\":" + str(o.getOrderStatus())
                + ",\"paymentStatus\":" + str(o.getPaymentStatus())
                + ",\"paymentMethod\":" + str(o.getPaymentMethod())
                + ",\"tableName\":" + str(o.getTableName())
                + ",\"finalAmount\":" + o.getFinalAmount()
                + ",\"discountAmount\":" + o.getDiscountAmount()
                + "}";
    }
}
