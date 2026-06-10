<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Staff, model.Product, model.Inventory, model.Recipe, java.util.List"%>
<%
    Staff staff = (Staff) session.getAttribute("staff");
    if (staff == null) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }
    String ctx = request.getContextPath();
    String pageTitle = "Quản lý Công thức — nhà cà phê";

    List<Product>   products    = (List<Product>)   request.getAttribute("products");
    List<Inventory> ingredients = (List<Inventory>) request.getAttribute("ingredients");
    Integer selPid       = (Integer) request.getAttribute("selectedProductId");
    Product selProduct   = (Product) request.getAttribute("selectedProduct");
    List<Recipe> curRecipe = (List<Recipe>) request.getAttribute("currentRecipe");
    String msg = (String) request.getAttribute("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/includes/head.jsp" %>
    <style>
        .admin-shell { padding: 24px 0 60px; }
        .page-hero { margin-bottom: 20px; }
        .page-hero h1 { font-size: 28px; margin-bottom: 4px; }
        .page-hero p  { color: var(--muted); font-size: 13px; }

        .recipe-layout { display: grid; grid-template-columns: 280px 1fr; gap: 20px; align-items: start; }

        /* ── product panel ── */
        .prod-panel { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; position: sticky; top: 80px; }
        .panel-head { padding: 14px 16px; background: var(--surface-2); border-bottom: 1px solid var(--line); }
        .panel-head h3 { font-size: 14px; }
        .prod-search { padding: 10px 12px; border-bottom: 1px solid var(--line); }
        .prod-search input { width: 100%; padding: 8px 10px; border: 1px solid var(--line-strong); border-radius: var(--radius-sm); font-family: var(--font-mono); font-size: 13px; outline: none; background: var(--surface); }
        .prod-search input:focus { border-color: var(--accent); }
        .prod-list { max-height: 500px; overflow-y: auto; }
        .prod-link { display: flex; align-items: center; gap: 10px; padding: 10px 14px; text-decoration: none; color: var(--ink-soft); border-bottom: 1px solid var(--line); transition: .12s; font-size: 13px; }
        .prod-link:hover { background: var(--surface-2); }
        .prod-link.selected { background: var(--accent-soft); border-left: 3px solid var(--accent); color: var(--ink); }
        .prod-initial { width: 34px; height: 34px; border-radius: 8px; background: linear-gradient(135deg,var(--surface-2),#efe3cc); border: 1px dashed var(--line-strong); display: flex; align-items: center; justify-content: center; font-family: var(--font-serif); font-size: 16px; color: var(--muted); flex-shrink: 0; }
        .prod-info .name  { font-size: 13px; font-weight: 600; color: var(--ink); }
        .prod-info .price { font-size: 11px; color: var(--muted); margin-top: 1px; }

        /* ── recipe editor ── */
        .recipe-editor { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow-soft); }
        .re-head { padding: 20px 24px; background: var(--surface-2); border-bottom: 1px solid var(--line); }
        .re-head h2 { font-size: 22px; margin-bottom: 4px; }
        .re-head p  { font-size: 13px; color: var(--muted); }
        .re-body { padding: 24px; }

        .info-strip { background: var(--accent-soft); border: 1px solid var(--accent); border-radius: var(--radius-sm); padding: 10px 14px; font-size: 12.5px; color: var(--accent-dark); margin-bottom: 20px; }

        .recipe-rows { display: flex; flex-direction: column; gap: 10px; margin-bottom: 16px; }
        .recipe-row { display: grid; grid-template-columns: 1fr 110px 44px 30px; gap: 10px; align-items: center; background: var(--surface-2); border: 1px solid var(--line); border-radius: var(--radius-sm); padding: 10px 14px; animation: fadein .2s; }
        @keyframes fadein { from { opacity:0; transform:translateY(-6px); } to { opacity:1; transform:none; } }
        .recipe-row select, .recipe-row input { padding: 7px 10px; border: 1px solid var(--line-strong); border-radius: var(--radius-sm); font-family: var(--font-mono); font-size: 13px; outline: none; background: var(--surface); width: 100%; }
        .recipe-row select:focus, .recipe-row input:focus { border-color: var(--accent); }
        .unit-tag { font-size: 11px; color: var(--muted); text-align: center; }
        .btn-remove { width: 28px; height: 28px; border: 1px solid var(--line-strong); border-radius: 6px; background: none; cursor: pointer; font-size: 14px; display: flex; align-items: center; justify-content: center; transition: .12s; color: var(--muted); }
        .btn-remove:hover { border-color: var(--danger); color: var(--danger); background: #f6e3e3; }

        .empty-recipe { background: var(--surface-2); border: 1px dashed var(--line-strong); border-radius: var(--radius-sm); padding: 28px; text-align: center; color: var(--muted); font-size: 13px; }

        .recipe-actions { display: flex; gap: 10px; flex-wrap: wrap; }
        .btn-add-row { border: 1px dashed var(--accent); background: transparent; color: var(--accent); padding: 9px 16px; border-radius: var(--radius-sm); font-family: var(--font-mono); font-size: 12px; letter-spacing: .1em; text-transform: uppercase; cursor: pointer; transition: .12s; }
        .btn-add-row:hover { background: var(--accent-soft); }

        .select-state { padding: 80px 40px; text-align: center; color: var(--muted); }
        .select-state .icon { font-size: 48px; margin-bottom: 14px; }
        .select-state h3 { font-size: 20px; color: var(--ink-soft); margin-bottom: 6px; }

        .page-alert { padding: 12px 16px; border-radius: var(--radius-sm); margin-bottom: 16px; font-size: 13px; display: flex; gap: 8px; animation: fadein .3s; }
        .alert-ok  { background: var(--good-soft); color: var(--good); border: 1px solid var(--good); }
        .alert-err { background: #f6e3e3; color: var(--danger); border: 1px solid var(--danger); }

        @media (max-width: 860px) {
            .recipe-layout { grid-template-columns: 1fr; }
            .prod-panel { position: static; }
            .prod-list { max-height: 260px; }
        }
    </style>
</head>
<body class="textured">
<%@ include file="/includes/staff-topbar.jsp" %>

<main class="wrap admin-shell">

    <div class="page-hero">
        <h1 class="serif">Quản lý Công thức (Recipes)</h1>
        <p>Định nghĩa nguyên liệu và định lượng cho từng sản phẩm — kho sẽ tự trừ khi đơn hoàn tất.</p>
    </div>

    <% if (msg != null && !msg.isEmpty()) { boolean ok = msg.contains("thành công"); %>
    <div class="page-alert <%= ok ? "alert-ok" : "alert-err" %>" id="pageAlert">
        <%= ok ? "✓" : "⚠" %> <%= msg %>
    </div>
    <% } %>

    <div class="recipe-layout">

        <!-- ── product list ── -->
        <div class="prod-panel">
            <div class="panel-head"><h3 class="serif">Chọn sản phẩm</h3></div>
            <div class="prod-search">
                <input type="text" id="prodSearch" placeholder="Tìm sản phẩm…" oninput="filterProd(this.value)">
            </div>
            <div class="prod-list" id="prodList">
                <% if (products != null) for (Product p : products) { %>
                <a class="prod-link <%= selPid != null && selPid == p.getProductId() ? "selected" : "" %>"
                   href="<%= ctx %>/recipe-management?productId=<%= p.getProductId() %>"
                   data-name="<%= p.getProductName().toLowerCase() %>">
                    <div class="prod-initial"><%= p.getProductName().charAt(0) %></div>
                    <div class="prod-info">
                        <div class="name"><%= p.getProductName() %></div>
                        <div class="price"><%= String.format("%,d", p.getPrice()) %> đ</div>
                    </div>
                </a>
                <% } %>
            </div>
        </div>

        <!-- ── recipe editor ── -->
        <div class="recipe-editor">
            <% if (selProduct == null) { %>
            <div class="select-state">
                <div class="icon">←</div>
                <h3 class="serif">Chọn một sản phẩm</h3>
                <p>Chọn sản phẩm bên trái để xem và chỉnh sửa công thức nguyên liệu.</p>
            </div>
            <% } else { %>
            <div class="re-head">
                <h2 class="serif"><%= selProduct.getProductName() %></h2>
                <p>Định lượng nguyên liệu cho 1 phần. Hệ thống tự trừ kho khi đơn hoàn tất.</p>
            </div>
            <div class="re-body">
                <div class="info-strip">
                    ℹ Khi đơn hàng chứa sản phẩm này được <strong>COMPLETED</strong>,
                    Auto-Deduction Engine sẽ tự trừ đúng định lượng bên dưới × số lượng đặt.
                </div>
                <form method="post" action="<%= ctx %>/recipe-management">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="productId" value="<%= selPid %>">

                    <div class="recipe-rows" id="recipeRows">
                        <% if (curRecipe == null || curRecipe.isEmpty()) { %>
                        <div class="empty-recipe" id="emptyRecipe">
                            Chưa có nguyên liệu. Nhấn "Thêm nguyên liệu" để bắt đầu.
                        </div>
                        <% } else { for (Recipe r : curRecipe) {
                            String ingUnit = "";
                            if (ingredients != null) for (Inventory inv : ingredients)
                                if (inv.getIngredientId() == r.getIngredientId()) { ingUnit = inv.getUnit(); break; }
                        %>
                        <div class="recipe-row">
                            <select name="ingredientId[]" onchange="updateUnit(this)" class="ing-select">
                                <option value="">— Chọn nguyên liệu —</option>
                                <% if (ingredients != null) for (Inventory inv : ingredients) { %>
                                <option value="<%= inv.getIngredientId() %>"
                                        data-unit="<%= inv.getUnit() %>"
                                        <%= inv.getIngredientId() == r.getIngredientId() ? "selected" : "" %>><%= inv.getIngredientName() %></option>
                                <% } %>
                            </select>
                            <input type="number" name="quantityNeeded[]" value="<%= r.getQuantityNeeded() %>" min="0.001" step="0.001" required>
                            <span class="unit-tag"><%= ingUnit %></span>
                            <button type="button" class="btn-remove" onclick="removeRow(this)">✕</button>
                        </div>
                        <% } } %>
                    </div>

                    <div class="recipe-actions">
                        <button type="button" class="btn-add-row" onclick="addRow()">+ Thêm nguyên liệu</button>
                        <button type="submit" class="btn btn-primary">Lưu công thức</button>
                    </div>
                </form>
            </div>
            <% } %>
        </div>

    </div>
</main>

<script>
    // Ingredient lookup for JS
    const ING = {<%
        if (ingredients != null) {
            boolean first = true;
            for (Inventory inv : ingredients) {
                if (!first) out.print(",");
                out.print(inv.getIngredientId() + ":{n:'" + inv.getIngredientName().replace("'","\\'") + "',u:'" + inv.getUnit() + "'}");
                first = false;
            }
        }
    %>};

    function buildSelect(selected) {
        let opts = '<option value="">— Chọn nguyên liệu —</option>';
        for (const [id, d] of Object.entries(ING))
            opts += `<option value="${id}" data-unit="${d.u}"${id==selected?' selected':''}>${d.n}</option>`;
        return opts;
    }

    function addRow() {
        const empty = document.getElementById('emptyRecipe');
        if (empty) empty.remove();
        const rows = document.getElementById('recipeRows');
        const div = document.createElement('div');
        div.className = 'recipe-row';
        div.innerHTML = `
            <select name="ingredientId[]" onchange="updateUnit(this)" class="ing-select">${buildSelect(null)}</select>
            <input type="number" name="quantityNeeded[]" min="0.001" step="0.001" required placeholder="0">
            <span class="unit-tag">—</span>
            <button type="button" class="btn-remove" onclick="removeRow(this)">✕</button>`;
        rows.appendChild(div);
    }

    function removeRow(btn) {
        btn.closest('.recipe-row').remove();
        if (!document.querySelectorAll('.recipe-row').length) {
            const d = document.createElement('div');
            d.className = 'empty-recipe'; d.id = 'emptyRecipe';
            d.textContent = 'Chưa có nguyên liệu. Nhấn "Thêm nguyên liệu" để bắt đầu.';
            document.getElementById('recipeRows').appendChild(d);
        }
    }

    function updateUnit(sel) {
        const opt = sel.options[sel.selectedIndex];
        sel.closest('.recipe-row').querySelector('.unit-tag').textContent = opt.dataset.unit || '—';
    }

    function filterProd(q) {
        document.querySelectorAll('.prod-link').forEach(a => {
            a.style.display = a.dataset.name.includes(q.toLowerCase()) ? '' : 'none';
        });
    }

    const alert = document.getElementById('pageAlert');
    if (alert) setTimeout(() => { alert.style.opacity='0'; alert.style.transition='.4s'; setTimeout(()=>alert.remove(),400); }, 4000);
</script>
</body>
</html>
