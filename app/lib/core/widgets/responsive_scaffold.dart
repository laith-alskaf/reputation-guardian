import 'package:flutter/material.dart';
import 'package:reputation_guardian/core/utils/responsive.dart';
import 'package:reputation_guardian/core/widgets/custom_app_bar.dart';

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
    this.useAnimatedAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: useAnimatedAppBar
          ? AnimatedCustomAppBar(
              title: title,
              actions: actions,
              showBackButton: showBackButton,
              onBackPressed: onBackPressed,
            )
          : CustomAppBar(
              title: title,
              actions: actions,
              showBackButton: showBackButton,
              onBackPressed: onBackPressed,
            ),
      drawer: drawer,
      body: SafeArea(
        child: Padding(padding: context.responsivePadding, child: body),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
