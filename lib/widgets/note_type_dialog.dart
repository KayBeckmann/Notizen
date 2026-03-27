import 'package:flutter/material.dart';
import '../models/enums.dart';

class NoteTypeDialog extends StatelessWidget {
  const NoteTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Notiz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Textnotiz'),
            onTap: () => Navigator.pop(context, ContentType.text),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Audionotiz'),
            onTap: () => Navigator.pop(context, ContentType.audio),
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Bildnotiz'),
            onTap: () => Navigator.pop(context, ContentType.image),
          ),
          ListTile(
            leading: const Icon(Icons.brush),
            title: const Text('Zeichnung'),
            onTap: () => Navigator.pop(context, ContentType.drawing),
          ),
        ],
      ),
    );
  }
}
