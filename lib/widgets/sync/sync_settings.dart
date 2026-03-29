import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../providers/sync_provider.dart';
import '../../services/sync/rest_api_provider.dart';
import 'sync_log_dialog.dart';
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

          // Sync-Log anzeigen
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Sync-Log'),
            subtitle: const Text('Sync-Aktivitäten anzeigen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showSyncLogDialog(context),
          ),

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
class _RestApiConfigDialog extends ConsumerStatefulWidget {
  const _RestApiConfigDialog();

  @override
  ConsumerState<_RestApiConfigDialog> createState() => _RestApiConfigDialogState();
}

class _RestApiConfigDialogState extends ConsumerState<_RestApiConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _testing = false;
  bool _connecting = false;
  String? _testResult;
  bool _testSuccess = false;

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
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Server-URL',
                  hintText: 'https://api.example.com',
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
              const SizedBox(height: 8),

              // Register Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showRegisterDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Neuen Account erstellen'),
                ),
              ),

              // Test Result Display
              if (_testResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess ? Icons.check_circle : Icons.error,
                        color: _testSuccess ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        OutlinedButton(
          onPressed: _testing || _connecting ? null : _testConnection,
          child: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Testen'),
        ),
        FilledButton(
          onPressed: _testing || _connecting ? null : _connect,
          child: _connecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verbinden'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final provider = RestApiSyncProvider();
      provider.configure(
        serverUrl: _serverController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
      );

      final success = await provider.testConnection();

      setState(() {
        _testing = false;
        _testSuccess = success;
        _testResult = success
            ? 'Verbindung erfolgreich!'
            : 'Verbindung fehlgeschlagen. Bitte Server-URL und API-Key prüfen.';
      });
    } catch (e) {
      setState(() {
        _testing = false;
        _testSuccess = false;
        _testResult = 'Fehler: ${e.toString()}';
      });
    }
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _connecting = true);

    try {
      final provider = RestApiSyncProvider();
      provider.configure(
        serverUrl: _serverController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
      );

      final syncService = ref.read(syncServiceProvider);
      await syncService.setProvider(provider);
      final success = await syncService.connect();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Erfolgreich verbunden!'
                : 'Verbindung fehlgeschlagen'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RegisterDialog(
        serverUrl: _serverController.text.trim(),
        onRegistered: (apiKey) {
          setState(() {
            _apiKeyController.text = apiKey;
            _testResult = null;
          });
        },
      ),
    );
  }
}

/// Dialog für User-Registrierung
class _RegisterDialog extends StatefulWidget {
  final String serverUrl;
  final void Function(String apiKey) onRegistered;

  const _RegisterDialog({
    required this.serverUrl,
    required this.onRegistered,
  });

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _registering = false;
  String? _resultApiKey;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If registration was successful, show the API key
    if (_resultApiKey != null) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Registrierung erfolgreich!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dein API-Key wurde erstellt. Speichere ihn gut, '
              'er wird nur einmal angezeigt!',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _resultApiKey!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopieren',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _resultApiKey!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API-Key in Zwischenablage kopiert!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          FilledButton.icon(
            onPressed: () {
              widget.onRegistered(_resultApiKey!);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('API-Key verwenden'),
          ),
        ],
      );
    }

    // Registration form
    return AlertDialog(
      title: const Text('Neuen Account erstellen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.serverUrl.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bitte zuerst eine Server-URL eingeben',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Benutzername',
                prefixIcon: Icon(Icons.person),
                hintText: 'z.B. max_mustermann',
              ),
              enabled: widget.serverUrl.isNotEmpty,
              autofocus: widget.serverUrl.isNotEmpty,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Benutzername erforderlich';
                }
                if (value.trim().length < 3) {
                  return 'Mindestens 3 Zeichen';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _registering || widget.serverUrl.isEmpty ? null : _register,
          child: _registering
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrieren'),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _registering = true;
      _errorMessage = null;
    });

    try {
      final serverUrl = widget.serverUrl.endsWith('/')
          ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
          : widget.serverUrl;

      final response = await http
          .post(
            Uri.parse('$serverUrl/api/v1/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': _usernameController.text.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _registering = false;
          _resultApiKey = data['api_key'] as String;
        });
      } else {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _registering = false;
          _errorMessage = data['error'] as String? ?? 'Registrierung fehlgeschlagen';
        });
      }
    } catch (e) {
      setState(() {
        _registering = false;
        _errorMessage = 'Verbindungsfehler: Server nicht erreichbar';
      });
    }
  }
}
