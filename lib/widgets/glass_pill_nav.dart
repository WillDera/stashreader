import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/app_motion.dart';
import '../theme/tokens/app_spacing.dart';

class NavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  const NavItem({required this.icon, this.activeIcon, required this.label});
}

/// A floating, frosted-glass bottom navigation pill.
///
/// The active indicator morphs smoothly between segments (animated position)
/// and the icons swap between outlined and filled variants when active.
class GlassPillNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final EdgeInsets margin;

  const GlassPillNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 60,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = c.bg.computeLuminance() < 0.5;
    final glassColor = isDark
        ? const Color(0xCC16171A)
        : const Color(0xCCFBFAF6);
    final innerStroke = isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x66FFFFFF);

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: AppSpacing.brPill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: AppSpacing.brPill,
                border: Border.all(
                  color: c.border.withValues(alpha: isDark ? 0.6 : 0.8),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0x66000000)
                        : const Color(0x1A000000),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final segWidth = constraints.maxWidth / items.length;
                  return Stack(
                    children: [
                      // Active indicator — morphs between segments.
                      AnimatedPositioned(
                        duration: AppMotion.base,
                        curve: AppMotion.standard,
                        left: segWidth * currentIndex + segWidth * 0.18,
                        top: 8,
                        bottom: 8,
                        width: segWidth * 0.64,
                        child: AnimatedContainer(
                          duration: AppMotion.base,
                          curve: AppMotion.standard,
                          decoration: BoxDecoration(
                            color: c.accentMuted,
                            borderRadius: AppSpacing.brPill,
                            border: Border(
                              top: BorderSide(
                                color: innerStroke,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(items.length, (i) {
                          final item = items[i];
                          final isActive = i == currentIndex;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTap(i),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: AppMotion.fast,
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                                  child: Column(
                                    key: ValueKey('${item.label}-$isActive'),
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isActive
                                            ? (item.activeIcon ?? item.icon)
                                            : item.icon,
                                        size: 22,
                                        color: isActive
                                            ? c.accent
                                            : c.textTertiary,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isActive
                                              ? c.accent
                                              : c.textTertiary,
                                          fontSize: 10,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
