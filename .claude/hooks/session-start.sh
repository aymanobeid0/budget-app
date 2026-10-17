#!/bin/bash
# Installs the Flutter SDK and pub packages in Claude Code cloud sessions,
# so `flutter analyze` and `flutter test` work there. Local machines already
# have Flutter, so this exits early outside the cloud.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Keep in step with the `flutter:` lower bound in pubspec.lock.
FLUTTER_VERSION="3.47.7"
FLUTTER_HOME="${HOME}/flutter"

STAMP="${FLUTTER_HOME}/.installed-by-session-hook"

if [ "$(cat "${STAMP}" 2>/dev/null)" != "${FLUTTER_VERSION}" ]; then
  rm -rf "${FLUTTER_HOME}"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "${HOME}"
  echo "${FLUTTER_VERSION}" > "${STAMP}"
fi

# The SDK is unpacked as root; git refuses to read it without this.
git config --global --add safe.directory "${FLUTTER_HOME}" >/dev/null 2>&1 || true

export PATH="${FLUTTER_HOME}/bin:${PATH}"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${FLUTTER_HOME}/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE}"
fi

flutter config --no-analytics >/dev/null 2>&1 || true
flutter --suppress-analytics --version >/dev/null

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"
flutter pub get
