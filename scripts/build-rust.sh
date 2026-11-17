#!/usr/bin/env bash
# Собирает rust-core в build/NortInstallFFI.xcframework.
# Запускать на macOS с Xcode и rustup (нужны цели iOS).
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="build"
LIB_NAME="libnortinstall_core.a"
TARGETS=("aarch64-apple-ios")   # при желании добавьте x86_64-apple-ios (симулятор)

rm -rf "$OUT/NortInstallFFI.xcframework"
mkdir -p "$OUT"

for target in "${TARGETS[@]}"; do
  rustup target add "$target"
  cargo build --release --target "$target" --manifest-path rust-core/Cargo.toml
done

ARGS=()
for target in "${TARGETS[@]}"; do
  ARGS+=(-library "rust-core/target/$target/release/$LIB_NAME" -headers rust-core/include)
done

xcodebuild -create-xcframework "${ARGS[@]}" -output "$OUT/NortInstallFFI.xcframework"
echo "Готово: $OUT/NortInstallFFI.xcframework"
