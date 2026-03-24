import 'package:flutter/material.dart';

/// Kontextmenü-Eintrag
class ContextMenuItem {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDivider;
  final bool isDestructive;

  const ContextMenuItem({
    this.icon,
    required this.label,
    this.onTap,
    this.isDivider = false,
    this.isDestructive = false,
  });

  const ContextMenuItem.divider()
      : icon = null,
        label = '',
        onTap = null,
        isDivider = true,
        isDestructive = false;
}

/// Kontextmenü für Rechtsklick
class ContextMenuRegion extends StatelessWidget {
  final Widget child;
  final List<ContextMenuItem> items;

  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colorScheme = Theme.of(context).colorScheme;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items.map((item) {
        if (item.isDivider) {
          return const PopupMenuDivider() as PopupMenuEntry<void>;
        }

        return PopupMenuItem<void>(
          onTap: item.onTap,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 20,
                  color: item.isDestructive
                      ? colorScheme.error
                      : colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                item.label,
                style: TextStyle(
                  color: item.isDestructive ? colorScheme.error : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Kontextmenü für Notizen
List<ContextMenuItem> buildNoteContextMenu({
  required VoidCallback onOpen,
  required VoidCallback onEdit,
  required VoidCallback onPin,
  required VoidCallback onMove,
  required VoidCallback onDelete,
  required bool isPinned,
}) {
  return [
    ContextMenuItem(
      icon: Icons.open_in_new,
      label: 'Öffnen',
      onTap: onOpen,
    ),
    ContextMenuItem(
      icon: Icons.edit,
      label: 'Bearbeiten',
      onTap: onEdit,
    ),
    const ContextMenuItem.divider(),
    ContextMenuItem(
      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
      label: isPinned ? 'Nicht mehr anpinnen' : 'Anpinnen',
      onTap: onPin,
    ),
    ContextMenuItem(
      icon: Icons.drive_file_move_outlined,
      label: 'Verschieben',
      onTap: onMove,
    ),
    const ContextMenuItem.divider(),
    ContextMenuItem(
      icon: Icons.delete_outline,
      label: 'Löschen',
      onTap: onDelete,
      isDestructive: true,
    ),
  ];
}

/// Kontextmenü für Ordner
List<ContextMenuItem> buildFolderContextMenu({
  required VoidCallback onOpen,
  required VoidCallback onRename,
  required VoidCallback onChangeColor,
  required VoidCallback onChangeIcon,
  required VoidCallback onAddSubfolder,
  required VoidCallback onDelete,
  bool canDelete = true,
}) {
  return [
    ContextMenuItem(
      icon: Icons.folder_open,
      label: 'Öffnen',
      onTap: onOpen,
    ),
    const ContextMenuItem.divider(),
    ContextMenuItem(
      icon: Icons.edit,
      label: 'Umbenennen',
      onTap: onRename,
    ),
    ContextMenuItem(
      icon: Icons.palette_outlined,
      label: 'Farbe ändern',
      onTap: onChangeColor,
    ),
    ContextMenuItem(
      icon: Icons.emoji_symbols,
      label: 'Icon ändern',
      onTap: onChangeIcon,
    ),
    const ContextMenuItem.divider(),
    ContextMenuItem(
      icon: Icons.create_new_folder_outlined,
      label: 'Unterordner erstellen',
      onTap: onAddSubfolder,
    ),
    if (canDelete) ...[
      const ContextMenuItem.divider(),
      ContextMenuItem(
        icon: Icons.delete_outline,
        label: 'Löschen',
        onTap: onDelete,
        isDestructive: true,
      ),
    ],
  ];
}

/// Kontextmenü für Tags
List<ContextMenuItem> buildTagContextMenu({
  required VoidCallback onFilter,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return [
    ContextMenuItem(
      icon: Icons.filter_list,
      label: 'Nach Tag filtern',
      onTap: onFilter,
    ),
    ContextMenuItem(
      icon: Icons.edit,
      label: 'Bearbeiten',
      onTap: onEdit,
    ),
    const ContextMenuItem.divider(),
    ContextMenuItem(
      icon: Icons.delete_outline,
      label: 'Löschen',
      onTap: onDelete,
      isDestructive: true,
    ),
  ];
}
