<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop - Kho nguyên liệu</title>
        <meta name="page-title-key" content="inventoryPageTitle">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
    <style>
        .stock-low { color: var(--danger); font-weight: 600; }
        .stock-ok { color: var(--success); }
        .low-stock-alert {
            margin-bottom: 16px;
            padding: 14px 16px;
            border: 1px solid color-mix(in srgb, var(--danger) 35%, var(--border));
            background: color-mix(in srgb, var(--danger) 10%, transparent);
            border-radius: 12px;
        }
        .low-stock-alert h3 { margin: 0 0 6px; color: var(--danger); font-size: 1rem; }
        .low-stock-alert p { margin: 0 0 8px; }
        .low-stock-alert ul { margin: 0; padding-left: 1.2rem; }
    </style>
</head>
<body>
    <nav class="nav"><div class="nav-inner"><a class="brand" href="index.html">coffeshop</a><div class="links" id="nav-links"></div><button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button></div></nav>
    <main class="shell work-shell">
        <div class="work-toolbar">
            <button class="btn primary" onclick="newItem()" data-i18n="addMaterialBtn">Thêm nguyên liệu</button>
        </div>
        <div id="low-stock-alert" class="low-stock-alert hidden"></div>
        <div class="grid side">
            <section class="card" style="padding:0; overflow-x:auto;">
                <table class="data-table" style="width:100%; text-align:left; border-collapse:collapse; white-space:nowrap;">
                    <thead>
                        <tr style="border-bottom:1px solid var(--border)">
                            <th style="padding:12px" data-i18n="materialId">Mã NL</th>
                            <th style="padding:12px" data-i18n="materialName">Tên nguyên liệu</th>
                            <th style="padding:12px; text-align:right" data-i18n="stock">Tồn kho</th>
                            <th style="padding:12px; text-align:right" data-i18n="minStock">Tối thiểu</th>
                            <th style="padding:12px" data-i18n="unit">Đơn vị</th>
                            <th style="padding:12px; text-align:right" data-i18n="importPrice">Giá nhập</th>
                            <th style="padding:12px"></th>
                        </tr>
                    </thead>
                    <tbody id="items-tbody"></tbody>
                </table>
            </section>
            
            <div class="overlay" id="form-overlay"></div>
            <aside class="card" id="edit-panel">
                <div class="form-panel-head">
                    <h2 id="form-title" data-i18n="materialInfo">Thông tin nguyên liệu</h2>
                    <button type="button" class="btn form-panel-close" onclick="resetForm(); closeEditSheet();" data-i18n="cancel">Huỷ</button>
                </div>
                <form class="grid" onsubmit="saveItem(event)">
                    <input id="originalId" type="hidden">
                    <div><label data-i18n="materialIdFull">Mã nguyên liệu (ID)</label><input id="id" minlength="2" maxlength="50" pattern="[A-Za-z0-9_-]+" title="Chỉ chữ, số, _ hoặc -" required placeholder="VD: CF_01" data-i18n-placeholder="materialIdPlaceholder"></div>
                    <div><label data-i18n="materialName">Tên nguyên liệu</label><input id="name" minlength="2" maxlength="120" required></div>
                    <div class="form-row">
                        <div>
                            <label data-i18n="unitHelp">Đơn vị (g, ml...)</label>
                            <input id="unit" required maxlength="20">
                        </div>
                        <div><label data-i18n="importPriceVND">Giá nhập (đ)</label><input id="importCost" type="number" min="0" step="1" required></div>
                    </div>
                    <div class="form-row">
                        <div><label data-i18n="currentStock">Tồn kho hiện tại</label><input id="stock" type="number" min="0" step="1" required></div>
                        <div><label data-i18n="minStockLevel">Mức tối thiểu</label><input id="minStock" type="number" min="0" step="1" required></div>
                    </div>
                    <button class="btn primary" type="submit" data-i18n="saveMaterial">Lưu nguyên liệu</button>
                    <div id="message" class="notice hidden"></div>
                </form>
            </aside>
        </div>
    </main>

    <button id="scrollToTopBtn" class="btn primary" style="position: fixed; bottom: 20px; right: 20px; z-index: 9999; display: none; align-items: center; justify-content: center; border-radius: 50%; width: 48px; height: 48px; padding: 0; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" onclick="window.scrollTo({top: 0, behavior: 'smooth'})">
        <svg style="width: 24px; height: 24px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path></svg>
    </button>

    <script src="assets/js/page-admin-inventory.js?v=4"></script>
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
