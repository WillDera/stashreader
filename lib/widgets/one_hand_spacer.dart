import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

/// When one-hand mode is on, this takes up 50 % of the usable screen
/// height.  Place it as the first child inside a scrollable widget so
/// it scrolls away when the user pulls up — it is not a fixed header.
class OneHandSpacer extends StatelessWidget {
  const OneHandSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    final on = context.watch<ThemeProvider>().oneHandMode;
    if (!on) return const SizedBox.shrink();
    final screenHeight = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;
    final available = screenHeight - topInset;
    return SizedBox(height: available * 0.30);
  }
}
