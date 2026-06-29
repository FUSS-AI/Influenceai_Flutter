# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --dart-define-from-file=.env

# Stage 2: Serve the app with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
