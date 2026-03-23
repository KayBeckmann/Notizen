# Notiz-App - Projektplan

## Geklärte Entscheidungen

| Thema | Entscheidung |
|-------|--------------|
| **State Management** | Riverpod (bessere Testbarkeit, kein BuildContext nötig, Multi-Plattform) |
| **Datenbank** | Drift (typsicher, reactive Streams, Web/Desktop Support) |
| **Text-Editor** | Markdown von Anfang an |
| **Theme** | System-Theme als Standard, User kann anpassen |
| **Plattformen** | Android, iOS, Windows, Linux, Web |
| **Ordner** | Verschachtelbar, Notiz nur in einem Ordner |
| **Backend (später)** | Google Drive / Nextcloud / NAS / eigener Server |

---

## Phase 1: Projektsetup & Grundstruktur

- [ ] Flutter-Projekt initialisieren (Multi-Plattform)
- [ ] Ordnerstruktur anlegen (lib/models, lib/providers, lib/screens, lib/widgets, lib/services)
- [ ] Abhängigkeiten definieren (pubspec.yaml)
  - [ ] drift + drift_dev (typsichere Datenbank)
  - [ ] path_provider (Dateispeicherung)
  - [ ] flutter_riverpod (State Management)
  - [ ] riverpod_annotation + riverpod_generator (Code-Generierung)
  - [ ] uuid (eindeutige IDs)
  - [ ] dynamic_color (Material You / Dynamic Color Support)
  - [ ] google_fonts (M3 Typography)
  - [ ] build_runner (Code-Generierung)

## Phase 2: Datenmodelle

- [ ] Notiz-Model erstellen (Drift Table)
  - [ ] ID, Titel, Erstellungsdatum, Änderungsdatum
  - [ ] Ordner-Referenz (Foreign Key)
  - [ ] Markdown-Inhalt
  - [ ] Inhaltstyp (Text/Audio/Bild/Zeichnung)
- [ ] Ordner-Model erstellen (Drift Table)
  - [ ] ID, Name, Farbe, Icon
  - [ ] Parent-ID für Verschachtelung (nullable, selbstreferenzierend)
  - [ ] "Neu"-Ordner als Standard
- [ ] Tag-Model erstellen (Drift Table)
  - [ ] ID, Name, Farbe
- [ ] Notiz-Tag Verknüpfungstabelle (Many-to-Many)

## Phase 3: Lokale Datenspeicherung

- [ ] Drift Database-Klasse implementieren
- [ ] DAOs (Data Access Objects) erstellen
  - [ ] NotesDao mit reactive Streams
  - [ ] FoldersDao mit Hierarchie-Abfragen
  - [ ] TagsDao
- [ ] Mediendateien im lokalen Speicher verwalten
  - [ ] Bilder speichern/laden
  - [ ] Audiodateien speichern/laden
  - [ ] Zeichnungen serialisieren/deserialisieren
- [ ] Riverpod Provider für Datenbank-Zugriff

## Phase 4: Basis-UI

### Design-System
- [ ] Material Design 3 (M3) implementieren
  - [ ] Dynamic Color / Material You unterstützen
  - [ ] M3 Theme konfigurieren (ColorScheme.fromSeed)
  - [ ] M3 Komponenten verwenden (FilledButton, NavigationBar, SearchBar, etc.)
  - [ ] Typography mit M3 TextTheme
- [ ] Theme-Einstellungen
  - [ ] System-Theme als Standard
  - [ ] Manuelle Theme-Auswahl (Hell/Dunkel/System)
  - [ ] Benutzerdefinierte Akzentfarbe
- [ ] Design-Skills verwenden (https://github.com/anthropics/skills)
  - [ ] Creative & Design Skills für UI/UX-Konzepte
  - [ ] Document Skills für Export-Layouts (PDF, DOCX)

### UI-Komponenten
- [ ] Hauptbildschirm mit Notizliste
- [ ] Ordner-Seitenleiste / Navigation (NavigationDrawer M3)
- [ ] Notiz-Editor (Basisversion mit Markdown)
- [ ] Ordner erstellen/bearbeiten Dialog (M3 AlertDialog)
- [ ] Tag-Verwaltung (M3 Chips)
- [ ] Einstellungen-Screen

## Phase 5: Erweiterte Notiz-Inhalte

### Markdown-Editor
- [ ] Markdown-Rendering (flutter_markdown)
- [ ] Live-Preview / Split-View
- [ ] Formatierungs-Toolbar
- [ ] Syntax-Highlighting

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

## Phase 6: Plattform-spezifisch

### Android
- [ ] home_widget Package integrieren
- [ ] Kleines Widget (einzelne Notiz-Vorschau)
- [ ] Mittleres Widget (Notizliste)
- [ ] Schnellnotiz-Widget (direkte Eingabe)
- [ ] Widget-Konfiguration

### Desktop (Windows/Linux)
- [ ] Keyboard-Shortcuts
- [ ] Responsive Layout für große Bildschirme
- [ ] Drag & Drop Support

### Web
- [ ] PWA-Konfiguration
- [ ] Offline-Support (Service Worker)

## Phase 7: Zusatzfunktionen

- [ ] Suche (Volltext, Tags, Ordner)
- [ ] Sortierung und Filterung
- [ ] Notiz-Export (PDF, Markdown, Text)
- [ ] Papierkorb / Archiv
- [ ] Einstellungen persistieren (SharedPreferences)

## Phase 8: Cloud-Sync

- [ ] Sync-Interface definieren (abstrakte Klasse)
- [ ] Sync-Provider implementieren
  - [ ] Google Drive
  - [ ] Nextcloud (WebDAV)
  - [ ] NAS / eigener Server
- [ ] Backend-Konfiguration UI
- [ ] Konfliktbehandlung
- [ ] Offline-First Architektur sicherstellen

---

## Technische Notizen

### Empfohlene Packages
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Datenbank (Drift)
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.0

  # State Management (Riverpod)
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Utilities
  uuid: ^4.2.0

  # Markdown
  flutter_markdown: ^0.6.18
  markdown: ^7.1.0

  # Media
  record: ^5.0.0
  audioplayers: ^5.2.0
  image_picker: ^1.0.0

  # Widgets (Android)
  home_widget: ^0.4.0

  # UI
  flutter_colorpicker: ^1.0.0
  dynamic_color: ^1.7.0
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.15.0
  riverpod_generator: ^2.3.0
  flutter_lints: ^3.0.0
```

### Material Design 3 Setup
```dart
// main.dart - M3 Theme mit System-Theme und User-Anpassung
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(seedColorProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ?? ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ?? ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
          ),
        );
      },
    );
  }
}
```

### Design-Ressourcen
- Anthropic Skills: https://github.com/anthropics/skills
  - Creative & Design Skills für UI/UX-Konzepte
  - Document Skills für Export-Layouts

### Ordnerstruktur
```
lib/
├── database/
│   ├── database.dart        # Drift Database
│   ├── tables/
│   │   ├── notes.dart
│   │   ├── folders.dart
│   │   └── tags.dart
│   └── daos/
│       ├── notes_dao.dart
│       ├── folders_dao.dart
│       └── tags_dao.dart
├── models/
│   └── enums.dart           # ContentType, etc.
├── providers/
│   ├── database_provider.dart
│   ├── notes_provider.dart
│   ├── folders_provider.dart
│   ├── theme_provider.dart
│   └── settings_provider.dart
├── services/
│   ├── storage_service.dart
│   └── sync/
│       ├── sync_service.dart
│       ├── google_drive_sync.dart
│       └── nextcloud_sync.dart
├── screens/
│   ├── home_screen.dart
│   ├── note_editor_screen.dart
│   ├── folder_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── note_card.dart
│   ├── folder_tree.dart
│   ├── markdown_editor.dart
│   ├── drawing_canvas.dart
│   └── audio_recorder.dart
└── main.dart
```
