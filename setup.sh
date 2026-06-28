#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

echo "→ Flutter: $(flutter --version | head -1)"
echo "→ Installing dependencies..."
flutter pub get
echo "✓ Dependencies ready."
