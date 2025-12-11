import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'screens/pairing_screen.dart';

void main() {
  runApp(const BioKeyRotateApp());
}

class BioKeyRotateApp extends StatelessWidget {
  const BioKeyRotateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BioKeyRotate',
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6A88E5),
      ),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _checking = true;
  bool _authFailedOrCanceled = false;
  AppLifecycleState? _lastLifecycleState; // 🔹 Track last lifecycle state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticateUser(); // 🔐 Only called on initial launch
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔹 Only re-auth when returning from REAL background (paused → resumed)
    if (_lastLifecycleState == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed) {
      setState(() {
        _checking = true;
        _authFailedOrCanceled = false;
      });
      _authenticateUser();
    }

    _lastLifecycleState = state;
  }

  Future<void> _authenticateUser() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isSupported) {
        setState(() {
          _checking = false;
          _authFailedOrCanceled = true;
        });
        return;
      }

      final bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to access BioKeyRotate',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'BioKeyRotate Locked',
            cancelButton: 'Cancel',
          ),
        ],
      );

      if (!mounted) return;

      if (isAuthenticated) {
        _goToPairing();
      } else {
        setState(() {
          _checking = false;
          _authFailedOrCanceled = true;
        });
      }
    } catch (e) {
      debugPrint("Authentication failed: $e");
      if (mounted) {
        setState(() {
          _checking = false;
          _authFailedOrCanceled = true;
        });
      }
    }
  }

  void _goToPairing() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PairingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.45),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: _checking
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "NextGen: Authentication",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_authFailedOrCanceled)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "App is locked.\nUse your device fingerprint to unlock.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _authenticateUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF6A88E5),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fingerprint),
                            SizedBox(width: 8),
                            Text(
                              "Unlock with fingerprint",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
