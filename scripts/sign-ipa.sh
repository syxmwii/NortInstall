#!/usr/bin/env bash
# Подписывает неподписанный IPA: .p12 + пароль + .mobileprovision.
# Запускается в CI (macos-15) или локально на Mac:
#   P12_B64=… P12_PASSWORD=… PROFILE_B64=… OUT=NortInstall-A.ipa \
#     ./scripts/sign-ipa.sh build/NortInstall.ipa
set -euo pipefail

INPUT=${1:?путь к неподписанному ipa}
OUT=${OUT:-NortInstall-signed.ipa}
: "${P12_B64:?нужен base64 .p12}" "${P12_PASSWORD:?нужен пароль}" "${PROFILE_B64:?нужен base64 .mobileprovision}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

unzip -q "$INPUT" -d "$WORK"
echo "$P12_B64" | base64 -d > "$WORK/cert.p12"
echo "$PROFILE_B64" | base64 -d > "$WORK/profile.mobileprovision"

# Временный keychain, чтобы не трогать системный
KEYCHAIN="$WORK/sign.keychain-db"
security create-keychain -p ci "$KEYCHAIN"
security set-keychain-settings -lut 3600 "$KEYCHAIN"
security unlock-keychain -p ci "$KEYCHAIN"
security import "$WORK/cert.p12" -k "$KEYCHAIN" -P "$P12_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k ci "$KEYCHAIN"

IDENTITY=$(security find-identity -v -p codesigning "$KEYCHAIN" | awk -F'"' '/[0-9]+\)/ {print $2; exit}')
echo "Подписываем: $IDENTITY"

APP=$(echo "$WORK"/Payload/*.app)
cp "$WORK/profile.mobileprovision" "$APP/embedded.mobileprovision"

# Сначала вложенные фреймворки, потом само приложение
if [ -d "$APP/Frameworks" ]; then
  for framework in "$APP/Frameworks/"*.framework; do
    [ -e "$framework" ] || continue
    /usr/bin/codesign --force --sign "$IDENTITY" --keychain "$KEYCHAIN" --timestamp=none "$framework"
  done
fi
/usr/bin/codesign --force --sign "$IDENTITY" --keychain "$KEYCHAIN" --timestamp=none "$APP"

( cd "$WORK" && zip -qry "$OLDPWD/$OUT" Payload )
security delete-keychain "$KEYCHAIN" || true

echo "Готово: $OUT"
