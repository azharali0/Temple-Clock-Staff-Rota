class AlertModel {
  final String id;
  final String? staffId;
  final String? staffName;
  final String? staffEmail;
  final String? targetStaffId;
  final String? targetStaffName;
  final String? shiftId;
  final String alertType; // running_late | emergency | general | admin_notice
  final String message;
  final int estimatedDelay;
  final bool readByAdmin;
  final bool readByStaff;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    this.staffId,
    this.staffName,
    this.staffEmail,
    this.targetStaffId,
    this.targetStaffName,
    this.shiftId,
    required this.alertType,
    required this.message,
    this.estimatedDelay = 0,
    this.readByAdmin = false,
    this.readByStaff = false,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String? sid, sName, sEmail;
    if (json['staffId'] is Map) {
      final staff = json['staffId'] as Map<String, dynamic>;
      sid = staff['_id'] ?? staff['id'];
      sName = staff['name'];
      sEmail = staff['email'];
    } else {
      sid = json['staffId']?.toString();
    }

    String? tid, tName;
    if (json['targetStaffId'] is Map) {
      final target = json['targetStaffId'] as Map<String, dynamic>;
      tid = target['_id'] ?? target['id'];
      tName = target['name'];
    } else {
      tid = json['targetStaffId']?.toString();
    }

    String? shiftId;
    if (json['shiftId'] is Map) {
      shiftId = (json['shiftId'] as Map<String, dynamic>)['_id']?.toString();
    } else {
      shiftId = json['shiftId']?.toString();
    }

    return AlertModel(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: sid,
      staffName: sName,
      staffEmail: sEmail,
      targetStaffId: tid,
      targetStaffName: tName,
      shiftId: shiftId,
      alertType: json['alertType'] ?? 'general',
      message: json['message'] ?? '',
      estimatedDelay: json['estimatedDelay'] ?? 0,
      readByAdmin: json['readByAdmin'] ?? false,
      readByStaff: json['readByStaff'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
