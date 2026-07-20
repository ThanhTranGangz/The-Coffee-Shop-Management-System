let currentWeekStart = getMonday(new Date());
let staffList = [];
let shiftList = [];

function getMonday(d) {
    d = new Date(d);
    var day = d.getDay(),
        diff = d.getDate() - day + (day == 0 ? -6 : 1);
    return new Date(d.setDate(diff));
}

function formatDate(date) {
    const d = new Date(date);
    let month = '' + (d.getMonth() + 1);
    let day = '' + d.getDate();
    const year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join('-');
}

function getDayName(date) {
    return dayName(date.getDay());
}

async function init() {
    await fetchStaffAndShifts();
    await initPayroll();
}

async function fetchStaffAndShifts() {
    try {
        const query = window.location.search;
        const staffResp = await fetch('api/staff' + query);
        if (staffResp.ok) {
            staffList = await staffResp.json();
        }
        const shiftResp = await fetch('api/shifts' + query);
        if (shiftResp.ok) {
            shiftList = dedupeShifts(await shiftResp.json());
        }
        populateStaffDropdown();
        renderCalendar();
        renderStaffList();
    } catch (e) {
        console.error("Error fetching data", e);
    }
}

function dedupeShifts(list) {
    const seen = new Set();
    const result = [];
    (Array.isArray(list) ? list : []).forEach(shift => {
        const key = `${Number(shift.staffId)}|${shift.date}|${shift.shiftName}`;
        if (seen.has(key)) return;
        seen.add(key);
        result.push(shift);
    });
    return result;
}

function availableStaffForShift(shiftName, dateStr, excludeStaffId) {
    const taken = new Set(
        shiftList
            .filter(s => s.shiftName === shiftName && s.date === dateStr && Number(s.staffId) !== Number(excludeStaffId || 0))
            .map(s => Number(s.staffId))
    );
    return staffList.filter(staff => isStaffActive(staff) && !taken.has(Number(staff.id)));
}

function scheduleRoles() {
    return [
        { id: 'Barista', label: t('roleBarista'), css: 'role-barista' },
        { id: 'Cashier', label: t('roleCashier'), css: 'role-cashier' },
        { id: 'Waiter', label: t('roleRunner'), css: 'role-waiter' }
    ];
}

function isStaffActive(staff) {
    if (!staff) return false;
    const status = String(staff.status || '');
    return staff.active !== false && (status === 'Active' || status === '');
}

function populateStaffDropdown(includeStaffId, shiftName, dateStr) {
    const select = document.getElementById('staffId');
    const keepId = includeStaffId ? Number(includeStaffId) : 0;
    select.innerHTML = `<option value="">${t('selectStaff')}</option>`;
    const candidates = (shiftName && dateStr)
        ? availableStaffForShift(shiftName, dateStr, keepId)
        : staffList.filter(isStaffActive);

    const keepStaff = keepId ? staffList.find(s => Number(s.id) === keepId) : null;
    const list = keepStaff && !candidates.some(s => Number(s.id) === keepId)
        ? [keepStaff, ...candidates]
        : candidates;

    list
        .slice()
        .sort((a, b) => String(a.name || '').localeCompare(String(b.name || ''), lang() === 'en' ? 'en' : 'vi'))
        .forEach(staff => {
            const option = document.createElement('option');
            option.value = staff.id;
            option.textContent = isStaffActive(staff)
                ? staff.name
                : `${staff.name} ${t('staffInactiveSuffix')}`;
            select.appendChild(option);
        });
}

function showNotice(text, ok = true) {
    const msg = document.getElementById('message');
    if (!msg) {
        alert(text);
        return;
    }
    msg.textContent = text;
    msg.className = ok ? 'notice' : 'notice danger';
    setTimeout(() => { msg.className = 'notice hidden'; }, 3500);
}

function displayShiftStatus(status) {
    if (status === 'Đã xếp lịch') return t('statusScheduled');
    if (status === 'Đã làm' || status === 'Hoàn thành') return t('statusDone');
    if (status === 'Vắng' || status === 'Nghỉ') return t('statusAbsent');
    return status;
}

function statusClassFor(status) {
    if (status === 'Đã làm' || status === 'Hoàn thành') return 'status-done';
    if (status === 'Vắng' || status === 'Nghỉ') return 'status-absent';
    return 'status-pending';
}

function renderCalendar() {
    const grid = document.getElementById('calendar-grid');
    grid.innerHTML = '';

    grid.appendChild(createCell('calendar-header', t('shiftLabel')));
    grid.appendChild(createCell('calendar-header', t('roleLabel')));

    const weekDates = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date(currentWeekStart);
        d.setDate(d.getDate() + i);
        weekDates.push(formatDate(d));
        grid.appendChild(createCell('calendar-header', `${getDayName(d)}<br><small style="font-weight:normal">${d.getDate()}/${d.getMonth() + 1}</small>`));
    }

    const fixedShifts = [
        { name: 'Ca Sáng', hours: '06:00 - 12:00' },
        { name: 'Ca Chiều', hours: '12:00 - 18:00' },
        { name: 'Ca Tối', hours: '18:00 - 23:00' }
    ];
    const roles = scheduleRoles();

    fixedShifts.forEach((shiftData, shiftIndex) => {
        roles.forEach((role, roleIndex) => {
            if (roleIndex === 0) {
                const nameCell = document.createElement('div');
                nameCell.className = 'calendar-cell staff-name-col' + (shiftIndex < fixedShifts.length - 1 ? ' shift-band-divider' : '');
                nameCell.innerHTML = `
                    ${escapeHtml(shiftNameText(shiftData.name))}
                    <span class="staff-role">${escapeHtml(shiftData.hours)}</span>
                `;
                grid.appendChild(nameCell);
            }

            const roleLabel = document.createElement('div');
            roleLabel.className = `calendar-cell role-label-col ${role.css}` + (roleIndex === roles.length - 1 && shiftIndex < fixedShifts.length - 1 ? ' shift-band-divider' : '');
            roleLabel.textContent = role.label;
            grid.appendChild(roleLabel);

            weekDates.forEach(dateStr => {
                const cell = document.createElement('div');
                cell.className = `calendar-cell role-day-cell ${role.css}` + (roleIndex === roles.length - 1 && shiftIndex < fixedShifts.length - 1 ? ' shift-band-divider' : '');

                const roleShifts = dedupeShifts(shiftList.filter(s =>
                    s.shiftName === shiftData.name
                    && s.date === dateStr
                    && String(s.assignedRole || 'Barista') === role.id
                ));

                if (roleShifts.length) {
                    roleShifts.forEach(shift => {
                        const shiftEl = document.createElement('div');
                        shiftEl.className = 'shift-block';
                        shiftEl.style.cursor = 'pointer';
                        shiftEl.onclick = () => editShift(shift);
                        shiftEl.innerHTML = `
                            <span class="shift-name">${escapeHtml(shift.staffName)}</span>
                            <span class="shift-status ${statusClassFor(shift.status)}">${escapeHtml(displayShiftStatus(shift.status))}</span>
                        `;
                        cell.appendChild(shiftEl);
                    });
                } else {
                    const warnEl = document.createElement('div');
                    warnEl.className = 'role-warning';
                    warnEl.textContent = '⚠ ' + t('understaffed');
                    cell.appendChild(warnEl);
                }

                const addBtn = document.createElement('div');
                addBtn.className = 'role-add-btn';
                addBtn.textContent = '+';
                addBtn.title = tf('addRoleTitle', { role: role.label });
                addBtn.onclick = () => prepareAddShift(shiftData.name, dateStr, role.id);
                cell.appendChild(addBtn);

                grid.appendChild(cell);
            });
        });
    });
}

function escapeHtml(value) {
    return String(value || '').replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}

function createCell(className, html) {
    const div = document.createElement('div');
    div.className = className;
    div.innerHTML = html;
    return div;
}

function prevWeek() {
    currentWeekStart.setDate(currentWeekStart.getDate() - 7);
    renderCalendar();
}

function nextWeek() {
    currentWeekStart.setDate(currentWeekStart.getDate() + 7);
    renderCalendar();
}

function prepareAddShift(shiftName, dateStr, roleId) {
    document.getElementById('shiftId').value = '';
    populateStaffDropdown(0, shiftName, dateStr);
    document.getElementById('staffId').value = '';
    document.getElementById('shiftDate').value = dateStr;
    document.getElementById('shiftName').value = shiftName;
    document.getElementById('assignedRole').value = roleId || 'Barista';
    document.getElementById('notes').value = '';
    document.getElementById('status').value = 'Đã xếp lịch';

    document.getElementById('form-title').textContent = t('addShiftTitle');
    document.getElementById('form-title').setAttribute('data-i18n', 'addShiftTitle');
    document.getElementById('form-title').scrollIntoView({ behavior: 'smooth' });
}

function editShift(shift) {
    document.getElementById('shiftId').value = shift.id;
    populateStaffDropdown(shift.staffId, shift.shiftName, shift.date);
    document.getElementById('staffId').value = shift.staffId;
    document.getElementById('shiftDate').value = shift.date;
    document.getElementById('shiftName').value = shift.shiftName;
    document.getElementById('assignedRole').value = shift.assignedRole || 'Barista';
    document.getElementById('notes').value = shift.notes || '';
    document.getElementById('status').value = shift.status;

    document.getElementById('form-title').textContent = t('editShiftTitle');
    document.getElementById('form-title').setAttribute('data-i18n', 'editShiftTitle');
    document.getElementById('form-title').scrollIntoView({ behavior: 'smooth' });
}

let savingShift = false;

function hasShiftOverlap(staffId, shiftDate, shiftName, excludeId) {
    return shiftList.some(s =>
        Number(s.staffId) === Number(staffId)
        && String(s.date) === String(shiftDate)
        && String(s.shiftName) === String(shiftName)
        && String(s.id || '') !== String(excludeId || '')
    );
}

function mapShiftError(raw) {
    if (!raw) return t('shiftSaveFailed');
    if (raw === 'SHIFT_OVERLAP' || /đã được phân công|already assigned/i.test(raw)) return t('shiftOverlap');
    if (/Thiếu thông tin|incomplete/i.test(raw)) return t('shiftMissingInfo');
    return raw;
}

async function saveShift(e) {
    e.preventDefault();
    if (savingShift) return;

    const shiftId = document.getElementById('shiftId').value;
    const staffId = parseInt(document.getElementById('staffId').value, 10);
    if (!staffId) {
        showNotice(t('selectStaffRequired'), false);
        return;
    }

    const staff = staffList.find(s => s.id === staffId);
    const shiftName = document.getElementById('shiftName').value;
    const shiftDate = document.getElementById('shiftDate').value;
    const status = document.getElementById('status').value;
    const assignedRole = document.getElementById('assignedRole').value || 'Barista';

    if (!shiftDate || !shiftName) {
        showNotice(t('shiftMissingInfo'), false);
        return;
    }

    if (hasShiftOverlap(staffId, shiftDate, shiftName, shiftId)) {
        showNotice(t('shiftOverlap'), false);
        return;
    }

    if (status === 'Đã làm' || status === 'Vắng') {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const selectedDate = new Date(shiftDate + 'T00:00:00');
        if (selectedDate > today) {
            showNotice(t('shiftStatusDateRule'), false);
            return;
        }
    }

    let hours = '06:00 - 12:00';
    if (shiftName === 'Ca Chiều') hours = '12:00 - 18:00';
    if (shiftName === 'Ca Tối') hours = '18:00 - 23:00';

    const newShift = {
        id: shiftId,
        staffId: staffId,
        staffName: staff ? staff.name : '',
        date: shiftDate,
        shiftName: shiftName,
        hours: hours,
        assignedRole: assignedRole,
        notes: document.getElementById('notes').value,
        status: status
    };

    savingShift = true;
    try {
        const query = window.location.search;
        const resp = await fetch('api/shifts' + query, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newShift)
        });

        if (resp.ok) {
            const savedShift = await resp.json();
            const idx = shiftList.findIndex(s => s.id === savedShift.id);
            if (idx !== -1) shiftList[idx] = savedShift;
            else shiftList.push(savedShift);

            e.target.reset();
            document.getElementById('shiftId').value = '';
            populateStaffDropdown();
            document.getElementById('form-title').textContent = t('shiftFormTitle');
            document.getElementById('form-title').setAttribute('data-i18n', 'shiftFormTitle');
            renderCalendar();
            showNotice(t('shiftSaved'));
        } else {
            const errText = await resp.text();
            let message = t('shiftSaveFailed');
            try {
                const parsed = JSON.parse(errText);
                if (parsed && parsed.error) message = mapShiftError(parsed.error);
            } catch (_) {
                if (errText) message = mapShiftError(errText);
            }
            showNotice(message, false);
        }
    } catch (err) {
        showNotice(t('networkErrorShort') + ': ' + err.message, false);
    } finally {
        savingShift = false;
    }
}

async function deleteShift() {
    const shiftId = document.getElementById('shiftId').value;
    if (!shiftId) {
        showNotice(t('selectShiftToDelete'), false);
        return;
    }

    if (!confirm(t('deleteShiftConfirm'))) return;

    try {
        const query = window.location.search;
        const resp = await fetch('api/shifts/delete' + query, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: shiftId })
        });

        if (resp.ok) {
            shiftList = shiftList.filter(s => s.id !== shiftId);
            const form = document.querySelector('aside.card form.grid');
            if (form) form.reset();
            document.getElementById('shiftId').value = '';
            populateStaffDropdown();
            document.getElementById('form-title').textContent = t('shiftFormTitle');
            document.getElementById('form-title').setAttribute('data-i18n', 'shiftFormTitle');
            renderCalendar();
            showNotice(t('shiftDeleted'));
        } else {
            const err = await resp.json().catch(() => ({}));
            showNotice(err.error || t('shiftDeleteFailed'), false);
        }
    } catch (err) {
        showNotice(t('networkErrorShort') + ': ' + err.message, false);
    }
}

document.addEventListener('DOMContentLoaded', init);

let currentPayrollData = [];

async function initPayroll() {
    const today = new Date();
    let month = '' + (today.getMonth() + 1);
    if (month.length < 2) month = '0' + month;
    const yyyyMM = today.getFullYear() + '-' + month;
    document.getElementById('payrollMonth').value = yyyyMM;
    await fetchPayroll();
}

async function fetchPayroll() {
    const tbody = document.getElementById('payroll-tbody');
    tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);">${t('loadingData')}</td></tr>`;

    const yyyyMM = document.getElementById('payrollMonth').value;
    if (!yyyyMM) return;

    try {
        const query = window.location.search;
        let url = 'api/payroll' + query;
        if (query.includes('?')) {
            url += '&month=' + yyyyMM;
        } else {
            url += '?month=' + yyyyMM;
        }

        const resp = await fetch(url);
        if (resp.ok) {
            currentPayrollData = await resp.json();
            applyPayrollFilter();
        } else {
            tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--danger);">${t('loadDataFailed')}</td></tr>`;
        }
    } catch (e) {
        console.error('Error fetching payroll', e);
        tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--danger);">${t('networkErrorShort')}</td></tr>`;
    }
}

function applyPayrollFilter() {
    const roleFilter = document.getElementById('payrollRoleFilter').value;
    let filteredData = currentPayrollData;

    if (roleFilter !== 'All') {
        filteredData = currentPayrollData.filter(item => item.role === roleFilter);
    }
    renderPayroll(filteredData);
}

function renderPayroll(data) {
    const tbody = document.getElementById('payroll-tbody');
    tbody.innerHTML = '';

    if (!data || data.length === 0) {
        tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);">${t('payrollEmpty')}</td></tr>`;
        return;
    }

    data.forEach(item => {
        const tr = document.createElement('tr');
        tr.style.borderBottom = '1px solid var(--line)';
        tr.innerHTML = `
            <td style="padding: 12px;">${escapeHtml(item.staffName)}</td>
            <td style="padding: 12px;">${escapeHtml(roleScheduleText(item.role) || t('roleUnknown'))}</td>
            <td style="padding: 12px; text-align: center; font-weight: bold;">${item.totalShifts}</td>
            <td style="padding: 12px; text-align: center; font-weight: bold; color: var(--accent);">${item.totalHours} ${t('hoursUnit')}</td>
        `;
        tbody.appendChild(tr);
    });
}

function renderStaffList() {
    const tbody = document.getElementById('staff-list-tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    if (!staffList || staffList.length === 0) {
        tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);">${t('noStaff')}</td></tr>`;
        return;
    }

    staffList
        .slice()
        .sort((a, b) => Number(a.id) - Number(b.id))
        .forEach(staff => {
            const tr = document.createElement('tr');
            tr.style.borderBottom = '1px solid var(--line)';
            let statusColor = 'var(--good)';
            if (staff.status === 'Temp_Inactive') statusColor = 'var(--warn)';
            if (staff.status === 'Inactive' || staff.status === 'Perm_Inactive') statusColor = 'var(--danger)';

            tr.innerHTML = `
                <td style="padding: 12px;">${staff.id}</td>
                <td style="padding: 12px; font-weight: bold;">${escapeHtml(staff.name)}</td>
                <td style="padding: 12px; color: ${statusColor}; font-weight: bold;">${escapeHtml(staffStatusText(staff.status))}</td>
                <td style="padding: 12px; text-align: right;">
                    <button class="btn" style="padding: 4px 8px; font-size: 12px; margin-right: 5px;" onclick="editStaff(${staff.id})">${t('edit')}</button>
                    <button class="btn" style="padding: 4px 8px; font-size: 12px; color: var(--danger); border-color: var(--danger);" onclick="deleteStaff(${staff.id})">${t('delete')}</button>
                </td>
            `;
            tbody.appendChild(tr);
        });
}

function openStaffModal() {
    document.getElementById('staffForm').reset();
    document.getElementById('staffIdInput').readOnly = false;
    document.getElementById('staffModalTitle').textContent = t('addStaff');
    applyI18n();
    document.getElementById('staffModal').classList.remove('hidden');
}

function closeStaffModal() {
    document.getElementById('staffModal').classList.add('hidden');
}

function editStaff(id) {
    const staff = staffList.find(s => s.id === id);
    if (!staff) return;

    document.getElementById('staffIdInput').value = staff.id;
    document.getElementById('staffIdInput').readOnly = true;
    document.getElementById('staffNameInput').value = staff.name;
    document.getElementById('staffStatusInput').value = staff.status || 'Active';

    document.getElementById('staffModalTitle').textContent = t('editStaff');
    applyI18n();
    document.getElementById('staffModal').classList.remove('hidden');
}

async function saveStaff(e) {
    e.preventDefault();
    const staff = {
        id: parseInt(document.getElementById('staffIdInput').value, 10),
        name: document.getElementById('staffNameInput').value,
        role: "staff",
        status: document.getElementById('staffStatusInput').value,
        active: document.getElementById('staffStatusInput').value === 'Active',
        username: "",
        password: "",
        pin: "",
        overtime: false,
        shift: ''
    };

    try {
        const query = window.location.search;
        const resp = await fetch('api/staff/save' + query, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(staff)
        });

        if (resp.ok) {
            const saved = await resp.json();
            const idx = staffList.findIndex(s => s.id === saved.id);
            if (idx >= 0) staffList[idx] = saved;
            else staffList.push(saved);

            renderStaffList();
            populateStaffDropdown();
            closeStaffModal();
            alert(t('staffSaved'));
        } else {
            alert(t('staffSaveFailed') + ' ' + await resp.text());
        }
    } catch (err) {
        alert(t('networkErrorShort') + ': ' + err.message);
    }
}

async function deleteStaff(id) {
    if (!confirm(t('deleteStaffConfirm'))) return;

    try {
        const query = window.location.search;
        const resp = await fetch('api/staff/delete' + query, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: id })
        });

        if (resp.ok) {
            const staff = staffList.find(s => s.id === id);
            if (staff) {
                staff.active = false;
                staff.status = 'Inactive';
            }
            renderStaffList();
            populateStaffDropdown();
            alert(t('staffDeleted'));
        } else {
            alert(t('staffDeleteFailed') + ' ' + await resp.text());
        }
    } catch (err) {
        alert(t('networkErrorShort') + ': ' + err.message);
    }
}

window.renderPage = () => {
    populateStaffDropdown(document.getElementById('staffId')?.value);
    renderCalendar();
    renderStaffList();
    applyPayrollFilter();
};
