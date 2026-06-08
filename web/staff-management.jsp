<%@page contentType="text/html" pageEncoding="UTF-8"%>
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
%>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Staff Management</title>

        <style>
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
            }

            body {
                font-family: Arial, Helvetica, sans-serif;
                min-height: 100vh;
                background: linear-gradient(135deg, #f8ede3, #f3e2d3);
                color: #2d1b12;
            }

            .wrapper {
                max-width: 1280px;
                margin: 0 auto;
                padding: 28px;
            }

            .topbar {
                display: flex;
                justify-content: space-between;
                align-items: center;
                background: rgba(255, 255, 255, 0.92);
                border-radius: 18px;
                padding: 18px 24px;
                box-shadow: 0 10px 25px rgba(80, 45, 20, 0.12);
                margin-bottom: 24px;
            }

            .brand {
                display: flex;
                align-items: center;
                gap: 14px;
            }

            .brand-icon {
                width: 52px;
                height: 52px;
                border-radius: 14px;
                background: linear-gradient(160deg, #6f4e37, #3d2417);
                color: white;
                display: flex;
                justify-content: center;
                align-items: center;
                font-size: 26px;
            }

            .brand-text h2 {
                font-size: 24px;
                color: #4a2d1d;
                margin-bottom: 4px;
            }

            .brand-text p {
                color: #7a6253;
                font-size: 14px;
            }

            .top-actions {
                display: flex;
                gap: 12px;
                align-items: center;
            }

            .nav-btn {
                display: inline-block;
                text-decoration: none;
                border: none;
                background: #6f4e37;
                color: white;
                padding: 12px 18px;
                border-radius: 12px;
                font-weight: bold;
                cursor: pointer;
                transition: 0.25s;
            }

            .nav-btn:hover {
                background: #4f3424;
                transform: translateY(-2px);
            }

            .nav-btn.light {
                background: #f4e7dc;
                color: #6f4e37;
            }

            .nav-btn.light:hover {
                background: #ead5c3;
            }

            .hero {
                background: linear-gradient(160deg, #6f4e37, #3d2417);
                color: white;
                border-radius: 24px;
                padding: 34px;
                margin-bottom: 24px;
                box-shadow: 0 16px 35px rgba(80, 45, 20, 0.18);
            }

            .hero .badge {
                display: inline-block;
                padding: 8px 14px;
                border-radius: 20px;
                background: rgba(255, 255, 255, 0.16);
                color: #fff4ea;
                font-size: 13px;
                margin-bottom: 18px;
            }

            .hero h1 {
                font-size: 38px;
                margin-bottom: 12px;
            }

            .hero p {
                color: #f1dccd;
                font-size: 16px;
                line-height: 1.7;
                max-width: 760px;
            }

            .content-grid {
                display: grid;
                grid-template-columns: 0.9fr 1.4fr;
                gap: 24px;
            }

            .card {
                background: rgba(255, 255, 255, 0.95);
                border-radius: 22px;
                padding: 24px;
                box-shadow: 0 12px 28px rgba(80, 45, 20, 0.10);
                border: 1px solid #f0e2d7;
            }

            .card h3 {
                font-size: 24px;
                color: #4a2d1d;
                margin-bottom: 8px;
            }

            .card-desc {
                color: #7a6253;
                font-size: 14px;
                line-height: 1.6;
                margin-bottom: 22px;
            }

            .form-group {
                margin-bottom: 16px;
            }

            label {
                display: block;
                color: #4a2d1d;
                font-weight: bold;
                font-size: 14px;
                margin-bottom: 7px;
            }

            input, select {
                width: 100%;
                padding: 13px 14px;
                border-radius: 12px;
                border: 1px solid #d7c0ad;
                background: #fffaf6;
                outline: none;
                font-size: 14px;
            }

            input:focus, select:focus {
                border-color: #6f4e37;
                box-shadow: 0 0 0 3px rgba(111, 78, 55, 0.15);
                background: white;
            }

            .submit-btn {
                width: 100%;
                padding: 14px;
                border: none;
                border-radius: 12px;
                background: #6f4e37;
                color: white;
                font-size: 15px;
                font-weight: bold;
                cursor: pointer;
                transition: 0.25s;
                margin-top: 6px;
            }

            .submit-btn:hover {
                background: #4f3424;
                transform: translateY(-2px);
            }

            table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 18px;
                overflow: hidden;
                border-radius: 16px;
            }

            thead {
                background: #6f4e37;
                color: white;
            }

            th, td {
                padding: 14px 12px;
                text-align: left;
                font-size: 14px;
            }

            tbody tr {
                background: #fffaf6;
                border-bottom: 1px solid #ead8c8;
            }

            tbody tr:hover {
                background: #f7ecdf;
            }

            .status {
                display: inline-block;
                padding: 6px 10px;
                border-radius: 20px;
                font-weight: bold;
                font-size: 12px;
            }

            .status.active {
                background: #e4f7e9;
                color: #1b7f3a;
            }

            .status.inactive {
                background: #ffe5e5;
                color: #c62828;
            }

            .role-badge {
                display: inline-block;
                padding: 6px 10px;
                border-radius: 20px;
                background: #f4e7dc;
                color: #6f4e37;
                font-weight: bold;
                font-size: 12px;
            }

            .action-form {
                display: inline-block;
            }

            .small-btn {
                border: none;
                padding: 8px 12px;
                border-radius: 10px;
                cursor: pointer;
                font-weight: bold;
                font-size: 12px;
            }

            .small-btn.deactivate {
                background: #ffe5e5;
                color: #c62828;
            }

            .small-btn.activate {
                background: #e4f7e9;
                color: #1b7f3a;
            }

            .empty-box {
                padding: 25px;
                text-align: center;
                color: #7a6253;
                background: #fffaf6;
                border-radius: 16px;
                margin-top: 18px;
            }

            .footer-note {
                margin-top: 28px;
                text-align: center;
                color: #7a6253;
                font-size: 14px;
                padding-bottom: 10px;
            }

            @media (max-width: 1000px) {
                .content-grid {
                    grid-template-columns: 1fr;
                }
            }

            @media (max-width: 700px) {
                .topbar {
                    flex-direction: column;
                    align-items: flex-start;
                    gap: 16px;
                }

                .top-actions {
                    width: 100%;
                    justify-content: space-between;
                }

                .hero h1 {
                    font-size: 30px;
                }

                table {
                    display: block;
                    overflow-x: auto;
                }
            }
        </style>
    </head>

    <body>
        <div class="wrapper">

            <div class="topbar">
                <div class="brand">
                    <div class="brand-icon">🧑‍💼</div>
                    <div class="brand-text">
                        <h2>Staff Management</h2>
                        <p>Manage employee accounts, roles, and account status</p>
                    </div>
                </div>

                <div class="top-actions">
                    <a class="nav-btn light" href="${pageContext.request.contextPath}/dashboard.jsp">Dashboard</a>
                    <a class="nav-btn" href="${pageContext.request.contextPath}/logout">Logout</a>
                </div>
            </div>

            <div class="hero">
                <div class="badge">Admin / Security Module</div>
                <h1>Staff Account Control</h1>
                <p>
                    Create staff accounts, assign system roles, activate or deactivate employees,
                    and support secure role-based access for the Coffee Shop Management System.
                </p>
            </div>

            <div class="content-grid">

                <div class="card">
                    <h3>Create New Staff</h3>
                    <p class="card-desc">
                        Add a new employee account. Password and PIN will be stored as hashed values.
                    </p>

                    <form action="${pageContext.request.contextPath}/staff-management" method="post">
                        <input type="hidden" name="action" value="create">

                        <div class="form-group">
                            <label>Username</label>
                            <input type="text" name="username" placeholder="Example: cashier01" required>
                        </div>

                        <div class="form-group">
                            <label>Full Name</label>
                            <input type="text" name="fullName" placeholder="Example: Nguyen Van A" required>
                        </div>

                        <div class="form-group">
                            <label>Password</label>
                            <input type="password" name="password" placeholder="Enter password" required>
                        </div>

                        <div class="form-group">
                            <label>PIN Code</label>
                            <input type="password" name="pin" placeholder="4-digit PIN" maxlength="4" pattern="[0-9]{4}" required>
                        </div>

                        <div class="form-group">
                            <label>Role</label>
                            <select name="roleID" required>
                                <%
                                    if (roleList != null) {
                                        for (Role role : roleList) {
                                %>
                                            <option value="<%= role.getRoleID() %>"><%= role.getRoleName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>

                        <button class="submit-btn" type="submit">Create Staff Account</button>
                    </form>
                </div>

                <div class="card">
                    <h3>Staff List</h3>
                    <p class="card-desc">
                        View all staff accounts and change account status when needed.
                    </p>

                    <%
                        if (staffList == null || staffList.isEmpty()) {
                    %>
                        <div class="empty-box">
                            No staff account found.
                        </div>
                    <%
                        } else {
                    %>
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Username</th>
                                    <th>Full Name</th>
                                    <th>Role</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>

                            <tbody>
                                <%
                                    for (Staff s : staffList) {
                                %>
                                    <tr>
                                        <td><%= s.getStaffID() %></td>
                                        <td><%= s.getUsername() %></td>
                                        <td><%= s.getFullName() %></td>
                                        <td>
                                            <span class="role-badge"><%= s.getRoleName() %></span>
                                        </td>
                                        <td>
                                            <% if (s.isActive()) { %>
                                                <span class="status active">Active</span>
                                            <% } else { %>
                                                <span class="status inactive">Inactive</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (s.isActive()) { %>
                                                <form class="action-form" action="${pageContext.request.contextPath}/staff-management" method="post">
                                                    <input type="hidden" name="action" value="deactivate">
                                                    <input type="hidden" name="staffID" value="<%= s.getStaffID() %>">
                                                    <button class="small-btn deactivate" type="submit">Deactivate</button>
                                                </form>
                                            <% } else { %>
                                                <form class="action-form" action="${pageContext.request.contextPath}/staff-management" method="post">
                                                    <input type="hidden" name="action" value="activate">
                                                    <input type="hidden" name="staffID" value="<%= s.getStaffID() %>">
                                                    <button class="small-btn activate" type="submit">Activate</button>
                                                </form>
                                            <% } %>
                                        </td>
                                    </tr>
                                <%
                                    }
                                %>
                            </tbody>
                        </table>
                    <%
                        }
                    %>
                </div>

            </div>

            <div class="footer-note">
                The Coffee Shop Management System © 2026
            </div>
        </div>
    </body>
</html>