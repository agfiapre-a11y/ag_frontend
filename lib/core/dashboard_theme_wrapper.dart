import 'package:flutter/material.dart';
import 'theme.dart';

/// Wrapper widget that applies the EmeraldTheme to all dashboard screens
/// while keeping login screen with ParadiseTheme
class DashboardThemeWrapper extends StatelessWidget {
  final Widget child;

  const DashboardThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: EmeraldTheme.theme,
      child: child,
    );
  }
}
