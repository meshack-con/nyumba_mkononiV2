#!/usr/bin/env bash
set -euo pipefail

readonly FLUTTER_VERSION="3.35.4"
readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLUTTER_DIR="${PROJECT_DIR}/.flutter-sdk"
readonly FLUTTER_ARCHIVE="/tmp/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  curl --fail --location --retry 3 \
    --output "${FLUTTER_ARCHIVE}" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  mkdir -p "${FLUTTER_DIR}"
  tar --extract --xz --file "${FLUTTER_ARCHIVE}" \
    --directory "${FLUTTER_DIR}" --strip-components=1
fi

readonly FLUTTER="${FLUTTER_DIR}/bin/flutter"
"${FLUTTER}" config --enable-web
"${FLUTTER}" pub get
"${FLUTTER}" build web --release \
  --dart-define=API_BASE_URL=https://nyumba-mkononi-backend.onrender.com
