const Payroll = require('../models/Payroll');
const Attendance = require('../models/Attendance');
const Shift = require('../models/Shift');
const User = require('../models/User');

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Get start/end Date objects for a month string "YYYY-MM".
 */
function monthRange(monthStr) {
    const [year, mon] = monthStr.split('-').map(Number);
    const start = new Date(year, mon - 1, 1);         // 1st of month 00:00
    const end = new Date(year, mon, 1);                // 1st of NEXT month 00:00
    return { start, end };
}

/**
 * Calculate hours between two dates.
 */
function hoursBetween(a, b) {
    return Math.abs(b.getTime() - a.getTime()) / 3600000;
}

// ── Generate Payroll ─────────────────────────────────────────────────────────

// @desc    Generate payroll for a given month (all staff or single staff)
// @route   POST /api/payroll/generate
// @access  Private/Admin
const generatePayroll = async (req, res) => {
    try {
        const { month, staffId: singleStaffId } = req.body;

        if (!month || !/^\d{4}-\d{2}$/.test(month)) {
            return res
                .status(400)
                .json({ message: 'Month is required in YYYY-MM format' });
        }

        const { start, end } = monthRange(month);

        // 1. Get all attendance records for the month that have both clock in/out
        const attendanceQuery = {
            clockInTime: { $gte: start, $lt: end },
            clockOutTime: { $exists: true, $ne: null },
        };
        if (singleStaffId) attendanceQuery.staffId = singleStaffId;

        const records = await Attendance.find(attendanceQuery).populate('shiftId');

        // 2. Group by staff
        const staffMap = {};
        for (const rec of records) {
            const sid = rec.staffId.toString();
            if (!staffMap[sid]) {
                staffMap[sid] = { totalWorked: 0, scheduledTotal: 0 };
            }

            // Actual worked hours
            const worked = hoursBetween(rec.clockInTime, rec.clockOutTime);
            staffMap[sid].totalWorked += worked;

            // Scheduled hours (from shift)
            if (rec.shiftId && rec.shiftId.startTime && rec.shiftId.endTime) {
                const [sh, sm] = rec.shiftId.startTime.split(':').map(Number);
                const [eh, em] = rec.shiftId.endTime.split(':').map(Number);
                const scheduled = (eh + em / 60) - (sh + sm / 60);
                staffMap[sid].scheduledTotal += Math.max(scheduled, 0);
            }
        }

        // 3. Always include ALL active staff (those without attendance get 0 hours)
        if (!singleStaffId) {
            const allStaff = await User.find({
                isActive: true,
                role: 'staff',
            });
            for (const u of allStaff) {
                if (!staffMap[u._id.toString()]) {
                    staffMap[u._id.toString()] = { totalWorked: 0, scheduledTotal: 0 };
                }
            }
        }

        const users = await User.find({
            _id: { $in: Object.keys(staffMap) },
        });

        const userMap = {};
        for (const u of users) {
            userMap[u._id.toString()] = u;
        }

        // 4. Upsert payroll records
        const results = [];
        for (const sid of Object.keys(staffMap)) {
            const user = userMap[sid];
            if (!user) continue;

            const { totalWorked, scheduledTotal } = staffMap[sid];
            const overtime = Math.max(totalWorked - scheduledTotal, 0);
            const rate = user.hourlyRate || 0;
            const grossPay = parseFloat((totalWorked * rate).toFixed(2));

            // Check for existing payroll to preserve adjustments
            const existing = await Payroll.findOne({ staffId: sid, month });

            if (existing && existing.status === 'finalized') {
                // Don't overwrite finalized payroll
                results.push(existing);
                continue;
            }

            const adjustments = existing ? existing.adjustments : [];
            const adjTotal = adjustments.reduce((s, a) => s + a.amount, 0);
            const finalPay = parseFloat((grossPay + adjTotal).toFixed(2));

            const payroll = await Payroll.findOneAndUpdate(
                { staffId: sid, month },
                {
                    totalHoursWorked: parseFloat(totalWorked.toFixed(2)),
                    overtimeHours: parseFloat(overtime.toFixed(2)),
                    hourlyRate: rate,
                    grossPay,
                    adjustments,
                    finalPay,
                    generatedBy: req.user._id,
                    status: 'draft',
                },
                { new: true, upsert: true, setDefaultsOnInsert: true }
            );

            await payroll.populate('staffId', 'name email department');
            results.push(payroll);
        }

        res.status(201).json({
            month,
            count: results.length,
            payroll: results,
        });
    } catch (error) {
        if (error.code === 11000) {
            return res
                .status(409)
                .json({ message: 'Payroll already exists for this period' });
        }
        console.error('GeneratePayroll error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// ── Get Payroll ──────────────────────────────────────────────────────────────

// @desc    List payroll records (optionally filtered by month)
// @route   GET /api/payroll
// @access  Private/Admin
const getPayroll = async (req, res) => {
    try {
        const query = {};
        if (req.query.month) query.month = req.query.month;

        const records = await Payroll.find(query)
            .populate('staffId', 'name email department role')
            .populate('generatedBy', 'name')
            .sort({ month: -1, 'staffId.name': 1 });

        res.json(records);
    } catch (error) {
        console.error('GetPayroll error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Get payroll for a single staff member
// @route   GET /api/payroll/:staffId
// @access  Private/Admin
const getStaffPayroll = async (req, res) => {
    try {
        const query = { staffId: req.params.staffId };
        if (req.query.month) query.month = req.query.month;

        const records = await Payroll.find(query)
            .populate('staffId', 'name email department')
            .sort({ month: -1 });

        res.json(records);
    } catch (error) {
        console.error('GetStaffPayroll error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// ── Adjust Payroll ───────────────────────────────────────────────────────────

// @desc    Add an adjustment to a payroll record
// @route   PUT /api/payroll/:id/adjust
// @access  Private/Admin
const adjustPayroll = async (req, res) => {
    try {
        const { description, amount } = req.body;

        if (!description || amount === undefined) {
            return res
                .status(400)
                .json({ message: 'Description and amount are required' });
        }

        const payroll = await Payroll.findById(req.params.id);
        if (!payroll) {
            return res.status(404).json({ message: 'Payroll record not found' });
        }

        if (payroll.status === 'finalized') {
            return res
                .status(403)
                .json({ message: 'Cannot adjust finalized payroll' });
        }

        // Add the adjustment
        payroll.adjustments.push({
            description,
            amount: parseFloat(amount),
            addedBy: req.user._id,
        });

        // Recalculate final pay
        const adjTotal = payroll.adjustments.reduce((s, a) => s + a.amount, 0);
        payroll.finalPay = parseFloat((payroll.grossPay + adjTotal).toFixed(2));

        await payroll.save();
        await payroll.populate('staffId', 'name email department');

        res.json(payroll);
    } catch (error) {
        console.error('AdjustPayroll error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// ── Finalize Payroll ─────────────────────────────────────────────────────────

// @desc    Lock a payroll record (no more changes)
// @route   PUT /api/payroll/:id/finalize
// @access  Private/Admin
const finalizePayroll = async (req, res) => {
    try {
        const payroll = await Payroll.findById(req.params.id);
        if (!payroll) {
            return res.status(404).json({ message: 'Payroll record not found' });
        }

        if (payroll.status === 'finalized') {
            return res
                .status(409)
                .json({ message: 'Payroll is already finalized' });
        }

        payroll.status = 'finalized';
        await payroll.save();
        await payroll.populate('staffId', 'name email department');

        res.json(payroll);
    } catch (error) {
        console.error('FinalizePayroll error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

module.exports = {
    generatePayroll,
    getPayroll,
    getStaffPayroll,
    adjustPayroll,
    finalizePayroll,
};
