# Notiz-App - Projektplan

## Phase 1: Projektsetup & Grundstruktur

- [ ] Flutter-Projekt initialisieren
- [ ] Ordnerstruktur anlegen (lib/models, lib/screens, lib/widgets, lib/services)
- [ ] Abhängigkeiten definieren (pubspec.yaml)
  - [ ] sqflite / drift (lokale Datenbank)
  - [ ] path_provider (Dateispeicherung)
  - [ ] provider / riverpod (State Management)
  - [ ] uuid (eindeutige IDs)
  - [ ] dynamic_color (Material You / Dynamic Color Support)
  - [ ] google_fonts (M3 Typography)

## Phase 2: Datenmodelle

- [ ] Notiz-Model erstellen
  - [ ] ID, Titel, Erstellungsdatum, Änderungsdatum
  - [ ] Ordner-Referenz
  - [ ] Tags-Liste
  - [ ] Inhaltstyp (Text/Audio/Bild/Zeichnung)
- [ ] Ordner-Model erstellen
  - [ ] ID, Name, Farbe, Icon
  - [ ] "Neu"-Ordner als Standard
- [ ] Tag-Model erstellen
  - [ ] ID, Name, Farbe

## Phase 3: Lokale Datenspeicherung

- [ ] Datenbank-Service implementieren
- [ ] CRUD-Operationen für Notizen
- [ ] CRUD-Operationen für Ordner
- [ ] CRUD-Operationen für Tags
- [ ] Mediendateien im lokalen Speicher verwalten
  - [ ] Bilder speichern/laden
  - [ ] Audiodateien speichern/laden
  - [ ] Zeichnungen serialisieren/deserialisieren

## Phase 4: Basis-UI

### Design-System
- [ ] Material Design 3 (M3) implementieren
  - [ ] Dynamic Color / Material You unterstützen
  - [ ] M3 Theme konfigurieren (ColorScheme.fromSeed)
  - [ ] M3 Komponenten verwenden (FilledButton, NavigationBar, SearchBar, etc.)
  - [ ] Typography mit M3 TextTheme
- [ ] Design-Skills verwenden (https://github.com/anthropics/skills)
  - [ ] Creative & Design Skills für UI/UX-Konzepte
  - [ ] Document Skills für Export-Layouts (PDF, DOCX)

### UI-Komponenten
- [ ] Hauptbildschirm mit Notizliste
- [ ] Ordner-Seitenleiste / Navigation (NavigationDrawer M3)
- [ ] Notiz-Editor (Basisversion mit Text)
- [ ] Ordner erstellen/bearbeiten Dialog (M3 AlertDialog)
- [ ] Tag-Verwaltung (M3 Chips)

## Phase 5: Erweiterte Notiz-Inhalte

### Text-Editor
- [ ] Rich-Text-Unterstützung (optional)
- [ ] Formatierungsoptionen

### Sprachnotizen
- [ ] Audio-Aufnahme implementieren (record package)
- [ ] Audio-Wiedergabe
- [ ] Aufnahme-UI mit Wellenform

### Bildnotizen
- [ ] Kamera-Integration
- [ ] Galerie-Auswahl
- [ ] Bildvorschau und -verwaltung

### Zeichenfunktion
- [ ] Canvas für freies Zeichnen
- [ ] Stiftauswahl (Dicke, Stil)
- [ ] Farbpalette
- [ ] Formen-Werkzeuge (Linie, Rechteck, Kreis, Pfeil)
- [ ] Radierer
- [ ] Rückgängig/Wiederholen

## Phase 6: Android Widgets

- [ ] home_widget Package integrieren
- [ ] Kleines Widget (einzelne Notiz-Vorschau)
- [ ] Mittleres Widget (Notizliste)
- [ ] Schnellnotiz-Widget (direkte Eingabe)
- [ ] Widget-Konfiguration

## Phase 7: Zusatzfunktionen

- [ ] Suche (Volltext, Tags, Ordner)
- [ ] Sortierung und Filterung
- [ ] Notiz-Export (PDF, Text)
- [ ] Papierkorb / Archiv
- [ ] Dark Mode / Themes

## Phase 8: Backend-Vorbereitung (später)

- [ ] Sync-Interface definieren
- [ ] Backend-Konfiguration UI
- [ ] Konfliktbehandlung planen
- [ ] Offline-First Architektur sicherstellen

---

## Technische Notizen

### Empfohlene Packages
```yaml
dependencies:
  # Datenbank & Speicherung
  sqflite: ^2.3.0
  path_provider: ^2.1.0

  # State Management
  provider: ^6.1.0

  # Utilities
  uuid: ^4.2.0

  # Media
  record: ^5.0.0
  audioplayers: ^5.2.0
  image_picker: ^1.0.0

  # Widgets
  home_widget: ^0.4.0
  flutter_colorpicker: ^1.0.0

  # Material Design 3
  dynamic_color: ^1.7.0      # Material You / Dynamic Color
  google_fonts: ^6.1.0       # M3 Typography
```

### Material Design 3 Setup
```dart
// main.dart - M3 Theme Konfiguration
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
);
```

### Design-Ressourcen
- Anthropic Skills: https://github.com/anthropics/skills
  - Creative & Design Skills für UI/UX-Konzepte
  - Document Skills für Export-Layouts

### Ordnerstruktur
```
lib/
├── models/
│   ├── note.dart
│   ├── folder.dart
│   └── tag.dart
├── services/
│   ├── database_service.dart
│   ├── storage_service.dart
│   └── sync_service.dart (später)
├── screens/
│   ├── home_screen.dart
│   ├── note_editor_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── note_card.dart
│   ├── folder_list.dart
│   ├── drawing_canvas.dart
│   └── audio_recorder.dart
└── main.dart
```
