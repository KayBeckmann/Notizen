import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

/// Vollbild-Bildanzeige mit Zoom
class ImageViewer extends StatelessWidget {
  final String imagePath;
  final String? title;
  final VoidCallback? onDelete;

  const ImageViewer({
    super.key,
    required this.imagePath,
    this.title,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        title: title != null ? Text(title!) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
            tooltip: 'Teilen',
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
              tooltip: 'Löschen',
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event?.expectedTotalBytes != null
                ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                : null,
            color: colorScheme.primary,
          ),
        ),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                'Bild konnte nicht geladen werden',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white54,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(imagePath)]),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Teilen: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bild löschen?'),
        content: const Text('Das Bild wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
              Navigator.pop(context);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

/// Bild-Vorschau für Notiz-Cards
class ImagePreview extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ImagePreview({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewer(imagePath: imagePath),
                ),
              ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Galerie-Widget für mehrere Bilder
class ImageGallery extends StatelessWidget {
  final List<String> imagePaths;
  final int crossAxisCount;
  final double spacing;
  final double aspectRatio;
  final Function(int index)? onImageTap;
  final Function(int index)? onImageDelete;

  const ImageGallery({
    super.key,
    required this.imagePaths,
    this.crossAxisCount = 3,
    this.spacing = 8,
    this.aspectRatio = 1,
    this.onImageTap,
    this.onImageDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: imagePaths.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ImagePreview(
              imagePath: imagePaths[index],
              onTap: () => onImageTap?.call(index),
            ),
            if (onImageDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(24, 24),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => onImageDelete!(index),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Hero-Animation Bildanzeige
class HeroImageViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;
  final String? title;

  const HeroImageViewer({
    super.key,
    required this.imagePath,
    required this.heroTag,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title != null ? Text(title!) : null,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Hero(
          tag: heroTag,
          child: PhotoView(
            imageProvider: FileImage(File(imagePath)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
