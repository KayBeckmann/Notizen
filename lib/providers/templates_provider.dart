import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../database/daos/templates_dao.dart';
import 'database_provider.dart';

part 'templates_provider.g.dart';

/// Provider für den TemplatesDao
@riverpod
TemplatesDao templatesDao(Ref ref) {
  final db = ref.watch(databaseProvider);
  return TemplatesDao(db);
}

/// Stream aller Vorlagen
@riverpod
Stream<List<Template>> allTemplates(Ref ref) {
  return ref.watch(templatesDaoProvider).watchAllTemplates();
}

/// Vorlagen für bestimmten Content-Type
@riverpod
Stream<List<Template>> templatesByType(Ref ref, String contentType) {
  return ref.watch(templatesDaoProvider).watchTemplatesByType(contentType);
}
