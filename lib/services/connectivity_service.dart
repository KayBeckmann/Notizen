import 'dart:async';

import 'package:flutter/foundation.dart';

/// Service zur Überwachung der Netzwerkverbindung
class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  Timer? _checkTimer;

  ConnectivityService() {
    // Starte regelmäßige Prüfung
    _startConnectivityCheck();
  }

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  void _startConnectivityCheck() {
    // Prüfe alle 30 Sekunden
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
    // Initiale Prüfung
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    // Auf Web ist navigator.onLine verfügbar
    // Auf anderen Plattformen nehmen wir an, dass wir online sind
    // (Eine echte Implementierung würde connectivity_plus verwenden)
    if (kIsWeb) {
      _setOnline(true); // Web-Implementierung würde JS-Interop nutzen
    } else {
      // Auf nativen Plattformen: immer online annehmen
      // (Erweiterung mit connectivity_plus möglich)
      _setOnline(true);
    }
  }

  void _setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  /// Manuelle Aktualisierung des Verbindungsstatus
  void setOnline(bool online) {
    _setOnline(online);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
