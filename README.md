# Modern Calculator

Modern Calculator is a Flutter-based calculator app designed to feel good on mobile and stay easy to turn into an Android APK. It includes a modern Material 3 interface, scientific mode, calculation history, and light/dark themes.

## Features

- Modern mobile-friendly UI built with Flutter and Material 3
- Standard calculator operations
- Scientific functions like `sin`, `cos`, `tan`, `ln`, `log`, `sqrt`, powers, factorial, and constants
- History panel with saved calculations
- Light and dark mode toggle
- Degree/Radian angle toggle for trigonometry
- GitHub Actions workflow that can build APK artifacts after push

## Project Structure

- `lib/main.dart`: app entry point and responsive calculator screen
- `lib/services/calculator_engine.dart`: expression parser and math engine
- `lib/services/calculator_controller.dart`: app state, history, and user actions
- `lib/services/storage_service.dart`: persistent storage for history and preferences
- `lib/theme/app_theme.dart`: light and dark theme definitions
- `.github/workflows/android-apk.yml`: CI workflow to build Android APKs on GitHub
- `.github/workflows/flutter.yml`: APK release workflow with Java 17 + Flutter 3.22.0
- `build_apk.bat`: one-command Windows helper for generating Android files and building APKs

## Local Setup

1. Install Flutter and Android Studio.
2. From the project root, run:

```bash
flutter create . --platforms=android
flutter pub get
flutter run
```

If you are on Windows and want a quicker APK flow, run:

```bat
build_apk.bat
```

That script will:

- generate Android files if they do not exist yet
- install packages
- run static analysis
- build release APKs

## Build APK

For a release build:

```bash
flutter build apk --release --split-per-abi
```

The APK files will be created in:

```text
build/app/outputs/flutter-apk/
```

## Push To GitHub

This workspace already has a local Git repository and an initial commit. Create an empty GitHub repository, then run:

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

## Build APK On GitHub

After you push the project:

1. Open the repository on GitHub.
2. Go to the `Actions` tab.
3. Run or wait for the `android-apk` workflow.
4. Download the APK artifact from the workflow run.

The workflow installs Flutter, prepares the Android platform if needed, and uploads the generated APK files as build artifacts.

## Important Notes Before Publishing

- Change the Android application ID before Play Store release if you do not want the default example package.
- Add signing configuration for Play Store publishing.
- Update the app version in `pubspec.yaml` before each release.

Official Flutter Android release documentation:

- [Build and release an Android app](https://docs.flutter.dev/deployment/android)
