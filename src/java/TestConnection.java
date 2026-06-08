import dal.DBContext;

public class TestConnection extends DBContext {

    public static void main(String[] args) {
        TestConnection test = new TestConnection();

        if (test.connection != null) {
            System.out.println("Connect to CSMS_DB successfully!");
        } else {
            System.out.println("Connect to CSMS_DB failed!");
        }
    }
}