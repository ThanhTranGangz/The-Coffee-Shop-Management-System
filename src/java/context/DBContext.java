package context;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class DBContext {
    private static final String SERVER = "localhost";
    private static final String PORT = "1433";
    private static final String DATABASE = "CoffeeShopLite";
    private static final String USER = "sa";
    private static final String PASSWORD = "123";
    private static boolean databaseReady = false;

    public Connection getConnection() throws Exception {
        ensureDatabase();
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        DriverManager.setLoginTimeout(4);
        String url = "jdbc:sqlserver://" + SERVER + ":" + PORT
                + ";databaseName=" + DATABASE
                + ";encrypt=true;trustServerCertificate=true"
                + ";loginTimeout=4;socketTimeout=8000";
        return DriverManager.getConnection(url, USER, PASSWORD);
    }

    private static synchronized void ensureDatabase() throws Exception {
        if (databaseReady) {
            return;
        }
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        String url = "jdbc:sqlserver://" + SERVER + ":" + PORT
                + ";databaseName=master"
                + ";encrypt=true;trustServerCertificate=true"
                + ";loginTimeout=4;socketTimeout=8000";
        try (Connection con = DriverManager.getConnection(url, USER, PASSWORD);
             Statement st = con.createStatement()) {
            st.execute("IF DB_ID(N'" + DATABASE + "') IS NULL CREATE DATABASE " + DATABASE);
        }
        databaseReady = true;
    }

    public static void main(String[] args) {
        try (Connection con = new DBContext().getConnection()) {
            System.out.println("Connected to " + con.getCatalog());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
