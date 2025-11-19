import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A simple wrapper to handle Android back button for tabbed or paged screens.
///
/// Behavior:
/// - If a TabController is provided and its current index > 0, back moves to the previous tab.
/// - Else, if a PageController is provided and current page > 0, back moves to the previous page.
/// - Otherwise, the route is allowed to pop normally.
class TabBackHandler extends StatelessWidget {
  final Widget child;
  final TabController? tabController;
  final PageController? pageController;

  const TabBackHandler({
    super.key,
    required this.child,
    this.tabController,
    this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Handle TabController first
        final tc = tabController;
        if (tc != null) {
          final idx = tc.index;
          if (idx > 0) {
            tc.animateTo(idx - 1);
            return;
          }
        }

        // Handle PageController next
        final pc = pageController;
        if (pc != null && pc.hasClients) {
          final page = pc.page ?? pc.initialPage.toDouble();
          final current = page.round();
          if (current > 0) {
            pc.animateToPage(
              current - 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
            return;
          }
        }

        // Default: allow normal back navigation (prefer GoRouter)
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          Navigator.maybePop(context);
        }
      },
      child: child,
    );
  }
}
