import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import 'database_provider.dart';

part 'tags_provider.g.dart';

@riverpod
Stream<List<Tag>> allTags(AllTagsRef ref) {
  return ref.watch(tagsDaoProvider).watchAllTags();
}
