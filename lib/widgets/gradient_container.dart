import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

/// Reusable container widget with gradient background support
/// Provides flexible gradient configurations for visual impact
class GradientContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GradientContainer({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColorPalette.charcoalGreen.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  /// Factory constructor for Field Fresh gradient
  factory GradientContainer.fieldFresh({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: AppColorPalette.fieldFreshGradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor for Robot Tech gradient
  factory GradientContainer.robotTech({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: AppColorPalette.robotTechGradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor for Success gradient
  factory GradientContainer.success({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: AppColorPalette.successGradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor for Alert gradient
  factory GradientContainer.alert({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: AppColorPalette.alertGradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor for custom gradient
  factory GradientContainer.custom({
    required Widget child,
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ),
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor for radial gradient
  factory GradientContainer.radial({
    required Widget child,
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 0.5,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: RadialGradient(
        colors: colors,
        center: center,
        radius: radius,
      ),
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor with no shadow (flat design)
  factory GradientContainer.flat({
    required Widget child,
    required Gradient gradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      gradient: gradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      boxShadow: const [], // No shadow
      child: child,
    );
  }
}
