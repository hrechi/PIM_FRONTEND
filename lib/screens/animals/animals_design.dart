import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/color_palette.dart';
import '../../utils/app_constants.dart';

class AnimalsDesign {
  AnimalsDesign._();

  static const double screenHorizontalPadding = AppUiConstants.screenPadding;
  static const double cardPadding = AppUiConstants.cardPadding;
  static const double cardGap = 12;
  static const double sectionGap = 16;
  static const double formGap = 16;
  static const double buttonHeight = 48;
  static const double borderRadius = AppUiConstants.borderRadius;
  static const double actionIconSize = 24;
  static const double inlineIconSize = 20;
  static const double labelIconSize = 16;

  static BorderRadius get radius =>
      const BorderRadius.all(Radius.circular(borderRadius));

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static AppBar animalsAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    Widget? bottom,
  }) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColorPalette.mistyBlue,
      foregroundColor: Colors.white,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      titleSpacing: 0,
      leading: leading,
      actions: actions,
      bottom: bottom == null ? null : PreferredSize(preferredSize: const Size.fromHeight(60), child: bottom),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(buttonHeight),
      backgroundColor: FieldlyColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: radius),
    );
  }

  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(buttonHeight),
      foregroundColor: FieldlyColors.primary,
      side: const BorderSide(color: FieldlyColors.primary),
      shape: RoundedRectangleBorder(borderRadius: radius),
    );
  }
}
