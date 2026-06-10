<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="model.Staff"%>
<%@page import="model.Role"%>
<%
    Staff currentStaff = (Staff) session.getAttribute("staff");
    if (currentStaff == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    List<Staff> staffList = (List<Staff>) request.getAttribute("staffList");
    List<Role> roleList = (List<Role>) request.getAttribute("roleList");
    String ctx = request.getContextPath();
    String pageTitle = "Quản lý nhân viên — nhà cà phê";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
</head>
<body class="textured">

    <%@ include file="/includes/staff-topbar.jsp" %>

    <main class="wrap staff-shell">
        <div class="card staff-hero">
            <p class="label">Quản trị hệ thống</p>
            <h1 class="serif">Quản lý nhân viên</h1>
            <p>Tạo tài khoản, gán vai trò và quản lý trạng thái nhân viên.</p>
        </div>

        <div class="module-grid">
            <div class="card card-pad">
                <h3 class="serif" style="font-size:20px;margin-bottom:8px">Tạo nhân viên mới</h3>
                <p class="label" style="text-transform:none;letter-spacing:0;margin-bottom:16px">
                    Mật khẩu và PIN được lưu dạng mã hóa.
                </p>

                <form action="<%=ctx%>/staff-management" method="post">
                    <input type="hidden" name="action" value="create">
                    <div class="staff-form-grid">
                        <div>
                            <label class="label label-dark" style="display:block;margin-bottom:6px">Tên đăng nhập</label>
                            <input class="field" type="text" name="username" required>
                        </div>
                        <div>
                            <label class="label label-dark" style="display:block;margin-bottom:6px">Họ và tên</label>
                            <input class="field" type="text" name="fullName" required>
                        </div>
                        <div>
                            <label class="label label-dark" style="display:block;margin-bottom:6px">Mật khẩu</label>
                            <input class="field" type="password" name="password" required>
                        </div>
                        <div>
                            <label class="label label-dark" style="display:block;margin-bottom:6px">Mã PIN (4 số)</label>
                            <input class="field" type="password" name="pin" maxlength="4" pattern="[0-9]{4}" required>
                        </div>
                        <div class="full">
                            <label class="label label-dark" style="display:block;margin-bottom:6px">Vai trò</label>
                            <select class="field" name="roleID" required>
                                <% if (roleList != null) {
                                    for (Role role : roleList) { %>
                                <option value="<%= role.getRoleID() %>"><%= role.getRoleName() %></option>
                                <%  }
                                   } %>
                            </select>
                        </div>
                    </div>
                    <button class="btn btn-primary btn-block" type="submit" style="margin-top:16px">Tạo tài khoản</button>
                </form>
            </div>

            <div class="card card-pad">
                <h3 class="serif" style="font-size:20px;margin-bottom:8px">Danh sách nhân viên</h3>
                <p class="label" style="text-transform:none;letter-spacing:0;margin-bottom:12px">
                    Kích hoạt hoặc vô hiệu hóa tài khoản khi cần.
                </p>

                <% if (staffList == null || staffList.isEmpty()) { %>
                <div class="empty-state" style="padding:30px 10px">
                    <p>Chưa có nhân viên nào.</p>
                </div>
                <% } else { %>
                <div class="staff-table-wrap">
                    <table class="staff-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Tài khoản</th>
                                <th>Họ tên</th>
                                <th>Vai trò</th>
                                <th>Trạng thái</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Staff s : staffList) { %>
                            <tr>
                                <td><%= s.getStaffID() %></td>
                                <td><%= s.getUsername() %></td>
                                <td><%= s.getFullName() %></td>
                                <td><span class="tier-chip"><%= s.getRoleName() %></span></td>
                                <td>
                                    <% if (s.isActive()) { %>
                                    <span class="badge paid">Hoạt động</span>
                                    <% } else { %>
                                    <span class="badge unpaid">Ngưng</span>
                                    <% } %>
                                </td>
                                <td>
                                    <% if (s.isActive()) { %>
                                    <form action="<%=ctx%>/staff-management" method="post" style="display:inline">
                                        <input type="hidden" name="action" value="deactivate">
                                        <input type="hidden" name="staffID" value="<%= s.getStaffID() %>">
                                        <button class="btn btn-ghost btn-sm" type="submit">Vô hiệu</button>
                                    </form>
                                    <% } else { %>
                                    <form action="<%=ctx%>/staff-management" method="post" style="display:inline">
                                        <input type="hidden" name="action" value="activate">
                                        <input type="hidden" name="staffID" value="<%= s.getStaffID() %>">
                                        <button class="btn btn-sm" type="submit">Kích hoạt</button>
                                    </form>
                                    <% } %>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                <% } %>
            </div>
        </div>
    </main>
</body>
</html>
