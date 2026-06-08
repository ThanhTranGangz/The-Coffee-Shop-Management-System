package controller;

import dal.StaffDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Role;
import model.Staff;

@WebServlet(name = "StaffManagementServlet", urlPatterns = {"/staff-management"})
public class StaffManagementServlet extends HttpServlet {

    private final StaffDAO staffDAO = new StaffDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        Staff currentStaff = null;

        if (session != null) {
            currentStaff = (Staff) session.getAttribute("staff");
        }

        if (currentStaff == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        if (!canManageStaff(currentStaff)) {
            response.sendRedirect("dashboard.jsp");
            return;
        }

        List<Staff> staffList = staffDAO.getAllStaff();
        List<Role> roleList = staffDAO.getAllRoles();

        request.setAttribute("staffList", staffList);
        request.setAttribute("roleList", roleList);

        request.getRequestDispatcher("staff-management.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        Staff currentStaff = null;

        if (session != null) {
            currentStaff = (Staff) session.getAttribute("staff");
        }

        if (currentStaff == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        if (!canManageStaff(currentStaff)) {
            response.sendRedirect("dashboard.jsp");
            return;
        }

        String action = request.getParameter("action");

        if ("create".equals(action)) {
            createStaff(request);
        } else if ("deactivate".equals(action)) {
            deactivateStaff(request);
        } else if ("activate".equals(action)) {
            activateStaff(request);
        }

        response.sendRedirect("staff-management");
    }

    private void createStaff(HttpServletRequest request) {
        String username = request.getParameter("username");
        String fullName = request.getParameter("fullName");
        String password = request.getParameter("password");
        String pin = request.getParameter("pin");
        String roleIDRaw = request.getParameter("roleID");

        if (username == null || username.trim().isEmpty()) {
            return;
        }

        if (fullName == null || fullName.trim().isEmpty()) {
            return;
        }

        if (password == null || password.trim().isEmpty()) {
            return;
        }

        if (pin == null || !pin.matches("\\d{4}")) {
            return;
        }

        try {
            int roleID = Integer.parseInt(roleIDRaw);
            staffDAO.createStaff(username.trim(), password, pin, fullName.trim(), roleID);
        } catch (NumberFormatException e) {
            e.printStackTrace();
        }
    }

    private void deactivateStaff(HttpServletRequest request) {
        try {
            int staffID = Integer.parseInt(request.getParameter("staffID"));
            staffDAO.deactivateStaff(staffID);
        } catch (NumberFormatException e) {
            e.printStackTrace();
        }
    }

    private void activateStaff(HttpServletRequest request) {
        try {
            int staffID = Integer.parseInt(request.getParameter("staffID"));
            staffDAO.activateStaff(staffID);
        } catch (NumberFormatException e) {
            e.printStackTrace();
        }
    }

    private boolean canManageStaff(Staff staff) {
        if (staff == null) {
            return false;
        }

        if ("MANAGER".equalsIgnoreCase(staff.getRoleName())) {
            return true;
        }

        return staffDAO.hasPermission(staff.getStaffID(), "MANAGE_STAFF");
    }
}