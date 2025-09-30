#!/usr/bin/env bash
set -e

if ! type flutter &>/dev/null && type fvm &>/dev/null; then
  echo 'Flutter not found, but fvm is. Using fvm flutter.'
  fvm use
  FLUTTER_CMD='fvm flutter'
else
  FLUTTER_CMD='flutter'
fi

if ${BUILD_IOS:-true}
then
  echo 'Building IPA (iOS/iPadOS)...'
  ${FLUTTER_CMD} build ipa --no-tree-shake-icons --obfuscate --split-debug-info=./ios/
else
  echo 'Skipping IPA (iOS/iPadOS)...'
fi
echo

if ${BUILD_ANDROID:-true}
then
  echo 'Building AppBundle (Android)...'
  ${BUILD_ANDROID:-true} && ${FLUTTER_CMD} build appbundle --no-tree-shake-icons --obfuscate --split-debug-info=./android/
else
  echo 'Skipping AppBundle (Android)...'
fi
