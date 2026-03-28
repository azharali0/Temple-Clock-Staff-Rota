// lib/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final double? hourlyRate;
  final String? phone;
  final String? department;
  final bool isActive;
  final double? annualLeaveBalance;
  final double? weeklyHours;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.hourlyRate,
    this.phone,
    this.department,
    this.isActive = true,
    this.annualLeaveBalance,
    this.weeklyHours,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'staff',
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      phone: json['phone'],
      department: json['department'],
      isActive: json['isActive'] ?? true,
      annualLeaveBalance: json['annualLeaveBalance'] != null
          ? (json['annualLeaveBalance']).toDouble()
          : null,
      weeklyHours: json['weeklyHours'] != null
          ? (json['weeklyHours']).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'hourlyRate': hourlyRate,
      'phone': phone,
      'department': department,
      'isActive': isActive,
      'annualLeaveBalance': annualLeaveBalance,
      'weeklyHours': weeklyHours,
    };
  }
}
