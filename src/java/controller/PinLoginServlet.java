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
import util.AuthUtil;

@WebServlet(name = "PinLoginServlet", urlPatterns = {"/pin-login"})
public class PinLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String pin = request.getParameter("pin");

        if (username != null) {
            username = username.trim();
        }

        if (pin != null) {
            pin = pin.trim();
        }

        if (username == null || username.isEmpty()
                || pin == null || pin.isEmpty()) {

            request.setAttribute("error", "Username and PIN must not be empty!");
            request.getRequestDispatcher("/pin-login.jsp").forward(request, response);
            return;
        }

        if (!pin.matches("\\d{4}")) {
            request.setAttribute("error", "PIN must be exactly 4 digits!");
            request.getRequestDispatcher("/pin-login.jsp").forward(request, response);
            return;
        }

        StaffDAO staffDAO = new StaffDAO();
        Staff staff = staffDAO.loginByPIN(username, pin, "WEB_BROWSER");

        if (staff != null) {
            HttpSession oldSession = request.getSession(false);

            if (oldSession != null) {
                oldSession.invalidate();
            }

            HttpSession newSession = request.getSession(true);
            AuthUtil.bindStaffSession(newSession, staff);

            response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
        } else {
            request.setAttribute("error", "Invalid username or PIN, or account is locked!");
            request.getRequestDispatcher("/pin-login.jsp").forward(request, response);
        }
    }
}
