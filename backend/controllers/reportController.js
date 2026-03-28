const ExcelJS = require('exceljs');
const User = require('../models/User');
const Shift = require('../models/Shift');
const Attendance = require('../models/Attendance');
const Payroll = require('../models/Payroll');
const Leave = require('../models/Leave');

// ── Helper: set response headers for Excel download ─────────────────────────
function setExcelHeaders(res, filename) {
    res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
}

// ── Helper: style a header row ──────────────────────────────────────────────
function styleHeader(sheet) {
    const headerRow = sheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
    headerRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF1B2A4A' }, // Navy
    };
    headerRow.alignment = { vertical: 'middle', horizontal: 'center' };
    headerRow.height = 24;
    sheet.columns.forEach((col) => {
        col.width = Math.max(col.width || 12, 14);
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. ROTA EXPORT
// ═══════════════════════════════════════════════════════════════════════════════

// @desc    Export rota as Excel
// @route   GET /api/reports/rota?month=YYYY-MM
// @access  Private/Admin
const exportRota = async (req, res) => {
    try {
        const month = req.query.month;
        const query = {};

        if (month) {
            const [y, m] = month.split('-').map(Number);
            const start = new Date(y, m - 1, 1);
            const end = new Date(y, m, 1);
            query.date = { $gte: start, $lt: end };
        }

        const shifts = await Shift.find(query)
            .populate('staffId', 'name email department')
            .sort({ date: 1, startTime: 1 });

        const wb = new ExcelJS.Workbook();
        wb.creator = 'CareShift';
        const ws = wb.addWorksheet('Rota');

        ws.columns = [
            { header: 'Date', key: 'date', width: 14 },
            { header: 'Day', key: 'day', width: 12 },
            { header: 'Staff Name', key: 'name', width: 20 },
            { header: 'Email', key: 'email', width: 25 },
            { header: 'Department', key: 'dept', width: 15 },
            { header: 'Start', key: 'start', width: 10 },
            { header: 'End', key: 'end', width: 10 },
            { header: 'Location', key: 'location', width: 18 },
            { header: 'Status', key: 'status', width: 12 },
        ];
        styleHeader(ws);

        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        for (const s of shifts) {
            const d = new Date(s.date);
            ws.addRow({
                date: d.toISOString().split('T')[0],
                day: days[d.getDay()],
                name: s.staffId?.name || 'Unassigned',
                email: s.staffId?.email || '',
                dept: s.staffId?.department || '',
                start: s.startTime,
                end: s.endTime,
                location: s.location || '',
                status: s.status,
            });
        }

        const filename = `CareShift_Rota_${month || 'all'}.xlsx`;
        setExcelHeaders(res, filename);
        await wb.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('ExportRota error:', error.message);
        res.status(500).json({ message: 'Failed to generate rota report' });
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 2. PAYROLL EXPORT
// ═══════════════════════════════════════════════════════════════════════════════

// @desc    Export payroll as Excel
// @route   GET /api/reports/payroll?month=YYYY-MM
// @access  Private/Admin
const exportPayroll = async (req, res) => {
    try {
        const month = req.query.month;
        const query = {};
        if (month) query.month = month;

        const records = await Payroll.find(query)
            .populate('staffId', 'name email department')
            .sort({ month: -1 });

        const wb = new ExcelJS.Workbook();
        wb.creator = 'CareShift';
        const ws = wb.addWorksheet('Payroll');

        ws.columns = [
            { header: 'Month', key: 'month', width: 12 },
            { header: 'Staff Name', key: 'name', width: 20 },
            { header: 'Email', key: 'email', width: 25 },
            { header: 'Department', key: 'dept', width: 15 },
            { header: 'Hours Worked', key: 'hours', width: 14 },
            { header: 'Overtime', key: 'overtime', width: 12 },
            { header: 'Rate (£)', key: 'rate', width: 10 },
            { header: 'Gross Pay (£)', key: 'gross', width: 14 },
            { header: 'Adjustments (£)', key: 'adj', width: 16 },
            { header: 'Final Pay (£)', key: 'final', width: 14 },
            { header: 'Status', key: 'status', width: 12 },
        ];
        styleHeader(ws);

        for (const r of records) {
            const adjTotal = r.adjustments.reduce((s, a) => s + a.amount, 0);
            ws.addRow({
                month: r.month,
                name: r.staffId?.name || '',
                email: r.staffId?.email || '',
                dept: r.staffId?.department || '',
                hours: r.totalHoursWorked,
                overtime: r.overtimeHours,
                rate: r.hourlyRate,
                gross: r.grossPay,
                adj: adjTotal,
                final: r.finalPay,
                status: r.status,
            });
        }

        // Totals row
        const lastRow = ws.lastRow.number;
        const totalsRow = ws.addRow({
            month: '',
            name: 'TOTALS',
            email: '',
            dept: '',
        });
        totalsRow.font = { bold: true };
        totalsRow.getCell('hours').value = {
            formula: `SUM(E2:E${lastRow})`,
        };
        totalsRow.getCell('gross').value = {
            formula: `SUM(H2:H${lastRow})`,
        };
        totalsRow.getCell('final').value = {
            formula: `SUM(J2:J${lastRow})`,
        };

        const filename = `CareShift_Payroll_${month || 'all'}.xlsx`;
        setExcelHeaders(res, filename);
        await wb.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('ExportPayroll error:', error.message);
        res.status(500).json({ message: 'Failed to generate payroll report' });
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 3. ATTENDANCE EXPORT
// ═══════════════════════════════════════════════════════════════════════════════

// @desc    Export attendance log as Excel
// @route   GET /api/reports/attendance?month=YYYY-MM
// @access  Private/Admin
const exportAttendance = async (req, res) => {
    try {
        const month = req.query.month;
        const query = {};

        if (month) {
            const [y, m] = month.split('-').map(Number);
            const start = new Date(y, m - 1, 1);
            const end = new Date(y, m, 1);
            query.clockInTime = { $gte: start, $lt: end };
        }

        const records = await Attendance.find(query)
            .populate('staffId', 'name email department')
            .populate('shiftId', 'date startTime endTime')
            .sort({ clockInTime: -1 });

        const wb = new ExcelJS.Workbook();
        wb.creator = 'CareShift';
        const ws = wb.addWorksheet('Attendance');

        ws.columns = [
            { header: 'Date', key: 'date', width: 14 },
            { header: 'Staff Name', key: 'name', width: 20 },
            { header: 'Email', key: 'email', width: 25 },
            { header: 'Scheduled', key: 'scheduled', width: 16 },
            { header: 'Clock In', key: 'clockIn', width: 18 },
            { header: 'Clock Out', key: 'clockOut', width: 18 },
            { header: 'Hours', key: 'hours', width: 10 },
            { header: 'Late (min)', key: 'late', width: 12 },
            { header: 'Status', key: 'status', width: 12 },
        ];
        styleHeader(ws);

        for (const r of records) {
            const hours =
                r.clockInTime && r.clockOutTime
                    ? (
                        Math.abs(r.clockOutTime - r.clockInTime) / 3600000
                    ).toFixed(2)
                    : 0;

            ws.addRow({
                date: r.shiftId?.date
                    ? new Date(r.shiftId.date).toISOString().split('T')[0]
                    : '',
                name: r.staffId?.name || '',
                email: r.staffId?.email || '',
                scheduled: r.shiftId
                    ? `${r.shiftId.startTime} - ${r.shiftId.endTime}`
                    : '',
                clockIn: r.clockInTime
                    ? new Date(r.clockInTime).toLocaleTimeString('en-GB')
                    : '',
                clockOut: r.clockOutTime
                    ? new Date(r.clockOutTime).toLocaleTimeString('en-GB')
                    : 'Missing',
                hours: parseFloat(hours),
                late: r.lateMinutes || 0,
                status: r.status,
            });
        }

        const filename = `CareShift_Attendance_${month || 'all'}.xlsx`;
        setExcelHeaders(res, filename);
        await wb.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('ExportAttendance error:', error.message);
        res.status(500).json({ message: 'Failed to generate attendance report' });
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 4. STAFF LIST EXPORT
// ═══════════════════════════════════════════════════════════════════════════════

// @desc    Export staff list as Excel
// @route   GET /api/reports/staff
// @access  Private/Admin
const exportStaff = async (req, res) => {
    try {
        const users = await User.find({ isActive: true }).sort({ name: 1 });

        const wb = new ExcelJS.Workbook();
        wb.creator = 'CareShift';
        const ws = wb.addWorksheet('Staff');

        ws.columns = [
            { header: 'Name', key: 'name', width: 22 },
            { header: 'Email', key: 'email', width: 28 },
            { header: 'Role', key: 'role', width: 10 },
            { header: 'Phone', key: 'phone', width: 16 },
            { header: 'Department', key: 'dept', width: 16 },
            { header: 'Hourly Rate (£)', key: 'rate', width: 16 },
            { header: 'Weekly Hours', key: 'weekly', width: 14 },
            { header: 'Annual Leave Bal (h)', key: 'leave', width: 20 },
        ];
        styleHeader(ws);

        for (const u of users) {
            ws.addRow({
                name: u.name,
                email: u.email,
                role: u.role,
                phone: u.phone || '',
                dept: u.department || '',
                rate: u.hourlyRate || 0,
                weekly: u.weeklyHours || 40,
                leave: u.annualLeaveBalance,
            });
        }

        setExcelHeaders(res, 'CareShift_Staff_List.xlsx');
        await wb.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('ExportStaff error:', error.message);
        res.status(500).json({ message: 'Failed to generate staff report' });
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 5. LEAVE EXPORT
// ═══════════════════════════════════════════════════════════════════════════════

// @desc    Export leave requests as Excel
// @route   GET /api/reports/leave?month=YYYY-MM
// @access  Private/Admin
const exportLeave = async (req, res) => {
    try {
        const month = req.query.month;
        const query = {};

        if (month) {
            const [y, m] = month.split('-').map(Number);
            const start = new Date(y, m - 1, 1);
            const end = new Date(y, m, 1);
            query.startDate = { $gte: start, $lt: end };
        }

        const records = await Leave.find(query)
            .populate('staffId', 'name email department')
            .sort({ startDate: 1 });

        const wb = new ExcelJS.Workbook();
        wb.creator = 'CareShift';
        const ws = wb.addWorksheet('Leave');

        ws.columns = [
            { header: 'Staff', key: 'staff', width: 22 },
            { header: 'Email', key: 'email', width: 26 },
            { header: 'Department', key: 'dept', width: 16 },
            { header: 'Leave Type', key: 'type', width: 18 },
            { header: 'Start Date', key: 'start', width: 14 },
            { header: 'End Date', key: 'end', width: 14 },
            { header: 'Hours', key: 'hours', width: 10 },
            { header: 'Status', key: 'status', width: 12 },
            { header: 'Reason', key: 'reason', width: 30 },
        ];
        styleHeader(ws);

        const typeLabels = {
            annual: 'Annual Leave',
            sick: 'Sick Leave (SSP)',
            maternity: 'Maternity',
            paternity: 'Paternity',
            shared_parental: 'Shared Parental',
            adoption: 'Adoption',
            parental: 'Parental',
            dependants: 'Dependants',
            compassionate: 'Compassionate',
            neonatal: 'Neonatal Care',
            carers: "Carer's Leave",
            public_duties: 'Public Duties',
            study: 'Study/Training',
            unpaid: 'Unpaid Leave',
        };

        for (const l of records) {
            ws.addRow({
                staff: l.staffId?.name || 'Unknown',
                email: l.staffId?.email || '',
                dept: l.staffId?.department || '',
                type: typeLabels[l.leaveType] || l.leaveType,
                start: new Date(l.startDate).toLocaleDateString('en-GB'),
                end: new Date(l.endDate).toLocaleDateString('en-GB'),
                hours: l.totalHours,
                status: l.status,
                reason: l.reason || '',
            });
        }

        const filename = `CareShift_Leave_${month || 'all'}.xlsx`;
        setExcelHeaders(res, filename);
        await wb.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('ExportLeave error:', error.message);
        res.status(500).json({ message: 'Failed to generate leave report' });
    }
};

module.exports = { exportRota, exportPayroll, exportAttendance, exportStaff, exportLeave };
