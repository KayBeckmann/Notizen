import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/templates.dart';

part 'templates_dao.g.dart';

/// DAO für Vorlagen-Operationen
@DriftAccessor(tables: [Templates])
class TemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$TemplatesDaoMixin {
  TemplatesDao(super.db);

  /// Alle Vorlagen als Stream
  Stream<List<Template>> watchAllTemplates() {
    return (select(templates)
          ..orderBy([
            (t) => OrderingTerm(expression: t.name),
          ]))
        .watch();
  }

  /// Alle Vorlagen laden
  Future<List<Template>> getAllTemplates() {
    return (select(templates)
          ..orderBy([
            (t) => OrderingTerm(expression: t.name),
          ]))
        .get();
  }

  /// Vorlage nach ID
  Future<Template?> getTemplateById(String id) {
    return (select(templates)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Vorlage erstellen
  Future<void> createTemplate(TemplatesCompanion template) {
    return into(templates).insert(template);
  }

  /// Vorlage aktualisieren
  Future<void> updateTemplate(Template template) {
    return (update(templates)..where((t) => t.id.equals(template.id)))
        .write(template);
  }

  /// Vorlage löschen
  Future<void> deleteTemplate(String id) {
    return (delete(templates)..where((t) => t.id.equals(id))).go();
  }

  /// Vorlagen für bestimmten Content-Type
  Stream<List<Template>> watchTemplatesByType(String contentType) {
    return (select(templates)
          ..where((t) => t.contentType.equals(contentType))
          ..orderBy([
            (t) => OrderingTerm(expression: t.name),
          ]))
        .watch();
  }
}
