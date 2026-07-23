<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
        <meta name="page-title-key" content="menuAdminTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=order-confirm-1">
    <script defer src="assets/js/i18n.js?v=i18n-sync-1"></script>
</head>
<body>
    <nav class="nav"><div class="nav-inner"><a class="brand" href="index.html">coffeshop</a><div class="links" id="nav-links"></div><button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button></div></nav>
    <main class="shell work-shell">
        <div class="work-toolbar">
            <button class="btn primary" onclick="newItem()" data-i18n="addNew">Thêm mới</button>
            <button class="btn" type="button" onclick="downloadImportTemplate()" data-i18n="downloadTemplate">Tải file mẫu</button>
            <button class="btn" type="button" onclick="document.getElementById('import-file').click()" data-i18n="importExcel">Import từ Excel</button>
            <input type="file" id="import-file" accept=".xlsx,.xls" style="display:none" onchange="importExcelFile(event)">
        </div>
        <div class="grid side">
            <section class="menu-grid" id="items"></section>
            <div class="overlay" id="form-overlay"></div>
            <aside class="card" id="edit-panel">
                <div class="form-panel-head">
                    <h2 id="form-title" data-i18n="itemInfo">Thông tin món</h2>
                    <button type="button" class="btn form-panel-close" onclick="resetForm(); closeEditSheet();" data-i18n="cancel">Huỷ</button>
                </div>
                <form class="grid" onsubmit="saveItem(event)">
                    <input id="id" type="hidden">
                    <div><label data-i18n="nameVi">Tên tiếng Việt</label><input id="nameVi" minlength="2" maxlength="80" required oninput="syncDefaultImage()"></div>
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
                    <hr style="margin: 1rem 0; border: none; border-top: 1px solid var(--border);">
                    <h3 style="font-size: 1rem; margin-bottom: 0.5rem;" data-i18n="recipeInfo">Công thức món</h3>
                    <section class="recipe-editor" id="recipe-editor">
                        <p class="muted" data-i18n="recipeHelp">Nhập định lượng nguyên liệu cho món này.</p>
                        <div id="recipe-rows"></div>
                        <button class="btn" type="button" onclick="addRecipeRow()" data-i18n="addMaterialBtn">Thêm nguyên liệu</button>
                    </section>
                    <label><input id="active" type="checkbox" checked style="width:auto"> <span data-i18n="active">Đang bán</span></label>
                    <button class="btn primary" type="submit" data-i18n="save">Lưu</button>
                    <div id="message" class="notice hidden"></div>
                </form>
            </aside>
        </div>
    </main>

    <button id="scrollToTopBtn" class="btn primary" style="position: fixed; bottom: 20px; right: 20px; z-index: 9999; display: none; align-items: center; justify-content: center; border-radius: 50%; width: 48px; height: 48px; padding: 0; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" onclick="window.scrollTo({top: 0, behavior: 'smooth'})">
        <svg style="width: 24px; height: 24px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path></svg>
    </button>

    <script src="assets/js/page-admin-menu.js?v=menu-images-1"></script>
    <script>
        window.addEventListener('scroll', function() {
            const btn = document.getElementById('scrollToTopBtn');
            if (btn) {
                if (window.scrollY > 300) btn.style.display = 'flex';
                else btn.style.display = 'none';
            }
        });
    </script>
</body>
</html>
