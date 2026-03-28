# Notizen

Eine plattformübergreifende Notiz-App mit Flutter und Material Design 3.

## Features

- **Verschiedene Notiztypen**
  - Text mit Markdown-Unterstützung
  - Sprachnotizen
  - Bildnotizen
  - Zeichnungen

- **Organisation**
  - Verschachtelte Ordnerstruktur
  - Tags für flexible Kategorisierung
  - Volltextsuche
  - Papierkorb & Archiv (mit "Papierkorb leeren" Funktion)

- **Design**
  - Material Design 3 (Material You)
  - Dynamic Color Support
  - System-Theme mit individueller Anpassung
  - Dark Mode

- **Plattformen**
  - Android (mit Home-Widgets)
  - iOS
  - Windows
  - Linux
  - Web

- **Sync (geplant)**
  - Google Drive
  - Nextcloud
  - NAS / eigener Server

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Datenbank:** Drift (SQLite)
- **Design:** Material Design 3

## Installation

```bash
# Repository klonen
git clone https://github.com/KayBeckmann/Notizen.git
cd Notizen

# Abhängigkeiten installieren
flutter pub get

# App starten
flutter run
```

## Entwicklung

```bash
# Code-Generierung (Drift, Riverpod)
dart run build_runner build

# Tests ausführen
flutter test

# Build für Produktion
flutter build apk        # Android
flutter build ios        # iOS
flutter build windows    # Windows
flutter build linux      # Linux
flutter build web        # Web
```

## Projektstruktur

```
lib/
├── models/           # Datenmodelle
├── providers/        # Riverpod State Management
├── services/         # Datenbank, Storage, Sync
├── screens/          # Bildschirme/Seiten
├── widgets/          # Wiederverwendbare Widgets
└── main.dart
```

## Roadmap

- [x] Projektplanung
- [x] Grundstruktur & Setup
- [x] Datenmodelle & Datenbank
- [x] Basis-UI mit Material Design 3
- [x] Notiz-Editor mit Markdown
- [x] Sprachnotizen
- [x] Bildnotizen
- [x] Zeichenfunktion
- [ ] Android Widgets
- [ ] Multi-Plattform Testing
- [x] Cloud-Sync (Nextcloud & REST API implementiert, Google Drive geplant)

## Lizenz

MIT License

## Unterstützen

- BTC: `12QBn6eba71FtAUM4HFmSGgTY9iTPfRKLx`
- [Buy Me a Coffee](https://www.buymeacoffee.com/snuppedelua)
