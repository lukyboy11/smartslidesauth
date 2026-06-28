#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANDROID_SDK="$PROJECT_ROOT/.tools/android-sdk"
CMDLINE_TOOLS_ZIP="$PROJECT_ROOT/.tools/cmdline-tools-linux.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

mkdir -p "$PROJECT_ROOT/.tools"

if [[ ! -x "$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" ]]; then
  echo "→ Downloading Android command-line tools..."
  curl -L --retry 3 -o "$CMDLINE_TOOLS_ZIP" "$CMDLINE_TOOLS_URL"
  rm -rf "$ANDROID_SDK/cmdline-tools"
  mkdir -p "$ANDROID_SDK/cmdline-tools"
  unzip -q -o "$CMDLINE_TOOLS_ZIP" -d "$ANDROID_SDK/cmdline-tools"
  mv "$ANDROID_SDK/cmdline-tools/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest"
  rm -f "$CMDLINE_TOOLS_ZIP"
fi

export ANDROID_HOME="$ANDROID_SDK"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "→ Installing Android SDK packages (first run may take a few minutes)..."
yes | sdkmanager --sdk_root="$ANDROID_SDK" \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;36.0.0" \
  "cmdline-tools;latest" > /dev/null

echo "→ Accepting Android licenses..."
yes | sdkmanager --sdk_root="$ANDROID_SDK" --licenses > /dev/null

# Persist SDK path for Gradle.
LOCAL_PROPS="$SCRIPT_DIR/android/local.properties"
if grep -q '^sdk.dir=' "$LOCAL_PROPS" 2>/dev/null; then
  sed -i "s|^sdk.dir=.*|sdk.dir=$ANDROID_SDK|" "$LOCAL_PROPS"
else
  echo "sdk.dir=$ANDROID_SDK" >> "$LOCAL_PROPS"
fi

# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"
flutter config --android-sdk "$ANDROID_SDK" > /dev/null

echo "✓ Android SDK ready at $ANDROID_SDK"
