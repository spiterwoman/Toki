import 'package:flutter/material.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: Hook up to real auth later
    Navigator.of(context).pushNamed('/verify');
  }

  @override
  Widget build(BuildContext context) {
    return const PageShell(
      showMenu: false,
      child: _SignupBody(),
    );
  }
}

class _SignupBody extends StatelessWidget {
  const _SignupBody();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SignupPageState>()!;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: state._formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Create your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: .85,
                    child: const Text(
                      'Join Toki to get started',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  const Text('Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: state._nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ada Lovelace',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  const Text('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: state._emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'astronaut@toki.space',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  const Text('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: state._pwCtrl,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Confirm password
                  const Text('Confirm password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: state._pw2Ctrl,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm password';
                      if (v != state._pwCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton(
                    onPressed: state._onSubmit,
                    child: const Text('Sign up'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Opacity(
                          opacity: .7,
                          child: const Text('Already have an account? '),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/login'),
                          child: const Text('Log in'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
