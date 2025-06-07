import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String apiVersion = 'v1';

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      throw ApiException('Failed to get token: $e');
    }
  }

  static Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      throw ApiException('Failed to save token: $e');
    }
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      throw ApiException('Failed to clear token: $e');
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await getToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };
    } catch (e) {
      throw ApiException('Failed to get headers: $e');
    }
  }

  static Future<ApiResponse> _handleResponse(http.Response response) async {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.fromJson(data);
      } else {
        throw ApiException(
          data['message'] ?? 'Unknown error occurred',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  // Auth
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$apiVersion/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final apiResponse = await _handleResponse(response);
      if (apiResponse.data != null && apiResponse.data['token'] != null) {
        await setToken(apiResponse.data['token']);
      }
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$apiVersion/user/profile'),
        headers: await _getHeaders(),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$apiVersion/dashboard'),
        headers: await _getHeaders(),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  // Orders
  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (sortBy != null) 'sortBy': sortBy,
        if (status != null) 'status': status,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/$apiVersion/orders')
            .replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$apiVersion/orders'),
        headers: await _getHeaders(),
        body: jsonEncode(orderData),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  // Inventory
  static Future<Map<String, dynamic>> getInventory({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null) 'search': search,
        if (category != null) 'category': category,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/$apiVersion/inventory')
            .replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  // Employees
  static Future<Map<String, dynamic>> getEmployees({
    int page = 1,
    int limit = 10,
    String? department,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (department != null) 'department': department,
        if (search != null) 'search': search,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/$apiVersion/employees')
            .replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }

  // Finance
  static Future<Map<String, dynamic>> getFinancialSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/$apiVersion/finance/summary')
            .replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      );
      final apiResponse = await _handleResponse(response);
      return apiResponse.data;
    } on http.ClientException {
      throw ApiException('Network error - Please check your connection');
    }
  }
}
