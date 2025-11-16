import 'package:flutter/material.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';


class VerificationPage extends StatefulWidget {
  final String email;
  final int verificationToken;
  final Future<bool> Function(String code)? onVerify;
  final VoidCallback? onResend;

  const VerificationPage({
    super.key,
    required this.email,
    required this.verificationToken,
    this.onVerify,
    this.onResend,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _codeCtrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Autofocus after first frame to mirror the TSX behavior
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
  final code = _codeCtrl.text;
  if (code.length != 6) {
    _focus.requestFocus();
    return;
  }
    try {
      final api = Api('https://mytoki.app');
      final email = widget.email;
      // Preserve the code as a string so leading zeros are not lost.
      final res = await api.verifyUser(
        email: email,
        verificationToken: code,
      );

    debugPrint('verifyUser response: $res');

    final err = res['error']?.toString() ?? 'unknown';

    if (err.toLowerCase().startsWith('success')) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/reminders');
    } else {
      if (!mounted) return;
      _showSnack(err); // show the REAL error from backend
      _focus.requestFocus();
    }
    } catch (e, st) {
      debugPrint('verifyUser exception: $e\n$st');
      if (!mounted) return;
      _showSnack('Error verifying code. Please try again.');
      _focus.requestFocus();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      showMenu: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // circular icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(128, 90, 213, 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.mail_outline,
                                size: 32, color: Color(0xFFA78BFA)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Opacity(
                          opacity: 0.6,
                          child: Text(
                            "We've sent a verification code to ${widget.email}",
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hidden raw input (digits only) + visible 6 slots
                  // Tap anywhere on the slots to focus the hidden field.
                  GestureDetector(
                    onTap: () => _focus.requestFocus(),
                    child: Column(
                      children: [
                        // invisible TextField that actually receives input
                        Opacity(
                          opacity: 0.0,
                          child: SizedBox(
                            height: 0,
                            child: TextField(
                              controller: _codeCtrl,
                              focusNode: _focus,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              // keep only digits
                              onChanged: (v) {
                                final digits = v.replaceAll(RegExp(r'\D'), '');
                                if (digits != v) {
                                  _codeCtrl.text = digits;
                                  _codeCtrl.selection = TextSelection.fromPosition(
                                      TextPosition(offset: digits.length));
                                }
                                setState(() {}); // rebuild slots
                              },
                            ),
                          ),
                        ),
                        _OtpSlots(code: _codeCtrl.text),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleVerify,
                      child: const Text('Verify Email'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Resend
                  Opacity(
                    opacity: 0.6,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text("Didn't receive the code? "),
                        TextButton(
                          onPressed: () {
                            widget.onResend?.call();
                            _showSnack('Verification code resent (stub).');
                          },
                          child: const Text(
                            'Resend',
                            style: TextStyle(decoration: TextDecoration.underline),
                          ),
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

/// Visual row of 6 OTP boxes mirroring the TSX styles.
class _OtpSlots extends StatelessWidget {
  final String code;
  const _OtpSlots({required this.code});

  @override
  Widget build(BuildContext context) {
    final boxes = List.generate(6, (i) {
      final hasChar = i < code.length;
      final display = hasChar ? code[i] : '';
      final isActive = !hasChar && i == code.length; // focus highlight for next slot
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6EA8FF).withOpacity(0.15),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          display,
          style: const TextStyle(fontSize: 18),
        ),
      );
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < boxes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          boxes[i],
        ],
      ],
    );
  }
}