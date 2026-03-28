import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../services/settings_service.dart';
import 'database_provider.dart';

part 'folders_provider.g.dart';

/// Stream aller Ordner
@riverpod
Stream<List<Folder>> allFolders(Ref ref) {
  return ref.watch(foldersDaoProvider).watchAllFolders();
}

/// Stream der Root-Ordner
@riverpod
Stream<List<Folder>> rootFolders(Ref ref) {
  return ref.watch(foldersDaoProvider).watchRootFolders();
}

/// Stream der Kind-Ordner
@riverpod
Stream<List<Folder>> childFolders(Ref ref, String parentId) {
  return ref.watch(foldersDaoProvider).watchChildFolders(parentId);
}

/// Aktuell ausgewählter Ordner (persistiert)
@riverpod
class CurrentFolder extends _$CurrentFolder {
  @override
  String? build() {
    // Letzten Ordner aus Einstellungen laden
    final lastFolder = SettingsService.instance.lastFolder;
    return lastFolder ?? 'default';
  }

  void select(String? folderId) {
    state = folderId;
    // Ordner in Einstellungen speichern
    SettingsService.instance.setLastFolder(folderId);
  }
}

/// Hierarchische Ordnerstruktur als Baum
class FolderNode {
  final Folder folder;
  final List<FolderNode> children;

  FolderNode({required this.folder, this.children = const []});
}

/// Ordnerbaum Provider
@riverpod
Future<List<FolderNode>> folderTree(Ref ref) async {
  final folders = await ref.watch(allFoldersProvider.future);
  return _buildTree(folders, null);
}

List<FolderNode> _buildTree(List<Folder> folders, String? parentId) {
  final children = folders.where((f) => f.parentId == parentId).toList();
  return children.map((folder) {
    return FolderNode(
      folder: folder,
      children: _buildTree(folders, folder.id),
    );
  }).toList();
}
