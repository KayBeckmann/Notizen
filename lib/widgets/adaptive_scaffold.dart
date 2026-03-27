import 'package:flutter/material.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget? drawer;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    this.drawer,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            if (drawer != null)
              SizedBox(
                width: 300,
                child: Drawer(
                  shape: const RoundedRectangleBorder(),
                  child: drawer,
                ),
              ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: appBar,
      drawer: drawer != null ? Drawer(child: drawer) : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
