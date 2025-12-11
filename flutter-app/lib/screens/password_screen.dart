// lib/screens/password_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:crypto/crypto.dart';  // NEW for SHA256

class PasswordScreen extends StatefulWidget {
  final String ctWeb;

  const PasswordScreen({
    super.key,
    required this.ctWeb,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  late String _rotatingPassword;
  late Timer _timer;
  late Timer _progressTimer;
  static const Duration _rotationDuration = Duration(seconds: 30);
  double _progressValue = 1.0;
  int _secondsLeft = 30;
  bool _copiedPassword = false;

  @override
  void initState() {
    super.initState();
    _generatePassword();
    _startRotationTimer();
    _startProgressCountdown();
  }

  /// ---------------------------------------------------------
  /// 🔥 MAIN PASSWORD GENERATOR
  ///
  /// Computes:
  ///   hash = SHA256( CTweb + floor(epoch/30) )
  ///   → Take first 8 chars (A–Z + 0–9)
  ///
  /// The same formula MUST be used on your backend.
  /// ---------------------------------------------------------
  String _generateTOTPPassword(String ctWeb, int epochSec) {
    int timeWindow = epochSec ~/ 30; // 30-second rolling bucket

    final raw = utf8.encode("$ctWeb$timeWindow");
    final digest = sha256.convert(raw).toString().toUpperCase();

    // Get password (e.g., 8 characters alphanumeric)
    return digest.substring(0, 8);
  }

  void _generatePassword() {
    final int epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    setState(() {
      _rotatingPassword = _generateTOTPPassword(widget.ctWeb, epoch);
      _progressValue = 1.0;
      _secondsLeft = _rotationDuration.inSeconds;
    });
  }

  void _startRotationTimer() {
    _timer = Timer.periodic(_rotationDuration, (_) {
      _generatePassword();
    });
  }

  void _startProgressCountdown() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, _rotationDuration.inSeconds);
        _progressValue = _secondsLeft / _rotationDuration.inSeconds;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressTimer.cancel();
    super.dispose();
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _rotatingPassword));
    setState(() => _copiedPassword = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedPassword = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0F1F),
              Color(0xFF1A2440),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 140,
                    child: Lottie.asset(
                      'assets/animations/unlock_success.json',
                      repeat: false,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Your Rotating Password",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _rotatingPassword,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 34,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(
                                _copiedPassword ? Icons.check_rounded : Icons.copy_rounded,
                                color: _copiedPassword ? Colors.greenAccent : Colors.white70,
                                size: 26,
                              ),
                              onPressed: _copyPassword,
                              tooltip: 'Copy password',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      widget.ctWeb,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressValue,
                      minHeight: 8,
                      color: Colors.greenAccent,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Next password in $_secondsLeft s",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
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
