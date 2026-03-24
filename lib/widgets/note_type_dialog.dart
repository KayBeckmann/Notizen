import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Dialog zur Auswahl des Notiz-Typs
class NoteTypeDialog extends StatelessWidget {
  const NoteTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neue Notiz erstellen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _NoteTypeCard(
                  type: ContentType.text,
                  icon: Icons.text_fields,
                  label: 'Text',
                  description: 'Markdown-Notiz',
                  color: colorScheme.primary,
                  onTap: () => Navigator.pop(context, ContentType.text),
                ),
                _NoteTypeCard(
                  type: ContentType.audio,
                  icon: Icons.mic,
                  label: 'Sprache',
                  description: 'Audio-Aufnahme',
                  color: colorScheme.error,
                  onTap: () => Navigator.pop(context, ContentType.audio),
                ),
                _NoteTypeCard(
                  type: ContentType.image,
                  icon: Icons.image,
                  label: 'Bild',
                  description: 'Kamera / Galerie',
                  color: colorScheme.tertiary,
                  onTap: () => Navigator.pop(context, ContentType.image),
                ),
                _NoteTypeCard(
                  type: ContentType.drawing,
                  icon: Icons.brush,
                  label: 'Zeichnung',
                  description: 'Freihand zeichnen',
                  color: colorScheme.secondary,
                  onTap: () => Navigator.pop(context, ContentType.drawing),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTypeCard extends StatelessWidget {
  final ContentType type;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _NoteTypeCard({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zeigt den Notiz-Typ-Dialog an
Future<ContentType?> showNoteTypeDialog(BuildContext context) {
  return showDialog<ContentType>(
    context: context,
    builder: (context) => const NoteTypeDialog(),
  );
}

/// Speed-Dial FAB für schnellen Zugriff auf Notiz-Typen
class NoteTypeFAB extends StatefulWidget {
  final Function(ContentType type) onTypeSelected;
  final bool isExpanded;

  const NoteTypeFAB({
    super.key,
    required this.onTypeSelected,
    this.isExpanded = false,
  });

  @override
  State<NoteTypeFAB> createState() => _NoteTypeFABState();
}

class _NoteTypeFABState extends State<NoteTypeFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _selectType(ContentType type) {
    _toggle();
    widget.onTypeSelected(type);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini-FABs
        ScaleTransition(
          scale: _animation,
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniFAB(
                icon: Icons.brush,
                label: 'Zeichnung',
                color: colorScheme.secondary,
                onTap: () => _selectType(ContentType.drawing),
              ),
              const SizedBox(height: 12),
              _MiniFAB(
                icon: Icons.image,
                label: 'Bild',
                color: colorScheme.tertiary,
                onTap: () => _selectType(ContentType.image),
              ),
              const SizedBox(height: 12),
              _MiniFAB(
                icon: Icons.mic,
                label: 'Sprache',
                color: colorScheme.error,
                onTap: () => _selectType(ContentType.audio),
              ),
              const SizedBox(height: 12),
              _MiniFAB(
                icon: Icons.text_fields,
                label: 'Text',
                color: colorScheme.primary,
                onTap: () => _selectType(ContentType.text),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Haupt-FAB
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(_isOpen ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}

class _MiniFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniFAB({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fab_$label',
          backgroundColor: color,
          foregroundColor: Colors.white,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}
