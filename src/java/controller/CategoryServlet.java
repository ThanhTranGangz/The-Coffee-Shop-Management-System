package controller;

import dal.CategoryDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet(name = "CategoryServlet", urlPatterns = {"/category-management"})
public class CategoryServlet extends HttpServlet {

    private final CategoryDAO categoryDAO = new CategoryDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("staff") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String msg;
        switch (action == null ? "" : action) {
            case "create": {
                String name = req.getParameter("categoryName");
                msg = categoryDAO.createCategory(name)
                        ? "Thêm danh mục thành công!" : "Thêm thất bại.";
                break;
            }
            case "update": {
                int    id   = parseInt(req.getParameter("categoryId"));
                String name = req.getParameter("categoryName");
                msg = categoryDAO.updateCategory(id, name)
                        ? "Cập nhật danh mục thành công!" : "Cập nhật thất bại.";
                break;
            }
            case "delete": {
                int id = parseInt(req.getParameter("categoryId"));
                if (categoryDAO.hasProducts(id)) {
                    msg = "Không thể xóa danh mục đang có sản phẩm.";
                } else {
                    msg = categoryDAO.deleteCategory(id) ? "Xóa danh mục thành công!" : "Xóa thất bại.";
                }
                break;
            }
            default: msg = "Hành động không hợp lệ.";
        }
        resp.sendRedirect(req.getContextPath() + "/product-management?tab=categories&msg=" + enc(msg));
    }

    private int parseInt(String v) {
        try { return Integer.parseInt(v); } catch (Exception e) { return 0; }
    }

    private String enc(String s) {
        try { return java.net.URLEncoder.encode(s, "UTF-8"); } catch (Exception e) { return s; }
    }
}
