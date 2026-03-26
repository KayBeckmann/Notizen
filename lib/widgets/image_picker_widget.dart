import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';

/// Widget für Bild-Auswahl (Kamera oder Galerie)
class ImagePickerWidget extends StatelessWidget {
  final Function(String path) onImageSelected;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.quality = 85,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bild hinzufügen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Kamera
              _ImageSourceButton(
                icon: Icons.camera_alt,
                label: 'Kamera',
                color: colorScheme.primary,
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              // Galerie
              _ImageSourceButton(
                icon: Icons.photo_library,
                label: 'Galerie',
                color: colorScheme.secondary,
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile == null) return;

      // Bildbytes statt dart:io File verwenden (Web-kompatibel)
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final savedPath = await StorageService.instance.saveImageBytes(
        bytes,
        extension: extension,
      );

      if (context.mounted) {
        Navigator.pop(context);
        onImageSelected(savedPath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Bildes: $e')),
        );
      }
    }
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zeigt den Bildauswahl-Dialog an
Future<String?> showImagePickerDialog(
  BuildContext context, {
  int maxWidth = 1920,
  int maxHeight = 1080,
  int quality = 85,
}) async {
  String? selectedPath;

  await showModalBottomSheet(
    context: context,
    builder: (context) => ImagePickerWidget(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
      onImageSelected: (path) {
        selectedPath = path;
      },
    ),
  );

  return selectedPath;
}
