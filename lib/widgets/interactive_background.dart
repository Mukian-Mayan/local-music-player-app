import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A slowly drifting, blurred glow backdrop behind the glass panels. Two
/// glows drift on their own; a third gently follows the user's drag, so the
/// background feels alive and responsive rather than static.
class InteractiveBackground extends StatefulWidget {
  const InteractiveBackground({super.key});

  @override
  State<InteractiveBackground> createState() => _InteractiveBackgroundState();
}

class _InteractiveBackgroundState extends State<InteractiveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _dragFraction = const Offset(0.5, 0.3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDrag(Offset localPosition, Size size) {
    if (size.width == 0 || size.height == 0) return;
    setState(() {
      _dragFraction = Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0),
        (localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBg : AppColors.lightBg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: (d) => _updateDrag(d.localPosition, size),
          onPanUpdate: (d) => _updateDrag(d.localPosition, size),
          child: Container(
            color: base,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value * 2 * math.pi;
                return Stack(
                  children: [
                    _glow(
                      Alignment(0.6 * math.cos(t), 0.5 * math.sin(t)),
                      AppColors.accent.withValues(alpha: isDark ? 0.28 : 0.16),
                      280,
                    ),
                    _glow(
                      Alignment(
                          -0.7 * math.sin(t * 0.7), 0.6 * math.cos(t * 0.7)),
                      AppColors.accent.withValues(alpha: isDark ? 0.14 : 0.08),
                      340,
                    ),
                    _glow(
                      Alignment(
                        (_dragFraction.dx * 2) - 1,
                        (_dragFraction.dy * 2) - 1,
                      ),
                      AppColors.accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      260,
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _glow(Alignment alignment, Color color, double diameter) {
    return Align(
      alignment: alignment,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
