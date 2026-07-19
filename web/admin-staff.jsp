<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
    <!DOCTYPE html>
    <html lang="vi">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
        <title>Quản lý nhân viên - Admin</title>
        <link rel="stylesheet" href="assets/css/app.css?v=admin-staff-1">
        <script defer src="assets/js/i18n.js?v=2"></script>
        <style>
            /* Custom styles for the staff calendar prototype */
            .staff-calendar {
                background: rgba(255, 250, 241, 0.96);
                border: 1px solid var(--line);
                border-radius: var(--radius);
                box-shadow: var(--shadow-soft);
                overflow-x: auto;
                padding: 18px;
                font-size: 13px;
            }

            .calendar-grid {
                display: grid;
                grid-template-columns: 100px repeat(7, minmax(130px, 1fr));
                gap: 1px;
                background: var(--line);
                border: 1px solid var(--line);
            }

            .calendar-cell {
                background: var(--surface);
                padding: 12px;
                min-height: 100px;
            }

            .calendar-header {
                background: var(--surface-2);
                font-weight: bold;
                text-align: center;
                padding: 12px;
            }

            .staff-name-col {
                background: var(--surface-2);
                font-weight: bold;
                display: flex;
                flex-direction: column;
                justify-content: center;
            }

            .staff-role {
                font-weight: normal;
                font-size: 11px;
                color: var(--muted);
                margin-top: 4px;
            }

            .shift-block {
                margin-bottom: 8px;
                padding-bottom: 8px;
                border-bottom: 1px dashed var(--line);
            }

            .shift-block:last-child {
                margin-bottom: 0;
                padding-bottom: 0;
                border-bottom: none;
            }

            .shift-name {
                font-weight: bold;
                display: block;
                margin-bottom: 2px;
            }

            .shift-time {
                font-size: 11px;
                color: var(--ink-soft);
                display: block;
            }

            .shift-status {
                font-size: 11px;
                margin-top: 4px;
                display: inline-block;
            }

            .status-done {
                color: var(--good);
            }

            .status-pending {
                color: var(--muted);
            }

            .status-absent {
                color: var(--danger);
            }

            .add-shift-btn {
                color: var(--muted);
                cursor: pointer;
                text-align: center;
                display: block;
                margin-top: 8px;
                font-weight: bold;
            }

            .add-shift-btn:hover {
                color: var(--accent);
            }

            /* Sub-roles inside cells */
            .role-group {
                border-bottom: 1px dashed var(--line);
                padding-bottom: 6px;
                margin-bottom: 6px;
            }

            .role-group:last-child {
                border-bottom: none;
                margin-bottom: 0;
                padding-bottom: 0;
            }

            .role-title {
                font-size: 11px;
                font-weight: 600;
                color: var(--ink);
                text-transform: uppercase;
                margin-bottom: 4px;
                opacity: 0.7;
            }

            .role-warning {
                color: var(--danger);
                font-size: 11px;
                margin-bottom: 4px;
            }

            .role-add-btn {
                color: var(--muted);
                cursor: pointer;
                text-align: center;
                font-size: 16px;
                line-height: 16px;
                font-weight: bold;
                border: 1px dashed var(--line);
                border-radius: 4px;
                margin-top: 4px;
                padding: 2px 0;
            }

            .role-add-btn:hover {
                color: var(--accent);
                border-color: var(--accent);
                background: rgba(199, 137, 72, 0.05);
            }

            .calendar-cell {
                padding: 8px;
                /* Slightly reduced padding to fit more content */
            }
        </style>
    </head>

    <body>
        <nav class="nav">
            <div class="nav-inner">
                <a class="brand" href="index.html">coffeshop</a>
                <div class="links" id="nav-links">
                    <a class="link" href="dashboard.jsp">Dashboard</a>
                    <a class="link" href="admin-menu.jsp">Menu</a>
                    <a class="link" href="admin-tables.jsp">Bàn</a>
                    <a class="link" href="admin-staff.jsp" style="border-color:var(--accent);color:var(--accent);">Nhân
                        viên</a>
                </div>
                <button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button>
            </div>
        </nav>
        <main class="shell work-shell">
            <div class="grid side admin-staff-layout">
                <!-- Left Side: Calendar Grid -->
                <section class="staff-calendar">
                    <div class="work-toolbar"
                        style="margin-bottom: 15px; display: flex; justify-content: space-between;">
                        <h3 data-i18n="staffSchedule">Lịch làm việc tuần này</h3>
                        <div style="display:flex; gap:10px; align-items:center;">
                            <button class="btn" type="button"
                                onclick="document.getElementById('payroll-section').scrollIntoView({ behavior: 'smooth' })"
                                style="background:var(--accent); color:white; border:none;"
                                title="Trượt xuống Bảng chấm công" data-i18n="jumpToPayroll">
                                Bảng Chấm Công
                            </button>
                            <button class="btn" onclick="prevWeek()" data-i18n="prevWeek">&lt; Tuần trước</button>
                            <button class="btn" onclick="nextWeek()" data-i18n="nextWeek">Tuần sau &gt;</button>
                        </div>
                    </div>

                    <div class="calendar-grid" id="calendar-grid">
                        <!-- Grid will be generated by JS -->
                    </div>
                </section>

                <!-- Right Side: Form -->
                <aside class="card">
                    <h2 id="form-title" data-i18n="shiftFormTitle">Phân công ca làm</h2>
                    <form class="grid" onsubmit="saveShift(event)" style="margin-top: 15px;">
                        <input id="shiftId" type="hidden">

                        <div>
                            <label data-i18n="staffLabel">Nhân viên</label>
                            <select id="staffId" required
                                style="width:100%; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                                <!-- Populated by JS -->
                            </select>
                        </div>

                        <div>
                            <label data-i18n="dateLabel">Ngày (YYYY-MM-DD)</label>
                            <input id="shiftDate" type="date" required
                                style="width:100%; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                        </div>

                        <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                            <div>
                                <label data-i18n="shiftLabel">Ca làm</label>
                                <select id="shiftName" required
                                    style="width:100%; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                                    <option value="Ca Sáng" data-i18n="shiftMorning">Ca Sáng (06:00 - 12:00)</option>
                                    <option value="Ca Chiều" data-i18n="shiftAfternoon">Ca Chiều (12:00 - 18:00)</option>
                                    <option value="Ca Tối" data-i18n="shiftEvening">Ca Tối (18:00 - 23:00)</option>
                                </select>
                            </div>
                            <div>
                                <label data-i18n="roleLabel">Vị trí (Vai trò)</label>
                                <select id="assignedRole" required
                                    style="width:100%; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                                    <option value="Barista" data-i18n="roleBaristaFull">Barista (Pha chế)</option>
                                    <option value="Cashier" data-i18n="roleCashierFull">Cashier (Thu ngân)</option>
                                    <option value="Waiter" data-i18n="roleWaiterFull">Waiter (Phục vụ)</option>
                                </select>
                            </div>
                        </div>

                        <div>
                            <label data-i18n="notesLabel">Ghi chú</label>
                            <textarea id="notes" rows="3" data-i18n-placeholder="notesPlaceholder" placeholder="Ghi chú thêm..."
                                style="width:100%; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm); font-family:inherit;"></textarea>
                        </div>

                        <div>
                            <label data-i18n="statusLabel">Trạng thái</label>
                            <select id="status" required
                                style="width:100%; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                                <option value="Đã xếp lịch" data-i18n="statusScheduled">Đã xếp lịch</option>
                                <option value="Đã làm" data-i18n="statusDone">Đã làm</option>
                                <option value="Vắng" data-i18n="statusAbsent">Vắng</option>
                            </select>
                        </div>

                        <div style="display: flex; gap: 10px; margin-top: 10px;">
                            <button class="btn primary block" type="submit" style="flex: 1;" data-i18n="saveShift">LƯU CA LÀM</button>
                            <button class="btn" type="button" onclick="deleteShift()" data-i18n="delete"
                                style="color: var(--danger); border-color: var(--danger);">XÓA</button>
                        </div>
                        <div id="message" class="notice hidden"></div>
                    </form>
                </aside>
            </div>

            <!-- Payroll Section -->
            <section id="payroll-section" class="card" style="margin-top: 20px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h2 style="margin: 0; font-size: 1.25rem;" data-i18n="payrollSection">Bảng chấm công (Tính tổng giờ)</h2>
                    <div style="display: flex; gap: 15px; align-items: center;">
                        <div>
                            <label style="font-weight: bold; margin-right: 5px;" data-i18n="roleFilter">Vai trò:</label>
                            <select id="payrollRoleFilter" onchange="applyPayrollFilter()"
                                style="padding: 8px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                                <option value="All" data-i18n="allRoles">Tất cả</option>
                                <option value="Barista" data-i18n="roleBaristaFull">Barista (Pha chế)</option>
                                <option value="Cashier" data-i18n="roleCashierFull">Cashier (Thu ngân)</option>
                                <option value="Waiter" data-i18n="roleWaiterFull">Waiter (Phục vụ)</option>
                            </select>
                        </div>
                        <div>
                            <label style="font-weight: bold; margin-right: 5px;" data-i18n="monthFilter">Tháng:</label>
                            <input type="month" id="payrollMonth" onchange="fetchPayroll()"
                                style="padding: 8px; border: 1px solid var(--line); border-radius: var(--radius-sm);">
                        </div>
                    </div>
                </div>

                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; text-align: left;">
                        <thead>
                            <tr style="border-bottom: 1px solid var(--line); background-color: rgba(0,0,0,0.02);">
                                <th style="padding: 12px; font-weight: bold;" data-i18n="staffLabel">Tên nhân viên</th>
                                <th style="padding: 12px; font-weight: bold;" data-i18n="roleLabel">Vị trí (Vai trò)</th>
                                <th style="padding: 12px; font-weight: bold; text-align: center;" data-i18n="totalShifts">Tổng số ca (Đã làm)</th>
                                <th style="padding: 12px; font-weight: bold; text-align: center;" data-i18n="totalHours">Tổng số giờ</th>
                            </tr>
                        </thead>
                        <tbody id="payroll-tbody">
                            <tr>
                                <td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);" data-i18n="loadingData">Đang tải
                                    dữ liệu...</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div style="margin-top: 10px; font-size: 11px; color: var(--muted);">
                    <span data-i18n="payrollNote1">* Chỉ tính số giờ cho những ca làm có trạng thái là "Đã làm" hoặc "Hoàn thành".</span><br>
                    <span data-i18n="payrollNote2">* Ca Sáng / Ca Chiều: 6 giờ. Ca Tối: 5 giờ.</span>
                </div>
            </section>

            <!-- Staff Management Section -->
            <section id="staff-management-section" class="card" style="margin-top: 20px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h2 style="margin: 0; font-size: 1.25rem;" data-i18n="staffManagementTitle">Quản lý danh sách nhân viên</h2>
                    <button class="btn primary" type="button" onclick="openStaffModal()">+ Thêm nhân viên</button>
                </div>
                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; text-align: left;">
                        <thead>
                            <tr style="border-bottom: 1px solid var(--line); background-color: rgba(0,0,0,0.02);">
                                <th style="padding: 12px; font-weight: bold;">ID</th>
                                <th style="padding: 12px; font-weight: bold;">Tên nhân viên</th>
                                <th style="padding: 12px; font-weight: bold;">Trạng thái</th>
                                <th style="padding: 12px; font-weight: bold; text-align: right;">Thao tác</th>
                            </tr>
                        </thead>
                        <tbody id="staff-list-tbody">
                            <tr>
                                <td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);">Đang tải dữ liệu...</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- Scroll to Top Button -->
            <button id="scrollTopBtn" onclick="window.scrollTo({top: 0, behavior: 'smooth'})"
                style="display: none; position: fixed; bottom: 20px; right: 20px; z-index: 1000; background-color: var(--primary); color: white; border: none; border-radius: 50%; width: 40px; height: 40px; font-size: 20px; cursor: pointer; box-shadow: 0 2px 5px rgba(0,0,0,0.3); align-items: center; justify-content: center;">
                ↑
            </button>
        </main>

        <!-- Staff Modal -->
        <div id="staffModal" class="modal hidden">
            <div class="modal-content" style="max-width: 500px;">
                <div class="modal-header">
                    <h2 id="staffModalTitle">Thêm nhân viên</h2>
                    <button class="btn-close" onclick="closeStaffModal()">×</button>
                </div>
                <div class="modal-body">
                    <form id="staffForm" onsubmit="saveStaff(event)">
                        <div class="form-group" style="margin-bottom: 15px;">
                            <label>ID Nhân viên (chỉ nhập số)</label>
                            <input type="number" id="staffIdInput" class="input" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 15px;">
                            <label>Tên nhân viên</label>
                            <input type="text" id="staffNameInput" class="input" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 15px;">
                            <label>Trạng thái</label>
                            <select id="staffStatusInput" class="input" required>
                                <option value="Active">Active (Đang làm)</option>
                                <option value="Inactive">Inactive (Đã nghỉ)</option>
                            </select>
                        </div>
                        <div style="display: flex; gap: 10px; margin-top: 20px;">
                            <button type="submit" class="btn primary" style="flex: 1;">LƯU NHÂN VIÊN</button>
                            <button type="button" class="btn" onclick="closeStaffModal()">HỦY</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        <style>
            .modal { display: flex; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5); justify-content: center; align-items: center; }
            .modal.hidden { display: none; }
            .modal-content { background-color: var(--surface); padding: 20px; border-radius: var(--radius); width: 90%; max-width: 600px; box-shadow: var(--shadow-strong); }
            .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; border-bottom: 1px solid var(--line); padding-bottom: 10px; }
            .modal-header h2 { margin: 0; font-size: 1.2rem; }
            .btn-close { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--muted); }
            .btn-close:hover { color: var(--danger); }
            .input { width: 100%; padding: 8px; border: 1px solid var(--line); border-radius: var(--radius-sm); box-sizing: border-box; }
        </style>

        <script>
            // Show/hide scroll to top button based on scroll position
            window.onscroll = function () {
                var btn = document.getElementById("scrollTopBtn");
                if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
                    btn.style.display = "flex";
                } else {
                    btn.style.display = "none";
                }
            };
        </script>
        <script src="assets/js/page-admin-staff.js?v=2"></script>
    </body>

    </html>