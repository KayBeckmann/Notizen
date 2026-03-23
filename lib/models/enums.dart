/// Enum für den Inhaltstyp einer Notiz
enum ContentType {
  text,
  audio,
  image,
  drawing,
}

/// Enum für die Sortierreihenfolge
enum SortOrder {
  name,
  created,
  modified,
}

/// Enum für die Sortierrichtung
enum SortDirection {
  ascending,
  descending,
}

/// Standard-Ordnerfarben (Material Design 3 Farben)
class FolderColors {
  static const List<int> defaults = [
    0xFF6750A4, // Primary
    0xFF625B71, // Secondary
    0xFF7D5260, // Tertiary
    0xFFBA1A1A, // Error
    0xFF006D3C, // Green
    0xFF006493, // Blue
    0xFFFF8F00, // Orange
    0xFF6D4C41, // Brown
  ];
}

/// Standard-Tag-Farben
class TagColors {
  static const List<int> defaults = [
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFFFFEB3B, // Yellow
    0xFFFF9800, // Orange
    0xFFFF5722, // Deep Orange
    0xFF795548, // Brown
  ];
}
