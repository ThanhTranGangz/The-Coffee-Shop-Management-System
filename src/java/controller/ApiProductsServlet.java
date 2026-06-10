package controller;

import dal.ProductDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import model.Category;
import model.Member;
import model.MenuItem;
import model.Tables;
import util.ApiJson;
import util.AppConfig;
import util.JsonUtil;

/**
 * GET /api/products[?q=tu+khoa]
 * Tra ve danh muc + toan bo mon (kem trang thai con hang) + ngu canh phien
 * (ban dang ngoi, thanh vien dang dang nhap) de ve trang menu.
 */
@WebServlet(name = "ApiProductsServlet", urlPatterns = {"/api/products"})
public class ApiProductsServlet extends ApiServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        ProductDAO dao = new ProductDAO();
        List<Category> categories = dao.getCategories();
        List<MenuItem> products = dao.getMenu(request.getParameter("q"));

        Tables table = currentTable(request);
        Member member = currentMember(request);

        StringBuilder sb = new StringBuilder();
        sb.append("{\"ok\":true,\"shopName\":").append(JsonUtil.str(AppConfig.SHOP_NAME));

        if (table != null) {
            sb.append(",\"table\":{\"tableId\":").append(table.getTableId())
              .append(",\"tableName\":").append(JsonUtil.str(table.getTableName())).append('}');
        } else {
            sb.append(",\"table\":null");
        }

        sb.append(",\"member\":").append(ApiJson.member(member));

        sb.append(",\"categories\":[");
        for (int i = 0; i < categories.size(); i++) {
            Category c = categories.get(i);
            if (i > 0) {
                sb.append(',');
            }
            sb.append("{\"categoryId\":").append(c.getCategoryId())
              .append(",\"categoryName\":").append(JsonUtil.str(c.getCategoryName())).append('}');
        }
        sb.append("],\"products\":[");
        for (int i = 0; i < products.size(); i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append(ApiJson.menuItem(products.get(i)));
        }
        sb.append("]}");

        writeJson(response, 200, sb.toString());
    }
}
