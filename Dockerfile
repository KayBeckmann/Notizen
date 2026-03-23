# Build Stage
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Dependencies kopieren und installieren
COPY pubspec.* ./
RUN flutter pub get

# Source kopieren
COPY . .

# Web-Build erstellen
RUN flutter build web --release

# Production Stage
FROM nginx:alpine

# Nginx-Konfiguration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Build-Artefakte kopieren
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
