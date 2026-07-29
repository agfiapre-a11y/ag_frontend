#!/bin/bash
# Download all Gradle/Maven dependencies manually with retries
# Run: bash download_gradle_deps.sh
#
# This pre-downloads all the JARs Gradle needs so the build doesn't time out.

set -e

export ANDROID_HOME=/home/echendaa/Android/Sdk
export ANDROID_SDK_ROOT=/home/echendaa/Android/Sdk
export JAVA_HOME=/home/echendaa/jdk17
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

PROJECT="/home/echendaa/Desktop/Paradise AG version2/paradise_ag"

echo "============================================"
echo "  Pre-download Gradle Dependencies"
echo "============================================"
echo ""

# List of critical Maven dependencies that keep timing out
# Format: URL | destination path
GRADLE_CACHE="$HOME/.gradle/caches/modules-2/files-2.1"

declare -a DEPS=(
  # bundletool
  "https://dl.google.com/dl/android/maven2/com/android/tools/build/bundletool/1.18.3/bundletool-1.18.3.jar|com.android.tools.build/bundletool/1.18.3/bundletool-1.18.3.jar"
  # Kotlin Gradle Plugin
  "https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.3.20/kotlin-gradle-plugin-2.3.20.jar|org.jetbrains.kotlin/kotlin-gradle-plugin/2.3.20/kotlin-gradle-plugin-2.3.20.jar"
  # Kotlin stdlib
  "https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/2.3.20/kotlin-stdlib-2.3.20.jar|org.jetbrains.kotlin/kotlin-stdlib/2.3.20/kotlin-stdlib-2.3.20.jar"
  # Guava
  "https://repo.maven.apache.org/maven2/com/google/guava/guava/32.1.1-jre/guava-32.1.1-jre.jar|com.google.guava/guava/32.1.1-jre/guava-32.1.1-jre.jar"
  # failureaccess
  "https://repo.maven.apache.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar|com.google.guava/failureaccess/1.0.1/failureaccess-1.0.1.jar"
  # Netty
  "https://repo.maven.apache.org/maven2/io/netty/netty-codec-socks/4.1.93.Final/netty-codec-socks-4.1.93.Final.jar|io.netty/netty-codec-socks/4.1.93.Final/netty-codec-socks-4.1.93.Final.jar"
  "https://repo.maven.apache.org/maven2/io/netty/netty-codec/4.1.93.Final/netty-codec-4.1.93.Final.jar|io.netty/netty-codec/4.1.93.Final/netty-codec-4.1.93.Final.jar"
  "https://repo.maven.apache.org/maven2/io/netty/netty-transport/4.1.93.Final/netty-transport-4.1.93.Final.jar|io.netty/netty-transport/4.1.93.Final/netty-transport-4.1.93.Final.jar"
  "https://repo.maven.apache.org/maven2/io/netty/netty-buffer/4.1.93.Final/netty-buffer-4.1.93.Final.jar|io.netty/netty-buffer/4.1.93.Final/netty-buffer-4.1.93.Final.jar"
  "https://repo.maven.apache.org/maven2/io/netty/netty-resolver/4.1.93.Final/netty-resolver-4.1.93.Final.jar|io.netty/netty-resolver/4.1.93.Final/netty-resolver-4.1.93.Final.jar"
  "https://repo.maven.apache.org/maven2/io/netty/netty-common/4.1.93.Final/netty-common-4.1.93.Final.jar|io.netty/netty-common/4.1.93.Final/netty-common-4.1.93.Final.jar"
  # AGP (Android Gradle Plugin)
  "https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/9.0.1/gradle-9.0.1.jar|com.android.tools.build/gradle/9.0.1/gradle-9.0.1.jar"
  # AAPT2
  "https://dl.google.com/dl/android/maven2/com/android/tools/build/aapt2/9.0.1-12056047/aapt2-9.0.1-12056047-linux.jar|com.android.tools.build/aapt2/9.0.1-12056047/aapt2-9.0.1-12056047-linux.jar"
)

download_with_retry() {
  local url="$1"
  local dest="$2"
  local max_retries=5
  
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    echo "  [SKIP] Already exists: $(basename $dest)"
    return 0
  fi
  
  mkdir -p "$(dirname "$dest")"
  
  for i in $(seq 1 $max_retries); do
    echo "  [TRY $i/$max_retries] $(basename $dest)"
    if curl -L --retry 2 --connect-timeout 30 --max-time 300 -sS "$url" -o "$dest" 2>&1; then
      if [ -s "$dest" ]; then
        echo "  [OK] Downloaded $(basename $dest) ($(du -h "$dest" | cut -f1))"
        return 0
      fi
    fi
    echo "  [FAIL] Retry $i..."
    rm -f "$dest"
    sleep 3
  done
  
  echo "  [ERROR] Failed after $max_retries retries: $url"
  return 1
}

echo ">>> Downloading ${#DEPS[@]} critical dependencies..."
echo ""

FAILED=0
for dep in "${DEPS[@]}"; do
  url="${dep%%|*}"
  relpath="${dep##*|}"
  dest="$GRADLE_CACHE/$relpath"
  
  echo "Checking: $(basename $relpath)"
  download_with_retry "$url" "$dest" || FAILED=$((FAILED+1))
  echo ""
done

echo "============================================"
echo "  Summary: $(( ${#DEPS[@]} - FAILED ))/${#DEPS[@]} downloaded"
if [ $FAILED -gt 0 ]; then
  echo "  $FAILED failed. Re-run this script to retry."
fi
echo ""
echo "  Now run: bash build_android.sh"
echo "============================================"
