<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Staff, model.Inventory, java.util.List"%>
<%
    Staff staff = (Staff) session.getAttribute("staff");
    if (staff == null) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }
    String ctx = request.getContextPath();
    String pageTitle = "Quản lý Kho — nhà cà phê";

    List<Inventory> ingredients  = (List<Inventory>) request.getAttribute("ingredients");
    List<Inventory> lowStockList = (List<Inventory>) request.getAttribute("lowStockList");
    int lowStockCount = request.getAttribute("lowStockCount") != null
                        ? (int) request.getAttribute("lowStockCount") : 0;
    String msg = (String) request.getAttribute("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
    <style>
        .admin-shell { padding: 24px 0 60px; }
        .page-hero { margin-bottom: 24px; }
        .page-hero h1 { font-size: 28px; margin-bottom: 4px; }
        .page-hero p  { color: var(--muted); font-size: 13px; }

        .stat-bar { display: grid; grid-template-columns: repeat(4,1fr); gap: 12px; margin-bottom: 20px; }
        .stat-item { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 16px 18px; }
        .stat-item .num  { font-family: var(--font-serif); font-size: 26px; }
        .stat-item .lbl  { font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); margin-top: 2px; }
        .stat-item.danger .num { color: var(--danger); }
        .stat-item.good   .num { color: var(--good); }

        .low-banner { border: 1px solid var(--danger); background: #f6e3e3; border-radius: var(--radius); padding: 14px 18px; margin-bottom: 20px; display: flex; gap: 12px; align-items: flex-start; }
        .low-banner h4 { color: var(--danger); font-size: 14px; margin-bottom: 6px; }
        .low-tags { display: flex; flex-wrap: wrap; gap: 6px; }
        .low-tag { font-size: 11px; border: 1px solid var(--danger); color: var(--danger); border-radius: 5px; padding: 2px 9px; }

        .toolbar { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-bottom: 16px; }

        .data-table-wrap { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow-soft); }
        .dt-head { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--line); }
        .dt-head h3 { font-size: 15px; }
        table { width: 100%; border-collapse: collapse; }
        thead tr { background: var(--surface-2); }
        th { padding: 11px 16px; text-align: left; font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); border-bottom: 1px solid var(--line); }
        td { padding: 13px 16px; font-size: 13.5px; border-bottom: 1px solid var(--line); vertical-align: middle; color: var(--ink-soft); }
        tr:last-child td { border-bottom: none; }
        tbody tr:hover td { background: var(--surface-2); }

        .stock-cell { min-width: 160px; }
        .stock-wrap { display: flex; align-items: center; gap: 8px; }
        .stock-num  { font-weight: 700; font-size: 14px; min-width: 56px; }
        .prog-bar   { flex: 1; height: 6px; background: var(--line); border-radius: 3px; overflow: hidden; }
        .prog-fill  { height: 100%; border-radius: 3px; transition: width .4s; }
        .prog-ok       { background: var(--good); }
        .prog-warn     { background: var(--warn); }
        .prog-critical { background: var(--danger); }

        .status-badge { display: inline-block; font-size: 10px; letter-spacing: .1em; text-transform: uppercase; border-radius: 5px; padding: 3px 9px; border: 1px solid; }
        .s-ok   { color: var(--good);   border-color: var(--good);   background: var(--good-soft); }
        .s-low  { color: var(--warn);   border-color: var(--warn);   background: var(--warn-soft); }
        .s-crit { color: var(--danger); border-color: var(--danger); background: #f6e3e3; }

        .row-actions { display: flex; gap: 6px; }
        .btn-sm { padding: 6px 12px; font-size: 11px; border-radius: var(--radius-sm); }
        .empty-row td { text-align: center; padding: 48px; color: var(--muted); }

        .page-alert { padding: 12px 16px; border-radius: var(--radius-sm); margin-bottom: 16px; font-size: 13px; display: flex; gap: 8px; animation: fadein .3s; }
        .alert-ok  { background: var(--good-soft); color: var(--good); border: 1px solid var(--good); }
        .alert-err { background: #f6e3e3; color: var(--danger); border: 1px solid var(--danger); }
        @keyframes fadein { from { opacity:0; transform:translateY(-6px); } to { opacity:1; transform:none; } }

        .drawer-overlay { position:fixed; inset:0; z-index:100; background:rgba(36,27,16,.5); display:none; align-items:center; justify-content:center; }
        .drawer-overlay.open { display:flex; }
        .drawer { background:var(--surface); border-radius:var(--radius); padding:28px; width:100%; max-width:460px; box-shadow:0 24px 60px rgba(0,0,0,.18); animation:slide-up .25s ease; }
        .drawer h3 { font-size: 22px; margin-bottom: 20px; }
        .frow { margin-bottom: 14px; }
        .frow label { display: block; font-size: 12px; letter-spacing: .1em; text-transform: uppercase; color: var(--muted); margin-bottom: 5px; }
        .frow .field { width: 100%; }
        .frow-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .drawer-foot { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }
        .restock-info { background: var(--good-soft); border: 1px solid var(--good); border-radius: var(--radius-sm); padding: 12px 14px; margin-bottom: 16px; font-size: 13px; color: var(--good); }

        @media (max-width:900px) { .stat-bar { grid-template-columns: repeat(2,1fr); } }
        @media (max-width:600px) { .stat-bar { grid-template-columns: 1fr; } }
    </style>
</head>
<body class="textured">
<%@ include file="/includes/staff-topbar.jsp" %>

<main class="wrap admin-shell">

    <div class="page-hero">
        <h1 class="serif">Quản lý Kho Nguyên liệu</h1>
        <p>Theo dõi tồn kho, nhập hàng và nhận cảnh báo khi nguyên liệu sắp hết.</p>
    </div>

    <% if (msg != null && !msg.isEmpty()) { boolean ok = msg.contains("thành công"); %>
    <div class="page-alert <%= ok ? "alert-ok" : "alert-err" %>" id="pageAlert">
        <%= ok ? "✓" : "⚠" %> <%= msg %>
    </div>
    <% } %>

    <div class="stat-bar">
        <div class="stat-item">
            <div class="num"><%= ingredients != null ? ingredients.size() : 0 %></div>
            <div class="lbl">Tổng nguyên liệu</div>
        </div>
        <div class="stat-item <%= lowStockCount > 0 ? "danger" : "" %>">
            <div class="num"><%= lowStockCount %></div>
            <div class="lbl">Sắp hết hàng</div>
        </div>
        <div class="stat-item good">
            <div class="num"><%= ingredients != null ? ingredients.size() - lowStockCount : 0 %></div>
            <div class="lbl">Đủ hàng</div>
        </div>
        <div class="stat-item">
            <div class="num"><%
                int total = ingredients != null && !ingredients.isEmpty() ? ingredients.size() : 1;
                out.print(String.format("%.0f%%", (double)lowStockCount / total * 100));
            %></div>
            <div class="lbl">Tỷ lệ cần nhập</div>
        </div>
    </div>

    <% if (lowStockCount > 0 && lowStockList != null && !lowStockList.isEmpty()) { %>
    <div class="low-banner">
        <span style="font-size:22px;">🚨</span>
        <div>
            <h4><%= lowStockCount %> nguyên liệu sắp hết — cần nhập kho ngay!</h4>
            <div class="low-tags">
                <% for (Inventory inv : lowStockList) { %>
                <span class="low-tag"><%= inv.getIngredientName() %> (<%= String.format("%.1f", inv.getStockQuantity()) %> <%= inv.getUnit() %>)</span>
                <% } %>
            </div>
        </div>
    </div>
    <% } %>

    <div class="toolbar">
        <button class="btn btn-primary" onclick="openDrawer('createIngDrawer')">+ Thêm nguyên liệu</button>
    </div>

    <div class="data-table-wrap">
        <div class="dt-head">
            <h3 class="serif">Danh sách nguyên liệu (<%= ingredients != null ? ingredients.size() : 0 %>)</h3>
        </div>
        <table>
            <thead>
                <tr><th>#</th><th>Tên nguyên liệu</th><th>Tồn kho</th><th>Mức tối thiểu</th><th>Trạng thái</th><th>Thao tác</th></tr>
            </thead>
            <tbody>
            <% if (ingredients == null || ingredients.isEmpty()) { %>
            <tr class="empty-row"><td colspan="6">Chưa có nguyên liệu nào trong kho.</td></tr>
            <% } else { for (Inventory inv : ingredients) {
                double pct = inv.getMinStockLevel() > 0
                    ? Math.min(100, inv.getStockQuantity() / inv.getMinStockLevel() * 100) : 100;
                String progClass = pct >= 100 ? "prog-ok" : (pct >= 50 ? "prog-warn" : "prog-critical");
                String sClass    = pct >= 100 ? "s-ok"    : (pct >= 50 ? "s-low"     : "s-crit");
                String sLabel    = pct >= 100 ? "đủ hàng" : (pct >= 50 ? "sắp hết"   : "hết hàng");
            %>
            <tr>
                <td style="color:var(--muted);">#<%= inv.getIngredientId() %></td>
                <td style="font-weight:600;color:var(--ink);"><%= inv.getIngredientName() %></td>
                <td class="stock-cell">
                    <div class="stock-wrap">
                        <span class="stock-num"><%= String.format("%.1f", inv.getStockQuantity()) %>
                            <span style="font-size:11px;color:var(--muted);font-weight:400;"><%= inv.getUnit() %></span>
                        </span>
                        <div class="prog-bar"><div class="prog-fill <%= progClass %>" style="width:<%= (int)Math.min(100,pct) %>%"></div></div>
                    </div>
                </td>
                <td><%= String.format("%.1f", inv.getMinStockLevel()) %> <%= inv.getUnit() %></td>
                <td><span class="status-badge <%= sClass %>"><%= sLabel %></span></td>
                <td>
                    <div class="row-actions">
                        <button class="btn btn-sm" style="color:var(--good);border-color:var(--good);"
                            onclick="openRestockDrawer(<%= inv.getIngredientId() %>,'<%= inv.getIngredientName().replace("'","\\'") %>','<%= inv.getUnit() %>',<%= inv.getStockQuantity() %>)">Nhập kho</button>
                        <button class="btn btn-ghost btn-sm"
                            onclick="openEditDrawer(<%= inv.getIngredientId() %>,'<%= inv.getIngredientName().replace("'","\\'") %>',<%= inv.getMinStockLevel() %>,'<%= inv.getUnit() %>')">Sửa</button>
                    </div>
                </td>
            </tr>
            <% } } %>
            </tbody>
        </table>
    </div>

</main>

<!-- ══ DRAWER: Thêm nguyên liệu ══ -->
<div class="drawer-overlay" id="createIngDrawer">
    <div class="drawer">
        <h3 class="serif">Thêm nguyên liệu</h3>
        <form method="post" action="<%= ctx %>/inventory-management">
            <input type="hidden" name="action" value="create">
            <div class="frow">
                <label>Tên nguyên liệu *</label>
                <input class="field" type="text" name="ingredientName" required placeholder="Hạt cà phê Arabica…">
            </div>
            <div class="frow-2">
                <div class="frow">
                    <label>Tồn kho ban đầu</label>
                    <input class="field" type="number" name="stockQuantity" value="0" min="0" step="0.01">
                </div>
                <div class="frow">
                    <label>Mức tối thiểu *</label>
                    <input class="field" type="number" name="minStockLevel" required min="0" step="0.01" placeholder="100">
                </div>
            </div>
            <div class="frow">
                <label>Đơn vị tính *</label>
                <input class="field" type="text" name="unit" required placeholder="gram, ml, kg, lít…">
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('createIngDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Thêm</button>
            </div>
        </form>
    </div>
</div>

<!-- ══ DRAWER: Sửa nguyên liệu ══ -->
<div class="drawer-overlay" id="editIngDrawer">
    <div class="drawer">
        <h3 class="serif">Chỉnh sửa nguyên liệu</h3>
        <form method="post" action="<%= ctx %>/inventory-management">
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="ingredientId" id="ei-id">
            <div class="frow">
                <label>Tên nguyên liệu *</label>
                <input class="field" type="text" name="ingredientName" id="ei-name" required>
            </div>
            <div class="frow-2">
                <div class="frow">
                    <label>Mức tối thiểu *</label>
                    <input class="field" type="number" name="minStockLevel" id="ei-min" required min="0" step="0.01">
                </div>
                <div class="frow">
                    <label>Đơn vị tính *</label>
                    <input class="field" type="text" name="unit" id="ei-unit" required>
                </div>
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('editIngDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Lưu</button>
            </div>
        </form>
    </div>
</div>

<!-- ══ DRAWER: Nhập kho ══ -->
<div class="drawer-overlay" id="restockDrawer">
    <div class="drawer">
        <h3 class="serif">Nhập kho</h3>
        <div class="restock-info" id="restock-info"></div>
        <form method="post" action="<%= ctx %>/inventory-management">
            <input type="hidden" name="action" value="restock">
            <input type="hidden" name="ingredientId" id="rs-id">
            <div class="frow">
                <label id="rs-qty-label">Số lượng nhập thêm *</label>
                <input class="field" type="number" name="quantity" required min="0.01" step="0.01" placeholder="0">
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('restockDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Xác nhận nhập kho</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openDrawer(id)  { document.getElementById(id).classList.add('open'); }
    function closeDrawer(id) { document.getElementById(id).classList.remove('open'); }
    document.querySelectorAll('.drawer-overlay').forEach(el => {
        el.addEventListener('click', e => { if (e.target === el) el.classList.remove('open'); });
    });

    function openEditDrawer(id, name, minStock, unit) {
        document.getElementById('ei-id').value   = id;
        document.getElementById('ei-name').value = name;
        document.getElementById('ei-min').value  = minStock;
        document.getElementById('ei-unit').value = unit;
        openDrawer('editIngDrawer');
    }

    function openRestockDrawer(id, name, unit, current) {
        document.getElementById('rs-id').value = id;
        document.getElementById('rs-qty-label').textContent = `Số lượng nhập thêm (${unit}) *`;
        document.getElementById('restock-info').innerHTML =
            `<strong>${name}</strong> — tồn kho hiện tại: <strong>${parseFloat(current).toFixed(1)} ${unit}</strong>`;
        openDrawer('restockDrawer');
    }

    const alert = document.getElementById('pageAlert');
    if (alert) setTimeout(() => { alert.style.opacity='0'; alert.style.transition='.4s'; setTimeout(()=>alert.remove(),400); }, 4000);
</script>
</body>
</html>
