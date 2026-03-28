class PayrollAdjustment {
  final String description;
  final double amount;
  final String? addedBy;
  final DateTime? addedAt;

  const PayrollAdjustment({
    required this.description,
    required this.amount,
    this.addedBy,
    this.addedAt,
  });

  factory PayrollAdjustment.fromJson(Map<String, dynamic> json) {
    return PayrollAdjustment(
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      addedBy: json['addedBy']?.toString(),
      addedAt: json['addedAt'] != null ? DateTime.tryParse(json['addedAt']) : null,
    );
  }
}

class PayrollRecord {
  final String id;
  final String staffId;
  final String? staffName;
  final String? staffEmail;
  final String? staffDepartment;
  final String month;
  final double totalHoursWorked;
  final double overtimeHours;
  final double hourlyRate;
  final double grossPay;
  final List<PayrollAdjustment> adjustments;
  final double finalPay;
  final String status; // draft | finalized
  final String? generatedByName;

  const PayrollRecord({
    required this.id,
    required this.staffId,
    this.staffName,
    this.staffEmail,
    this.staffDepartment,
    required this.month,
    required this.totalHoursWorked,
    required this.overtimeHours,
    required this.hourlyRate,
    required this.grossPay,
    required this.adjustments,
    required this.finalPay,
    required this.status,
    this.generatedByName,
  });

  double get adjustmentTotal => adjustments.fold(0.0, (s, a) => s + a.amount);

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    // staffId can be a populated object or a string
    String sid;
    String? sName, sEmail, sDept;
    if (json['staffId'] is Map) {
      final staff = json['staffId'] as Map<String, dynamic>;
      sid = staff['_id'] ?? staff['id'] ?? '';
      sName = staff['name'];
      sEmail = staff['email'];
      sDept = staff['department'];
    } else {
      sid = json['staffId']?.toString() ?? '';
    }

    String? genName;
    if (json['generatedBy'] is Map) {
      genName = (json['generatedBy'] as Map<String, dynamic>)['name'];
    }

    return PayrollRecord(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: sid,
      staffName: sName,
      staffEmail: sEmail,
      staffDepartment: sDept,
      month: json['month'] ?? '',
      totalHoursWorked: (json['totalHoursWorked'] ?? 0).toDouble(),
      overtimeHours: (json['overtimeHours'] ?? 0).toDouble(),
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      grossPay: (json['grossPay'] ?? 0).toDouble(),
      adjustments: (json['adjustments'] as List? ?? [])
          .map((a) => PayrollAdjustment.fromJson(a))
          .toList(),
      finalPay: (json['finalPay'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      generatedByName: genName,
    );
  }
}
