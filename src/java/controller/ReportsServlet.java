package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import util.AuthUtil;
import util.Permission;

@WebServlet(name = "ReportsServlet", urlPatterns = {"/staff/reports"})
public class ReportsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        if (AuthUtil.currentStaff(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        if (!AuthUtil.hasPermission(request, Permission.VIEW_REPORT) && !"MANAGER".equalsIgnoreCase(AuthUtil.currentStaff(request).getRoleName())) {
            response.sendRedirect(request.getContextPath() + "/dashboard.jsp?denied=1");
            return;
        }
        
        request.getRequestDispatcher("/reports.jsp").forward(request, response);
    }
}
