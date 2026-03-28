enum LeaveStatus { pending, approved, rejected, cancelled }

class LeaveRequest {
  final String id;
  final String staffId;
  final String staffName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalHours;
  final String reason;
  final LeaveStatus status;
  final String rejectedReason;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalHours,
    required this.reason,
    required this.status,
    required this.rejectedReason,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final staff = json['staffId'];
    final staffId = staff is Map<String, dynamic>
        ? (staff['_id'] ?? '').toString()
        : (staff ?? '').toString();
    final staffName = staff is Map<String, dynamic>
        ? (staff['name'] ?? '').toString()
        : '';

    return LeaveRequest(
      id: (json['_id'] ?? '').toString(),
      staffId: staffId,
      staffName: staffName,
      leaveType: (json['leaveType'] ?? '').toString(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalHours: (json['totalHours'] ?? 0).toDouble(),
      reason: (json['reason'] ?? '').toString(),
      status: _mapStatus(json['status']?.toString()),
      rejectedReason: (json['rejectedReason'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static LeaveStatus _mapStatus(String? status) {
    switch (status) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
        return LeaveStatus.cancelled;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }
}
