import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

/// Reusable card widget for dashboard sections
/// Provides consistent styling and optional gradient backgrounds
class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double? elevation;
  final double borderRadius;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const DashboardCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.elevation,
    this.borderRadius = 16.0,
    this.onTap,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = padding ?? const EdgeInsets.all(16.0);
    final defaultMargin = margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    
    // Determine background decoration
    final decoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? AppColorPalette.white) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColorPalette.charcoalGreen.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
    );

    Widget cardContent = Container(
      decoration: decoration,
      padding: defaultPadding,
      child: child,
    );

    // Wrap with InkWell if onTap is provided
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: defaultMargin,
      child: cardContent,
    );
  }

  /// Factory constructor for gradient cards
  factory DashboardCard.gradient({
    required Widget child,
    required Gradient gradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    VoidCallback? onTap,
  }) {
    return DashboardCard(
      gradient: gradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor for elevated cards
  factory DashboardCard.elevated({
    required Widget child,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double elevation = 4.0,
    VoidCallback? onTap,
  }) {
    return DashboardCard(
      backgroundColor: backgroundColor,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      boxShadow: [
        BoxShadow(
          color: AppColorPalette.charcoalGreen.withOpacity(0.15),
          blurRadius: elevation * 4,
          offset: Offset(0, elevation),
        ),
      ],
      child: child,
    );
  }

  /// Factory constructor for outlined cards
  factory DashboardCard.outlined({
    required Widget child,
    Color? backgroundColor,
    Color borderColor = AppColorPalette.softSlate,
    double borderWidth = 1.5,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    VoidCallback? onTap,
  }) {
    return DashboardCard(
      backgroundColor: backgroundColor,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: const [], // No shadow for outlined cards
      child: child,
    );
  }
}
