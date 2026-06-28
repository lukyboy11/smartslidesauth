#!/usr/bin/env bash
# Source this file to use the project-local Flutter SDK:
#   source env.sh
#   flutter run

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLUTTER_ROOT="$SCRIPT_DIR/../.tools/flutter"
export ANDROID_HOME="$SCRIPT_DIR/../.tools/android-sdk"
export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Android Gradle builds require JDK 17 (Java 25 is not supported yet).
if [[ -x "$SCRIPT_DIR/../.tools/jdk-17/bin/java" ]]; then
  export JAVA_HOME="$SCRIPT_DIR/../.tools/jdk-17"
elif [[ -d /usr/lib/jvm/java-17-openjdk ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
elif [[ -d /usr/lib/jvm/java-21-openjdk ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi
