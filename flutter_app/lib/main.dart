import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/verification_page.dart';
import 'features/reminders/reminders_page.dart';
import 'features/daily_summary/daily_summary.dart';
import 'features/calendar/calendar_page.dart';
import 'features/tasks/tasks_page.dart';
import 'features/weather/weather_page.dart';
import 'features/nasa_photos/nasa_photo_page.dart';
import 'features/ucf_parking/parking_page.dart';

void main() {
  runApp(const TokiApp());
}

class TokiApp extends StatelessWidget {
  const TokiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toki',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F1E),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // landing page
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/verify': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          final email = args['email'] as String;
          final verificationToken = int.parse(args['verificationToken'].toString());

          return VerificationPage(
            email: email,
            verificationToken: verificationToken,
          );
        },
        '/reminders': (context) => const RemindersPage(),
        '/daily': (context) => const DailySummaryPage(),
        '/tasks': (context) => const TasksPage(),
        '/weather': (context) => const WeatherPage(),
        '/nasa-photo': (context) => const NasaPhotoPage(),
        '/parking': (context) => const UcfParkingPage(),
        '/calendar': (context) => const CalendarPage()
        /*
        Put this instead of => for verify if everything breaks
        
          const VerificationPage()

        */
      },
    );
  }
}
