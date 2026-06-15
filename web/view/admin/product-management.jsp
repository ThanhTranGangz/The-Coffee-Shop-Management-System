<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Staff, model.Product, model.Category, java.util.List"%>
<%
    Staff staff = (Staff) session.getAttribute("staff");
    if (staff == null) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }
    String ctx = request.getContextPath();
    String pageTitle = "Quản lý Sản phẩm — nhà cà phê";

    List<Product>  products   = (List<Product>)  request.getAttribute("products");
    List<Category> categories = (List<Category>) request.getAttribute("categories");
    String keyword   = (String)  request.getAttribute("keyword");
    int    selCat    = request.getAttribute("selectedCategory") != null
                       ? (int) request.getAttribute("selectedCategory") : 0;
    String msg       = (String) request.getAttribute("msg");
    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "products";
    if (keyword == null) keyword = "";

    int totalActive = 0;
    if (products != null) for (Product p : products) if (p.isStatus()) totalActive++;
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

        .stat-bar { display: grid; grid-template-columns: repeat(3,1fr); gap: 12px; margin-bottom: 24px; }
        .stat-item { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 16px 18px; }
        .stat-item .num  { font-family: var(--font-serif); font-size: 26px; color: var(--ink); }
        .stat-item .lbl  { font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); margin-top: 2px; }

        .page-tabs { display: flex; gap: 4px; background: var(--surface-2); border: 1px solid var(--line); border-radius: var(--radius-sm); padding: 4px; width: fit-content; margin-bottom: 20px; }
        .page-tab  { padding: 8px 20px; border-radius: 8px; border: none; background: transparent; font-family: var(--font-mono); font-size: 12px; letter-spacing: .1em; text-transform: uppercase; color: var(--muted); cursor: pointer; transition: .15s; }
        .page-tab.active { background: var(--ink); color: var(--surface); }

        .toolbar { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-bottom: 16px; }
        .toolbar .field { padding: 9px 12px; border-radius: var(--radius-sm); min-width: 200px; }
        .toolbar select.field { flex-shrink: 0; min-width: 160px; }

        .data-table-wrap { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow-soft); }
        .dt-head { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--line); }
        .dt-head h3 { font-size: 15px; }
        table { width: 100%; border-collapse: collapse; }
        thead tr { background: var(--surface-2); }
        th { padding: 11px 16px; text-align: left; font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); font-weight: 600; border-bottom: 1px solid var(--line); }
        td { padding: 13px 16px; font-size: 13.5px; border-bottom: 1px solid var(--line); vertical-align: middle; color: var(--ink-soft); }
        tr:last-child td { border-bottom: none; }
        tbody tr:hover td { background: var(--surface-2); }

        .prod-cell { display: flex; align-items: center; gap: 10px; }
        .prod-thumb { width: 40px; height: 40px; border-radius: 8px; object-fit: cover; border: 1px solid var(--line); }
        .prod-initial { width: 40px; height: 40px; border-radius: 8px; background: linear-gradient(135deg,var(--surface-2),#efe3cc); border: 1px dashed var(--line-strong); display: flex; align-items: center; justify-content: center; font-family: var(--font-serif); font-size: 18px; color: var(--muted); flex-shrink: 0; }
        .prod-name { font-weight: 600; color: var(--ink); font-size: 14px; }
        .prod-id   { font-size: 11px; color: var(--muted); }
        .price-val { font-weight: 700; color: var(--accent-dark); }

        .status-badge { display: inline-block; font-size: 10px; letter-spacing: .1em; text-transform: uppercase; border-radius: 5px; padding: 3px 9px; border: 1px solid; }
        .s-on  { color: var(--good); border-color: var(--good); background: var(--good-soft); }
        .s-off { color: var(--muted); border-color: var(--line-strong); background: var(--surface-2); }

        .row-actions { display: flex; gap: 6px; }
        .btn-sm { padding: 6px 12px; font-size: 11px; border-radius: var(--radius-sm); }

        .empty-row td { text-align: center; padding: 48px; color: var(--muted); font-size: 14px; }

        .page-alert { padding: 12px 16px; border-radius: var(--radius-sm); margin-bottom: 16px; font-size: 13px; display: flex; align-items: center; gap: 8px; animation: fadein .3s; }
        .alert-ok  { background: var(--good-soft); color: var(--good); border: 1px solid var(--good); }
        .alert-err { background: #f6e3e3; color: var(--danger); border: 1px solid var(--danger); }
        @keyframes fadein { from { opacity:0; transform:translateY(-6px); } to { opacity:1; transform:none; } }

        .drawer-overlay { position:fixed; inset:0; z-index:100; background:rgba(36,27,16,.5); display:none; align-items:center; justify-content:center; }
        .drawer-overlay.open { display:flex; }
        .drawer { background:var(--surface); border-radius:var(--radius); padding:28px; width:100%; max-width:480px; box-shadow:0 24px 60px rgba(0,0,0,.18); animation:slide-up .25s ease; max-height:90vh; overflow-y:auto; }
        .drawer h3 { font-size: 22px; margin-bottom: 20px; }
        .frow { margin-bottom: 14px; }
        .frow label { display: block; font-size: 12px; letter-spacing: .1em; text-transform: uppercase; color: var(--muted); margin-bottom: 5px; }
        .frow .field { width: 100%; }
        .frow-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .drawer-foot { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }

        @media (max-width:720px) { .stat-bar { grid-template-columns: 1fr 1fr; } .toolbar { flex-direction:column; align-items:stretch; } }
    </style>
</head>
<body class="textured">
<%@ include file="/includes/staff-topbar.jsp" %>

<main class="wrap admin-shell">

    <div class="page-hero">
        <h1 class="serif">Quản lý Sản phẩm &amp; Menu</h1>
        <p>Quản lý danh mục, sản phẩm, giá bán và trạng thái hiển thị trên menu.</p>
    </div>

    <% if (msg != null && !msg.isEmpty()) { boolean ok = msg.contains("thành công"); %>
    <div class="page-alert <%= ok ? "alert-ok" : "alert-err" %>" id="pageAlert">
        <%= ok ? "✓" : "⚠" %> <%= msg %>
    </div>
    <% } %>

    <div class="stat-bar">
        <div class="stat-item">
            <div class="num"><%= products != null ? products.size() : 0 %></div>
            <div class="lbl">Tổng sản phẩm</div>
        </div>
        <div class="stat-item">
            <div class="num"><%= totalActive %></div>
            <div class="lbl">Đang hiển thị</div>
        </div>
        <div class="stat-item">
            <div class="num"><%= categories != null ? categories.size() : 0 %></div>
            <div class="lbl">Danh mục</div>
        </div>
    </div>

    <div class="page-tabs">
        <button class="page-tab <%= !"categories".equals(activeTab) ? "active" : "" %>" onclick="switchTab('products',this)">Sản phẩm</button>
        <button class="page-tab <%= "categories".equals(activeTab) ? "active" : "" %>"  onclick="switchTab('categories',this)">Danh mục</button>
    </div>

    <!-- ══ TAB: PRODUCTS ══ -->
    <div id="panel-products" style="<%= "categories".equals(activeTab) ? "display:none" : "" %>">
        <div class="toolbar">
            <form method="get" action="<%= ctx %>/product-management" style="display:contents;">
                <input class="field" type="text" name="keyword" placeholder="Tìm tên sản phẩm…" value="<%= keyword %>">
                <select class="field" name="categoryId">
                    <option value="0">Tất cả danh mục</option>
                    <% if (categories != null) for (Category c : categories) { %>
                    <option value="<%= c.getCategoryId() %>" <%= c.getCategoryId() == selCat ? "selected" : "" %>><%= c.getCategoryName() %></option>
                    <% } %>
                </select>
                <button class="btn" type="submit">Lọc</button>
                <a class="btn btn-ghost" href="<%= ctx %>/product-management">Xóa lọc</a>
            </form>
            <button class="btn btn-primary" onclick="openDrawer('createProductDrawer')">+ Thêm sản phẩm</button>
        </div>

        <div class="data-table-wrap">
            <div class="dt-head">
                <h3 class="serif">Danh sách sản phẩm (<%= products != null ? products.size() : 0 %>)</h3>
            </div>
            <table>
                <thead><tr><th>Sản phẩm</th><th>Danh mục</th><th>Giá bán</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
                <tbody>
                <% if (products == null || products.isEmpty()) { %>
                <tr class="empty-row"><td colspan="5">Chưa có sản phẩm nào.</td></tr>
                <% } else { for (Product p : products) {
                    String catName = "";
                    if (categories != null) for (Category c : categories)
                        if (c.getCategoryId() == p.getCategoryId()) { catName = c.getCategoryName(); break; }
                %>
                <tr>
                    <td>
                        <div class="prod-cell">
                            <% if (p.getImageUrl() != null && !p.getImageUrl().isEmpty()) { %>
                            <img class="prod-thumb" src="<%= p.getImageUrl() %>" alt="" onerror="this.style.display='none'">
                            <% } else { %>
                            <div class="prod-initial"><%= p.getProductName().charAt(0) %></div>
                            <% } %>
                            <div>
                                <div class="prod-name"><%= p.getProductName() %></div>
                                <div class="prod-id">#<%= p.getProductId() %></div>
                            </div>
                        </div>
                    </td>
                    <td><%= catName.isEmpty() ? "—" : catName %></td>
                    <td class="price-val"><%= String.format("%,d", p.getPrice()) %> đ</td>
                    <td><span class="status-badge <%= p.isStatus() ? "s-on" : "s-off" %>"><%= p.isStatus() ? "hiển thị" : "ẩn" %></span></td>
                    <td>
                        <div class="row-actions">
                            <button class="btn btn-sm" onclick="openEditProduct(<%= p.getProductId() %>,'<%= p.getProductName().replace("'","\\'") %>',<%= p.getPrice() %>,'<%= p.getImageUrl()!=null?p.getImageUrl():"" %>',<%= p.isStatus()?1:0 %>,<%= p.getCategoryId() %>)">Sửa</button>
                            <form method="post" action="<%= ctx %>/product-management" style="display:inline;">
                                <input type="hidden" name="action" value="toggle">
                                <input type="hidden" name="productId" value="<%= p.getProductId() %>">
                                <button class="btn btn-ghost btn-sm" type="submit"><%= p.isStatus() ? "Ẩn" : "Hiện" %></button>
                            </form>
                            <form method="post" action="<%= ctx %>/product-management" style="display:inline;"
                                  onsubmit="return confirm('Xóa sản phẩm này?')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="productId" value="<%= p.getProductId() %>">
                                <button class="btn btn-sm" style="color:var(--danger);border-color:var(--danger);" type="submit">Xóa</button>
                            </form>
                        </div>
                    </td>
                </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ══ TAB: CATEGORIES ══ -->
    <div id="panel-categories" style="<%= !"categories".equals(activeTab) ? "display:none" : "" %>">
        <div class="toolbar">
            <button class="btn btn-primary" onclick="openDrawer('createCategoryDrawer')">+ Thêm danh mục</button>
        </div>
        <div class="data-table-wrap">
            <div class="dt-head"><h3 class="serif">Danh mục (<%= categories != null ? categories.size() : 0 %>)</h3></div>
            <table>
                <thead><tr><th>#</th><th>Tên danh mục</th><th>Thao tác</th></tr></thead>
                <tbody>
                <% if (categories == null || categories.isEmpty()) { %>
                <tr class="empty-row"><td colspan="3">Chưa có danh mục.</td></tr>
                <% } else { for (Category c : categories) { %>
                <tr>
                    <td style="color:var(--muted);">#<%= c.getCategoryId() %></td>
                    <td style="font-weight:600;color:var(--ink);"><%= c.getCategoryName() %></td>
                    <td>
                        <div class="row-actions">
                            <button class="btn btn-sm" onclick="openEditCategory(<%= c.getCategoryId() %>,'<%= c.getCategoryName().replace("'","\\'") %>')">Sửa</button>
                            <form method="post" action="<%= ctx %>/category-management" style="display:inline;"
                                  onsubmit="return confirm('Xóa danh mục này?')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="categoryId" value="<%= c.getCategoryId() %>">
                                <button class="btn btn-sm" style="color:var(--danger);border-color:var(--danger);" type="submit">Xóa</button>
                            </form>
                        </div>
                    </td>
                </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>

</main>

<!-- ══ DRAWER: Thêm sản phẩm ══ -->
<div class="drawer-overlay" id="createProductDrawer">
    <div class="drawer">
        <h3 class="serif">Thêm sản phẩm mới</h3>
        <form method="post" action="<%= ctx %>/product-management">
            <input type="hidden" name="action" value="create">
            <div class="frow">
                <label>Tên sản phẩm *</label>
                <input class="field" type="text" name="productName" required placeholder="Cà phê đen, Trà sữa…">
            </div>
            <div class="frow-2">
                <div class="frow">
                    <label>Giá bán (đ) *</label>
                    <input class="field" type="number" name="price" required min="0" placeholder="35000">
                </div>
                <div class="frow">
                    <label>Danh mục *</label>
                    <select class="field" name="categoryId" required>
                        <% if (categories != null) for (Category c : categories) { %>
                        <option value="<%= c.getCategoryId() %>"><%= c.getCategoryName() %></option>
                        <% } %>
                    </select>
                </div>
            </div>
            <div class="frow">
                <label>URL ảnh</label>
                <input class="field" type="text" name="imageUrl" placeholder="https://…">
            </div>
            <div class="frow">
                <label>Trạng thái</label>
                <select class="field" name="status">
                    <option value="1">Hiển thị trên menu</option>
                    <option value="0">Ẩn</option>
                </select>
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('createProductDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Thêm sản phẩm</button>
            </div>
        </form>
    </div>
</div>

<!-- ══ DRAWER: Sửa sản phẩm ══ -->
<div class="drawer-overlay" id="editProductDrawer">
    <div class="drawer">
        <h3 class="serif">Chỉnh sửa sản phẩm</h3>
        <form method="post" action="<%= ctx %>/product-management">
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="productId" id="ep-id">
            <div class="frow">
                <label>Tên sản phẩm *</label>
                <input class="field" type="text" name="productName" id="ep-name" required>
            </div>
            <div class="frow-2">
                <div class="frow">
                    <label>Giá bán (đ) *</label>
                    <input class="field" type="number" name="price" id="ep-price" required min="0">
                </div>
                <div class="frow">
                    <label>Danh mục *</label>
                    <select class="field" name="categoryId" id="ep-cat" required>
                        <% if (categories != null) for (Category c : categories) { %>
                        <option value="<%= c.getCategoryId() %>"><%= c.getCategoryName() %></option>
                        <% } %>
                    </select>
                </div>
            </div>
            <div class="frow">
                <label>URL ảnh</label>
                <input class="field" type="text" name="imageUrl" id="ep-img">
            </div>
            <div class="frow">
                <label>Trạng thái</label>
                <select class="field" name="status" id="ep-status">
                    <option value="1">Hiển thị trên menu</option>
                    <option value="0">Ẩn</option>
                </select>
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('editProductDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- ══ DRAWER: Thêm danh mục ══ -->
<div class="drawer-overlay" id="createCategoryDrawer">
    <div class="drawer">
        <h3 class="serif">Thêm danh mục</h3>
        <form method="post" action="<%= ctx %>/category-management">
            <input type="hidden" name="action" value="create">
            <div class="frow">
                <label>Tên danh mục *</label>
                <input class="field" type="text" name="categoryName" required placeholder="Cà phê, Trà, Nước ép…">
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('createCategoryDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Thêm danh mục</button>
            </div>
        </form>
    </div>
</div>

<!-- ══ DRAWER: Sửa danh mục ══ -->
<div class="drawer-overlay" id="editCategoryDrawer">
    <div class="drawer">
        <h3 class="serif">Chỉnh sửa danh mục</h3>
        <form method="post" action="<%= ctx %>/category-management">
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="categoryId" id="ec-id">
            <div class="frow">
                <label>Tên danh mục *</label>
                <input class="field" type="text" name="categoryName" id="ec-name" required>
            </div>
            <div class="drawer-foot">
                <button type="button" class="btn btn-ghost" onclick="closeDrawer('editCategoryDrawer')">Hủy</button>
                <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
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

    function openEditProduct(id, name, price, img, status, catId) {
        document.getElementById('ep-id').value     = id;
        document.getElementById('ep-name').value   = name;
        document.getElementById('ep-price').value  = price;
        document.getElementById('ep-img').value    = img;
        document.getElementById('ep-status').value = status;
        document.getElementById('ep-cat').value    = catId;
        openDrawer('editProductDrawer');
    }

    function openEditCategory(id, name) {
        document.getElementById('ec-id').value   = id;
        document.getElementById('ec-name').value = name;
        openDrawer('editCategoryDrawer');
    }

    function switchTab(tab, btn) {
        document.getElementById('panel-products').style.display   = tab === 'products'   ? '' : 'none';
        document.getElementById('panel-categories').style.display = tab === 'categories' ? '' : 'none';
        document.querySelectorAll('.page-tab').forEach(t => t.classList.remove('active'));
        btn.classList.add('active');
    }

    const alert = document.getElementById('pageAlert');
    if (alert) setTimeout(() => { alert.style.opacity='0'; alert.style.transition='.4s'; setTimeout(()=>alert.remove(),400); }, 4000);
</script>
</body>
</html>
