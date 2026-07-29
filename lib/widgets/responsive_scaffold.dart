import 'package:flutter/material.dart';
import 'app_drawer.dart';

/// A responsive Scaffold that shows a permanent navigation drawer on desktop
/// and a temporary slide-in drawer on mobile/tablet.
///
/// Drop-in replacement for `Scaffold` that automatically handles:
/// - Mobile: hamburger menu drawer (default Flutter behavior)
/// - Desktop (>= 1024px): permanent left drawer, no hamburger needed
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? persistentFooterButtons;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.persistentFooterButtons,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      persistentFooterButtons: persistentFooterButtons,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
    );
  }
}
