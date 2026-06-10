import java.sql.*;
public class DbTest {
  public static void main(String[] a) throws Exception {
    String url="jdbc:sqlserver://localhost:1433;databaseName=CSMS_DB;trustServerCertificate=true";
    try {
      Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
      Connection c=DriverManager.getConnection(url,"sa","123");
      System.out.println("CONNECT OK");
      c.close();
    } catch(Throwable t){ System.out.println("CONNECT FAIL: "+t.getClass().getName()+": "+t.getMessage()); }
  }
}
