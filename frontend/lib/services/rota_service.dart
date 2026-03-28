import 'dart:convert';
import '../models/rota_model.dart';
import 'api_service.dart';

class RotaService {
  final ApiService _apiService;

  RotaService(this._apiService);

  Future<List<RotaShift>> getMyShifts() async {
    final response = await _apiService.get('/shifts/my-shifts');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> list = data is List ? data : (data['shifts'] ?? []);
      return list.map((item) => _parseShift(item)).toList();
    } else {
      throw Exception('Failed to fetch shifts');
    }
  }

  Future<List<RotaShift>> getAllShifts({String? week, String? date}) async {
    String url = '/shifts';
    final params = <String>[];
    if (week != null) params.add('week=$week');
    if (date != null) params.add('date=$date');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await _apiService.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> list = data is List ? data : (data['shifts'] ?? []);
      return list.map((item) => _parseShift(item)).toList();
    } else {
      throw Exception('Failed to fetch all shifts');
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiService.get('/shifts/stats');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'totalShifts': 0, 'todayShifts': 0, 'upcomingShifts': 0};
  }

  Future<void> createShift({
    required String staffId,
    required String date,
    required String startTime,
    required String endTime,
    String? location,
    String? notes,
  }) async {
    final response = await _apiService.post('/shifts', {
      'staffId': staffId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
    });
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create shift');
    }
  }

  Future<void> updateShift(String id, Map<String, dynamic> fields) async {
    final response = await _apiService.put('/shifts/$id', fields);
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update shift');
    }
  }

  Future<void> deleteShift(String id) async {
    final response = await _apiService.delete('/shifts/$id');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete shift');
    }
  }

  RotaShift _parseShift(Map<String, dynamic> json) {
    // Backend populates staffId as {_id, name, email} object
    final staff = json['staffId'];
    String staffId = '';
    String staffName = 'Unknown';

    if (staff is Map<String, dynamic>) {
      staffId = staff['_id'] ?? '';
      staffName = staff['name'] ?? 'Unknown';
    } else if (staff is String) {
      staffId = staff;
    }

    // Backend uses date + startTime/endTime as separate fields
    final dateStr = json['date'] ?? '';
    final startStr = json['startTime'] ?? '09:00';
    final endStr = json['endTime'] ?? '17:00';

    DateTime shiftDate;
    try {
      shiftDate = DateTime.parse(dateStr);
    } catch (_) {
      shiftDate = DateTime.now();
    }

    final startParts = startStr.split(':');
    final endParts = endStr.split(':');

    final start = DateTime(
      shiftDate.year, shiftDate.month, shiftDate.day,
      int.tryParse(startParts[0]) ?? 9,
      startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0,
    );
    final end = DateTime(
      shiftDate.year, shiftDate.month, shiftDate.day,
      int.tryParse(endParts[0]) ?? 17,
      endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0,
    );

    return RotaShift(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: staffId,
      staffName: staffName,
      role: json['role'] ?? 'Staff',
      departmentName: json['location'],
      scheduledHours: end.difference(start).inMinutes / 60.0,
      startTime: start,
      endTime: end,
      status: json['status'] ?? 'scheduled',
    );
  }
}
