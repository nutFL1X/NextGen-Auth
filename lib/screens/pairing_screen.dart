// lib/screens/pairing_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

import '../services/pairing_service.dart';
import '../services/storage_service.dart';
import 'dashboard_screen.dart';
import 'fusion_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();

  bool _scanned = false;
  bool _showFlashOverlay = false;
  bool _isProcessing = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Open dashboard directly (demo button)
  void _goToDashboardDirect() {
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _isProcessing) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    _scanned = true;
    _isProcessing = true;
    await _controller.stop();

    // small haptic + flash
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) await Vibration.vibrate(duration: 80);
    } catch (_) {}

    setState(() => _showFlashOverlay = true);
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() => _showFlashOverlay = false);

    final raw = code.trim();

    try {
      // 🔹 Try to parse QR as JSON (our website format)
      Map<String, dynamic>? parsed;
      try {
        parsed = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        parsed = null;
      }

      final isWebsiteQr =
          parsed != null && parsed['s'] != null && parsed['u'] != null && parsed['t'] != null;

      if (isWebsiteQr) {
        // REAL WEBSITE QR → call backend
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pairing with server...'),
            duration: Duration(seconds: 1),
          ),
        );

        // uses the raw JSON text; pairing_service decodes it again
        final site = await pairFromQr(raw);
        await StorageService.addOrUpdateSite(site);

        if (!mounted) return;

        // Show fusion animation, then go to DASHBOARD (not password screen)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                FusionScreen(
              ctWeb: site.ctWebBase64,
              timeEpoch: DateTime.now().millisecondsSinceEpoch,
              goToDashboard: true, // <<< important
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        );
      } else {
        // Not our QR → just show error and resume scanner
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR format for pairing")),
        );
        _scanned = false;
        _isProcessing = false;
        await _controller.start();
      }
    } catch (e) {
      debugPrint('Error during pairing: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pairing failed: $e')),
      );
      _scanned = false;
      _isProcessing = false;
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // dark overlay
          Container(
            color: Colors.black.withValues(alpha: 0.65),
          ),

          // neon frame + scan line
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + 0.02 * _pulseController.value;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const _AnimatedScanLine(),
                if (_showFlashOverlay)
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),

          // text
          Positioned(
            bottom: 140,
            child: Column(
              children: const [
                Text(
                  "Align QR inside the frame",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Scan a website to pair your fingerprint",
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          // DASHBOARD button
          Positioned(
            bottom: 60,
            child: ElevatedButton(
              onPressed: _goToDashboardDirect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Dashboard',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedScanLine extends StatefulWidget {
  const _AnimatedScanLine();

  @override
  State<_AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<_AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pos = Tween<double>(begin: 0.05, end: 0.85)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pos,
      builder: (context, child) {
        return Positioned(
          top: 260 * _pos.value,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.9),
                  Colors.cyanAccent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
