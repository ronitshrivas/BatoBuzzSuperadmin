# ---- Build stage: compile the Flutter web bundle ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy pubspec first and fetch packages (cached unless pubspec changes)
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the source and build
COPY . .
RUN flutter build web --release

# ---- Serve stage: nginx serves the static files ----
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
