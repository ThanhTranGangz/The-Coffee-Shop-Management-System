package model;

/**
 * Represents a historical financial report for a specific month and year.
 */
public class HistoricalReport {
    private int year;
    private int month;
    private long revenue;
    private long expenses;
    private long profit;
    private String status;

    /**
     * Default constructor.
     */
    public HistoricalReport() {}

    /**
     * Constructs a HistoricalReport with specified values.
     * 
     * @param year the year of the report
     * @param month the month of the report
     * @param revenue the total revenue
     * @param expenses the total expenses
     * @param profit the net profit
     * @param status the status of the report
     */
    public HistoricalReport(int year, int month, long revenue, long expenses, long profit, String status) {
        this.year = year;
        this.month = month;
        this.revenue = revenue;
        this.expenses = expenses;
        this.profit = profit;
        this.status = status;
    }

    public int getYear() { return year; }
    public void setYear(int year) { this.year = year; }

    public int getMonth() { return month; }
    public void setMonth(int month) { this.month = month; }

    public long getRevenue() { return revenue; }
    public void setRevenue(long revenue) { this.revenue = revenue; }

    public long getExpenses() { return expenses; }
    public void setExpenses(long expenses) { this.expenses = expenses; }

    public long getProfit() { return profit; }
    public void setProfit(long profit) { this.profit = profit; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
