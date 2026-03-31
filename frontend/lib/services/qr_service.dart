import 'dart:convert';
import 'api_service.dart';

class DailyQR {
  final String id;
  final String token;
  final String label;
  final bool isActive;
  final String generatedByName;
  final DateTime createdAt;

  DailyQR({
    required this.id,
    required this.token,
    required this.label,
    required this.isActive,
    required this.generatedByName,
    required this.createdAt,
  });

  factory DailyQR.fromJson(Map<String, dynamic> json) {
    String byName = '';
    if (json['generatedBy'] is Map) {
      byName = json['generatedBy']['name'] ?? '';
    }
    return DailyQR(
      id: json['_id'] ?? '',
      token: json['token'] ?? '',
      label: json['label'] ?? '',
      isActive: json['isActive'] ?? false,
      generatedByName: byName,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class QrService {
  final ApiService _apiService;
  QrService(this._apiService);

  /// Admin: Generate a new daily QR code (expires all previous).
  Future<DailyQR> generateDailyQR({String? label}) async {
    final response = await _apiService.post(
      '/qr/generate',
      label != null ? {'label': label} : {},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return DailyQR.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to generate QR');
  }

  /// Get the current active QR code.
  Future<DailyQR> getActiveQR() async {
    final response = await _apiService.get('/qr/active');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return DailyQR.fromJson(data);
    }
    throw Exception(data['message'] ?? 'No active QR');
  }

  /// Staff: Verify a scanned QR token.
  Future<bool> verifyQR(String token) async {
    final response = await _apiService.post('/qr/verify', {'token': token});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['valid'] == true) {
      return true;
    }
    throw Exception(data['message'] ?? 'Invalid QR code');
  }

  /// Admin: Get QR history.
  Future<List<DailyQR>> getQRHistory() async {
    final response = await _apiService.get('/qr/history');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => DailyQR.fromJson(e)).toList();
    }
    throw Exception('Failed to load QR history');
  }

  /// Admin: Expire a specific QR code.
  Future<void> expireQR(String qrId) async {
    final response = await _apiService.put('/qr/$qrId/expire', {});
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to expire QR');
    }
  }
}
