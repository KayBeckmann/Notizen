import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import 'database_provider.dart';

part 'folders_provider.g.dart';

@riverpod
Stream<List<Folder>> allFolders(AllFoldersRef ref) {
  return ref.watch(foldersDaoProvider).watchAllFolders();
}

@riverpod
Stream<List<Folder>> rootFolders(RootFoldersRef ref) {
  return ref.watch(foldersDaoProvider).watchRootFolders();
}
