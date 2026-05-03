import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Standardized Scaffold for Fieldly screens.
///
/// - Uses the app's signature cream background (`AppColors.wheatWarmClay`).
/// - Wraps `body` in `SafeArea` by default to avoid notch / status-bar overlap.
/// - Sets `resizeToAvoidBottomInset: true` so forms shift up with the keyboard.
/// - Forwards every common `Scaffold` slot so existing screens can adopt it
///   incrementally without losing functionality.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool safeArea;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? bodyPadding;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.safeArea = true,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (bodyPadding != null) {
      content = Padding(padding: bodyPadding!, child: content);
    }
    if (safeArea) {
      content = SafeArea(top: !extendBodyBehindAppBar, child: content);
    }
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.wheatWarmClay,
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
