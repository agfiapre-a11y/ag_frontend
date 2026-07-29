#!/bin/bash
# Install all Android build dependencies for Paradise AG
# Run: bash install_android_deps.sh

set -e

export ANDROID_HOME=/home/echendaa/Android/Sdk
export ANDROID_SDK_ROOT=/home/echendaa/Android/Sdk
export JAVA_HOME=/home/echendaa/jdk17
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

echo "============================================"
echo "  Paradise AG - Android Dependencies Installer"
echo "============================================"
echo ""
echo "Android SDK: $ANDROID_HOME"
echo "Java:        $JAVA_HOME"
echo ""

# Verify JDK
if [ ! -f "$JAVA_HOME/bin/javac" ]; then
  echo "ERROR: JDK not found at $JAVA_HOME"
  echo "Install JDK 17 first:"
  echo "  curl -L 'https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse' -o /tmp/jdk17.tar.gz"
  echo "  mkdir -p /home/echendaa/jdk17"
  echo "  tar -xzf /tmp/jdk17.tar.gz -C /home/echendaa/jdk17 --strip-components=1"
  exit 1
fi

echo "JDK OK: $($JAVA_HOME/bin/javac -version 2>&1)"
echo ""

# 1. Accept all SDK licenses
echo ">>> [1/5] Accepting SDK licenses..."
yes | $SDKMANAGER --licenses 2>/dev/null || true
echo "Done."
echo ""

# 2. Install Android SDK Platform 36
echo ">>> [2/5] Installing Android SDK Platform 36..."
$SDKMANAGER "platforms;android-36" 2>/dev/null
echo "Done."
echo ""

# 3. Install Build-Tools 36
echo ">>> [3/5] Installing Build-Tools 36..."
$SDKMANAGER "build-tools;36.0.0" 2>/dev/null
echo "Done."
echo ""

# 4. Install Platform-Tools (if missing)
echo ">>> [4/5] Installing Platform-Tools..."
$SDKMANAGER "platform-tools" 2>/dev/null
echo "Done."
echo ""

# 5. Verify NDK
echo ">>> [5/5] Verifying NDK..."
NDK_DIR="$ANDROID_HOME/ndk/28.2.13676358"
if [ -f "$NDK_DIR/source.properties" ]; then
  echo "NDK OK: found at $NDK_DIR"
else
  echo "WARNING: NDK 28.2.13676358 not found or incomplete."
  echo "Installing NDK (this is a large download ~1GB)..."
  $SDKMANAGER "ndk;28.2.13676358"
fi
echo ""

# Verify everything
echo "============================================"
echo "  Verification"
echo "============================================"

echo -n "Platform 36:    "
[ -d "$ANDROID_HOME/platforms/android-36" ] && echo "OK" || echo "MISSING"

echo -n "Build-Tools 36: "
[ -d "$ANDROID_HOME/build-tools/36.0.0" ] && echo "OK" || echo "MISSING"

echo -n "Platform-Tools: "
[ -d "$ANDROID_HOME/platform-tools" ] && echo "OK" || echo "MISSING"

echo -n "NDK:            "
[ -f "$NDK_DIR/source.properties" ] && echo "OK" || echo "MISSING"

echo -n "javac:          "
[ -f "$JAVA_HOME/bin/javac" ] && echo "OK" || echo "MISSING"

echo -n "jlink:          "
[ -f "$JAVA_HOME/bin/jlink" ] && echo "OK" || echo "MISSING"

echo ""
echo "============================================"
echo "  All dependencies installed!"
echo "  Now run: bash build_android.sh"
echo "============================================"
