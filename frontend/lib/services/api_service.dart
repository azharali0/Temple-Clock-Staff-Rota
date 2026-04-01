import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Exception thrown when the API server is unreachable.
class ApiConnectionException implements Exception {
  final String message;
  const ApiConnectionException(
      [this.message = 'Cannot connect to server. Please check your connection.']);
  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Wraps every HTTP call so network-level failures surface as a clear
  /// [ApiConnectionException] instead of raw platform exceptions.
  Future<http.Response> _safe(Future<http.Response> Function() fn) async {
    try {
      return await fn();
    } on http.ClientException {
      throw const ApiConnectionException();
    } catch (e) {
      // On web, network errors may surface as generic exceptions
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('NetworkError') ||
          e.toString().contains('Failed to fetch') ||
          e.toString().contains('SocketException')) {
        throw const ApiConnectionException();
      }
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    return _safe(() => _client.get(url, headers: headers));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    return _safe(() => _client.post(url, headers: headers, body: jsonEncode(body)));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    return _safe(() => _client.put(url, headers: headers, body: jsonEncode(body)));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    return _safe(() => _client.delete(url, headers: headers));
  }

  void dispose() {
    _client.close();
  }
}
