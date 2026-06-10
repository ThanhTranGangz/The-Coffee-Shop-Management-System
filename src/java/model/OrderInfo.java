package model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * Don hang day du thong tin de hien thi (ten ban, ten thanh vien, chi tiet mon).
 */
public class OrderInfo {

    private int orderId;
    private Timestamp orderDate;
    private int totalAmount;
    private int discountAmount;
    private int finalAmount;
    private String paymentMethod;
    private String orderSource;
    private String orderStatus;
    private String paymentStatus;
    private Integer tableId;
    private String tableName;
    private Integer memberId;
    private String memberName;
    private List<OrderItemInfo> items = new ArrayList<>();

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public Timestamp getOrderDate() { return orderDate; }
    public void setOrderDate(Timestamp orderDate) { this.orderDate = orderDate; }

    public int getTotalAmount() { return totalAmount; }
    public void setTotalAmount(int totalAmount) { this.totalAmount = totalAmount; }

    public int getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(int discountAmount) { this.discountAmount = discountAmount; }

    public int getFinalAmount() { return finalAmount; }
    public void setFinalAmount(int finalAmount) { this.finalAmount = finalAmount; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getOrderSource() { return orderSource; }
    public void setOrderSource(String orderSource) { this.orderSource = orderSource; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public Integer getTableId() { return tableId; }
    public void setTableId(Integer tableId) { this.tableId = tableId; }

    public String getTableName() { return tableName; }
    public void setTableName(String tableName) { this.tableName = tableName; }

    public Integer getMemberId() { return memberId; }
    public void setMemberId(Integer memberId) { this.memberId = memberId; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }

    public List<OrderItemInfo> getItems() { return items; }
    public void setItems(List<OrderItemInfo> items) { this.items = items; }
}
