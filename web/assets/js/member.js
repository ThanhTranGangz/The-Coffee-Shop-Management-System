/* Logic dang nhap / dang ky / tai khoan thanh vien — dung chung member.jsp + order-summary */
(function () {
    'use strict';
    var C = window.CSMS;
    if (!C) return;

  window.MemberUI = {
    /** Mo modal dang nhap (neu co tren trang). */
    openAuth: function () {
      var m = document.getElementById('authModal');
      if (m) {
        m.classList.add('show');
        MemberUI.setAuthMode(false);
      } else {
        location.href = C.BASE + '/member.jsp';
      }
    },

    setAuthMode: function (register) {
      var tabL = document.getElementById('tabLogin');
      var tabR = document.getElementById('tabRegister');
      if (!tabL) return;
      tabL.classList.toggle('active', !register);
      tabR.classList.toggle('active', register);
      document.getElementById('paneLogin').style.display = register ? 'none' : '';
      document.getElementById('paneRegister').style.display = register ? '' : 'none';
      document.getElementById('authSubmit').textContent = register ? 'Tạo tài khoản' : 'Đăng nhập';
      var msg = document.getElementById('authMsg');
      if (msg) { msg.textContent = ''; msg.className = 'form-msg'; }
    },

    submitAuth: function (register) {
      var msg = document.getElementById('authMsg');
      var p = new URLSearchParams();
      var path;
      if (register) {
        path = '/api/member/register';
        p.append('fullName', document.getElementById('regName').value.trim());
        p.append('phone', document.getElementById('regPhone').value.trim());
        p.append('password', document.getElementById('regPass').value);
      } else {
        path = '/api/member/login';
        p.append('phone', document.getElementById('loginPhone').value.trim());
        p.append('password', document.getElementById('loginPass').value);
      }
      return C.apiPost(path, p).then(function (data) {
        if (data.ok) {
          var modal = document.getElementById('authModal');
          if (modal) modal.classList.remove('show');
          C.toast(register ? 'Chào mừng bạn gia nhập nhà cà phê!' : 'Chào ' + data.member.fullName + '!');
          if (typeof window.onMemberLogin === 'function') {
            window.onMemberLogin(data.member);
          }
          return data;
        }
        if (msg) {
          msg.className = 'form-msg err';
          msg.textContent = data.message || 'Có lỗi xảy ra.';
        }
        return data;
      });
    },

    logout: function () {
      return C.apiPost('/api/member/logout').then(function () {
        C.toast('Đã đăng xuất.');
        if (typeof window.onMemberLogout === 'function') {
          window.onMemberLogout();
        }
      });
    },

    offerDesc: function (v) {
      return v.discountPercent != null
        ? 'Giảm ' + v.discountPercent + '%'
        : 'Giảm ' + C.money(v.discountAmount);
    },

    statusLabel: function (status) {
      var map = {
        PENDING: 'Chờ pha chế', PREPARING: 'Đang pha', READY: 'Sẵn sàng',
        COMPLETED: 'Hoàn tất', CANCELLED: 'Đã hủy',
        PAID: 'Đã thanh toán', UNPAID: 'Chưa thanh toán', PENDING_PAY: 'Chờ xác nhận CK'
      };
      return map[status] || status;
    }
  };
})();
