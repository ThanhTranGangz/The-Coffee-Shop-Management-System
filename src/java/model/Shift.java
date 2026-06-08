package model;

import java.sql.Timestamp;

public class Shift {
    private int shiftId;
    private Timestamp startTime;
    private Timestamp endTime;
    private int startingCash;
    private Integer actualCash;
    private Integer systemCalculatedCash;
    private int cashierId;

    public Shift() {
    }

    public Shift(int shiftId, Timestamp startTime, Timestamp endTime, int startingCash, Integer actualCash, Integer systemCalculatedCash, int cashierId) {
        this.shiftId = shiftId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.startingCash = startingCash;
        this.actualCash = actualCash;
        this.systemCalculatedCash = systemCalculatedCash;
        this.cashierId = cashierId;
    }

    public int getShiftId() { return shiftId; }
    public void setShiftId(int shiftId) { this.shiftId = shiftId; }

    public Timestamp getStartTime() { return startTime; }
    public void setStartTime(Timestamp startTime) { this.startTime = startTime; }

    public Timestamp getEndTime() { return endTime; }
    public void setEndTime(Timestamp endTime) { this.endTime = endTime; }

    public int getStartingCash() { return startingCash; }
    public void setStartingCash(int startingCash) { this.startingCash = startingCash; }

    public Integer getActualCash() { return actualCash; }
    public void setActualCash(Integer actualCash) { this.actualCash = actualCash; }

    public Integer getSystemCalculatedCash() { return systemCalculatedCash; }
    public void setSystemCalculatedCash(Integer systemCalculatedCash) { this.systemCalculatedCash = systemCalculatedCash; }

    public int getCashierId() { return cashierId; }
    public void setCashierId(int cashierId) { this.cashierId = cashierId; }
}
