<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>coffeshop</title>
    <meta name="page-title-key" content="promoAdmin">
    <link rel="stylesheet" href="assets/css/app.css?v=loyalty-3">
    <script defer src="assets/js/i18n.js?v=loyalty-3"></script>
</head>
<body>
    <nav class="nav"><div class="nav-inner"><a class="brand" href="index.html">coffeshop</a><div class="links" id="nav-links"></div><button id="lang-toggle" class="link lang-toggle" type="button" onclick="toggleLang()">EN</button></div></nav>
    <main class="shell work-shell">
        <div class="work-toolbar">
            <button class="btn primary" onclick="newPromo()" data-i18n="addNew">Thêm mới</button>
        </div>
        <div class="grid side">
            <section class="menu-grid" id="promo-list"></section>
            <div class="overlay" id="form-overlay"></div>
            <aside class="card" id="edit-panel">
                <div class="form-panel-head">
                    <h2 id="form-title" data-i18n="promoAdmin">Khuyến mãi</h2>
                    <button type="button" class="btn form-panel-close" onclick="resetForm(); closeEditSheet();" data-i18n="cancel">Huỷ</button>
                </div>
                <form class="grid" onsubmit="savePromo(event)">
                    <input id="id" type="hidden">
                    <div><label data-i18n="promoCode">Mã</label><input id="code" maxlength="40" required></div>
                    <div><label data-i18n="nameVi">Tên tiếng Việt</label><input id="nameVi" maxlength="120" required></div>
                    <div><label data-i18n="nameEn">Tên tiếng Anh</label><input id="nameEn" maxlength="120" required></div>
                    <div class="form-row">
                        <div>
                            <label>Loại</label>
                            <select id="discountType">
                                <option value="PERCENT">%</option>
                                <option value="AMOUNT">Số tiền</option>
                            </select>
                        </div>
                        <div><label>Giá trị</label><input id="discountValue" type="number" min="0" required></div>
                    </div>
                    <div class="form-row">
                        <div><label>Đơn tối thiểu</label><input id="minSubtotal" type="number" min="0" value="0"></div>
                        <div><label>Giảm tối đa</label><input id="maxDiscount" type="number" min="0" value="0"></div>
                    </div>
                    <div class="form-row">
                        <div><label>Bắt đầu</label><input id="startAt" placeholder="yyyy-MM-dd HH:mm:ss"></div>
                        <div><label>Kết thúc</label><input id="endAt" placeholder="yyyy-MM-dd HH:mm:ss"></div>
                    </div>
                    <div><label>Số lượt tối đa (0 = không giới hạn)</label><input id="maxUses" type="number" min="0" value="0"></div>
                    <label><input id="active" type="checkbox" checked style="width:auto"> <span data-i18n="active">Đang bán</span></label>
                    <button class="btn primary" type="submit" data-i18n="save">Lưu</button>
                    <div id="message" class="notice hidden"></div>
                </form>
            </aside>
        </div>
        <section class="card" style="margin-top:16px">
            <h3>VAT / Tip</h3>
            <p class="muted" style="margin:0 0 8px">Giá menu đã gồm VAT. % VAT chỉ dùng để tách số thuế trên hóa đơn/báo cáo, không cộng thêm khi thanh toán.</p>
            <form class="grid" onsubmit="saveTaxConfig(event)" style="max-width:420px">
                <div><label>VAT % (đã gồm trong giá)</label><input id="vatPercent" type="number" min="0" max="100"></div>
                <div><label>Phí phục vụ % (cộng thêm nếu &gt; 0)</label><input id="serviceChargePercent" type="number" min="0" max="100"></div>
                <label><input id="tipEnabled" type="checkbox" style="width:auto"> Tip</label>
                <button class="btn primary" type="submit" data-i18n="save">Lưu</button>
            </form>
        </section>
    </main>
    <script src="assets/js/page-admin-promotions.js"></script>
</body>
</html>
