/* =====================================================================
   nhà cà phê — JS dùng chung: giỏ hàng (localStorage), gọi API,
   định dạng tiền, toast. Không phụ thuộc thư viện ngoài.
   ===================================================================== */
(function () {
    'use strict';

    // Context path, vd: /The-Coffee-Shop-Management-System
    var BASE = location.pathname.replace(/\/[^/]*$/, '');
    var CART_KEY = 'csms_cart_v1';

    /* Dung ma Unicode thay vi ky tu "d" de tranh loi font khi serve file .js */
    var VND = '\u0111';

    function money(n) {
        return (n || 0).toLocaleString('vi-VN') + VND;
    }

    function escapeHtml(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    /* ---------------- giỏ hàng ---------------- */

    function cartLoad() {
        try {
            var raw = sessionStorage.getItem(CART_KEY);
            var items = raw ? JSON.parse(raw) : [];
            return Array.isArray(items) ? items : [];
        } catch (e) {
            return [];
        }
    }

    function cartSave(items) {
        sessionStorage.setItem(CART_KEY, JSON.stringify(items));
        document.dispatchEvent(new CustomEvent('cart:change'));
    }

    function lineKey(productId, note) {
        return productId + '||' + (note || '');
    }

    var Cart = {
        items: cartLoad,

        /** Cùng món + cùng ghi chú thì gộp dòng, khác ghi chú tách dòng. */
        add: function (productId, name, price, qty, note) {
            note = (note || '').trim();
            var items = cartLoad();
            var key = lineKey(productId, note);
            var found = null;
            for (var i = 0; i < items.length; i++) {
                if (lineKey(items[i].productId, items[i].note) === key) { found = items[i]; break; }
            }
            if (found) {
                found.qty = Math.min(20, found.qty + qty);
            } else {
                items.push({ productId: productId, name: name, price: price, qty: qty, note: note });
            }
            cartSave(items);
        },

        setQty: function (index, qty) {
            var items = cartLoad();
            if (!items[index]) return;
            if (qty <= 0) {
                items.splice(index, 1);
            } else {
                items[index].qty = Math.min(20, qty);
            }
            cartSave(items);
        },

        setNote: function (index, note) {
            var items = cartLoad();
            if (!items[index]) return;
            items[index].note = (note || '').trim();
            // gộp nếu trùng với dòng khác
            var key = lineKey(items[index].productId, items[index].note);
            for (var i = 0; i < items.length; i++) {
                if (i !== index && lineKey(items[i].productId, items[i].note) === key) {
                    items[i].qty = Math.min(20, items[i].qty + items[index].qty);
                    items.splice(index, 1);
                    break;
                }
            }
            cartSave(items);
        },

        remove: function (index) {
            var items = cartLoad();
            items.splice(index, 1);
            cartSave(items);
        },

        removeByProduct: function (productId) {
            cartSave(cartLoad().filter(function (it) { return it.productId !== productId; }));
        },

        clear: function () { cartSave([]); },

        count: function () {
            return cartLoad().reduce(function (s, it) { return s + it.qty; }, 0);
        },

        subtotal: function () {
            return cartLoad().reduce(function (s, it) { return s + it.qty * it.price; }, 0);
        },

        /** Tham số form-encoded gửi cho API quote/create. */
        toParams: function (extra) {
            var p = new URLSearchParams();
            cartLoad().forEach(function (it) {
                p.append('productId', it.productId);
                p.append('quantity', it.qty);
                p.append('note', it.note || '');
            });
            if (extra) {
                Object.keys(extra).forEach(function (k) {
                    if (extra[k] != null) p.append(k, extra[k]);
                });
            }
            return p;
        }
    };

    /* ---------------- API ---------------- */

    function apiGet(path) {
        return fetch(BASE + path, { headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); });
    }

    function apiPost(path, params) {
        return fetch(BASE + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
            body: params ? params.toString() : ''
        }).then(function (r) { return r.json(); });
    }

    /* ---------------- toast ---------------- */

    var toastEl = null, toastTimer = null;

    function toast(msg) {
        if (!toastEl) {
            toastEl = document.createElement('div');
            toastEl.className = 'toast';
            document.body.appendChild(toastEl);
        }
        toastEl.textContent = msg;
        toastEl.classList.add('show');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { toastEl.classList.remove('show'); }, 2400);
    }

    /* ---------------- thanh giỏ hàng dính đáy ---------------- */

    function renderCartBar() {
        var bar = document.getElementById('cartBar');
        if (!bar) return;
        var count = Cart.count();
        if (count > 0) {
            bar.classList.add('show');
            bar.querySelector('.cart-count').textContent = count;
            bar.querySelector('.cart-bar-total').textContent = money(Cart.subtotal());
        } else {
            bar.classList.remove('show');
        }
    }

    document.addEventListener('cart:change', renderCartBar);
    document.addEventListener('DOMContentLoaded', renderCartBar);

    /* ---------------- trạng thái đơn (nhãn tiếng Việt) ---------------- */

    var ORDER_STATUS = {
        PENDING:   'Chờ pha chế',
        PREPARING: 'Đang pha chế',
        READY:     'Sẵn sàng phục vụ',
        COMPLETED: 'Hoàn tất',
        CANCELLED: 'Đã hủy'
    };

    var PAY_STATUS = {
        UNPAID:  'Chưa thanh toán',
        PENDING: 'Chờ xác nhận CK',
        PAID:    'Đã thanh toán',
        FAILED:  'Lỗi thanh toán'
    };

    window.CSMS = {
        BASE: BASE,
        money: money,
        escapeHtml: escapeHtml,
        Cart: Cart,
        apiGet: apiGet,
        apiPost: apiPost,
        toast: toast,
        renderCartBar: renderCartBar,
        ORDER_STATUS: ORDER_STATUS,
        PAY_STATUS: PAY_STATUS
    };
})();
