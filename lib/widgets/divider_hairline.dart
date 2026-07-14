import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A hairline divider. Optional inset for the leading edge.
class HairlineDivider extends StatelessWidget {
  final double indent;
  final double? endIndent;
  final double thickness;
  final Color? color;

  const HairlineDivider({
    super.key,
    this.indent = 0,
    this.endIndent,
    this.thickness = 0.5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Divider(
      height: thickness,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent ?? 0,
      color: color ?? c.border,
    );
  }
}
