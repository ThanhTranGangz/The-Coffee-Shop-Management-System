package controller;

import dal.TableDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Trang nhan vien: danh sach ban + ma QR de in va dan tai ban.
 */
@WebServlet(name = "TableQRServlet", urlPatterns = {"/staff/table-qr"})
public class TableQRServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setAttribute("tables", new TableDAO().getAllWithToken());
        request.getRequestDispatcher("/table-qr.jsp").forward(request, response);
    }
}
