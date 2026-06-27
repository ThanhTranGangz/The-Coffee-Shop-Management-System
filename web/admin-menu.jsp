<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
    <link rel="stylesheet" href="assets/css/app.css?v=order-confirm-1">
    <script defer src="assets/js/i18n.js?v=tab-session-1"></script>
</head>
<body>
    <nav class="nav"><div class="nav-inner"><a class="brand" href="index.html">coffeshop</a><div class="links" id="nav-links"></div><button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button></div></nav>
    <main class="shell work-shell">
        <div class="work-toolbar">
            <button class="btn primary" onclick="resetForm()" data-i18n="addNew">Thêm mới</button>
        </div>
        <div class="grid side">
            <section class="menu-grid" id="items"></section>
            <aside class="card">
                <h2 id="form-title" data-i18n="itemInfo">Thông tin món</h2>
                <form class="grid" onsubmit="saveItem(event)">
                    <input id="id" type="hidden">
                    <div><label data-i18n="nameVi">Tên tiếng Việt</label><input id="nameVi" minlength="2" maxlength="80" required></div>
                    <div><label data-i18n="nameEn">Tên tiếng Anh</label><input id="nameEn" minlength="2" maxlength="80" required></div>
                    <div class="form-row">
                        <div>
                            <label data-i18n="category">Nhóm</label>
                            <select id="category" onchange="syncDefaultImage()">
                                <option value="Cà phê" data-category-option>Cà phê</option>
                                <option value="Trà" data-category-option>Trà</option>
                                <option value="Đặc biệt" data-category-option>Đặc biệt</option>
                                <option value="Bánh ngọt" data-category-option>Bánh ngọt</option>
                            </select>
                        </div>
                        <div><label data-i18n="price">Giá</label><input id="price" type="number" min="10000" max="200000" step="1000" required></div>
                    </div>
                    <div><label data-i18n="imagePath">Ảnh local</label><input id="imagePath" value="assets/img/menu/coffee.jpg" required></div>
                    <label><input id="hasSizes" type="checkbox" style="width:auto" onchange="toggleSizeEditor()"> <span data-i18n="hasSizes">Sản phẩm có size</span></label>
                    <section class="size-editor hidden" id="size-editor">
                        <p class="muted" data-i18n="baseSizeHelp">Size S dùng giá gốc.</p>
                        <div id="size-rows"></div>
                        <button class="btn" type="button" onclick="addSizeRow()" data-i18n="addSize">Thêm size</button>
                    </section>
                    <label><input id="active" type="checkbox" checked style="width:auto"> <span data-i18n="active">Đang bán</span></label>
                    <button class="btn primary" type="submit" data-i18n="save">Lưu</button>
                    <div id="message" class="notice hidden"></div>
                </form>
            </aside>
        </div>
    </main>
    <script src="assets/js/page-admin-menu.js?v=order-confirm-1"></script>
</body>
</html>
