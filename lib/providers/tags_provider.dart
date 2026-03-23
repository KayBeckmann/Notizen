import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import 'database_provider.dart';

part 'tags_provider.g.dart';

/// Stream aller Tags
@riverpod
Stream<List<Tag>> allTags(Ref ref) {
  return ref.watch(tagsDaoProvider).watchAllTags();
}

/// Stream der Tags einer bestimmten Notiz
@riverpod
Stream<List<Tag>> tagsForNote(Ref ref, String noteId) {
  return ref.watch(tagsDaoProvider).watchTagsForNote(noteId);
}

/// Aktuell ausgewählter Tag zum Filtern
@riverpod
class SelectedTag extends _$SelectedTag {
  @override
  String? build() => null;

  void select(String? tagId) {
    state = tagId;
  }

  void clear() {
    state = null;
  }
}
