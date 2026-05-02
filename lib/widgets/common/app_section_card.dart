import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/responsive.dart';

/// Standardized white "section" card used across screens.
///
/// - 16dp rounded corners, soft single-direction shadow.
/// - Padding scales with `Responsive.cardPadding(context)` so it adapts on
///   tablets / desktop without changing mobile layouts.
/// - Optional `onTap` upgrades it to a tappable surface using `InkWell`.
class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Gradient? gradient;

  const AppSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius = 16,
    this.onTap,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ??
        EdgeInsets.all(Responsive.cardPadding(context));
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? Colors.white) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryText.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget content = Container(
      padding: resolvedPadding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return Container(margin: margin, child: content);
  }
}
