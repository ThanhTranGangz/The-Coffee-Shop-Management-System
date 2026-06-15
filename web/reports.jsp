<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Staff"%>
<%@page import="util.AuthUtil"%>
<%@page import="util.Permission"%>
<%
    Staff staff = (Staff) session.getAttribute("staff");
    if (staff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String ctx = request.getContextPath();
    String pageTitle = "Báo cáo & Phân tích — nhà cà phê";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .report-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 20px;
            margin-top: 20px;
        }
        @media (min-width: 800px) {
            .report-grid {
                grid-template-columns: 2fr 1fr;
            }
            .grid-2col {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
            }
        }
        
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 14px;
            margin-bottom: 20px;
        }
        @media (min-width: 768px) {
            .kpi-row {
                grid-template-columns: repeat(4, 1fr);
            }
        }
        
        .kpi-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius-sm);
            padding: 18px 14px;
            text-align: center;
            box-shadow: var(--shadow-soft);
        }
        .kpi-card .num {
            font-family: var(--font-serif);
            font-size: 20px;
            font-weight: 700;
            color: var(--accent);
            margin-top: 4px;
        }
        
        .chart-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            padding: 20px;
            box-shadow: var(--shadow-soft);
            margin-bottom: 20px;
        }
        .chart-card h4 {
            margin-bottom: 15px;
            font-size: 16px;
            border-left: 3px solid var(--accent);
            padding-left: 10px;
        }
        
        .date-picker-row {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: flex-end;
            background: var(--surface-2);
            padding: 16px;
            border-radius: var(--radius-sm);
            margin-bottom: 20px;
            border: 1px solid var(--line);
        }
        .date-picker-row .group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .date-picker-row label {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: .08em;
            color: var(--muted);
        }
        .date-picker-row input {
            padding: 8px 12px;
            border: 1px solid var(--line-strong);
            background: var(--surface);
            border-radius: 6px;
            outline: none;
        }
        .date-picker-row input:focus {
            border-color: var(--accent);
        }
        
        /* Tab panel styling */
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
        
        .page-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 1px solid var(--line-strong);
            padding-bottom: 8px;
        }
        .page-tab {
            font-family: var(--font-mono);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: .1em;
            border: none;
            background: none;
            color: var(--muted);
            padding: 6px 12px;
            cursor: pointer;
            border-radius: var(--radius-sm);
            transition: all .2s;
        }
        .page-tab.active {
            background: var(--ink);
            color: var(--surface);
        }
        
        /* Simulator Styles */
        .sim-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 20px;
        }
        @media (min-width: 800px) {
            .sim-grid {
                grid-template-columns: 1fr 1.2fr;
            }
        }
        .sim-form {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }
        .sim-form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .sim-form-group label {
            font-size: 12px;
            font-weight: 600;
            color: var(--ink-soft);
        }
        .sim-result-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            padding: 24px;
            box-shadow: var(--shadow);
            border-top: 4px solid var(--accent);
        }
        
        /* Progress Bar Upgrade */
        .progress-container {
            margin: 20px 0;
            position: relative;
        }
        .progress-bar-bg {
            height: 10px;
            background: var(--line);
            border-radius: 99px;
            overflow: hidden;
            position: relative;
        }
        .progress-bar-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--accent), #eab308);
            width: 0%;
            transition: width 0.6s ease;
        }
        .progress-ticks {
            display: flex;
            justify-content: space-between;
            margin-top: 8px;
            font-size: 11px;
            color: var(--muted);
        }
        .progress-tick {
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        
        .alert-upgrade {
            background: var(--warn-soft);
            border: 1px solid var(--warn);
            color: var(--warn);
            border-radius: var(--radius-sm);
            padding: 14px;
            text-align: center;
            font-weight: 700;
            animation: bounce 1s infinite alternate;
            margin-top: 15px;
        }
        @keyframes bounce {
            from { transform: translateY(0); }
            to { transform: translateY(-4px); }
        }
        
        .sim-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dashed var(--line);
            font-size: 13.5px;
        }
        .sim-item:last-child {
            border-bottom: none;
        }
        .sim-item.total {
            font-weight: 700;
            font-size: 16px;
            color: var(--ink);
            border-top: 1px solid var(--line-strong);
            padding-top: 12px;
            margin-top: 8px;
        }
        .sim-item.points {
            color: var(--good);
            font-weight: 600;
        }
        
        /* Table styles */
        .report-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            margin-top: 10px;
        }
        .report-table th, .report-table td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid var(--line);
        }
        .report-table th {
            background: var(--surface-2);
            color: var(--ink-soft);
            font-weight: 600;
        }
        .report-table tr:hover {
            background: var(--surface-2);
        }
        
        .text-right {
            text-align: right;
        }
    </style>
</head>
<body class="textured">

    <%@ include file="/includes/staff-topbar.jsp" %>

    <main class="wrap staff-shell">
        <div class="card staff-hero" style="margin-bottom:20px">
            <p class="label">Phân tích cửa hàng</p>
            <h1 class="serif">Báo cáo & Thống kê CRM</h1>
            <p>Chào mừng bạn, <b><%= staff.getFullName() %></b>. Xem biểu đồ kinh doanh và giả lập chính sách tích điểm của quán.</p>
        </div>
        
        <div class="page-tabs">
            <button class="page-tab active" onclick="switchTab('tab-stats')">Báo cáo doanh thu</button>
            <button class="page-tab" onclick="switchTab('tab-sim')">Bộ tính Điểm &amp; Voucher</button>
        </div>
        
        <!-- TAP 1: BAO CAO DOANH THU & BIEU DO -->
        <div id="tab-stats" class="tab-content active">
            <div class="date-picker-row">
                <div class="group">
                    <label for="startDate">Từ ngày</label>
                    <input type="date" id="startDate">
                </div>
                <div class="group">
                    <label for="endDate">Đến ngày</label>
                    <input type="date" id="endDate">
                </div>
                <button class="btn btn-primary" onclick="loadStats()" style="padding: 8px 16px">Cập nhật</button>
            </div>
            
            <div class="kpi-row">
                <div class="kpi-card">
                    <p class="label">Tổng doanh thu</p>
                    <div class="num" id="kpiRevenue">0đ</div>
                </div>
                <div class="kpi-card">
                    <p class="label">Tổng đơn hàng</p>
                    <div class="num" id="kpiOrders">0</div>
                </div>
                <div class="kpi-card">
                    <p class="label">Đơn trung bình</p>
                    <div class="num" id="kpiAvgValue">0đ</div>
                </div>
                <div class="kpi-card">
                    <p class="label">Tổng thành viên</p>
                    <div class="num" id="kpiMembers">0</div>
                </div>
            </div>
            
            <div class="report-grid">
                <!-- Column 1: Charts & Tables -->
                <div>
                    <div class="chart-card">
                        <h4>Doanh thu &amp; Số lượng đơn hàng theo ngày</h4>
                        <div style="position:relative; height:300px; width:100%">
                            <canvas id="revenueChart"></canvas>
                        </div>
                    </div>
                    
                    <div class="chart-card">
                        <h4>Top 10 sản phẩm bán chạy nhất</h4>
                        <div style="position:relative; height:320px; width:100%">
                            <canvas id="productsChart"></canvas>
                        </div>
                    </div>
                    
                    <!-- Raw Data Tables in Tabs -->
                    <div class="chart-card">
                        <h4>Bảng số liệu chi tiết</h4>
                        <div class="tabs" style="margin-top: 10px; margin-bottom: 12px">
                            <button class="active" id="tabBtnDaily" onclick="switchTableTab('daily')">Theo ngày</button>
                            <button id="tabBtnProducts" onclick="switchTableTab('products')">Sản phẩm</button>
                            <button id="tabBtnTiers" onclick="switchTableTab('tiers')">Thành viên</button>
                        </div>
                        
                        <div id="tableDaily" style="overflow-x:auto">
                            <table class="report-table">
                                <thead>
                                    <tr>
                                        <th>Ngày</th>
                                        <th class="text-right">Số đơn</th>
                                        <th class="text-right">Tiền mặt</th>
                                        <th class="text-right">VietQR</th>
                                        <th class="text-right">Tổng doanh thu</th>
                                    </tr>
                                </thead>
                                <tbody id="tableDailyBody">
                                    <tr><td colspan="5" style="text-align:center">Đang tải...</td></tr>
                                </tbody>
                            </table>
                        </div>
                        
                        <div id="tableProducts" style="display:none; overflow-x:auto">
                            <table class="report-table">
                                <thead>
                                    <tr>
                                        <th>Sản phẩm</th>
                                        <th>Danh mục</th>
                                        <th class="text-right">Số lượng bán</th>
                                        <th class="text-right">Tổng doanh thu</th>
                                    </tr>
                                </thead>
                                <tbody id="tableProductsBody">
                                    <tr><td colspan="4" style="text-align:center">Đang tải...</td></tr>
                                </tbody>
                            </table>
                        </div>
                        
                        <div id="tableTiers" style="display:none; overflow-x:auto">
                            <table class="report-table">
                                <thead>
                                    <tr>
                                        <th>Hạng thành viên</th>
                                        <th class="text-right">Số lượng tài khoản</th>
                                    </tr>
                                </thead>
                                <tbody id="tableTiersBody">
                                    <tr><td colspan="2" style="text-align:center">Đang tải...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Column 2: Side Charts -->
                <div>
                    <div class="chart-card">
                        <h4>Nguồn đặt đơn hàng</h4>
                        <div style="position:relative; height:200px; width:100%; display:flex; justify-content:center">
                            <canvas id="sourceChart"></canvas>
                        </div>
                    </div>
                    
                    <div class="chart-card">
                        <h4>Phương thức thanh toán</h4>
                        <div style="position:relative; height:200px; width:100%; display:flex; justify-content:center">
                            <canvas id="paymentChart"></canvas>
                        </div>
                    </div>
                    
                    <div class="chart-card">
                        <h4>Tỷ lệ hạng thành viên</h4>
                        <div style="position:relative; height:200px; width:100%; display:flex; justify-content:center">
                            <canvas id="memberChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- TAP 2: BO TINH DIEM & VOUCHER SIMULATOR -->
        <div id="tab-sim" class="tab-content">
            <div class="card card-pad" style="margin-bottom: 20px; border-left: 4px solid var(--good)">
                <h3 class="serif" style="font-size:18px; margin-bottom:4px">Giả lập Tích lũy điểm &amp; Ưu đãi</h3>
                <p style="color:var(--ink-soft)">Nhập thông tin giả định để tính toán trước hóa đơn, điểm tích lũy và kiểm tra khả năng thăng hạng thành viên dựa trên chính sách của quán.</p>
            </div>
            
            <div class="sim-grid">
                <!-- Form Inputs -->
                <div class="card card-pad">
                    <h3 class="serif" style="font-size:16px; margin-bottom:15px; border-bottom:1px solid var(--line); padding-bottom:8px">Thông tin tính toán</h3>
                    
                    <form class="sim-form" onsubmit="event.preventDefault(); runSimulation();">
                        <div class="sim-form-group">
                            <label for="simStartingPoints">Điểm tích lũy hiện tại của khách</label>
                            <input type="number" id="simStartingPoints" class="field" value="0" min="0" placeholder="Ví dụ: 120">
                            <span class="label" style="font-size:10px; margin-top:2px">Bronze: 0-99, Silver: 100-499, Gold: 500+</span>
                        </div>
                        
                        <div class="sim-form-group">
                            <label for="simCartAmount">Tổng tiền giỏ hàng ban đầu (VND)</label>
                            <input type="number" id="simCartAmount" class="field" value="150000" min="0" step="1000" placeholder="Ví dụ: 250000">
                        </div>
                        
                        <div class="sim-form-group">
                            <label for="simVoucherCode">Mã Voucher (Nếu có)</label>
                            <input type="text" id="simVoucherCode" class="field" style="text-transform:uppercase" placeholder="Ví dụ: GIAM50K">
                            <span class="label" style="font-size:10px; margin-top:2px">Hệ thống sẽ kiểm tra hạn dùng &amp; điều kiện hạng trong DB.</span>
                        </div>
                        
                        <button type="submit" class="btn btn-primary btn-block" style="margin-top:10px">Tính toán kết quả</button>
                    </form>
                </div>
                
                <!-- Calculation Results -->
                <div class="sim-result-card" id="simResult" style="display:none">
                    <h3 class="serif" style="font-size:18px; margin-bottom:10px">Kết quả phân tích</h3>
                    
                    <div style="margin-bottom:15px">
                        <span class="label">Hạng bắt đầu:</span>
                        <b style="font-size:15px; color:var(--ink-soft)" id="resStartingTier">Bronze</b>
                        <span style="font-size:12px; color:var(--muted)" id="resStartingPoints">(0đ)</span>
                    </div>
                    
                    <div style="margin-bottom: 20px">
                        <h4 class="label" style="margin-bottom:8px; border-bottom:1px solid var(--line)">Chi tiết hóa đơn</h4>
                        <div class="sim-item">
                            <span>Giá trị giỏ hàng</span>
                            <span id="resCartAmount">0đ</span>
                        </div>
                        <div class="sim-item" style="color:var(--good)">
                            <span>Giảm hạng thành viên (<span id="resMemberDiscountPercent">0</span>%)</span>
                            <span id="resMemberDiscount">-0đ</span>
                        </div>
                        <div class="sim-item" style="color:var(--good)">
                            <span>Giảm giá Voucher (<span id="resVoucherCode">NONE</span>)</span>
                            <span id="resVoucherDiscount">-0đ</span>
                        </div>
                        <div class="sim-item" style="font-size:11px; color:var(--muted); padding-top:2px" id="resVoucherMsgRow">
                            <span id="resVoucherMsg" style="font-style:italic">Không sử dụng voucher</span>
                        </div>
                        <div class="sim-item total">
                            <span>Thành tiền thực trả</span>
                            <span id="resFinalAmount">0đ</span>
                        </div>
                    </div>
                    
                    <div>
                        <h4 class="label" style="margin-bottom:8px; border-bottom:1px solid var(--line)">Điểm &amp; Nâng hạng</h4>
                        <div class="sim-item points">
                            <span>Điểm tích lũy mới nhận</span>
                            <span id="resPointsEarned">+0 điểm</span>
                        </div>
                        <div class="sim-item">
                            <span>Tổng điểm tích lũy sau đơn</span>
                            <span id="resEndingPoints">0 điểm</span>
                        </div>
                        <div class="sim-item">
                            <span>Hạng thành viên mới</span>
                            <b style="color:var(--accent)" id="resEndingTier">Bronze</b>
                        </div>
                    </div>
                    
                    <!-- Progress Bar for Upgrading -->
                    <div class="progress-container">
                        <div class="progress-bar-bg">
                            <div class="progress-bar-fill" id="resProgressBar"></div>
                        </div>
                        <div class="progress-ticks">
                            <div class="progress-tick">
                                <span>Bronze</span>
                                <b>0 pts</b>
                            </div>
                            <div class="progress-tick">
                                <span>Silver</span>
                                <b>100 pts</b>
                            </div>
                            <div class="progress-tick">
                                <span>Gold</span>
                                <b>500 pts</b>
                            </div>
                        </div>
                    </div>
                    
                    <div class="alert-upgrade" id="upgradeAlert" style="display:none">
                        🎉 TUYỆT VỜI! KHÁCH HÀNG ĐÃ ĐỦ ĐIỂM THĂNG HẠNG LÊN <span id="upgradeTierName">GOLD</span>!
                    </div>
                </div>
                
                <!-- Placeholder when no calculation has been run -->
                <div class="card card-pad" id="simPlaceholder" style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding: 40px 20px; text-align:center">
                    <svg style="width: 48px; height: 48px; stroke: var(--muted); stroke-width: 1.5; fill: none; margin-bottom: 12px" viewBox="0 0 24 24">
                        <rect x="3" y="3" width="18" height="18" rx="2" />
                        <line x1="9" y1="9" x2="15" y2="9" />
                        <line x1="9" y1="13" x2="15" y2="13" />
                        <line x1="9" y1="17" x2="13" y2="17" />
                    </svg>
                    <h4 class="serif" style="font-size:16px; margin-bottom:6px">Chưa có kết quả giả lập</h4>
                    <p style="font-size:13px; color:var(--muted); max-width:280px">Nhập thông tin điểm và giỏ hàng bên trái rồi nhấn "Tính toán kết quả" để xem chi tiết.</p>
                </div>
            </div>
        </div>
        
        <p class="label" style="text-align:center; margin-top:40px; margin-bottom: 20px">nhà cà phê © 2026</p>
    </main>
    
    <script>
        // Global variables for Chart instances
        let revChartInstance = null;
        let prodChartInstance = null;
        let srcChartInstance = null;
        let payChartInstance = null;
        let memChartInstance = null;

        // On document load
        document.addEventListener("DOMContentLoaded", function() {
            // Set default dates
            const today = new Date();
            const past30Days = new Date();
            past30Days.setDate(today.getDate() - 30);
            
            document.getElementById('startDate').value = past30Days.toISOString().split('T')[0];
            document.getElementById('endDate').value = today.toISOString().split('T')[0];
            
            // Load dashboard data
            loadStats();
        });
        
        function formatVND(amount) {
            return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount).replace('₫', 'đ');
        }
        
        function switchTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.page-tab').forEach(b => b.classList.remove('active'));
            
            document.getElementById(tabId).classList.add('active');
            // Find button by onclick content
            document.querySelectorAll('.page-tab').forEach(b => {
                if (b.getAttribute('onclick').includes(tabId)) {
                    b.classList.add('active');
                }
            });
        }
        
        function switchTableTab(tableType) {
            document.getElementById('tableDaily').style.display = 'none';
            document.getElementById('tableProducts').style.display = 'none';
            document.getElementById('tableTiers').style.display = 'none';
            
            document.getElementById('tabBtnDaily').classList.remove('active');
            document.getElementById('tabBtnProducts').classList.remove('active');
            document.getElementById('tabBtnTiers').classList.remove('active');
            
            if (tableType === 'daily') {
                document.getElementById('tableDaily').style.display = 'block';
                document.getElementById('tabBtnDaily').classList.add('active');
            } else if (tableType === 'products') {
                document.getElementById('tableProducts').style.display = 'block';
                document.getElementById('tabBtnProducts').classList.add('active');
            } else if (tableType === 'tiers') {
                document.getElementById('tableTiers').style.display = 'block';
                document.getElementById('tabBtnTiers').classList.add('active');
            }
        }
        
        function loadStats() {
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;
            
            fetch(`<%= ctx %>/api/staff/reports?startDate=\${startDate}&endDate=\${endDate}`)
                .then(res => res.json())
                .then(data => {
                    if (data.ok) {
                        displayKPIs(data);
                        populateTables(data);
                        renderCharts(data);
                    } else {
                        alert("Không tải được dữ liệu báo cáo: " + data.message);
                    }
                })
                .catch(err => {
                    console.error("Error fetching report data", err);
                    alert("Lỗi kết nối khi tải số liệu báo cáo.");
                });
        }
        
        function displayKPIs(data) {
            // Calculate total revenue, orders, avg order value
            let totalRevenue = 0;
            let totalOrders = 0;
            data.dailyRevenue.forEach(d => {
                totalRevenue += d.totalRevenue;
                totalOrders += d.totalOrders;
            });
            
            let avgValue = totalOrders > 0 ? Math.round(totalRevenue / totalOrders) : 0;
            
            let totalMembers = 0;
            data.memberStats.forEach(m => {
                totalMembers += m.memberCount;
            });
            
            document.getElementById('kpiRevenue').innerText = formatVND(totalRevenue);
            document.getElementById('kpiOrders').innerText = totalOrders.toLocaleString('vi-VN');
            document.getElementById('kpiAvgValue').innerText = formatVND(avgValue);
            document.getElementById('kpiMembers').innerText = totalMembers.toLocaleString('vi-VN');
        }
        
        function populateTables(data) {
            // Daily Table
            const dailyBody = document.getElementById('tableDailyBody');
            dailyBody.innerHTML = '';
            if (data.dailyRevenue.length === 0) {
                dailyBody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--muted)">Không có đơn hàng nào trong khoảng thời gian này.</td></tr>';
            } else {
                data.dailyRevenue.forEach(r => {
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td>\${r.date}</td>
                        <td class="text-right">\${r.totalOrders.toLocaleString('vi-VN')}</td>
                        <td class="text-right">\${formatVND(r.cashRevenue)}</td>
                        <td class="text-right">\${formatVND(r.vietQrRevenue)}</td>
                        <td class="text-right" style="font-weight:600">\${formatVND(r.totalRevenue)}</td>
                    `;
                    dailyBody.appendChild(tr);
                });
            }
            
            // Products Table
            const productsBody = document.getElementById('tableProductsBody');
            productsBody.innerHTML = '';
            if (data.topProducts.length === 0) {
                productsBody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--muted)">Chưa có dữ liệu sản phẩm.</td></tr>';
            } else {
                data.topProducts.forEach(p => {
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td style="font-weight:600">\${p.productName}</td>
                        <td>\${p.categoryName}</td>
                        <td class="text-right">\${p.quantitySold.toLocaleString('vi-VN')}</td>
                        <td class="text-right">\${formatVND(p.totalRevenue)}</td>
                    `;
                    productsBody.appendChild(tr);
                });
            }
            
            // Tiers Table
            const tiersBody = document.getElementById('tableTiersBody');
            tiersBody.innerHTML = '';
            data.memberStats.forEach(m => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td style="font-weight:600">\${m.tierName}</td>
                    <td class="text-right">\${m.memberCount.toLocaleString('vi-VN')}</td>
                `;
                tiersBody.appendChild(tr);
            });
        }
        
        function renderCharts(data) {
            if (typeof Chart === 'undefined') {
                console.warn('Chart.js could not be loaded; tables are still available.');
                return;
            }

            // Color theme values
            const accentColor = '#b04528';
            const inkColor = '#241b10';
            const mutedColor = '#8d8170';
            const goodColor = '#4f7350';
            const warnColor = '#a3681c';
            const gridColor = '#e4dac4';

            // 1. REVENUE AND ORDERS CHART (Combo chart)
            const dates = data.dailyRevenue.map(d => d.date);
            const revenues = data.dailyRevenue.map(d => d.totalRevenue);
            const orders = data.dailyRevenue.map(d => d.totalOrders);
            
            if (revChartInstance) revChartInstance.destroy();
            revChartInstance = new Chart(document.getElementById('revenueChart'), {
                type: 'bar',
                data: {
                    labels: dates,
                    datasets: [
                        {
                            label: 'Doanh thu (VND)',
                            data: revenues,
                            type: 'line',
                            borderColor: accentColor,
                            backgroundColor: 'transparent',
                            borderWidth: 2.5,
                            tension: 0.15,
                            yAxisID: 'yRev'
                        },
                        {
                            label: 'Số đơn hàng',
                            data: orders,
                            backgroundColor: 'rgba(79, 115, 80, 0.25)',
                            borderColor: goodColor,
                            borderWidth: 1,
                            yAxisID: 'yOrd'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            grid: { display: false },
                            ticks: { font: { family: 'IBM Plex Mono', size: 10 } }
                        },
                        yRev: {
                            type: 'linear',
                            position: 'left',
                            grid: { color: gridColor },
                            ticks: { 
                                font: { family: 'IBM Plex Mono', size: 10 },
                                callback: val => (val / 1000) + 'k'
                            }
                        },
                        yOrd: {
                            type: 'linear',
                            position: 'right',
                            grid: { display: false },
                            ticks: { 
                                font: { family: 'IBM Plex Mono', size: 10 },
                                stepSize: 1
                            }
                        }
                    },
                    plugins: {
                        legend: { labels: { font: { family: 'IBM Plex Mono', size: 11 } } }
                    }
                }
            });

            // 2. TOP PRODUCTS CHART
            const prodNames = data.topProducts.map(p => p.productName);
            const prodQtys = data.topProducts.map(p => p.quantitySold);
            
            if (prodChartInstance) prodChartInstance.destroy();
            prodChartInstance = new Chart(document.getElementById('productsChart'), {
                type: 'bar',
                data: {
                    labels: prodNames,
                    datasets: [{
                        label: 'Số lượng đã bán',
                        data: prodQtys,
                        backgroundColor: '#8d8170',
                        hoverBackgroundColor: accentColor,
                        borderRadius: 5
                    }]
                },
                options: {
                    indexAxis: 'y',
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            grid: { color: gridColor },
                            ticks: { font: { family: 'IBM Plex Mono', size: 10 } }
                        },
                        y: {
                            grid: { display: false },
                            ticks: { font: { family: 'Playfair Display', size: 11 } }
                        }
                    },
                    plugins: {
                        legend: { display: false }
                    }
                }
            });

            // 3. ORDER SOURCE CHART (Pie/Donut)
            const srcNames = data.sourceStats.map(s => s.source);
            const srcRevenues = data.sourceStats.map(s => s.totalRevenue);
            
            if (srcChartInstance) srcChartInstance.destroy();
            srcChartInstance = new Chart(document.getElementById('sourceChart'), {
                type: 'doughnut',
                data: {
                    labels: srcNames,
                    datasets: [{
                        data: srcRevenues,
                        backgroundColor: [accentColor, goodColor, warnColor]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { font: { family: 'IBM Plex Mono', size: 10 } } }
                    }
                }
            });

            // 4. PAYMENT METHOD CHART (Pie)
            const payNames = data.paymentStats.map(p => p.paymentMethod);
            const payRevenues = data.paymentStats.map(p => p.totalRevenue);
            
            if (payChartInstance) payChartInstance.destroy();
            payChartInstance = new Chart(document.getElementById('paymentChart'), {
                type: 'pie',
                data: {
                    labels: payNames,
                    datasets: [{
                        data: payRevenues,
                        backgroundColor: ['#4f7350', '#a3681c']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { font: { family: 'IBM Plex Mono', size: 10 } } }
                    }
                }
            });

            // 5. MEMBER STATS (Doughnut)
            const memTiers = data.memberStats.map(m => m.tierName);
            const memCounts = data.memberStats.map(m => m.memberCount);
            
            if (memChartInstance) memChartInstance.destroy();
            memChartInstance = new Chart(document.getElementById('memberChart'), {
                type: 'doughnut',
                data: {
                    labels: memTiers,
                    datasets: [{
                        data: memCounts,
                        backgroundColor: ['#b45309', '#9ca3af', '#fbbf24'] // Bronze, Silver, Gold colors
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { font: { family: 'IBM Plex Mono', size: 10 } } }
                    }
                }
            });
        }
        
        function runSimulation() {
            const points = document.getElementById('simStartingPoints').value;
            const amount = document.getElementById('simCartAmount').value;
            const voucher = document.getElementById('simVoucherCode').value;
            
            fetch('<%= ctx %>/api/staff/calculate-sim', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `startingPoints=\${points}&cartAmount=\${amount}&voucherCode=\${voucher}`
            })
            .then(res => res.json())
            .then(data => {
                if (data.ok) {
                    displaySimResult(data);
                } else {
                    alert("Lỗi giả lập: " + data.message);
                }
            })
            .catch(err => {
                console.error("Sim error", err);
                alert("Lỗi kết nối khi chạy tính toán giả lập.");
            });
        }
        
        function displaySimResult(data) {
            document.getElementById('simPlaceholder').style.display = 'none';
            document.getElementById('simResult').style.display = 'block';
            
            // Set starting info
            document.getElementById('resStartingTier').innerText = data.startingTier;
            document.getElementById('resStartingPoints').innerText = `(\${data.startingPoints} điểm)`;
            
            // Invoice section
            document.getElementById('resCartAmount').innerText = formatVND(data.cartAmount);
            document.getElementById('resMemberDiscountPercent').innerText = data.memberDiscountPercent;
            document.getElementById('resMemberDiscount').innerText = `- \${formatVND(data.memberDiscount)}`;
            document.getElementById('resVoucherCode').innerText = data.voucherCode ? data.voucherCode.toUpperCase() : 'NONE';
            document.getElementById('resVoucherDiscount').innerText = `- \${formatVND(data.voucherDiscount)}`;
            
            // Voucher MSG
            const msgEl = document.getElementById('resVoucherMsg');
            if (data.voucherCode) {
                msgEl.innerText = data.voucherMessage;
                if (data.voucherValid) {
                    msgEl.style.color = 'var(--good)';
                } else {
                    msgEl.style.color = 'var(--danger)';
                }
            } else {
                msgEl.innerText = 'Không áp dụng voucher';
                msgEl.style.color = 'var(--muted)';
            }
            
            document.getElementById('resFinalAmount').innerText = formatVND(data.finalAmount);
            
            // Points Section
            document.getElementById('resPointsEarned').innerText = `+ \${data.pointsEarned} điểm`;
            document.getElementById('resEndingPoints').innerText = `\${data.endingPoints} điểm`;
            document.getElementById('resEndingTier').innerText = data.endingTier;
            
            // Progress Bar & Target calculation
            const progressFill = document.getElementById('resProgressBar');
            let percentage = 0;
            
            if (data.endingPoints >= 500) {
                percentage = 100;
            } else if (data.endingPoints >= 100) {
                // In Silver range: 100 -> 500 (represents 50% to 100% of visual bar)
                const silverProgress = (data.endingPoints - 100) / 400; // 0.0 to 1.0
                percentage = 50 + (silverProgress * 50);
            } else {
                // In Bronze range: 0 -> 100 (represents 0% to 50% of visual bar)
                const bronzeProgress = data.endingPoints / 100; // 0.0 to 1.0
                percentage = bronzeProgress * 50;
            }
            
            progressFill.style.width = `\${percentage}%`;
            
            // Upgrade alert
            const upgradeAlert = document.getElementById('upgradeAlert');
            if (data.upgraded) {
                document.getElementById('upgradeTierName').innerText = data.endingTier.toUpperCase();
                upgradeAlert.style.display = 'block';
            } else {
                upgradeAlert.style.display = 'none';
            }
        }
    </script>
</body>
</html>
