<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
    <!DOCTYPE html>
    <html lang="vi">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
        <title>Quản lý nhân viên - Admin</title>
        <meta name="page-title-key" content="staffAdminTitle">
        <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
        <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
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
                grid-template-columns: 88px 82px repeat(7, minmax(118px, 1fr));
                gap: 1px;
                background: var(--line);
                border: 1px solid var(--line);
            }

            .calendar-cell {
                background: var(--surface);
                padding: 8px;
                min-height: 64px;
            }

            .calendar-header {
                background: var(--surface-2);
                font-weight: bold;
                text-align: center;
                padding: 10px 8px;
                min-height: auto;
            }

            .staff-name-col {
                background: var(--surface-2);
                font-weight: bold;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: flex-start;
                grid-row: span 3;
                border-right: 2px solid var(--line);
            }

            .staff-role {
                font-weight: normal;
                font-size: 11px;
                color: var(--muted);
                margin-top: 4px;
            }

            .role-label-col {
                display: flex;
                align-items: center;
                justify-content: center;
                text-align: center;
                font-size: 11px;
                font-weight: 800;
                letter-spacing: 0.02em;
                text-transform: uppercase;
                border-right: 1px solid var(--line);
                min-height: 72px;
            }

            .role-day-cell {
                display: flex;
                flex-direction: column;
                gap: 4px;
                min-height: 72px;
            }

            .role-barista,
            .role-label-col.role-barista,
            .role-day-cell.role-barista {
                background: #fff8f1;
            }

            .role-cashier,
            .role-label-col.role-cashier,
            .role-day-cell.role-cashier {
                background: #f4f8f4;
            }

            .role-waiter,
            .role-label-col.role-waiter,
            .role-day-cell.role-waiter {
                background: #f7f5f1;
            }

            .shift-block {
                margin: 0;
                padding: 6px 7px;
                border: 1px solid var(--line);
                border-radius: 6px;
                background: rgba(255, 255, 255, 0.72);
            }

            .shift-name {
                font-weight: bold;
                display: block;
                margin-bottom: 2px;
                line-height: 1.25;
            }

            .shift-status {
                font-size: 11px;
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

            .role-warning {
                color: var(--danger);
                font-size: 11px;
                line-height: 1.3;
            }

            .role-add-btn {
                color: var(--muted);
                cursor: pointer;
                text-align: center;
                font-size: 15px;
                line-height: 1;
                font-weight: bold;
                border: 1px dashed var(--line);
                border-radius: 4px;
                margin-top: auto;
                padding: 4px 0;
                background: rgba(255, 255, 255, 0.45);
            }

            .role-add-btn:hover {
                color: var(--accent);
                border-color: var(--accent);
                background: rgba(199, 137, 72, 0.08);
            }

            .shift-band-divider {
                box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.06);
            }

            #message.notice.danger {
                color: var(--danger);
                border-color: rgba(180, 60, 60, 0.35);
                background: rgba(180, 60, 60, 0.08);
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
                                data-i18n-title="jumpToPayrollTitle" title="Trượt xuống Bảng chấm công" data-i18n="jumpToPayroll">
                                Bảng Chấm Công
                            </button>
                            <button class="btn" id="carryOverBtn" type="button" onclick="carryOverShifts()"
                                style="background:#2e7d32; color:white; border:none; white-space:nowrap;"
                                title="Sao chép lịch tuần này sang tuần tới" data-i18n="carryOverShifts">
                                📋 Sao chép → Tuần sau
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
                                    <option value="barista" data-i18n="roleBaristaFull">Barista (Pha chế)</option>
                                    <option value="cashier" data-i18n="roleCashierFull">Cashier (Thu ngân)</option>
                                    <option value="runner" data-i18n="roleWaiterFull">Waiter (Phục vụ)</option>
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
                                <option value="barista" data-i18n="roleBaristaFull">Barista (Pha chế)</option>
                                <option value="cashier" data-i18n="roleCashierFull">Cashier (Thu ngân)</option>
                                <option value="runner" data-i18n="roleWaiterFull">Waiter (Phục vụ)</option>
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
                    <button class="btn primary" type="button" onclick="openStaffModal()" data-i18n="addStaff">+ Thêm nhân viên</button>
                </div>
                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; text-align: left;">
                        <thead>
                            <tr style="border-bottom: 1px solid var(--line); background-color: rgba(0,0,0,0.02);">
                                <th style="padding: 12px; font-weight: bold;">ID</th>
                                <th style="padding: 12px; font-weight: bold;" data-i18n="staffNameLabel">Tên nhân viên</th>
                                <th style="padding: 12px; font-weight: bold;" data-i18n="statusLabel">Trạng thái</th>
                                <th style="padding: 12px; font-weight: bold; text-align: right;" data-i18n="actions">Thao tác</th>
                            </tr>
                        </thead>
                        <tbody id="staff-list-tbody">
                            <tr>
                                <td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);" data-i18n="loadingData">Đang tải dữ liệu...</td>
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
                            <label data-i18n="staffIdLabel">ID Nhân viên (chỉ nhập số)</label>
                            <input type="number" id="staffIdInput" class="input" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 15px;">
                            <label data-i18n="staffNameLabel">Tên nhân viên</label>
                            <input type="text" id="staffNameInput" class="input" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 15px;">
                            <label data-i18n="statusLabel">Trạng thái</label>
                            <select id="staffStatusInput" class="input" required>
                                <option value="Active" data-i18n="staffActive">Đang làm</option>
                                <option value="Inactive" data-i18n="staffInactive">Đã nghỉ</option>
                            </select>
                        </div>
                        <div style="display: flex; gap: 10px; margin-top: 20px;">
                            <button type="submit" class="btn primary" style="flex: 1;" data-i18n="saveStaff">LƯU NHÂN VIÊN</button>
                            <button type="button" class="btn" onclick="closeStaffModal()" data-i18n="cancel">HỦY</button>
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
        <script src="assets/js/page-admin-staff.js?v=5"></script>
    </body>

    </html>