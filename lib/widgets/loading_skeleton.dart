import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/app_spacing.dart';

/// A shimmer-style placeholder box. Use for skeletons while content loads.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppSpacing.brSm,
            gradient: LinearGradient(
              begin: Alignment(-1 + _ctrl.value * 2, 0),
              end: Alignment(1 + _ctrl.value * 2, 0),
              colors: [
                c.surfaceMuted,
                c.surface,
                c.surfaceMuted,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
