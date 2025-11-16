import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  final Dio _dio;
  final FlutterSecureStorage _store = const FlutterSecureStorage();

  Api(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )) {
    // Attach access token automatically if present
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _store.read(key: 'accessToken');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ---- Auth & User ----

  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/api/addUser', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
    final map = Map<String, dynamic>.from(res.data);
    // server returns id, firstName, lastName, accessToken, error
    if (map['accessToken'] != null) {
      await _store.write(key: 'accessToken', value: map['accessToken']);
      await _store.write(key: 'userId', value: map['id'].toString());
    }
    return map;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/api/loginUser', data: {
      'email': email,
      'password': password,
    });
    final map = Map<String, dynamic>.from(res.data);
    // returns id, firstName, lastName, accessToken, verificationToken, error
    if (map['accessToken'] != null) {
      await _store.write(key: 'accessToken', value: map['accessToken']);
      await _store.write(key: 'userId', value: map['id'].toString());
      if (map['verificationToken'] != null) {
        await _store.write(key: 'verificationToken', value: map['verificationToken'].toString());
      }
    }
    return map;
  }

  /// Verify a user's email using the provided verification token.
  ///
  /// Note: verificationToken is sent as a String to preserve leading zeros. Passing an int
  /// would drop leading zeros and cause valid codes like "012345" to fail.
  Future<Map<String, dynamic>> verifyUser({
    required String email,
    required String verificationToken,
  }) async {
    final accessToken = await _store.read(key: 'accessToken');
    final res = await _dio.post('/api/verifyUser', data: {
      'email': email,
      'verificationToken': int.parse(verificationToken),
      'accessToken': accessToken,
    });
    final map = Map<String, dynamic>.from(res.data);
    return map; // { id, accessToken, error: 'success, send to Dashboard page' } on success
  }

/*
  Future<Map<String, dynamic>> sendVerEmail({
    required String email,
    required int verificationToken,
  }) async {
    
  }

*/

  Future<Map<String, dynamic>> createReminder({
    required String userId,
    required String accessToken,
    required String title,
    required String desc,
    required String status,
    required String priority,
    required DateTime dueDate
  }) async {
    try {
      // Backend expects year, month, day in the body
      final body = {
        'userId': userId,
        'accessToken': accessToken,
        'title': title,
        'desc': desc,
        'status': status,
        'priority': priority,
        'year': dueDate.year,
        'month': dueDate.month,
        'day': dueDate.day,
      };

      final response = await _dio.post(
        '/api/createReminder',
        data: body,
      );

      return Map<String, dynamic>.from(response.data);

    } on DioException catch (e) {
      // Handle HTTP or network errors
      if (e.response != null) {
        // Server responded with error status
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        // No response (timeout, no internet, etc.)
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}