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

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username != null) {
            username = username.trim();
        }

        if (password != null) {
            password = password.trim();
        }

        if (username == null || username.isEmpty()
                || password == null || password.isEmpty()) {

            request.setAttribute("error", "Username and password must not be empty!");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        StaffDAO staffDAO = new StaffDAO();
        Staff staff = staffDAO.loginByUsernamePassword(username, password);

        if (staff != null) {
            HttpSession oldSession = request.getSession(false);
            if (oldSession != null) {
                oldSession.invalidate();
            }

            HttpSession newSession = request.getSession(true);
            newSession.setAttribute("staff", staff);

            String role = staff.getRoleName().toUpperCase(); // giả sử Staff có getter roleName

            switch (role) {
                case "BARISTA":
                    response.sendRedirect(request.getContextPath() + "/kds.jsp");
                    break;
                case "WAITER":
                    response.sendRedirect(request.getContextPath() + "/waitstation.jsp");
                    break;
                default:
                    response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
                    break;
            }
        } else {
            request.setAttribute("error", "Invalid username or password!");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }

    }
}
