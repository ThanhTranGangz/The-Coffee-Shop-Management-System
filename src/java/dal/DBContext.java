package dal;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBContext {

    protected Connection connection;

    public DBContext() {
        try {
            Properties properties = new Properties();

            InputStream inputStream = Thread.currentThread()
                    .getContextClassLoader()
                    .getResourceAsStream("ConnectDB.properties");

            if (inputStream == null) {
                throw new RuntimeException("Không tìm thấy ConnectDB.properties trong Source Packages");
            }

            properties.load(inputStream);

            String user = properties.getProperty("userID");
            String pass = properties.getProperty("password");
            String url = properties.getProperty("url");

            if (user == null || pass == null || url == null) {
                throw new RuntimeException("ConnectDB.properties thiếu userID, password hoặc url");
            }

            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            connection = DriverManager.getConnection(url, user, pass);

            System.out.println("Connect database successfully!");

        } catch (ClassNotFoundException e) {
            throw new RuntimeException("Chưa add SQL Server JDBC Driver vào project", e);
        } catch (SQLException e) {
            throw new RuntimeException("Kết nối SQL Server thất bại. Kiểm tra url, user, password, database.", e);
        } catch (IOException e) {
            throw new RuntimeException("Không đọc được ConnectDB.properties", e);
        }
    }
}