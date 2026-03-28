// lib/models/rota_model.dart

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
  });

  factory RotaShift.fromJson(Map<String, dynamic> json) {
    return RotaShift(
      id: json['_id'] ?? json['id'],
      staffId: json['staff']['_id'],
      staffName: json['staff']['name'],
      role: json['role'] ?? 'Staff',
      departmentName: json['department']?['name']?.toString(),
      scheduledHours: ((json['scheduledHours'] ?? 0) as num).toDouble(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? 'scheduled',
    );
  }

  double get durationHours => endTime.difference(startTime).inMinutes / 60.0;
}
