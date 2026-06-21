package context;

import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Standard DBContext class for MS SQL Server JDBC connection management.
 * Suitable for FPT University standard Java Servlet projects (SWT301/SWP391).
 */
public class DBContext {
    
    // ==========================================
    // DATABASE CONNECTION CONFIGURATION PARAMETERS
    // ==========================================
    private final String serverName = "localhost";
    private final String dbName = "ArtisanBrew";
    private final String portNumber = "1433";
    private final String userID = "sa";       // Default username is 'sa'
    private final String password = "123";    // Default password

    /**
     * Obtains a Connection object connected to the MS SQL Server instance.
     * Includes modern fallback parameters (encrypt=true;trustServerCertificate=true)
     * to eliminate security policy negotiation crashes standard with newer JDBC drivers.
     * 
     * @return DB connection
     * @throws Exception connection error
     */
    public Connection getConnection() throws Exception {
        String url = "jdbc:sqlserver://" + serverName + ":" + portNumber 
                + ";databaseName=" + dbName 
                + ";encrypt=true;trustServerCertificate=true";
        
        // Load SQL Server Driver
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        
        return DriverManager.getConnection(url, userID, password);
    }

    /**
     * Main self-contained test execution environment helper.
     * Users can run this file directly in NetBeans to verify their connection.
     */
    public static void main(String[] args) {
        try {
            DBContext db = new DBContext();
            System.out.println("Attempting database handshake connection...");
            try (Connection con = db.getConnection()) {
                if (con != null) {
                    System.out.println("=================================================");
                    System.out.println(" SUCCESS: Database connection established!");
                    System.out.println(" Database Catalog Name: " + con.getCatalog());
                    System.out.println("=================================================");
                } else {
                    System.err.println(" FAILURE: Connection returned null.");
                }
            }
        } catch (Exception e) {
            System.err.println("=================================================");
            System.err.println(" DB Handshake FAILED!");
            System.err.println(" Critical Exception trace:");
            e.printStackTrace();
            System.err.println("=================================================");
        }
    }
}
