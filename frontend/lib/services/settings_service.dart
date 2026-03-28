import 'dart:convert';
import 'api_service.dart';

class SettingsService {
  final ApiService _apiService;

  SettingsService(this._apiService);

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiService.get('/settings');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch settings');
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> fields) async {
    final response = await _apiService.put('/settings', fields);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to update settings');
  }
}
