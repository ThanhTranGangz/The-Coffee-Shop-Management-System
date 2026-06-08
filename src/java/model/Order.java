package model;

import java.sql.Timestamp;

public class Order {
    private int orderId;
    private Timestamp orderDate;
    private int totalAmount;
    private int discountAmount;
    private int finalAmount;
    private String paymentMethod;
    private String transactionId;
    private String orderSource;
    private String orderStatus;
    private String paymentStatus;
    private Integer tableId;
    private Integer cashierId;
    private Integer memberId;
    private Integer voucherId;

    public Order() {
    }

    public Order(int orderId, Timestamp orderDate, int totalAmount, int discountAmount, int finalAmount, 
                 String paymentMethod, String transactionId, String orderSource, String orderStatus, 
                 String paymentStatus, Integer tableId, Integer cashierId, Integer memberId, Integer voucherId) {
        this.orderId = orderId;
        this.orderDate = orderDate;
        this.totalAmount = totalAmount;
        this.discountAmount = discountAmount;
        this.finalAmount = finalAmount;
        this.paymentMethod = paymentMethod;
        this.transactionId = transactionId;
        this.orderSource = orderSource;
        this.orderStatus = orderStatus;
        this.paymentStatus = paymentStatus;
        this.tableId = tableId;
        this.cashierId = cashierId;
        this.memberId = memberId;
        this.voucherId = voucherId;
    }

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

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }

    public String getOrderSource() { return orderSource; }
    public void setOrderSource(String orderSource) { this.orderSource = orderSource; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public Integer getTableId() { return tableId; }
    public void setTableId(Integer tableId) { this.tableId = tableId; }

    public Integer getCashierId() { return cashierId; }
    public void setCashierId(Integer cashierId) { this.cashierId = cashierId; }

    public Integer getMemberId() { return memberId; }
    public void setMemberId(Integer memberId) { this.memberId = memberId; }

    public Integer getVoucherId() { return voucherId; }
    public void setVoucherId(Integer voucherId) { this.voucherId = voucherId; }
}
