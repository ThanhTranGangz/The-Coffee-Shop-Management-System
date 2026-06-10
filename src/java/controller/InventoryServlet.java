package controller;

import dal.InventoryDAO;
import model.Inventory;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "InventoryServlet", urlPatterns = {"/inventory-management"})
public class InventoryServlet extends HttpServlet {

    private final InventoryDAO inventoryDAO = new InventoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!checkAuth(req, resp)) return;

        List<Inventory> ingredients = inventoryDAO.getAllIngredients();
        List<Inventory> lowStock    = inventoryDAO.getLowStockIngredients();

        req.setAttribute("ingredients",   ingredients);
        req.setAttribute("lowStockList",  lowStock);
        req.setAttribute("lowStockCount", lowStock.size());
        setMsg(req);

        req.getRequestDispatcher("/view/admin/inventory-management.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!checkAuth(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String msg;
        switch (action == null ? "" : action) {
            case "create":  msg = handleCreate(req);  break;
            case "update":  msg = handleUpdate(req);  break;
            case "restock": msg = handleRestock(req); break;
            default:        msg = "Hành động không hợp lệ.";
        }
        resp.sendRedirect(req.getContextPath() + "/inventory-management?msg=" + enc(msg));
    }

    private String handleCreate(HttpServletRequest req) {
        try {
            Inventory i = new Inventory();
            i.setIngredientName(req.getParameter("ingredientName").trim());
            i.setStockQuantity(Double.parseDouble(req.getParameter("stockQuantity")));
            i.setMinStockLevel(Double.parseDouble(req.getParameter("minStockLevel")));
            i.setUnit(req.getParameter("unit").trim());
            return inventoryDAO.createIngredient(i) ? "Thêm nguyên liệu thành công!" : "Thêm thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    private String handleUpdate(HttpServletRequest req) {
        try {
            Inventory i = new Inventory();
            i.setIngredientId(Integer.parseInt(req.getParameter("ingredientId")));
            i.setIngredientName(req.getParameter("ingredientName").trim());
            i.setMinStockLevel(Double.parseDouble(req.getParameter("minStockLevel")));
            i.setUnit(req.getParameter("unit").trim());
            return inventoryDAO.updateIngredient(i) ? "Cập nhật thành công!" : "Cập nhật thất bại.";
        } catch (Exception e) { return "Lỗi: " + e.getMessage(); }
    }

    private String handleRestock(HttpServletRequest req) {
        try {
            int    id  = Integer.parseInt(req.getParameter("ingredientId"));
            double qty = Double.parseDouble(req.getParameter("quantity"));
            if (qty <= 0) return "Số lượng nhập phải lớn hơn 0.";
            return inventoryDAO.restockIngredient(id, qty) ? "Nhập kho thành công!" : "Nhập kho thất bại.";
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
