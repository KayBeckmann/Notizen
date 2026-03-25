import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sync_provider.dart';
import 'sync_status_indicator.dart';

/// Sync-Einstellungen für den Settings-Screen
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final isConnected = ref.watch(syncConnectedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Synchronisation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),

        // Status-Karte
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SyncStatusCard(),
        ),

        const SizedBox(height: 8),

        // Einstellungen (nur wenn verbunden)
        if (isConnected) ...[
          // Auto-Sync
          SwitchListTile(
            title: const Text('Automatische Synchronisation'),
            subtitle: Text(
              syncService.autoSyncEnabled
                  ? 'Alle ${syncService.autoSyncIntervalMinutes} Minuten'
                  : 'Deaktiviert',
            ),
            value: syncService.autoSyncEnabled,
            onChanged: (value) => syncService.setAutoSyncEnabled(value),
          ),

          // Auto-Sync Intervall
          if (syncService.autoSyncEnabled)
            ListTile(
              title: const Text('Sync-Intervall'),
              subtitle: Text('Alle ${syncService.autoSyncIntervalMinutes} Minuten'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showIntervalPicker(context, syncService),
            ),

          // Nur über WLAN
          SwitchListTile(
            title: const Text('Nur über WLAN synchronisieren'),
            subtitle: const Text('Spart mobile Daten'),
            value: syncService.syncOnlyOnWifi,
            onChanged: (value) => syncService.setSyncOnlyOnWifi(value),
          ),

          const Divider(),

          // Verbindung trennen
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Verbindung trennen'),
            onTap: () => _confirmDisconnect(context, ref),
          ),
        ],

        // Provider-Auswahl (wenn nicht verbunden)
        if (!isConnected) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_to_drive),
            title: const Text('Google Drive'),
            subtitle: const Text('Mit Google-Konto verbinden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connectGoogleDrive(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Nextcloud / WebDAV'),
            subtitle: const Text('Eigenen Server verwenden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connectWebDAV(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Eigener Server (REST API)'),
            subtitle: const Text('Mit REST-API verbinden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connectRestApi(context, ref),
          ),
        ],
      ],
    );
  }

  void _showIntervalPicker(BuildContext context, dynamic syncService) {
    final intervals = [5, 10, 15, 30, 60];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sync-Intervall'),
        children: intervals.map((minutes) {
          return RadioListTile<int>(
            title: Text('$minutes Minuten'),
            value: minutes,
            groupValue: syncService.autoSyncIntervalMinutes,
            onChanged: (value) {
              if (value != null) {
                syncService.setAutoSyncInterval(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verbindung trennen?'),
        content: const Text(
          'Die Synchronisation wird deaktiviert. '
          'Lokale Daten bleiben erhalten, aber Änderungen werden nicht mehr synchronisiert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(syncServiceProvider).disconnect();
              Navigator.pop(context);
            },
            child: const Text('Trennen'),
          ),
        ],
      ),
    );
  }

  void _connectGoogleDrive(BuildContext context, WidgetRef ref) {
    // TODO: Google Drive Implementierung
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Drive Integration wird noch entwickelt'),
      ),
    );
  }

  void _connectWebDAV(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _WebDAVConfigDialog(),
    );
  }

  void _connectRestApi(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _RestApiConfigDialog(),
    );
  }
}

/// Dialog für WebDAV/Nextcloud Konfiguration
class _WebDAVConfigDialog extends StatefulWidget {
  const _WebDAVConfigDialog();

  @override
  State<_WebDAVConfigDialog> createState() => _WebDAVConfigDialogState();
}

class _WebDAVConfigDialogState extends State<_WebDAVConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _testing = false;

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nextcloud / WebDAV'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server-URL',
                hintText: 'https://cloud.example.com/remote.php/dav',
                prefixIcon: Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Server-URL erforderlich';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL muss mit http:// oder https:// beginnen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Benutzername',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Benutzername erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Passwort / App-Token',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Passwort erforderlich';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        OutlinedButton(
          onPressed: _testing ? null : _testConnection,
          child: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Testen'),
        ),
        FilledButton(
          onPressed: _testing ? null : _connect,
          child: const Text('Verbinden'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _testing = true);

    // TODO: WebDAV-Verbindung testen
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _testing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WebDAV Integration wird noch entwickelt'),
        ),
      );
    }
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: WebDAV-Verbindung herstellen
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WebDAV Integration wird noch entwickelt'),
      ),
    );
  }
}

/// Dialog für REST API Konfiguration
class _RestApiConfigDialog extends StatefulWidget {
  const _RestApiConfigDialog();

  @override
  State<_RestApiConfigDialog> createState() => _RestApiConfigDialogState();
}

class _RestApiConfigDialogState extends State<_RestApiConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _testing = false;

  @override
  void dispose() {
    _serverController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('REST API Server'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server-URL',
                hintText: 'https://api.example.com/v1',
                prefixIcon: Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Server-URL erforderlich';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL muss mit http:// oder https:// beginnen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API-Key',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
              obscureText: _obscureApiKey,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'API-Key erforderlich';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        OutlinedButton(
          onPressed: _testing ? null : _testConnection,
          child: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Testen'),
        ),
        FilledButton(
          onPressed: _testing ? null : _connect,
          child: const Text('Verbinden'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _testing = true);

    // TODO: REST API-Verbindung testen
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _testing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('REST API Integration wird noch entwickelt'),
        ),
      );
    }
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: REST API-Verbindung herstellen
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('REST API Integration wird noch entwickelt'),
      ),
    );
  }
}
