package model;

public class MemberTierStats {
    private String tierName;
    private int memberCount;

    public MemberTierStats() {}

    public MemberTierStats(String tierName, int memberCount) {
        this.tierName = tierName;
        this.memberCount = memberCount;
    }

    public String getTierName() {
        return tierName;
    }

    public void setTierName(String tierName) {
        this.tierName = tierName;
    }

    public int getMemberCount() {
        return memberCount;
    }

    public void setMemberCount(int memberCount) {
        this.memberCount = memberCount;
    }
}
