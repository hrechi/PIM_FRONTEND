import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// App-wide primary button.
///
/// - Defaults to the Fieldly green (`AppColors.mistyBlue`).
/// - `gradient = true` switches to the green-to-emerald hero gradient for
///   high-impact CTAs (e.g., dashboard actions).
/// - Always full-width inside its parent (parents control width via
///   `Expanded` / `SizedBox`).
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;
  final bool gradient;
  final Color? color;
  final double height;
  final double borderRadius;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.gradient = false,
    this.color,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.mistyBlue;
    final isDisabled = onPressed == null || loading;

    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );

    final decoration = BoxDecoration(
      gradient: gradient
          ? LinearGradient(
              colors: [bg, AppColors.fieldFreshStart],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: gradient ? null : (isDisabled ? bg.withValues(alpha: 0.5) : bg),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isDisabled
          ? const []
          : [
              BoxShadow(
                color: bg.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: decoration,
          child: Center(child: child),
        ),
      ),
    );
  }
}
