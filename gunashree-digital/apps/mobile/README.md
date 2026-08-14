# Gunashree Digital mobile app

The Flutter app is an independent poster design studio for Android. It includes
published template sync, offline starter templates, local saved designs,
authentication, and a touch-friendly poster editor.

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

`10.0.2.2` is the Android emulator address for a host machine. For a physical
device, use the API server's LAN address instead.

## Build a release APK

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-api.example.com
```

The APK is written to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For a production release, replace the debug signing configuration in
`android/app/build.gradle.kts` with a private Android keystore.