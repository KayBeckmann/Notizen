# Notizen App - Roadmap

> Detaillierte Entwicklungs-Roadmap mit Meilensteinen und Aufgaben

---

## Übersicht

| Meilenstein | Beschreibung | Status |
|-------------|--------------|--------|
| M1 | Projektsetup & Grundstruktur | Erledigt |
| M2 | Datenmodelle & Datenbank | Erledigt |
| M3 | Basis-UI & Design-System | Erledigt |
| M4 | Markdown-Editor | Erledigt |
| M5 | Medien-Integration | Erledigt |
| M6 | Zeichenfunktion | Erledigt |
| M7 | Plattform-Features | Erledigt |
| M8 | Zusatzfunktionen | Erledigt |
| M9 | Cloud-Sync | Ausstehend |
| M10 | Release & Polish | Ausstehend |

---

## Meilenstein 1: Projektsetup & Grundstruktur

**Ziel:** Lauffähiges Flutter-Projekt mit allen Abhängigkeiten und Grundstruktur

### 1.1 Flutter-Projekt initialisieren
- [x] 1.1.1 `flutter create` mit Organisation und Projektname ausführen
- [x] 1.1.2 Plattform-Support aktivieren (Android, iOS, Windows, Linux, Web)
- [x] 1.1.3 Minimale SDK-Version festlegen (Flutter 3.16+, Dart 3.2+)
- [x] 1.1.4 `.gitignore` anpassen für Flutter-Projekt
- [x] 1.1.5 Initiales Build auf allen Plattformen testen

### 1.2 Ordnerstruktur anlegen
- [x] 1.2.1 `lib/database/` erstellen (Drift Database)
- [x] 1.2.2 `lib/database/tables/` erstellen (Drift Tables)
- [x] 1.2.3 `lib/database/daos/` erstellen (Data Access Objects)
- [x] 1.2.4 `lib/models/` erstellen (Enums, DTOs)
- [x] 1.2.5 `lib/providers/` erstellen (Riverpod Provider)
- [x] 1.2.6 `lib/services/` erstellen (Business Logic)
- [x] 1.2.7 `lib/screens/` erstellen (Seiten/Views)
- [x] 1.2.8 `lib/widgets/` erstellen (Wiederverwendbare Widgets)
- [x] 1.2.9 `lib/utils/` erstellen (Hilfsfunktionen)
- [x] 1.2.10 `lib/constants/` erstellen (App-Konstanten)

### 1.3 Abhängigkeiten konfigurieren
#### 1.3.1 Datenbank-Packages
- [x] 1.3.1.1 `drift` hinzufügen
- [x] 1.3.1.2 `sqlite3_flutter_libs` hinzufügen
- [x] 1.3.1.3 `path_provider` hinzufügen
- [x] 1.3.1.4 `path` hinzufügen

#### 1.3.2 State Management
- [x] 1.3.2.1 `flutter_riverpod` hinzufügen
- [x] 1.3.2.2 `riverpod_annotation` hinzufügen

#### 1.3.3 Code-Generierung (dev_dependencies)
- [x] 1.3.3.1 `build_runner` hinzufügen
- [x] 1.3.3.2 `drift_dev` hinzufügen
- [x] 1.3.3.3 `riverpod_generator` hinzufügen

#### 1.3.4 UI & Design
- [x] 1.3.4.1 `dynamic_color` hinzufügen
- [x] 1.3.4.2 `google_fonts` hinzufügen
- [x] 1.3.4.3 `flutter_colorpicker` hinzufügen

#### 1.3.5 Utilities
- [x] 1.3.5.1 `uuid` hinzufügen
- [x] 1.3.5.2 `shared_preferences` hinzufügen
- [x] 1.3.5.3 `intl` hinzufügen (Datumsformatierung)

#### 1.3.6 Testing
- [x] 1.3.6.1 `flutter_test` konfigurieren
- [x] 1.3.6.2 `mocktail` hinzufügen
- [x] 1.3.6.3 `flutter_lints` konfigurieren

### 1.4 Basis-Konfiguration
- [x] 1.4.1 `analysis_options.yaml` anpassen (Lint-Regeln)
- [x] 1.4.2 `build.yaml` für Code-Generierung erstellen
- [x] 1.4.3 App-Icons vorbereiten (Platzhalter)
- [x] 1.4.4 Splash-Screen konfigurieren
- [x] 1.4.5 `flutter pub get` ausführen
- [x] 1.4.6 Initiales `dart run build_runner build` testen

### 1.5 Deliverables M1
- [x] Lauffähige App auf allen Zielplattformen
- [x] Vollständige Ordnerstruktur
- [x] Alle Dependencies installiert
- [x] Build-Runner funktioniert

---

## Meilenstein 2: Datenmodelle & Datenbank

**Ziel:** Vollständige Datenbankschicht mit Drift und Riverpod-Integration

### 2.1 Enums & Konstanten definieren
- [x] 2.1.1 `ContentType` Enum erstellen (text, audio, image, drawing)
- [x] 2.1.2 `SortOrder` Enum erstellen (name, created, modified)
- [x] 2.1.3 `SortDirection` Enum erstellen (asc, desc)
- [x] 2.1.4 Standard-Ordner-Farben definieren
- [x] 2.1.5 Standard-Tag-Farben definieren

### 2.2 Drift Tables erstellen
#### 2.2.1 Folders Table
- [x] 2.2.1.1 `id` (UUID, Primary Key)
- [x] 2.2.1.2 `name` (Text, nicht leer)
- [x] 2.2.1.3 `color` (Integer, Hex-Wert)
- [x] 2.2.1.4 `icon` (Text, Icon-Name)
- [x] 2.2.1.5 `parentId` (UUID, nullable, Foreign Key auf sich selbst)
- [x] 2.2.1.6 `position` (Integer, für Sortierung)
- [x] 2.2.1.7 `createdAt` (DateTime)
- [x] 2.2.1.8 `updatedAt` (DateTime)

#### 2.2.2 Notes Table
- [x] 2.2.2.1 `id` (UUID, Primary Key)
- [x] 2.2.2.2 `title` (Text)
- [x] 2.2.2.3 `content` (Text, Markdown)
- [x] 2.2.2.4 `contentType` (Enum)
- [x] 2.2.2.5 `folderId` (UUID, Foreign Key)
- [x] 2.2.2.6 `isPinned` (Boolean)
- [x] 2.2.2.7 `isArchived` (Boolean)
- [x] 2.2.2.8 `isTrashed` (Boolean)
- [x] 2.2.2.9 `trashedAt` (DateTime, nullable)
- [x] 2.2.2.10 `mediaPath` (Text, nullable - für Audio/Bild)
- [x] 2.2.2.11 `drawingData` (Text, nullable - JSON für Zeichnung)
- [x] 2.2.2.12 `createdAt` (DateTime)
- [x] 2.2.2.13 `updatedAt` (DateTime)

#### 2.2.3 Tags Table
- [x] 2.2.3.1 `id` (UUID, Primary Key)
- [x] 2.2.3.2 `name` (Text, unique)
- [x] 2.2.3.3 `color` (Integer, Hex-Wert)
- [x] 2.2.3.4 `createdAt` (DateTime)

#### 2.2.4 NoteTags Table (Many-to-Many)
- [x] 2.2.4.1 `noteId` (UUID, Foreign Key)
- [x] 2.2.4.2 `tagId` (UUID, Foreign Key)
- [x] 2.2.4.3 Composite Primary Key (noteId, tagId)

### 2.3 Drift Database-Klasse
- [x] 2.3.1 `AppDatabase` Klasse erstellen
- [x] 2.3.2 Alle Tables registrieren
- [x] 2.3.3 Schema-Version definieren
- [x] 2.3.4 Migration-Strategie implementieren
- [x] 2.3.5 Datenbank-Pfad konfigurieren (plattformspezifisch)
- [ ] 2.3.6 Web-Support mit `drift_dev` konfigurieren

### 2.4 Data Access Objects (DAOs)
#### 2.4.1 FoldersDao
- [x] 2.4.1.1 `watchAllFolders()` - Stream aller Ordner
- [x] 2.4.1.2 `watchRootFolders()` - Stream der Root-Ordner
- [x] 2.4.1.3 `watchChildFolders(parentId)` - Stream der Kind-Ordner
- [x] 2.4.1.4 `getFolderById(id)` - Einzelner Ordner
- [x] 2.4.1.5 `getFolderPath(id)` - Pfad vom Root zum Ordner
- [x] 2.4.1.6 `createFolder(folder)` - Ordner erstellen
- [x] 2.4.1.7 `updateFolder(folder)` - Ordner aktualisieren
- [x] 2.4.1.8 `deleteFolder(id)` - Ordner löschen (kaskadierend)
- [x] 2.4.1.9 `moveFolder(id, newParentId)` - Ordner verschieben
- [x] 2.4.1.10 `reorderFolders(ids)` - Reihenfolge ändern
- [x] 2.4.1.11 `createDefaultFolder()` - "Neu"-Ordner erstellen

#### 2.4.2 NotesDao
- [x] 2.4.2.1 `watchAllNotes()` - Stream aller Notizen
- [x] 2.4.2.2 `watchNotesByFolder(folderId)` - Stream nach Ordner
- [x] 2.4.2.3 `watchNotesByTag(tagId)` - Stream nach Tag
- [x] 2.4.2.4 `watchPinnedNotes()` - Stream der gepinnten Notizen
- [x] 2.4.2.5 `watchArchivedNotes()` - Stream des Archivs
- [x] 2.4.2.6 `watchTrashedNotes()` - Stream des Papierkorbs
- [x] 2.4.2.7 `getNoteById(id)` - Einzelne Notiz
- [x] 2.4.2.8 `searchNotes(query)` - Volltextsuche
- [x] 2.4.2.9 `createNote(note)` - Notiz erstellen
- [x] 2.4.2.10 `updateNote(note)` - Notiz aktualisieren
- [x] 2.4.2.11 `deleteNote(id)` - Notiz endgültig löschen
- [x] 2.4.2.12 `moveToTrash(id)` - In Papierkorb verschieben
- [x] 2.4.2.13 `restoreFromTrash(id)` - Aus Papierkorb wiederherstellen
- [x] 2.4.2.14 `emptyTrash()` - Papierkorb leeren
- [x] 2.4.2.15 `moveNote(id, folderId)` - Notiz verschieben
- [x] 2.4.2.16 `togglePin(id)` - Anpinnen umschalten
- [x] 2.4.2.17 `toggleArchive(id)` - Archivieren umschalten

#### 2.4.3 TagsDao
- [x] 2.4.3.1 `watchAllTags()` - Stream aller Tags
- [x] 2.4.3.2 `watchTagsForNote(noteId)` - Tags einer Notiz
- [x] 2.4.3.3 `getTagById(id)` - Einzelner Tag
- [x] 2.4.3.4 `createTag(tag)` - Tag erstellen
- [x] 2.4.3.5 `updateTag(tag)` - Tag aktualisieren
- [x] 2.4.3.6 `deleteTag(id)` - Tag löschen
- [x] 2.4.3.7 `addTagToNote(noteId, tagId)` - Tag zuweisen
- [x] 2.4.3.8 `removeTagFromNote(noteId, tagId)` - Tag entfernen
- [x] 2.4.3.9 `setTagsForNote(noteId, tagIds)` - Tags setzen

### 2.5 Riverpod Provider
- [x] 2.5.1 `databaseProvider` - Singleton Database-Instanz
- [x] 2.5.2 `foldersDaoProvider` - FoldersDao Instanz
- [x] 2.5.3 `notesDaoProvider` - NotesDao Instanz
- [x] 2.5.4 `tagsDaoProvider` - TagsDao Instanz
- [x] 2.5.5 `allFoldersProvider` - Stream-Provider für Ordner
- [x] 2.5.6 `folderTreeProvider` - Hierarchische Ordner-Struktur
- [x] 2.5.7 `currentFolderProvider` - Aktuell ausgewählter Ordner
- [x] 2.5.8 `notesInFolderProvider` - Notizen im aktuellen Ordner
- [x] 2.5.9 `selectedNoteProvider` - Aktuell ausgewählte Notiz
- [x] 2.5.10 `allTagsProvider` - Stream-Provider für Tags
- [x] 2.5.11 `searchQueryProvider` - Suchbegriff State
- [x] 2.5.12 `searchResultsProvider` - Suchergebnisse

### 2.6 Unit Tests
- [x] 2.6.1 FoldersDao Tests schreiben
- [x] 2.6.2 NotesDao Tests schreiben
- [x] 2.6.3 TagsDao Tests schreiben
- [x] 2.6.4 In-Memory-Datenbank für Tests konfigurieren

### 2.7 Deliverables M2
- [x] Vollständiges Datenbankschema
- [x] Alle DAOs implementiert und getestet
- [x] Riverpod Provider funktionsfähig
- [x] Migration-System vorbereitet

---

## Meilenstein 3: Basis-UI & Design-System

**Ziel:** Material Design 3 Theme und grundlegende UI-Komponenten

### 3.1 Theme-System
#### 3.1.1 Basis-Theme
- [x] 3.1.1.1 `ThemeData` mit `useMaterial3: true`
- [x] 3.1.1.2 Light-Theme konfigurieren
- [x] 3.1.1.3 Dark-Theme konfigurieren
- [x] 3.1.1.4 `ColorScheme.fromSeed()` implementieren
- [x] 3.1.1.5 Standard-Seed-Farbe festlegen

#### 3.1.2 Dynamic Color
- [x] 3.1.2.1 `DynamicColorBuilder` integrieren
- [x] 3.1.2.2 Fallback für Plattformen ohne Dynamic Color
- [x] 3.1.2.3 Dynamic Color testen (Android 12+)

#### 3.1.3 Typography
- [x] 3.1.3.1 Google Fonts einbinden (z.B. Roboto, Inter)
- [x] 3.1.3.2 M3 TextTheme konfigurieren
- [x] 3.1.3.3 Custom TextStyles für Notiz-Inhalte

#### 3.1.4 Theme-Einstellungen
- [x] 3.1.4.1 `themeModeProvider` erstellen (System/Light/Dark)
- [x] 3.1.4.2 `seedColorProvider` erstellen (Custom Farbe)
- [x] 3.1.4.3 `useDynamicColorProvider` erstellen (An/Aus)
- [x] 3.1.4.4 Theme-Einstellungen in SharedPreferences speichern
- [x] 3.1.4.5 Theme-Einstellungen beim Start laden

### 3.2 App-Struktur
- [x] 3.2.1 `main.dart` mit ProviderScope aufsetzen
- [x] 3.2.2 `MyApp` Widget mit Theme-Integration
- [x] 3.2.3 Router/Navigation konfigurieren (go_router oder Navigator 2.0)
- [x] 3.2.4 Responsive Breakpoints definieren (Mobile/Tablet/Desktop)

### 3.3 Home-Screen
#### 3.3.1 Layout
- [x] 3.3.1.1 Scaffold mit AppBar
- [x] 3.3.1.2 NavigationDrawer für Ordner (Mobile)
- [x] 3.3.1.3 NavigationRail für Ordner (Tablet)
- [x] 3.3.1.4 Permanente Sidebar für Ordner (Desktop)
- [x] 3.3.1.5 Responsive Layout-Switching

#### 3.3.2 AppBar
- [x] 3.3.2.1 App-Titel / Ordner-Name
- [x] 3.3.2.2 Such-Button
- [x] 3.3.2.3 Sortier-Button mit Dropdown
- [x] 3.3.2.4 Mehr-Optionen-Menü
- [ ] 3.3.2.5 SearchBar-Modus (expandable)

#### 3.3.3 Notizliste
- [x] 3.3.3.1 `NoteCard` Widget erstellen
- [x] 3.3.3.2 Titel, Vorschau, Datum anzeigen
- [x] 3.3.3.3 Content-Type Icon anzeigen
- [x] 3.3.3.4 Pinned-Indikator
- [x] 3.3.3.5 Tags als Chips anzeigen
- [x] 3.3.3.6 ListView für Mobile
- [ ] 3.3.3.7 GridView Option
- [x] 3.3.3.8 Leerer Zustand (Empty State)
- [x] 3.3.3.9 Ladeindikator

#### 3.3.4 Floating Action Button
- [x] 3.3.4.1 FAB für neue Notiz
- [x] 3.3.4.2 Extended FAB auf Desktop
- [ ] 3.3.4.3 Speed Dial für verschiedene Notiztypen (optional)

### 3.4 Ordner-Navigation
#### 3.4.1 Ordner-Baum Widget
- [x] 3.4.1.1 `FolderTree` Widget erstellen
- [x] 3.4.1.2 Rekursive Darstellung (verschachtelt)
- [ ] 3.4.1.3 Expand/Collapse Animation
- [x] 3.4.1.4 Ordner-Icon und Farbe anzeigen
- [ ] 3.4.1.5 Anzahl Notizen pro Ordner
- [x] 3.4.1.6 Aktiven Ordner hervorheben
- [x] 3.4.1.7 Ordner per Tap auswählen

#### 3.4.2 Ordner-Aktionen
- [x] 3.4.2.1 Kontextmenü (Long-Press / Rechtsklick)
- [x] 3.4.2.2 Ordner umbenennen
- [x] 3.4.2.3 Ordner-Farbe ändern
- [x] 3.4.2.4 Ordner-Icon ändern
- [x] 3.4.2.5 Ordner verschieben
- [x] 3.4.2.6 Ordner löschen (mit Bestätigung)
- [x] 3.4.2.7 Neuen Unterordner erstellen

#### 3.4.3 Spezielle Ordner
- [x] 3.4.3.1 "Alle Notizen" Eintrag
- [x] 3.4.3.2 "Angepinnt" Eintrag
- [x] 3.4.3.3 "Archiv" Eintrag
- [x] 3.4.3.4 "Papierkorb" Eintrag
- [x] 3.4.3.5 Trennlinie zwischen Spezial- und User-Ordnern

### 3.5 Ordner-Dialog
- [x] 3.5.1 `CreateFolderDialog` erstellen
- [x] 3.5.2 Name-Eingabefeld mit Validierung
- [x] 3.5.3 Farb-Auswahl (ColorPicker)
- [x] 3.5.4 Icon-Auswahl (Icon-Grid)
- [x] 3.5.5 Parent-Ordner Auswahl (Dropdown)
- [x] 3.5.6 `EditFolderDialog` (gleiche Felder, vorausgefüllt)

### 3.6 Tag-Verwaltung
#### 3.6.1 Tag-Liste
- [x] 3.6.1.1 Alle Tags anzeigen als Chips
- [x] 3.6.1.2 Tag antippen zum Filtern
- [ ] 3.6.1.3 Tag-Anzahl (Notizen mit diesem Tag)

#### 3.6.2 Tag-Dialog
- [x] 3.6.2.1 `CreateTagDialog` erstellen
- [x] 3.6.2.2 Name-Eingabefeld
- [x] 3.6.2.3 Farb-Auswahl
- [x] 3.6.2.4 `EditTagDialog`
- [x] 3.6.2.5 Tag löschen (mit Bestätigung)

### 3.7 Einstellungen-Screen
- [x] 3.7.1 Scaffold mit AppBar
- [x] 3.7.2 Theme-Modus Auswahl (ListTile mit RadioButtons)
- [x] 3.7.3 Akzentfarbe Auswahl (ColorPicker)
- [x] 3.7.4 Dynamic Color Toggle (SwitchListTile)
- [ ] 3.7.5 Sprache Auswahl (für später)
- [x] 3.7.6 Über die App (Version, Lizenzen)
- [x] 3.7.7 Spenden-Links

### 3.8 Allgemeine Widgets
- [x] 3.8.1 `ConfirmationDialog` (wiederverwendbar)
- [x] 3.8.2 `LoadingOverlay` Widget
- [x] 3.8.3 `ErrorWidget` für Fehlerzustände
- [x] 3.8.4 `EmptyStateWidget` für leere Listen

### 3.9 Deliverables M3
- [x] Vollständiges Theme-System
- [x] Home-Screen mit Notizliste
- [x] Ordner-Navigation funktionsfähig
- [x] Einstellungen-Screen
- [x] Responsive Layout (Mobile/Tablet/Desktop)

---

## Meilenstein 4: Markdown-Editor

**Ziel:** Vollständiger Markdown-Editor mit Live-Preview

### 4.1 Editor-Screen Layout
- [x] 4.1.1 Scaffold mit AppBar
- [x] 4.1.2 Titel-Eingabefeld
- [x] 4.1.3 Content-Bereich (Editor oder Preview)
- [x] 4.1.4 Split-View Option (Editor + Preview nebeneinander)
- [x] 4.1.5 Toggle zwischen Edit/Preview/Split
- [x] 4.1.6 Responsive Layout (Desktop: Split als Standard)

### 4.2 Markdown-Editor
#### 4.2.1 Text-Eingabe
- [x] 4.2.1.1 `TextField` mit `maxLines: null`
- [x] 4.2.1.2 Monospace-Schrift für Code-Blöcke
- [x] 4.2.1.3 Auto-Save mit Debounce (2 Sekunden)
- [x] 4.2.1.4 Cursor-Position merken

#### 4.2.2 Formatierungs-Toolbar
- [x] 4.2.2.1 Bold (`**text**`)
- [x] 4.2.2.2 Italic (`*text*`)
- [x] 4.2.2.3 Strikethrough (`~~text~~`)
- [x] 4.2.2.4 Heading 1-3 (`#`, `##`, `###`)
- [x] 4.2.2.5 Bullet List (`- item`)
- [x] 4.2.2.6 Numbered List (`1. item`)
- [x] 4.2.2.7 Checkbox (`- [ ] task`)
- [x] 4.2.2.8 Code Inline (`` `code` ``)
- [x] 4.2.2.9 Code Block (``` ``` ```)
- [x] 4.2.2.10 Quote (`> quote`)
- [x] 4.2.2.11 Link (`[text](url)`)
- [x] 4.2.2.12 Horizontal Rule (`---`)
- [x] 4.2.2.13 Toolbar scrollbar auf Mobile

#### 4.2.3 Toolbar-Logik
- [x] 4.2.3.1 Text-Selektion erkennen
- [x] 4.2.3.2 Formatierung um Selektion anwenden
- [x] 4.2.3.3 Wenn keine Selektion: Platzhalter einfügen
- [x] 4.2.3.4 Cursor nach Formatierung positionieren

### 4.3 Markdown-Preview
#### 4.3.1 Rendering
- [x] 4.3.1.1 `flutter_markdown` integrieren
- [x] 4.3.1.2 Custom Stylesheet (passend zum Theme)
- [x] 4.3.1.3 Syntax-Highlighting für Code-Blöcke
- [x] 4.3.1.4 Checkbox-Interaktion (anklickbar)
- [x] 4.3.1.5 Link-Handling (URL öffnen)
- [ ] 4.3.1.6 Bild-Rendering (lokale Bilder) → M5

#### 4.3.2 Scrolling
- [x] 4.3.2.1 Scroll-Position synchronisieren (Editor <-> Preview)
- [x] 4.3.2.2 Smooth Scrolling

### 4.4 AppBar-Aktionen
- [x] 4.4.1 Speichern-Button (falls nicht Auto-Save)
- [x] 4.4.2 Rückgängig-Button
- [x] 4.4.3 Wiederholen-Button
- [x] 4.4.4 Teilen-Button
- [x] 4.4.5 Mehr-Menü (Tags bearbeiten, In Ordner verschieben, Löschen)

### 4.5 Tag-Zuweisung im Editor
- [x] 4.5.1 Tag-Chips unter Titel anzeigen
- [x] 4.5.2 Tag hinzufügen (Autocomplete)
- [x] 4.5.3 Tag entfernen (X-Button)
- [x] 4.5.4 Neuen Tag erstellen (inline)

### 4.6 Notiz-Metadaten
- [x] 4.6.1 Erstellungsdatum anzeigen
- [x] 4.6.2 Änderungsdatum anzeigen
- [x] 4.6.3 Wortanzahl anzeigen
- [x] 4.6.4 Zeichenanzahl anzeigen

### 4.7 Keyboard-Shortcuts (Desktop)
- [x] 4.7.1 `Ctrl+S` - Speichern
- [x] 4.7.2 `Ctrl+B` - Bold
- [x] 4.7.3 `Ctrl+I` - Italic
- [x] 4.7.4 `Ctrl+Z` - Rückgängig
- [x] 4.7.5 `Ctrl+Y` - Wiederholen
- [x] 4.7.6 `Ctrl+1/2/3` - Heading 1/2/3
- [x] 4.7.7 `Escape` - Editor verlassen

### 4.8 Deliverables M4
- [x] Funktionaler Markdown-Editor
- [x] Live-Preview mit Syntax-Highlighting
- [x] Formatierungs-Toolbar
- [x] Auto-Save
- [x] Desktop Keyboard-Shortcuts

---

## Meilenstein 5: Medien-Integration

**Ziel:** Sprachnotizen und Bildnotizen

### 5.1 Storage-Service
- [x] 5.1.1 `StorageService` Klasse erstellen
- [x] 5.1.2 App-Dokumenten-Verzeichnis ermitteln
- [x] 5.1.3 Unterverzeichnisse erstellen (audio, images)
- [x] 5.1.4 Datei speichern mit UUID-Namen
- [x] 5.1.5 Datei lesen
- [x] 5.1.6 Datei löschen
- [x] 5.1.7 Verwaiste Dateien aufräumen

### 5.2 Sprachnotizen
#### 5.2.1 Aufnahme
- [x] 5.2.1.1 `record` Package integrieren
- [x] 5.2.1.2 Mikrofon-Berechtigung anfragen
- [x] 5.2.1.3 Aufnahme starten
- [x] 5.2.1.4 Aufnahme pausieren/fortsetzen
- [x] 5.2.1.5 Aufnahme stoppen
- [x] 5.2.1.6 Aufnahme abbrechen
- [x] 5.2.1.7 Aufnahme-Timer anzeigen
- [x] 5.2.1.8 Wellenform-Visualisierung (Amplitude)

#### 5.2.2 Wiedergabe
- [x] 5.2.2.1 `audioplayers` Package integrieren
- [x] 5.2.2.2 Play/Pause Button
- [x] 5.2.2.3 Stop Button
- [x] 5.2.2.4 Seek-Bar (Position)
- [x] 5.2.2.5 Aktuelle Zeit / Gesamtdauer anzeigen
- [x] 5.2.2.6 Wiedergabegeschwindigkeit (0.5x, 1x, 1.5x, 2x)

#### 5.2.3 Audio-Notiz UI
- [x] 5.2.3.1 `AudioRecorder` Widget erstellen
- [x] 5.2.3.2 `AudioPlayer` Widget erstellen
- [x] 5.2.3.3 Audio-Notiz Screen
- [x] 5.2.3.4 Titel-Eingabe für Audio-Notiz
- [x] 5.2.3.5 Optional: Text-Notizen zur Audio hinzufügen

### 5.3 Bildnotizen
#### 5.3.1 Bild-Erfassung
- [x] 5.3.1.1 `image_picker` Package integrieren
- [x] 5.3.1.2 Kamera-Berechtigung anfragen
- [x] 5.3.1.3 Foto mit Kamera aufnehmen
- [x] 5.3.1.4 Bild aus Galerie wählen
- [x] 5.3.1.5 Bild komprimieren (Qualität/Größe)
- [x] 5.3.1.6 Bild im Storage speichern

#### 5.3.2 Bild-Anzeige
- [x] 5.3.2.1 Bild-Vorschau in Notiz-Card
- [x] 5.3.2.2 Vollbild-Ansicht
- [x] 5.3.2.3 Pinch-to-Zoom
- [x] 5.3.2.4 Bild teilen

#### 5.3.3 Bild-Notiz UI
- [x] 5.3.3.1 Bild-Notiz Screen
- [x] 5.3.3.2 Titel-Eingabe
- [x] 5.3.3.3 Optional: Beschreibung (Markdown)
- [x] 5.3.3.4 Bild ersetzen
- [x] 5.3.3.5 Bild löschen

### 5.4 Notiz-Typ Auswahl
- [x] 5.4.1 "Neue Notiz" Dialog mit Typ-Auswahl
- [x] 5.4.2 Text-Notiz Option
- [x] 5.4.3 Sprachnotiz Option
- [x] 5.4.4 Bildnotiz Option
- [x] 5.4.5 Zeichnung Option
- [x] 5.4.6 Schnellzugriff über Speed-Dial FAB (optional)

### 5.5 Deliverables M5
- [x] Funktionale Sprachnotizen (Aufnahme + Wiedergabe)
- [x] Funktionale Bildnotizen (Kamera + Galerie)
- [x] Storage-Service für Mediendateien
- [x] Integration in Notiz-Screens

---

## Meilenstein 6: Zeichenfunktion

**Ziel:** Vollständiger Zeicheneditor mit Werkzeugen

### 6.1 Canvas-Grundlagen
- [x] 6.1.1 `CustomPainter` für Zeichenfläche
- [x] 6.1.2 Touch/Maus-Events erfassen
- [x] 6.1.3 Pfade als Liste von Punkten speichern
- [x] 6.1.4 Pfade mit Eigenschaften (Farbe, Dicke, Stil)
- [x] 6.1.5 Smooth-Drawing (Bézier-Kurven)

### 6.2 Zeichenwerkzeuge
#### 6.2.1 Stift
- [x] 6.2.1.1 Freihand-Zeichnen
- [x] 6.2.1.2 Stiftdicke wählbar (3 Stufen minimum)
- [x] 6.2.1.3 Stiftfarbe wählbar

#### 6.2.2 Marker/Highlighter
- [x] 6.2.2.1 Halbtransparenter Stift
- [x] 6.2.2.2 Breitere Standarddicke

#### 6.2.3 Radierer
- [x] 6.2.3.1 Radierer-Größe wählbar
- [x] 6.2.3.2 Pfade unter Radierer entfernen
- [ ] 6.2.3.3 Punkt-basiertes Radieren (optional)

#### 6.2.4 Formen
- [x] 6.2.4.1 Linie
- [x] 6.2.4.2 Rechteck
- [x] 6.2.4.3 Kreis/Ellipse
- [x] 6.2.4.4 Pfeil
- [x] 6.2.4.5 Form-Vorschau während Zeichnen
- [x] 6.2.4.6 Gefüllt / Nur Umriss Option

### 6.3 Farbauswahl
- [x] 6.3.1 Schnell-Farbpalette (8-12 Farben)
- [x] 6.3.2 Aktuelle Farbe anzeigen
- [x] 6.3.3 Erweiterter ColorPicker (Dialog)
- [x] 6.3.4 Letzte verwendete Farben merken

### 6.4 Dicke-Auswahl
- [x] 6.4.1 Slider für Stiftdicke
- [x] 6.4.2 Vorschau der Dicke
- [x] 6.4.3 Preset-Buttons (Fein, Normal, Dick)

### 6.5 Undo/Redo
- [x] 6.5.1 Undo-Stack implementieren
- [x] 6.5.2 Redo-Stack implementieren
- [x] 6.5.3 Undo-Button in Toolbar
- [x] 6.5.4 Redo-Button in Toolbar
- [x] 6.5.5 Keyboard-Shortcuts (Ctrl+Z, Ctrl+Y)

### 6.6 Zusätzliche Funktionen
- [x] 6.6.1 Alles löschen (mit Bestätigung)
- [x] 6.6.2 Hintergrundfarbe ändern
- [x] 6.6.3 Raster anzeigen (optional)
- [ ] 6.6.4 Zoom & Pan (für große Zeichnungen)

### 6.7 Speicherung
- [x] 6.7.1 Zeichnung als JSON serialisieren
- [x] 6.7.2 JSON in Datenbank speichern
- [x] 6.7.3 Zeichnung aus JSON laden
- [x] 6.7.4 Auto-Save mit Debounce
- [x] 6.7.5 Als Bild exportieren (PNG)

### 6.8 Drawing-Screen UI
- [x] 6.8.1 Vollbild-Canvas
- [x] 6.8.2 Toolbar am unteren Rand (Mobile)
- [x] 6.8.3 Sidebar-Toolbar (Desktop)
- [x] 6.8.4 Werkzeug-Auswahl
- [x] 6.8.5 Farb-Auswahl
- [x] 6.8.6 Dicke-Auswahl
- [x] 6.8.7 Undo/Redo Buttons

### 6.9 Deliverables M6
- [x] Funktionaler Zeicheneditor
- [x] Stift, Marker, Radierer
- [x] Formen (Linie, Rechteck, Kreis, Pfeil)
- [x] Farbpalette und Dicken-Auswahl
- [x] Undo/Redo
- [x] Speicherung und Laden

---

## Meilenstein 7: Plattform-Features

**Ziel:** Plattform-spezifische Optimierungen

### 7.1 Android Home-Widgets
#### 7.1.1 Setup
- [ ] 7.1.1.1 `home_widget` Package konfigurieren
- [ ] 7.1.1.2 Native Android-Widget Code (Kotlin)
- [ ] 7.1.1.3 Widget-Provider registrieren
- [ ] 7.1.1.4 Widget-Layouts erstellen (XML)

#### 7.1.2 Kleines Widget (2x1)
- [ ] 7.1.2.1 Einzelne Notiz-Vorschau
- [ ] 7.1.2.2 Titel anzeigen
- [ ] 7.1.2.3 Tap öffnet Notiz

#### 7.1.3 Mittleres Widget (4x2)
- [ ] 7.1.3.1 Liste der letzten 3-5 Notizen
- [ ] 7.1.3.2 Titel und Vorschau
- [ ] 7.1.3.3 Tap öffnet jeweilige Notiz

#### 7.1.4 Schnellnotiz-Widget (4x1)
- [ ] 7.1.4.1 "+" Button für neue Notiz
- [ ] 7.1.4.2 Schnellzugriff auf verschiedene Typen
- [ ] 7.1.4.3 Öffnet App mit Editor

#### 7.1.5 Widget-Konfiguration
- [ ] 7.1.5.1 Welche Notiz/Ordner anzeigen
- [ ] 7.1.5.2 Widget-Erscheinungsbild
- [ ] 7.1.5.3 Widget-Update bei Notiz-Änderung

### 7.2 iOS Widgets (optional)
- [ ] 7.2.1 WidgetKit Extension erstellen
- [ ] 7.2.2 Small Widget
- [ ] 7.2.3 Medium Widget
- [ ] 7.2.4 Lock Screen Widget

### 7.3 Desktop-Optimierungen
#### 7.3.1 Keyboard-Shortcuts
- [x] 7.3.1.1 `Ctrl+N` - Neue Notiz
- [x] 7.3.1.2 `Ctrl+F` - Suche
- [x] 7.3.1.3 `Ctrl+,` - Einstellungen
- [x] 7.3.1.4 `Delete` - Notiz löschen
- [x] 7.3.1.5 `F2` - Umbenennen
- [x] 7.3.1.6 Shortcuts-Hilfe Dialog

#### 7.3.2 Responsive Layout
- [ ] 7.3.2.1 Drei-Spalten-Layout (Ordner | Liste | Editor)
- [ ] 7.3.2.2 Resizable Panels
- [ ] 7.3.2.3 Collapse/Expand Sidebar
- [ ] 7.3.2.4 Minimale Fenstergrößen

#### 7.3.3 Drag & Drop
- [x] 7.3.3.1 Notizen zwischen Ordnern ziehen
- [x] 7.3.3.2 Ordner neu anordnen
- [ ] 7.3.3.3 Dateien in App ziehen (Bilder)
- [x] 7.3.3.4 Visual Feedback beim Ziehen

#### 7.3.4 Kontextmenüs
- [x] 7.3.4.1 Rechtsklick auf Notiz
- [x] 7.3.4.2 Rechtsklick auf Ordner
- [x] 7.3.4.3 Native Kontextmenü-Styling

### 7.4 Web-Optimierungen
#### 7.4.1 PWA
- [x] 7.4.1.1 `manifest.json` konfigurieren
- [x] 7.4.1.2 App-Icons für Web
- [ ] 7.4.1.3 Service Worker für Offline-Support
- [ ] 7.4.1.4 Install-Prompt

#### 7.4.2 Web-spezifisch
- [ ] 7.4.2.1 URL-Routing für Notizen
- [ ] 7.4.2.2 Browser-Tab-Titel aktualisieren
- [x] 7.4.2.3 Keyboard-Shortcuts ohne Konflikte
- [x] 7.4.2.4 Responsive für alle Bildschirmgrößen

### 7.5 Deliverables M7
- [ ] Android Home-Widgets funktionsfähig
- [ ] Desktop Keyboard-Shortcuts
- [ ] Drag & Drop auf Desktop
- [ ] PWA-Konfiguration für Web

---

## Meilenstein 8: Zusatzfunktionen

**Ziel:** Suche, Export, Papierkorb und weitere Features

### 8.1 Suche
#### 8.1.1 Suchfunktion
- [x] 8.1.1.1 Suchfeld in AppBar
- [x] 8.1.1.2 Volltextsuche in Titel und Inhalt
- [x] 8.1.1.3 Suche in Echtzeit (mit Debounce)
- [x] 8.1.1.4 Suchergebnisse als Liste
- [ ] 8.1.1.5 Suchbegriff hervorheben

#### 8.1.2 Filter
- [x] 8.1.2.1 Nach Ordner filtern
- [x] 8.1.2.2 Nach Tags filtern (Multi-Select)
- [x] 8.1.2.3 Nach Notiztyp filtern
- [ ] 8.1.2.4 Nach Datum filtern (erstellt/geändert)
- [x] 8.1.2.5 Filter-Chips anzeigen
- [x] 8.1.2.6 Filter kombinieren (AND)

#### 8.1.3 Sortierung
- [x] 8.1.3.1 Nach Name (A-Z, Z-A)
- [x] 8.1.3.2 Nach Erstellungsdatum
- [x] 8.1.3.3 Nach Änderungsdatum
- [ ] 8.1.3.4 Sortierung merken (pro Ordner oder global)

### 8.2 Export
#### 8.2.1 Markdown-Export
- [x] 8.2.1.1 Einzelne Notiz als .md exportieren
- [ ] 8.2.1.2 Ordner als .zip mit .md-Dateien
- [ ] 8.2.1.3 Alle Notizen exportieren

#### 8.2.2 PDF-Export
- [ ] 8.2.2.1 `pdf` Package integrieren
- [ ] 8.2.2.2 Markdown zu PDF konvertieren
- [ ] 8.2.2.3 Styling anpassen
- [ ] 8.2.2.4 Bilder einbetten
- [ ] 8.2.2.5 Zeichnungen einbetten

#### 8.2.3 Text-Export
- [x] 8.2.3.1 Plain-Text Export (ohne Markdown)
- [x] 8.2.3.2 In Zwischenablage kopieren

#### 8.2.4 Teilen
- [x] 8.2.4.1 Share-Intent (Mobile)
- [x] 8.2.4.2 Als Text teilen
- [x] 8.2.4.3 Als Datei teilen
- [ ] 8.2.4.4 Als PDF teilen

### 8.3 Papierkorb & Archiv
#### 8.3.1 Papierkorb
- [x] 8.3.1.1 Gelöschte Notizen 30 Tage aufbewahren
- [x] 8.3.1.2 Papierkorb-Ansicht
- [x] 8.3.1.3 Notiz wiederherstellen
- [x] 8.3.1.4 Notiz endgültig löschen
- [x] 8.3.1.5 Papierkorb leeren
- [x] 8.3.1.6 Automatische Bereinigung (30+ Tage)

#### 8.3.2 Archiv
- [x] 8.3.2.1 Notiz archivieren
- [x] 8.3.2.2 Archiv-Ansicht
- [x] 8.3.2.3 Notiz aus Archiv wiederherstellen
- [x] 8.3.2.4 Archivierte Notizen aus Suche ausschließen (optional)

### 8.4 Einstellungen persistieren
- [x] 8.4.1 `SharedPreferences` Service erstellen
- [x] 8.4.2 Theme-Modus speichern/laden
- [x] 8.4.3 Akzentfarbe speichern/laden
- [x] 8.4.4 Dynamic Color Präferenz speichern
- [x] 8.4.5 Sortier-Einstellungen speichern
- [x] 8.4.6 Letzter geöffneter Ordner speichern
- [ ] 8.4.7 Editor-Präferenzen (Split-View, etc.)

### 8.5 Zusätzliche Features
- [x] 8.5.1 Notiz duplizieren
- [ ] 8.5.2 Notiz als Vorlage speichern
- [ ] 8.5.3 Aus Vorlage erstellen
- [ ] 8.5.4 Mehrfachauswahl (Notizen)
- [ ] 8.5.5 Bulk-Aktionen (Löschen, Verschieben, Tags)

### 8.6 Deliverables M8
- [ ] Vollständige Suchfunktion
- [ ] Filter und Sortierung
- [ ] Export (Markdown, PDF, Text)
- [ ] Papierkorb mit Wiederherstellung
- [ ] Archiv
- [ ] Persistierte Einstellungen

---

## Meilenstein 9: Cloud-Sync

**Ziel:** Synchronisation mit verschiedenen Cloud-Diensten

### 9.1 Sync-Architektur
#### 9.1.1 Interface definieren
- [ ] 9.1.1.1 `SyncProvider` abstrakte Klasse
- [ ] 9.1.1.2 `connect()` Methode
- [ ] 9.1.1.3 `disconnect()` Methode
- [ ] 9.1.1.4 `isConnected()` Methode
- [ ] 9.1.1.5 `sync()` Methode
- [ ] 9.1.1.6 `upload(note)` Methode
- [ ] 9.1.1.7 `download(noteId)` Methode
- [ ] 9.1.1.8 `delete(noteId)` Methode
- [ ] 9.1.1.9 `getRemoteChanges()` Methode

#### 9.1.2 Sync-Logik
- [ ] 9.1.2.1 Änderungs-Tracking (lastSyncedAt)
- [ ] 9.1.2.2 Lokale Änderungen erkennen
- [ ] 9.1.2.3 Remote-Änderungen erkennen
- [ ] 9.1.2.4 Änderungen zusammenführen
- [ ] 9.1.2.5 Sync-Queue für Offline-Änderungen

#### 9.1.3 Konflikt-Behandlung
- [ ] 9.1.3.1 Konflikt erkennen (gleiche Notiz, verschiedene Änderungen)
- [ ] 9.1.3.2 Konflikt-Dialog anzeigen
- [ ] 9.1.3.3 "Lokal behalten" Option
- [ ] 9.1.3.4 "Remote übernehmen" Option
- [ ] 9.1.3.5 "Beide behalten" Option (Duplikat)
- [ ] 9.1.3.6 Automatische Konfliktlösung (neueste gewinnt, optional)

### 9.2 Google Drive Integration
- [ ] 9.2.1 `googleapis` Package integrieren
- [ ] 9.2.2 Google Sign-In implementieren
- [ ] 9.2.3 OAuth2 Tokens verwalten
- [ ] 9.2.4 App-Ordner in Drive erstellen
- [ ] 9.2.5 Notizen als JSON-Dateien speichern
- [ ] 9.2.6 Mediendateien hochladen
- [ ] 9.2.7 Änderungen synchronisieren
- [ ] 9.2.8 Sign-Out implementieren

### 9.3 Nextcloud/WebDAV Integration
- [ ] 9.3.1 WebDAV-Client implementieren
- [ ] 9.3.2 Server-URL Eingabe
- [ ] 9.3.3 Authentifizierung (User/Passwort oder App-Token)
- [ ] 9.3.4 Verbindung testen
- [ ] 9.3.5 App-Ordner auf Server erstellen
- [ ] 9.3.6 Dateien hochladen/herunterladen
- [ ] 9.3.7 Änderungen synchronisieren

### 9.4 Eigener Server (REST API)
- [ ] 9.4.1 API-Spezifikation definieren
- [ ] 9.4.2 Server-URL Eingabe
- [ ] 9.4.3 API-Key oder JWT-Auth
- [ ] 9.4.4 HTTP-Client implementieren
- [ ] 9.4.5 CRUD-Endpunkte ansprechen
- [ ] 9.4.6 Mediendateien-Upload
- [ ] 9.4.7 Sync-Endpunkt (Delta-Sync)

### 9.5 Sync-UI
#### 9.5.1 Einstellungen
- [ ] 9.5.1.1 Sync-Provider Auswahl
- [ ] 9.5.1.2 Verbindung herstellen
- [ ] 9.5.1.3 Verbindungsstatus anzeigen
- [ ] 9.5.1.4 Letzter Sync-Zeitpunkt
- [ ] 9.5.1.5 Manueller Sync-Button
- [ ] 9.5.1.6 Auto-Sync Intervall einstellen
- [ ] 9.5.1.7 Nur über WLAN synchronisieren (Mobile)
- [ ] 9.5.1.8 Verbindung trennen

#### 9.5.2 Sync-Status
- [ ] 9.5.2.1 Sync-Icon in AppBar
- [ ] 9.5.2.2 Sync-Animation während Synchronisation
- [ ] 9.5.2.3 Fehler-Indikator
- [ ] 9.5.2.4 Ausstehende Änderungen anzeigen
- [ ] 9.5.2.5 Sync-Log (Debug)

### 9.6 Offline-First
- [ ] 9.6.1 Alle Operationen lokal zuerst
- [ ] 9.6.2 Änderungen queuen wenn offline
- [ ] 9.6.3 Bei Verbindung automatisch synchronisieren
- [ ] 9.6.4 Netzwerkstatus überwachen
- [ ] 9.6.5 Offline-Indikator anzeigen

### 9.7 Deliverables M9
- [ ] Sync-Interface und Logik
- [ ] Mindestens ein Provider funktionsfähig
- [ ] Konflikt-Behandlung
- [ ] Offline-First Architektur
- [ ] Sync-UI in Einstellungen

---

## Meilenstein 10: Release & Polish

**Ziel:** App produktionsreif machen

### 10.1 Testing
#### 10.1.1 Unit Tests
- [ ] 10.1.1.1 Alle DAOs getestet
- [ ] 10.1.1.2 Alle Provider getestet
- [ ] 10.1.1.3 Sync-Logik getestet
- [ ] 10.1.1.4 Utility-Funktionen getestet
- [ ] 10.1.1.5 Code Coverage > 70%

#### 10.1.2 Widget Tests
- [ ] 10.1.2.1 Wichtige Widgets getestet
- [ ] 10.1.2.2 Formulare getestet
- [ ] 10.1.2.3 Navigation getestet

#### 10.1.3 Integration Tests
- [ ] 10.1.3.1 Happy-Path Flows testen
- [ ] 10.1.3.2 Notiz erstellen/bearbeiten/löschen
- [ ] 10.1.3.3 Ordner-Management
- [ ] 10.1.3.4 Suche und Filter

#### 10.1.4 Manuelles Testing
- [ ] 10.1.4.1 Android (verschiedene Geräte)
- [ ] 10.1.4.2 iOS (iPhone, iPad)
- [ ] 10.1.4.3 Windows
- [ ] 10.1.4.4 Linux
- [ ] 10.1.4.5 Web (Chrome, Firefox, Safari)

### 10.2 Performance
- [ ] 10.2.1 Startup-Zeit optimieren
- [ ] 10.2.2 Liste mit vielen Notizen testen
- [ ] 10.2.3 Lazy Loading implementieren
- [ ] 10.2.4 Bilder cachen
- [ ] 10.2.5 Memory Leaks finden und beheben
- [ ] 10.2.6 Jank in Animationen beheben

### 10.3 Accessibility
- [ ] 10.3.1 Semantics für Screen Reader
- [ ] 10.3.2 Ausreichende Kontraste
- [ ] 10.3.3 Touch-Targets mindestens 48x48
- [ ] 10.3.4 Keyboard-Navigation vollständig
- [ ] 10.3.5 Schriftgrößen-Skalierung testen

### 10.4 Internationalisierung
- [ ] 10.4.1 `flutter_localizations` einrichten
- [ ] 10.4.2 Alle Strings extrahieren
- [ ] 10.4.3 Deutsche Übersetzung (Standard)
- [ ] 10.4.4 Englische Übersetzung
- [ ] 10.4.5 Datum/Zeit-Formatierung lokalisieren

### 10.5 App Store Assets
#### 10.5.1 Icons
- [ ] 10.5.1.1 Android Adaptive Icon
- [ ] 10.5.1.2 iOS App Icon
- [ ] 10.5.1.3 Windows Icon
- [ ] 10.5.1.4 Linux Icon
- [ ] 10.5.1.5 Web Favicon & Icons

#### 10.5.2 Screenshots
- [ ] 10.5.2.1 Android Screenshots (Phone + Tablet)
- [ ] 10.5.2.2 iOS Screenshots (iPhone + iPad)
- [ ] 10.5.2.3 Desktop Screenshots

#### 10.5.3 Store Listings
- [ ] 10.5.3.1 App-Beschreibung (DE + EN)
- [ ] 10.5.3.2 Feature-Liste
- [ ] 10.5.3.3 Kategorien wählen
- [ ] 10.5.3.4 Datenschutzerklärung
- [ ] 10.5.3.5 Keywords

### 10.6 Release-Builds
#### 10.6.1 Android
- [ ] 10.6.1.1 Signing Key erstellen
- [ ] 10.6.1.2 `build.gradle` konfigurieren
- [ ] 10.6.1.3 ProGuard/R8 konfigurieren
- [ ] 10.6.1.4 Release APK bauen
- [ ] 10.6.1.5 Release AAB bauen
- [ ] 10.6.1.6 In Play Store hochladen

#### 10.6.2 iOS
- [ ] 10.6.2.1 Apple Developer Account
- [ ] 10.6.2.2 Certificates & Profiles
- [ ] 10.6.2.3 Release Build erstellen
- [ ] 10.6.2.4 In App Store Connect hochladen
- [ ] 10.6.2.5 TestFlight Beta

#### 10.6.3 Windows
- [ ] 10.6.3.1 MSIX Package erstellen
- [ ] 10.6.3.2 Code Signing (optional)
- [ ] 10.6.3.3 Installer erstellen
- [ ] 10.6.3.4 Microsoft Store (optional)

#### 10.6.4 Linux
- [ ] 10.6.4.1 Release Build erstellen
- [ ] 10.6.4.2 AppImage erstellen
- [ ] 10.6.4.3 Flatpak (optional)
- [ ] 10.6.4.4 Snap (optional)

#### 10.6.5 Web
- [ ] 10.6.5.1 Production Build
- [ ] 10.6.5.2 Hosting einrichten
- [ ] 10.6.5.3 Domain konfigurieren (optional)
- [ ] 10.6.5.4 SSL-Zertifikat

### 10.7 Dokumentation
- [ ] 10.7.1 README aktualisieren
- [ ] 10.7.2 CHANGELOG erstellen
- [ ] 10.7.3 CONTRIBUTING Guide (optional)
- [ ] 10.7.4 Code-Dokumentation (Dart Doc)
- [ ] 10.7.5 User Guide (optional)

### 10.8 Deliverables M10
- [ ] Alle Tests bestehen
- [ ] Performance optimiert
- [ ] Accessibility geprüft
- [ ] Deutsche + Englische Lokalisierung
- [ ] Release-Builds für alle Plattformen
- [ ] Store-Listings vorbereitet
- [ ] Dokumentation vollständig

---

## Zusammenfassung

| Meilenstein | Aufgaben | Geschätzte Komplexität |
|-------------|----------|------------------------|
| M1: Setup | 30 | Niedrig |
| M2: Datenbank | 55 | Mittel |
| M3: Basis-UI | 65 | Mittel |
| M4: Markdown | 35 | Mittel |
| M5: Medien | 35 | Mittel |
| M6: Zeichnen | 40 | Hoch |
| M7: Plattform | 40 | Mittel |
| M8: Features | 45 | Mittel |
| M9: Sync | 55 | Hoch |
| M10: Release | 60 | Mittel |
| **Gesamt** | **~460** | |

---

## Legende

- [ ] Ausstehend
- [x] Erledigt
- Nummern (z.B. 2.3.4) = Hierarchische Task-IDs für Referenzen
