#!/usr/bin/env bash
set -e

if ! type flutter &>/dev/null -a type fvm &>/dev/null; then
  echo 'Flutter not found, but fvm is. Using fvm flutter.'
  fvm use
  FLUTTER_CMD='fvm flutter'
else
  FLUTTER_CMD='flutter'
fi

echo 'Building IPA (iOS/iPadOS)...'
${FLUTTER_CMD} build ipa --no-tree-shake-icons --obfuscate --split-debug-info=./ios/
echo

echo 'Building AppBundle (Android)...'
${FLUTTER_CMD} build appbundle --no-tree-shake-icons --obfuscate --split-debug-info=./android/
