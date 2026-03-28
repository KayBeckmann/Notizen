import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sync_provider.dart';
import '../../services/sync/sync_service.dart';

/// Dialog zum Anzeigen des Sync-Logs
class SyncLogDialog extends ConsumerWidget {
  const SyncLogDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final log = syncService.syncLog;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Sync-Log'),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: log.isEmpty
                ? null
                : () {
                    syncService.clearLog();
                  },
            tooltip: 'Log leeren',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: log.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Log-Einträge',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: log.length,
                itemBuilder: (context, index) {
                  final entry = log[index];
                  return _LogEntryTile(entry: entry);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final SyncLogEntry entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _getIcon(),
        color: _getColor(context),
        size: 20,
      ),
      title: Text(
        entry.message,
        style: TextStyle(
          color: entry.level == SyncLogLevel.error
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(entry.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (entry.details != null)
            Text(
              entry.details!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      dense: true,
    );
  }

  IconData _getIcon() {
    switch (entry.level) {
      case SyncLogLevel.info:
        return Icons.info_outline;
      case SyncLogLevel.success:
        return Icons.check_circle_outline;
      case SyncLogLevel.warning:
        return Icons.warning_amber;
      case SyncLogLevel.error:
        return Icons.error_outline;
    }
  }

  Color _getColor(BuildContext context) {
    switch (entry.level) {
      case SyncLogLevel.info:
        return Theme.of(context).colorScheme.primary;
      case SyncLogLevel.success:
        return Colors.green;
      case SyncLogLevel.warning:
        return Colors.orange;
      case SyncLogLevel.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

/// Zeigt den Sync-Log-Dialog an
void showSyncLogDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const SyncLogDialog(),
  );
}
