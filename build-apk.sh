#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$SCRIPT_DIR/../.tools/android-sdk/platform-tools" ]]; then
  echo "Android SDK not found. Running setup-android.sh first..."
  "$SCRIPT_DIR/setup-android.sh"
fi

# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"
cd "$SCRIPT_DIR"

if [[ -z "${JAVA_HOME:-}" ]]; then
  echo "ERROR: JDK 17 is required for Android builds."
  echo "Install it with: sudo dnf install -y java-17-openjdk-devel"
  exit 1
fi

echo "→ Flutter: $(flutter --version | head -1)"
echo "→ Java:    $(java -version 2>&1 | head -1)"
echo "→ Android: $ANDROID_HOME"
echo "→ Installing dependencies..."
flutter pub get

MODE="${1:-release}"
shift || true

if [[ "$MODE" == "debug" ]]; then
  echo "→ Building debug APK..."
  flutter build apk --debug "$@"
  APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
else
  echo "→ Building release APK..."
  flutter build apk --release "$@"
  APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
fi

echo ""
echo "✓ APK built successfully:"
echo "  $SCRIPT_DIR/$APK_PATH"
echo ""
echo "Copy to your phone (USB debugging) with:"
echo "  adb install -r \"$SCRIPT_DIR/$APK_PATH\""
