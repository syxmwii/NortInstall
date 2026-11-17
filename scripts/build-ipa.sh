#!/usr/bin/env bash
# Собирает НЕПОДПИСАННЫЙ build/NortInstall.ipa (локально и в CI, macOS + Xcode).
# Перед запуском нужен build/NortInstallFFI.xcframework: ./scripts/build-rust.sh
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen

xcodebuild \
  -project NortInstall.xcodeproj \
  -scheme NortInstall \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/NortInstall.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  archive

rm -rf build/ipa
mkdir -p build/ipa/Payload
cp -R build/NortInstall.xcarchive/Products/Applications/NortInstall.app build/ipa/Payload/
(cd build/ipa && zip -qry ../NortInstall.ipa Payload)

echo "Готово: build/NortInstall.ipa (неподписанный)"
