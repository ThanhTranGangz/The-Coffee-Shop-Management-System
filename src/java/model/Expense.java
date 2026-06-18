package model;

public class Expense {
    private String id;
    private int amount;
    private String details;
    private String timestamp;

    public Expense() {}

    public Expense(String id, int amount, String details, String timestamp) {
        this.id = id;
        this.amount = amount;
        this.details = details;
        this.timestamp = timestamp;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public int getAmount() { return amount; }
    public void setAmount(int amount) { this.amount = amount; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
}
