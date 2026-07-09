import context.DBContext;
import java.sql.Connection;
import java.sql.Statement;

public class FixRecipes {
    public static void main(String[] args) {
        try {
            DBContext db = new DBContext();
            try (Connection con = db.getConnection(); Statement st = con.createStatement()) {
                st.execute("DELETE FROM dbo.RecipeItems");
                System.out.println("Cleared RecipeItems table.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
