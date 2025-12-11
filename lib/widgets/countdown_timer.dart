import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final Function(int) onTick;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.onComplete,
    required this.onTick,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int remaining;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remaining = widget.seconds;
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => remaining--);
      widget.onTick(remaining);
      if (remaining <= 0) {
        t.cancel();
        widget.onComplete();
        remaining = widget.seconds;
        startTimer(); // clean restart
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "$remaining s left",
          style: const TextStyle(fontSize: 16, color: Colors.cyanAccent),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: remaining / widget.seconds,
          color: Colors.cyanAccent,
          backgroundColor: Colors.grey[800],
        ),
      ],
    );
  }
}
