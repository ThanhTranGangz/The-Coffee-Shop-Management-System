package model;

import java.util.ArrayList;
import java.util.List;

public class Member {
    private String phone;
    private String name;
    private String rank;
    private int points;
    private String email;
    private String pref;
    private String discount;
    private List<String> vouchers;

    public Member() {}

    public Member(String phone, String name, String rank, int points, String email, String pref, String discount) {
        this(phone, name, rank, points, email, pref, discount, new ArrayList<String>());
    }

    public Member(String phone, String name, String rank, int points, String email, String pref, String discount, List<String> vouchers) {
        this.phone = phone;
        this.name = name;
        this.rank = rank;
        this.points = points;
        this.email = email;
        this.pref = pref;
        this.discount = discount;
        this.vouchers = vouchers != null ? vouchers : new ArrayList<String>();
    }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getRank() { return rank; }
    public void setRank(String rank) { this.rank = rank; }

    public int getPoints() { return points; }
    public void setPoints(int points) { this.points = points; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPref() { return pref; }
    public void setPref(String pref) { this.pref = pref; }

    public String getDiscount() { return discount; }
    public void setDiscount(String discount) { this.discount = discount; }

    public List<String> getVouchers() { return vouchers; }
    public void setVouchers(List<String> vouchers) { this.vouchers = vouchers != null ? vouchers : new ArrayList<String>(); }
}
