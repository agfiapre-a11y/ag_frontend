#!/bin/bash
# Build Android APK for Paradise AG
# Run: bash build_android.sh

set -e

export ANDROID_HOME=/home/echendaa/Android/Sdk
export ANDROID_SDK_ROOT=/home/echendaa/Android/Sdk
export JAVA_HOME=/home/echendaa/jdk17
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

echo "=== Android SDK: $ANDROID_HOME ==="
echo "=== NDK: $(ls $ANDROID_HOME/ndk/ 2>/dev/null || echo 'none') ==="
echo ""

# Clean
echo ">>> Cleaning..."
flutter clean
rm -rf build/ .dart_tool/ android/.gradle/

# Pub get
echo ">>> Getting dependencies..."
flutter pub get

# Build APK (release with Supabase credentials)
echo ">>> Building APK (release)..."
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://dbmbkevspcozcnhcsyii.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRibWJrZXZzcGNvemNuaGNzeWlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3ODczNTUsImV4cCI6MjA5OTM2MzM1NX0.7W2hZ0QIBYdpZ4tYh_wl7M3SpP9NzD7QWO90QHk5FDo"

# Show result
APK="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
  SIZE=$(du -h "$APK" | cut -f1)
  echo ""
  echo "=== SUCCESS ==="
  echo "APK: $APK ($SIZE)"
  echo "Copy to phone and install."
else
  echo "=== BUILD FAILED ==="
  exit 1
fi
