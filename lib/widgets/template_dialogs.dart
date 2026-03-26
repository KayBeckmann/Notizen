import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../providers/templates_provider.dart';

/// Dialog zum Speichern einer Notiz als Vorlage
class SaveAsTemplateDialog extends ConsumerStatefulWidget {
  final String? title;
  final String content;
  final String contentType;

  const SaveAsTemplateDialog({
    super.key,
    this.title,
    required this.content,
    this.contentType = 'text',
  });

  @override
  ConsumerState<SaveAsTemplateDialog> createState() =>
      _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends ConsumerState<SaveAsTemplateDialog> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  Color _selectedColor = const Color(0xFF6750A4);
  String _selectedIcon = 'description';

  final _icons = [
    'description',
    'article',
    'note',
    'sticky_note_2',
    'list_alt',
    'checklist',
    'assignment',
    'event_note',
    'subject',
    'text_snippet',
    'format_quote',
    'code',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _titleController = TextEditingController(text: widget.title ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Als Vorlage speichern'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name der Vorlage',
                hintText: 'z.B. Meeting-Notizen',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel-Vorlage (optional)',
                hintText: 'z.B. Meeting vom {datum}',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Farbe',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in [
                  const Color(0xFF6750A4),
                  const Color(0xFF4285F4),
                  const Color(0xFF34A853),
                  const Color(0xFFFBBC04),
                  const Color(0xFFEA4335),
                  const Color(0xFFFF6D00),
                  const Color(0xFF9C27B0),
                  const Color(0xFF00BCD4),
                ])
                  InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: _selectedColor == color
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const SweepGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                          Colors.red,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.colorize,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((iconName) {
                final icon = _getIconData(iconName);
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? _selectedColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saveTemplate,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'description':
        return Icons.description;
      case 'article':
        return Icons.article;
      case 'note':
        return Icons.note;
      case 'sticky_note_2':
        return Icons.sticky_note_2;
      case 'list_alt':
        return Icons.list_alt;
      case 'checklist':
        return Icons.checklist;
      case 'assignment':
        return Icons.assignment;
      case 'event_note':
        return Icons.event_note;
      case 'subject':
        return Icons.subject;
      case 'text_snippet':
        return Icons.text_snippet;
      case 'format_quote':
        return Icons.format_quote;
      case 'code':
        return Icons.code;
      default:
        return Icons.description;
    }
  }

  Future<void> _saveTemplate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }

    final now = DateTime.now();
    final template = TemplatesCompanion.insert(
      id: const Uuid().v4(),
      name: name,
      titleTemplate: Value(_titleController.text.trim()),
      content: Value(widget.content),
      contentType: Value(widget.contentType),
      icon: Value(_selectedIcon),
      color: Value(_selectedColor.value),
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(templatesDaoProvider).createTemplate(template);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vorlage gespeichert')),
      );
    }
  }
}

/// Dialog zur Auswahl einer Vorlage
class SelectTemplateDialog extends ConsumerWidget {
  final String? contentType;

  const SelectTemplateDialog({
    super.key,
    this.contentType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = contentType != null
        ? ref.watch(templatesByTypeProvider(contentType!))
        : ref.watch(allTemplatesProvider);

    return AlertDialog(
      title: const Text('Vorlage wählen'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Vorlagen vorhanden',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateListTile(
                  template: template,
                  onTap: () => Navigator.pop(context, template),
                  onDelete: () => _confirmDelete(context, ref, template),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Fehler: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'empty'),
          child: const Text('Leere Notiz'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Template template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vorlage löschen?'),
        content: Text(
            'Möchtest du die Vorlage "${template.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(templatesDaoProvider).deleteTemplate(template.id);
    }
  }
}

class _TemplateListTile extends StatelessWidget {
  final Template template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateListTile({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(template.color).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getIconData(template.icon),
          color: Color(template.color),
        ),
      ),
      title: Text(template.name),
      subtitle: template.titleTemplate.isNotEmpty
          ? Text(
              template.titleTemplate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'description':
        return Icons.description;
      case 'article':
        return Icons.article;
      case 'note':
        return Icons.note;
      case 'sticky_note_2':
        return Icons.sticky_note_2;
      case 'list_alt':
        return Icons.list_alt;
      case 'checklist':
        return Icons.checklist;
      case 'assignment':
        return Icons.assignment;
      case 'event_note':
        return Icons.event_note;
      case 'subject':
        return Icons.subject;
      case 'text_snippet':
        return Icons.text_snippet;
      case 'format_quote':
        return Icons.format_quote;
      case 'code':
        return Icons.code;
      default:
        return Icons.description;
    }
  }
}
