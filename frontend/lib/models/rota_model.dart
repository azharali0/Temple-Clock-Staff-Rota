// lib/models/rota_model.dart

class ShiftVisit {
  final String clientId;
  final String clientName;
  final String clientAddress;
  final DateTime expectedStartTime;
  final DateTime expectedEndTime;

  ShiftVisit({
    required this.clientId,
    required this.clientName,
    required this.clientAddress,
    required this.expectedStartTime,
    required this.expectedEndTime,
  });
}

class RotaShift {
  final String id;
  final String staffId;
  final String staffName;
  final String role;
  final String? departmentName;
  final double scheduledHours;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<ShiftVisit>? visits;

  const RotaShift({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.role,
    this.departmentName,
    required this.scheduledHours,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.visits,
  });

  double get durationHours => endTime.difference(startTime).inMinutes / 60.0;
}
