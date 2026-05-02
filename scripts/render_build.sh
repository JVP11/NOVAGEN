#!/usr/bin/env bash
# Render.com static build: install Flutter stable, build web release.
# Repo layout: this script lives in scripts/; Flutter app is in files(1)/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT}/files(1)"
FLUTTER_DIR="${FLUTTER_DIR:-${ROOT}/.flutter-sdk}"

if [[ ! -d "${FLUTTER_DIR}/bin" ]]; then
  echo "Installing Flutter (stable, shallow clone)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --version
flutter config --no-analytics --enable-web
cd "${APP_DIR}"
flutter pub get
flutter build web --release

echo "Web build output: ${APP_DIR}/build/web"
