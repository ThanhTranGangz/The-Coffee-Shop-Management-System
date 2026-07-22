package service;

import context.DBContext;

public class TestRunner {
    public static void main(String[] args) {
        try {
            System.out.println("Starting LiteService to trigger DB migrations...");
            LiteService service = LiteService.getInstance();
            System.out.println("Migrations completed successfully!");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
