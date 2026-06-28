#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

cd "$SCRIPT_DIR"

echo "→ Flutter: $(flutter --version | head -1)"
echo "→ Checking dependencies..."
flutter pub get

echo "→ Launching app..."
exec flutter run "$@"
