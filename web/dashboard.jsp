<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.Staff"%>

<%
    Staff staff = (Staff) session.getAttribute("staff");

    if (staff == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String fullName = staff.getFullName();
    String roleName = staff.getRoleName();
%>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Admin Dashboard</title>

        <style>
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
            }

            body {
                font-family: Arial, Helvetica, sans-serif;
                background: linear-gradient(135deg, #f8ede3, #f3e2d3);
                color: #2d1b12;
                min-height: 100vh;
            }

            .dashboard-wrapper {
                max-width: 1280px;
                margin: 0 auto;
                padding: 28px;
            }

            .topbar {
                display: flex;
                justify-content: space-between;
                align-items: center;
                background: rgba(255, 255, 255, 0.9);
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

            .topbar-right {
                display: flex;
                align-items: center;
                gap: 15px;
            }

            .user-box {
                text-align: right;
            }

            .user-box .name {
                font-size: 15px;
                font-weight: bold;
                color: #4a2d1d;
            }

            .user-box .role {
                font-size: 13px;
                color: #8a6f5d;
            }

            .logout-btn {
                display: inline-block;
                text-decoration: none;
                background: #6f4e37;
                color: white;
                padding: 12px 18px;
                border-radius: 12px;
                font-weight: bold;
                transition: 0.25s;
            }

            .logout-btn:hover {
                background: #4f3424;
                transform: translateY(-2px);
                box-shadow: 0 10px 20px rgba(111, 78, 55, 0.2);
            }

            .hero {
                display: grid;
                grid-template-columns: 1.3fr 0.7fr;
                gap: 20px;
                margin-bottom: 24px;
            }

            .hero-left {
                background: linear-gradient(160deg, #6f4e37, #3d2417);
                color: white;
                border-radius: 24px;
                padding: 34px;
                box-shadow: 0 16px 35px rgba(80, 45, 20, 0.18);
            }

            .hero-left .badge {
                display: inline-block;
                padding: 8px 14px;
                border-radius: 20px;
                background: rgba(255, 255, 255, 0.16);
                color: #fff4ea;
                font-size: 13px;
                margin-bottom: 18px;
            }

            .hero-left h1 {
                font-size: 38px;
                margin-bottom: 12px;
                line-height: 1.2;
            }

            .hero-left p {
                color: #f1dccd;
                font-size: 16px;
                line-height: 1.7;
                max-width: 700px;
            }

            .hero-right {
                background: rgba(255, 255, 255, 0.9);
                border-radius: 24px;
                padding: 28px;
                box-shadow: 0 16px 35px rgba(80, 45, 20, 0.12);
                display: flex;
                flex-direction: column;
                justify-content: center;
            }

            .hero-right h3 {
                font-size: 22px;
                color: #4a2d1d;
                margin-bottom: 14px;
            }

            .hero-info {
                display: flex;
                flex-direction: column;
                gap: 14px;
            }

            .hero-info-item {
                background: #fffaf6;
                border: 1px solid #ead8c8;
                border-radius: 14px;
                padding: 14px 16px;
            }

            .hero-info-item .label {
                font-size: 13px;
                color: #8a6f5d;
                margin-bottom: 6px;
            }

            .hero-info-item .value {
                font-size: 16px;
                font-weight: bold;
                color: #4a2d1d;
            }

            .section-title {
                font-size: 24px;
                color: #4a2d1d;
                margin-bottom: 16px;
            }

            .overview-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 18px;
                margin-bottom: 28px;
            }

            .overview-card {
                background: rgba(255, 255, 255, 0.92);
                border-radius: 20px;
                padding: 22px;
                box-shadow: 0 10px 25px rgba(80, 45, 20, 0.10);
                border: 1px solid #f0e2d7;
            }

            .overview-card .icon {
                font-size: 28px;
                margin-bottom: 14px;
            }

            .overview-card h4 {
                font-size: 18px;
                color: #4a2d1d;
                margin-bottom: 8px;
            }

            .overview-card p {
                font-size: 14px;
                color: #7a6253;
                line-height: 1.6;
            }

            .module-grid {
                display: grid;
                grid-template-columns: repeat(2, 1fr);
                gap: 22px;
            }

            .module-card {
                background: rgba(255, 255, 255, 0.95);
                border-radius: 22px;
                padding: 24px;
                box-shadow: 0 12px 28px rgba(80, 45, 20, 0.10);
                border: 1px solid #f0e2d7;
                transition: 0.25s;
            }

            .module-card:hover {
                transform: translateY(-4px);
                box-shadow: 0 18px 35px rgba(80, 45, 20, 0.16);
            }

            .module-header {
                display: flex;
                align-items: center;
                gap: 14px;
                margin-bottom: 16px;
            }

            .module-icon {
                width: 54px;
                height: 54px;
                border-radius: 16px;
                background: #6f4e37;
                color: white;
                display: flex;
                justify-content: center;
                align-items: center;
                font-size: 26px;
            }

            .module-header h3 {
                font-size: 24px;
                color: #4a2d1d;
            }

            .module-card p {
                color: #6f5a4d;
                font-size: 15px;
                line-height: 1.7;
                margin-bottom: 16px;
            }

            .module-list {
                margin-bottom: 20px;
                padding-left: 18px;
                color: #6f5a4d;
            }

            .module-list li {
                margin-bottom: 8px;
                line-height: 1.5;
            }

            .module-actions {
                display: flex;
                gap: 12px;
                flex-wrap: wrap;
            }

            .module-btn {
                display: inline-block;
                text-decoration: none;
                padding: 11px 16px;
                border-radius: 12px;
                font-weight: bold;
                font-size: 14px;
                transition: 0.25s;
            }

            .module-btn.primary {
                background: #6f4e37;
                color: white;
            }

            .module-btn.primary:hover {
                background: #4f3424;
            }

            .module-btn.secondary {
                background: #f4e7dc;
                color: #6f4e37;
            }

            .module-btn.secondary:hover {
                background: #ead5c3;
            }

            .footer-note {
                margin-top: 28px;
                text-align: center;
                color: #7a6253;
                font-size: 14px;
                padding-bottom: 10px;
            }

            @media (max-width: 1100px) {
                .overview-grid {
                    grid-template-columns: repeat(2, 1fr);
                }

                .module-grid {
                    grid-template-columns: 1fr;
                }

                .hero {
                    grid-template-columns: 1fr;
                }
            }

            @media (max-width: 700px) {
                .topbar {
                    flex-direction: column;
                    align-items: flex-start;
                    gap: 16px;
                }

                .topbar-right {
                    width: 100%;
                    justify-content: space-between;
                }

                .overview-grid {
                    grid-template-columns: 1fr;
                }

                .hero-left h1 {
                    font-size: 30px;
                }
            }
        </style>
    </head>

    <body>
        <div class="dashboard-wrapper">

            <div class="topbar">
                <div class="brand">
                    <div class="brand-icon">☕</div>
                    <div class="brand-text">
                        <h2>Coffee Shop Management</h2>
                        <p>Admin, Security & CRM Dashboard</p>
                    </div>
                </div>

                <div class="topbar-right">
                    <div class="user-box">
                        <div class="name"><%= fullName %></div>
                        <div class="role"><%= roleName %></div>
                    </div>

                    <a class="logout-btn" href="${pageContext.request.contextPath}/logout">Logout</a>
                </div>
            </div>

            <div class="hero">
                <div class="hero-left">
                    <div class="badge">Dashboard Overview</div>
                    <h1>Welcome back, <%= fullName %>!</h1>
                    <p>
                        Manage the coffee shop’s internal administration, security,
                        staff accounts, loyalty program, vouchers, and reporting system
                        from one centralized dashboard.
                    </p>
                </div>

                <div class="hero-right">
                    <h3>Current Session</h3>

                    <div class="hero-info">
                        <div class="hero-info-item">
                            <div class="label">Logged in as</div>
                            <div class="value"><%= fullName %></div>
                        </div>

                        <div class="hero-info-item">
                            <div class="label">Role</div>
                            <div class="value"><%= roleName %></div>
                        </div>

                        <div class="hero-info-item">
                            <div class="label">Module Access</div>
                            <div class="value">Admin / Security / CRM</div>
                        </div>
                    </div>
                </div>
            </div>

            <h2 class="section-title">Quick Overview</h2>
            <div class="overview-grid">
                <div class="overview-card">
                    <div class="icon">📊</div>
                    <h4>Reports</h4>
                    <p>Review end-of-day reports, revenue summaries, and business performance.</p>
                </div>

                <div class="overview-card">
                    <div class="icon">👥</div>
                    <h4>Staff Control</h4>
                    <p>Manage staff accounts, staff roles, and role-based system permissions.</p>
                </div>

                <div class="overview-card">
                    <div class="icon">🎟️</div>
                    <h4>Voucher System</h4>
                    <p>Maintain discount vouchers and promotional logic for loyal customers.</p>
                </div>

                <div class="overview-card">
                    <div class="icon">⭐</div>
                    <h4>Customer CRM</h4>
                    <p>Track members, reward points, tier levels, and customer engagement.</p>
                </div>
            </div>

            <h2 class="section-title">Main Modules</h2>
            <div class="module-grid">

                <div class="module-card">
                    <div class="module-header">
                        <div class="module-icon">📈</div>
                        <h3>Reports</h3>
                    </div>

                    <p>
                        Access important operational and financial data for daily monitoring
                        and business decision-making.
                    </p>

                    <ul class="module-list">
                        <li>End-of-day report</li>
                        <li>Revenue overview</li>
                        <li>Payment summary</li>
                        <li>Best-selling items</li>
                    </ul>

                    <div class="module-actions">
                        <a class="module-btn primary" href="#">Open Module</a>
                        <a class="module-btn secondary" href="#">View Summary</a>
                    </div>
                </div>

                <div class="module-card">
                    <div class="module-header">
                        <div class="module-icon">🧑‍💼</div>
                        <h3>Staff Management</h3>
                    </div>

                    <p>
                        Maintain staff accounts, assign roles, and support secure access
                        for each part of the system.
                    </p>

                    <ul class="module-list">
                        <li>Create and deactivate staff accounts</li>
                        <li>Role-based permission control</li>
                        <li>PIN login support</li>
                        <li>Session management</li>
                    </ul>

                    <div class="module-actions">
<a class="module-btn primary" href="${pageContext.request.contextPath}/staff-management">Open Module</a>                        <a class="module-btn secondary" href="#">Manage Roles</a>
                    </div>
                </div>

                <div class="module-card">
                    <div class="module-header">
                        <div class="module-icon">🏷️</div>
                        <h3>Vouchers</h3>
                    </div>

                    <p>
                        Configure promotion rules and valid discount vouchers for customers
                        based on loyalty and order conditions.
                    </p>

                    <ul class="module-list">
                        <li>Create voucher codes</li>
                        <li>Set discount amount or percent</li>
                        <li>Define expiry date</li>
                        <li>Apply tier-based conditions</li>
                    </ul>

                    <div class="module-actions">
                        <a class="module-btn primary" href="#">Open Module</a>
                        <a class="module-btn secondary" href="#">Check Validity</a>
                    </div>
                </div>

                <div class="module-card">
                    <div class="module-header">
                        <div class="module-icon">💎</div>
                        <h3>CRM</h3>
                    </div>

                    <p>
                        Track member profiles, reward points, customer tiers,
                        and loyalty-related activities.
                    </p>

                    <ul class="module-list">
                        <li>Member information</li>
                        <li>Reward point history</li>
                        <li>Tier calculation</li>
                        <li>Loyalty support</li>
                    </ul>

                    <div class="module-actions">
                        <a class="module-btn primary" href="#">Open Module</a>
                        <a class="module-btn secondary" href="#">View Members</a>
                    </div>
                </div>

            </div>

            <div class="footer-note">
                The Coffee Shop Management System © 2026
            </div>
        </div>
    </body>
</html>