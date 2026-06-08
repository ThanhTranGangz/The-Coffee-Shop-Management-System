package controller;

import dal.StaffDAO;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Staff;

@WebServlet(name = "PinLoginServlet", urlPatterns = {"/pin-login"})
public class PinLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String pin = request.getParameter("pin");

        StaffDAO staffDAO = new StaffDAO();

        Staff staff = staffDAO.loginByPIN(username, pin, "WEB_BROWSER");

        if (staff != null) {
            HttpSession session = request.getSession();
            session.setAttribute("staff", staff);

            response.sendRedirect("dashboard.jsp");
        } else {
            request.setAttribute("error", "Invalid username or PIN, or account is locked!");
            request.getRequestDispatcher("pin-login.jsp").forward(request, response);
        }
    }
}