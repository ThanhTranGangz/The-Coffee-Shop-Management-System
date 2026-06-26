package model;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents a loyalty member of the coffee shop.
 */
public class Member {
    private String phone;
    private String name;
    private String rank;
    private int points;
    private String email;
    private String pref;
    private String discount;
    private List<String> vouchers;

    /**
     * Default constructor.
     */
    public Member() {}

    /**
     * Constructs a Member with basic information, initializing an empty voucher list.
     * 
     * @param phone the member's phone number
     * @param name the member's name
     * @param rank the member's loyalty rank
     * @param points the accumulated points
     * @param email the member's email address
     * @param pref the member's preferences
     * @param discount the applicable discount
     */
    public Member(String phone, String name, String rank, int points, String email, String pref, String discount) {
        this(phone, name, rank, points, email, pref, discount, new ArrayList<String>());
    }

    /**
     * Constructs a Member with full information, including their vouchers.
     * 
     * @param phone the member's phone number
     * @param name the member's name
     * @param rank the member's loyalty rank
     * @param points the accumulated points
     * @param email the member's email address
     * @param pref the member's preferences
     * @param discount the applicable discount
     * @param vouchers a list of voucher codes owned by the member
     */
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
