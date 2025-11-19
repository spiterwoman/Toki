import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// update this to your real path
import '../../../lib/core/api/api.dart';

// ===== Mocks ==============================================================

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockDio mockDio;
  late MockSecureStorage mockStore;
  late Api api;

  setUpAll(() {
    // Needed so mocktail has a fallback instance for non-nullable RequestOptions
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = MockDio();
    mockStore = MockSecureStorage();

    // Common auth setup: pretend user is logged in
    when(() => mockStore.read(key: 'accessToken'))
        .thenAnswer((_) async => 'fake-access-token');
    when(() => mockStore.read(key: 'userId'))
        .thenAnswer((_) async => 'fake-user-id');

    api = Api.forTesting(
      dio: mockDio,
      store: mockStore,
    );
  });

  // ========================================================================
  // Reminders APIs
  // ========================================================================

  test('createReminder sends correct body and parses success', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'reminderId': 'abc123',
          'error': '',
          'accessToken': 'refreshed-token',
        },
        requestOptions: RequestOptions(path: '/api/createReminder'),
      ),
    );

    final due = DateTime(2025, 11, 17);

    final res = await api.createReminder(
      title: 'Test reminder',
      desc: 'Do the thing',
      status: 'pending',
      priority: 'high',
      dueDate: due,
    );

    expect(res['success'], true);
    expect(res['reminderId'], 'abc123');

    verify(() => mockDio.post(
          '/api/createReminder',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['userId'], 'userId', 'fake-user-id')
                .having((m) => m['accessToken'], 'accessToken',
                    'fake-access-token')
                .having((m) => m['title'], 'title', 'Test reminder')
                .having((m) => m['priority'], 'priority', 'high')
                .having((m) => m['year'], 'year', due.year)
                .having((m) => m['month'], 'month', due.month)
                .having((m) => m['day'], 'day', due.day),
          ),
        )).called(1);
  });

  test('viewReminders calls /api/viewReminder and returns data map', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'reminders': [
            {
              '_id': '1',
              'title': 'R1',
            },
          ],
          'error': '',
        },
        requestOptions: RequestOptions(path: '/api/viewReminder'),
      ),
    );

    final res = await api.viewReminders();

    expect(res['success'], true);
    expect((res['reminders'] as List).length, 1);

    verify(() => mockDio.post(
          '/api/viewReminder',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['userId'], 'userId', 'fake-user-id')
                .having((m) => m['accessToken'], 'accessToken',
                    'fake-access-token'),
          ),
        )).called(1);
  });

  test('completeReminder hits /api/completeReminder with title', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {'success': true, 'error': ''},
        requestOptions: RequestOptions(path: '/api/completeReminder'),
      ),
    );

    final res = await api.completeReminder(title: 'R1');

    expect(res['success'], true);

    verify(() => mockDio.post(
          '/api/completeReminder',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['title'], 'title', 'R1')
                .having((m) => m['userId'], 'userId', 'fake-user-id'),
          ),
        )).called(1);
  });

  test('deleteReminder sends title', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {'success': true, 'error': ''},
        requestOptions: RequestOptions(path: '/api/deleteReminder'),
      ),
    );

    final res = await api.deleteReminder(title: 'R1');

    expect(res['success'], true);

    verify(() => mockDio.post(
          '/api/deleteReminder',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['title'], 'title', 'R1')
                .having((m) => m['userId'], 'userId', 'fake-user-id'),
          ),
        )).called(1);
  });

  // ========================================================================
  // Tasks APIs
  // ========================================================================

  test('createTask sends minimal valid payload and parses success', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'taskId': 'task-123',
          'error': '',
          'accessToken': 'refreshed-token',
        },
        requestOptions: RequestOptions(path: '/api/createTask'),
      ),
    );

    final due = DateTime(2025, 11, 17);

    final res = await api.createTask(
      title: 'My task',
      description: 'Testing',
      status: 'not started',
      priority: 'medium',
      dueDate: due,
    );

    expect(res['success'], true);
    expect(res['taskId'], 'task-123');

    verify(() => mockDio.post(
          '/api/createTask',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['title'], 'title', 'My task')
                .having((m) => m['priority'], 'priority', 'medium')
                .having((m) => m['userId'], 'userId', 'fake-user-id'),
          ),
        )).called(1);
  });

  test('viewTasks requests tasks and parses list', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'tasks': [
            {
              '_id': '1',
              'title': 'Task 1',
            },
          ],
          'error': '',
        },
        requestOptions: RequestOptions(path: '/api/viewTask'),
      ),
    );

    final res = await api.viewTasks();

    expect(res['success'], true);
    expect((res['tasks'] as List).length, 1);

    verify(() => mockDio.post(
          '/api/viewTask',
          data: any(named: 'data'),
        )).called(1);
  });

  test('deleteTask posts title only', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {'success': true, 'error': ''},
        requestOptions: RequestOptions(path: '/api/deleteTask'),
      ),
    );

    final res = await api.deleteTask(title: 'Task 1');

    expect(res['success'], true);

    verify(() => mockDio.post(
          '/api/deleteTask',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['title'], 'title', 'Task 1')
                .having((m) => m['userId'], 'userId', 'fake-user-id'),
          ),
        )).called(1);
  });

  // ========================================================================
  // Calendar APIs
  // ========================================================================

  test('createCalendarEvent posts title/description/endDate and returns eventId',
      () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'eventId': 'event-123',
          'error': '',
          'accessToken': 'refreshed-token',
        },
        requestOptions: RequestOptions(path: '/api/createCalendarEvent'),
      ),
    );

    final end = DateTime(2025, 11, 17, 15, 30);

    final res = await api.createCalendarEvent(
      title: 'Launch',
      description: 'Big launch',
      endDate: end,
    );

    expect(res['success'], true);
    expect(res['eventId'], 'event-123');

    verify(() => mockDio.post(
          '/api/createCalendarEvent',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['title'], 'title', 'Launch')
                .having((m) => m['description'], 'description', 'Big launch')
                .having((m) => m['userId'], 'userId', 'fake-user-id'),
          ),
        )).called(1);
  });

  test('viewCalendarEvents without id fetches all events', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'events': [
            {
              '_id': 'e1',
              'title': 'Calendar Event',
            },
          ],
          'error': '',
        },
        requestOptions: RequestOptions(path: '/api/viewCalendarEvent'),
      ),
    );

    final res = await api.viewCalendarEvents();

    expect(res['success'], true);
    expect((res['events'] as List).length, 1);

    verify(() => mockDio.post(
          '/api/viewCalendarEvent',
          data: any(named: 'data'),
        )).called(1);
  });

  test('deleteCalendarEvent posts title', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {'success': true, 'error': ''},
        requestOptions: RequestOptions(path: '/api/deleteCalendarEvent'),
      ),
    );

    final res = await api.deleteCalendarEvent(title: 'Calendar Event');

    expect(res['success'], true);

    verify(() => mockDio.post(
          '/api/deleteCalendarEvent',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['title'], 'title', 'Calendar Event')
                .having((m) => m['userId'], 'userId', 'fake-user-id'),
          ),
        )).called(1);
  });

  // ========================================================================
  // NASA APOD APIs
  // ========================================================================


  test('fetchRecentApods posts limit and parses photos list', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'photos': [
            {
              'date': '2025-11-15',
              'title': 'Photo 1',
              'thumbnailUrl': 'https://example.com/t1.jpg',
            },
            {
              'date': '2025-11-16',
              'title': 'Photo 2',
              'thumbnailUrl': 'https://example.com/t2.jpg',
            },
          ],
          'error': '',
        },
        requestOptions: RequestOptions(path: '/api/recentAPODs'),
      ),
    );

    final photos = await api.fetchRecentApods(limit: 2);

    expect(photos.length, 2);
    expect(photos[0]['title'], 'Photo 1');
    expect(photos[1]['title'], 'Photo 2');

    verify(() => mockDio.post(
          '/api/recentAPODs',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>()
                .having((m) => m['limit'], 'limit', 2)
                .having((m) => m['accessToken'], 'accessToken',
                    'fake-access-token'),
          ),
        )).called(1);
  });

  // ========================================================================
  // Weather & Garages
  // ========================================================================

  test('viewWeather parses weather map', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'weather': {
            'location': 'Orlando, FL',
            'high': 80,
            'low': 65,
            'forecast': 'Sunny',
            'humid': 50,
            'vis': 10,
            'pressure': 1012,
            'windSpeed': 5,
            'sunrise': '7:00 AM',
            'sunset': '7:30 PM',
          },
          'error': '',
        },
        requestOptions: RequestOptions(path: '/api/viewWeather'),
      ),
    );

    final w = await api.viewWeather();

    expect(w['location'], 'Orlando, FL');
    expect(w['high'], 80);
  });

  test('viewGarages parses list of garages', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        data: {
          'success': true,
          'garages': [
            {
              'garageName': 'Garage A',
              'availableSpots': 100,
              'totalSpots': 500,
            },
          ],
          'error': '',
        },
        requestOptions: RequestOptions(path: '/api/viewGarages'),
      ),
    );

    final garages = await api.viewGarages();

    expect(garages.length, 1);
    expect(garages[0]['garageName'], 'Garage A');
  });
}
