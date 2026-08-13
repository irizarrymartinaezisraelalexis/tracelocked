import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static Map<String, String> get headers {
    final token = AuthService.accessToken;

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Dashboard request failed');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load profiles');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid profiles response');
    }

    return decoded.map<Map<String, dynamic>>(
      (item) {
        final profile = Map<String, dynamic>.from(
          item as Map,
        );

        if (profile['id'] == null &&
            profile['profile_id'] != null) {
          profile['id'] = profile['profile_id'];
        }

        return profile;
      },
    ).toList();
  }

  static Future<void> createProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String street,
    required String city,
    required String state,
    required String postalCode,
    required String dateOfBirth,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/'),
      headers: headers,
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email_addresses': [email],
        'phone_numbers': [phone],
        'current_address': {
          'street': street,
          'city': city,
          'state': state,
          'postal_code': postalCode,
        },
        'previous_addresses': [],
        'date_of_birth': dateOfBirth.isEmpty ? null : dateOfBirth,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }

  static Future<void> updateProfile({
    required String profileId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String street,
    required String city,
    required String state,
    required String postalCode,
    required String dateOfBirth,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/$profileId'),
      headers: headers,
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email_addresses': [email],
        'phone_numbers': [phone],
        'current_address': {
          'street': street,
          'city': city,
          'state': state,
          'postal_code': postalCode,
        },
        'previous_addresses': [],
        'date_of_birth': dateOfBirth.isEmpty ? null : dateOfBirth,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  static Future<void> deleteProfile(
    String profileId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profiles/$profileId'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  static Future<Map<String, dynamic>> startScan(
    String profileId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan/start/$profileId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getScanResults(
    String profileId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scan/results/$profileId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateScanStatus({
    required String resultId,
    required String newStatus,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/scan/results/$resultId/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> initializeScanQueue(
    String profileId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/scan/queue/$profileId/initialize',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetScanQueue(
    String profileId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/scan/queue/$profileId/reset',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSavedScanQueue(
    String profileId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/scan/queue/$profileId/saved',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateScanTask({
    required String taskId,
    required String status,
    String? resultUrl,
    double? confidenceScore,
  }) async {
    final body = <String, dynamic>{
      'status': status,
    };

    if (resultUrl != null) {
      body['result_url'] = resultUrl;
    }

    if (confidenceScore != null) {
      body['confidence_score'] = confidenceScore;
    }

    final response = await http.patch(
      Uri.parse(
        '$baseUrl/scan/queue/task/$taskId',
      ),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getScanSources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/scan/sources'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getScanPlan(
    String profileId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/scan/plan/$profileId',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRemovalAction(
    String resultId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/scan/results/$resultId/removal-action',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRecheckAction(
    String resultId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/scan/results/$resultId/recheck',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static String _extractError(
    http.Response response,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail is String) {
          return detail;
        }

        if (detail is List) {
          return detail
              .map(
                (item) {
                  if (item is Map<String, dynamic>) {
                    return item['msg']?.toString() ??
                        item.toString();
                  }

                  return item.toString();
                },
              )
              .join('\n');
        }
      }
    } catch (_) {}

    return 'Request failed with status ${response.statusCode}.';
  }
}