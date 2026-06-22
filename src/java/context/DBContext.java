package context;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Properties;

/**
 * Standard DBContext class for MS SQL Server JDBC connection management.
 * Suitable for FPT University standard Java Servlet projects (SWT301/SWP391).
 */
public class DBContext {
    
    // ==========================================
    // DATABASE CONNECTION CONFIGURATION PARAMETERS
    // ==========================================
    private String serverName;
    private String dbName;
    private String portNumber;
    private String userID;
    private String password;

    public DBContext() {
        loadProperties();
    }

    private void loadProperties() {
        try (InputStream input = getClass().getClassLoader().getResourceAsStream("db.properties")) {
            Properties prop = new Properties();
            if (input == null) {
                System.out.println("Sorry, unable to find db.properties. Falling back to default values.");
                this.serverName = "localhost";
                this.dbName = "ArtisanBrew";
                this.portNumber = "1433";
                this.userID = "sa";
                this.password = "123";
                return;
            }

            prop.load(input);
            this.serverName = prop.getProperty("db.serverName", "localhost");
            this.dbName = prop.getProperty("db.dbName", "ArtisanBrew");
            this.portNumber = prop.getProperty("db.portNumber", "1433");
            this.userID = prop.getProperty("db.userID", "sa");
            this.password = prop.getProperty("db.password", "123");

        } catch (Exception ex) {
            ex.printStackTrace();
            this.serverName = "localhost";
            this.dbName = "ArtisanBrew";
            this.portNumber = "1433";
            this.userID = "sa";
            this.password = "123";
        }
    }

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
                + ";encrypt=true;trustServerCertificate=true"
                + ";loginTimeout=3;connectRetryCount=0;socketTimeout=5000";
        
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        DriverManager.setLoginTimeout(3);
        
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
