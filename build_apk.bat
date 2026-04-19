@echo off
setlocal

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not available in PATH.
  echo Install Flutter first, then run this script again.
  exit /b 1
)

if not exist android\settings.gradle (
  if not exist android\settings.gradle.kts (
    echo Android platform files not found. Generating them with Flutter...
    call flutter create . --platforms=android
    if errorlevel 1 exit /b 1
  )
)

call flutter pub get
if errorlevel 1 exit /b 1

call flutter analyze
if errorlevel 1 exit /b 1

call flutter build apk --release --split-per-abi
if errorlevel 1 exit /b 1

echo.
echo Release APK files are available in:
echo build\app\outputs\flutter-apk\

endlocal
