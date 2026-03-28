const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');
const Shift = require('./models/Shift');
const Leave = require('./models/Leave');

const path = require('path');
dotenv.config({ path: path.resolve(__dirname, '../.env'), override: true });

const seedData = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connected for seeding...');

    // Clear existing data
    await User.deleteMany({});
    await Shift.deleteMany({});
    await Leave.deleteMany({});
    console.log('Cleared existing data.');

    // ── Create Admin ────────────────────────────────────────────────────────
    const admin = await User.create({
      name: 'Sarah Johnson',
      email: 'admin@careshift.co.uk',
      password: 'Admin@123',
      role: 'admin',
      hourlyRate: 25.0,
      department: 'Management',
      phone: '07700000001',
    });
    console.log(`Created admin: ${admin.email}`);

    // ── Create 10 Staff Members ─────────────────────────────────────────────
    const staffData = [
      { name: 'James Carter', email: 'staff@careshift.co.uk', hourlyRate: 12.50, department: 'Care', phone: '07700000002' },
      { name: 'Aisha Patel', email: 'aisha@careshift.co.uk', hourlyRate: 13.50, department: 'Care', phone: '07700000003' },
      { name: 'Michael Brown', email: 'michael@careshift.co.uk', hourlyRate: 11.50, department: 'Care', phone: '07700000004' },
      { name: 'Tom Williams', email: 'tom@careshift.co.uk', hourlyRate: 11.44, department: 'Office', phone: '07700000005' },
      { name: 'Lucy Barnes', email: 'lucy@careshift.co.uk', hourlyRate: 12.80, department: 'Residential', phone: '07700000006' },
      { name: 'Priya Singh', email: 'priya@careshift.co.uk', hourlyRate: 15.00, department: 'Care', phone: '07700000007' },
      { name: 'David Chen', email: 'david@careshift.co.uk', hourlyRate: 11.44, department: 'Care', phone: '07700000008' },
      { name: 'Emma Thompson', email: 'emma@careshift.co.uk', hourlyRate: 14.00, department: 'Residential', phone: '07700000009' },
      { name: 'Hassan Ali', email: 'hassan@careshift.co.uk', hourlyRate: 12.00, department: 'Care', phone: '07700000010' },
      { name: 'Sophie Williams', email: 'sophie@careshift.co.uk', hourlyRate: 13.00, department: 'Office', phone: '07700000011' },
    ];

    const staffMembers = [];
    for (const s of staffData) {
      const user = await User.create({
        ...s,
        password: 'Staff@123',
        role: 'staff',
        annualLeaveBalance: 224, // 40h × 5.6 weeks (UK statutory)
        weeklyHours: 40,
      });
      staffMembers.push(user);
    }
    console.log(`Created ${staffMembers.length} staff users.`);

    // ── Generate 100+ Shifts ────────────────────────────────────────────────
    const today = new Date();
    const thisMonday = new Date(today);
    thisMonday.setDate(today.getDate() - today.getDay() + 1);
    thisMonday.setHours(0, 0, 0, 0);

    const locations = [
      'Client A \u2013 Domiciliary',
      'Client B \u2013 Domiciliary',
      'Client C \u2013 Domiciliary',
      'Client D \u2013 Domiciliary',
      'Head Office',
      'Residential Unit 1',
      'Residential Unit 2',
      'Night Cover \u2013 Site A',
    ];

    const shiftPatterns = [
      { start: '06:00', end: '14:00' },
      { start: '07:00', end: '15:00' },
      { start: '07:30', end: '15:30' },
      { start: '08:00', end: '16:00' },
      { start: '09:00', end: '17:00' },
      { start: '10:00', end: '18:00' },
      { start: '14:00', end: '22:00' },
      { start: '20:00', end: '08:00' },
    ];

    const noteOptions = [
      '',
      'Client review scheduled',
      'Medication round at 10:00',
      'New client introduction',
      'Team briefing at start',
      'Cover for absent colleague',
      'Training session included',
      'Handover notes required',
      'Key handover at end of shift',
      'Supervisor check-in at 14:00',
    ];

    const shifts = [];

    const getDate = (weekOffset, dayOffset) => {
      const d = new Date(thisMonday);
      d.setDate(thisMonday.getDate() + (weekOffset * 7) + dayOffset);
      return d;
    };

    const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

    // ── PAST WEEK 2 (2 weeks ago) — 25 shifts ────────────────────────────
    for (let day = 0; day < 5; day++) {
      const date = getDate(-2, day);
      for (let s = 0; s < 5; s++) {
        const staff = staffMembers[s];
        const pattern = shiftPatterns[s % 5];
        shifts.push({
          staffId: staff._id,
          date,
          startTime: pattern.start,
          endTime: pattern.end,
          location: locations[s % locations.length],
          notes: Math.random() > 0.7 ? pick(noteOptions) : '',
          status: Math.random() > 0.1 ? 'completed' : 'cancelled',
          createdBy: admin._id,
        });
      }
    }

    // ── PAST WEEK 1 (last week) — ~46 shifts ────────────────────────────
    for (let day = 0; day < 7; day++) {
      const date = getDate(-1, day);
      const isWeekend = day >= 5;
      const staffCount = isWeekend ? 3 : 8;
      for (let s = 0; s < staffCount; s++) {
        const staff = staffMembers[s];
        const pattern = shiftPatterns[(s + day) % shiftPatterns.length];
        const loc = locations[(s + day) % locations.length];
        shifts.push({
          staffId: staff._id,
          date,
          startTime: pattern.start,
          endTime: pattern.end,
          location: loc,
          notes: Math.random() > 0.6 ? pick(noteOptions) : '',
          status: Math.random() > 0.05 ? 'completed' : 'cancelled',
          createdBy: admin._id,
        });
      }
    }

    // ── CURRENT WEEK — ~58 shifts ───────────────────────────────────────
    for (let day = 0; day < 7; day++) {
      const date = getDate(0, day);
      const isWeekend = day >= 5;
      const dayDiff = Math.floor((date - new Date(today.getFullYear(), today.getMonth(), today.getDate())) / 86400000);
      const isPast = dayDiff < 0;

      const staffCount = isWeekend ? 4 : 10;
      for (let s = 0; s < staffCount; s++) {
        const staff = staffMembers[s % staffMembers.length];
        const pattern = shiftPatterns[(s + day) % shiftPatterns.length];
        const loc = locations[(s + day) % locations.length];

        let status = 'scheduled';
        if (isPast) status = Math.random() > 0.05 ? 'completed' : 'cancelled';

        shifts.push({
          staffId: staff._id,
          date,
          startTime: pattern.start,
          endTime: pattern.end,
          location: loc,
          notes: Math.random() > 0.5 ? pick(noteOptions) : '',
          status,
          createdBy: admin._id,
        });
      }
    }

    // ── NEXT WEEK — ~46 shifts ──────────────────────────────────────────
    for (let day = 0; day < 7; day++) {
      const date = getDate(1, day);
      const isWeekend = day >= 5;
      const staffCount = isWeekend ? 3 : 8;
      for (let s = 0; s < staffCount; s++) {
        const staff = staffMembers[s % staffMembers.length];
        const pattern = shiftPatterns[(s + day + 2) % shiftPatterns.length];
        const loc = locations[(s + day + 1) % locations.length];
        shifts.push({
          staffId: staff._id,
          date,
          startTime: pattern.start,
          endTime: pattern.end,
          location: loc,
          notes: Math.random() > 0.7 ? pick(noteOptions) : '',
          status: 'scheduled',
          createdBy: admin._id,
        });
      }
    }

    // ── WEEK AFTER NEXT — 30 shifts ─────────────────────────────────────
    for (let day = 0; day < 5; day++) {
      const date = getDate(2, day);
      for (let s = 0; s < 6; s++) {
        const staff = staffMembers[s % staffMembers.length];
        const pattern = shiftPatterns[(s + day + 3) % shiftPatterns.length];
        const loc = locations[(s + day + 2) % locations.length];
        shifts.push({
          staffId: staff._id,
          date,
          startTime: pattern.start,
          endTime: pattern.end,
          location: loc,
          notes: Math.random() > 0.8 ? pick(noteOptions) : '',
          status: 'scheduled',
          createdBy: admin._id,
        });
      }
    }

    await Shift.insertMany(shifts);
    console.log(`Created ${shifts.length} shifts across 5 weeks.`);

    // ── Create Sample Leave Requests ──────────────────────────────────────────
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);
    nextMonth.setDate(1);

    const leaveRequests = [
      // Pending annual leave — James Carter
      {
        staffId: staffMembers[0]._id,
        leaveType: 'annual',
        startDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 10),
        endDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 14),
        totalHours: 40,
        reason: 'Family holiday',
        status: 'pending',
      },
      // Pending sick leave — Aisha Patel
      {
        staffId: staffMembers[1]._id,
        leaveType: 'sick',
        startDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 5),
        endDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 6),
        totalHours: 16,
        reason: 'Doctor appointment and recovery',
        status: 'pending',
      },
      // Approved compassionate — Michael Brown
      {
        staffId: staffMembers[2]._id,
        leaveType: 'compassionate',
        startDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 2),
        endDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 4),
        totalHours: 24,
        reason: 'Family bereavement',
        status: 'approved',
        approvedBy: admin._id,
      },
      // Rejected annual — Tom Williams
      {
        staffId: staffMembers[3]._id,
        leaveType: 'annual',
        startDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 15),
        endDate: new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 26),
        totalHours: 80,
        reason: 'Extended holiday abroad',
        status: 'rejected',
        rejectedReason: 'Insufficient cover for this period',
      },
    ];

    await Leave.insertMany(leaveRequests);
    console.log(`Created ${leaveRequests.length} sample leave requests.`);

    console.log('\n========================================');
    console.log('  SEED COMPLETE');
    console.log('========================================');
    console.log(`  Users:  1 admin + ${staffMembers.length} staff = ${staffMembers.length + 1} total`);
    console.log(`  Shifts: ${shifts.length} total`);
    console.log(`  Leave:  ${leaveRequests.length} requests`);
    console.log('');
    console.log('  Demo Logins:');
    console.log('    Admin:  admin@careshift.co.uk / Admin@123');
    console.log('    Staff:  staff@careshift.co.uk / Staff@123');
    console.log('    Staff:  aisha@careshift.co.uk / Staff@123');
    console.log('    Staff:  michael@careshift.co.uk / Staff@123');
    console.log('    Staff:  tom@careshift.co.uk / Staff@123');
    console.log('    Staff:  lucy@careshift.co.uk / Staff@123');
    console.log('    Staff:  priya@careshift.co.uk / Staff@123');
    console.log('    Staff:  david@careshift.co.uk / Staff@123');
    console.log('    Staff:  emma@careshift.co.uk / Staff@123');
    console.log('    Staff:  hassan@careshift.co.uk / Staff@123');
    console.log('    Staff:  sophie@careshift.co.uk / Staff@123');
    console.log('    (All staff passwords: Staff@123)');
    console.log('========================================\n');

    process.exit(0);
  } catch (error) {
    console.error('Seed error:', error.message);
    process.exit(1);
  }
};

seedData();
