import 'package:flutter/material.dart';

import '../constants/breakpoints.dart';

/// Adaptives Scaffold das je nach Bildschirmgröße verschiedene Navigations-Layouts verwendet
class AdaptiveScaffold extends StatefulWidget {
  final Widget body;
  final Widget? secondaryBody;
  final Widget? drawer;
  final Widget? navigationRail;
  final Widget? permanentDrawer;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final double initialSidebarWidth;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.secondaryBody,
    this.drawer,
    this.navigationRail,
    this.permanentDrawer,
    this.appBar,
    this.floatingActionButton,
    this.scaffoldKey,
    this.initialSidebarWidth = 280,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  late double _sidebarWidth;
  double _listWidth = 350.0;

  @override
  void initState() {
    super.initState();
    _sidebarWidth = widget.initialSidebarWidth;
  }

  @override
  Widget build(BuildContext context) {
    final layoutType = Breakpoints.getLayoutType(context);

    switch (layoutType) {
      case LayoutType.compact:
        // Phone: Drawer
        return Scaffold(
          key: widget.scaffoldKey,
          appBar: widget.appBar,
          drawer: widget.drawer,
          body: widget.body,
          floatingActionButton: widget.floatingActionButton,
        );

      case LayoutType.medium:
        // Tablet: NavigationRail
        return Scaffold(
          key: widget.scaffoldKey,
          appBar: widget.appBar,
          body: Row(
            children: [
              if (widget.navigationRail != null) widget.navigationRail!,
              const VerticalDivider(width: 1),
              Expanded(child: widget.body),
            ],
          ),
          floatingActionButton: widget.floatingActionButton,
        );

      case LayoutType.expanded:
      case LayoutType.large:
        // Desktop: Permanente Sidebar + Optionale 3. Spalte
        return Scaffold(
          key: widget.scaffoldKey,
          body: Row(
            children: [
              if (widget.permanentDrawer != null)
                SizedBox(
                  width: _sidebarWidth,
                  child: widget.permanentDrawer!,
                ),
              if (widget.permanentDrawer != null)
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      setState(() {
                        _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(200.0, 400.0);
                      });
                    },
                    child: const SizedBox(
                      width: 8,
                      child: VerticalDivider(width: 8, thickness: 1),
                    ),
                  ),
                ),
              if (widget.secondaryBody == null)
                Expanded(
                  child: Scaffold(
                    appBar: widget.appBar,
                    body: widget.body,
                    floatingActionButton: widget.floatingActionButton,
                  ),
                )
              else ...[
                SizedBox(
                  width: _listWidth,
                  child: Scaffold(
                    appBar: widget.appBar,
                    body: widget.body,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      setState(() {
                        _listWidth = (_listWidth + details.delta.dx).clamp(250.0, 600.0);
                      });
                    },
                    child: const SizedBox(
                      width: 8,
                      child: VerticalDivider(width: 8, thickness: 1),
                    ),
                  ),
                ),
                Expanded(
                  child: widget.secondaryBody!,
                ),
              ],
            ],
          ),
          floatingActionButton: widget.secondaryBody != null ? widget.floatingActionButton : null,
        );
    }
  }
}

