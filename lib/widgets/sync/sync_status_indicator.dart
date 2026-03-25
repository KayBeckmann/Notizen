import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/sync_provider.dart';
import '../../services/sync/sync_provider.dart';

/// Kleines Icon das den Sync-Status anzeigt (für AppBar)
class SyncStatusIcon extends ConsumerWidget {
  final VoidCallback? onTap;

  const SyncStatusIcon({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final isConnected = ref.watch(syncConnectedProvider);
    final pendingCount = ref.watch(pendingChangesCountProvider);

    if (!isConnected) {
      return IconButton(
        icon: const Icon(Icons.cloud_off),
        onPressed: onTap,
        tooltip: 'Nicht verbunden',
      );
    }

    Widget icon;
    String tooltip;

    switch (status) {
      case SyncStatus.syncing:
        icon = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        tooltip = 'Synchronisiere...';
        break;
      case SyncStatus.error:
        icon = const Icon(Icons.cloud_off, color: Colors.red);
        tooltip = 'Sync-Fehler';
        break;
      case SyncStatus.conflict:
        icon = Badge(
          label: const Text('!'),
          backgroundColor: Colors.orange,
          child: const Icon(Icons.cloud_sync),
        );
        tooltip = 'Konflikte vorhanden';
        break;
      default:
        if (pendingCount > 0) {
          icon = Badge(
            label: Text(pendingCount.toString()),
            child: const Icon(Icons.cloud_upload_outlined),
          );
          tooltip = '$pendingCount Änderungen ausstehend';
        } else {
          icon = const Icon(Icons.cloud_done);
          tooltip = 'Synchronisiert';
        }
    }

    return IconButton(
      icon: icon,
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}

/// Detaillierte Sync-Status Anzeige (für Drawer oder Settings)
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final status = ref.watch(syncStatusProvider);
    final isConnected = ref.watch(syncConnectedProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final pendingCount = ref.watch(pendingChangesCountProvider);

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildStatusIcon(status, isConnected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(status, isConnected),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (syncService.provider != null)
                        Text(
                          syncService.provider!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isConnected && status != SyncStatus.syncing)
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () => syncService.sync(),
                    tooltip: 'Jetzt synchronisieren',
                  ),
              ],
            ),

            if (isConnected) ...[
              const Divider(height: 24),

              // Letzte Synchronisation
              if (lastSync != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Letzte Sync: ${_formatLastSync(lastSync)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Ausstehende Änderungen
              if (pendingCount > 0) ...[
                Row(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount Änderungen ausstehend',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Fehler
              if (status == SyncStatus.error &&
                  syncService.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncService.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Verbinden Button
            if (!isConnected) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: Provider-Auswahl Dialog öffnen
                  },
                  icon: const Icon(Icons.cloud),
                  label: const Text('Mit Cloud verbinden'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status, bool isConnected) {
    if (!isConnected) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.cloud_off, color: Colors.grey),
      );
    }

    IconData icon;
    Color color;

    switch (status) {
      case SyncStatus.syncing:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = Colors.red;
        break;
      case SyncStatus.conflict:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.cloud_done;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  String _getStatusText(SyncStatus status, bool isConnected) {
    if (!isConnected) return 'Nicht verbunden';

    switch (status) {
      case SyncStatus.syncing:
        return 'Synchronisiere...';
      case SyncStatus.error:
        return 'Sync fehlgeschlagen';
      case SyncStatus.conflict:
        return 'Konflikte vorhanden';
      case SyncStatus.success:
      case SyncStatus.idle:
        return 'Synchronisiert';
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min.';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours} Std.';
    } else {
      return DateFormat('dd.MM. HH:mm').format(lastSync);
    }
  }
}
