package model;

public class Member {
    private int memberId;
    private String fullName;
    private String phone;
    private int rewardPoints;
    private int tierId;
    private boolean isActive;

    public Member() {
    }

    public Member(int memberId, String fullName, String phone, int rewardPoints, int tierId, boolean isActive) {
        this.memberId = memberId;
        this.fullName = fullName;
        this.phone = phone;
        this.rewardPoints = rewardPoints;
        this.tierId = tierId;
        this.isActive = isActive;
    }

    public int getMemberId() {
        return memberId;
    }

    public void setMemberId(int memberId) {
        this.memberId = memberId;
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

    public int getTierId() {
        return tierId;
    }

    public void setTierId(int tierId) {
        this.tierId = tierId;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    @Override
    public String toString() {
        return "Member{" +
                "memberId=" + memberId +
                ", fullName='" + fullName + '\'' +
                ", phone='" + phone + '\'' +
                ", rewardPoints=" + rewardPoints +
                ", tierId=" + tierId +
                ", isActive=" + isActive +
                '}';
    }
}
