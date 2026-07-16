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
    const days = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    return days[date.getDay()];
}

async function init() {
    await fetchStaffAndShifts();
    await initPayroll();
}

async function fetchStaffAndShifts() {
    try {
        const query = window.location.search; // includes ?tabSession=...
        const staffResp = await fetch('api/staff' + query);
        if (staffResp.ok) {
            staffList = await staffResp.json();
        }
        const shiftResp = await fetch('api/shifts' + query);
        if (shiftResp.ok) {
            shiftList = await shiftResp.json();
        }
        populateStaffDropdown();
        renderCalendar();
    } catch (e) {
        console.error("Error fetching data", e);
    }
}

function populateStaffDropdown() {
    const select = document.getElementById('staffId');
    select.innerHTML = '<option value="">-- Chọn nhân viên --</option>';
    staffList.forEach(staff => {
        const option = document.createElement('option');
        option.value = staff.id;
        option.textContent = `${staff.name} (${staff.role})`;
        select.appendChild(option);
    });
}

function renderCalendar() {
    const grid = document.getElementById('calendar-grid');
    grid.innerHTML = ''; // clear

    // 1. Render Header Row
    grid.appendChild(createCell('calendar-header', 'Ca làm'));
    
    const weekDates = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date(currentWeekStart);
        d.setDate(d.getDate() + i);
        weekDates.push(formatDate(d));
        grid.appendChild(createCell('calendar-header', `${getDayName(d)}<br><small style="font-weight:normal">${d.getDate()}/${d.getMonth()+1}</small>`));
    }

    // 2. Render Shift Rows
    const fixedShifts = [
        { name: 'Ca Sáng', hours: '06:00 - 12:00' },
        { name: 'Ca Chiều', hours: '12:00 - 18:00' },
        { name: 'Ca Tối', hours: '18:00 - 23:00' }
    ];

    fixedShifts.forEach(shiftData => {
        // Shift Name Cell
        const nameCell = document.createElement('div');
        nameCell.className = 'calendar-cell staff-name-col';
        nameCell.innerHTML = `
            ${shiftData.name}
            <span class="staff-role">${shiftData.hours}</span>
        `;
        grid.appendChild(nameCell);

        // Days Cells
        weekDates.forEach(dateStr => {
            const cell = document.createElement('div');
            cell.className = 'calendar-cell';
            
            // Find shifts for this shiftName on this date
            const shifts = shiftList.filter(s => s.shiftName === shiftData.name && s.date === dateStr);
            
            const roles = [
                { id: 'Barista', label: typeof t === 'function' ? t('roleBarista') : 'Barista' },
                { id: 'Cashier', label: typeof t === 'function' ? t('roleCashier') : 'Thu ngân' },
                { id: 'Waiter', label: typeof t === 'function' ? t('roleRunner') : 'Phục vụ' }
            ];
            
            roles.forEach(role => {
                const roleShifts = shifts.filter(s => s.assignedRole === role.id);
                
                const roleGroup = document.createElement('div');
                roleGroup.className = 'role-group';
                
                const roleTitle = document.createElement('div');
                roleTitle.className = 'role-title';
                roleTitle.textContent = role.label;
                roleGroup.appendChild(roleTitle);
                
                if (roleShifts.length > 0) {
                    roleShifts.forEach(shift => {
                        const shiftEl = document.createElement('div');
                        shiftEl.className = 'shift-block';
                        shiftEl.style.cursor = 'pointer';
                        shiftEl.onclick = () => editShift(shift);
                        
                        let statusClass = 'status-pending';
                        if (shift.status === 'Đã làm' || shift.status === 'Hoàn thành') statusClass = 'status-done';
                        if (shift.status === 'Vắng' || shift.status === 'Nghỉ') statusClass = 'status-absent';
                        
                        let displayStatus = shift.status;
                        if (typeof t === 'function') {
                            if (shift.status === 'Đã xếp lịch') displayStatus = t('statusScheduled');
                            else if (shift.status === 'Đã làm') displayStatus = t('statusDone');
                            else if (shift.status === 'Vắng') displayStatus = t('statusAbsent');
                        }
                        
                        shiftEl.innerHTML = `
                            <span class="shift-name">${shift.staffName}</span>
                            <span class="shift-status ${statusClass}">${displayStatus}</span>
                        `;
                        roleGroup.appendChild(shiftEl);
                    });
                } else {
                    const warnEl = document.createElement('div');
                    warnEl.className = 'role-warning';
                    warnEl.innerHTML = `⚠ Thiếu người`;
                    roleGroup.appendChild(warnEl);
                }

                // add button for THIS specific role
                const addBtn = document.createElement('div');
                addBtn.className = 'role-add-btn';
                addBtn.innerHTML = '+';
                addBtn.title = `Thêm ${role.label}`;
                addBtn.onclick = () => prepareAddShift(shiftData.name, dateStr, role.id);
                roleGroup.appendChild(addBtn);

                cell.appendChild(roleGroup);
            });

            grid.appendChild(cell);
        });
    });
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
    document.getElementById('staffId').value = '';
    document.getElementById('shiftDate').value = dateStr;
    document.getElementById('shiftName').value = shiftName;
    document.getElementById('assignedRole').value = roleId || 'Barista';
    document.getElementById('notes').value = '';
    document.getElementById('status').value = 'Đã xếp lịch';
    
    document.getElementById('form-title').textContent = typeof t === 'function' ? t('addShiftTitle') : 'Thêm nhân viên vào ca';
    document.getElementById('form-title').setAttribute('data-i18n', 'addShiftTitle');
    
    // Scroll to form on mobile
    document.getElementById('form-title').scrollIntoView({ behavior: 'smooth' });
}

function editShift(shift) {
    document.getElementById('shiftId').value = shift.id;
    document.getElementById('staffId').value = shift.staffId;
    document.getElementById('shiftDate').value = shift.date;
    document.getElementById('shiftName').value = shift.shiftName;
    document.getElementById('assignedRole').value = shift.assignedRole || 'Barista';
    document.getElementById('notes').value = shift.notes || '';
    document.getElementById('status').value = shift.status;
    
    document.getElementById('form-title').textContent = typeof t === 'function' ? t('editShiftTitle') : 'Sửa phân công';
    document.getElementById('form-title').setAttribute('data-i18n', 'editShiftTitle');
    
    // Scroll to form on mobile
    document.getElementById('form-title').scrollIntoView({ behavior: 'smooth' });
}

async function saveShift(e) {
    e.preventDefault();
    
    const shiftId = document.getElementById('shiftId').value;
    const staffId = parseInt(document.getElementById('staffId').value);
    
    // Find staff name
    const staff = staffList.find(s => s.id === staffId);
    
    const shiftName = document.getElementById('shiftName').value;
    const shiftDate = document.getElementById('shiftDate').value;
    const status = document.getElementById('status').value;
    
    // Validation: Cannot set status to "Đã làm" or "Vắng" for future dates
    if (status === 'Đã làm' || status === 'Vắng') {
        const today = new Date();
        today.setHours(0,0,0,0);
        const selectedDate = new Date(shiftDate);
        if (selectedDate > today) {
            showMessage('Lỗi: Chỉ có thể đánh dấu "Đã làm" hoặc "Vắng" cho các ca làm trong ngày hôm nay hoặc quá khứ.', false);
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
        date: document.getElementById('shiftDate').value,
        shiftName: shiftName,
        hours: hours,
        assignedRole: document.getElementById('assignedRole').value,
        notes: document.getElementById('notes').value,
        status: document.getElementById('status').value
    };
    
    try {
        const query = window.location.search;
        const resp = await fetch('api/shifts' + query, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newShift)
        });
        
        if (resp.ok) {
            const savedShift = await resp.json();
            if (shiftId) {
                const idx = shiftList.findIndex(s => s.id === savedShift.id);
                if (idx !== -1) shiftList[idx] = savedShift;
            } else {
                shiftList.push(savedShift);
            }
            
            // reset form
            e.target.reset();
            document.getElementById('shiftId').value = '';
            document.getElementById('form-title').textContent = typeof t === 'function' ? t('shiftFormTitle') : 'Phân công ca làm';
            document.getElementById('form-title').setAttribute('data-i18n', 'shiftFormTitle');
            
            renderCalendar();
            
            const msg = document.getElementById('message');
            msg.textContent = typeof t === 'function' ? t('save') + ' OK' : 'Đã lưu ca làm thành công!';
            msg.className = 'notice';
            setTimeout(() => { msg.className = 'notice hidden'; }, 3000);
        } else {
            alert('Lỗi lưu ca làm: ' + await resp.text());
        }
    } catch (err) {
        alert('Lỗi mạng: ' + err.message);
    }
}

async function deleteShift() {
    const shiftId = document.getElementById('shiftId').value;
    if (!shiftId) return;
    
    if (!confirm('Bạn có chắc chắn muốn xóa ca làm này?')) return;
    
    try {
        const query = window.location.search;
        const resp = await fetch('api/shifts/delete' + query, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: shiftId })
        });
        
        if (resp.ok) {
            shiftList = shiftList.filter(s => s.id !== shiftId);
            
            // reset form
            document.querySelector('.grid').reset();
            document.getElementById('shiftId').value = '';
            document.getElementById('form-title').textContent = typeof t === 'function' ? t('shiftFormTitle') : 'Phân công ca làm';
            document.getElementById('form-title').setAttribute('data-i18n', 'shiftFormTitle');
            
            renderCalendar();
            
            const msg = document.getElementById('message');
            msg.textContent = typeof t === 'function' ? t('delete') + ' OK' : 'Đã xóa ca làm!';
            msg.className = 'notice';
            setTimeout(() => { msg.className = 'notice hidden'; }, 3000);
        } else {
            alert('Lỗi xóa ca làm: ' + await resp.text());
        }
    } catch (err) {
        alert('Lỗi mạng: ' + err.message);
    }
}

// Initialize on load
document.addEventListener('DOMContentLoaded', init);

// Payroll logic
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
    tbody.innerHTML = '<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);">Đang tải dữ liệu...</td></tr>';
    
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
            tbody.innerHTML = '<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--danger);">Lỗi tải dữ liệu.</td></tr>';
        }
    } catch (e) {
        console.error('Error fetching payroll', e);
        tbody.innerHTML = '<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--danger);">Lỗi mạng.</td></tr>';
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
        tbody.innerHTML = '<tr><td colspan="4" style="padding: 20px; text-align: center; color: var(--muted);">Không có dữ liệu phù hợp với bộ lọc (hoặc chưa có ca nào "Đã làm").</td></tr>';
        return;
    }
    
    data.forEach(item => {
        const tr = document.createElement('tr');
        tr.style.borderBottom = '1px solid var(--line)';
        tr.innerHTML = `
            <td style="padding: 12px;">${item.staffName}</td>
            <td style="padding: 12px;">${item.role || 'Chưa rõ'}</td>
            <td style="padding: 12px; text-align: center; font-weight: bold;">${item.totalShifts}</td>
            <td style="padding: 12px; text-align: center; font-weight: bold; color: var(--accent);">${item.totalHours} giờ</td>
        `;
        tbody.appendChild(tr);
    });
}
