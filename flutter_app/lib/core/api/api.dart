import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  final Dio _dio;
  final FlutterSecureStorage _store;

  // -----------------------------
  // NORMAL CONSTRUCTOR (production)
  // -----------------------------
  Api(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )),
        _store = const FlutterSecureStorage() {

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

  // -----------------------------
  // TEST-ONLY CONSTRUCTOR (mockable)
  // -----------------------------
  Api.forTesting({
    required Dio dio,
    required FlutterSecureStorage store,
  })  : _dio = dio,
        _store = store;
  

  // ===== Helpers for auth body  =========================================

  Future<Map<String, dynamic>> _buildAuthBody(
      [Map<String, dynamic>? extra]) async {
    final accessToken = await _store.read(key: 'accessToken');
    final userId = await _store.read(key: 'userId');

    if (accessToken == null || userId == null) {
      throw Exception('Not logged in (missing userId or accessToken).');
    }

    return {
      'userId': userId,
      'accessToken': accessToken,
      if (extra != null) ...extra,
    };
  }

  // ===== Reminders =======================================================

  /// Create a reminder (backend: POST /api/createReminder)
  Future<Map<String, dynamic>> createReminder({
    required String title,
    required String desc,
    required String status,
    required String priority,
    required DateTime dueDate,
  }) async {
    final body = await _buildAuthBody({
      'title': title,
      'desc': desc,
      'status': status,
      'priority': priority,
      'year': dueDate.year,
      'month': dueDate.month,
      'day': dueDate.day,
    });

    try {
      final res = await _dio.post('/api/createReminder', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// View all reminders (backend: POST /api/viewReminder)
  Future<Map<String, dynamic>> viewReminders({String? reminderId}) async {
    final body = await _buildAuthBody(
      reminderId != null ? {'reminderId': reminderId} : null,
    );

    try {
      final res = await _dio.post('/api/viewReminder', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Mark a reminder as completed (backend: POST /api/completeReminder)
  Future<Map<String, dynamic>> completeReminder({
    required String title,
  }) async {
    final body = await _buildAuthBody({
      'title': title,
    });

    try {
      final res = await _dio.post('/api/completeReminder', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Delete a reminder (backend: POST /api/deleteReminder)
  Future<Map<String, dynamic>> deleteReminder({
    required String title,
  }) async {
    final body = await _buildAuthBody({
      'title': title,
    });

    try {
      final res = await _dio.post('/api/deleteReminder', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Edit a reminder (backend: POST /api/editReminder)
  Future<Map<String, dynamic>> editReminder({
    required String title,
    required String desc,
    required String status,
    required String priority,
    required DateTime dueDate,
  }) async {
    final body = await _buildAuthBody({
      'title': title,
      'desc': desc,
      'status': status,
      'priority': priority,
      'year': dueDate.year,
      'month': dueDate.month,
      'day': dueDate.day,
    });

    try {
      final res = await _dio.post('/api/editReminder', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
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

  // ===== Tasks ==========================================================

  /// Create a task (backend: POST /api/createTask)
  ///
  /// Server defaults:
  /// - description -> '' if omitted
  /// - status -> 'not started' if omitted
  /// - priority -> 'medium' if omitted
  /// - dueDate -> null if omitted
  /// - completed -> {isCompleted:false, completedAt:null} if omitted
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) async {
    final extra = <String, dynamic>{
      'title': title,
    };

    if (description != null) extra['description'] = description;
    if (status != null) extra['status'] = status;
    if (priority != null) extra['priority'] = priority;
    if (dueDate != null) extra['dueDate'] = dueDate.toIso8601String();

    // Only send "completed" if caller provides something
    if (isCompleted != null || completedAt != null) {
      extra['completed'] = {
        'isCompleted': isCompleted ?? false,
        'completedAt': completedAt?.toIso8601String(),
      };
    }

    final body = await _buildAuthBody(extra);

    try {
      final res = await _dio.post('/api/createTask', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// View tasks (backend: POST /api/viewTask)
  ///
  /// - If [taskId] is provided: returns a single task.
  /// - If [taskId] is null: returns all tasks for the user.
  Future<Map<String, dynamic>> viewTasks({String? taskId}) async {
    final body = await _buildAuthBody(
      taskId != null ? {'taskId': taskId} : null,
    );

    try {
      final res = await _dio.post('/api/viewTask', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Edit a task (backend: POST /api/editTask)
  ///
  /// All fields except [taskId] are optional; only non-null fields are sent
  /// and will be updated on the server.
  Future<Map<String, dynamic>> editTask({
    required String taskId,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) async {
    final extra = <String, dynamic>{
      'taskId': taskId,
    };

    if (title != null) extra['title'] = title;
    if (description != null) extra['description'] = description;
    if (status != null) extra['status'] = status;
    if (priority != null) extra['priority'] = priority;
    if (dueDate != null) extra['dueDate'] = dueDate.toIso8601String();

    if (isCompleted != null || completedAt != null) {
      extra['completed'] = {
        'isCompleted': isCompleted ?? false,
        'completedAt': completedAt?.toIso8601String(),
      };
    }

    final body = await _buildAuthBody(extra);

    try {
      final res = await _dio.post('/api/editTask', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Delete a task (backend: POST /api/deleteTask)
  Future<Map<String, dynamic>> deleteTask({
    required String taskId,
  }) async {
    final body = await _buildAuthBody({
      'taskId': taskId,
    });

    try {
      final res = await _dio.post('/api/deleteTask', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  // ===== Calendar Events ===============================================

  /// Create a calendar event (backend: POST /api/createCalendarEvent)
  ///
  /// Server expects:
  ///   title, description, location, startDate, endDate, color, allDay, reminder
  /// and will default color/allDay/reminder to {} if omitted.
  Future<Map<String, dynamic>> createCalendarEvent({
    required String title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? color,
    Map<String, dynamic>? allDay,
    Map<String, dynamic>? reminder,
  }) async {
    final extra = <String, dynamic>{
      'title': title,
    };

    if (description != null) extra['description'] = description;
    if (location != null) extra['location'] = location;
    if (startDate != null) extra['startDate'] = startDate.toIso8601String();
    if (endDate != null) extra['endDate'] = endDate.toIso8601String();
    if (color != null) extra['color'] = color;
    if (allDay != null) extra['allDay'] = allDay;
    if (reminder != null) extra['reminder'] = reminder;

    final body = await _buildAuthBody(extra);

    try {
      final res = await _dio.post('/api/createCalendarEvent', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// View calendar events (backend: POST /api/viewCalendarEvent)
  ///
  /// - If [eventId] is provided: returns a single event (`event` field).
  /// - If [eventId] is null: returns all events (`events` field).
  Future<Map<String, dynamic>> viewCalendarEvents({String? eventId}) async {
    final body = await _buildAuthBody(
      eventId != null ? {'eventId': eventId} : null,
    );

    try {
      final res = await _dio.post('/api/viewCalendarEvent', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Edit a calendar event (backend: POST /api/editCalendarEvent)
  ///
  /// Only non-null fields are sent and updated server-side.
  Future<Map<String, dynamic>> editCalendarEvent({
    required String eventId,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? color,
    Map<String, dynamic>? allDay,
    Map<String, dynamic>? reminder,
  }) async {
    final extra = <String, dynamic>{
      'eventId': eventId,
    };

    if (title != null) extra['title'] = title;
    if (description != null) extra['description'] = description;
    if (location != null) extra['location'] = location;
    if (startDate != null) extra['startDate'] = startDate.toIso8601String();
    if (endDate != null) extra['endDate'] = endDate.toIso8601String();
    if (color != null) extra['color'] = color;
    if (allDay != null) extra['allDay'] = allDay;
    if (reminder != null) extra['reminder'] = reminder;

    final body = await _buildAuthBody(extra);

    try {
      final res = await _dio.post('/api/editCalendarEvent', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Delete a calendar event (backend: POST /api/deleteCalendarEvent)
  Future<Map<String, dynamic>> deleteCalendarEvent({
    required String eventId,
  }) async {
    final body = await _buildAuthBody({
      'eventId': eventId,
    });

    try {
      final res = await _dio.post('/api/deleteCalendarEvent', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
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

  // ===== Weather =======================================================

  /// Fetch current weather info from the backend.
  ///
  /// Backend route: POST /api/viewWeather
  ///
  /// Expected response:
  /// {
  ///   success: true,
  ///   weather: {
  ///     location: "Orlando, FL",
  ///     high: ...,
  ///     low: ...,
  ///     sunrise: ...,
  ///     sunset: ...,
  ///     forecast: ...,
  ///     humid: ...,
  ///     vis: ...,
  ///     pressure: ...,
  ///     windSpeed: ...,
  ///     lastUpdated: ...
  ///   },
  ///   error: "",
  ///   accessToken: "..."
  /// }
  Future<Map<String, dynamic>> viewWeather() async {
    try {
      // No body needed – authMiddleware uses Authorization header,
      // which your interceptor already sets.
      final response = await _dio.post('/api/viewWeather');

      final map = Map<String, dynamic>.from(response.data);

      if (map['success'] != true) {
        final err = map['error'] ?? 'Failed to fetch weather.';
        throw Exception(err.toString());
      }

      // If backend sends a refreshed token, store it
      if (map['accessToken'] != null) {
        await _store.write(
          key: 'accessToken',
          value: map['accessToken'].toString(),
        );
      }

      final weatherRaw = map['weather'];
      if (weatherRaw == null) {
        throw Exception('Weather data missing from response.');
      }

      // Just return the weather map itself
      return Map<String, dynamic>.from(weatherRaw as Map);
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


    // ===== UCF Garages / Parking =========================================

  /// Fetch all garages from the backend.
  ///
  /// Backend route: POST /api/viewGarages
  /// Body: { userId, accessToken }
  ///
  /// Expected response:
  /// {
  ///   success: true,
  ///   garages: [
  ///     {
  ///       "garageName": "Garage A",
  ///       "availableSpots": 250,
  ///       "totalSpots": 1000,
  ///       "percentFull": 75,
  ///       "lastUpdated": "2025-11-18T03:12:45.123Z",
  ///       "updatedAt": "...",
  ///       "createdAt": "..."
  ///     },
  ///     ...
  ///   ],
  ///   error: "",
  ///   accessToken: "..."
  /// }
  Future<List<Map<String, dynamic>>> viewGarages() async {
    // Reuse the same auth body helper (userId + accessToken)
    final body = await _buildAuthBody();

    try {
      final res = await _dio.post('/api/viewGarages', data: body);
      final map = Map<String, dynamic>.from(res.data);

      if (map['success'] != true) {
        final err = map['error'] ?? 'Failed to fetch garage data.';
        throw Exception(err.toString());
      }

      // If the backend refreshed the token, persist it
      if (map['accessToken'] != null) {
        await _store.write(
          key: 'accessToken',
          value: map['accessToken'].toString(),
        );
      }

      final raw = map['garages'] ?? [];
      final garages = List<Map<String, dynamic>>.from(
        (raw as List).map(
          (g) => Map<String, dynamic>.from(g as Map),
        ),
      );

      return garages;
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