// lib/models/attendance_model.dart

enum AttendanceStatus {
  onTime,
  late,
  earlyDeparture,
  overtime,
  absent,
}

class AttendanceRecord {
  final String id;
  final String staffId;
  final String staffName;
  final String shiftId;
  final String? clientId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final int lateMinutes;
  final double extraHours;
  final String? photoInPath;
  final String? photoOutPath;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.shiftId,
    this.clientId,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.clockInTime,
    this.clockOutTime,
    this.lateMinutes = 0,
    this.extraHours = 0.0,
    this.photoInPath,
    this.photoOutPath,
    required this.status,
    this.notes,
  });

  bool get isClockedIn => clockInTime != null && clockOutTime == null;
  bool get isClockedOut => clockInTime != null && clockOutTime != null;

  double get totalHoursWorked {
    if (clockInTime == null) return 0;
    final endTime = clockOutTime ?? DateTime.now();
    return endTime.difference(clockInTime!).inMinutes / 60.0;
  }

  AttendanceRecord copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? shiftId,
    String? clientId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    int? lateMinutes,
    double? extraHours,
    String? photoInPath,
    String? photoOutPath,
    AttendanceStatus? status,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      shiftId: shiftId ?? this.shiftId,
      clientId: clientId ?? this.clientId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      extraHours: extraHours ?? this.extraHours,
      photoInPath: photoInPath ?? this.photoInPath,
      photoOutPath: photoOutPath ?? this.photoOutPath,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
