#!/usr/bin/env bash
set -euo pipefail

# Run this on macOS only.
# Required: Xcode, Go, gomobile, Apple SDK toolchain.
# Accepted source layouts next to this project root:
#   ./sing-box-testing/
#   ./sing-box-testing/sing-box-testing/
# You can also override with SING_BOX_SOURCE_DIR=/absolute/path.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/ios/Frameworks"
SOURCE_OVERRIDE="${SING_BOX_SOURCE_DIR:-}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must be run on macOS because Libbox.xcframework needs Xcode Apple SDKs." >&2
  exit 1
fi

resolve_source_dir() {
  if [[ -n "${SOURCE_OVERRIDE}" ]]; then
    echo "${SOURCE_OVERRIDE}"
    return 0
  fi
  if [[ -d "${ROOT_DIR}/sing-box-testing/cmd/internal/build_libbox" ]]; then
    echo "${ROOT_DIR}/sing-box-testing"
    return 0
  fi
  if [[ -d "${ROOT_DIR}/sing-box-testing/sing-box-testing/cmd/internal/build_libbox" ]]; then
    echo "${ROOT_DIR}/sing-box-testing/sing-box-testing"
    return 0
  fi
  return 1
}

BUILD_SRC_DIR="$(resolve_source_dir || true)"
if [[ -z "${BUILD_SRC_DIR}" || ! -d "${BUILD_SRC_DIR}" ]]; then
  echo "Missing sing-box source tree with cmd/internal/build_libbox" >&2
  echo "Unzip sing-box-testing.zip next to the project root and rerun." >&2
  exit 1
fi

cd "${BUILD_SRC_DIR}"
go run ./cmd/internal/build_libbox -target apple
mkdir -p "${OUTPUT_DIR}"
rm -rf "${OUTPUT_DIR}/Libbox.xcframework"
mv Libbox.xcframework "${OUTPUT_DIR}/Libbox.xcframework"
echo "[OK] Created ${OUTPUT_DIR}/Libbox.xcframework"
