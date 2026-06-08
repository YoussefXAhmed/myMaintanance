import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

/// Full-screen ambient background: a deep gradient with several slowly drifting,
/// blurred colour blobs. This is what the frosted-glass surfaces refract.
class FrostedBackground extends StatefulWidget {
  const FrostedBackground({super.key, required this.child, this.animate = true});

  final Widget child;
  final bool animate;

  @override
  State<FrostedBackground> createState() => _FrostedBackgroundState();
}

class _FrostedBackgroundState extends State<FrostedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: glass.background,
        ),
      ),
      child: Stack(
        children: [
          if (widget.animate)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(
                  painter: _BlobPainter(_c.value, glass.brightness),
                ),
              ),
            ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t, this.brightness);
  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = brightness == Brightness.dark ? 0.42 : 0.30;
    final blobs = <_Blob>[
      _Blob(AppColors.primary, const Offset(0.12, 0.12), 0.55, 0.0),
      _Blob(AppColors.secondary, const Offset(0.85, 0.08), 0.50, 0.4),
      _Blob(AppColors.tertiary, const Offset(0.78, 0.82), 0.52, 0.7),
      _Blob(AppColors.accentPink, const Offset(0.10, 0.88), 0.42, 0.2),
    ];
    for (final b in blobs) {
      final angle = (t + b.phase) * 2 * math.pi;
      final dx = (b.center.dx + 0.05 * math.cos(angle)) * size.width;
      final dy = (b.center.dy + 0.05 * math.sin(angle)) * size.height;
      final radius = b.radius * size.shortestSide;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: dim), b.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.t != t || old.brightness != brightness;
}

class _Blob {
  const _Blob(this.color, this.center, this.radius, this.phase);
  final Color color;
  final Offset center;
  final double radius;
  final double phase;
}
