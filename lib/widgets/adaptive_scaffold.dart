import 'package:flutter/material.dart';

import '../constants/breakpoints.dart';

/// Adaptives Scaffold das je nach Bildschirmgröße verschiedene Navigations-Layouts verwendet
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final Widget? navigationRail;
  final Widget? permanentDrawer;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.navigationRail,
    this.permanentDrawer,
    this.appBar,
    this.floatingActionButton,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final layoutType = Breakpoints.getLayoutType(context);

    switch (layoutType) {
      case LayoutType.compact:
        // Phone: Drawer
        return Scaffold(
          key: scaffoldKey,
          appBar: appBar,
          drawer: drawer,
          body: body,
          floatingActionButton: floatingActionButton,
        );

      case LayoutType.medium:
        // Tablet: NavigationRail
        return Scaffold(
          key: scaffoldKey,
          appBar: appBar,
          body: Row(
            children: [
              if (navigationRail != null) navigationRail!,
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
          floatingActionButton: floatingActionButton,
        );

      case LayoutType.expanded:
      case LayoutType.large:
        // Desktop: Permanente Sidebar
        return Scaffold(
          key: scaffoldKey,
          body: Row(
            children: [
              if (permanentDrawer != null)
                SizedBox(
                  width: 280,
                  child: permanentDrawer!,
                ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Scaffold(
                  appBar: appBar,
                  body: body,
                  floatingActionButton: floatingActionButton,
                ),
              ),
            ],
          ),
        );
    }
  }
}
