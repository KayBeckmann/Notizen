import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';

/// Service für persistierte App-Einstellungen
class SettingsService {
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;

  SettingsService._();

  SharedPreferences? _prefs;

  /// Initialisiert den Service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Keys für SharedPreferences
  static const String _sortOrderKey = 'sort_order';
  static const String _sortDirectionKey = 'sort_direction';
  static const String _lastFolderKey = 'last_folder';
  static const String _editorSplitModeKey = 'editor_split_mode';
  static const String _editorModeKey = 'editor_mode';
  static const String _viewModeKey = 'view_mode';

  // --- Sort Order ---

  SortOrder get sortOrder {
    final index = _prefs?.getInt(_sortOrderKey) ?? SortOrder.modified.index;
    return SortOrder.values[index];
  }

  Future<void> setSortOrder(SortOrder order) async {
    await _prefs?.setInt(_sortOrderKey, order.index);
  }

  // --- Sort Direction ---

  SortDirection get sortDirection {
    final index =
        _prefs?.getInt(_sortDirectionKey) ?? SortDirection.descending.index;
    return SortDirection.values[index];
  }

  Future<void> setSortDirection(SortDirection direction) async {
    await _prefs?.setInt(_sortDirectionKey, direction.index);
  }

  // --- Last Folder ---

  String? get lastFolder {
    return _prefs?.getString(_lastFolderKey);
  }

  Future<void> setLastFolder(String? folderId) async {
    if (folderId == null) {
      await _prefs?.remove(_lastFolderKey);
    } else {
      await _prefs?.setString(_lastFolderKey, folderId);
    }
  }

  // --- Editor Split Mode (deprecated, use editorMode) ---

  bool get editorSplitMode {
    return _prefs?.getBool(_editorSplitModeKey) ?? true;
  }

  Future<void> setEditorSplitMode(bool enabled) async {
    await _prefs?.setBool(_editorSplitModeKey, enabled);
  }

  // --- Editor Mode (edit=0, preview=1, split=2) ---

  int get editorModeIndex {
    return _prefs?.getInt(_editorModeKey) ?? 2; // Default to split
  }

  Future<void> setEditorModeIndex(int index) async {
    await _prefs?.setInt(_editorModeKey, index);
  }

  // --- Use Split Mode on Desktop by default ---

  bool get useSplitOnDesktop {
    return _prefs?.getBool('use_split_on_desktop') ?? true;
  }

  Future<void> setUseSplitOnDesktop(bool enabled) async {
    await _prefs?.setBool('use_split_on_desktop', enabled);
  }

  // --- View Mode (List/Grid) ---

  ViewMode get viewMode {
    final index = _prefs?.getInt(_viewModeKey) ?? ViewMode.list.index;
    return ViewMode.values[index];
  }

  Future<void> setViewMode(ViewMode mode) async {
    await _prefs?.setInt(_viewModeKey, mode.index);
  }
}
