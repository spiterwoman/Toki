import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  final Dio _dio;
  final FlutterSecureStorage _store;

  // -----------------------------
  // NORMAL CONSTRUCTOR (production)
  // -----------------------------
  Api(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json'},
          ),
        ),
        _store = const FlutterSecureStorage() {
    // Attach JWT from secure storage as Authorization: Bearer <token>
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _store.read(key: 'accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
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

  /// For legacy routes that still expect userId/accessToken in the body.
  /// Many routes now just use authMiddleware + Authorization header,
  /// but this helper is still safe to use (extra fields are ignored by Node).
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

  // ======================================================================
  //                            AUTH & USER
  // ======================================================================

  /// Signup -> /api/addUser
  ///
  /// Backend expects: { name, email, password }
  /// We concatenate first + last into "name".
  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final name = (firstName.trim() + ' ' + lastName.trim()).trim();

    final res = await _dio.post('/api/addUser', data: {
      'name': name,
      'email': email,
      'password': password,
    });

    final map = Map<String, dynamic>.from(res.data);

    if (map['accessToken'] != null) {
      await _store.write(key: 'accessToken', value: map['accessToken']);
      await _store.write(key: 'userId', value: map['id'].toString());
    }

    return map; // { id, firstName, lastName, accessToken, verificationToken, error }
  }

  /// Login -> /api/loginUser
  ///
  /// Returns id, firstName, lastName, accessToken, maybe verificationToken, error
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/api/loginUser', data: {
      'email': email,
      'password': password,
    });

    final map = Map<String, dynamic>.from(res.data);

    if (map['accessToken'] != null) {
      await _store.write(key: 'accessToken', value: map['accessToken']);
      await _store.write(key: 'userId', value: map['id'].toString());
      if (map['verificationToken'] != null) {
        await _store.write(
          key: 'verificationToken',
          value: map['verificationToken'].toString(),
        );
      }
    }

    return map;
  }

  /// Verify user email -> /api/verifyUser (authMiddleware)
  ///
  /// Backend body: { email, verificationToken }
  /// Response: { id, error }
  Future<Map<String, dynamic>> verifyUser({
    required String email,
    required String verificationToken,
  }) async {
    final res = await _dio.post('/api/verifyUser', data: {
      'email': email,
      // Backend stores it as a number; we parse to int here.
      'verificationToken': int.parse(verificationToken),
    });

    return Map<String, dynamic>.from(res.data);
  }

  /// Simple logout helper for frontend -> /api/logout
  ///
  /// Backend just returns { error: '', jwtToken: '' }.
  Future<Map<String, dynamic>> logout() async {
    final res = await _dio.post('/api/logout');
    final map = Map<String, dynamic>.from(res.data);

    // Clear stored token regardless
    await _store.delete(key: 'accessToken');
    await _store.delete(key: 'userId');
    await _store.delete(key: 'verificationToken');

    return map;
  }

  // ======================================================================
  //                            REMINDERS
  // ======================================================================

  /// Create a reminder -> /api/createReminder
  ///
  /// Backend currently only uses "title" (desc/status/priority/dueDate are
  /// handled in editReminder). Extra fields are harmless.
  Future<Map<String, dynamic>> createReminder({
    required String title,
    String? desc,
    String? status,
    String? priority,
    DateTime? dueDate,
  }) async {
    final extra = <String, dynamic>{
      'title': title,
    };

    if (desc != null) extra['desc'] = desc;
    if (status != null) extra['status'] = status;
    if (priority != null) extra['priority'] = priority;
    if (dueDate != null) {
      extra['year'] = dueDate.year;
      extra['month'] = dueDate.month;
      extra['day'] = dueDate.day;
    }

    final body = await _buildAuthBody(extra);

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

  /// View reminders -> /api/viewReminder
  ///
  /// Backend body: optional { title } to fetch a single reminder,
  /// or nothing to fetch all.
  ///
  /// Returns either:
  ///  { success, reminder, error } OR { success, reminders, error }
  Future<Map<String, dynamic>> viewReminders({String? title}) async {
    final extra = <String, dynamic>{};
    if (title != null) {
      extra['title'] = title;
    }

    final body = await _buildAuthBody(extra.isEmpty ? null : extra);

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

  /// Mark a reminder completed -> /api/completeReminder
  ///
  /// Backend identifies reminders by (userId, title).
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

  /// Delete reminder -> /api/deleteReminder
  ///
  /// Backend deletes by (userId, title).
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

  /// Edit reminder -> /api/editReminder
  ///
  /// Backend finds reminder by (userId, title) then updates fields.
  Future<Map<String, dynamic>> editReminder({
    required String title,
    String? desc,
    String? status,
    String? priority,
    DateTime? dueDate,
  }) async {
    final extra = <String, dynamic>{
      'title': title,
    };

    if (desc != null) extra['desc'] = desc;
    if (status != null) extra['status'] = status;
    if (priority != null) extra['priority'] = priority;
    if (dueDate != null) {
      extra['year'] = dueDate.year;
      extra['month'] = dueDate.month;
      extra['day'] = dueDate.day;
    }

    final body = await _buildAuthBody(extra);

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

  // ======================================================================
  //                               TASKS
  // ======================================================================

  /// Create task -> /api/createTask
  ///
  /// Backend expects: { title, dueDate, tag, priority }
  ///   - dueDate: string or null; backend does new Date(dueDate)
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description, // stored only via editTask
    String? status, // stored only via editTask
    String? priority,
    String? tag,
    DateTime? dueDate,
    bool? isCompleted, // stored only via editTask
    DateTime? completedAt, // stored only via editTask
  }) async {
    final extra = <String, dynamic>{
      'title': title,
    };

    if (priority != null) extra['priority'] = priority;
    if (tag != null) extra['tag'] = tag;
    if (dueDate != null) extra['dueDate'] = dueDate.toIso8601String();

    // description/status/completed are used in editTask; including them
    // here is harmless but not necessary.
    if (description != null) extra['description'] = description;
    if (status != null) extra['status'] = status;
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

  /// View tasks -> /api/viewTask
  ///
  /// Backend body: optional { title } to fetch a specific task,
  /// or nothing to fetch all for the user.
  ///
  /// Returns:
  ///  - { success, task, error }  OR
  ///  - { success, tasks, error }
  Future<Map<String, dynamic>> viewTasks({String? title}) async {
    final extra = <String, dynamic>{};
    if (title != null) {
      extra['title'] = title;
    }

    final body = await _buildAuthBody(extra.isEmpty ? null : extra);

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

  /// Edit task -> /api/editTask
  ///
  /// Backend edits by taskId (ObjectId), and userId from authMiddleware.
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

  /// Delete task -> /api/deleteTask
  ///
  /// Delete a task (backend: POST /api/deleteTask)
  ///
  /// Backend expects { title }.
  Future<Map<String, dynamic>> deleteTask({
    required String title,
  }) async {
    final body = await _buildAuthBody({
      'title': title,
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


  // ======================================================================
  //                          CALENDAR EVENTS
  // ======================================================================

  /// Create calendar event -> /api/createCalendarEvent
  ///
  /// Backend expects: { title, description, endDate }
  ///   - startDate is set to new Date() server-side.
  /// Extra fields are safe but currently ignored.
  Future<Map<String, dynamic>> createCalendarEvent({
    required String title,
    String? description,
    DateTime? endDate,
  }) async {
    final extra = <String, dynamic>{
      'title': title,
    };

    if (description != null) extra['description'] = description;
    if (endDate != null) extra['endDate'] = endDate.toIso8601String();

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

  /// View calendar events -> /api/viewCalendarEvent
  ///
  /// Backend body: optional { title } to get a single event,
  /// or nothing to get all events for the user.
  ///
  /// Returns:
  ///  - { success, event, error } OR { success, events, error }
  Future<Map<String, dynamic>> viewCalendarEvents({String? title}) async {
    final extra = <String, dynamic>{};
    if (title != null) {
      extra['title'] = title;
    }

    final body = await _buildAuthBody(extra.isEmpty ? null : extra);

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

  /// Edit calendar event -> /api/editCalendarEvent
  ///
  /// Backend edits by eventId (ObjectId) + userId.
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

  /// Delete calendar event -> /api/deleteCalendarEvent
  ///
  /// Backend deletes by (userId, title), **not** eventId.
  Future<Map<String, dynamic>> deleteCalendarEvent({
    String? eventId, // legacy, unused by backend
    String? title,
  }) async {
    if (title == null || title.isEmpty) {
      throw Exception(
        'deleteCalendarEvent now deletes by title. Please provide the event title.',
      );
    }

    final body = await _buildAuthBody({
      'title': title,
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

  // ======================================================================
  //                              NASA APOD
  // ======================================================================

  String _formatApodDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// View APOD for a specific date -> /api/viewAPOD (authMiddleware)
  ///
  /// Backend body: { date: "YYYY-MM-DD" }
  Future<Map<String, dynamic>> viewApod({
    required DateTime date,
  }) async {
    final dateStr = _formatApodDate(date);

    try {
      final response = await _dio.post(
        '/api/viewAPOD',
        data: {
          'date': dateStr,
        },
      );

      return Map<String, dynamic>.from(response.data);
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

  /// NOTE: /api/recentAPODs is commented out in api.js right now.
  /// This will fail if called until that route is re-enabled.
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

  // ======================================================================
  //                               WEATHER
  // ======================================================================

  /// View current weather -> /api/viewWeather (authMiddleware)
  ///
  /// Returns on success:
  /// {
  ///   success: true,
  ///   weather: {
  ///     location, high, low, sunrise, sunset,
  ///     forecast, humid, vis, pressure, windSpeed, lastUpdated
  ///   },
  ///   error: ''
  /// }
  Future<Map<String, dynamic>> viewWeather() async {
    try {
      // authMiddleware uses Authorization header; no body needed
      final response = await _dio.post('/api/viewWeather');

      final map = Map<String, dynamic>.from(response.data);

      if (map['success'] != true) {
        final err = map['error'] ?? 'Failed to fetch weather.';
        throw Exception(err.toString());
      }

      final weatherRaw = map['weather'];
      if (weatherRaw == null) {
        throw Exception('Weather data missing from response.');
      }

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

  // ======================================================================
  //                          UCF GARAGES / PARKING
  // ======================================================================

  /// View garages -> /api/viewGarages (authMiddleware)
  ///
  /// Backend returns:
  /// {
  ///   success: true,
  ///   garages: [
  ///     {
  ///       "garageName": "Garage A",
  ///       "availableSpots": 250,
  ///       "totalSpots": 1000,
  ///       "percentFull": 75,
  ///       "lastUpdated": "...",
  ///       ...
  ///     },
  ///     ...
  ///   ],
  ///   error: ''
  /// }
  Future<List<Map<String, dynamic>>> viewGarages() async {
    // No body required; auth via header only.
    try {
      final res = await _dio.post('/api/viewGarages');
      final map = Map<String, dynamic>.from(res.data);

      if (map['success'] != true) {
        final err = map['error'] ?? 'Failed to fetch garage data.';
        throw Exception(err.toString());
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
