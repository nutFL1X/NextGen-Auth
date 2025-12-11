// lib/screens/fusion_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import 'password_screen.dart';
import 'dashboard_screen.dart';

class FusionScreen extends StatefulWidget {
  final String ctWeb;
  final int timeEpoch;
  final bool goToDashboard; // if true → go to Dashboard after animation

  const FusionScreen({
    super.key,
    required this.ctWeb,
    required this.timeEpoch,
    this.goToDashboard = false,
  });

  @override
  State<FusionScreen> createState() => _FusionScreenState();
}

class _FusionScreenState extends State<FusionScreen>
    with TickerProviderStateMixin {
  bool _played = false;
  late final AnimationController _bgController;
  late AnimationController _fusionController;
  Duration _fusionDuration = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    // Background gradient animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Fusion animation controller (duration set after Lottie loads)
    _fusionController = AnimationController(
      vsync: this,
      duration: _fusionDuration,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fusionController.dispose();
    super.dispose();
  }

  Future<void> _startSequence() async {
    if (_played) return;
    _played = true;

    // Small haptic
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 70);
      }
    } catch (_) {}

    // Wait for fusion animation
    await Future.delayed(_fusionDuration);

    // Final vibration
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 120);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _bgController.stop();

    // 🔥 Navigation logic
    if (widget.goToDashboard) {
      // After pairing: go to dashboard
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      // Old flow: go directly to rotating password screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              PasswordScreen(ctWeb: widget.ctWeb),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF101C3A),
                        const Color(0xFF142A52),
                        _bgController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF0B1E3B),
                        const Color(0xFF050A15),
                        _bgController.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Fusion in Progress",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 40),

                // Fusion Lottie animation
                Lottie.asset(
                  'assets/animations/fusion.json',
                  height: 220,
                  repeat: false,
                  fit: BoxFit.contain,
                  controller: _fusionController,
                  onLoaded: (composition) {
                    _fusionDuration = composition.duration;
                    _fusionController.duration = _fusionDuration;

                    _fusionController.forward();
                    _startSequence();
                  },
                ),
                const SizedBox(height: 40),

                // CT_Web info card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.12),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Fusing Biometric Template (CT_Web)",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.ctWeb.length > 40
                              ? '${widget.ctWeb.substring(0, 40)}...'
                              : widget.ctWeb,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Timestamp: ${widget.timeEpoch} (±30s)",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Generating rotating password...",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
