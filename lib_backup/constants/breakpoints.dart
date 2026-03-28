import 'package:flutter/widgets.dart';

/// Responsive Breakpoints nach Material Design 3
class Breakpoints {
  /// Compact (Phone): < 600dp
  static const double compact = 600;

  /// Medium (Tablet): 600dp - 840dp
  static const double medium = 840;

  /// Expanded (Desktop): > 840dp
  static const double expanded = 1200;

  /// Large (Desktop): > 1200dp
  static const double large = 1600;

  /// Prüft ob das Gerät ein Telefon ist
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compact;
  }

  /// Prüft ob das Gerät ein Tablet ist
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compact && width < medium;
  }

  /// Prüft ob das Gerät ein Desktop ist
  static bool isExpanded(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= medium;
  }

  /// Prüft ob das Gerät ein großer Desktop ist
  static bool isLarge(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= expanded;
  }

  /// Gibt den aktuellen Layout-Typ zurück
  static LayoutType getLayoutType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return LayoutType.compact;
    if (width < medium) return LayoutType.medium;
    if (width < expanded) return LayoutType.expanded;
    return LayoutType.large;
  }
}

/// Layout-Typen
enum LayoutType {
  compact,
  medium,
  expanded,
  large,
}

/// Widget das je nach Bildschirmgröße verschiedene Layouts anzeigt
class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final layoutType = Breakpoints.getLayoutType(context);

    switch (layoutType) {
      case LayoutType.compact:
        return compact;
      case LayoutType.medium:
        return medium ?? compact;
      case LayoutType.expanded:
      case LayoutType.large:
        return expanded ?? medium ?? compact;
    }
  }
}
