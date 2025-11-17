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

  // ---- NASA APOD ----

  /// Format a DateTime as YYYY-MM-DD to match how APOD dates are stored
  String _formatApodDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Fetch APOD info for a given date from the backend.
  /// Backend route: POST /api/viewAPOD
  ///
  /// Returns a map like:
  /// {
  ///   success: true/false,
  ///   title: ...,
  ///   hdurl: ...,
  ///   explanation: ...,
  ///   thumbnailUrl: ...,
  ///   copyright: ...,
  ///   error: '',
  ///   accessToken: '...'
  /// }
  Future<Map<String, dynamic>> viewApod({
    required DateTime date,
  }) async {
    // Read the JWT we stored during login/verify
    final accessToken = await _store.read(key: 'accessToken');
    if (accessToken == null) {
      throw Exception('No access token found. User may not be logged in.');
    }

    final dateStr = _formatApodDate(date);

    try {
      final response = await _dio.post(
        '/api/viewAPOD',
        data: {
          'accessToken': accessToken,
          'date': dateStr,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with an error status
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        // Network / timeout
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ---- NASA APOD: Recent photos ----

  /// Fetch the most recent APOD entries from the backend.
  ///
  /// Backend route: POST /api/recentAPODs
  /// Body: { accessToken, limit }
  ///
  /// Expected response:
  /// {
  ///   success: true,
  ///   photos: [
  ///     {
  ///       "date": "2025-11-16",
  ///       "title": "...",
  ///       "thumbnailUrl": "...",
  ///       "hdurl": "...",
  ///       "explanation": "...",
  ///       "copyright": "..."
  ///     },
  ///     ...
  ///   ],
  ///   error: "",
  ///   accessToken: "..."
  /// }
  Future<List<Map<String, dynamic>>> fetchRecentApods({
    int limit = 6,
  }) async {
    final accessToken = await _store.read(key: 'accessToken');
    if (accessToken == null) {
      throw Exception('No access token found. User may not be logged in.');
    }

    try {
      final response = await _dio.post(
        '/api/recentAPODs',
        data: {
          'accessToken': accessToken,
          'limit': limit,
        },
      );

      final map = Map<String, dynamic>.from(response.data);

      if (map['success'] != true) {
        final err = map['error'] ?? 'Failed to fetch recent APODs.';
        throw Exception(err.toString());
      }

      final photosRaw = map['photos'] ?? [];
      final photos = List<Map<String, dynamic>>.from(
        (photosRaw as List).map(
          (p) => Map<String, dynamic>.from(p as Map),
        ),
      );

      return photos;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}