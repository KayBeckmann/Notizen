import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';

/// Banner das angezeigt wird, wenn die App offline ist
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return MaterialBanner(
      content: const Row(
        children: [
          Icon(Icons.cloud_off, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keine Internetverbindung. Änderungen werden lokal gespeichert.',
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      contentTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Connectivity manuell prüfen
            ref.read(connectivityServiceProvider).setOnline(true);
          },
          child: const Text('Erneut versuchen'),
        ),
      ],
    );
  }
}

/// Wrapper der Offline-Banner mit Child kombiniert
class OfflineAwareScaffold extends ConsumerWidget {
  final Widget child;

  const OfflineAwareScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        if (!isOnline)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline - Änderungen werden lokal gespeichert',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

/// Kleiner Offline-Indikator für die AppBar
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 14,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
