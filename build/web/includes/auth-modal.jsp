<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<div class="modal" id="authModal">
    <div class="modal-in">
        <h3>Thành viên nhà cà phê</h3>
        <div class="tabs">
            <button type="button" id="tabLogin" class="active">Đăng nhập</button>
            <button type="button" id="tabRegister">Đăng ký mới</button>
        </div>
        <div id="paneLogin">
            <input class="field" id="loginPhone" type="tel" placeholder="Số điện thoại" style="margin-bottom:10px">
            <input class="field" id="loginPass" type="password" placeholder="Mật khẩu">
        </div>
        <div id="paneRegister" style="display:none">
            <input class="field" id="regName" placeholder="Họ và tên" style="margin-bottom:10px">
            <input class="field" id="regPhone" type="tel" placeholder="Số điện thoại" style="margin-bottom:10px">
            <input class="field" id="regPass" type="password" placeholder="Mật khẩu (từ 6 ký tự)">
        </div>
        <div class="form-msg" id="authMsg"></div>
        <div style="display:flex;gap:8px;margin-top:8px">
            <button type="button" class="btn btn-ghost" style="flex:1" id="authCancel">Đóng</button>
            <button type="button" class="btn btn-primary" style="flex:1" id="authSubmit">Đăng nhập</button>
        </div>
        <p class="label" style="margin-top:12px;text-align:center">Tích 1 điểm cho mỗi 10.000&#273; đơn hàng</p>
    </div>
</div>
