import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';

/// Verfügbare Icons für Ordner
const List<IconData> folderIcons = [
  Icons.folder,
  Icons.work,
  Icons.home,
  Icons.school,
  Icons.favorite,
  Icons.star,
  Icons.bookmark,
  Icons.label,
  Icons.shopping_cart,
  Icons.attach_money,
  Icons.flight,
  Icons.restaurant,
  Icons.fitness_center,
  Icons.music_note,
  Icons.movie,
  Icons.photo_camera,
  Icons.code,
  Icons.science,
  Icons.medical_services,
  Icons.pets,
  Icons.sports_soccer,
  Icons.local_cafe,
  Icons.lightbulb,
  Icons.psychology,
];

/// Icon-Name zu IconData Mapping
IconData getIconFromName(String name) {
  return switch (name) {
    'work' => Icons.work,
    'home' => Icons.home,
    'school' => Icons.school,
    'favorite' => Icons.favorite,
    'star' => Icons.star,
    'bookmark' => Icons.bookmark,
    'label' => Icons.label,
    'shopping_cart' => Icons.shopping_cart,
    'attach_money' => Icons.attach_money,
    'flight' => Icons.flight,
    'restaurant' => Icons.restaurant,
    'fitness_center' => Icons.fitness_center,
    'music_note' => Icons.music_note,
    'movie' => Icons.movie,
    'photo_camera' => Icons.photo_camera,
    'code' => Icons.code,
    'science' => Icons.science,
    'medical_services' => Icons.medical_services,
    'pets' => Icons.pets,
    'sports_soccer' => Icons.sports_soccer,
    'local_cafe' => Icons.local_cafe,
    'lightbulb' => Icons.lightbulb,
    'psychology' => Icons.psychology,
    _ => Icons.folder,
  };
}

/// IconData zu Name Mapping
String getIconName(IconData icon) {
  if (icon == Icons.work) return 'work';
  if (icon == Icons.home) return 'home';
  if (icon == Icons.school) return 'school';
  if (icon == Icons.favorite) return 'favorite';
  if (icon == Icons.star) return 'star';
  if (icon == Icons.bookmark) return 'bookmark';
  if (icon == Icons.label) return 'label';
  if (icon == Icons.shopping_cart) return 'shopping_cart';
  if (icon == Icons.attach_money) return 'attach_money';
  if (icon == Icons.flight) return 'flight';
  if (icon == Icons.restaurant) return 'restaurant';
  if (icon == Icons.fitness_center) return 'fitness_center';
  if (icon == Icons.music_note) return 'music_note';
  if (icon == Icons.movie) return 'movie';
  if (icon == Icons.photo_camera) return 'photo_camera';
  if (icon == Icons.code) return 'code';
  if (icon == Icons.science) return 'science';
  if (icon == Icons.medical_services) return 'medical_services';
  if (icon == Icons.pets) return 'pets';
  if (icon == Icons.sports_soccer) return 'sports_soccer';
  if (icon == Icons.local_cafe) return 'local_cafe';
  if (icon == Icons.lightbulb) return 'lightbulb';
  if (icon == Icons.psychology) return 'psychology';
  return 'folder';
}

/// Schnell-Farbpalette für Ordner
const List<Color> folderColors = [
  Color(0xFF6750A4), // Primary (M3 Purple)
  Color(0xFF7D5260), // Tertiary (M3 Pink)
  Color(0xFF625B71), // Secondary (M3 Gray-Purple)
  Color(0xFFB3261E), // Error (Red)
  Color(0xFF0061A4), // Blue
  Color(0xFF006D3B), // Green
  Color(0xFFE65100), // Orange
  Color(0xFF6D4C41), // Brown
  Color(0xFF455A64), // Blue Gray
  Color(0xFF7B1FA2), // Purple
  Color(0xFFC2185B), // Pink
  Color(0xFF00796B), // Teal
];

/// Dialog zum Erstellen eines neuen Ordners
class CreateFolderDialog extends ConsumerStatefulWidget {
  final String? parentId;

  const CreateFolderDialog({super.key, this.parentId});

  @override
  ConsumerState<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends ConsumerState<CreateFolderDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = folderColors.first;
  IconData _selectedIcon = Icons.folder;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);

    return AlertDialog(
      title: const Text('Neuer Ordner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ordnername',
                hintText: 'z.B. Arbeit',
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
            const SizedBox(height: 24),

            // Icon
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildIconPicker(),
            const SizedBox(height: 24),

            // Parent Folder
            Text(
              'Übergeordneter Ordner',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            foldersAsync.when(
              data: (folders) => _buildParentDropdown(folders),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Fehler beim Laden'),
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
          onPressed: _createFolder,
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
        ...folderColors.map((color) => _ColorChip(
              color: color,
              isSelected: _selectedColor == color,
              onTap: () => setState(() => _selectedColor = color),
            )),
        // Custom color button
        _ColorChip(
          color: _selectedColor,
          isSelected: !folderColors.contains(_selectedColor),
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

  Widget _buildIconPicker() {
    return SizedBox(
      height: 160,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: folderIcons.length,
        itemBuilder: (context, index) {
          final icon = folderIcons[index];
          final isSelected = _selectedIcon == icon;
          return InkWell(
            onTap: () => setState(() => _selectedIcon = icon),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentDropdown(List<Folder> folders) {
    final rootFolders = folders.where((f) => f.parentId == null).toList();

    return DropdownButtonFormField<String?>(
      value: _selectedParentId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Kein (Root-Ordner)'),
        ),
        ...rootFolders.map((folder) => DropdownMenuItem(
              value: folder.id,
              child: Row(
                children: [
                  Icon(
                    getIconFromName(folder.icon),
                    size: 18,
                    color: Color(folder.color),
                  ),
                  const SizedBox(width: 8),
                  Text(folder.name),
                ],
              ),
            )),
      ],
      onChanged: (value) => setState(() => _selectedParentId = value),
    );
  }

  void _createFolder() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }

    final now = DateTime.now();
    ref.read(foldersDaoProvider).createFolder(
          FoldersCompanion.insert(
            id: const Uuid().v4(),
            name: name,
            color: _selectedColor.toARGB32(),
            icon: Value(getIconName(_selectedIcon)),
            parentId: Value(_selectedParentId),
            createdAt: now,
            updatedAt: now,
          ),
        );

    Navigator.pop(context);
  }
}

/// Dialog zum Bearbeiten eines Ordners
class EditFolderDialog extends ConsumerStatefulWidget {
  final Folder folder;

  const EditFolderDialog({super.key, required this.folder});

  @override
  ConsumerState<EditFolderDialog> createState() => _EditFolderDialogState();
}

class _EditFolderDialogState extends ConsumerState<EditFolderDialog> {
  late final TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
    _selectedColor = Color(widget.folder.color);
    _selectedIcon = getIconFromName(widget.folder.icon);
    _selectedParentId = widget.folder.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);

    return AlertDialog(
      title: const Text('Ordner bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ordnername',
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
            const SizedBox(height: 24),

            // Icon
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildIconPicker(),
            const SizedBox(height: 24),

            // Parent Folder
            Text(
              'Übergeordneter Ordner',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            foldersAsync.when(
              data: (folders) => _buildParentDropdown(folders),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Fehler beim Laden'),
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
          onPressed: _updateFolder,
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
        ...folderColors.map((color) => _ColorChip(
              color: color,
              isSelected: _selectedColor == color,
              onTap: () => setState(() => _selectedColor = color),
            )),
        _ColorChip(
          color: _selectedColor,
          isSelected: !folderColors.contains(_selectedColor),
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

  Widget _buildIconPicker() {
    return SizedBox(
      height: 160,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: folderIcons.length,
        itemBuilder: (context, index) {
          final icon = folderIcons[index];
          final isSelected = _selectedIcon == icon;
          return InkWell(
            onTap: () => setState(() => _selectedIcon = icon),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentDropdown(List<Folder> folders) {
    // Exclude this folder and its descendants from parent options
    final validParents = folders
        .where((f) => f.parentId == null && f.id != widget.folder.id)
        .toList();

    return DropdownButtonFormField<String?>(
      value: _selectedParentId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Kein (Root-Ordner)'),
        ),
        ...validParents.map((folder) => DropdownMenuItem(
              value: folder.id,
              child: Row(
                children: [
                  Icon(
                    getIconFromName(folder.icon),
                    size: 18,
                    color: Color(folder.color),
                  ),
                  const SizedBox(width: 8),
                  Text(folder.name),
                ],
              ),
            )),
      ],
      onChanged: (value) => setState(() => _selectedParentId = value),
    );
  }

  void _updateFolder() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }

    ref.read(foldersDaoProvider).updateFolder(
          widget.folder.copyWith(
            name: name,
            color: _selectedColor.toARGB32(),
            icon: getIconName(_selectedIcon),
            parentId: Value(_selectedParentId),
            updatedAt: DateTime.now(),
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
