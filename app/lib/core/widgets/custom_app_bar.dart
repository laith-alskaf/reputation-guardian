import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// =============================================================
/// Custom AppBar – Enterprise SaaS Style
/// =============================================================
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool animated;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return animated
        ? _AnimatedAppBarContent(
            title: title,
            actions: actions,
            showBackButton: showBackButton,
            onBackPressed: onBackPressed,
          )
        : _StaticAppBarContent(
            title: title,
            actions: actions,
            showBackButton: showBackButton,
            onBackPressed: onBackPressed,
          );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// =============================================================
/// Static AppBar
/// =============================================================
class _StaticAppBarContent extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const _StaticAppBarContent({
    required this.title,
    this.actions,
    required this.showBackButton,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: AppColors.elevatedShadow,
      ),
      child: _BaseAppBar(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
        onBackPressed: onBackPressed,
      ),
    );
  }
}

/// =============================================================
/// Animated AppBar
/// =============================================================
class _AnimatedAppBarContent extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const _AnimatedAppBarContent({
    required this.title,
    this.actions,
    required this.showBackButton,
    this.onBackPressed,
  });

  @override
  State<_AnimatedAppBarContent> createState() =>
      _AnimatedAppBarContentState();
}

class _AnimatedAppBarContentState extends State<_AnimatedAppBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGradient.colors[0],
                AppColors.primaryGradient.colors[1],
                AppColors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.6 + (_animation.value * 0.2), 1.0],
            ),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: _BaseAppBar(
            title: widget.title,
            actions: widget.actions,
            showBackButton: widget.showBackButton,
            onBackPressed: widget.onBackPressed,
          ),
        );
      },
    );
  }
}

/// =============================================================
/// Base AppBar (Shared UI)
/// =============================================================
class _BaseAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const _BaseAppBar({
    required this.title,
    this.actions,
    required this.showBackButton,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? _BackButton(onPressed: onBackPressed)
          : const _AppLogo(),
      title: _TitleWithBadge(title: title),
      actions: actions ?? const [_NotificationAction()],
    );
  }
}

/// =============================================================
/// Components
/// =============================================================
class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.pop(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          'assets/icons/icon.png',
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

class _TitleWithBadge extends StatelessWidget {
  final String title;

  const _TitleWithBadge({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        _ProBadge(),
      ],
    );
  }
}

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Pro',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationAction extends StatelessWidget {
  const _NotificationAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: () {
          // TODO: Notifications
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
