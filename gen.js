const fs = require('fs');
const staffs = [
    {id: 1, name: "Phạm Minh Tuấn"},
    {id: 2, name: "Lê Quốc Bảo"},
    {id: 3, name: "Nguyễn Thu Trà"},
    {id: 4, name: "Đặng Văn Phong"},
    {id: 5, name: "Trần Tuấn Dũng"},
    {id: 6, name: "Lý Thùy Linh"},
    {id: 7, name: "Bùi Quang Huy"},
    {id: 8, name: "Võ Tấn Phát"},
    {id: 9, name: "Hồ Ngọc Mai"},
    {id: 10, name: "Đỗ Minh Châu"}
];

const dates = ['2026-07-06', '2026-07-07', '2026-07-08', '2026-07-09', '2026-07-10', '2026-07-11', '2026-07-12'];
const shifts = [
    {name: 'Ca Sáng', hours: '06:00 - 12:00'},
    {name: 'Ca Chiều', hours: '12:00 - 18:00'},
    {name: 'Ca Tối', hours: '18:00 - 23:00'}
];
const roles = ['Barista', 'Cashier', 'Waiter'];

let sql = "DELETE FROM dbo.Shifts WHERE shiftDate >= '2026-07-06' AND shiftDate <= '2026-07-12';\n";
sql += "INSERT INTO dbo.Shifts (id, staffId, staffName, shiftDate, shiftName, hours, status, notes, assignedRole) VALUES\n";

let staffIndex = 0;
let values = [];
let idCounter = 100;

for (let d of dates) {
    for (let s of shifts) {
        for (let r of roles) {
            let st = staffs[staffIndex % staffs.length];
            // Randomly some are absent but mostly done
            let status = (Math.random() < 0.1) ? "Vắng" : "Đã làm";
            values.push(`('mock-full-${idCounter++}', ${st.id}, N'${st.name}', '${d}', N'${s.name}', '${s.hours}', N'${status}', '', '${r}')`);
            staffIndex++;
        }
    }
}

sql += values.join(",\n") + ";\n";
fs.writeFileSync('generate_full_mock.sql', sql);
