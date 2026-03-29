# Basis-Image
FROM dart:stable AS build

# Arbeitsverzeichnis
WORKDIR /app

# Abhängigkeiten kopieren und installieren
COPY pubspec.* ./
RUN dart pub get

# Quellcode kopieren
COPY . .

# Ausführbare Datei bauen
RUN dart compile exe bin/server.dart -o bin/server

# Schlankes Laufzeit-Image
FROM debian:bookworm-slim

# Notwendige Bibliotheken für SQLite
RUN apt-get update && apt-get install -y libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*

# App kopieren
COPY --from=build /app/bin/server /app/bin/server

# Verzeichnis für die Datenbank
RUN mkdir -p /app/data
VOLUME /app/data

# App starten
CMD ["/app/bin/server"]
