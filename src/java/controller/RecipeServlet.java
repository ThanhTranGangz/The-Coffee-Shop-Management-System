package controller;

import dal.CategoryDAO;
import dal.InventoryDAO;
import dal.ProductDAO;
import dal.RecipeDAO;
import model.Inventory;
import model.Product;
import model.Recipe;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet(name = "RecipeServlet", urlPatterns = {"/recipe-management"})
public class RecipeServlet extends HttpServlet {

    private final RecipeDAO    recipeDAO    = new RecipeDAO();
    private final ProductDAO   productDAO   = new ProductDAO();
    private final InventoryDAO inventoryDAO = new InventoryDAO();
    private final CategoryDAO  categoryDAO  = new CategoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!checkAuth(req, resp)) return;

        req.setAttribute("products",    productDAO.getAllProducts());
        req.setAttribute("ingredients", inventoryDAO.getAllIngredients());
        req.setAttribute("categories",  categoryDAO.getAllCategories());

        String pidParam = req.getParameter("productId");
        if (pidParam != null) {
            try {
                int pid = Integer.parseInt(pidParam);
                req.setAttribute("selectedProductId", pid);
                req.setAttribute("selectedProduct",   productDAO.getProductById(pid));
                req.setAttribute("currentRecipe",     recipeDAO.getRecipeByProduct(pid));
            } catch (NumberFormatException ignored) { }
        }
        setMsg(req);
        req.getRequestDispatcher("/view/admin/recipe-management.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!checkAuth(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String msg = "save".equals(req.getParameter("action"))
                ? handleSave(req) : "Hành động không hợp lệ.";

        String pid = req.getParameter("productId");
        String url = req.getContextPath() + "/recipe-management?msg=" + enc(msg);
        if (pid != null) url += "&productId=" + pid;
        resp.sendRedirect(url);
    }

    private String handleSave(HttpServletRequest req) {
        try {
            int productId = Integer.parseInt(req.getParameter("productId"));
            String[] ids  = req.getParameterValues("ingredientId[]");
            String[] qtys = req.getParameterValues("quantityNeeded[]");

            List<Recipe> list = new ArrayList<>();
            if (ids != null && qtys != null) {
                for (int i = 0; i < ids.length; i++) {
                    int    ingId = Integer.parseInt(ids[i].trim());
                    double qty   = Double.parseDouble(qtys[i].trim());
                    if (ingId > 0 && qty > 0) list.add(new Recipe(productId, ingId, qty));
                }
            }
            return recipeDAO.saveRecipe(productId, list)
                    ? "Lưu công thức thành công!" : "Lưu thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    private boolean checkAuth(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("staff") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return false;
        }
        return true;
    }

    private void setMsg(HttpServletRequest req) {
        String m = req.getParameter("msg");
        if (m != null) req.setAttribute("msg", m);
    }

    private String enc(String s) {
        try { return java.net.URLEncoder.encode(s, "UTF-8"); } catch (Exception e) { return s; }
    }
}
