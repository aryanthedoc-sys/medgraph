import 'package:flutter/material.dart';

/// Renders [mobile] below 600px width, [desktop] at or above.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  final Widget mobile;
  final Widget desktop;

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600;

  @override
  Widget build(BuildContext context) =>
      isDesktop(context) ? desktop : mobile;
}
