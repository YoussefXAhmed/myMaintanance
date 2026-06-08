import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

/// A large animated circular gauge used for the overall Vehicle Health Score.
/// Sweeps from 0 to [value] (0..100) with a glowing gradient arc.
class CircularHealthIndicator extends StatefulWidget {
  const CircularHealthIndicator({
    super.key,
    required this.value,
    this.size = 200,
    this.label,
    this.strokeWidth = 16,
  });

  final double value; // 0..100
  final double size;
  final String? label;
  final double strokeWidth;

  @override
  State<CircularHealthIndicator> createState() => _CircularHealthIndicatorState();
}

class _CircularHealthIndicatorState extends State<CircularHealthIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant CircularHealthIndicator old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final gradient = AppColors.gradientForScore(widget.value);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final shown = widget.value * _anim.value;
          return CustomPaint(
            painter: _GaugePainter(
              value: shown,
              track: glass.border,
              gradient: gradient,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label ?? '',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (r) => gradient.createShader(r),
                    child: Text(
                      '${shown.round()}%',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.track,
    required this.gradient,
    required this.strokeWidth,
  });

  final double value;
  final Color track;
  final Gradient gradient;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * (value / 100);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + 2 * math.pi,
        colors: gradient.colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    canvas.drawArc(rect, start, sweep, false, arcPaint);

    // Glowing tip
    if (value > 0) {
      final tipAngle = start + sweep;
      final tip = Offset(center.dx + radius * math.cos(tipAngle), center.dy + radius * math.sin(tipAngle));
      final glow = Paint()
        ..color = gradient.colors.last.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(tip, strokeWidth * 0.55, glow);
      canvas.drawCircle(tip, strokeWidth * 0.32, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value || old.track != track;
}

/// Compact ring used for sub-systems (oil, battery, tyre, insurance).
class MiniHealthRing extends StatelessWidget {
  const MiniHealthRing({
    super.key,
    required this.value,
    required this.icon,
    required this.label,
    this.size = 64,
  });

  final double value;
  final IconData icon;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final color = AppColors.forScore(value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value / 100),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: 5,
                    backgroundColor: glass.border,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Icon(icon, size: size * 0.34, color: color),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: glass.textMuted)),
        Text('${value.round()}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textPrimary)),
      ],
    );
  }
}
