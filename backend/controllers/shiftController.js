const { validationResult } = require('express-validator');
const Shift = require('../models/Shift');

// @desc    Create a new shift
// @route   POST /api/shifts
// @access  Private/Admin
const createShift = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { staffId, date, startTime, endTime, location, notes, visits } = req.body;

    const shift = await Shift.create({
      staffId,
      date,
      startTime,
      endTime,
      location,
      notes,
      visits: Array.isArray(visits) ? visits : undefined,
      createdBy: req.user._id,
    });

    // Populate staff details before returning
    await shift.populate('staffId', 'name email');

    res.status(201).json(shift);
  } catch (error) {
    console.error('CreateShift error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get shifts (admin sees all, staff sees their own)
// @route   GET /api/shifts
// @access  Private
const getShifts = async (req, res) => {
  try {
    let query = {};

    // Staff can only see their own shifts
    if (req.user.role === 'staff') {
      query.staffId = req.user._id;
    }

    // Optional date filter: ?date=2025-03-01
    if (req.query.date) {
      const filterDate = new Date(req.query.date);
      const nextDay = new Date(filterDate);
      nextDay.setDate(nextDay.getDate() + 1);
      query.date = { $gte: filterDate, $lt: nextDay };
    }

    // Optional staff filter (admin only): ?staffId=xxx
    if (req.query.staffId && req.user.role === 'admin') {
      query.staffId = req.query.staffId;
    }

    // Optional week filter: ?week=2025-03-01 (gets Mon-Sun of that week)
    if (req.query.week) {
      const weekStart = new Date(req.query.week);
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 7);
      query.date = { $gte: weekStart, $lt: weekEnd };
    }

    const shifts = await Shift.find(query)
      .populate('staffId', 'name email role')
      .populate('visits.client', 'name address coordinates')
      .sort({ date: 1, startTime: 1 });

    res.json(shifts);
  } catch (error) {
    console.error('GetShifts error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get single shift
// @route   GET /api/shifts/:id
// @access  Private
const getShiftById = async (req, res) => {
  try {
    const shift = await Shift.findById(req.params.id)
      .populate('staffId', 'name email')
      .populate('visits.client', 'name address coordinates');

    if (!shift) {
      return res.status(404).json({ message: 'Shift not found' });
    }

    // Staff can only view their own shifts
    if (
      req.user.role === 'staff' &&
      shift.staffId._id.toString() !== req.user._id.toString()
    ) {
      return res.status(403).json({ message: 'Not authorized to view this shift' });
    }

    res.json(shift);
  } catch (error) {
    console.error('GetShiftById error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Update shift
// @route   PUT /api/shifts/:id
// @access  Private/Admin
const updateShift = async (req, res) => {
  try {
    const { staffId, date, startTime, endTime, location, coordinates, notes, status, visits } = req.body;

    const shift = await Shift.findById(req.params.id);

    if (!shift) {
      return res.status(404).json({ message: 'Shift not found' });
    }

    if (staffId) shift.staffId = staffId;
    if (date) shift.date = date;
    if (startTime) shift.startTime = startTime;
    if (endTime) shift.endTime = endTime;
    if (location !== undefined) shift.location = location;
    if (coordinates !== undefined) shift.coordinates = coordinates;
    if (notes !== undefined) shift.notes = notes;
    if (status) shift.status = status;
    if (visits !== undefined) shift.visits = visits;

    const updatedShift = await shift.save();
    await updatedShift.populate('staffId', 'name email');

    res.json(updatedShift);
  } catch (error) {
    console.error('UpdateShift error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Delete shift
// @route   DELETE /api/shifts/:id
// @access  Private/Admin
const deleteShift = async (req, res) => {
  try {
    const shift = await Shift.findById(req.params.id);

    if (!shift) {
      return res.status(404).json({ message: 'Shift not found' });
    }

    await shift.deleteOne();
    res.json({ message: 'Shift deleted successfully' });
  } catch (error) {
    console.error('DeleteShift error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get shift statistics
// @route   GET /api/shifts/stats
// @access  Private
const getShiftStats = async (req, res) => {
  try {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart);
    todayEnd.setDate(todayEnd.getDate() + 1);

    const totalShifts = await Shift.countDocuments();
    const todayShifts = await Shift.countDocuments({
      date: { $gte: todayStart, $lt: todayEnd },
    });
    const upcomingShifts = await Shift.countDocuments({
      date: { $gte: todayEnd },
      status: 'scheduled',
    });

    res.json({ totalShifts, todayShifts, upcomingShifts });
  } catch (error) {
    console.error('GetShiftStats error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { createShift, getShifts, getShiftById, updateShift, deleteShift, getShiftStats };
