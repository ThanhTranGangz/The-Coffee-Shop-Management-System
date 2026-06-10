package model;

public class Member {

    private int memberID;
    private String fullName;
    private String phone;
    private int rewardPoints;
    private int tierID;
    private String tierName;
    private int tierDiscountPercent;
    private boolean active;

    public Member() {
    }

    public Member(int memberID, String fullName, String phone, int rewardPoints,
                  int tierID, String tierName, boolean active) {
        this.memberID = memberID;
        this.fullName = fullName;
        this.phone = phone;
        this.rewardPoints = rewardPoints;
        this.tierID = tierID;
        this.tierName = tierName;
        this.active = active;
    }

    public int getMemberID() {
        return memberID;
    }

    public void setMemberID(int memberID) {
        this.memberID = memberID;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public int getRewardPoints() {
        return rewardPoints;
    }

    public void setRewardPoints(int rewardPoints) {
        this.rewardPoints = rewardPoints;
    }

    public int getTierID() {
        return tierID;
    }

    public void setTierID(int tierID) {
        this.tierID = tierID;
    }

    public String getTierName() {
        return tierName;
    }

    public void setTierName(String tierName) {
        this.tierName = tierName;
    }

    public int getTierDiscountPercent() {
        return tierDiscountPercent;
    }

    public void setTierDiscountPercent(int tierDiscountPercent) {
        this.tierDiscountPercent = tierDiscountPercent;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}