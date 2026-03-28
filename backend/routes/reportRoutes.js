const express = require('express');
const {
    exportRota,
    exportPayroll,
    exportAttendance,
    exportStaff,
    exportLeave,
} = require('../controllers/reportController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// All report routes require admin authentication
router.use(protect);
router.use(authorize('admin'));

router.get('/rota', exportRota);
router.get('/payroll', exportPayroll);
router.get('/attendance', exportAttendance);
router.get('/staff', exportStaff);
router.get('/leave', exportLeave);

module.exports = router;
