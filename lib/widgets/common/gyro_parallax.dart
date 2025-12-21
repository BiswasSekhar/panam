import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroParallax extends StatefulWidget {
  final Widget child;

  /// Max translation in logical pixels.
  final double maxOffset;

  /// Max rotation in radians.
  final double maxRotation;

  const GyroParallax({
    super.key,
    required this.child,
    this.maxOffset = 10,
    this.maxRotation = 0.03,
  });

  @override
  State<GyroParallax> createState() => _GyroParallaxState();
}

class _GyroParallaxState extends State<GyroParallax> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _dx = 0;
  double _dy = 0;

  @override
  void initState() {
    super.initState();

    // Accelerometer is usually available on-device; on simulators it may be zero.
    _sub = accelerometerEventStream().listen((event) {
      // event.x: left/right, event.y: up/down depending on device orientation.
      // Keep it subtle.
      final nx = (event.x / 9.81).clamp(-1.0, 1.0);
      final ny = (event.y / 9.81).clamp(-1.0, 1.0);

      if (!mounted) return;
      setState(() {
        _dx = -nx * widget.maxOffset;
        _dy = ny * widget.maxOffset;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rx = (_dy / widget.maxOffset) * widget.maxRotation;
    final ry = (_dx / widget.maxOffset) * widget.maxRotation;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(rx)
        ..rotateY(ry)
        ..translate(_dx, _dy),
      child: widget.child,
    );
  }
}
