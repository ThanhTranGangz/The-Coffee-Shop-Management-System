package controller;

import dal.CategoryDAO;
import dal.ProductDAO;
import model.Category;
import model.Product;
import model.Staff;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "ProductServlet", urlPatterns = {"/product-management"})
public class ProductServlet extends HttpServlet {

    private final ProductDAO  productDAO  = new ProductDAO();
    private final CategoryDAO categoryDAO = new CategoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!checkAuth(req, resp)) return;

        String keyword    = req.getParameter("keyword");
        int    categoryId = parseInt(req.getParameter("categoryId"), 0);

        List<Product> products = (keyword != null && !keyword.isEmpty()) || categoryId > 0
                ? productDAO.searchProducts(keyword, categoryId)
                : productDAO.getAllProducts();

        req.setAttribute("products",          products);
        req.setAttribute("categories",        categoryDAO.getAllCategories());
        req.setAttribute("keyword",           keyword == null ? "" : keyword);
        req.setAttribute("selectedCategory",  categoryId);
        setMsg(req);

        req.getRequestDispatcher("/view/admin/product-management.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!checkAuth(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String msg;
        switch (action == null ? "" : action) {
            case "create": msg = handleCreate(req); break;
            case "update": msg = handleUpdate(req); break;
            case "toggle": msg = handleToggle(req); break;
            case "delete": msg = handleDelete(req); break;
            default:       msg = "Hành động không hợp lệ.";
        }
        resp.sendRedirect(req.getContextPath() + "/product-management?msg=" + enc(msg));
    }

    // ── handlers ────────────────────────────────────────────────────────────

    private String handleCreate(HttpServletRequest req) {
        try {
            return productDAO.createProduct(buildProduct(req))
                    ? "Thêm sản phẩm thành công!" : "Thêm sản phẩm thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    private String handleUpdate(HttpServletRequest req) {
        try {
            Product p = buildProduct(req);
            p.setProductId(parseInt(req.getParameter("productId"), 0));
            return productDAO.updateProduct(p) ? "Cập nhật thành công!" : "Cập nhật thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    private String handleToggle(HttpServletRequest req) {
        try {
            int id = parseInt(req.getParameter("productId"), 0);
            return productDAO.toggleProductStatus(id) ? "Đã chuyển trạng thái." : "Thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    private String handleDelete(HttpServletRequest req) {
        try {
            int id = parseInt(req.getParameter("productId"), 0);
            if (productDAO.hasOrderDetails(id))
                return "Không thể xóa — sản phẩm đã có trong đơn hàng. Hãy dùng 'Ẩn sản phẩm'.";
            return productDAO.deleteProduct(id) ? "Xóa thành công!" : "Xóa thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    // ── helpers ─────────────────────────────────────────────────────────────

    private Product buildProduct(HttpServletRequest req) {
        Product p = new Product();
        p.setProductName(req.getParameter("productName").trim());
        p.setPrice(parseInt(req.getParameter("price"), 0));
        p.setImageUrl(req.getParameter("imageUrl"));
        p.setCategoryId(parseInt(req.getParameter("categoryId"), 0));
        p.setStatus(!"0".equals(req.getParameter("status")));
        return p;
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

    private int parseInt(String v, int def) {
        try { return Integer.parseInt(v); } catch (Exception e) { return def; }
    }

    private String enc(String s) {
        try { return java.net.URLEncoder.encode(s, "UTF-8"); } catch (Exception e) { return s; }
    }
}
