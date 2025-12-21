import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool enableGradient;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.padding,
    this.borderRadius,
    this.enableGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tintColor = scheme.surface;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              scheme.surface.withValues(alpha: 0.42),
              scheme.primary.withValues(alpha: 0.14),
              scheme.surface.withValues(alpha: 0.26),
            ]
          : [
              scheme.surface.withValues(alpha: 0.82),
              scheme.primary.withValues(alpha: 0.08),
              scheme.surface.withValues(alpha: 0.62),
            ],
    );
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tintColor.withValues(alpha: opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.10),
              width: 1.5,
            ),
            gradient: enableGradient ? gradient : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
