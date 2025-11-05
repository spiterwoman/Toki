import 'package:flutter/material.dart';
import 'core/widgets/page_shell.dart';
import 'core/widgets/glass_card.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';

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
        // Temporary placeholder so /verify works during testing:
        '/verify': (context) => const _VerifyPlaceholder(),
      },
    );
  }
}

class _VerifyPlaceholder extends StatelessWidget {
  const _VerifyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const PageShell(
      title: 'Verification',
      subtitle: 'Replace this screen with your real verification page.',
      child: GlassCard(child: Text('Verification placeholder')),
    );
  }
}
