package model;

public class Tables {
    private int tableId;
    private String tableName;
    private String status;

    public Tables() {
    }

    public Tables(int tableId, String tableName, String status) {
        this.tableId = tableId;
        this.tableName = tableName;
        this.status = status;
    }

    public int getTableId() { return tableId; }
    public void setTableId(int tableId) { this.tableId = tableId; }

    public String getTableName() { return tableName; }
    public void setTableName(String tableName) { this.tableName = tableName; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
