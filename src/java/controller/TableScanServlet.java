package controller;

import dal.TableDAO;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import model.Tables;

/**
 * Diem den cua ma QR dan tai ban: /table?token=xxx
 * Xac dinh ban, luu vao session roi dua khach vao menu.
 */
@WebServlet(name = "TableScanServlet", urlPatterns = {"/table"})
public class TableScanServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String token = request.getParameter("token");
        String ctx = request.getContextPath();

        if (token == null || token.trim().isEmpty()) {
            response.sendRedirect(ctx + "/menu.jsp?qr=invalid");
            return;
        }

        Tables table = new TableDAO().findByToken(token.trim());
        if (table == null) {
            response.sendRedirect(ctx + "/menu.jsp?qr=invalid");
            return;
        }

        request.getSession(true).setAttribute("table", table);
        response.sendRedirect(ctx + "/menu.jsp");
    }
}
