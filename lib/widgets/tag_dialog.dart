import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Schnell-Farbpalette für Tags
const List<Color> tagColors = [
  Color(0xFF6750A4), // Primary (M3 Purple)
  Color(0xFF7D5260), // Tertiary (M3 Pink)
  Color(0xFFB3261E), // Error (Red)
  Color(0xFF0061A4), // Blue
  Color(0xFF006D3B), // Green
  Color(0xFFE65100), // Orange
  Color(0xFF6D4C41), // Brown
  Color(0xFF455A64), // Blue Gray
  Color(0xFF7B1FA2), // Purple
  Color(0xFFC2185B), // Pink
  Color(0xFF00796B), // Teal
  Color(0xFF5D4037), // Deep Brown
];

/// Dialog zum Erstellen eines neuen Tags
class CreateTagDialog extends ConsumerStatefulWidget {
  const CreateTagDialog({super.key});

  @override
  ConsumerState<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends ConsumerState<CreateTagDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = tagColors.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neuer Tag'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tag-Name',
                hintText: 'z.B. Wichtig',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Farbe
            Text(
              'Farbe',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildColorPicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _createTag,
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tagColors.map((color) => _ColorChip(
              color: color,
              isSelected: _selectedColor == color,
              onTap: () => setState(() => _selectedColor = color),
            )),
        // Custom color button
        _ColorChip(
          color: _selectedColor,
          isSelected: !tagColors.contains(_selectedColor),
          icon: Icons.colorize,
          onTap: _showColorPickerDialog,
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _createTag() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }

    ref.read(tagsDaoProvider).createTag(
          TagsCompanion.insert(
            id: const Uuid().v4(),
            name: name,
            color: _selectedColor.toARGB32(),
            createdAt: DateTime.now(),
          ),
        );

    Navigator.pop(context);
  }
}

/// Dialog zum Bearbeiten eines Tags
class EditTagDialog extends ConsumerStatefulWidget {
  final Tag tag;

  const EditTagDialog({super.key, required this.tag});

  @override
  ConsumerState<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends ConsumerState<EditTagDialog> {
  late final TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _selectedColor = Color(widget.tag.color);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tag bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tag-Name',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Farbe
            Text(
              'Farbe',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildColorPicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _updateTag,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tagColors.map((color) => _ColorChip(
              color: color,
              isSelected: _selectedColor == color,
              onTap: () => setState(() => _selectedColor = color),
            )),
        _ColorChip(
          color: _selectedColor,
          isSelected: !tagColors.contains(_selectedColor),
          icon: Icons.colorize,
          onTap: _showColorPickerDialog,
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _updateTag() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }

    ref.read(tagsDaoProvider).updateTag(
          widget.tag.copyWith(
            name: name,
            color: _selectedColor.toARGB32(),
          ),
        );

    Navigator.pop(context);
  }
}

/// Farbauswahl-Chip
class _ColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 3,
                )
              : null,
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: Colors.white)
            : isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
      ),
    );
  }
}

/// Bestätigungsdialog zum Löschen eines Tags
Future<bool?> showDeleteTagDialog(BuildContext context, Tag tag) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tag löschen?'),
      content: Text(
        'Der Tag "${tag.name}" wird von allen Notizen entfernt.',
      ),
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
}
