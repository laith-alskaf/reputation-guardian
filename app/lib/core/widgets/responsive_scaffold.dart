import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/widgets/custom_app_bar.dart';

/// =============================================================
/// Responsive Scaffold
/// Handles layout, padding & AppBar behavior
/// =============================================================
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool useAnimatedAppBar;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.onBackPressed,
    this.useAnimatedAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,

      /// ---------------- AppBar ----------------
      appBar: CustomAppBar(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
        onBackPressed: onBackPressed,
        animated: useAnimatedAppBar,
      ),

      /// ---------------- Body ----------------
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: body,
        ),
      ),

      /// ---------------- Optional UI ----------------
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
