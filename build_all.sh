#!/usr/bin/env bash
set -e

echo "Building IPA (iOS/iPadOS)..."
flutter build ipa --no-tree-shake-icons --obfuscate --split-debug-info=./ios/
echo

echo "Building AppBundle (Android)..."
flutter build appbundle --no-tree-shake-icons --obfuscate --split-debug-info=./android/

rm -f android/symbols.zip
(cd build/app/intermediates/merged_native_libs/release/out/lib && zip --recurse-paths ../../../../../../../android/symbols.zip ./* >/dev/null)
